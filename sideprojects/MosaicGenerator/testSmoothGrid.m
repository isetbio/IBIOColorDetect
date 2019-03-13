function testSmoothGrid

    load('cp0.5degs.mat', 'conePositions');

    % Termination conditions
    dTolerance = 1.0e-3;
    maxIterations = 500;
    
    visualizeProgress = true;
    conePositions = smoothGrid(conePositions,  dTolerance, maxIterations, visualizeProgress);        
end

function conePositions = smoothGrid(conePositions,  dTolerance, maxIterations, visualizeProgress)  

    gridParams.coneSpacingFunction = @coneSpacingFunction;
    gridParams.domainFunction = @ellipticalDomainFunction;
    gridParams.radius = max(abs(conePositions(:)));
    gridParams.center = [0 0];
    gridParams.ellipseAxes = [1 1.2247];
    gridParams.borderTolerance = 0.001 * 2;
    gridParams.positionalDiffTolerance = 0.8;
    gridParams.lambdaMin = 2;
    gridParams.dTolerance = gridParams.lambdaMin * dTolerance;
    gridParams.maxIterations = maxIterations;
    
    deps = sqrt(eps) * gridParams.lambdaMin;
    deltaT = 0.2;

    % Initialize convergence
    forceMagnitudes = [];

    % Turn off Delaunay triangularization warning
    warning('off', 'MATLAB:qhullmx:InternalWarning');
    
    % Number of cones
    conesNum = size(conePositions, 1);
    
    % Iteratively adjust the cone positions until the forces between nodes
    % (conePositions) reach equilibrium.
    notConverged = true;
    oldConePositions = inf;
    
    iteration = 0;
    maxMovements = [];
    
    while (notConverged) && (iteration <= gridParams.maxIterations)
        iteration = iteration + 1;
  
        % compute cone positional diffs
        positionalDiffs = sqrt(sum((conePositions-oldConePositions).^ 2,2)); 
        
        if (max(positionalDiffs) > gridParams.positionalDiffTolerance)
            % save old come positions
            oldConePositions = conePositions;
            
            % Perform new Delaunay triangulation to determine the updated
            % topology of the truss.
            triangleConeIndices = delaunayn(conePositions);
        
            % Compute the centroids of all triangles
            centroidPositions = 1.0/3.0 * (...
                    conePositions(triangleConeIndices(:, 1), :) + ...
                    conePositions(triangleConeIndices(:, 2), :) + ...
                    conePositions(triangleConeIndices(:, 3), :));
            
            % Remove centroids outside the desired region by applying the
            % signed distance function
            d = feval(gridParams.domainFunction, centroidPositions, ...
                    gridParams.center, gridParams.radius, ...
                    gridParams.ellipseAxes);
            triangleConeIndices = triangleConeIndices(d < gridParams.borderTolerance, :);
            
           % Create a list of the unique springs (each spring connecting 2 cones)
           springs = [...
                    triangleConeIndices(:, [1, 2]); ...
                    triangleConeIndices(:, [1, 3]); ...
                    triangleConeIndices(:, [2, 3]) ...
           ];
           springs = unique(sort(springs, 2), 'rows');

           % find all springs connected to this cone
           springIndices = cell(1,conesNum);
           for coneIndex = 1:conesNum
               springIndices{coneIndex} = find((springs(:, 1) == coneIndex) | (springs(:, 2) == coneIndex));
           end
        end
        
        % Compute spring vectors
        springVectors =  conePositions(springs(:, 1), :) - conePositions(springs(:, 2), :);
        % their centers
        springCenters = (conePositions(springs(:, 1), :) + conePositions(springs(:, 2), :)) / 2.0;
        % and their lengths
        springLengths = sqrt(sum(springVectors.^2, 2));
        
        % Compute desired spring lengths. This is done by evaluating the
        % passed coneDistance function at the spring centers.
        desiredSpringLengths = feval(gridParams.coneSpacingFunction, springCenters);
        
        % Normalize spring lengths
        normalizingFactor = sqrt(sum(springLengths .^ 2) / ...
            sum(desiredSpringLengths .^ 2));
        desiredSpringLengths = desiredSpringLengths * normalizingFactor;
        
        gain = 1.1;
        springForces = max(gain * desiredSpringLengths - springLengths, 0);

        % compute x, y-components of forces on each of the springs
        springForceXYcomponents = abs(springForces ./ springLengths * [1, 1] .* springVectors);

        % Compute net forces on each cone
        netForceVectors = zeros(conesNum, 2);
        
        parfor coneIndex = 1:conesNum
           % compute net force from all connected springs
           deltaPos = -bsxfun(@minus, springCenters(springIndices{coneIndex}, :), conePositions(coneIndex, :));
           netForceVectors(coneIndex, :) = sum(sign(deltaPos) .* springForceXYcomponents(springIndices{coneIndex}, :), 1);
        end
            
        % update cone positions according to netForceVectors
        conePositions = conePositions + deltaT * netForceVectors;
        
        d = feval(gridParams.domainFunction, conePositions, ...
                gridParams.center, gridParams.radius, gridParams.ellipseAxes);
        outsideBoundaryIndices = d > 0;
            
        % And project them back to the domain
        if (~isempty(outsideBoundaryIndices))
                % Compute numerical gradient along x-positions
                dXgradient = (feval(gridParams.domainFunction, ...
                    [conePositions(outsideBoundaryIndices, 1) + deps, ...
                    conePositions(outsideBoundaryIndices, 2)], ...
                    gridParams.center, gridParams.radius, ...
                    gridParams.ellipseAxes) - d(outsideBoundaryIndices)) / ...
                    deps;
                dYgradient = (feval(gridParams.domainFunction, ...
                    [conePositions(outsideBoundaryIndices, 1), ...
                    conePositions(outsideBoundaryIndices, 2)+deps], ...
                    gridParams.center, gridParams.radius, ...
                    gridParams.ellipseAxes) - d(outsideBoundaryIndices)) / ...
                    deps;

                % Project these points back to boundary
                conePositions(outsideBoundaryIndices, :) = ...
                    conePositions(outsideBoundaryIndices, :) - ...
                    [d(outsideBoundaryIndices) .* dXgradient, ...
                    d(outsideBoundaryIndices) .* dYgradient];
        end
            
        % Check if all interior nodes move less than dTolerance
        movementAmplitudes = sqrt(sum(deltaT * netForceVectors(d < -gridParams.borderTolerance, :) .^2 , 2));
        if max(movementAmplitudes) < gridParams.dTolerance
            notConverged = false; 
        end
        fprintf('Iteration: %d/%d, maxMov: %2.6f, tolerance: %2.6f\n', iteration, gridParams.maxIterations, max(movementAmplitudes), gridParams.dTolerance);
        
        if (visualizeProgress)
            maxMovements(iteration) = max(movementAmplitudes);
            plotMosaic(conePositions, triangleConeIndices, maxMovements,  gridParams.dTolerance);
        end
    end
    
    if notConverged
        fprintf('Exceeded max number of iteraritions\n');
    else
        fprintf('Converged !\n');
    end
        
end

function distances = ellipticalDomainFunction(conePositions, center, radius, ellipseAxes)
    xx = conePositions(:, 1) - center(1);
    yy = conePositions(:, 2) - center(2);
    radii = sqrt((xx / ellipseAxes(1)) .^ 2 + (yy / ellipseAxes(2)) .^ 2);
    distances = radii - radius;
end

function [coneSpacingInMicrons, eccentricitiesInMicrons] = coneSpacingFunction(conePositions)
    eccentricitiesInMicrons = sqrt(sum(conePositions .^ 2, 2));
    eccentricitiesInMeters = eccentricitiesInMicrons * 1e-6;
    angles = atan2(conePositions(:, 2), conePositions(:, 1)) / pi * 180;
    coneSpacingInMeters = coneSizeReadData('eccentricity', eccentricitiesInMeters, 'angle', angles);
    coneSpacingInMicrons = coneSpacingInMeters' * 1e6;
end

function plotMosaic(conePositions, triangleConeIndices, maxMovements,  dTolerance)
    figure(1); clf;
    subplot(2,3,[1 2 4 5]);
    visualizeLatticeState(conePositions, triangleConeIndices)
    plot(conePositions(:,1), conePositions(:,2), 'r.');
    set(gca, 'XLim', 70*[-1 1], 'YLim', 70*[-1 1], 'FontSize', 16);
    axis 'equal'
    
    subplot(2,3,3);
    plot(1:numel(maxMovements), maxMovements, 'ks-');
    hold on;
    plot([1 numel(maxMovements)], dTolerance*[1 1], 'r-', 'LineWidth', 1.5);
    set(gca, 'YLim', [dTolerance*0.5 max(maxMovements)], 'YScale', 'linear', 'FontSize', 16);
    xlabel('iteration');
    ylabel('max movement', 'FontSize', 16)
    ylabel('movement', 'FontSize', 16);
    axis 'square'
    
    qDist = computeQuality(conePositions, triangleConeIndices);
    qLims = [0 1.005]; qBins = [0.0:0.01:1.0];
    [counts,centers] = hist(qDist, qBins);
    subplot(2,3,6)
    bar(centers,counts,1)
    set(gca, 'XLim', qLims, 'YLim', [0 max(counts)], 'XTick', [0.1:0.2:1.0],  'FontSize', 16);
    grid on
    xlabel('hex-index $\left(\displaystyle 2 r_{ins} / r_{cir} \right)$', 'Interpreter', 'latex', 'FontSize', 16);
    ylabel('count', 'FontSize', 16);
    axis 'square'
    drawnow
    
end

function q = computeQuality(coneLocs, triangles)
    
    trianglesNum = size(triangles,1);
    X = coneLocs(:,1);
    Y = coneLocs(:,2);
    
    q = zeros(1,trianglesNum);
    for triangleIndex = 1:trianglesNum
        for node = 1:3
            x(node) = X(triangles(triangleIndex,node));
            y(node) = Y(triangles(triangleIndex,node));
        end 
        aLength = sqrt((x(1)-x(2))^2 + (y(1)-y(2))^2);
        bLength = sqrt((x(1)-x(3))^2 + (y(1)-y(3))^2);
        cLength = sqrt((x(2)-x(3))^2 + (y(2)-y(3))^2);
        q(triangleIndex) = (bLength+cLength-aLength)*(cLength+aLength-bLength)*(aLength+bLength-cLength)/(aLength*bLength*cLength);
    end
end


function visualizeLatticeState(conePositions, triangleConeIndices)
    x = conePositions(:,1);
    y = conePositions(:,2);
    
    xx = []; yy = [];
    for triangleIndex = 1:size(triangleConeIndices, 1)
        coneIndices = triangleConeIndices(triangleIndex, :);
        xCoords = x(coneIndices);
        yCoords = y(coneIndices);
        for k = 1:numel(coneIndices)
            xx = cat(2, xx, xCoords);
            yy = cat(2, yy, yCoords);
        end
    end
    
    patch(xx, yy, [0 0 0], 'EdgeColor', [0.4 0.4 0.4], ...
        'EdgeAlpha', 0.5, 'FaceAlpha', 0.0, ...
        'FaceColor', [0.99 0.99 0.99], 'LineWidth', 1.0, ...
        'LineStyle', '-', 'Parent', gca); 
    hold on;
end



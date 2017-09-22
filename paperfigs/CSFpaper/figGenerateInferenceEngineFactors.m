function figGenerateInferenceEngineFactors()

    close all;
    inferenceEngines = {...
        'mlpt' ...
        'svmV1FilterBank' ...
        'svm' ...
    };
    inferenceEngineLabels = inferenceEngines


    % Trials computed
    nTrainingSamples = 1024;
    
    % Perhaps use a subset of the trials.
    performanceTrialsUsed = 1024;
    
    useRBFSVMKernel = false;
    
    % Spatial pooling kernel parameters
    spatialPoolingKernelParams.type = 'V1QuadraturePair';  % Choose between 'V1CosUnit' 'V1SinUnit' 'V1QuadraturePair';
    spatialPoolingKernelParams.activationFunction = 'energy';  % Choose between 'energy' and 'fullWaveRectifier'
    spatialPoolingKernelParams.adjustForConeDensity = false;
    spatialPoolingKernelParams.temporalPCAcoeffs = Inf;  % Inf, results in no PCA, just the raw time series
    spatialPoolingKernelParams.shrinkageFactor = 1.0;  % > 1, results in expansion, < 1 results in shrinking 
   
    
    mosaicParams = getParamsForMosaicWithLabel('ISETbioHexEccBasedLMS');
    
    % 'random'; 'frozen0';
    emPathType = 'frozen0'; %random'; %'random';     
    centeredEMPaths = false;
    
    opticsModel = 'WvfHumanMeanOTFmagMeanOTFphase';
    pupilDiamMm = 3.0;
    
    ramPercentageEmployed = 1.0;  % use all the RAM
    freezeNoise = true;
        
    cyclesPerDegreeExamined =  [50];
    luminancesExamined =  [34]; 

    responseStabilizationMilliseconds = 10;
    responseExtinctionMilliseconds = 50;
    integrationTimeMilliseconds =  5.0;
    lowContrast = 0.0001;
    highContrast = 0.3;
    nContrastsPerDirection =  18;
    
    % What to do ?
    visualizeSpatialScheme = ~true;
    findPerformance = ~true;
    visualizePerformance = true;
    visualizeTransformedSignals = ~true;
    
    
    for inferenceEngineIndex = 1:numel(inferenceEngines)
        
        performanceClassifier = inferenceEngines{inferenceEngineIndex};
        performanceSignal = 'isomerizations';
        d = getData();
        sfTest{inferenceEngineIndex} = d.cyclesPerDegree;
        for luminanceIndex = 1:size(d.mlptThresholds,1)
            inferenceCSF(luminanceIndex,inferenceEngineIndex,:) = 1./([d.mlptThresholds(luminanceIndex,:).thresholdContrasts]*d.mlptThresholds(1).testConeContrasts(1));
        end
        
        if (inferenceEngineIndex > 1)
            if (any(sfTest{inferenceEngineIndex}-sfTest{1})~=0)
                error('sfs do not match');
            end
        end
        ratioCSF{inferenceEngineIndex} = squeeze(inferenceCSF(1,inferenceEngineIndex,:)) ./ squeeze(inferenceCSF(1,1,:));
        
    end % inferenceEngineIndex
    
    inferenceColors = [1 0 0; 0 0 1; 1 0 1];
    
    figure(1); clf;
    hold on
    for inferenceEngineIndex = 1:numel(inferenceEngines)
        
        if (inferenceEngineIndex == 1)
            % reference inference engine
            markerType  = 's-';
            markerSize = 13;
        else
            markerType = 'o-';
            markerSize = 10;
        end
        
        plot(sfTest{1}, squeeze(inferenceCSF(1,inferenceEngineIndex,:)), markerType, 'MarkerSize', markerSize, 'MarkerEdgeColor', [0 0 0], ...
            'MarkerFaceColor', squeeze(inferenceColors(inferenceEngineIndex,:)), ...
            'LineWidth', 1.5, ...
            'Color', squeeze(inferenceColors(inferenceEngineIndex,:)));
    end
    
    function d  = getData()
        [d, the_rParams, noiseFreeResponse, theOI] = c_BanksEtAlPhotocurrentAndEyeMovements(...
            'opticsModel', opticsModel, ...
            'pupilDiamMm', pupilDiamMm, ...
            'cyclesPerDegree', cyclesPerDegreeExamined, ...
            'luminances', luminancesExamined, ...
            'nTrainingSamples', nTrainingSamples, ...
            'nContrastsPerDirection', nContrastsPerDirection, ...
            'lowContrast', lowContrast, ...
            'highContrast', highContrast, ...
            'ramPercentageEmployed', ramPercentageEmployed, ...
            'emPathType', emPathType, ...
            'centeredEMPaths', centeredEMPaths, ...
            'responseStabilizationMilliseconds', responseStabilizationMilliseconds, ...
            'responseExtinctionMilliseconds', responseExtinctionMilliseconds, ...
            'freezeNoise', freezeNoise, ...
            'integrationTime', integrationTimeMilliseconds/1000, ...
            'coneSpacingMicrons', mosaicParams.coneSpacingMicrons, ...
            'innerSegmentSizeMicrons', mosaicParams.innerSegmentDiameter, ...
            'conePacking', mosaicParams.conePacking, ...
            'LMSRatio', mosaicParams.LMSRatio, ...
            'mosaicRotationDegs', mosaicParams.mosaicRotationDegs, ...
            'computeMosaic', false, ...
            'visualizeMosaic', false, ...
            'computeResponses', false, ...
            'visualizeResponses', false, ...
            'visualizeSpatialScheme', visualizeSpatialScheme, ...
            'findPerformance', findPerformance, ...
            'visualizePerformance', visualizePerformance, ...
            'visualizeKernelTransformedSignals', visualizeTransformedSignals, ...
            'performanceSignal' , performanceSignal, ...
            'performanceClassifier', performanceClassifier, ...
            'useRBFSVMKernel', useRBFSVMKernel, ...
            'performanceTrialsUsed', nTrainingSamples, ...
            'spatialPoolingKernelParams', spatialPoolingKernelParams ...
            );
    end

end


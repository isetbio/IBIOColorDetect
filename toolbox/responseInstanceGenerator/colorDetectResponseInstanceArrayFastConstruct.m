function [responseStruct, osImpulseResponseFunctions, osImpulseReponseFunctionTimeAxis, osMeanCurrents] = ...
    colorDetectResponseInstanceArrayFastConstruct(stimulusLabel, nTrials, spatialParams, backgroundParams, colorModulationParams, temporalParams, theOI, theMosaic, varargin)
% [responseStruct, osImpulseResponseFunctions, osMeanCurrents] = colorDetectResponseInstanceArrayFastConstruct(stimulusLabel, nTrials, spatialParams, backgroundParams, colorModulationParams, temporalParams, theOI, theMosaic)
% 
% Construct an array of nTrials response instances given the
% simulationTimeStep, spatialParams, temporalParams, theOI, theMosaic.
%
% The noise free isomerizations response is returned for the first
% instance. NOTE THAT BECAUSE EYE MOVEMENT PATHS DIFFER ACROSS INSTANCES,
% THIS IS NOT THE SAME FOR EVERY INSTANCE.]
%
% Key/value pairs
%  'seed' - value (default 1). Random number generator seed
%   'workerID' - (default empty).  If this field is non-empty, the progress of
%            the computation is printed in the command window along with the
%            workerID (from a parfor loop).
%  'displayTrialBlockPartitionDiagnostics' -true/false (default false). Wether to report time elapsed for each block
%  'centeredEMPaths' - true/false (default false) or a string
%               Controls wether the eye movement paths start at (0,0) (default) or whether they are centered around (0,0)
%               If a string the two possible values are
%               'atStimulusModulationOnset', in which case, the em position is (0,0) at stimulus onset, OR
%               'atStimulusModulationMidPoint', in which case, the centroid of the emPath within the stimulation time is at (0,0)
%  'osImpulseResponseFunctions' - the LMS impulse response filters to be used (default: [])
%  'osMeanCurrents' - the steady-state LMS currents caused by the mean absorption LMS rates
%  'computePhotocurrentResponseInstances' - true/false (default true) wether to compute photocurrent response instances
%  'computeNoiseFreeSignals' - true/false (default true) wether to compute the noise free isomerizations and photocurrents
%  'useSinglePrecision' - true/false (default true) use single precision to represent isomerizations and photocurrent
%  'visualizeSpatialScheme' - true/false (default false) wether to co-visualize the optical image and the cone mosaic
%  'paramsList' - the paramsList associated for this direction (used for exporting response figures to the right directory)
% 7/10/16  npc Wrote it.

%% Parse arguments
p = inputParser;
p.addParameter('seed',1, @isnumeric);   
p.addParameter('workerID', [], @isnumeric);
p.addParameter('displayTrialBlockPartitionDiagnostics', false, @islogical);
p.addParameter('useSinglePrecision',true,@islogical);
p.addParameter('centeredEMPaths',false, @(x) (islogical(x) || (ischar(x))));
p.addParameter('theExpandedMosaic', []);
p.addParameter('osImpulseResponseFunctions', [], @isnumeric);
p.addParameter('osMeanCurrents', [], @isnumeric);
p.addParameter('computePhotocurrentResponseInstances', true, @islogical);
p.addParameter('computeNoiseFreeSignals', true, @islogical);
p.addParameter('visualizeDisplay', false, @islogical);
p.addParameter('visualizeSpatialScheme', false, @islogical);
p.addParameter('visualizeStimulusAndOpticalImage', false, @islogical);
p.addParameter('visualizeOIsequence', false, @islogical);
p.addParameter('visualizeMosaicWithFirstEMpath', false, @islogical);
p.addParameter('paramsList', {}, @iscell);
p.parse(varargin{:});
currentSeed = p.Results.seed;
theExpandedMosaic = p.Results.theExpandedMosaic;

%% Start computation time measurement
if (p.Results.displayTrialBlockPartitionDiagnostics)
    tic
end

%% Get pupil size out of OI, which is sometimes needed by colorSceneCreate
oiParamsTemp.pupilDiamMm = 1000*opticsGet(oiGet(theOI,'optics'),'aperture diameter');

%% Create the background scene
theBaseColorModulationParams = colorModulationParams;
theBaseColorModulationParams.coneContrasts = [0 0 0]';
theBaseColorModulationParams.contrast = 0;
[backgroundScene, ~, theDisplay] = colorSceneCreate(spatialParams, backgroundParams, ...
    theBaseColorModulationParams, oiParamsTemp);

%% Create the modulated scene
modulatedScene = colorSceneCreate(spatialParams, backgroundParams, ...
    colorModulationParams, oiParamsTemp);

%% Compute the background OI
oiBackground = theOI;
oiBackground = oiCompute(oiBackground, backgroundScene);

%% Compute the modulated OI
oiModulated = theOI;
oiModulated = oiCompute(oiModulated, modulatedScene);

%% Generate the stimulus modulation function
if (isnan(temporalParams.windowTauInSeconds))
    [stimulusTimeAxis, stimulusModulationFunction, ~] = squareTemporalWindowCreate(temporalParams);
else
    [stimulusTimeAxis, stimulusModulationFunction, ~] = gaussianTemporalWindowCreate(temporalParams);
end

%% Compute the oiSequence
if (strcmp(spatialParams.spatialType, 'pedestalDisk'))
    theOIsequence = oiSequence(oiBackground, oiModulated, stimulusTimeAxis, stimulusModulationFunction, ...
        'composition', 'xor');
else
    theOIsequence = oiSequence(oiBackground, oiModulated, stimulusTimeAxis, stimulusModulationFunction, ...
        'composition', 'blend');
end

%% Visualize the display
if (p.Results.visualizeDisplay)
    hFig = visualizeDisplayProperties(theDisplay, backgroundParams, modulatedScene);
    % Save figure
    theProgram = mfilename;
    rwObject = IBIOColorDetectReadWriteBasic;
    data = 0;
    fileName = sprintf('Display');
    rwObject.write(fileName, data, p.Results.paramsList, theProgram, ...
           'type', 'NicePlotExportPNG', 'FigureHandle', hFig, 'FigureType', 'png');
end

%%  Visualize the oiSequence
if (p.Results.visualizeOIsequence)
    uData = theOIsequence.visualize('montage', 'showIlluminanceMap', true, 'backendRenderer', 'figure');
    % Save figure
    theProgram = mfilename;
    rwObject = IBIOColorDetectReadWriteBasic;
    data = 0;
    fileName = sprintf('OISequence');
    rwObject.write(fileName, data, p.Results.paramsList, theProgram, ...
           'type', 'NicePlotExportPNG', 'FigureHandle', uData.figHandle, 'FigureType', 'png');
       
    % Also visualize the modulated scene luminance and retinal illuminance
    visualizeSceneLuminanceAndIlluminance(modulatedScene, oiModulated, p.Results.paramsList);
end

if (p.Results.visualizeStimulusAndOpticalImage)
    visualizeSceneAndOpticalImage(backgroundScene, modulatedScene, oiBackground, oiModulated, p.Results.paramsList);
end

%% Co-visualize the optical image and the cone mosaic
if (p.Results.visualizeSpatialScheme)
    [~, timeBinOfPeakModulation] = max(abs(stimulusModulationFunction));
    thePeakOI = theOIsequence.frameAtIndex(timeBinOfPeakModulation);
    maxIllumValueToDisplay = 10;  % set to [] to use the max from the illum map
    visualizeStimulusAndConeMosaic(theMosaic, thePeakOI, modulatedScene, p.Results.paramsList, 'maxIllumValueToDisplay', maxIllumValueToDisplay);
end
    
% Clear oiModulated and oiBackground to save space
varsToClear = {'backgroundScene', 'oiBackground'};
clear(varsToClear{:});

%% Compute number of eye movements
eyeMovementsNum = theOIsequence.maxEyeMovementsNumGivenIntegrationTime(theMosaic.integrationTime, ...
    'stimulusSamplingInterval', temporalParams.stimulusSamplingIntervalInSeconds);


%% Generate eye movement paths for all instances
[theEMpaths, theEMpathsMicrons] = colorDetectMultiTrialEMPathGenerate(...
    theMosaic, nTrials, eyeMovementsNum, temporalParams.emPathType, ...
    'centeredEMPaths', (islogical(p.Results.centeredEMPaths))&&(p.Results.centeredEMPaths), ... 
    'seed', currentSeed);
    
%% Special emPath centering - we use this when we want to center assymetrically, e.g., when the stimulus onset is not at zero
% This was needed in the photocurrent computation because we needed a warm-up period
if ischar(p.Results.centeredEMPaths)
    % Find time points at which stimulus in on
    idx = find(stimulusModulationFunction>0);
    timeOfStimOnset = stimulusTimeAxis(idx(1));
    timeOfStimOffset = stimulusTimeAxis(idx(end)) + temporalParams.stimulusSamplingIntervalInSeconds;
    stimulusMidTime = timeOfStimOnset + (timeOfStimOffset-timeOfStimOnset)/2;
    
    emPathTimeAxis = stimulusTimeAxis(1) + (0:(eyeMovementsNum-1)) * theMosaic.integrationTime;
    
    % Determine alignment time
    if (strcmp(p.Results.centeredEMPaths, 'atStimulusModulationMidPoint'))
        alignmentTime = stimulusMidTime;
        [~,tAlignmentBin] = min(abs(emPathTimeAxis-alignmentTime));
        
        % determine time bins over which we average position to find the center of the em path
        tRangeBins = round(0.5*temporalParams.stimulusDurationInSeconds/theMosaic.integrationTime);
        tBinsForAveraging = tAlignmentBin + [-tRangeBins:1:tRangeBins];
    
    elseif (strcmp(p.Results.centeredEMPaths, 'atStimulusModulationOnset'))
         alignmentTime = timeOfStimOnset;
         [~,tAlignmentBin] = min(abs(emPathTimeAxis-alignmentTime));
         tBinsForAveraging = tAlignmentBin;
    else
        error('Unknown alignemnt method: ''%s''.', p.Results.centeredEMPaths);
    end
    
    if (1==2)
                %fprintf('emPath should be 0 at t = %2.2f msec (time point: %d)', emPathTimeAxis(tAlignmentBin)*1000, tAlignmentBin);

                figure(100); clf;
                subplot(2,2,1);
                plot(emPathTimeAxis, squeeze(theEMpaths(:,:,1)), 'r-');
                hold on;
                plot(emPathTimeAxis, squeeze(theEMpaths(:,:,1))*0, 'k-');
                plot(emPathTimeAxis(tAlignmentBin)*[1 1], 100*[-1 1], 'k-');

                subplot(2,2,2);
                plot(emPathTimeAxis, squeeze(theEMpaths(:,:,2)), 'b-');
                hold on;
                plot(emPathTimeAxis, squeeze(theEMpaths(:,:,1))*0, 'k-');
                plot(emPathTimeAxis(tAlignmentBin)*[1 1], 100*[-1 1], 'k-');

                subplot(2,2,3);
                plot(emPathTimeAxis, squeeze(theEMpathsMicrons(:,:,1)), 'r-');
                hold on;
                plot(emPathTimeAxis, squeeze(theEMpaths(:,:,1))*0, 'k-');
                plot(emPathTimeAxis(tAlignmentBin)*[1 1], 100*[-1 1], 'k-');

                subplot(2,2,4);
                plot(emPathTimeAxis, squeeze(theEMpathsMicrons(:,:,2)), 'b-');
                hold on;
                plot(emPathTimeAxis, squeeze(theEMpaths(:,:,1))*0, 'k-');
                plot(emPathTimeAxis(tAlignmentBin)*[1 1], 100*[-1 1], 'k-');
                drawnow
    end
    
    % Recenter the emPaths
    emPathCenters = theEMpaths(:,tBinsForAveraging,:);
    emPathCenters = mean(emPathCenters,2);
    theEMpaths = bsxfun(@minus, theEMpaths, emPathCenters);
    % emPaths must be integered-valued, so round
    theEMpaths = round(theEMpaths);
    
    % Recenter the emPathsMicrons
    emPathMicronsCenters = theEMpathsMicrons(:,tBinsForAveraging,:);
    emPathMicronsCenters = mean(emPathMicronsCenters,2);
    % subtract them from the emPaths
    theEMpathsMicrons = bsxfun(@minus, theEMpathsMicrons, emPathMicronsCenters);    
    
    if (1==2)
                figure(101); clf;
                subplot(2,2,1);
                plot(emPathTimeAxis, squeeze(theEMpaths(:,:,1)), 'r-');
                hold on;
                plot(emPathTimeAxis, squeeze(theEMpaths(:,:,1))*0, 'k-');
                plot(emPathTimeAxis(tAlignmentBin)*[1 1], 100*[-1 1], 'k-');

                subplot(2,2,2);
                plot(emPathTimeAxis, squeeze(theEMpaths(:,:,2)), 'b-');
                hold on;
                plot(emPathTimeAxis, squeeze(theEMpaths(:,:,1))*0, 'k-');
                plot(emPathTimeAxis(tAlignmentBin)*[1 1], 100*[-1 1], 'k-');

                subplot(2,2,3);
                plot(emPathTimeAxis, squeeze(theEMpathsMicrons(:,:,1)), 'r-');
                hold on;
                plot(emPathTimeAxis, squeeze(theEMpaths(:,:,1))*0, 'k-');
                plot(emPathTimeAxis(tAlignmentBin)*[1 1], 100*[-1 1], 'k-');

                subplot(2,2,4);
                plot(emPathTimeAxis, squeeze(theEMpathsMicrons(:,:,2)), 'b-');
                hold on;
                plot(emPathTimeAxis, squeeze(theEMpaths(:,:,1))*0, 'k-');
                plot(emPathTimeAxis(tAlignmentBin)*[1 1], 100*[-1 1], 'k-');
                drawnow
    end
end
 

%% Generate theExpandedMosaic
padRows = max(max(abs(theEMpaths(:, :, 2))));
padCols = max(max(abs(theEMpaths(:, :, 1))));

if  ((isempty(theExpandedMosaic)) || ...
     (size(theExpandedMosaic.pattern,1) < theMosaic.rows + 2 * padRows) || ...
     (size(theExpandedMosaic.pattern,2) < theMosaic.cols + 2 * padCols))
    % We need a larger expandedMosaic to cover these emPaths
    theMosaic.absorptions = [];
    theMosaic.current = [];
    theMosaic.os.lmsConeFilter = [];
    theExpandedMosaic = theMosaic.copy();
    theExpandedMosaic.pattern = zeros(...
        theMosaic.rows + 2 * padRows, ...
        theMosaic.cols + 2 * padCols);
end

% Compute instances    
[isomerizations, photocurrents, osImpulseResponseFunctions, osMeanCurrents] = ...
     theMosaic.computeForOISequence(theOIsequence, ...
                    'stimulusSamplingInterval', temporalParams.stimulusDurationInSeconds, ...
                    'seed', currentSeed, ...
                    'theExpandedMosaic', theExpandedMosaic, ...
                    'emPaths', theEMpaths, ...
                    'interpFilters', p.Results.osImpulseResponseFunctions, ...
                    'meanCur', p.Results.osMeanCurrents, ...
                    'trialBlockSize', nTrials, ...
                    'currentFlag', p.Results.computePhotocurrentResponseInstances, ...
                    'workDescription', sprintf('%d trials of noisy responses', nTrials),...
                    'workerID', p.Results.workerID, ...
                    'beVerbose', false);

if (isempty(p.Results.osImpulseResponseFunctions))
    % Since we compute the impulse response functions, the 
    % mosaic.interpFilterTimeAxis has already being computed for us
    osImpulseReponseFunctionTimeAxis = theMosaic.interpFilterTimeAxis;
else
    % Since we do not compute the impulse response functions, the
    % mosaic.interpFilterTimeAxis is not computed, so compute it here
    osImpulseReponseFunctionTimeAxis = (0:(size(p.Results.osImpulseResponseFunctions,1)-1))*theMosaic.integrationTime;
end

isomerizationsTimeAxis = theMosaic.timeAxis + theOIsequence.timeAxis(1);
photoCurrentTimeAxis = isomerizationsTimeAxis;
 
%% Remove unwanted portions of the responses
isomerizationsTimeIndicesToKeep = find(abs(isomerizationsTimeAxis-temporalParams.secondsToIncludeOffset) <= temporalParams.secondsToInclude/2);
photocurrentsTimeIndicesToKeep = find(abs(photoCurrentTimeAxis-temporalParams.secondsToIncludeOffset) <= temporalParams.secondsToInclude/2);
if (isa(theMosaic , 'coneMosaicHex'))
     isomerizations = isomerizations(:,:,isomerizationsTimeIndicesToKeep);
     if (~isempty(photocurrents))
        photocurrents = photocurrents(:,:,photocurrentsTimeIndicesToKeep);
     end
else
     isomerizations = isomerizations(:,:,:,isomerizationsTimeIndicesToKeep);
     if (~isempty(photocurrents))
        photocurrents = photocurrents(:,:,:,photocurrentsTimeIndicesToKeep);
     end
end

%% Form the responseInstanceArray struct
if (p.Results.useSinglePrecision)
    responseStruct.responseInstanceArray.theMosaicIsomerizations = single(isomerizations);
    responseStruct.responseInstanceArray.theMosaicPhotocurrents = single(photocurrents);
else
    responseStruct.responseInstanceArray.theMosaicIsomerizations = isomerizations;
    responseStruct.responseInstanceArray.theMosaicPhotocurrents = photocurrents;
end
responseStruct.responseInstanceArray.theMosaicEyeMovements = theEMpaths(:,isomerizationsTimeIndicesToKeep,:);
responseStruct.responseInstanceArray.theMosaicEyeMovementsMicrons = theEMpathsMicrons(:,isomerizationsTimeIndicesToKeep,:);
responseStruct.responseInstanceArray.timeAxis = isomerizationsTimeAxis(isomerizationsTimeIndicesToKeep);
responseStruct.responseInstanceArray.photocurrentTimeAxis = photoCurrentTimeAxis(photocurrentsTimeIndicesToKeep);

if (p.Results.visualizeMosaicWithFirstEMpath)
    visualizedTrial = 1;
    visualizedTimeIndices = 1:size(responseStruct.responseInstanceArray.theMosaicEyeMovementsMicrons,2); % find(responseStruct.responseInstanceArray.timeAxis<100/1000);
    %emVisualizationTime = [responseStruct.responseInstanceArray.timeAxis(visualizedTimeIndices(1)) responseStruct.responseInstanceArray.timeAxis(visualizedTimeIndices(end))]
    hFig = theMosaic.visualizeGrid(...
        'overlayEMpathMicrons', squeeze(responseStruct.responseInstanceArray.theMosaicEyeMovementsMicrons(visualizedTrial,visualizedTimeIndices,:)), ...
        'apertureShape', 'disks', ...
        'visualizedConeAperture', 'geometricArea', ...
        'labelConeTypes', true,...
        'backgroundColor', [1 1 1], ...
        'generateNewFigure', true);
    % Save figure
    theProgram = mfilename;
    rwObject = IBIOColorDetectReadWriteBasic;
    data = 0;
    fileName = sprintf('MosaicAndFirstEMpath');
    rwObject.write(fileName, data, p.Results.paramsList, theProgram, ...
           'type', 'NicePlotExportPDF', 'FigureHandle', hFig, 'FigureType', 'pdf');
end

if (~p.Results.computeNoiseFreeSignals)
    responseStruct.noiseFreeIsomerizations = [];
    responseStruct.noiseFreePhotocurrents = [];
    return;
end

%% Compute the noise-free isomerizations & photocurrents
if strcmp(temporalParams.emPathType, 'frozen')
    % use the first emPath if we have a frozen path
    theEMpaths = theEMpaths(1,:,:);
else
    % use all zeros path otherwise
    theEMpaths = theEMpaths(1,:,:)*0;
end

% Save original noise flags
originalIsomerizationNoiseFlag = theMosaic.noiseFlag;
originalPhotocurrentNoiseFlag = theMosaic.os.noiseFlag;

% Set noiseFlags to none
theMosaic.noiseFlag = 'none';
theMosaic.os.noiseFlag = 'none';

% Compute the noise-free responses
[responseStruct.noiseFreeIsomerizations, responseStruct.noiseFreePhotocurrents] = ...
     theMosaic.computeForOISequence(theOIsequence, ...
                    'stimulusSamplingInterval', temporalParams.stimulusDurationInSeconds, ...
                    'theExpandedMosaic', theExpandedMosaic, ...
                    'emPaths',theEMpaths, ...
                    'interpFilters', p.Results.osImpulseResponseFunctions, ...
                    'meanCur', p.Results.osMeanCurrents, ...
                    'currentFlag', true, ...
                    'workDescription', 'noise-free responses', ...
                    'workerID', p.Results.workerID);

%% Remove unwanted portions of the noise-free responses
if (isa(theMosaic , 'coneMosaicHex'))
     responseStruct.noiseFreeIsomerizations = responseStruct.noiseFreeIsomerizations(:,:,isomerizationsTimeIndicesToKeep);
     responseStruct.noiseFreePhotocurrents = responseStruct.noiseFreePhotocurrents(:,:,photocurrentsTimeIndicesToKeep);
else
     responseStruct.noiseFreeIsomerizations = responseStruct.noiseFreeIsomerizations(:,:,:,isomerizationsTimeIndicesToKeep);
     responseStruct.noiseFreePhotocurrents = responseStruct.noiseFreePhotocurrents(:,:,:,photocurrentsTimeIndicesToKeep);
end

% Restore noiseFlags to none
theMosaic.noiseFlag = originalIsomerizationNoiseFlag;
theMosaic.os.noiseFlag = originalPhotocurrentNoiseFlag;


if (p.Results.visualizeStimulusAndOpticalImage)
    visualizeSceneOpticalImageAndMeanResponses(modulatedScene, oiModulated, theMosaic, responseStruct.noiseFreeIsomerizations, responseStruct.noiseFreePhotocurrents, p.Results.paramsList);
end

varsToClear = {'modulatedScene', 'oiModulated'};
clear(varsToClear{:});

% Store
responseStruct.noiseFreeIsomerizations = squeeze(responseStruct.noiseFreeIsomerizations);
if (~isempty(responseStruct.noiseFreePhotocurrents))
    responseStruct.noiseFreePhotocurrents = squeeze(responseStruct.noiseFreePhotocurrents);
end

% Save an RGB of the OI
[~, timeBinOfPeakModulation] = max(abs(stimulusModulationFunction));
 thePeakOI = theOIsequence.frameAtIndex(timeBinOfPeakModulation);
support = oiGet(thePeakOI, 'spatial support', 'microns');
micronsPerDegree = oiGet(thePeakOI, 'width')*1e6 / oiGet(thePeakOI, 'hfov');
responseStruct.thePeakOI.xAxisDegs = support(1,:,1)/micronsPerDegree;
responseStruct.thePeakOI.yAxisDegs = support(:,1,2)/micronsPerDegree;
responseStruct.thePeakOI.RGBimage = oiGet(thePeakOI, 'RGB image');

%% Report time taken
if (p.Results.displayTrialBlockPartitionDiagnostics)
    if isempty(p.Results.workerID)
        fprintf('<strong> Response instance array computation (%d instances) on worker %d took %2.3f minutes. </strong> \n', nTrials, toc/60);
    else
        fprintf('<strong> Response instance array computation (%d instances) in worker %d took %2.3f minutes. </strong> \n', nTrials, p.Results.workerID, toc/60);
    end
end
end
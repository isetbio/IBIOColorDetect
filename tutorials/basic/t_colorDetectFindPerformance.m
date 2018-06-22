function [validationData,extraData] = t_colorDetectFindPerformance(varargin)
% [validationData,extraData] = t_colorDetectFindPerformance(varargin)
%
% Classify data generated by
%   t_coneCurrentEyeMovementsResponseInstances.
% That tutorial generates multiple noisy instances of responses for color
% Gabors and saves them out.  Here we read the output and use an
% SVM to build a computational observer that gives us percent correct, and
% then do this for multiple contrasts.  The output of this tutorial can
% then be used by
%   t_colorGaborDetectThresholdsOnLMPlane
% to find and plot thresholds.
%
% See also
%   t_coneCurrentEyeMovementsResponseInstances,
%   t_colorGaborDetectIllustrateClassificationBoundary,
%   t_plotGabotDetectThresholdsOnLMPlane.
%
% Key/value pairs
%  'rParams' - Value the is the rParams structure to use.  Default empty,
%     which then uses defaults produced by generation function.
%   'testDirectionParams' - Value is the testDirectionParams structure to use
%   'thresholdParams' - Parameters related to how we find thresholds from responses
%   'freezeNoise'- true/false (default false).  Freezes all noise so that results are reproducible.
%     If there is no noise set, this leaves it alone.
%   'compute' - true/false (default true).  Do the computations.
%   'parforWorkersNum' - 0 .. 20 (default: 6). How many workers to use for the computations.
%       use 0: for a serial for loop
%       use > 0: for a parfor loop with desired number of workers
%   'generatePlots' - true/false (default true).  Produce any plots at
%      all? Other plot options only have an effect if this is true.
%   'visualizeSpatialScheme' - true/false (default false). Visualize the post-receptoral spatial pooling scheme
%   'visualizeKernelTransformedSignals' - true/false (default false). Visualize the output of the post-receptoral spatial pooling scheme
%   'plotPsychometric' - true/false (default false). Produce psychometric function output graphs.
%   'plotSvmBoundary' - true/false (default false).  Plot classification boundary
%   'plotPCAAxis1' - First PCA component to plot (default 1)
%   'plotPCAAxis2' - Second PCA component to plot (default 2)
%   'delete' - true/false (default true).  Delete the response instance
%        files.  Useful for cleaning up utput when we are done with
%        it.  If this is true, output files are deleted at the end.
%        Does not currently delete figures or parent directories, but maybe
%        it should.

%% Parse input
p = inputParser;
p.addParameter('rParams',[],@isemptyorstruct);
p.addParameter('testDirectionParams',[],@isemptyorstruct);
p.addParameter('thresholdParams',[],@isemptyorstruct);
p.addParameter('spatialPoolingKernelParams', struct(), @isstruct);
p.addParameter('freezeNoise',false,@islogical);
p.addParameter('compute',true,@islogical);
p.addParameter('parforWorkersNum', 10, @isnumeric);
p.addParameter('employStandardHostComputerResources', false, @islogical);
p.addParameter('generatePlots',true,@islogical);
p.addParameter('visualizeSpatialScheme', false, @islogical);
p.addParameter('visualizeKernelTransformedSignals', false, @islogical);
p.addParameter('visualizeVarianceExplained', false, @islogical);
p.addParameter('plotPsychometric',false,@islogical);
p.addParameter('plotSvmBoundary',false,@islogical);
p.addParameter('plotPCAAxis1',1,@isnumeric)
p.addParameter('plotPCAAxis2',2,@isnumeric)
p.addParameter('delete',false',@islogical);
p.addParameter('IBIOColorDetectSnapshot', struct(), @isstruct);

p.parse(varargin{:});
rParams = p.Results.rParams;
testDirectionParams = p.Results.testDirectionParams;
thresholdParams = p.Results.thresholdParams;

% Check the parforWorkersNum
parforWorkersNum = p.Results.parforWorkersNum;
[numberOfWorkers, ~, ~] = determineSystemResources(p.Results.employStandardHostComputerResources);
if (numberOfWorkers < parforWorkersNum)
    parforWorkersNum = numberOfWorkers;
end

fprintf('Classifying using %d workers\n', parforWorkersNum);

%% Clear
if (nargin == 0)
    ieInit; close all;
end

%% Get the parameters we need
%
% t_colorGaborResponseGenerationParams returns a hierarchical struct of
% parameters used by a number of tutorials and functions in this project.
if (isempty(rParams))
    rParams = responseParamsGenerate;
    
    % Override some defult parameters
    %
    % Set duration equal to sampling interval to do just one frame.
    rParams.temporalParams.stimulusDurationInSeconds = 200/1000;
    rParams.temporalParams.stimulusSamplingIntervalInSeconds = rParams.temporalParams.stimulusDurationInSeconds;
    rParams.temporalParams.secondsToInclude = rParams.temporalParams.stimulusDurationInSeconds;
    rParams.temporalParams.emPathType = 'none';
    
    rParams.mosaicParams.integrationTimeInSeconds = rParams.temporalParams.stimulusDurationInSeconds;
    rParams.mosaicParams.isomerizationNoise = 'random';     % Type coneMosaic.validNoiseFlags to get valid values
    rParams.mosaicParams.osNoise = 'random';                % Type outerSegment.validNoiseFlags to get valid values
    rParams.mosaicParams.osModel = 'Linear';
end

% Fix random number generator so we can validate output exactly
if (p.Results.freezeNoise)
     rng(1);
     if (strcmp(rParams.mosaicParams.isomerizationNoise, 'random'))
         rParams.mosaicParams.isomerizationNoise = 'frozen';
     end
     if (strcmp(rParams.mosaicParams.osNoise, 'random'))
         rParams.mosaicParams.osNoise = 'frozen';
     end
end

%% Parameters that define the LM instances we'll generate here
%
% Make these numbers small (trialNum = 2, deltaAngle = 180,
% nContrastsPerDirection = 2) to run through a test quickly.
if (isempty(testDirectionParams))
    testDirectionParams = instanceParamsGenerate;
end

%% Parameters related to how we find thresholds from responses
if (isempty(thresholdParams))
    thresholdParams = thresholdParamsGenerate;
end


%% Set up the rw object for this program
rwObject = IBIOColorDetectReadWriteBasic;
readProgram = 't_coneCurrentEyeMovementsResponseInstances';
writeProgram = mfilename;

constantParamsList = {rParams.topLevelDirParams, rParams.mosaicParams, rParams.oiParams, rParams.spatialParams,  rParams.temporalParams,  rParams.backgroundParams, testDirectionParams};


%% svmV1FilterBank - related checks and computations
if (~strcmp(rParams.mosaicParams.conePacking, 'hex')) && (~strcmp(rParams.mosaicParams.conePacking, 'hexReg')) && ... 
   ((strcmp(thresholdParams.method, 'svmV1FilterBank')))
    error('Currently, classification using the ''svmV1FilterBank'' method is only implemented for  hex mosaics.\n')
end

if (~strcmp(rParams.mosaicParams.conePacking, 'hex')) && (~strcmp(rParams.mosaicParams.conePacking, 'hexReg')) && ... 
   ((strcmp(thresholdParams.method, 'svmV1FilterEnsemble')))
    error('Currently, classification using the ''svmV1FilterEnsemble'' method is only implemented for  hex mosaics.\n')
end

if (~strcmp(rParams.mosaicParams.conePacking, 'hex')) && (~strcmp(rParams.mosaicParams.conePacking, 'hexReg')) && ...
   (strcmp(thresholdParams.method, 'svmGaussianRF'))
    error('Currently, classification using the ''svmGaussianRF'' method is only implemented for  hex mosaics.\n')
end

if (strcmp(thresholdParams.method, 'svmV1FilterBank'))
    % Generate V1 filter bank struct and add it to thresholdParams
    V1filterBank = generateV1FilterBank(rParams.spatialParams, rParams.mosaicParams, rParams.topLevelDirParams, p.Results.visualizeSpatialScheme, thresholdParams, constantParamsList);
    thresholdParams = modifyStructParams(thresholdParams, ...
        'spatialPoolingKernel', V1filterBank);
end

if (strcmp(thresholdParams.method, 'svmV1FilterEnsemble'))
    % Generate V1 filter ensemble struct and add it to thresholdParams
    V1filterEnsemble = generateV1FilterEnsemble(rParams.spatialParams, rParams.mosaicParams, rParams.topLevelDirParams, p.Results.visualizeSpatialScheme, thresholdParams, constantParamsList);
    thresholdParams = modifyStructParams(thresholdParams, ...
        'spatialPoolingKernel', V1filterEnsemble);
end

if (strcmp(thresholdParams.method, 'svmGaussianRF')) || (strcmp(thresholdParams.method, 'mlptGaussianRF'))
    gaussianPoolingKernel = generateSpatialPoolingKernel(rParams.spatialParams, rParams.mosaicParams, rParams.topLevelDirParams, p.Results.visualizeSpatialScheme, thresholdParams, constantParamsList);
    thresholdParams = modifyStructParams(thresholdParams, ...
        'spatialPoolingKernel', gaussianPoolingKernel);
end


%% Compute if desired
if (p.Results.compute)   
    % Inform the user regarding what we are currently working on
    if (strcmp(thresholdParams.method, 'svmV1FilterBank')) || (strcmp(thresholdParams.method, 'svmGaussianRF')) || (strcmp(thresholdParams.method, 'svmV1FilterEnsemble'))
        fprintf('Computing performance for <strong>%s</strong> emPaths using an <strong>%s</strong> classifier operating on the raw <strong>%s</strong>.\n', ...
        rParams.temporalParams.emPathType, thresholdParams.method, thresholdParams.signalSource);                  
    elseif (~strcmp(thresholdParams.method, 'mlpt'))
        fprintf('Computing performance for <strong>%s</strong> emPaths using an <strong>%s</strong> classifier operating on the first %d PCA components of <strong>%s</strong>.\n', ...
        rParams.temporalParams.emPathType, thresholdParams.method, thresholdParams.PCAComponents, thresholdParams.signalSource);                  
    else
        fprintf('Computing performance for <strong>%s</strong> emPaths using an <strong>%s</strong> classifier operating on  <strong>%s</strong>.\n', ...
    	rParams.temporalParams.emPathType, thresholdParams.method, thresholdParams.signalSource);                  
    end
    
    % Read data for the no stimulus condition
    fprintf('Reading no stimulus data ... \n');
    colorModulationParamsTemp = rParams.colorModulationParams;
    colorModulationParamsTemp.coneContrasts = [0 0 0]';
    colorModulationParamsTemp.contrast = 0;
    paramsList = constantParamsList;
    paramsList{numel(paramsList)+1} = colorModulationParamsTemp;
    clear 'colorModulationParamsTemp'
    ancillaryData = rwObject.read('ancillaryData',paramsList,readProgram);
    noStimData = rwObject.read('responseInstances',paramsList,readProgram);
    
    if (strcmp(thresholdParams.signalSource,'isomerizations'))
        noStimData.responseInstanceArray.theMosaicPhotocurrents = [];
    else
        noStimData.responseInstanceArray.theMosaicIsomerizations = [];
    end
    
    % Only keep the trials we will use
    if isfield(thresholdParams, 'trialsUsed')
        noStimData.responseInstanceArray = keepTrialsUsed(noStimData.responseInstanceArray, thresholdParams.trialsUsed);
    end

    % Only keep the time bins we will use
    if (~isempty(thresholdParams.evidenceIntegrationTime))
        [noStimData, thresholdParams.actualEvidenceIntegrationTime] = keepTimeBinsUsed(noStimData, thresholdParams.evidenceIntegrationTime);
    end
        
    % Get out some data we'll want
    nTrials = numel(noStimData.responseInstanceArray);
    testConeContrasts = ancillaryData.testConeContrasts;
    testContrasts = ancillaryData.testContrasts;
    
    % If everything is working right, rParams and ancillaryData.rParams
    % should be identical structs. Same for testDirectionParams and ancillaryParams.instanceParams
    % Check for that below.
    displayStructs = false;
    checkStructs('rParams', rParams, 'ancillaryParams-rParams', ancillaryData.rParams, 'ignoredFields', {'plotParams'}, 'displayStructs', displayStructs);
    checkStructs('testDirectionParams', testDirectionParams, 'ancillaryParams.instanceParams', ancillaryData.instanceParams, 'displayStructs', false);
    fprintf('done\n');
    
    tic
    parforConditionStructs = responseGenerationParforConditionStructsGenerate(testConeContrasts,testContrasts);
    for kk = 1:length(parforConditionStructs)
        thisConditionStruct = parforConditionStructs{kk};
        colorModulationParamsTemp = rParams.colorModulationParams;
        colorModulationParamsTemp.coneContrasts = thisConditionStruct.testConeContrasts;
        colorModulationParamsTemp.contrast = thisConditionStruct.contrast;
        paramsList = constantParamsList;
        paramsList{numel(paramsList)+1} = colorModulationParamsTemp;
        thisConditionStruct.paramsList = paramsList;
        parforConditionStructs{kk} = thisConditionStruct;
    end
    
    nParforConditions = length(parforConditionStructs);
    parforRanSeeds = randi(1000000,nParforConditions,1)+1;
    usePercentCorrect = zeros(size(testConeContrasts,2),1);
    useStdErr = zeros(size(testConeContrasts,2),1);
    rState = rng;
    
    %parfor (kk = 1:nParforConditions, parforWorkersNum)
    for kk = nParforConditions:-1:1
        
        rng(parforRanSeeds(kk));
        thisConditionStruct = parforConditionStructs{kk};
        paramsList = thisConditionStruct.paramsList;
        fprintf('Classifying data for condition %d of %d... \n', kk,nParforConditions);
        stimData = rwObject.read('responseInstances',paramsList,readProgram);
        
        if (strcmp(thresholdParams.signalSource,'isomerizations'))
            stimData.responseInstanceArray.theMosaicPhotocurrents = [];
        else
            stimData.responseInstanceArray.theMosaicIsomerizations = [];
        end
        
        % Only keep the data we will use
        if isfield(thresholdParams, 'trialsUsed')
            stimData.responseInstanceArray = keepTrialsUsed(stimData.responseInstanceArray, thresholdParams.trialsUsed);
        end
        
        % Only keep the time bins we will use
        if (~isempty(thresholdParams.evidenceIntegrationTime))
            [stimData, ~] = keepTimeBinsUsed(stimData, thresholdParams.evidenceIntegrationTime);
        end
        
        % Get performance for this condition.  Optional parameters control
        % whether or not the routine returns a handle to a plot that
        % illustrates the classifier.
        [usePercentCorrect(kk),useStdErr(kk),h, varianceExplained(kk,:)] = ...
            classifyForOneDirectionAndContrast(noStimData,stimData,thresholdParams, ...
            'paramsList', paramsList, ...
            'visualizeKernelTransformedSignals', p.Results.visualizeKernelTransformedSignals, ...
            'plotSvmBoundary', p.Results.generatePlots && p.Results.plotSvmBoundary, ...
            'plotPCAAxis1', p.Results.plotPCAAxis1, ...
            'plotPCAAxis2',p.Results.plotPCAAxis2);
        
        % Save classifier plot if we made one and then close the figure.
        if (p.Results.generatePlots && p.Results.plotSvmBoundary)
            paramsList{numel(paramsList)+1} = thresholdParams;
            rwObject.write(sprintf('svmBoundary_PCA%d_PCA%d',plotSvmPCAAxis1,plotSvmPCAAxis2), ...
                h,paramsList,writeProgram,'Type','figure');
            close(h);
        end
    end
    rng(rState);
    fprintf('Classification for all %d conditions took %2.2f minutes\n', nParforConditions, toc/60);
    clearvars('theData','useData','classificationData','classes');
    
    % Take the returned vector form of the performance data and put it back into the
    % matrix form we expect below and elsewhere.
    %
    % See function responseGenerationParforConditionStructsGenerate for how we
    % pack the conditions into the order that this unpacks.
    for kk = 1:nParforConditions
        thisConditionStruct = parforConditionStructs{kk};
        performanceData.percentCorrect(thisConditionStruct.ii,thisConditionStruct.jj) = usePercentCorrect(kk);
        performanceData.stdErr(thisConditionStruct.ii,thisConditionStruct.jj) = useStdErr(kk);
        performanceData.varianceExplained(thisConditionStruct.ii,thisConditionStruct.jj,:) = squeeze(varianceExplained(kk,:));
    end
    
    %% Tuck away other information that we want to store
    performanceData.IBIOColorDetectSnapshot = p.Results.IBIOColorDetectSnapshot;
    performanceData.testConeContrasts = testConeContrasts;
    performanceData.testContrasts = testContrasts;
    performanceData.rParams = rParams;
    performanceData.instanceParams = testDirectionParams;
    performanceData.thresholdParams = thresholdParams;
    clearvars('usePercentCorrect','useStdErr');
    
    %% Save classification performance data and a copy of this script
    fprintf('Writing performance data ... ');
    paramsList = constantParamsList;
    paramsList{numel(paramsList)+1} = thresholdParams;
    rwObject.write('performanceData',performanceData,paramsList,writeProgram);
    fprintf('done\n');
    
    %% Validation data
    if (nargout > 0)
        validationData.testConeContrasts = performanceData.testConeContrasts;
        validationData.testContrasts = performanceData.testContrasts;
        validationData.percentCorrect = performanceData.percentCorrect;
        validationData.stdErr = performanceData.stdErr;   
    end
    if (nargout > 1)
        extraData.rParams = performanceData.rParams;
        extraData.instanceParams = performanceData.instanceParams;
        extraData.thresholdParams = performanceData.thresholdParams;
    end
end

%% Plot performances obtained in each color direction as raw psychometric functions
if (p.Results.generatePlots && p.Results.plotPsychometric) 
    fprintf('Reading performance data ... ');
    paramsList = constantParamsList;
    paramsList{numel(paramsList)+1} = thresholdParams;
    performanceData = rwObject.read('performanceData',paramsList,writeProgram);
    fprintf('done\n');
    
    testConeContrasts = performanceData.testConeContrasts;
    testContrasts = performanceData.testContrasts;
    

    for ii = 1:size(testConeContrasts,2)
        hFig = figure; clf;
        errorbar(testContrasts, squeeze(performanceData.percentCorrect(ii,:)), squeeze(performanceData.stdErr(ii, :)), ...
            'ro-', 'LineWidth', rParams.plotParams.lineWidth, 'MarkerSize', rParams.plotParams.markerSize, 'MarkerFaceColor', [1.0 0.5 0.50]);
        axis 'square'
        set(gca,'XScale', 'log', 'YLim', [0 1.0],'XLim', [testContrasts(1) testContrasts(end)], 'FontSize', rParams.plotParams.axisFontSize);
        xlabel('contrast', 'FontSize' ,rParams.plotParams.labelFontSize, 'FontWeight', 'bold');
        ylabel('percent correct', 'FontSize' ,rParams.plotParams.labelFontSize, 'FontWeight', 'bold');
        box off; grid on
        if (isempty(thresholdParams.evidenceIntegrationTime))
             title(sprintf('LMS = [%2.2f %2.2f %2.2f]\nsignal = ''%s'', classifier = ''%s''\nemPath = ''%s''', ...
                 testConeContrasts(1,ii), testConeContrasts(2,ii), testConeContrasts(3,ii), ...
                 thresholdParams.signalSource, thresholdParams.method, rParams.temporalParams.emPathType), ...
                'FontSize',rParams.plotParams.titleFontSize);
        else
            title(sprintf('LMS = [%2.2f %2.2f %2.2f]\nsignal = ''%s'', classifier = ''%s''\nemPath = ''%s'', evidenceIntTime: %2.1f ms', ...
                 testConeContrasts(1,ii), testConeContrasts(2,ii), testConeContrasts(3,ii), ...
                 thresholdParams.signalSource, thresholdParams.method, rParams.temporalParams.emPathType, thresholdParams.actualEvidenceIntegrationTime), ...
                'FontSize',rParams.plotParams.titleFontSize);
        end
        rwObject.write(sprintf('performanceData_%d',ii),hFig,paramsList,writeProgram,'Type','figure');
    end
end

if (p.Results.visualizeVarianceExplained)
    fprintf('Reading performance data ... ');
    paramsList = constantParamsList;
    paramsList{numel(paramsList)+1} = thresholdParams;
    performanceData = rwObject.read('performanceData',paramsList,writeProgram);
    fprintf('done\n');
    
    if (isfield(performanceData, 'varianceExplained'))
        testConeContrasts = performanceData.testConeContrasts;
        testContrasts = performanceData.testContrasts;
        % Plot variance explained figure
        for ii = 1:size(testConeContrasts,2)
            hFig = figure(1200+ii-1); clf; 
            set(hFig, 'Position', [10 10 960 1260], 'Color', [1 1 1]);
            hold on;
            pcaIndices = 1:size(performanceData.varianceExplained,3);
            percentCorrect = squeeze(performanceData.percentCorrect(ii,:));
            legends = {};
            colors = brewermap(numel(testContrasts), '*Spectral');
            for contrastIndex = numel(testContrasts):-1:1
                variances = squeeze(performanceData.varianceExplained(ii,contrastIndex,:));
                plot(pcaIndices, cumsum(variances), 'ko-', ...
                    'MarkerSize', 6, 'MarkerFaceColor', squeeze(colors(contrastIndex,:)), ...
                    'MarkerFaceColor', squeeze(colors(contrastIndex,:)), ...
                    'Color', squeeze(colors(contrastIndex,:)), 'LineWidth', 1.5);
                legends{numel(legends)+1} = sprintf('contrast:%2.1e, %%correct:%2.0f)',testContrasts(contrastIndex),100.0*percentCorrect(contrastIndex));
            end
            hL = legend(legends, 'Location', 'SouthEast');
        end
        set(gca, 'XScale', 'log', 'YScale', 'log', ...
            'XLim', [1 numel(pcaIndices)], 'YLim', [0.1 100], ...
            'XTick', [1 10 60 100 600 1000], 'YTick', [0.1 1 10 100], 'FontSize', 18);
        xlabel('# of PCA components', 'FontWeight', 'bold');
        ylabel('cumulative response variance explained (%)', 'FontWeight', 'bold');
        title(sprintf('%d instances, %2.0f c/deg', thresholdParams.trialsUsed,rParams.spatialParams.cyclesPerDegree));
        box('on'); grid('on');
    else
       fprintf('Did not find varianceExplained field in performanceData. No plotting.\n'); 
    end
end

%% Delete output data if desired
%
% Doesn't delete figures.  
if (p.Results.delete)
    paramsList = constantParamsList;
    paramsList{numel(paramsList)+1} = thresholdParams;
    rwObject.delete('performanceData',paramsList,writeProgram);
end
end

% Function to check for struct equality
function checkStructs(struct1Name, struct1, struct2Name, struct2, varargin)

    %% Parse input
    p = inputParser;
    p.addParameter('ignoredFields',{},@iscell);
    p.addParameter('displayStructs', false);
    p.parse(varargin{:});

    % Deal with ignored fields
    ignoredFields = p.Results.ignoredFields;
    if (~isempty(ignoredFields))
        % Make ignoredFields empty
        for subFieldIndex = 1:numel(ignoredFields)
            struct1.(ignoredFields{subFieldIndex}) = [];
            struct2.(ignoredFields{subFieldIndex}) = [];
        end
    end
    
    if (p.Results.displayStructs)
        disp(UnitTest.displayNicelyFormattedStruct(struct1, struct1Name, '', 60));
        disp(UnitTest.displayNicelyFormattedStruct(struct2, struct2Name, '', 60));
    end

    graphMismatchedData = false;

    defaultTolerance = 1e-6;
    structCheck = RecursivelyCompareStructs(...
        struct1Name, struct1, ...
        struct2Name, struct2, ...
        'defaultTolerance', defaultTolerance, ...
        'graphMismatchedData', graphMismatchedData);
    
    if (~isempty(structCheck))
        % Oh oh, structs do not match. Print mismatched fields
        for k = 1:numel(structCheck)
            fprintf(2,'\t[%d]. %s\n', k, structCheck{k});
        end
        error('\n<strong>%s and %s are NOT identical structs. </strong>\n', struct1Name, struct2Name);
    else
        %fprintf('%s and %s are identical structs\n', struct1Name, struct2Name);
    end
end

function responseInstanceArray = keepTrialsUsed(responseInstanceArray, trialsUsed)
    if (~isempty(responseInstanceArray.theMosaicIsomerizations))
        fprintf('Classifying based on %d of the computed %d trials\n', trialsUsed, size(responseInstanceArray.theMosaicIsomerizations,1));
        responseInstanceArray.theMosaicIsomerizations = responseInstanceArray.theMosaicIsomerizations(1:trialsUsed,:,:,:);
    end
    if ~isempty(responseInstanceArray.theMosaicPhotocurrents)
        fprintf('Classifying based on %d of the computed %d trials\n', trialsUsed, size(responseInstanceArray.theMosaicPhotocurrents,1));
        responseInstanceArray.theMosaicPhotocurrents = responseInstanceArray.theMosaicPhotocurrents(1:trialsUsed,:,:,:);
    end
end

function [stimData, actualEvidenceIntegrationTime] = keepTimeBinsUsed(stimData, evidenceIntegrationTime)

    dt = stimData.responseInstanceArray.timeAxis(2)-stimData.responseInstanceArray.timeAxis(1);
    timeBinsToKeep = find(stimData.responseInstanceArray.timeAxis <= stimData.responseInstanceArray.timeAxis(1)+abs(evidenceIntegrationTime)/1000);
    if (evidenceIntegrationTime >= 0)
        % em1 -> emN
        actualEvidenceIntegrationTime = numel(timeBinsToKeep)*dt*1000;
    else
        % emN -> em1
        timeBinsToKeep = numel(stimData.responseInstanceArray.timeAxis) - timeBinsToKeep + 1;
        actualEvidenceIntegrationTime = -numel(timeBinsToKeep)*dt*1000;
    end
    
    if (~isempty(responseInstanceArray.theMosaicIsomerizations))
        responseDimensionality = ndims(stimData.responseInstanceArray.theMosaicIsomerizations);
    
        if (responseDimensionality == 2)
            % nTrials x cones - do nothing
        elseif (responseDimensionality == 3)
            % nTrials X non-null cones x time bins
            stimData.responseInstanceArray.theMosaicIsomerizations = stimData.responseInstanceArray.theMosaicIsomerizations(:,:,timeBinsToKeep);
            stimData.noiseFreeIsomerizations = stimData.noiseFreeIsomerizations(:,timeBinsToKeep);
        elseif (responseDimensionality == 4)
            % nTrials X cone rows x cone cols x time bins
            stimData.responseInstanceArray.theMosaicIsomerizations = stimData.responseInstanceArray.theMosaicIsomerizations(:,:,:,timeBinsToKeep);
            stimData.noiseFreeIsomerizations = stimData.noiseFreeIsomerizations(:,:,timeBinsToKeep);
        else
            error('Response dimensionality: %d', responseDimensionality);
        end
    end
    
    if (~isempty(responseInstanceArray.theMosaicPhotocurrents))
        responseDimensionality = ndims(stimData.responseInstanceArray.theMosaicPhotocurrents);
    
        if (responseDimensionality == 2)
            % nTrials x cones - do nothing
        elseif (responseDimensionality == 3)
            % nTrials X non-null cones x time bins
            stimData.responseInstanceArray.theMosaicPhotocurrents = stimData.responseInstanceArray.theMosaicPhotocurrents(:,:,timeBinsToKeep);
            stimData.noiseFreePhotocurrents = stimData.noiseFreePhotocurrents(:,timeBinsToKeep);
        elseif (responseDimensionality == 4)
            % nTrials X cone rows x cone cols x time bins
            stimData.responseInstanceArray.theMosaicPhotocurrents = stimData.responseInstanceArray.theMosaicPhotocurrents(:,:,:,timeBinsToKeep);
            stimData.noiseFreePhotocurrents = stimData.noiseFreePhotocurrents(:,:,timeBinsToKeep);
        else
            error('Response dimensionality: %d', responseDimensionality);
        end
    end
    
end



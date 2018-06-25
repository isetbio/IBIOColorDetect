function run_EyeMovementVaryConditions
% This is the script used to assess the impact of different types of eye movements on the CSF
%  
    % How to split the computation
    % 0 (All mosaics), 1; (Largest mosaic), 2 (Second largest), 3 (all 2 largest)
    computationInstance = 0;
    
    % Whether to make a summary figure with CSF from all examined conditions
    makeSummaryFigure = ~true;
    
    % Mosaic to use
    mosaicName = 'ISETbioHexEccBasedLMSrealisticEfficiencyCorrection'; 
    
    % Optics to use
    opticsName = 'ThibosAverageSubject3MMPupil';
    
    params = getCSFpaperDefaultParams(mosaicName, computationInstance);
    
    % Adjust any params we want to change from their default values
    params.opticsModel = opticsName;
    
    % All conds  with 2 mm pupilto compare to Banks subject data
    params.pupilDiamMm = 2.0;
    
    % Chromatic direction params
    params.coneContrastDirection = 'L+M+S';
  
    % Response duration params
    params.frameRate = 20; %(2 frames)
    params.responseStabilizationMilliseconds = 100;
    params.responseExtinctionMilliseconds = 50;
    
    defaultSpatialPoolingKernelParams = params.spatialPoolingKernelParams;
    
    condIndex = 0;
    
    
    condIndex = condIndex+1;

    
%     examinedCond(condIndex).emPathType = 'frozen0';
%     examinedCond(condIndex).classifier = 'svm';
%     examinedCond(condIndex).legend = 'no eye movements, SVM-PCA';
%     examinedCond(condIndex).centeredEMpaths = true;
%     examinedCond(condIndex).frameRate = 20; %(20 frames/sec, so 2 frames, each 50 msec long)
%     examinedCond(condIndex).responseStabilizationMilliseconds = 100;
%     examinedCond(condIndex).responseExtinctionMilliseconds = 50;
%     examinedCond(condIndex).spatialPoolingKernelParams = defaultSpatialPoolingKernelParams;

    
    condIndex = condIndex+1;
    examinedCond(condIndex).emPathType = 'random';
    examinedCond(condIndex).classifier = 'svm';
    examinedCond(condIndex).legend = 'drifts+\mu-sacc, SVM';
    examinedCond(condIndex).centeredEMpaths = ~true;
    examinedCond(condIndex).frameRate = 20; %(20 frames/sec, so 2 frames, each 50 msec long)
    examinedCond(condIndex).responseStabilizationMilliseconds = 100;
    examinedCond(condIndex).responseExtinctionMilliseconds = 50;
    examinedCond(condIndex).spatialPoolingKernelParams = defaultSpatialPoolingKernelParams;
    
%     condIndex = condIndex+1;
%     examinedCond(condIndex).emPathType = 'random';
%     examinedCond(condIndex).classifier = 'svmV1FilterBank';
%     examinedCond(condIndex).legend = 'drifts+\mu-sacc, SVM-TemplateQ';
%     examinedCond(condIndex).centeredEMpaths = ~true;
%     examinedCond(condIndex).frameRate = 20; %(20 frames/sec, so 2 frames, each 50 msec long)
%     examinedCond(condIndex).responseStabilizationMilliseconds = 100;
%     examinedCond(condIndex).responseExtinctionMilliseconds = 50;
%     examinedCond(condIndex).spatialPoolingKernelParams = defaultSpatialPoolingKernelParams;

    
     
%     condIndex = condIndex+1;
%     examinedCond(condIndex).emPathType = 'random';
%     examinedCond(condIndex).classifier = 'svmV1FilterEnsemble';
%     examinedCond(condIndex).legend = 'drifts+\mu-sacc. (rnd), SVM (v1RF-match QPhE(1.0))';
%     examinedCond(condIndex).centeredEMpaths = true;
%     examinedCond(condIndex).frameRate = 10;  %(20 frames/sec, so 2 frames, each 50 msec long)
%     examinedCond(condIndex).responseStabilizationMilliseconds = 40;
%     examinedCond(condIndex).responseExtinctionMilliseconds = 40; 
%     examinedCond(condIndex).spatialPoolingKernelParams = defaultSpatialPoolingKernelParams;
%     examinedCond(condIndex).spatialPoolingKernelParams.spatialPositionsNum = 9;
%     examinedCond(condIndex).spatialPoolingKernelParams.cyclesPerRFs = 1;
%     examinedCond(condIndex).spatialPoolingKernelParams.orientations = 0;
%     
%     condIndex = condIndex+1;
%     examinedCond(condIndex).emPathType = 'random';
%     examinedCond(condIndex).classifier = 'svmV1FilterEnsemble';
%     examinedCond(condIndex).legend = 'drifts+\mu-sacc. (rnd), SVM (v1RF-match QPhE(1.5))';
%     examinedCond(condIndex).centeredEMpaths = true;
%     examinedCond(condIndex).frameRate = 10;  %(20 frames/sec, so 2 frames, each 50 msec long)
%     examinedCond(condIndex).responseStabilizationMilliseconds = 40;
%     examinedCond(condIndex).responseExtinctionMilliseconds = 40; 
%     examinedCond(condIndex).spatialPoolingKernelParams = defaultSpatialPoolingKernelParams;
%     examinedCond(condIndex).spatialPoolingKernelParams.spatialPositionsNum = 9;
%     examinedCond(condIndex).spatialPoolingKernelParams.cyclesPerRFs = 1.5;
%     examinedCond(condIndex).spatialPoolingKernelParams.orientations = 0;
%     
%     condIndex = condIndex+1;
%     examinedCond(condIndex).emPathType = 'random';
%     examinedCond(condIndex).classifier = 'svmV1FilterEnsemble';
%     examinedCond(condIndex).legend = 'drifts+\mu-sacc. (rnd), SVM (v1RF-match QPhE(2.0))';
%     examinedCond(condIndex).centeredEMpaths = true;
%     examinedCond(condIndex).frameRate = 10;  %(20 frames/sec, so 2 frames, each 50 msec long)
%     examinedCond(condIndex).responseStabilizationMilliseconds = 40;
%     examinedCond(condIndex).responseExtinctionMilliseconds = 40; 
%     examinedCond(condIndex).spatialPoolingKernelParams = defaultSpatialPoolingKernelParams;
%     examinedCond(condIndex).spatialPoolingKernelParams.spatialPositionsNum = 9;
%     examinedCond(condIndex).spatialPoolingKernelParams.cyclesPerRFs = 2.0;
%     examinedCond(condIndex).spatialPoolingKernelParams.orientations = 0;
    
    
    % Simulation steps to perform
    params.computeMosaic = ~true; 
    params.visualizeMosaic = ~true;
    
    params.computeResponses = true;
    params.computePhotocurrentResponseInstances = true;
    
    params.visualizeResponses = ~true;
    params.visualizeSpatialScheme = ~true;
    params.visualizeOIsequence = ~true;
    params.visualizeOptics = ~true;
    params.visualizeStimulusAndOpticalImage = ~true;
    params.visualizeMosaicWithFirstEMpath = ~true;
    params.visualizeSpatialPoolingScheme = ~true;
    params.visualizeStimulusAndOpticalImage = ~true;
    params.visualizeDisplay = ~true;
    
    params.visualizeKernelTransformedSignals = ~true;
    params.findPerformance = ~true;
    params.visualizePerformance = true;
    params.deleteResponseInstances = ~true;
    
    
    % Go
    examinedEyeMovementTypeLegends = {};
    for condIndex = 1:numel(examinedCond)
        cond = examinedCond(condIndex);
        params.emPathType = cond.emPathType;
        params.centeredEMPaths = cond.centeredEMpaths;
        params.frameRate = cond.frameRate;
        params.responseStabilizationMilliseconds = cond.responseStabilizationMilliseconds;
        params.responseExtinctionMilliseconds = cond.responseExtinctionMilliseconds;
        params.performanceClassifier = cond.classifier;
        params.spatialPoolingKernelParams = cond.spatialPoolingKernelParams;

        examinedEyeMovementTypeLegends{condIndex} = cond.legend;
        [~,~, theFigData{condIndex}] = run_BanksPhotocurrentEyeMovementConditions(params);
    end
    
    if (makeSummaryFigure)
        variedParamName = 'EyeMovement';
        theRatioLims = [0.1 2];
        theRatioTicks = [0.1 0.2 0.5 1 2];
        generateFigureForPaper(theFigData, examinedEyeMovementTypeLegends, variedParamName, sprintf('%s_%s',mosaicName, opticsName), ...
            'figureType', 'CSF', ...
            'inGraphText', ' B ', ...
            'plotFirstConditionInGray', true, ...
            'plotRatiosOfOtherConditionsToFirst', true, ...
            'theRatioLims', theRatioLims, ...
            'theRatioTicks', theRatioTicks ...
            );
    end
end
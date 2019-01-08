function run_ConditionToVisualizePhotocurrentResponses
% This is the script used to just visualize responses

    % How to split the computation
    % 0 (All mosaics), 1; (Largest mosaic), 2 (Second largest), 3 (all but
    % the 2 largest), or some specific spatial frequency, like 16
    computationInstance = 16;
    

    % Pupil diameter to be used
    pupilDiamMm = 3.0;
    
    % Integration time to use, 2.5 is better for capturing fixationalEM dynamics
    integrationTimeMilliseconds = 5.0;
    
    params = getCSFPaper2DefaultParams(pupilDiamMm, integrationTimeMilliseconds, computationInstance);
    
    % Only the max contrast level
    params.lowContrast = 1.0; 
    params.highContrast =  1.0; 
    params.nContrastsPerDirection = 1;
    params.nTrainingSamples = 4;
        
    
    % Simulation steps to perform
    params.computeResponses = true;
    params.computeMosaic = ~true; 
    params.visualizeMosaic = ~true;
    
    params.computePhotocurrentResponseInstances = true;
    params.visualizeDisplay = ~true;
    params.visualizeResponses = true;
    params.visualizeSpatialScheme = ~true;
    params.visualizeOIsequence = ~true;
    params.visualizeOptics = ~true;
    params.visualizeStimulusAndOpticalImage = ~true;
    params.visualizeSpatialPoolingScheme = ~true;
    params.visualizeMosaicWithFirstEMpath = ~true;
    
    params.visualizeKernelTransformedSignals = true;
    params.findPerformance = ~true;
    params.visualizePerformance = ~true;
    params.deleteResponseInstances = ~true;
    
    % Go
    run_BanksPhotocurrentEyeMovementConditions(params);
end
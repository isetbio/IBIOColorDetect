function c_PoirsonAndWandell96RunSession()
% Conduct batch runs using the c_PoirsonAndWandel executive script
%
    % How many instances to generate
    nTrainingSamples = 32; %1024;
    
    nContrastsPerDirection = 8;
    
    % Freeze photon-isomerization & photocurrent noise
    freezeNoise = false;
    
    % Compute the hex-mosaic or use existing one
    computeMosaic = true;
    
    % Size of cone mosaic
    coneMosaicFOVDegs = 0.25; %1.25;
    
    % Conditions to examine
    % Full set of conditions
    [emPathTypesList, stimParamsList, classifierSignalList, classifierTypeList] = assembleFullConditionsSet();
    
    % Or override some, such as:
    emPathTypesList = {'random'};
    
    stimParamsList = {...
        struct('spatialFrequency', 10, 'meanLuminance', 200) ...
    };

    % performance params to examine
    classifierSignalList = {'isomerizations', 'photocurrents'};
    classifierTypeList = {'svmV1FilterBank'};
    
    % Actions to perform
    computeResponses   = true;
    visualizeSpatialScheme = true;
    visualizeResponses = ~true;
    findPerformances   = true;
    visualizePerformances = ~true;
    
    % Go !
    batchJob(computeMosaic, computeResponses, visualizeSpatialScheme, visualizeResponses, findPerformances, visualizePerformances, ...
        nContrastsPerDirection, nTrainingSamples, freezeNoise,  coneMosaicFOVDegs, emPathTypesList, stimParamsList, ...
        classifierSignalList, classifierTypeList);
    
    if (1==2)
        % Optionally, assess performance as a function of integrated response
        % Response integration times (in milliseconds) to examine
        evidenceIntegrationTimes = ([6 18 30 48 60 78 90 108 120 138 150 168 186 210]-1); % (5:10:250); %-([6 18 30 48 60 78 90 108 120 138 150 168 186 210]-1); % (5:10:250);
        evidenceIntegrationTimes = ([6 18 30 48 60 90 120 150 186 210]-1);
        % Stimulus & performance params to examine
        spatialFrequency = 10;
        meanLuminance = 200;
        emPathType = 'frozen0';
        classifier = 'mlpt';
        performanceSignal = 'isomerizations';
        
        findPerformancesForDifferentEvidenceIntegrationTimes(...
            spatialFrequency, meanLuminance, nTrainingSamples, ...
            emPathType, classifier, performanceSignal, ...
            evidenceIntegrationTimes);
    end
    
end


function batchJob(computeMosaic, computeResponses, visualizeSpatialScheme, visualizeResponses, findPerformances, visualizePerformances, ...
        nContrastsPerDirection, nTrainingSamples, freezeNoise, coneMosaicFOVDegs, emPathTypesList, stimParamsList, classifierSignalList, classifierTypeList)

    % Start timing
    tBegin = clock;    
    
    % Only compute the mosaic once
    mosaicAlreadyComputed = false;
        
    for emPathTypeIndex = 1:numel(emPathTypesList)
        % Get the emPathType
        emPathType = emPathTypesList{emPathTypeIndex};
        
        for stimConditionIndex = 1:numel(stimParamsList)
            % Get the stim params
            params = stimParamsList{stimConditionIndex};
            
            % Compute responses
            if (computeResponses) || (visualizeResponses)
                 % Inform the user regarding what we are currently working on
                 fprintf('Computing/visualizing responses for %2.2f c/deg, %d cd/m2 with ''%s'' emPaths.\n', ...
                            params.spatialFrequency, params.meanLuminance, emPathType);
                    
                 if (mosaicAlreadyComputed)
                     computeMosaic = false;
                 end
                 
                 c_PoirsonAndWandell96Replicate(...
                    'spatialFrequency', params.spatialFrequency, ...
                    'meanLuminance', params.meanLuminance, ...
                    'nContrastsPerDirection', nContrastsPerDirection, ...
                    'nTrainingSamples', nTrainingSamples, ...
                    'emPathType', emPathType, ...
                    'freezeNoise', freezeNoise, ...
                    'computeMosaic', computeMosaic, ...
                    'coneMosaicFOVDegs', coneMosaicFOVDegs, ...
                    'computeResponses', computeResponses, ...
                    'visualizeResponses', visualizeResponses, ...
                    'visualizeSpatialScheme', visualizeSpatialScheme , ...
                    'findPerformance', false);
                
                 mosaicAlreadyComputed = true;
            end % if (computeResponses)
            
            % Find/visualize performance
            if (findPerformances) || (visualizePerformances)
                for classifierTypeIndex = 1:numel(classifierTypeList)
                    % Get the classifier name
                    classifierTypeName = classifierTypeList{classifierTypeIndex};
                    for classifierSignalIndex = 1:numel(classifierSignalList)
                        % Get the signal name on which to measure performance
                        performanceSignalName = classifierSignalList{classifierSignalIndex};
                        if (~strcmp(performanceSignalName, 'isomerizations')) && (strcmp(classifierTypeName, 'mlpt'))
                            fprintf(2,'Finding performance using an <strong>%s</strong> classifier on <strong>%s</strong> is not feasible. Skipping...\n', classifierTypeName, performanceSignalName);
                            continue;
                        end
                        % Inform the user regarding what we are currently working on
                        fprintf('Finding/visualizing performance for <strong>%2.2f c/deg, %d cd/m2</strong> with <strong>%s</strong> emPaths using an <strong>%s</strong> classifier operating on <strong>%s</strong>.\n', ...
                            params.spatialFrequency, params.meanLuminance, emPathType, classifierTypeName, performanceSignalName);
                        
                        c_PoirsonAndWandell96Replicate(...
                            'spatialFrequency', params.spatialFrequency, ...
                            'meanLuminance', params.meanLuminance, ...
                            'nContrastsPerDirection', nContrastsPerDirection, ...
                            'nTrainingSamples', nTrainingSamples, ...
                            'emPathType', emPathType, ...
                            'freezeNoise', freezeNoise, ...
                            'coneMosaicFOVDegs', coneMosaicFOVDegs, ...
                            'computeResponses', false, ...
                            'visualizeResponses', false, ...
                            'findPerformance', findPerformances, ...
                            'visualizePerformance', visualizePerformances, ...
                            'performanceSignal', performanceSignalName, ...
                            'performanceClassifier', classifierTypeName ...
                            );  % findPerformances
                        
                    end % classifierSignalIndex
                end % classifierTypeIndex
            end % if (findPerformances) || (visualizePerformances)
            
        end % stimConditionIndex
    end % emPathTypeIndex
    
    tEnd = clock;
    timeLapsed = etime(tEnd,tBegin);
    fprintf('BATCH JOB: Completed in %.2f hours. \n', timeLapsed/60/60);
end

function [emPathTypesList, stimParamsList, ...
         classifierSignalList, classifierTypeList] = assembleFullConditionsSet()

    % emPathTypes to compute/analyze
    emPathTypesList = {'frozen0', 'frozen', 'random'};
    
    % stimParams to compute/analyze
    stimParamsList = {...
        struct('spatialFrequency', 2, 'meanLuminance', 20) ...
        struct('spatialFrequency', 2, 'meanLuminance', 200) ...
        struct('spatialFrequency', 10, 'meanLuminance', 200) ...
    };

    % performance params to examine
    classifierSignalList = {'isomerizations', 'photocurrents'};
    classifierTypeList = {'mlpt', 'svm', 'svmV1FilterBank'};
end


% Method to assess performance as a function of the included response duration
function findPerformancesForDifferentEvidenceIntegrationTimes(...
    spatialFrequency, meanLuminance, nTrainingSamples, ...
    emPathType, classifier, performanceSignal, ...
    evidenceIntegrationTimes)

    for k = 1:numel(evidenceIntegrationTimes)
        evidenceIntegrationTime = evidenceIntegrationTimes(k);
        fprintf(2, 'Finding performance for ''%s'' EMpaths using an %s classifier operating on %2.1f milliseconds of the %s signals.\n', emPathType, classifier, evidenceIntegrationTime, performanceSignal);
        c_PoirsonAndWandell96Replicate(...
                'spatialFrequency', spatialFrequency, ...
                'meanLuminance', meanLuminance, ...
                'nTrainingSamples', nTrainingSamples, ...
                'computeResponses', false, ...
                'emPathType', emPathType, ...
                'visualizeResponses', false, ...
                'findPerformance', true, ...
                'performanceSignal', performanceSignal, ...
                'performanceClassifier', classifier, ...
                'performanceEvidenceIntegrationTime', evidenceIntegrationTime ....
                );
    end % k
    
    % And the the full time course
    c_PoirsonAndWandell96Replicate(...
                'spatialFrequency', spatialFrequency, ...
                'meanLuminance', meanLuminance, ...
                'nTrainingSamples', nTrainingSamples, ...
                'computeResponses', false, ...
                'emPathType', emPathType, ...
                'visualizeResponses', false, ...
                'findPerformance', true, ...
                'performanceSignal', performanceSignal, ...
                'performanceClassifier', classifier, ...
                'performanceEvidenceIntegrationTime', [] ....
                );       
end

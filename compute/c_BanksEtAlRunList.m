% c_BanksEtAlRunList
%
% Run the Banks et al. computations with various set parameters.

% Clear and close
clear; close all;

% Common parameters
params.computeResponses = true;
params.findPerformance = true;
params.fitPsychometric = true;
params.thresholdMethod = 'mlpt';
params.nTrainingSamples = 2000;

params.useScratchTopLevelDirName = false;

params.conePacking = 'hexReg';
params.mosaicRotationDegs = 30;
params.coneSpacingMicrons = 3;
params.innerSegmentSizeMicrons = params.coneSpacingMicrons;
params.coneDarkNoiseRate = [0 0 0];
params.LMSRatio = [0.67 0.33 0];
params.cyclesPerDegree = [10 20 30 40 50 60];
params.luminances = [3.4 34 340];
params.pupilDiamMm = 2;
params.thresholdCriterionFraction = 0.701;
params.highContrast = 1;
params.freezeNoise = true;
params.computeResponses = false;
params.generatePlots = true;
params.plotCSF = true;
params.visualizeResponses = false;

% % No blur, no dark noise, no aperture blur
% params.blur = false;
% params.apertureBlur = false;
% params.coneDarkNoiseRate = [0 0 0];
% c_BanksEtAlReplicate(params);
% 
% % No blur, no dark noise, with aperture blur
% params.blur = false;
% params.apertureBlur = true;
% params.coneDarkNoiseRate = [0 0 0];
% c_BanksEtAlReplicate(params);
% 
% % With blur, no dark noise, with aperture blur
% params.blur = true;
% params.apertureBlur = true;
% params.coneDarkNoiseRate = [0 0 0];
% c_BanksEtAlReplicate(params);

% With blur, no dark noise, with aperture blur and Davila-Geisler lsf taken as psf optics
params.blur = true;
params.apertureBlur = true;
params.coneDarkNoiseRate = [0 0 0];
params.opticsModel = 'GeislerLsfAsPsf';
c_BanksEtAlReplicate(params);
params = rmfield(params,'opticsModel');

% With blur, no dark noise, with aperture blur and Davila-Geisler optics
params.blur = true;
params.apertureBlur = true;
params.coneDarkNoiseRate = [0 0 0];
params.opticsModel = 'Geisler';
c_BanksEtAlReplicate(params);
params = rmfield(params,'opticsModel');

% % With blur, no dark noise, with aperture blur and Davila-Geisler optics
% params.blur = true;
% params.apertureBlur = true;
% params.coneDarkNoiseRate = [0 0 0];
% params.opticsModel = 'DavilaGeislerLsfAsPsf';
% c_BanksEtAlReplicate(params);
% params = rmfield(params,'opticsModel');
% 
% % Let's go to a space varying hex mosaic and put the S cones back in
% % and stick in some dark noise
% params.blur = true;
% params.apertureBlur = true;
% params.LMSRatio = [0.62 0.31 0.07];
% params.coneDarkNoiseRate = [300 300 300];
% params.conePacking = 'hex';
% if (isfield(params,'innerSegmentSizeMicrons'))
%     params = rmfield(params,'innerSegmentSizeMicrons');
% end
% if (isfield(params,'coneSpacingMicrons'))
%     params = rmfield(params,'coneSpacingMicrons');
% end
% c_BanksEtAlReplicate(params);
% 
% % SVM version of the above, 50 components
% params.computeResponses = false;
% params.findPerformance = false;
% params.thresholdMethod = 'svm';
% params.thresholdPCA = 50;
% params.blur = true;
% params.apertureBlur = true;
% params.LMSRatio = [0.62 0.31 0.07];
% params.coneDarkNoiseRate = [300 300 300];
% params.conePacking = 'hex';
% if (isfield(params,'innerSegmentSizeMicrons'))
%     params = rmfield(params,'innerSegmentSizeMicrons');
% end
% if (isfield(params,'coneSpacingMicrons'))
%     params = rmfield(params,'coneSpacingMicrons');
% end
% c_BanksEtAlReplicate(params);
% 
% % SVM version of the above, 5 components
% params.computeResponses = false;
% params.findPerformance = false;
% params.thresholdMethod = 'svm';
% params.thresholdPCA = 5;
% params.blur = true;
% params.apertureBlur = true;
% params.LMSRatio = [0.62 0.31 0.07];
% params.coneDarkNoiseRate = [300 300 300];
% params.conePacking = 'hex';
% if (isfield(params,'innerSegmentSizeMicrons'))
%     params = rmfield(params,'innerSegmentSizeMicrons');
% end
% if (isfield(params,'coneSpacingMicrons'))
%     params = rmfield(params,'coneSpacingMicrons');
% end
% c_BanksEtAlReplicate(params);

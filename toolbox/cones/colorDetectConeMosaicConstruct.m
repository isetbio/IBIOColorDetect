function theMosaic = colorDetectConeMosaicConstruct(mosaicParams, varargin)
% colorDetectConeMosaicConstruct  Construct cone mosaic according to parameters structure
%   theMosaic = colorDetectConeMosaicConstruct(mosaicParams)
% 
% Construct a cone mosaic according to the passed parameters structure.
% Designed to allow us to control exactly what features of early vision
% we're using.
% 
%
% Key/Value pairs
%       'visualizeMosaic' - true/false (default true). Wether to visualize the cone mosaic
%
%
% 07/9/16  npc, dhb  Wrote it.
% 12/8/16  npc       Update it after linearized os model.

%% Parse arguments
p = inputParser;
p.addParameter('visualizeMosaic',true, @islogical);   
p.parse(varargin{:});
visualizeMosaic = p.Results.visualizeMosaic;

if (ischar(mosaicParams.conePacking))
    if (strcmp(mosaicParams.conePacking, 'hex'))
        resamplingFactor = 6;
        centerInMM = [0.0 0.0];                    % mosaic eccentricity in MM - this should obey mosaicParams.eccentricityDegs, but it does not do so yet
        spatiallyVaryingConeDensity = true;        % spatially-varying density (at the mosaic's eccentricity)
        theMosaic = coneMosaicHex(resamplingFactor, spatiallyVaryingConeDensity, [], ...
            'center', centerInMM*1e-3, ...
            'spatialDensity', [0 mosaicParams.LMSRatio]', ...
            'rotationDegs', mosaicParams.mosaicRotationDegs ...
            );
        
        % Set the pigment light collecting dimensions
        theMosaic.pigment.pdWidth = mosaicParams.innerSegmentSizeMicrons*1e-6;
        theMosaic.pigment.pdHeight = mosaicParams.innerSegmentSizeMicrons*1e-6;
        
    elseif (strcmp(mosaicParams.conePacking, 'hexReg'))
        resamplingFactor = 6;
        centerInMM = [0.0 0.0];                    % mosaic eccentricity in MM - this should obey mosaicParams.eccentricityDegs, but it does not do so yet
        spatiallyVaryingConeDensity = false;        % spatially-varying density (at the mosaic's eccentricity)
        
        % match cone-spacing to inner segment diameter
        customLambda = mosaicParams.coneSpacingMicrons;
        theMosaic = coneMosaicHex(resamplingFactor, spatiallyVaryingConeDensity, customLambda, ...
            'center', centerInMM*1e-3, ...
            'spatialDensity', [0 mosaicParams.LMSRatio]', ...
            'rotationDegs', mosaicParams.mosaicRotationDegs ...
            );
        
        % Set the pigment light collecting dimensions
        theMosaic.pigment.pdWidth = mosaicParams.innerSegmentSizeMicrons*1e-6;
        theMosaic.pigment.pdHeight = mosaicParams.innerSegmentSizeMicrons*1e-6;
        
        % Set the pigment geometric dimensions
        theMosaic.pigment.width = customLambda*1e-6;
        theMosaic.pigment.height = customLambda*1e-6;
        
    elseif (strcmp(mosaicParams.conePacking, 'rect'))
        % Construct a cone mosaic with rectangular cone packing
        theMosaic = coneMosaic();
        theMosaic.spatialDensity = [0 mosaicParams.LMSRatio]';
        
        % Set the pigment collecting area   
        theMosaic.pigment.pdWidth = mosaicParams.innerSegmentSizeMicrons*1e-6;
        theMosaic.pigment.pdHeight = mosaicParams.innerSegmentSizeMicrons*1e-6;
        
        % Set the pigment geometric dimensions
        theMosaic.pigment.width = mosaicParams.coneSpacingMicrons*1e-6;
        theMosaic.pigment.height = mosaicParams.coneSpacingMicrons*1e-6;
    else
        mosaicParams.conePacking
        error('Unknown conePacking value');
    end
else
    mosaicParams.conePacking
    error('Unknown conePacking value');
end

% Set whether to blur by cone aperture
theMosaic.apertureBlur = mosaicParams.apertureBlur;

% Set dark noise
theMosaic.coneDarkNoiseRate = mosaicParams.coneDarkNoiseRate;

% Set the outer segment model
if strcmp(mosaicParams.osModel, 'Linear')
    theMosaic.os = osLinear();
end

% Set mosaic field of view.  In principle this would be as large as the
% stimulus, but space and time considerations may lead to it being smaller.
if (isfield(mosaicParams, 'fieldOfViewDegs'))
    if (isa(theMosaic, 'coneMosaicHex'))
        theMosaic.setSizeToFOVForHexMosaic(mosaicParams.fieldOfViewDegs);
        if ((isfield(mosaicParams, 'realisticSconeSubmosaic')) && (mosaicParams.realisticSconeSubmosaic == true))
            theMosaic.reassignConeIdentities(...
                'sConeMinDistanceFactor', 3.0, ...   % min distance between neighboring S-cones = f * local cone separation, to make the S-cone lattice semi-regular
                'sConeFreeRadiusMicrons', 45);       % 45/300 = 0.15, so S-cone free radius of 0.15 deg (0.3 deg diameter)
        end
        if (visualizeMosaic)
            theMosaic.visualizeGrid(); % 'visualizedConeAperture', 'geometricArea');
        end
        theMosaic.displayInfo();
    else
        theMosaic.setSizeToFOV(mosaicParams.fieldOfViewDegs);
    end
end

% Integration time
if (isfield(mosaicParams, 'integrationTimeInSeconds'))
    theMosaic.integrationTime = mosaicParams.integrationTimeInSeconds;
end

% Outer-segment time step
if (isfield(mosaicParams, 'osTimeStep'))
    if (mosaicParams.osTimeStepInSeconds > 1/1000)
        error('Cannot set os.timeStepto %2.4f. It must be less t<= to 1/1000, and preferably <= 0.5/1000', mosaicParams.osTimeStepInSeconds);
    end
    theMosaic.os.timeStep = mosaicParams.osTimeStepInSeconds;
end

% Isomerization noise
if (isfield(mosaicParams, 'isomerizationNoise'))
    theMosaic.noiseFlag = mosaicParams.isomerizationNoise;
end

% Outer segment noise
if (isfield(mosaicParams, 'osNoise'))
    theMosaic.os.noiseFlag = mosaicParams.osNoise;
end
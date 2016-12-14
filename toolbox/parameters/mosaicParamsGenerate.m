function mosaicParams = mosaicParamsGenerate(varargin)
% mosaicParams = mosaicParamsGenerate(varargin)
%
% Properties of the cone mosaic set here.
%  macular - Boolean, include macular pigment (may not be implemeted yet)
%  LMSRatio - Vector giving L, M, S cone ratio
%  osModel - What model to use to compute photocurrent
%  conePacking - Type of cone mosaic
%    'rect' - rectangular
%    'hex' - hexagonal-like
%
% Other parameters that are needed for the mosaic are
%  fieldOfViewDegs - Field of view computed
%
% See also
%   responseParametersGenerate

mosaicParams.type = 'Mosaic';

mosaicParams.conePacking = 'rect';
mosaicParams.macular = true;
mosaicParams.LMSRatio = [0.62 0.31 0.07];
mosaicParams.eccentricityDegs = 0;
mosaicParams.integrationTimeInSeconds = 10/1000;
mosaicParams.osTimeStepInSeconds = 0.1/1000;
mosaicParams.isomerizationNoise = 'none';           % Type coneMosaic.validNoiseFlags to get valid values
mosaicParams.osModel = 'Linear';
mosaicParams.osNoise = 'random';                    % Type outerSegment.validNoiseFlags to get valid values
mosaicParams.emPathType = 'none';                   % Select from {'random','frozen', or 'none'}.
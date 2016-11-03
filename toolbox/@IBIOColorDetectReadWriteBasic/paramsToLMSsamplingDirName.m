function dirname = paramsToLMSsamplingDirName(obj,params)
% dirname = paramsToLMSsamplingDirName(obj,params)
% 
% Generate a directory names that captures the session parameters.


if (~strcmp(params.type,'LMSsampling'))
    error('Incorrect parameter type passed');
end

dirname = sprintf('[LMS_SPACE_SAMPLING]_azimuth%2.0f_elevation%2.0f_stimStrengthAxis(%0.3f_%0.3f_%0.0f)_instancesNum%0.0f',...
                params.azimuthAngle, ...
                params.elevationAngle, ...
                100.0*params.stimulusStrengthAxis(1), ...
                100.0*params.stimulusStrengthAxis(end), ...
                numel(params.stimulusStrengthAxis), ...
                params.instancesNum ...
                );
end




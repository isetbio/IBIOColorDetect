function dirname = paramsToResponseGenerationDirName(obj,params)
% dirname = paramsToResponseGenerationDirName(obj,params)
% 
% Generate a directory names that captures the basic LMPlane instance generation
% parameters.

if (~strcmp(params.type,'Instance'))
    error('Incorrect parameter type passed');
end

switch(params.instanceType)
    case 'LMPlane'
        theLMPlaneInstanceName = sprintf('LMPlane_%0.0f_%0.0f_%0.0f_con%0.0f_%0.5f_%0.3f_nt%0.0f',...
            params.startAngle,...
            params.deltaAngle,...
            params.nAngles,...
            params.nContrastsPerDirection, ...
            params.lowContrast, ...
            params.highContrast, ...
            params.trialsNum ...
            );
        dirname = theLMPlaneInstanceName;
    case 'contrasts'
        theContrastInstanceName = sprintf('Contrasts_con%0.0f_%0.5f_%0.3f_nt%0.0f',...
            params.nContrastsPerDirection, ...
            params.lowContrast, ...
            params.highContrast, ...
            params.trialsNum ...
            );
        dirname = theContrastInstanceName;
    otherwise
        error('Unknown instance type passed');
end




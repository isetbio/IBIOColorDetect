function theEMpaths = colorDetectMultiTrialEMPathGenerate(theConeMosaic, nTrials, eyeMovementsPerTrial, emPathType)
% theEMpaths = colorDetectEMPathGenerate(theConeMosaic, nTrials, eyeMovementsPerTrial, emPathType)
%
% Create an array of EMpaths, one for each of the nTrials, depending on
% eyeMovementPath parameter
%
%  11/30/16  npc Wrote it.
%
switch (emPathType)
    case 'Zero'
        theEMpaths = zeros(nTrials, eyeMovementsPerTrial, 2);     
    case 'Frozen'
        theFixedEMpath = theConeMosaic.emGenSequence(eyeMovementsPerTrial);
        theEMpaths = permute(repmat(theFixedEMpath, [1 1 nTrials]), [3 1 2]);
    case 'Dynamic'
        theEMpaths = zeros(nTrials, eyeMovementsPerTrial, 2);
        for iTrial= 1:nTrials
            theEMpaths(iTrial, :,:) = theConeMosaic.emGenSequence(eyeMovementsPerTrial);
        end
    otherwise
        error('Unknown emPathType: ''%s''. Valid choices: ''Zero'', ''Frozen'', ''Dynamic''.', emPathType);
end
end
function generateLargeMosaicInSteps
    
    mosaicParams = struct(...
        'resamplingFactor', 7, ...
        'fovDegs', 15, ...
        'LMSRatio', [0.60 0.30 0.10], ...
        'sConeMinDistanceFactor', 3, ...
        'sConeFreeRadiusMicrons', 45, ...
        'latticeAdjustmentPositionalToleranceF', 0.01, ...
        'latticeAdjustmentDelaunayToleranceF', 0.001, ...
        'queryGridAdjustmentIterations', 100, ...           % Pass Inf, to avoid querying
        'maxGridAdjustmentIterations', 10000, ...
        'marginF', []...
    );
            
    theMosaic = coneMosaicHex(mosaicParams.resamplingFactor, ...                     
        'fovDegs',                       mosaicParams.fovDegs, ...                   
        'spatialDensity',                [0 mosaicParams.LMSRatio]', ...
        'sConeMinDistanceFactor',        mosaicParams.sConeMinDistanceFactor, ...
        'sConeFreeRadiusMicrons',        mosaicParams.sConeFreeRadiusMicrons, ... 
        'eccBasedConeDensity',           true, ...                                  % cone density varies with eccentricity
        'eccBasedConeQuantalEfficiency', true, ...                                  % cone quantal efficiency varies with eccentricity
        'latticeAdjustmentPositionalToleranceF',mosaicParams.latticeAdjustmentPositionalToleranceF, ...   
        'latticeAdjustmentDelaunayToleranceF',  mosaicParams.latticeAdjustmentDelaunayToleranceF, ...
        'marginF',                              mosaicParams.marginF, ...
        'queryGridAdjustmentIterations',        mosaicParams.queryGridAdjustmentIterations, ...
        'maxGridAdjustmentIterations',          mosaicParams.maxGridAdjustmentIterations);
    
    theMosaic.visualizeGrid();
    
end
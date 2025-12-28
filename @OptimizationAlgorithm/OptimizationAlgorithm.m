classdef (HandleCompatible) OptimizationAlgorithm < handle
    
    %% Input SCU
    properties
        % parallel version: false or 0, true or otherwise
        parRuns logical = false; %true;       
        % Define pop_ini to force initial evaluation of this population. Values
        % must be in real limits, otherwise pop_ini must be empty
        pop_ini         = [];
        % Maximum number of experiments or evaluations
        maxIter         = 2; 
        % ncomp: number of complexes (sub-pop.)- between 2 and 20
        ngs             = 2;
        % verbose mode: false or 0, true or otherwise
        verbose         = 0;
        % Error 
        peps            = 0.001;
        % the initial parameter array at the start;
        x0              = []
        % the lower bound of the parameters
        bl
        % the upper bound of the parameters
        bu
    end           
    
    methods
        
        %% Shuffled Complex Evolution (SCE-UA) METHOD
        [bestx,bestf,allbest,allEvals] = sce(Basin)
        
        [bestx,bestf,allbest,allEvals] = Opt_LHS(Basin)
        %% GLUE - Sensitivity analysis
        [bestx,bestf,allbest,allEvals] = Opt_DDS(Basin)
        [best, allbest, solution] = dds(Basin)
        
    end
end
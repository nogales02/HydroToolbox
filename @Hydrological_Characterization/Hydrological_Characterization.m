classdef Hydrological_Characterization %< HydroTools_TimeSeries & Stokos    
    
    %% Methods    
    methods               
        %% Duration Curve, IRH and Environmental Flow
        [Fig, QA, IRH] = DurationCurve_IRH_EnvironmentalFlow(obj, Q)   
        
        %% Summary Hydrological Regime
        Summary_HydrologicalRegime_Month(obj, varargin)
        
        %% Return Period
        ReturnPeriod(obj, varargin)
        
        %%
        Step_1_QAmb_Q95(obj, varargin)
        
        Step_2_QAmb_7Q10(obj, varargin)
    end
end
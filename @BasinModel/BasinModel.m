classdef BasinModel < ClassNetwork & OptimizationAlgorithm & HydroTools_TimeSeries &  HydroSignature  

    %% Input Data
    properties
        % Area (m2)
        BasinArea(:,1) double 
        % Floodplains Area (m2)
        FloodArea(:,1) double         
        % BaseFlow (m3/seg)
        Qsim double    
        % Runoff (mm)
        Esc double  
        % NameModel
        NameModel string = 'GR4J';
        % Basin Parameters
        ParamsBasin double
        ParamsBasinCal double
        % Floodplains Parameters
        ParamsFlood double
        ParamsFloodCal double
        % Seed Paramters Optimization
        ParamsSeed double
        % Observation Flow (m3/seg)
        Qobs double
        % IDGauges
        GaugesID double
        % Gauges Calibration
        GaugesCal double
        % Group Calibartion
        GroupCal(:,1) double
        % Similary Parameters
        Simil_Params(:,1) double
        % ID Demand
        ID_Demand(:,1) double
        % ID Returns
        ID_Return(:,1) double    
        % Demand
        Demands double
        % Returns
        Returns double
        % ArcID River Mouth Basin
        RiverMouthBasin(:,1) double        
    end           
    
    %% Calibration
    properties
        % Variable States Flood
        StatesFlood
        % Variable States Basin
        StatesBasin        
    end
    
    %% Calibration
    properties
        % Date Calibration
        DateCal_Init
        DateCal_End
        % Date Validation 
        DateVal_Init
        DateVal_End
        % DateInit Calibration
        PorcCal
        % Date Days
        PorcOmit
        % Limit Parameters
        RangeParamsBasin
        % Limit Parameters
        RangeParamsFlood
        % Max iteration
        MaxIter
        % Name metric calibration
        CalMetric
        % UserData for optimization script
        UserData
        %
        CalMetricSelect        
    end
    
    % Temporal Properties
    properties
        % Category
        CatGauges
        % RiverMouth ArcID Gauges
        ArIDGauges
        % PoPo
        PoPo logical
        % IDPoPo
        IDPoPo logical
        % PosiQObs
        CodeQobs
        CodePoPo
    end
    
    % Geometric Basin 
    properties
        % X
        XBasin
        % RiverMouth ArcID Gauges
        YBasin
        % PoPo
        BoundingBox
    end
    
    %% Status model
    properties
        Status_ModelFlood       = false;
        OptMethod char          = 'LHS'
    end
    
    %% Reservoir
    properties
        Status_ModelReservoir   = false;
        Reservoir_Level
        Reservoir_Vol
        Reservoir_MaxLevel
        Gasto_Level
        Gasto_Q
    end

    % Lectura de datos
    methods
        % Datos climáticos
        LoadClimate(Basin)
        % Datos de demanda y retornos
        LoadDemandsReturns(Basin)
        % Datos de configuración
        LoadConfigure(Basin)
        % Parámetros
        LoadParams(Basin)
        % Topología de la cuenca
        LoadTopology(Basin, varargin)
        % Datos observados
        LoadQobs(Basin) 
        % Datos inicialespar optimizaci�n
        LoadSeedOpt(Basin)
    end
    
    methods                        
        %% Clip SubBasin
        obj = ClipSubBasin(obj, PoNet)        
        
        %% Interpolation Field
        Values = InterpolationField_Basin(obj, TimeSeriesGauges, Method, Var, PathDEM, varargin)                  
        Values = InterpolationField_Basin_Tester(obj, TimeSeriesGauges, Method, Var, PathDEM, varargin)

        %% Function Obj
        Metric_Cal = Function_Obj(obj, Parms,varargin);
        
        %% Plot Eval Model
        [Fig, Summary, ResultsModel] = Plot_Eval_Model(obj, DateInit, DateEnd)
        
        %% Write 
        WriteData_BasinModel(obj, NameVar)
        
        %% Calibration Model
        CalibrationModel(Basin)
%         [bestx,bestf,allbest,allEvals,...
%           Fig_Cal, Summary_Cal, ResultsModel_Cal,...
%           Fig_Val, Summary_Val, ResultsModel_Val] = CalibrationModel(obj)
        Matrics = EstimationMetric(obj, Qobs, Qsim)               
        
        %% Incertirbumre
        % Glue
        UncertantyAnalysis_GLUE(obj)

        %% Summary Hydrological Regime
        Summary_HydrologicalRegime_Day(obj, varargin)
        Summary_HydrologicalRegime_Day_Volumen(obj, varargin)
        
        %% Duration Curve, IRH and Environmental Flow
        [Fig, QA, IRH] = DurationCurve_IRH_EnvironmentalFlow(obj, Q)   
        
        %% Summary Hydrological Regime
        Summary_HydrologicalRegime_Month(obj, varargin)       

        %% Return Period
        ReturnPeriod(obj, varargin)       
        
        %% Periodo de Retorno No Estacionario
        ReturnPeriod_NoEst(obj1, varargin)

        %% Caudal Ambiental Q1
        Step_1_QAmb_Q95(obj, varargin)
        
        %% Caudal Ambiental 7Q10
        Step_2_QAmb_7Q10(obj, varargin)
       
    end
end
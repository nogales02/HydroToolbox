classdef (HandleCompatible) HydroSignature < handle & HydroTools_TimeSeries
    properties   
        % Precipitation (mm)
        P double
        % Evapotranspiration (mm)
        ETP double
        % Evaporation (mm)
        EV double
        % Temperature (°C)
        T double
        % Caudales (m3/s)
        Q double
        % Signature
        HySig
    end
    
    methods
        function obj = HydroSignature(varargin)
            warning off            
            % Ruta de donde se ejecuta el código
            PathHydroSig = fileparts(mfilename('fullpath'));
            try
                % Agregar ruta de funciones de firmas hidrologicas
                addpath(genpath(fullfile(PathHydroSig,'Hydrological_Signature')))                
                addpath(genpath(fullfile(PathHydroSig,'Utility')))
            catch
                
            end
        end
    end
    
    %% Cálculo de firmas hidrológicas
    methods
        % Cálculo de todas las firmas
        Signature = HydroSig_All(Obj, Q, P, Date, varargin)
        % Cálculo de firmas para representatividad
        Signature = HydroSig_Representativeness(Obj, varargin)
    end
end
% classdef ClassNetwork
classdef (HandleCompatible) ClassNetwork < handle
% -------------------------------------------------------------------------
% Matlab Version - R2018b 
% -------------------------------------------------------------------------
%                              BASE DATA 
%--------------------------------------------------------------------------
% Author        : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Occupation    : Hydrology Specialist
% Company       : The Nature Conservancy - TNC
% Date          : October, 2018
%
%--------------------------------------------------------------------------
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the 
% Free Software Foundation, either version 3 of the License, or option) any 
% later version. This program is distributed in the hope that it will be 
% useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
% ee the GNU General Public License for more details. You should have 
% received a copy of the GNU General Public License along with this program
% If not, see http://www.gnu.org/licenses/.
%--------------------------------------------------------------------------
%                               DESCRIPTION 
%--------------------------------------------------------------------------
% This object represent a topological network 
%
%--------------------------------------------------------------------------
%                               INPUT DATA 
%--------------------------------------------------------------------------
%   n = it is the section number that haves the topological network
%
%   ID          [n,1] = ID of the River Sections (Ad)
%   FromNode    [n,1] = Initial Node of the River Sections (Ad)
%   ToNode      [n,1] = End Node of the River Sections (Ad)
%   RiverMouth  [1,1] = ID of the River Sections corresponding to the River 
%                       Mouth (Ad)                    
%
%--------------------------------------------------------------------------
%                              OUTPUT DATA 
%--------------------------------------------------------------------------
% ClassNetwork [Object] = This object contain a topological network 

    %% Properties
    % Properties of the topological network
    properties        
        % ID of the River Sections (Ad)
        Code(:,1) double
        % Initial Node of the River Sections (Ad)
        FromNode(:,1) double
        % End Node of the River Sections (Ad)
        ToNode(:,1) double
        % ArcID of the River Sections corresponding to the River Mouth (Ad)
        RiverMouth(:,1) double
        % Barrier
        Barrier(:,1) double        
    end
    
    % Variables para el análisis network orientado a objetos
    properties  
        % Varibles para propagar
        ProVar double
        % Variables para acumular
        AccumVar double
        % Variables para acumular con retenciones
        AccumClipVar double
        % Tasa de perdida
        LossRate double
        % Variables acumuladas con perdida
        AccumLossVar double
        % Variables acumuladas con perdida y retenciones
        AccumClipLossVar double
        % Estado de función
        StatusFun(1,1) logical = false
        % Function        
        FunNetwork_1 char = ';'
        % Function        
        FunNetwork_2 char = ';'
    end
    
    methods
        %% Analysis Network - Versión Inicial
        [FuncNetwork, varargout]    = AnalysisNetwork_Original(obj, varargin);        

        %% Analysis Network - Versión para manejo de gran volumenes de datos
        % Para ejecutar esta función, es necesario crear un .mat con las
        % variables a analizar.
        % Ejemplo
        % -----------------------------------------------------------------
        % BigDataPath               = 'C:\DataBase_Network_BigData';
        % BigData                   = matfile(BigDataPath,'Writable',true);
        % BigData.ProVar            = [];
        % BigData.AccumVar          = [];
        % BigData.AccumClipVar      = [];
        % BigData.AccumLossVar      = [];
        % BigData.AccumClipLossVar  = [];        
        [FuncNetwork, varargout]    = AnalysisNetwork_BigData(obj, BigDataPath, Barrier); 
        
        %% Analysis Network - Considerando varaibles globales
        [FuncNetwork, varargout]    = AnalysisNetwork_Global(obj, varargin)
        
        %% Analysis Network - Optimizada a objetos
        [FuncNetwork, varargout]    = AnalysisNetwork_Obj(obj, varargin)        
        [FuncNetwork,PoNet]         = FunctionalBranch(obj,ArcID_RM,ArcID_RM_i,CurrID,PoNet)
    end

end
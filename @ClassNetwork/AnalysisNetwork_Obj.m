function [FuncNetwork, varargout] = AnalysisNetwork_Obj(obj, varargin)
% -------------------------------------------------------------------------
% Matlab Version - R2018b 
% -------------------------------------------------------------------------
%                              BASE DATA 
% -------------------------------------------------------------------------
% Author        : Jonathan Nogales Pimentel
% Email         : jonathan.nogales@tnc.org
% Occupation    : Hydrology Specialist
% Company       : The Nature Conservancy - TNC
% Date          : October, 2018
%
% -------------------------------------------------------------------------
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the 
% Free Software Foundation, either version 3 of the License, or option) any 
% later version. This program is distributed in the hope that it will be 
% useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
% ee the GNU General Public License for more details. You should have 
% received a copy of the GNU General Public License along with this program
% If not, see http://www.gnu.org/licenses/.
% -------------------------------------------------------------------------
%                               DESCRIPTION 
% -------------------------------------------------------------------------
% 
% -------------------------------------------------------------------------
% INPUTS DATA
% -------------------------------------------------------------------------
% Network [Struct]
%   .ArcID            [n,1] = ID of the River Sections (Ad)
%   .FromNode         [n,1] = Initial Node of the River Sections (Ad)
%   .ToNode           [n,1] = End Node of the River Sections (Ad)
%   .ArcID_RM         [1,1] = ArcID of the River Sections corresponding to 
%                             the River Mouth (Ad)
% ProVar              [n,w] = Varaibles to Progate
% AccumVar            [n,m] = Varaibles to Acumulated
% AccumClipVar        [n,h] = Varaibles to Accumulate with Clipping
% LossRateVar         [n,k] = Varaibles with Loss Rate (%)
% AccumLossVar        [n,h] = Varaibles to Accumulate with Losses
% AccumClipLossVar    [n,l] = Varaibles to Accumulate with Losses and Clipping
%
% -------------------------------------------------------------------------
%                              OUTPUT DATA 
% -------------------------------------------------------------------------
% FuncNetwork         [n,r] = ID of the Functional Network by Barrier. 
% ProVarOut           [n,w] = Propagated Variables
% AccumVarOut         [n,m] = Cumulative Variables
% AccumClipVarOut     [n,h] = Cumulative Variables With Clipping
% AccumLossVarOut     [n,k] = Cumulative Variables With Losses
% AccumClipLossVarOut [n,h] = Cumulative Variables With Losses and Clipping
% PoNet               [n,1] = Position of the Network in one River Sections 
%                             Special
%
set(0,'RecursionLimit',40000)

% -------------------------------------------------------------------------
% Barrier
% -------------------------------------------------------------------------
if ~isempty(obj.Barrier)
    n = length(obj.Barrier(:,1)) - length(obj.Code);
    if n ~= 0 
        error('The length of "Barrier" does not match the stretches of the topological network');
    end
else
    obj.Barrier = zeros(length(obj.Code),1);
end    

% -------------------------------------------------------------------------
% Variables to propagate
% -------------------------------------------------------------------------
if ~isempty(obj.ProVar)
    n = length(obj.ProVar(:,1)) - length(obj.Code);
    if n ~= 0 
        error('The length of "ProVar" does not match the stretches of the topological network');
    end
end    

% -------------------------------------------------------------------------
% Variables to accumulate
% -------------------------------------------------------------------------
if ~isempty(obj.AccumVar)
    n = length(obj.AccumVar(:,1)) - length(obj.Code);
    if n ~= 0 
        error('The length of "AccumVar" does not match the stretches of the topological network');
    end
end    

% -------------------------------------------------------------------------
% Variables to accumulate with clipping 
% -------------------------------------------------------------------------
if ~isempty(obj.AccumClipVar)
    n = length(obj.AccumClipVar(:,1)) - length(obj.Code);
    if n ~= 0 
        error('The length of "AccumClipVar" does not match the stretches of the topological network');
    end
end    

% -------------------------------------------------------------------------
% Variables to accumulate with losses
% -------------------------------------------------------------------------
if ~isempty(obj.LossRate)
    n = length(obj.LossRate) - length(obj.Code);
    if n ~= 0 
        error('The length of "LossRate" does not match the stretches of the topological network');
    end
    n = sum((obj.LossRate > 100) & (obj.LossRate < 1));
    if n ~= 0 
        error('LossRate greater than 0 and smaller than 100');
    end
end
if ~isempty(obj.AccumLossVar)
    n = length(obj.AccumLossVar(:,1)) - length(obj.Code);
    if n ~= 0 
        error('The length of "AccumLossVar" does not match the stretches of the topological network');
    end
end    

% -------------------------------------------------------------------------
% Variables to accumulate with clipping and losses
% -------------------------------------------------------------------------
if ~isempty(obj.LossRate)
    n = length(obj.LossRate) - length(obj.Code);
    if n ~= 0 
        error('The length of "LossRate" does not match the stretches of the topological network');
    end
    n = sum((obj.LossRate > 100) & (obj.LossRate < 1));
    if n ~= 0 
        error('LossRate greater than 0 and smaller than 100');
    end
end
if ~isempty(obj.AccumClipLossVar)
    n = length(obj.AccumClipLossVar(:,1)) - length(obj.Code);
    if n ~= 0 
        error('The length of "AccumClipLossVar" does not match the stretches of the topological network');
    end
end    
        
%% FunctionalBranch
% Currenct ID 
CurrID      = zeros(1,length(obj.Barrier(1,:)));
PoNet       = obj.Code*0;
FuncNetwork = obj.Barrier*0;
for i = 1:length(obj.RiverMouth)
    [FuncNetwork_i,O6] = obj.FunctionalBranch( obj.RiverMouth(i),...                                                  
                                                  obj.RiverMouth(i),...
                                                  CurrID,...
                                                  PoNet);


    FuncNetwork      = FuncNetwork + FuncNetwork_i;
    PoNet            = PoNet + O6;
end

% AccumClipLossVarOut
varargout{1} = PoNet;

end


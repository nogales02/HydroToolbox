%% Functional Branch
function [  FuncNetwork,PoNet] = ...
            FunctionalBranch(   obj,... 
                                ArcID_RM,...                                            
                                ArcID_RM_i,...
                                CurrID,...
                                PoNet)
% -------------------------------------------------------------------------
% /usr/bin/Matlab-R2018b
% -------------------------------------------------------------------------
%                               BASE DATA 
% -------------------------------------------------------------------------
% Author        : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
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
% received a copy of the GNU General Public License along with this program.  
% If not, see http://www.gnu.org/licenses/.
% -------------------------------------------------------------------------
%                              DESCRIPTION
% -------------------------------------------------------------------------
% Function that calculates: Fragmentation, Accumulation and Propagation of a 
% topological fluvial obj. These analyzes allow us to characterize the 
% fluvial network, to later evaluate the cumulative impacts of a set of 
% infrastructure works such as reservoirs, dams, etc., located in a fluvial 
% network, in terms of loss of Free Rivers, effects downstream by modification 
% of the regime of flows and sediments, among others.
%
% -------------------------------------------------------------------------
% INPUTS DATA
% -------------------------------------------------------------------------
% Network [Struct]
%   .ArcID              [n,1] = ID of the River Sections (Ad)
%   .FromNode           [n,1] = Initial Node of the River Sections (Ad)
%   .ToNode             [n,1] = End Node of the River Sections (Ad)
%   .ArcID_RM           [1,1] = ArcID of the River Sections corresponding to 
%                               the River Mouth (Ad)
%   .ProVar             [n,w] = Variables to Propagate
%   .AccumVar           [n,m] = Variables to Accumulate
%   .AccumClipVar       [n,k] = Variables to Accumulate with Clipping
%   .AccumLossVar       [n,h] = Variables to Accumulate with Losses
%   .AccumClipLossVar   [n,l] = Variables to Accumulate with Losses and Clipping
%   .ArcBarrier         [n,1] = ArcID of the River Sections with Barriers (Ad)
%   .CurrID             [1,1] = ID of the Functional obj.                                      
%   .LossRate           [n,1] = Loss Rate (%)
%
% -------------------------------------------------------------------------
% OUTPUTS DATA
% -------------------------------------------------------------------------
%   FuncNetwork         [n,1] = ID of the Functional Network by Barrier. 
%   ProVarOut           [n,w] = Propagated Variables
%   AccumVarOut         [n,m] = Cumulative Variables
%   AccumClipVarOut     [n,h] = Cumulative Variables With Clipping
%   AccumLossVarOut     [n,k] = Cumulative Variables With Losses
%   AccumClipLossVarOut [n,h] = Cumulative Variables With Losses and Clipping
%   PoNet               [n,1] = Position of the Network in one River Sections 
%                               Special
%
%--------------------------------------------------------------------------
%                              REFERENCES
%--------------------------------------------------------------------------
% - Authors of base Code : Hector Angarita
% 
%--------------------------------------------------------------------------

FuncNetwork         = 0 * obj.Barrier;
% Current ArcID
CurrentID           = ArcID_RM;
% Position of the Current ArcID
Posi                = find(obj.Code == CurrentID);
% Position Network
PoNet(Posi)         = 1;
% Branch Number
NumBranch           = 1;
% Other Posi
PosiUni             = [];

while (NumBranch == 1)
    
    FuncNetwork(Posi,:) = CurrID;
    CurrIDOut           = CurrID;
    
    if sum(obj.Barrier(Posi,:) > 0) > 0                     
        % a barrier was found, a new functional network must be assigned to upstream reaches:
        CurrIDOut(obj.Barrier(Posi,:) > 0)  = obj.Barrier(Posi, obj.Barrier(Posi,:) > 0);
        PosiUni = Posi;
    end

    Npre = Posi;
    
    % keeps going upstream
    Posi = find(obj.ToNode == obj.FromNode(Posi)); 
  
    try
        Posi1   = find(obj.ToNode == obj.FromNode(Posi));
        Posi2   = find(obj.ToNode == obj.FromNode(Posi1));
    catch
        Posi1 = [0 1 0 1];
        Posi2 = [0 1 0 1];
    end
    
    NumBranch   = length(Posi);
    
    if length(Posi) == 1 && isempty(Posi2)
        if sum(obj.Barrier(Posi,:) > 0) > 0                      
            % a barrier was found, a new functional network must be assigned to upstream reaches:
            CurrIDOut(obj.Barrier(Posi,:) > 0)  = obj.Barrier(Posi, obj.Barrier(Posi,:) > 0);      
        end
    end
        
    if NumBranch == 0
        Posi1 = [];
    end
    
    if (NumBranch == 1  && isempty(Posi1))
        
        % Position Network
        % -------------------------------------------------------------------------
        PoNet(Posi)     = 1;
        i               = 1;  

        % Functional Network
        % -------------------------------------------------------------------------
        FuncNetwork(Posi(i),:)           = obj.Barrier(Posi(i),:);
        
        % Variables to Propagated
        % -------------------------------------------------------------------------
        if ~isempty(obj.ProVar)
            obj.ProVar(Npre,:)           = obj.ProVar(Npre,:) + obj.ProVar(Posi(i),:);            
        end

        % Variables to Accumulate
        % -------------------------------------------------------------------------
        if ~isempty(obj.AccumVar)
            obj.AccumVar(Npre,:)         = obj.AccumVar(Npre,:) + obj.AccumVar(Posi(i),:);
        end

        % Variables to Accumulate With Clipping
        % -------------------------------------------------------------------------
        if ~isempty(obj.AccumClipVar)
            obj.AccumClipVar(Npre,:)     = obj.AccumClipVar(Npre,:) + obj.AccumClipVar(Posi(i),:);
        end

        % Variables to Accumulate With Losses
        % -------------------------------------------------------------------------
        if ~isempty(obj.AccumLossVar)
            obj.AccumLossVar(Npre,:)     = (obj.AccumLossVar(Npre,:) + obj.AccumLossVar(Posi(i),:));
        end

        % Variables to Accumulate With Clipping and Losses
        % -------------------------------------------------------------------------
        if ~isempty(obj.AccumClipLossVar)
            obj.AccumClipLossVar(Npre,:) = (obj.AccumClipLossVar(Npre,:) + obj.AccumClipLossVar(Posi(i),:));
        end
        
        % Function eval
        if obj.StatusFun
            eval(obj.FunNetwork_1)
        end
        
        % Branch Number
        NumBranch = 0;                
        
    elseif (NumBranch > 1  || ~isempty(Posi1)) || (NumBranch == 1  || isempty(Posi1))
        for i = 1:NumBranch 
            
            New_ArcID_RM = obj.Code(Posi(i));
            
            %% Functional Branch
            [FuncNetwork_i,...
            PoNet] = ...
            obj.FunctionalBranch(New_ArcID_RM,...                    
                                    ArcID_RM_i,...
                                    CurrIDOut,...                                     
                                    PoNet);
            
            % Functional Network
            % -------------------------------------------------------------------------
            FuncNetwork = FuncNetwork + FuncNetwork_i;
            
            % Variables to Propagated
            % -------------------------------------------------------------------------
            if ~isempty(obj.ProVar)
                obj.ProVar(Npre,:)           = obj.ProVar(Npre,:) + obj.ProVar(Posi(i),:);  
            end
            
            % Variables to Accumulate
            % -------------------------------------------------------------------------
            if ~isempty(obj.AccumVar)
                obj.AccumVar(Npre,:)         = obj.AccumVar(Npre,:) + obj.AccumVar(Posi(i),:);
            end
            
            % Variables to Accumulate With Clipping
            % -------------------------------------------------------------------------
            if ~isempty(obj.AccumClipVar)
                obj.AccumClipVar(Npre,:)     = obj.AccumClipVar(Npre,:) + obj.AccumClipVar(Posi(i),:);
            end
            
            % Variables to Accumulate With Losses
            % -------------------------------------------------------------------------
            if ~isempty(obj.AccumLossVar)
                obj.AccumLossVar(Npre,:)     = (obj.AccumLossVar(Npre,:) + obj.AccumLossVar(Posi(i),:));
            end
            
            % Variables to Accumulate With Clipping and Losses
            % -------------------------------------------------------------------------
            if ~isempty(obj.AccumClipLossVar)
                obj.AccumClipLossVar(Npre,:) = (obj.AccumClipLossVar(Npre,:) + obj.AccumClipLossVar(Posi(i),:));
            end
            
            % Function eval
            if obj.StatusFun
                eval(obj.FunNetwork_1)
            end
            
            % Branch Number
            if NumBranch == 1
                NumBranch = 0;
            end
        end
    end        
            
    % Functional Network
    % -------------------------------------------------------------------------
    if isempty(obj.Barrier(Posi,:)) && (NumBranch == 0) && ~isempty(PosiUni)
        FuncNetwork(PosiUni,:) = CurrIDOut;
    end
    
    % Variables to Accumulate With Losses
    % -------------------------------------------------------------------------
    if ~isempty(obj.AccumLossVar)
        obj.AccumLossVar(Npre,:) = obj.AccumLossVar(Npre,:) * (1 - (obj.LossRate(Npre)/100));
    end
    
    % Variables to Accumulate With Clipping
    % -------------------------------------------------------------------------
    if ~isempty(obj.AccumClipVar)
        if (obj.Barrier(Npre,1) > 0)                      
            % a barrier was found, resets river network accumulation:
            obj.AccumClipVar(Npre,:) = obj.AccumClipVar(Npre,:);
        end
    end
    
    % Variables to Accumulate With Clipping and Losses
    % ------------------------------------------------------------------------
    if ~isempty(obj.AccumClipLossVar)
        obj.AccumClipLossVar(Npre,:) = obj.AccumClipLossVar(Npre,:) * (1 - (obj.LossRate(Npre)/100));
        if (obj.Barrier(Npre,1) > 0) 
            obj.AccumClipLossVar(Npre,:) = obj.AccumClipLossVar(Npre,:);
        end
    end
    
    % Variables to Propagated
    % -------------------------------------------------------------------------
    if ~isempty(obj.ProVar)
        if (obj.ProVar(Npre) > 0)
            obj.ProVar(Npre) = obj.ProVar(Npre);
        end
    end    
    
    % Function eval
    if obj.StatusFun
        eval(obj.FunNetwork_2)
    end
            
    % Break While
    % -------------------------------------------------------------------------
    if Npre == ArcID_RM_i
        break
    end
    
end 

end
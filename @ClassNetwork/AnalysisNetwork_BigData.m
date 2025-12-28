function [FuncNetwork, varargout] = AnalysisNetwork_BigData(Network, BigDataPath, Barrier)
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

%% Abrir Objeto .mat
BigData     = matfile(BigDataPath,'Writable',true);

%% Check Input Data
% -------------------------------------------------------------------------
% Barrier
% -------------------------------------------------------------------------
if isempty(Barrier)
    Barrier = zeros(length(Network.Code), 1);
end

%% FunctionalBranch
% Currenct ID 
CurrID      = zeros(1,length(Barrier(1,:)));
PoNet       = Network.Code*0;
FuncNetwork = Barrier*0;
for i = 1:length(Network.RiverMouth)
    tic
    [FuncNetwork_i,O6] = FunctionalBranch_V2( Network.Code,...
                                        Network.FromNode, Network.ToNode,...
                                        Network.RiverMouth(i),...
                                        BigData, Barrier, CurrID, ...
                                        Network.RiverMouth(i), PoNet);

    FuncNetwork      = FuncNetwork + FuncNetwork_i;
    PoNet            = PoNet + O6;
    toc
end

%% OUTPUT DATA
% AccumClipLossVarOut
varargout{1} = PoNet;

end

%% Functional Branch
function [  FuncNetwork,...
            PoNet] = ...
            FunctionalBranch_V2(    ArcID, FromNode, ToNode, ArcID_RM,...
                                    BigData, ArcBarrier, CurrID,...
                                    ArcID_RM_i, PoNet )
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
% topological fluvial network. These analyzes allow us to characterize the 
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
%   .CurrID             [1,1] = ID of the Functional Network.                                      
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

FuncNetwork         = 0 * ArcBarrier;
% Current ArcID
CurrentID           = ArcID_RM;
% Position of the Current ArcID
Posi                = find(ArcID == CurrentID);
% Position Network
PoNet(Posi)         = 1;
% Branch Number
NumBranch           = 1;
% Other Posi
PosiUni             = [];

while (NumBranch == 1)
    
    FuncNetwork(Posi,:) = CurrID;
    CurrIDOut           = CurrID;
    
    if sum(ArcBarrier(Posi,:) > 0) > 0                     
        % a barrier was found, a new functional network must be assigned to upstream reaches:
        CurrIDOut(ArcBarrier(Posi,:) > 0)  = ArcBarrier(Posi, ArcBarrier(Posi,:) > 0);
        PosiUni = Posi;
    end

    Npre = Posi;
    
    % keeps going upstream
    Posi = find(ToNode == FromNode(Posi)); 
  
    try
        Posi1   = find(ToNode == FromNode(Posi));
        Posi2   = find(ToNode == FromNode(Posi1));
    catch
        Posi1 = [0 1 0 1];
        Posi2 = [0 1 0 1];
    end
    
    NumBranch   = length(Posi);
    
    if length(Posi) == 1 && isempty(Posi2)
        if sum(ArcBarrier(Posi,:) > 0) > 0                      
            % a barrier was found, a new functional network must be assigned to upstream reaches:
            CurrIDOut(ArcBarrier(Posi,:) > 0)  = ArcBarrier(Posi, ArcBarrier(Posi,:) > 0);      
        end
    end
        
    if NumBranch == 0
        Posi1 = [];
    end
    
    if (NumBranch == 1  && isempty(Posi1))
        
        % Position Network
        % -------------------------------------------------------------------------
        PoNet(Posi)       = 1;

        % Functional Network
        % -------------------------------------------------------------------------
        FuncNetwork(Posi,:) = ArcBarrier(Posi,:);
        
        % Variables to Propagated
        % -------------------------------------------------------------------------
        if ~isempty(BigData.ProVar)
            BigData.ProVar(Npre,:)           = BigData.ProVar(Npre,:) + BigData.ProVar(Posi,:);  
        end

        % Variables to Accumulate
        % -------------------------------------------------------------------------
        if ~isempty(BigData.AccumVar)
            BigData.AccumVar(Npre,:)         = BigData.AccumVar(Npre,:) + BigData.AccumVar(Posi,:);
        end

        % Variables to Accumulate With Clipping
        % -------------------------------------------------------------------------
        if ~isempty(BigData.AccumClipVar)
            BigData.AccumClipVar(Npre,:)     = BigData.AccumClipVar(Npre,:) + BigData.AccumClipVar(Posi,:);
        end

        % Variables to Accumulate With Losses
        % -------------------------------------------------------------------------
        if ~isempty(BigData.AccumLossVar)
            BigData.AccumLossVar(Npre,:)     = (BigData.AccumLossVar(Npre,:) + BigData.AccumLossVar(Posi,:));
        end

        % Variables to Accumulate With Clipping and Losses
        % -------------------------------------------------------------------------
        if ~isempty(BigData.AccumClipLossVar)
            BigData.AccumClipLossVar(Npre,:) = (BigData.AccumClipLossVar(Npre,:) + BigData.AccumClipLossVar(Posi,:));
        end
        
        % Branch Number
        NumBranch = 0;
        
    elseif (NumBranch > 1  || ~isempty(Posi1)) || (NumBranch == 1  || isempty(Posi1))
        for i = 1:NumBranch 
            
            New_ArcID_RM = ArcID(Posi(i));
            
            %% Functional Branch
            [FuncNetwork_i,...
            PoNet] = ...
            FunctionalBranch_V2(  ArcID, FromNode, ToNode, New_ArcID_RM,...                         
                                 BigData, ArcBarrier, CurrIDOut,... 
                                 ArcID_RM_i, PoNet);
            
            % Functional Network
            % -------------------------------------------------------------------------
            FuncNetwork  = FuncNetwork + FuncNetwork_i;
            
            % Variables to Propagated
            % -------------------------------------------------------------------------
            if ~isempty(BigData.ProVar)
                BigData.ProVar(Npre,:)              = BigData.ProVar(Npre,:) + BigData.ProVar(Posi(i),:);  
            end
            
            % Variables to Accumulate
            % -------------------------------------------------------------------------
            if ~isempty(BigData.AccumVar)
                BigData.AccumVar(Npre,:)            = BigData.AccumVar(Npre,:) + BigData.AccumVar(Posi(i),:);
            end
            
            % Variables to Accumulate With Clipping
            % -------------------------------------------------------------------------
            if ~isempty(BigData.AccumClipVar)
                BigData.AccumClipVar(Npre,:)        = BigData.AccumClipVar(Npre,:) + BigData.AccumClipVar(Posi(i),:);
            end
            
            % Variables to Accumulate With Losses
            % -------------------------------------------------------------------------
            if ~isempty(BigData.AccumLossVar)
                BigData.AccumLossVar(Npre,:)        = (BigData.AccumLossVar(Npre,:) + BigData.AccumLossVar(Posi(i),:));
            end
            
            % Variables to Accumulate With Clipping and Losses
            % -------------------------------------------------------------------------
            if ~isempty(BigData.AccumClipLossVar)
                BigData.AccumClipLossVar(Npre,:)    = (BigData.AccumClipLossVar(Npre,:) + BigData.AccumClipLossVar(Posi(i),:));
            end
            
            % Branch Number
            if NumBranch == 1
                NumBranch = 0;
            end
        end
    end
    
    % Functional Network
    % -------------------------------------------------------------------------
    if isempty(ArcBarrier(Posi,:)) && (NumBranch == 0) && ~isempty(PosiUni)
        FuncNetwork(PosiUni,:) = CurrIDOut;
    end
    
    % Variables to Accumulate With Losses
    % -------------------------------------------------------------------------
    if ~isempty(BigData.AccumLossVar)
        BigData.AccumLossVar(Npre,:) = BigData.AccumLossVar(Npre,:) * (1 - (BigData.LossRate(Npre)/100));
    end
    
    % Variables to Accumulate With Clipping
    % -------------------------------------------------------------------------
    if ~isempty(BigData.AccumClipVar)
        if (ArcBarrier(Npre,1) > 0)                      
            % a barrier was found, resets river network accumulation:
            BigData.AccumClipVar(Npre,:) = BigData.AccumClipVar(Npre,:);
        end
    end
    
    % Variables to Accumulate With Clipping and Losses
    % ------------------------------------------------------------------------
    if ~isempty(BigData.AccumClipLossVar)
        BigData.AccumClipLossVar(Npre,:) = BigData.AccumClipLossVar(Npre,:) * (1 - (BigData.LossRate(Npre)/100));
        if (ArcBarrier(Npre,1) > 0) 
            BigData.AccumClipLossVar(Npre,:) = BigData.AccumClipLossVar(Npre,:);
        end
    end
    
    % Variables to Propagated
    % -------------------------------------------------------------------------
    if ~isempty(BigData.ProVar)
        if (BigData.ProVar(Npre) > 0)
            BigData.ProVar(Npre) = BigData.ProVar(Npre);
        end
    end
    
    % Break While
    % -------------------------------------------------------------------------
    if Npre == ArcID_RM_i
        break
    end
    
end 

end


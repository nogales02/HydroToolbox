function Network = graph_preprocessing_JNP( ReachData )
%GRAPH_PREPROCESSING_DYN receives the informations about reach and node ID and
%return the struct Network, that describes network connectivity. This
%function is specific for the D-CASCADE model

% INPUT: 
%
% ReachData    = dataset of network reaches
%
%---
% OUTPUT: 
%
% Network  = 1x1 struct containing for each node info on upstream and downstream nodes
%  
%- Network.Upstream/Downstream.Distance {A,1}(B): distance, in m, between the
%       reach A FromN and reach B FromN, considering only movement
%       upstream/downstream;
%
%- Network.Upstream/Downstream.Path {A,1}{1,B}: list of reaches passed
%       through moving upstream/downstream from reach A to reach B;
%
%- Network.Upstream/Downstream.Predecessors {A,1}(B): ID of the reach
%       directly upstream/downstream reach B, in the path from 
%       reach A towards the source/outlet node;
%
%- Network.Upstream.NumberUpstreamNode [R,1]: max number of nodes between
%       reach R and a source node
%
%- Network.Upstream.Node  {1,R}: ID of the fromN of the reaches direcly 
%       upstream reach R

%% 
FromN   = [ReachData.FromN]';
ToN     = [ReachData.ToN]';
Length  = [ReachData.Length]';

% -------------------------------------------------------------------------
% Matriz de adyacencia Downstream
% -------------------------------------------------------------------------
[D,~]   = write_adj_matrix(FromN , ToN , Length);

% -------------------------------------------------------------------------
% Matriz de adyacencia Upstream
% -------------------------------------------------------------------------
[Dus,~] = write_adj_matrix(ToN , FromN , Length);

Network.Upstream.numberUpstreamNodes    = zeros(1,length(FromN));
Network.Upstream.distancelist           = cell(1,length(FromN));
Network.Upstream.Node                   = cell(length(FromN),1);
Network.II                              = NaN(length(FromN),length(FromN));
Network.NH                              = cell(1,length(FromN));

% -------------------------------------------------------------------------
InfoGPU         = gpuDevice; 
Step            = min([floor(sqrt(InfoGPU.AvailableMemory/8)*0.9), 1000]); 
NPart           = ceil(length(FromN)/Step);
PosiPart        = 1:Step:(NPart*Step);
PosiPart(end)   = length(FromN);

if length(FromN) < 5000
    % ---------------------------------------------------------------------
    % the upstream network definition is required to find reservoirs
    % upstream from a given downstream reservoirs
    % ---------------------------------------------------------------------
    hwb = waitbar(0);
    [Downstream_Distance, ~,~] = ...
        (arrayfun(@(fromnode) graphshortestpath(D,fromnode),FromN,'UniformOutput',false));
    waitbar(1/2,hwb,'Processing');
    
    % -------------------------------------------------------------------------
    % the upstream network definition is required to find reservoirs
    % upstream from a given downstream reservoirs
    % -------------------------------------------------------------------------
    [Network.Upstream.Distance, Upstream_Path, Upstream_Predecessors] = ...
     (arrayfun(@(fromnode) graphshortestpath(Dus,fromnode),FromN,'UniformOutput',false));
    waitbar(1,hwb,'Processing');
    close(hwb);
    
    hwb = waitbar(0,'Porcessing');
    for i = 1:length(FromN)     
        % ---------------------------------------------------------------------
        % Transfer downstream path from each each node into a matrix 
        % representation
        % ---------------------------------------------------------------------
        Network.II(i,:) = Downstream_Distance{i};          

        % ---------------------------------------------------------------------
        % find the number of upstream nodes    
        % ---------------------------------------------------------------------
        Network.Upstream.numberUpstreamNodes(i) = max(cellfun(@length,Upstream_Path{i}));

        % ---------------------------------------------------------------------
        % directly upstream nodes
        % ---------------------------------------------------------------------
        Network.Upstream.Node{i} = find(Upstream_Predecessors{i}==i);    

        % ---------------------------------------------------------------------
        % closest node list
        % ---------------------------------------------------------------------
        [sort_data,Network.Upstream.distancelist{i}] = sort(Network.Upstream.Distance{i});    
        Network.Upstream.distancelist{i}( sort_data == inf ) = inf;

        waitbar(i/length(FromN));    
    end
    close(hwb);

else    
    hwb     = waitbar(0);    
    Network.Upstream.Distance = cell(length(FromN),1);        
    
    for i = 1:NPart-1
        % -----------------------------------------------------------------
        % the Downstream network definition is required to find reservoirs
        % upstream from a given downstream reservoirs
        % ----------------------------------------------------------------- 
        [Downstream_Distance,~,~] = ...
         (arrayfun(@(fromnode) graphshortestpath(D,fromnode),...
         FromN(PosiPart(i):PosiPart(i+1)),'UniformOutput',false));
        
        % -----------------------------------------------------------------
        % the upstream network definition is required to find reservoirs
        % upstream from a given downstream reservoirs
        % -----------------------------------------------------------------
        [Network.Upstream.Distance(PosiPart(i):PosiPart(i+1)),...
         Upstream_Path,... 
         Upstream_Predecessors] = ...
         (arrayfun(@(fromnode) graphshortestpath(Dus,fromnode),...
         FromN(PosiPart(i):PosiPart(i+1)),'UniformOutput',false));
        
        % 
        for ii = PosiPart(i):PosiPart(i+1) 
            % ---------------------------------------------------------------------
            % Transfer downstream path from each each node into a matrix 
            % representation
            % ---------------------------------------------------------------------
            Network.II(ii,:) = Downstream_Distance{ii - (PosiPart(i) -1)};          

            % ---------------------------------------------------------------------
            % find the number of upstream nodes    
            % ---------------------------------------------------------------------
            Network.Upstream.numberUpstreamNodes(ii) = max(cellfun(@length,Upstream_Path{ii-(PosiPart(i) -1)}));

            % ---------------------------------------------------------------------
            % directly upstream nodes
            % ---------------------------------------------------------------------
            Network.Upstream.Node{ii} = find(Upstream_Predecessors{ii-(PosiPart(i) -1)}==ii);    

            % ---------------------------------------------------------------------
            % closest node list
            % ---------------------------------------------------------------------
            [sort_data,Network.Upstream.distancelist{ii}] = sort(Network.Upstream.Distance{ii});    
            Network.Upstream.distancelist{ii}( sort_data == inf ) = inf; 
        end
        
        waitbar(i/(NPart-1),hwb,'Processing'); 
    end
    close(hwb);
end
    
% Check Inf
Network.II(~isfinite(Network.II)) = nan;

% NH contains the node hierarchy
[~, Network.NH] = sort(Network.Upstream.numberUpstreamNodes);

function Network = graph_preprocessing( ReachData )
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

% Matriz de adveniencia 1
[D,~]   = write_adj_matrix(FromN , ToN , Length);

% Matriz de adveniencia 2
[Dus,~] = write_adj_matrix(ToN , FromN , Length);

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
Step            = 1000; 
NPart           = ceil(length(FromN)/Step);
PosiPart        = 1:Step:(NPart*Step);
PosiPart(end)   = length(FromN);

hwb     = waitbar(0);
if length(FromN) < Step
    % [Network.Downstream.Distance, Network.Downstream.Path, Network.Downstream.Predecessors] = ...
    %     (arrayfun(@(fromnode) graphshortestpath(D,fromnode),FromN,'UniformOutput',false));
    [Network.Downstream.Distance, Network.Downstream.Path, Network.Downstream.Predecessors] = ...
        (arrayfun(@(fromnode) graphshortestpath(D,fromnode),FromN,'UniformOutput',false));
    waitbar(1,hwb,'Processing');
else
    Network.Downstream.Distance     = cell(length(FromN),1);
    Network.Downstream.Path         = cell(length(FromN),1);
    Network.Downstream.Predecessors = cell(length(FromN),1);       
    
    for i = 1:NPart-1
        [Network.Downstream.Distance(PosiPart(i):PosiPart(i+1)),...
         Network.Downstream.Path(PosiPart(i):PosiPart(i+1)),... 
         Network.Downstream.Predecessors(PosiPart(i):PosiPart(i+1))] = ...
         (arrayfun(@(fromnode) graphshortestpath(D,fromnode),...
         FromN(PosiPart(i):PosiPart(i+1)),'UniformOutput',false));
     
        waitbar(i/NPart,hwb,'Processing');
    end
    waitbar(1,hwb,'Processing');
end
close(hwb);

% -------------------------------------------------------------------------
% the upstream network definition is required to find reservoirs
% upstream from a given downstream reservoirs
% -------------------------------------------------------------------------
hwb     = waitbar(0);
if length(FromN) < Step    
    [Network.Upstream.Distance, Network.Upstream.Path, Network.Upstream.Predecessors] = ...
     (arrayfun(@(fromnode) graphshortestpath(Dus,fromnode),FromN,'UniformOutput',false));
    waitbar(1,hwb,'Processing');
else
    Network.Upstream.Distance     = cell(length(FromN),1);
    Network.Upstream.Path         = cell(length(FromN),1);
    Network.Upstream.Predecessors = cell(length(FromN),1);       
    
    for i = 1:NPart-1
        [Network.Upstream.Distance(PosiPart(i):PosiPart(i+1)),...
         Network.Upstream.Path(PosiPart(i):PosiPart(i+1)),... 
         Network.Upstream.Predecessors(PosiPart(i):PosiPart(i+1))] = ...
         (arrayfun(@(fromnode) graphshortestpath(Dus,fromnode),...
         FromN(PosiPart(i):PosiPart(i+1)),'UniformOutput',false));
     
        waitbar(i/NPart,hwb,'Processing');
    end
    waitbar(1,hwb,'Processing');   
end
close(hwb);

% Transfer downstream path from each each node into a matrix representation
Network.II = cell2mat(Network.Downstream.Distance);
Network.II(isfinite(Network.II)==0) = nan;   

%find the number of upstream nodes
hwb     = waitbar(0);
Network.Upstream.numberUpstreamNodes = zeros(1,length(Network.Upstream.Path));
for i = 1:length(Network.II)
    Network.Upstream.numberUpstreamNodes(i) = max(cellfun(@length,Network.Upstream.Path{i}));
    waitbar(i/length(Network.II),hwb,'Step 1 - Find the number of upstream nodes');
end
close(hwb);

% NH contains the node hierarchy
[~, Network.NH] = sort(Network.Upstream.numberUpstreamNodes);

%directly upstream nodes
hwb     = waitbar(0);
Network.Upstream.Node = cell(1,length(Network.NH));
for i = 1:length(Network.NH)
    Network.Upstream.Node{i} = find(Network.Upstream.Predecessors{i}==i);
    waitbar(i/length(Network.NH),hwb,'Step 2 - directly upstream nodes');
end
close(hwb);
  
%directly downstream nodes
hwb     = waitbar(0);
Network.Downstream.Node = cell(1,length(Network.NH));
for i=1:length(Network.NH)
    Network.Downstream.Node{i} = find(Network.Downstream.Predecessors{i}==i);
    waitbar(i/length(Network.NH),hwb,'Step 3 - directly downstream nodes');
end
close(hwb);

%closest node list
hwb     = waitbar(0);
for i=1:length(Network.NH)
    [sort_data,Network.Upstream.distancelist{i}] = sort(Network.Upstream.Distance{i, 1});
    Network.Upstream.distancelist{i}( sort_data == inf ) = inf;
    waitbar(i/length(Network.NH),hwb,'Step 4 - closest node list');
end
close(hwb);

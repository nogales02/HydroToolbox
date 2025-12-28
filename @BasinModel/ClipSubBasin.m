function obj = ClipSubBasin(obj, PoNet)
PoNet             = logical(PoNet);
% Code Basin
obj.Code          = obj.Code(PoNet);
% FromNode
obj.FromNode      = obj.FromNode(PoNet);
% ToNode
obj.ToNode        = obj.ToNode(PoNet);
% Area (m2)
obj.BasinArea     = obj.BasinArea(PoNet);
% Floodplains Area (m2)
obj.FloodArea     = obj.FloodArea(PoNet);
% Precipitation (mm)
obj.P             = obj.P(:,PoNet);
% Evapotranspiration (mm)
obj.ETP           = obj.ETP(:,PoNet);
% Basin Parameters
obj.ParamsBasin   = obj.ParamsBasin(PoNet,:);                 
% Floodplains Parameters
obj.ParamsFlood   = obj.ParamsFlood(PoNet,:);
% Group Calibartion
obj.GroupCal      = obj.GroupCal(PoNet);
% Similary Parameters
obj.Simil_Params  = obj.Simil_Params(PoNet);
% ID Demand
obj.ID_Demand     = obj.ID_Demand(PoNet);
% ID Returns
obj.ID_Return     = obj.ID_Return(PoNet);
% Demand
obj.Demands       = obj.Demands(:,PoNet);
% Returns
obj.Returns       = obj.Returns(:,PoNet);
% Qsim
obj.Qsim          = obj.Qsim(:,PoNet);
% PoPo
obj.PoPo          = obj.PoPo(PoNet);
% IDPoPo
obj.IDPoPo        = obj.IDPoPo(PoNet);

end
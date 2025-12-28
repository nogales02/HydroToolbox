function LoadParams(Basin)
tic

NameFile            = fullfile(Basin.PathProject, 'INPUTS','2_Parameters.csv');
Tmp                 = readmatrix(NameFile);
Code                = Tmp(:,1);
FromNode            = Tmp(:,2);
ToNode              = Tmp(:,3);
BasinArea           = Tmp(:,4);
FloodArea           = Tmp(:,5);
RiverMouth          = Code(logical(Tmp(:,6)));
GaugesCal           = Tmp(:,7);
GroupCal            = Tmp(:,8);
Simil_Params        = Tmp(:,9);
ID_Demand           = Tmp(:,10);
ID_Return           = Tmp(:,11);
ParmsFlood          = Tmp(:,12:15);
ParmsBasin          = Tmp(:,16:end);

% Code Basin
Basin.Code          = Code;
% FromNode
Basin.FromNode      = FromNode;
% ToNode
Basin.ToNode        = ToNode;
% Area (m2)
Basin.BasinArea     = BasinArea;
% Floodplains Area (m2)
Basin.FloodArea     = FloodArea;
% River Mouth
Basin.RiverMouth    = RiverMouth;
Basin.RiverMouthBasin = RiverMouth;
% Gauges Calibration
Basin.GaugesCal     = GaugesCal;
% Group Calibartion
Basin.GroupCal      = GroupCal;
% Similary Parameters
Basin.Simil_Params  = Simil_Params;
% ID Demand
Basin.ID_Demand     = ID_Demand;
% ID Returns
Basin.ID_Return     = ID_Return;

% Basin Parameters
Basin.ParamsBasin    = ParmsBasin;  
Basin.ParamsBasin(Basin.ParamsBasin == Basin.NoValue) = NaN;
Basin.ParamsBasinCal = Basin.ParamsBasin;

% Floodplains Parameters
Basin.ParamsFlood    = ParmsFlood;
Basin.ParamsFlood(Basin.ParamsFlood == Basin.NoValue) = NaN;
Basin.ParamsFloodCal = Basin.ParamsFlood;

% Name
Name = cell(1,length(Basin.Code));
Type = cell(1,length(Basin.Code));
for i = 1:length(Basin.Code)
    Name{i} = ['UHA-',num2str(Basin.Code(i))];
    Type{i} = 'UHA';
end
Basin.Name      = Name;
Basin.Type      = Type;
Basin.IDPoPo    = true(length(Basin.Code),1);

disp(['Load Parameters - Ok - ',num2str(toc)])
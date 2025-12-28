function LoadTopology(Basin, varargin)

tic
%% Read UHA 
if nargin == 1
    PathBasin   = fullfile(Basin.PathProject, 'INPUTS','02-UHA','UHA.shp');
else
    PathBasin   = varargin{1};
end

[BasinTmp, Tmp] = shaperead(PathBasin);
X               = [Tmp.X]';
Y               = [Tmp.Y]';
Z               = [Tmp.Z]';
Longitude       = [Tmp.Lon]';
Latitude        = [Tmp.Lat]';
XBasin          = {BasinTmp.X}';
YBasin          = {BasinTmp.Y}';
BoundingBox     = {BasinTmp.BoundingBox}';
CodeTmp         = [Tmp.Code]';

[id, posi]      = ismember(Basin.Code, CodeTmp);
if sum(id) ~= length(Basin.Code)
    error('Error')
end

Basin.X           = X(posi);
Basin.Y           = Y(posi);
Basin.Z           = Z(posi);
Basin.Longitude   = Longitude(posi);
Basin.Latitude    = Latitude(posi);
Basin.XBasin      = XBasin(posi);
Basin.YBasin      = YBasin(posi);
Basin.BoundingBox = BoundingBox(posi);

disp(['Load Topology - Ok - ',num2str(toc)])
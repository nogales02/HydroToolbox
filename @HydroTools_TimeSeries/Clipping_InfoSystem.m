function Clipping_InfoSystem(obj, Input)         

if ischar(Input) || isstring(Input)
    %% Lectura de Shapefile de dominimo de trabajo
    [Windows, ~] = shaperead(Input);

    id = ~isnan(Windows.X);
    X  = Windows.X(id);
    Y  = Windows.Y(id);

    id = ~isnan(Y);
    Y  = Y(id);
    X  = X(id);
    
    %% Select Gauges in Windows
    id = inpolygon(obj.X, obj.Y, Windows.X, Windows.Y);
elseif ismatrix(Input)
    [id, ~] = ismember(obj.Code, Input);
else
    error('Error Inputs')
end

%% Clip Information System
% Name
obj.Name        = obj.Name(id);
% Type
obj.Type        = obj.Type(id);
% Code
obj.Code        = obj.Code(id);
% Coordinate X
obj.X           = obj.X(id);
% Coordinate Y
obj.Y           = obj.Y(id);
% Elevation
obj.Z           = obj.Z(id);
% Longitude
obj.Longitude   = obj.Longitude(id);
% Latitude
obj.Latitude    = obj.Latitude(id);
% Data
obj.Data        = obj.Data(:,id);
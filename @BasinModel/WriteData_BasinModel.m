function WriteData_BasinModel(obj, NameVar)
% -------------------------------------------------------------------------
% Programado en Matlab - R2019b 
% -------------------------------------------------------------------------
%                           Informaci�n Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Fecha         : 01-Enero-2019
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los t�rminos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener. Para mayor informaci�n revisar 
% http://www.gnu.org/licenses/
%
% -------------------------------------------------------------------------
% Descripci�n del Codigo
% -------------------------------------------------------------------------
%
% -------------------------------------------------------------------------
% Input Data
% -------------------------------------------------------------------------
% 
% -------------------------------------------------------------------------
% Output Data
% -------------------------------------------------------------------------
%
if nargin < 2
    NameVar = 'Qsim';
end
NameFile = fullfile(obj.PathProject, 'OUTPUTS','Variables',[NameVar,'.csv']);
                    
%% Open File
ID_File     = fopen(NameFile,'w');

%% Varible Name
fprintf(ID_File,'%s\n','Varible,Caudal');

%% Variable Unit
fprintf(ID_File,'%s\n','Unit,m3/s');

%% Data Source
fprintf(ID_File,'%s\n','Source,Hydrological-Model');

%% No Value
fprintf(ID_File,'%s\n',['NoValue,',num2str(obj.NoValue)]);

%% EPSG
fprintf(ID_File,'%s\n',['EPSG,',num2str(obj.EPSG)]);

%% Name Gauges
Name = 'Name,Month,Day,Hour,Minute,Second'; 
for i = 1:length((obj.Name))
    Name = [Name,',',num2str(obj.Name{i})]; 
end
fprintf(ID_File,'%s\n',Name);

%% Gauges Type
Name = 'Type,Month,Day,Hour,Minute,Second'; 
for i = 1:length((obj.Name))
    Name = [Name,',',num2str(obj.Type{i})]; 
end
fprintf(ID_File,'%s\n',Name);

%% Longitude
Name = ['Longitude',repmat([',',num2str(obj.NoValue)],1,5)]; 
for i = 1:length((obj.Name))
    Name = [Name,',',num2str(obj.Longitude(i))]; 
end
fprintf(ID_File,'%s\n',Name);

%% Latitude
Name = ['Latitude',repmat([',',num2str(obj.NoValue)],1,5)]; 
for i = 1:length((obj.Name))
    Name = [Name,',',num2str(obj.Latitude(i))]; 
end
fprintf(ID_File,'%s\n',Name);

%% Coordinates in X
Name = ['Coordinates-X',repmat([',',num2str(obj.NoValue)],1,5)]; 
for i = 1:length((obj.Name))
    Name = [Name,',',num2str(obj.X(i))]; 
end
fprintf(ID_File,'%s\n',Name);

%% Coordinates in Y
Name = ['Coordinates-Y',repmat([',',num2str(obj.NoValue)],1,5)]; 
for i = 1:length((obj.Name))
    Name = [Name,',',num2str(obj.Y(i))]; 
end
fprintf(ID_File,'%s\n',Name);

%% Elevation
Name = ['Elevation',repmat([',',num2str(obj.NoValue)],1,5)]; 
for i = 1:length((obj.Name))
    Name = [Name,',',num2str(obj.Z(i))]; 
end
fprintf(ID_File,'%s\n',Name);

%% Date
Name = 'Year,Month,Day,Hour,Minute,Second';
for i = 1:length((obj.Name))
    Name = [Name,',',num2str(obj.Code(i))]; 
end
fprintf(ID_File,'%s\n',Name);

Date = [year(obj.Date) month(obj.Date) day(obj.Date) hour(obj.Date) minute(obj.Date) second(obj.Date)];

%% Assignation NaN Value
eval(['Data = round(obj.',NameVar,',3);']);
Data(isnan(Data)) = obj.NoValue;

%% Wirte Data
fprintf(ID_File, ['%d,%d,%d,%d,%d,%d',repmat(',%.2f',1,length(obj.Code)),'\n'],[Date, Data]');

%% Close File 
fclose(ID_File);

%% Asignation NaN Value
Data(Data == obj.NoValue) = NaN;
eval(['obj.',NameVar,' = Data;']);
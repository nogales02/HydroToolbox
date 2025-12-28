function LoadClimate(Basin)
tic
% -------------------------------------------------------------------------
% Archivos de precipitación y evapotranspiración potencial 
% -------------------------------------------------------------------------
NameFile_P      = fullfile(Basin.PathProject, 'INPUTS','3_P');
NameFile_ETP    = fullfile(Basin.PathProject, 'INPUTS','4_ETP');

% -------------------------------------------------------------------------
% Verificación de archivos csv o .mat
% -------------------------------------------------------------------------
DataInfo    = isfile([NameFile_P,'.mat']);
if DataInfo
    Status_P = true;
else
    Status_P = false;
end

DataInfo    = isfile([NameFile_ETP,'.mat']);
if DataInfo
    Status_ETP = true;
else
    Status_ETP = false;
end

% ---------------------------------------------------------------------
% lectura - Datos de precipitación 
% ---------------------------------------------------------------------
if Status_P
    VarMat      = matfile([NameFile_P,'.mat']);
    Basin.P     = VarMat.Data;
    Code        = VarMat.Code;
    Date        = VarMat.Date;
else
    ID_File     = fopen([NameFile_P,'.csv'],'r');
    Code        = textscan(ID_File,'%s',3 + length(Basin.Code),'Delimiter',',');
    Code        = cellfun(@str2num,Code{1}(4:end));
    FormatText  = ['%f,%f,%f',repmat(',%f',1,length(Basin.Code))];
    Basin.P     = cell2mat(textscan(ID_File,FormatText));
    Date        = datetime(Basin.P(:,1:3));
    Basin.P     = Basin.P(:,4:end); 
    fclose(ID_File);
end

% Verificar si las fechas de la serie de tiempo coinciden con las definidas
% en el objeto Basin
[id, posi1] = ismember(Basin.Date, Date);
if sum(id) ~= length(Basin.Date)
    error('Error')
end

% Verificar si los códigos de la serie de tiempo coinciden con los definidos
% en el objeto Basin
[id, posi] = ismember(Basin.Code, Code);
if sum(id) ~= length(Basin.Code)
    error('Error')
end

% recortar fechas al periodo de simulación definido en el objeto Basin
Basin.P = Basin.P(posi1,posi);
% Asignación de valores noValue a NaN
Basin.P(Basin.P == Basin.NoValue) = NaN;

% ---------------------------------------------------------------------
% lectura - Datos de evapotranspiración potencial
% ---------------------------------------------------------------------
if Status_ETP
    VarMat      = matfile([NameFile_ETP,'.mat']);
    Basin.ETP   = VarMat.Data;
    Code        = VarMat.Code;
    Date        = VarMat.Date;
else
    ID_File     = fopen([NameFile_ETP,'.csv'],'r');
    Code        = textscan(ID_File,'%s',3 + length(Basin.Code),'Delimiter',',');
    Code        = cellfun(@str2num,Code{1}(4:end));
    FormatText  = ['%f,%f,%f',repmat(',%f',1,length(Basin.Code))];
    Basin.ETP   = cell2mat(textscan(ID_File,FormatText));
    Date        = datetime(Basin.ETP(:,1:3));
    Basin.ETP   = Basin.ETP(:,4:end); 
    fclose(ID_File);
end

% Verificar si las fechas de la serie de tiempo coinciden con las definidas
% en el objeto Basin
[id, posi1] = ismember(Basin.Date, Date);
if sum(id) ~= length(Basin.Date)
    error('Error')
end

% Verificar si los códigos de la serie de tiempo coinciden con los definidos
% en el objeto Basin
[id, posi] = ismember(Basin.Code, Code);
if sum(id) ~= length(Basin.Code)
    error('Error')
end

% recortar fechas al periodo de simulación definido en el objeto Basin
Basin.ETP = Basin.ETP(posi1,posi);
% Asignación de valores noValue a NaN
Basin.ETP(Basin.ETP == Basin.NoValue) = NaN;

disp(['Load Climate - Ok - ',num2str(toc)])
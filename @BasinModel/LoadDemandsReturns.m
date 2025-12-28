function LoadDemandsReturns(Basin)

% -------------------------------------------------------------------------
% Archivos de precipitación y evapotranspiración potencial 
% -------------------------------------------------------------------------
NameFile_D    = fullfile(Basin.PathProject, 'INPUTS','5_Demands');
NameFile_R    = fullfile(Basin.PathProject, 'INPUTS','6_Returns');

% -------------------------------------------------------------------------
% Verificación de archivos csv o .mat
% -------------------------------------------------------------------------
DataInfo    = dir([NameFile_D,'.mat']);
if ~isempty(DataInfo)
    Status_D = true;
else
    Status_D = false;
end

DataInfo    = dir([NameFile_R,'.mat']);
if ~isempty(DataInfo)
    Status_R = true;
else
    Status_R = false;
end

try
    % ---------------------------------------------------------------------
    % lectura - Datos de precipitación 
    % ---------------------------------------------------------------------
    if Status_D
        VarMat      = matfile([NameFile_D,'.mat']);
        Basin.Demands = VarMat.Data;
        Code        = VarMat.Code;
        Date        = VarMat.Date;
    else
        ID_File     = fopen([NameFile_D,'.csv'],'r');
        Code        = textscan(ID_File,'%s',3 + length(Basin.Code),'Delimiter',',');
        Code        = cellfun(@str2num,Code{1}(4:end));
        FormatText  = ['%f,%f,%f',repmat(',%f',1,length(Basin.Code))];
        Basin.Demands   = cell2mat(textscan(ID_File,FormatText));
        Date            = datetime(Basin.Demands(:,1:3));
        Basin.Demands   = Basin.Demands(:,4:end); 
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
    Basin.Demands = Basin.Demands(posi1,posi);
    % Asignación de valores noValue a NaN
    Basin.Demands(Basin.Demands == Basin.NoValue) = NaN;
    
    % ---------------------------------------------------------------------
    % lectura - Datos de evapotranspiración potencial
    % ---------------------------------------------------------------------
    if Status_R
        VarMat      = matfile([NameFile_R,'.mat']);
        Basin.Returns   = VarMat.Data;
        Code        = VarMat.Code;
        Date        = VarMat.Date;
    else
        ID_File     = fopen([NameFile_R,'.csv'],'r');
        Code        = textscan(ID_File,'%s',3 + length(Basin.Code),'Delimiter',',');
        Code        = cellfun(@str2num,Code{1}(4:end));
        FormatText  = ['%f,%f,%f',repmat(',%f',1,length(Basin.Code))];
        Basin.Returns   = cell2mat(textscan(ID_File,FormatText));
        Date            = datetime(Basin.Returns(:,1:3));
        Basin.Returns   = Basin.Returns(:,4:end); 
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
    Basin.Returns = Basin.Returns(posi1,posi);
    % Asignación de valores noValue a NaN
    Basin.Returns(Basin.Returns == Basin.NoValue) = NaN;

catch ME
    errorMessage = sprintf('Error in function %s() at line %d.\n\nError Message:\n%s', ...
        ME.stack(1).name, ME.stack(1).line, ME.message);
    errordlg(errorMessage,'!! Error !!')    
    return
end
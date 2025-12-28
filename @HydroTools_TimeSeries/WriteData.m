function WriteData(obj, NameFile, varargin)
% WRITEDATA Escribe datos de series de tiempo a archivos CSV con formato específico
%
% SYNTAX:
%   WriteData(obj, NameFile)
%   WriteData(obj, NameFile, 'NameVarSave', 'Data')
%   WriteData(obj, NameFile, 'Verbose', true)
%
% DESCRIPTION:
%   Esta función escribe datos de series de tiempo a archivos CSV con el formato
%   específico de header (13 líneas) que contiene metadatos de las estaciones y
%   posteriormente los datos temporales. Convierte automáticamente valores NaN
%   a NoValue para escritura y los restaura después.
%
% INPUT PARAMETERS:
%   obj      - [HydroTools_TimeSeries] Objeto de la clase con datos a escribir
%   
%   NameFile - [char] Ruta completa del archivo CSV a crear. El archivo tendrá:
%              * Línea 1: Variable (ej: 'Var,Precipitación')
%              * Línea 2: Unidad (ej: 'Unit,mm')
%              * Línea 3: Fuente (ej: 'Source,IDEAM')
%              * Línea 4: Valor nulo (ej: 'NoValue,-9999')
%              * Línea 5: EPSG (ej: 'EPSG,4326')
%              * Línea 6: Nombres de estaciones
%              * Línea 7: Tipos de estaciones
%              * Línea 8: Longitudes
%              * Línea 9: Latitudes
%              * Línea 10: Coordenada X
%              * Línea 11: Coordenada Y
%              * Línea 12: Elevación Z
%              * Línea 13: Códigos de estaciones
%              * Línea 14+: Datos (Año,Mes,Día,Hora,Minuto,Segundo,Estación1,...)
%
% OPTIONAL PARAMETERS (Name-Value pairs):
%   'NameVarSave'  - [char, default: 'Data'] Nombre de la propiedad del objeto que
%                    contiene los datos a escribir
%   
%   'Verbose'      - [logical, default: false] Si es true, muestra información
%                    detallada del proceso de escritura
%
% EXAMPLES:
%   % Escritura básica de datos
%   WriteData(obj, 'datos_exportados.csv');
%   
%   % Escribir variable específica con información detallada
%   WriteData(obj, 'temperatura.csv', 'NameVarSave', 'Temperature', 'Verbose', true);
%
% NOTES:
%   - El archivo se crea con el formato exacto para ReadData
%   - Los valores NaN se convierten temporalmente a NoValue para escritura
%   - Los valores NaN se restauran automáticamente después de escribir
%   - Se preservan todas las propiedades de metadatos del objeto
%
% SEE ALSO:
%   ReadData, fprintf, inputParser, fopen
%
% -------------------------------------------------------------------------
% Matlab - R2024b y versiones superiores
% -------------------------------------------------------------------------
%                           Información del Autor
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Versión       : 2.0 - Simplificada bajo filosofía "simple es mejor"
% Fecha         : 2025
%--------------------------------------------------------------------------

    % =====================================================================
    % PARSING SIMPLE DE PARÁMETROS 
    % =====================================================================
    
    % Crear inputParser básico
    p               = inputParser;
    p.KeepUnmatched = false;
    
    % Validaciones simples
    addRequired(p, 'NameFile', @ischar);
    addParameter(p, 'NameVarSave', 'Data', @ischar);
    addParameter(p, 'Verbose', false, @islogical);
    
    parse(p, NameFile, varargin{:});
    
    % Extraer parámetros
    fileName        = p.Results.NameFile;
    varName         = p.Results.NameVarSave;
    verbose         = p.Results.Verbose;
    
    % =====================================================================
    % VALIDACIONES BÁSICAS
    % =====================================================================
    
    if ~isprop(obj, varName)
        error('WriteData:VariableNotFound', 'La variable %s no existe en el objeto', varName);
    end
    
    if verbose
        fprintf('\n=== ESCRITURA DE DATOS ===\n');
        fprintf('Archivo: %s\n', fileName);
        fprintf('Variable: %s\n', varName);
        fprintf('Estaciones: %d\n', length(obj.Code));
        fprintf('Registros: %d\n', size(obj.(varName), 1));
        fprintf('=========================\n');
    end
    
    % =====================================================================
    % ABRIR ARCHIVO PARA ESCRITURA
    % =====================================================================
    
    ID_File = fopen(fileName, 'w');
    if ID_File == -1
        error('WriteData:CannotCreateFile', 'No se puede crear el archivo: %s', fileName);
    end
    
    try
        % =====================================================================
        % ESCRIBIR METADATOS DEL HEADER
        % =====================================================================
        
        % Variable Name
        fprintf(ID_File, '%s\n', ['Varible,', obj.Var]);
        
        % Variable Unit
        fprintf(ID_File, '%s\n', ['Unit,', obj.Unit]);
        
        % Data Source
        fprintf(ID_File, '%s\n', ['Source,', obj.Source]);
        
        % No Value
        fprintf(ID_File, '%s\n', ['NoValue,', num2str(obj.NoValue)]);
        
        % EPSG
        fprintf(ID_File, '%s\n', ['EPSG,', num2str(obj.EPSG)]);
        
        % =====================================================================
        % ESCRIBIR PROPIEDADES VECTORIALES
        % =====================================================================
        
        % Name Gauges
        fprintf(ID_File, '%s\n', strjoin([{'Name','Month','Day','Hour','Minute','Second'}, reshape(obj.Name,1,[])], ','));
        
        % Gauges Type
        fprintf(ID_File, '%s\n', strjoin([{'Type','Month','Day','Hour','Minute','Second'}, reshape(obj.Type,1,[])], ','));
        
        % Longitude
        fprintf(ID_File, '%s\n', strjoin([{'Longitude'}, repmat({num2str(obj.NoValue)}, 1, 5), arrayfun(@num2str, obj.Longitude, 'UniformOutput', false)], ','));
        
        % Latitude
        fprintf(ID_File, '%s\n', strjoin([{'Latitude'}, repmat({num2str(obj.NoValue)}, 1, 5), arrayfun(@num2str, obj.Latitude, 'UniformOutput', false)], ','));
        
        % Coordinates in X
        fprintf(ID_File, '%s\n', strjoin([{'Coordinates-X'}, repmat({num2str(obj.NoValue)}, 1, 5), arrayfun(@num2str, obj.X, 'UniformOutput', false)], ','));
        
        % Coordinates in Y
        fprintf(ID_File, '%s\n', strjoin([{'Coordinates-Y'}, repmat({num2str(obj.NoValue)}, 1, 5), arrayfun(@num2str, obj.Y, 'UniformOutput', false)], ','));
        
        % Elevation
        fprintf(ID_File, '%s\n', strjoin([{'Elevation'}, repmat({num2str(obj.NoValue)}, 1, 5), arrayfun(@num2str, obj.Z, 'UniformOutput', false)], ','));
        
        % Codes
        fprintf(ID_File, '%s\n', strjoin([{'Year','Month','Day','Hour','Minute','Second'}, arrayfun(@num2str, reshape(obj.Code,1,[]), 'UniformOutput', false)], ','));
        
        % =====================================================================
        % PREPARAR Y ESCRIBIR DATOS TEMPORALES
        % =====================================================================
        
        % Crear componentes de fecha
        dateComponents = [year(obj.Date) month(obj.Date) day(obj.Date) ...
                         hour(obj.Date) minute(obj.Date) second(obj.Date)];
        
        % Preparar datos para escritura
        dataToWrite = obj.(varName);
        
        % Convertir valores NaN a NoValue
        nanMask = isnan(dataToWrite);
        dataToWrite(nanMask) = obj.NoValue;
        
        % Escribir datos con formato específico
        formatStr = ['%d,%d,%d,%d,%d,%d', repmat(',%.2f', 1, length(obj.Code)), '\n'];
        fprintf(ID_File, formatStr, [dateComponents, dataToWrite]');
        
        % =====================================================================
        % RESTAURAR VALORES NaN EN OBJETO ORIGINAL
        % =====================================================================
        
        % Restaurar NaN en el objeto
        obj.(varName)(nanMask) = NaN;
        
    catch ME
        fclose(ID_File);
        rethrow(ME);
    end
    
    % =====================================================================
    % CERRAR ARCHIVO Y MENSAJE FINAL
    % =====================================================================
    
    fclose(ID_File);
    
    if verbose
        fprintf('Archivo escrito exitosamente.\n');
        fprintf('Valores NaN convertidos: %d\n', sum(nanMask(:)));
        fprintf('Valores NaN restaurados en objeto.\n\n');
    end

end
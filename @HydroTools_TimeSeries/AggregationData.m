function obj = AggregationData(obj, Resolution, Type, varargin)
% AGGREGATIONDATA Realiza agregación temporal de series de tiempo
%
% SYNTAX:
%   obj = AggregationData(obj, Resolution, Type)
%   obj = AggregationData(obj, Resolution, Type, StationCodes)
%   obj = AggregationData(obj, Resolution, Type, 'Verbose', true)
%
% DESCRIPTION:
%   Esta función realiza la agregación de series de tiempo contenidas en un
%   objeto de datos, permitiendo cambiar la resolución temporal mediante
%   diferentes funciones estadísticas de agregación.
%
% INPUT PARAMETERS:
%   obj        - [struct] Estructura con datos de series de tiempo que debe contener:
%                * Date: [datetime array] Vector de fechas
%                * Data: [double matrix] Matriz de datos (filas=tiempo, columnas=estaciones)
%                * Code: [cell array] Códigos de identificación de estaciones
%                * Name: [cell array] Nombres de las estaciones
%                * Type, Longitude, Latitude, X, Y, Z: [arrays] Metadatos opcionales
%   
%   Resolution - [char] Resolución temporal de agregación. Opciones válidas:
%                * 'Minute'  : Agregación por minutos
%                * 'Hourly'  : Agregación por horas  
%                * 'Daily'   : Agregación por días
%                * 'Monthly' : Agregación por meses
%                * 'Yearly'  : Agregación por años
%                * 'MMM'     : Agregación climatológica por mes (año fijo 1900)
%   
%   Type       - [char] Función de agregación. Opciones válidas:
%                * 'Mean'     : Promedio aritmético
%                * 'NAN_Mean' : Promedio ignorando valores NaN
%                * 'Sum'      : Suma de valores
%                * 'NaN_Sum'  : Suma ignorando valores NaN
%                * 'Min'      : Valor mínimo
%                * 'Max'      : Valor máximo
%
% OPTIONAL PARAMETERS:
%   StationCodes - [numeric array, default: []] Códigos numéricos de estaciones específicas
%   'Verbose'    - [logical, default: false] Muestra información detallada
%
% OUTPUT PARAMETERS:
%   obj        - [struct] Estructura de datos agregados con la misma estructura
%                de entrada pero con resolución temporal modificada y datos
%                agregados según la función especificada.
%
% EXAMPLES:
%   % Agregación diaria usando promedio
%   obj_daily = AggregationData(obj, 'Daily', 'Mean');
%   
%   % Agregación mensual para estaciones específicas
%   codes = [233200, 233213, 233215];
%   obj_monthly = AggregationData(obj, 'Monthly', 'Sum', codes);
%   
%   % Con información detallada
%   obj_hourly = AggregationData(obj, 'Hourly', 'NAN_Mean', 'Verbose', true);
%
% SEE ALSO:
%   datetime, varfun, table, mean, sum
%
% -------------------------------------------------------------------------
% Matlab - R2024b y versiones superiores
% -------------------------------------------------------------------------
%                           Información del Autor
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Versión       : 3.0 - Simplificada bajo filosofía "simple es mejor"
% Fecha         : 2025
%--------------------------------------------------------------------------

    % =====================================================================
    % PARSING SIMPLE DE PARÁMETROS 
    % =====================================================================
    
    % Crear inputParser básico
    p               = inputParser;
    p.KeepUnmatched = false;
    
    % Validaciones simples
    addRequired(p, 'obj', @isobject);
    addRequired(p, 'Resolution', @ischar);
    addRequired(p, 'Type', @ischar);
    addOptional(p, 'StationCodes', [], @(x) isempty(x) || isnumeric(x));
    addParameter(p, 'Verbose', false, @islogical);
    
    parse(p, obj, Resolution, Type, varargin{:});
    
    % Extraer parámetros
    stationCodes    = p.Results.StationCodes;
    verbose         = p.Results.Verbose;
    
    % =====================================================================
    % CONFIGURACIÓN DE FUNCIÓN DE AGREGACIÓN (TU LÓGICA ORIGINAL MEJORADA)
    % =====================================================================
    
    % Funciones de agregación - simple y directo
    switch Type
        case 'NAN_Mean'
            MyFun = @(x) mean(x,'omitnan');
        case 'NaN_Sum'
            MyFun = @(x) sum(x,'omitnan');
        case 'Mean'
            MyFun = @(x) mean(x);
        case 'Sum'
            MyFun = @(x) sum(x);
        case 'Min'
            MyFun = @(x) min(x);
        case 'Max'
            MyFun = @(x) max(x);
        otherwise
            error('Tipo de agregación no válido: %s', Type);
    end
    
    % =====================================================================
    % PROCESAMIENTO DE ESTACIONES (CORREGIDO PARA CÓDIGOS NUMÉRICOS)
    % =====================================================================
    
    if ~isempty(stationCodes)
        [~, stationIdx] = ismember(stationCodes, obj.Code);
        if any(stationIdx == 0)
            warning('Algunos códigos de estación no fueron encontrados');
            stationIdx = stationIdx(stationIdx > 0);
        end
    else
        stationIdx = 1:length(obj.Code);
    end
    
    if verbose
        fprintf('\n=== AGREGACIÓN TEMPORAL ===\n');
        fprintf('Resolución: %s ? %s\n', char(obj.Date(2) - obj.Date(1)), Resolution);
        fprintf('Función: %s\n', Type);
        fprintf('Estaciones: %d de %d\n', length(stationIdx), length(obj.Code));
        fprintf('==========================\n');
    end
    
    % =====================================================================
    % CREACIÓN DE TABLA (CORREGIDA PARA MÚLTIPLES ESTACIONES)
    % =====================================================================
    
    nStations = length(stationIdx);
    NameCol = cell(1, nStations + 6);
    NameCol{1} = 'Date';
    
    for i = 1:nStations
        NameCol{i+1} = ['Gauges_', num2str(i)];
    end
    NameCol(end-4:end) = {'Y', 'M', 'D', 'H', 'MM'};
    
    % Extraer datos seleccionados y componentes de fecha
    selectedData = obj.Data(:, stationIdx);
    dateComponents = [year(obj.Date), month(obj.Date), day(obj.Date), ...
                     hour(obj.Date), minute(obj.Date)];
    
    % Crear tabla expandiendo selectedData por columnas
    tableData = [table(obj.Date, 'VariableNames', {'Date'}), ...
                 array2table(selectedData, 'VariableNames', NameCol(2:nStations+1)), ...
                 array2table(dateComponents, 'VariableNames', NameCol(end-4:end))];
    
    Table_i = tableData;
    
    % =====================================================================
    % AGREGACIÓN SEGÚN RESOLUCIÓN (TU LÓGICA ORIGINAL)
    % =====================================================================
    
    dataColumns = NameCol(2:end-5);
    
    if strcmp(Resolution,'Minute')
        Tmp = table2array(varfun(MyFun,Table_i,'GroupingVariables',{'Y','M','D','H','MM'},'InputVariable',dataColumns));
        obj.Date    = datetime(Tmp(:,1), Tmp(:,2), Tmp(:,3), Tmp(:,4), Tmp(:,5), ones(size(Tmp,1),1));
        obj.Data    = Tmp(:,7:end);
        
    elseif strcmp(Resolution,'Hourly')
        Tmp = table2array(varfun(MyFun,Table_i,'GroupingVariables',{'Y','M','D','H'},'InputVariable',dataColumns));
        obj.Date    = datetime(Tmp(:,1), Tmp(:,2), Tmp(:,3), Tmp(:,4), ones(size(Tmp,1),1), ones(size(Tmp,1),1));
        obj.Data    = Tmp(:,6:end);
        
    elseif strcmp(Resolution,'Daily')
        Tmp = table2array(varfun(MyFun,Table_i,'GroupingVariables',{'Y','M','D'},'InputVariable',dataColumns));
        obj.Date    = datetime(Tmp(:,1), Tmp(:,2), Tmp(:,3), ones(size(Tmp,1),1), ones(size(Tmp,1),1), ones(size(Tmp,1),1));
        obj.Data    = Tmp(:,5:end);
        
    elseif strcmp(Resolution,'Monthly')
        Tmp = table2array(varfun(MyFun,Table_i,'GroupingVariables',{'Y','M'},'InputVariable',dataColumns));
        obj.Date    = datetime(Tmp(:,1), Tmp(:,2), ones(size(Tmp,1),1), zeros(size(Tmp,1),1), zeros(size(Tmp,1),1), zeros(size(Tmp,1),1));
        obj.Data    = Tmp(:,4:end);
        
    elseif strcmp(Resolution,'Yearly')
        Tmp = table2array(varfun(MyFun,Table_i,'GroupingVariables',{'Y'},'InputVariable',dataColumns));
        obj.Date    = datetime(Tmp(:,1), ones(size(Tmp,1),1), ones(size(Tmp,1),1), zeros(size(Tmp,1),1), zeros(size(Tmp,1),1), zeros(size(Tmp,1),1));
        obj.Data    = Tmp(:,3:end);    
        
    elseif strcmp(Resolution,'MMM')
        Tmp = table2array(varfun(MyFun,Table_i,'GroupingVariables',{'M'},'InputVariable',dataColumns));
        obj.Date    = datetime(repmat(1900, size(Tmp,1), 1), Tmp(:,1), ones(size(Tmp,1),1), zeros(size(Tmp,1),1), zeros(size(Tmp,1),1), zeros(size(Tmp,1),1));
        obj.Data    = Tmp(:,3:end);
        
    else
        error('Resolución no válida: %s', Resolution);
    end  
    
    % =====================================================================
    % ACTUALIZACIÓN DE METADATOS (TU ESTILO ORIGINAL CONSERVADO)
    % =====================================================================
    
    % Name
    if isprop(obj, 'Name') && ~isempty(obj.Name)
        obj.Name = obj.Name(stationIdx);
    end
    
    % Type
    if isprop(obj, 'Type') && ~isempty(obj.Type)
        obj.Type = obj.Type(stationIdx);
    end
    
    % Longitude
    if isprop(obj, 'Longitude') && ~isempty(obj.Longitude)
        obj.Longitude = obj.Longitude(stationIdx);
    end
    
    % Latitude
    if isprop(obj, 'Latitude') && ~isempty(obj.Latitude)
        obj.Latitude = obj.Latitude(stationIdx);
    end
    
    % Coordinate X
    if isprop(obj, 'X') && ~isempty(obj.X)
        obj.X = obj.X(stationIdx);
    end
    
    % Coordinate Y
    if isprop(obj, 'Y') && ~isempty(obj.Y)
        obj.Y = obj.Y(stationIdx);
    end
    
    % Elevation
    if isprop(obj, 'Z') && ~isempty(obj.Z)
        obj.Z = obj.Z(stationIdx);
    end
    
    % Code
    obj.Code = obj.Code(stationIdx);
    
    % Delta time
    if length(obj.Date) > 1
        obj.dt = obj.Date(2) - obj.Date(1);
    end
    
    if verbose
        fprintf('Agregación completada: %d registros x %d estaciones\n\n', size(obj.Data, 1), size(obj.Data, 2));
    end

end
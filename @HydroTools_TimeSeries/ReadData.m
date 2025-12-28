function obj = ReadData(obj, NameFile, varargin)
% READDATA Lee datos de series de tiempo desde archivos CSV con formato específico
%
% SYNTAX:
%   obj = ReadData(obj, NameFile)
%   obj = ReadData(obj, NameFile, 'NameVarRead', 'Data')
%   obj = ReadData(obj, NameFile, 'Verbose', true)
%
% DESCRIPTION:
%   Esta función lee datos de series de tiempo desde archivos CSV con un formato
%   específico de header (13 líneas) que contiene metadatos de las estaciones y
%   posteriormente los datos temporales. Asigna automáticamente valores NaN a 
%   los datos que coincidan con NoValue.
%
% INPUT PARAMETERS:
%   obj      - [HydroTools_TimeSeries] Objeto de la clase a cargar con datos
%   
%   NameFile - [char] Ruta completa del archivo CSV a leer. El archivo debe tener:
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
%   'NameVarRead'  - [char, default: 'Data'] Nombre de la propiedad del objeto donde
%                    almacenar los datos leídos
%   
%   'Verbose'      - [logical, default: false] Si es true, muestra información
%                    detallada del proceso de lectura
%
% OUTPUT PARAMETERS:
%   obj - [HydroTools_TimeSeries] Objeto con todas las propiedades cargadas:
%         * Metadatos: Var, Unit, Source, NoValue, EPSG
%         * Información espacial: Name, Type, Longitude, Latitude, X, Y, Z, Code
%         * Datos temporales: Date, Data (o NameVarRead), dt
%
% EXAMPLES:
%   % Lectura básica de datos
%   obj = HydroTools_TimeSeries();
%   obj = ReadData(obj, 'datos_estaciones.csv');
%   
%   % Lectura con información detallada
%   obj = ReadData(obj, 'precipitacion.csv', 'Verbose', true);
%   
%   % Almacenar en propiedad diferente
%   obj = ReadData(obj, 'temperatura.csv', 'NameVarRead', 'Temperature');
%
% NOTES:
%   - El archivo debe seguir exactamente el formato de header especificado
%   - Los valores que coincidan con NoValue se convierten automáticamente a NaN
%   - Se calcula automáticamente dt (delta time) entre las primeras dos fechas
%
% SEE ALSO:
%   textscan, datetime, inputParser, fopen
%
% -------------------------------------------------------------------------
% Matlab - R2024b y versiones superiores
% -------------------------------------------------------------------------
%                           Información del Autor
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Versión       : 2.0 - Mejorada con inputParser y verbose
% Fecha         : 2025
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los términos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener. Para mayor información revisar 
% http://www.gnu.org/licenses/.
%
% -------------------------------------------------------------------------

    % =====================================================================
    % VALIDACIÓN Y PARSING DE PARÁMETROS CON INPUTPARSER
    % =====================================================================
    
    % Crear y configurar inputParser
    p                   = inputParser;
    p.KeepUnmatched     = false;
    p.CaseSensitive     = false;
    p.PartialMatching   = true;
    
    % Funciones de validación
    validFile           = @(x) ischar(x) || isstring(x);
    validVarName        = @(x) ischar(x) && isvarname(x);
    validLogical        = @(x) islogical(x) || (isnumeric(x) && (x == 0 || x == 1));
    
    % Definir parámetros
    addRequired(p, 'NameFile', validFile);
    addParameter(p, 'NameVarRead', 'Data', validVarName);
    addParameter(p, 'Verbose', true, validLogical);
    
    % Parsear inputs
    parse(p, NameFile, varargin{:});
    
    % Extraer parámetros parseados
    NameFile        = char(p.Results.NameFile);
    NameVarRead     = p.Results.NameVarRead;
    Verbose         = p.Results.Verbose;
    
    % =====================================================================
    % LECTURA DE METADATOS (TU CÓDIGO ORIGINAL FUNCIONANDO)
    % =====================================================================
    
    if Verbose
        fprintf('\n=== LECTURA DE DATOS DE SERIES DE TIEMPO ===\n');
        fprintf('Archivo: %s\n', NameFile);
        fprintf('Variable destino: %s\n', NameVarRead);
        fprintf('Leyendo metadatos...\n');
    end
    
    % Load Data - Tu código original
    ID_File     = fopen(NameFile,'r');
    Linetext    = fgetl(ID_File);
    Count       = 1;
    
    while Count < 14
        if (Count == 1)
            Tmp     = strsplit(Linetext,',');
            obj.Var = Tmp{2};                
        elseif (Count == 2)
            Tmp     = strsplit(Linetext,',');
            obj.Unit= Tmp{2};                
        elseif (Count == 3)
            Tmp     = strsplit(Linetext,',');
            obj.Source  = Tmp{2};
        elseif (Count == 4)
            Tmp     = strsplit(Linetext,',');
            obj.NoValue = str2double(Tmp{2});
        elseif (Count == 5)    
            Tmp     = strsplit(Linetext,',');
            obj.EPSG    = str2double(Tmp{2});
        elseif (Count == 6)
            Tmp     = strsplit(Linetext,',');
            obj.Name    = Tmp(7:end);
        elseif (Count == 7)
            Tmp     = strsplit(Linetext,',');
            obj.Type    = Tmp(7:end);
        elseif (Count == 8)
            Tmp     = strsplit(Linetext,',');
            obj.Longitude       = cellfun(@str2num,Tmp(7:end));
        elseif (Count == 9)
            Tmp     = strsplit(Linetext,',');
            obj.Latitude       = cellfun(@str2num,Tmp(7:end));
        elseif (Count == 10)
            Tmp     = strsplit(Linetext,',');
            obj.X       = cellfun(@str2num,Tmp(7:end));
        elseif (Count == 11)
            Tmp     = strsplit(Linetext,',');
            obj.Y       = cellfun(@str2num,Tmp(7:end));
        elseif (Count == 12)
            Tmp     = strsplit(Linetext,',');
            obj.Z       = cellfun(@str2num,Tmp(7:end));
        elseif (Count == 13)
            Tmp     = strsplit(Linetext,',');
            obj.Code    = cellfun(@str2num,Tmp(7:end));
        end
        
        Count = Count + 1;
        Linetext    = fgetl(ID_File);
    end
    fclose(ID_File);
    
    nStations = length(obj.Code);
    
    if Verbose
        fprintf('Metadatos leídos exitosamente:\n');
        fprintf('  Variable: %s [%s]\n', obj.Var, obj.Unit);
        fprintf('  Fuente: %s\n', obj.Source);
        fprintf('  EPSG: %g\n', obj.EPSG);
        fprintf('  Valor nulo: %g\n', obj.NoValue);
        fprintf('  Estaciones: %d\n', nStations);
        fprintf('Leyendo datos temporales...\n');
    end
    
    % =====================================================================
    % LECTURA DE DATOS TEMPORALES (SIN EVAL - MEJORADO)
    % =====================================================================
    
    % Load Data - Mejorado sin eval()
    ID_File         = fopen(NameFile,'r');
    Format          = ['%d%d%d%d%d%d',repmat('%f',1,length(obj.Code))];
    rawData         = textscan(ID_File,Format,'Delimiter',',','Headerlines',13);
    fclose(ID_File);
    
    % No tomar hora minuto segundo - Sin eval()
    obj.Date = datetime(cell2mat(rawData(1:3)));
    
    % Extraer datos de estaciones - Sin eval()
    stationData = cell2mat(rawData(7:end));
    
    % Asignar a la propiedad especificada - Sin eval()
    obj.(NameVarRead) = stationData;
    
    % Convertir NoValue a NaN - Sin eval()
    invalidIdx = obj.(NameVarRead) == obj.NoValue;
    obj.(NameVarRead)(invalidIdx) = NaN;
    
    % Paso de tiempo - Tu código original
    obj.dt = obj.Date(2) - obj.Date(1);
    
    % =====================================================================
    % INFORMACIÓN VERBOSE OPCIONAL
    % =====================================================================
    
    if Verbose
        nRecords = length(obj.Date);
        totalValues = numel(obj.(NameVarRead));
        nanValues = sum(isnan(obj.(NameVarRead)(:)));
        validValues = totalValues - nanValues;
        
        fprintf('Datos temporales leídos:\n');
        fprintf('  Registros: %s\n', sprintf('%s', regexprep(sprintf('%.0f', nRecords), '(\d)(?=(\d{3})+(?!\d))', '$1,')));
        fprintf('  Período: %s a %s\n', char(obj.Date(1)), char(obj.Date(end)));
        fprintf('  Delta time: %s\n', char(obj.dt));
        fprintf('  Valores totales: %s\n', sprintf('%s', regexprep(sprintf('%.0f', totalValues), '(\d)(?=(\d{3})+(?!\d))', '$1,')));
        fprintf('  Valores válidos: %s (%.1f%%)\n', sprintf('%s', regexprep(sprintf('%.0f', validValues), '(\d)(?=(\d{3})+(?!\d))', '$1,')), 100*validValues/totalValues);
        fprintf('  Valores NaN: %s (%.1f%%)\n', sprintf('%s', regexprep(sprintf('%.0f', nanValues), '(\d)(?=(\d{3})+(?!\d))', '$1,')), 100*nanValues/totalValues);
        fprintf('Lectura completada exitosamente.\n');
        fprintf('==========================================\n\n');
    end

end
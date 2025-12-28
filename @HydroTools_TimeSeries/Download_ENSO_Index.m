function IndexResults = Download_ENSO_Index(obj, varargin)
% -------------------------------------------------------------------------
% Matlab - R2019b 
% -------------------------------------------------------------------------
%                           Información Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Componente    : Modelación Hidrologica
% Fecha         : Marzo-2022
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los términos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener.Para mayor información revisar 
% http://www.gnu.org/licenses/.
%
% -------------------------------------------------------------------------
% Descripción del Codigo
% -------------------------------------------------------------------------
% Este código descarga las series de tiempo de los indicadores océanicos y 
% atmosféricos del ENSO de la página https://psl.noaa.gov/enso/data.html y 
% los organiza en el formato de la librería HydroTools
%
% -------------------------------------------------------------------------
% Coordenada de las regiones donde se mide la temperatura en el océano 
% -------------------------------------------------------------------------
% AMO       : Indice de temperaturas del Atl´antico Norte
% BEST      : Combinación del SOI estandarizado y las SST estandarizada en 
%             la zona niño 3-4
% MEI       : Indice de intensidad de El Ni~no combinando las series 
%             variables más relevantes: presi´on al nivel del mar, 
%             componentes del viento superficial zonal y meridional, SST, 
%             temperatura del aire superficial, fracción de nubosidad total 
%             del cielo
% NAO       : Se define tradicionalmente como el gradiente de presión 
%             normalizado entre una estación en los Azores y otra en 
%             Islandia
% NINO1+2   : SST en la regi´on del extremo este pacifico tropical
% NINO3     : SST en la regi´on del oeste pacifico tropical
% NINO3     : SST en la regi´on del centro pacifico tropical
% NINO3.4   : SST en la regi´on del centro-este pacifico tropical
% ONI       : Media móvil de las anomal´?as en la SST en la zona 3.4 del 
%             pacífico basado en un promedio de referencia dado por 30 años, 
%             esta referencia tiene 5 años de vigencia
% PDO       : Series de componentes principales (CP) estandarizados de las 
%             anomalías de la SST en el pacifico norte
% PNA       : Patrón de alternancia entre las presiones atmosféricas en el 
%             océano pacifico central y centros de acci´on en el este del 
%             océano de Canadá y el suroeste Estadounidense
% QBO       : oscilación del sentido de la componente zonal del viento en 
%             alturas entre los 30 y los 50 hPa, que cambia de sentido 
%             aproximadamente cada dos a~nos. Esta oscilación está limitada 
%             latitudinalmente entre los 12?N y los 12?S, aunque se puede 
%             identificar en latitudes fuera de ese intervalo
% SOI       : Presión al nivel del mar, diferencias estandarizadas entre 
%             anomalías en Tahití y Darwin
% Solar Flux: Reporte del flujo solar evaluado por el National Research 
%             Council, en español Concejo nacional de investigación, 
%             Canada (NRC)
% TNA       : Anomalías del promedio mensual de SST entre 5.5?N, 23.5?N 
%             y 15?W a 57.5?W
% TNI       : Diferencia estandarizada entre SST NINO1+2 y SST en el 
%             pacífico tropical, región central (NINO4) con una media 
%             móvil de 5 meses de periodo.
% TSA       : Anomalías del promedio mensual de SST entre el Ecuador (0?) 
%             y los 20?S y 10?E a 30?W
% WHWP      : Anomalía mensual del área de la superficie del mar con 
%             temperaturas mayores a 28.5?C en el atl´antico y pacifico 
%             noroeste
% WP        : Dipolo norte-sur de anomalías, con un centro ubicado sobre la
%             península de Kamchatka y otro amplio centro de signos opuestos 
%             que cubre porciones del sudeste asiático y el Pacífico 
%             subtropical occidental del norte.
%
% -------------------------------------------------------------------------
% Páginas web para descargar las series de tiempo de los indicadores
% -------------------------------------------------------------------------
% Web site total -> https://psl.noaa.gov/data/climateindices/list/

if nargin > 1
    NameFileR = varargin{1};
else
    NameFileR = fullfile(obj.PathProject, 'RESULTS','ENSO_Index');
end

%% Directorios
% obj.PathProject = pwd;
mkdir(fullfile(NameFileR,'Raw_ENSO-Index'))

%% URL de los sitios web donde descargar los datos
WebPath         = struct;
WebPath.AMO     = 'https://psl.noaa.gov/data/correlation/amon.us.data';
WebPath.BEST    = 'https://psl.noaa.gov/data/correlation/censo.data';
WebPath.MEI     = 'https://psl.noaa.gov/enso/mei/data/meiv2.data';
WebPath.NAO     = 'https://psl.noaa.gov/data/correlation/nao.data';
WebPath.Nino12  = 'https://psl.noaa.gov/data/correlation/nina1.anom.data';
WebPath.Nino3   = 'https://psl.noaa.gov/data/correlation/nina3.anom.data';
WebPath.Nino34  = 'https://psl.noaa.gov/data/correlation/nina34.anom.data';
WebPath.Nino4   = 'https://psl.noaa.gov/data/correlation/nina4.anom.data';
WebPath.ONI     = 'https://psl.noaa.gov/data/correlation/oni.data';
WebPath.PDO     = 'https://psl.noaa.gov/data/correlation/pdo.data';
WebPath.PNA     = 'https://psl.noaa.gov/data/correlation/pna.data';
WebPath.QBO     = 'https://psl.noaa.gov/data/correlation/qbo.data';
WebPath.SOI     = 'https://psl.noaa.gov/data/correlation/soi.data';
WebPath.SolarF  = 'https://psl.noaa.gov/data/correlation/solar.data';
WebPath.TNA     = 'https://psl.noaa.gov/data/correlation/tna.data';
WebPath.TNI     = 'https://psl.noaa.gov/data/correlation/tni.data';
WebPath.TSA     = 'https://psl.noaa.gov/data/correlation/tsa.data';
WebPath.WHWP    = 'https://psl.noaa.gov/data/correlation/whwp.data';
WebPath.WPI     = 'https://psl.noaa.gov/data/correlation/wp.data';
NameIndex       = fieldnames(WebPath);

%% Almac
IndexResults            = obj.copy();
IndexResults.Var        = 'ENSO Index';
IndexResults.Unit       = 'Ad';                
IndexResults.Source     = 'NOAA - https://psl.noaa.gov/data/climateindices/list/';
IndexResults.NoValue    = -99;
IndexResults.EPSG       = -99;
IndexResults.Name       = NameIndex;
IndexResults.Type       = NameIndex;
IndexResults.Longitude  = repmat(-99,1,length(NameIndex));
IndexResults.Latitude   = repmat(-99,1,length(NameIndex));
IndexResults.X          = repmat(-99,1,length(NameIndex));
IndexResults.Y          = repmat(-99,1,length(NameIndex));
IndexResults.Z          = repmat(-99,1,length(NameIndex));
IndexResults.Code       = 1:length(NameIndex);
IndexResults.Date       = (datetime(1900,1,1):calmonths:datetime(year(datetime('today')),12,1))';
IndexResults.dt         = IndexResults.Date(2) - IndexResults.Date(1);
IndexResults.Data       = NaN(length(IndexResults.Date),length(NameIndex));

%% Descarga de indicadores
for i = 1:length(NameIndex)
    % Descarga de datos en formato de texto plano
    Options = weboptions("ContentType", "text");
    Data    = webread( getfield(WebPath, NameIndex{i}),Options);
    
    % Guardar datos originales en txt
    NameFile    = fullfile(NameFileR,'Raw_ENSO-Index',[NameIndex{i},'.txt']);
    ID_File     = fopen(NameFile,'w');
    fprintf(ID_File,Data);
    fclose(ID_File);

    % convertir datos en un arreglo matricial   
    ID_File     = fopen(NameFile,'r');
    Linetext    = fgetl(ID_File);
    YearData    = str2num(Linetext);
    YearData    = (YearData(1):YearData(2))';
    Data        = zeros(length(YearData),13);
    for j = 1:length(YearData)
        Linetext        = fgetl(ID_File);
        Tmp             = strsplit( Linetext,' ');   
        if isempty(Tmp{1})
            Data(j,:)   = cellfun(@str2num,Tmp(2:end));
        else
            Data(j,:)   = cellfun(@str2num,Tmp(1:13));                    
        end
    end
    fclose(ID_File);
    Data(Data == -99.9)     = NaN;
    Data(Data == -999)      = NaN;
    Data(Data == -99.99)    = NaN;
    
    % Convertir datos en serie de tiempo   
    Date    = (datetime(YearData(1),1,1):calmonths:datetime(YearData(end),12,1))';
    Data    = reshape(Data(:,2:end)',[],1);
    
    % Agregar a hydrotools
    [id,posi] = ismember(Date,IndexResults.Date);   
    IndexResults.Data(posi(id),i) = Data(id);    
end

%% Guardar
IndexResults.WriteData(fullfile(NameFileR,'ENSO_Index.csv'))

function Test_Rachas_Est(obj, varargin)
% -------------------------------------------------------------------------
% Matlab - R2018b 
% -------------------------------------------------------------------------
%                           Informaci?n Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Componente    : Modelaci?n Hidrologica
% Organizaci?n  : The Nature Conservancy - TNC
% Fecha         : 01- July - 2019
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los t?rminos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener.Para mayor informaci?n revisar 
% http://www.gnu.org/licenses/.
%
% -------------------------------------------------------------------------
% Proyecto
%--------------------------------------------------------------------------
% Consultor?a t?cnica para el an?lisis de la cuenca alta y propuesta de 
% medidas de conservaci?n que contribuyan a la resiliencia de la cuenca del
% r?o Juan D?az en ciudad de Panam? para la mitigaci?n del riesgo por 
% inundaci?n
%
% -------------------------------------------------------------------------
% Descripci?n del Codigo
% -------------------------------------------------------------------------
% Este c?digo permite descargar la informaci?n de precipitaci?n, temperatura 
% m?nima y m?xima a resoluci?n diaria de los modelos meteorol?gicos globales 
% que modelan el cambio clim?tico (GCM). En total son 21 GCM de los cuales 
% se descarga la informaci?n, tanto para el hist?rico como para los 
% escenarios rcp45 y rcp85 
%
% -------------------------------------------------------------------------
% Input Data
% -------------------------------------------------------------------------
% 
% -------------------------------------------------------------------------
% Output Data
% -------------------------------------------------------------------------
%
% Var: variable, 1 para precipitacion, 0 para las demas

warning off

if nargin > 1
    Code_PoPo = varargin{1}; 
else
    Code_PoPo = [];
end

if ~isempty(Code_PoPo)
    [~, PoPo] = ismember(Code_PoPo, obj.Code);
else
    PoPo = 1:length(obj.Code);
end

% moving average of order 
if nargin > 2
    m = floor(varargin{2});
else
    m = 10;
end

%% Create Folder
mkdir(fullfile(obj.PathProject,'RESULTS','Random'))

Rachas  = zeros(length(PoPo),2);
Esta    = zeros(length(PoPo),2);
for ii = 1:length(PoPo)  
    try
        id          = find(~isnan(obj.Data(:,PoPo(ii))));
        Data        = obj.Data(id(1):id(end),PoPo(ii));   

%         %% Clear NaN
%         id      = ~isnan(Data);
%         Data    = Data(id);
%         Data(Data == 0) = 0.1;
% 
%         %% Log
%         Data = log(Data);
% 
%         %% Average Moving
%         w = ((2*m) + 1);
%         n = length(Data);
% 
% %         Results = zeros(n-w+1,1);
%         Results = zeros(n-m-w+1,1);
%         for i = m+1:n-w+1
%             Results(i-m) = mean(Data(i-m:i+m),'omitnan');
%         end
%     %     Data = Data(m+1:n-m) - Results;
%         Data = Results;
% 
%         %% Tranformation Series
%         % Centralizamos
%         Data = Data - mean(Data, 'omitnan');
%         % Estandarizamos
%         Data = Data./std(Data, 'omitnan');

        %% Test de Rachas 
        [h,p] = runstest(Data);
        Rachas(ii,:) = [h,p];
        
        %% Test de Estacionaridad
        [h,p] = adftest(Data);
        Esta(ii,:) = [h,p];        
        
        disp(['Test Rachas ok for Gauges ->',num2str(obj.Code(PoPo(ii)))])
    catch
        disp(['Error in Gauges ->',num2str(obj.Code(PoPo(ii)))])
    end
    
end

Code = obj.Code(PoPo);
Code = reshape(Code,length(Code),1);

%% Save Rachas
NameFile    = fullfile(obj.PathProject,'RESULTS','Random','Rachas_Test_Normal.csv');
ID_File     = fopen(NameFile,'w');

fprintf(ID_File,'%s\n','Code,Test,pValue');
fprintf(ID_File, '%d,%d,%f\n',[Code, Rachas]');
fclose(ID_File);

%% Save Alearory
NameFile    = fullfile(obj.PathProject,'RESULTS','Random','Estacionareidad_Test_Normal.csv');
ID_File     = fopen(NameFile,'w');

fprintf(ID_File,'%s\n','Code,Test,pValue');
fprintf(ID_File, '%d,%d,%f\n',[Code, Esta]');
fclose(ID_File);

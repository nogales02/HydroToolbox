function IntegrationMonthly(obj, varargin)
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

%% Preliminary
warning off

%% Name Function
if nargin > 1
    NameFun = varargin{1}; 
else
    NameFun = 'Mean';
end

%% Codes
if nargin > 2
    Code_PoPo = varargin{1}; 
else
    Code_PoPo = [];
end

if ~isempty(Code_PoPo)
    [~, PoPo] = ismember(Code_PoPo, obj.Code);
else
    PoPo = 1:length(obj.Code);
end

%% Initial Complementation
Results = NaN(12, length(PoPo) );

        
%% Select Month
for m = 1:12
    id = month(obj.Date) == m;
    Choco = NaN(length(obj.Date),1);
    Choco(id) = 1;
    if strcmp(NameFun,'Mean')                
        Results(m,:) = mean(bsxfun(@times,Choco,obj.Data),'omitnan');
    elseif strcmp(NameFun,'Min')
        Results(m,:) = min(bsxfun(@times,Choco,obj.Data));
    elseif strcmp(NameFun,'Max')
        Results(m,:) = max(bsxfun(@times,Choco,obj.Data));
    elseif strcmp(NameFun,'Sum')
        Results(m,:) = sum(bsxfun(@times,Choco,obj.Data),'omitnan');
    end
end

%% Assignation Data
obj.Data = Results;

%% Assignation Date 
Tmp = year(datetime(date));
obj.Date = (datetime(Tmp,1,1):calmonths:datetime(Tmp,12,1))';
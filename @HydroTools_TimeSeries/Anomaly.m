function Anomaly(obj)
% -------------------------------------------------------------------------
% Matlab - R2018b 
% -------------------------------------------------------------------------
%                           Informaciï¿½n Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Componente    : Modelaciï¿½n Hidrologica
% Organizaciï¿½n  : The Nature Conservancy - TNC
% Fecha         : 01- July - 2019
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los tï¿½rminos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener.Para mayor informaciï¿½n revisar 
% http://www.gnu.org/licenses/.
%
% -------------------------------------------------------------------------
% Proyecto
%--------------------------------------------------------------------------
% Consultorï¿½a tï¿½cnica para el anï¿½lisis de la cuenca alta y propuesta de 
% medidas de conservaciï¿½n que contribuyan a la resiliencia de la cuenca del
% rï¿½o Juan Dï¿½az en ciudad de Panamï¿½ para la mitigaciï¿½n del riesgo por 
% inundaciï¿½n
%
% -------------------------------------------------------------------------
% Descripciï¿½n del Codigo
% -------------------------------------------------------------------------
% Este cï¿½digo permite descargar la informaciï¿½n de precipitaciï¿½n, temperatura 
% mï¿½nima y mï¿½xima a resoluciï¿½n diaria de los modelos meteorolï¿½gicos globales 
% que modelan el cambio climï¿½tico (GCM). En total son 21 GCM de los cuales 
% se descarga la informaciï¿½n, tanto para el histï¿½rico como para los 
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

%% Estimación de media
Data_M      = mean(obj.Data,'omitnan');

%% Calculo de anomalia
Ano         = bsxfun(@minus,Data,Data_M);

%% Nash
obj.Data    = Ano;

end

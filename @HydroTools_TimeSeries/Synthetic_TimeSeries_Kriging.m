function [Date, Data] = Synthetic_TimeSeries_Kriging(obj,Coor_X, Coor_Y, varargin)
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

%% Mas Distance (meters)
if nargin > 3
    Maxdist = varargin{1};
else
    Maxdist = 50000;    
end

%% Semivariograms models to evaluate
% model   = {'circular','spherical','pentaspherical','exponential', 'gaussian'};
model   = {'circular','spherical','pentaspherical'};

Data = NaN(length(obj.Date),length(Coor_X));
Date = obj.Date;

%% Initial Complementation
for i = 1:length(obj.Date) 
    id = ~isnan(obj.Data(i,:));
    try                    
        %% Create Empiric Variogram                
        v       = variogram([obj.X(id)' obj.Y(id)'],obj.Data(i,id)','plotit',false, 'nrbins',sum(id),'maxdist',Maxdist);

        %% Fitting Teoric Variogram
        error   = -1E12;                
        for jj = 1:length(model)
            try
                [~,vstruct] = variogramfit(v.distance,v.val,[],[],[],'model',model{jj},'plotit',false);                    
                if vstruct.Rs > error
                    error = vstruct.Rs;
                    Model_ii    = jj;
                end
            catch
            end
        end

        %% Create Best Teoric Variogram 
        [~,vstruct] = variogramfit(v.distance,v.val,[],[],[],'model',model{Model_ii},'plotit',false);

        %% Interpolation Kriging
        [Data(i,:),~]   = kriging(vstruct,obj.X(id)', obj.Y(id)', obj.Data(i,id)', Coor_X, Coor_Y);                    
        id              = Data(i,:) > max(obj.Data(i,id)');
        Data(i,id)      = max(obj.Data(i,id)');
        
        disp(['Ok Date -> ',datestr(Date(i))])
    catch
        disp(['Error Date -> ',datestr(Date(i))])
        %disp(['No Hay datos sufcientes para construir el Semivariograma en la fecha -> ', datestr(obj.Date(i))])
        continue
    end
end      

Data(Data<0) = 0;
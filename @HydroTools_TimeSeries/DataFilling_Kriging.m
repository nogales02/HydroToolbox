function DataFilling_Kriging(obj,varargin)
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

%% Codes
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

%% Threshold Gauges
if nargin > 2
    ThresholdGauges = varargin{2};
else
    ThresholdGauges = 5;
end

%% Mas Distance (meters)
if nargin > 3
    Maxdist = varargin{3};
else
    Maxdist = 50000;    
end

if nargin > 4
    NaNStatus = varargin{4};
else
    NaNStatus = true;
end

if nargin > 5
    SaveStatus = varargin{4};
else
    SaveStatus = true;
end

%% size
[fil, col] = size(obj.Data);

%% Semivariograms models to evaluate
% model   = {'circular','spherical','pentaspherical','exponential', 'gaussian'};
model   = {'circular','spherical','pentaspherical'};

%% Initial Date
InitData    = zeros(length(obj.Code), 1);
EndData     = zeros(length(obj.Code), 1);
for i = 1:length(obj.Code)
    Ident           = (1:length(obj.Date));
    tmp             = Ident(~isnan(obj.Data(:,i)));
    if isempty(tmp)
        InitData(i,1)   = 1;
        EndData(i,1)    = length(obj.Date);
        continue
    end
    InitData(i,1)   = tmp(1) -1;
    EndData(i,1)    = tmp(end) + 1;
end

%% Estimate Max
M = month(obj.Date);
MaxData = zeros(12, length(obj.Code));
MinData = zeros(12, length(obj.Code));
for i = 1:12
    MaxData(i,:) = max(obj.Data(M==i,:));
    MinData(i,:) = min(obj.Data(M==i,:));
end

%% Initial Complementation
for ii = 1:length(PoPo) 
    try
        if NaNStatus
            idii    = find(~isnan(obj.Data(:,PoPo(ii))));
        else
            idii    = (1:length(obj.Date))';
        end
        
        Data    = obj.Data(idii(1):idii(end),PoPo(ii));   
        Date    = obj.Date(idii(1):idii(end));
        
%         Date_S  = month(Date)*100 + day(Date);
        
        %% NaN
        NaNValue = find(isnan(Data));

        %% Select Gauges by Interpolation
        X1      = obj.X(PoPo(ii));
        Y1      = obj.Y(PoPo(ii));

        % Distance
        Dist    = sqrt( (obj.X - X1).^2 + (obj.Y - Y1).^2 );
        Dist(PoPo(ii)) = 1E50;
        ID_Se   = find(Dist <= Maxdist);

        %% Data Seect
        Data2   = obj.Data(idii(1):idii(end),ID_Se); 

        for ijk = 1:length(NaNValue)%1:length(obj.Date)
            i   = NaNValue(ijk);                                 
            id  = ~isnan(Data2(i,:));

            if sum(id) == 0
                %disp(['Todas las estaciones estan vacias en la fecha -> ', datestr(obj.Date(i))])
                continue
            end        
            
            %% Estimation Mean Day 
%             Mean_Day = NaN;%mean(Data(Date_S == Date_S(ijk)), 'omitnan');
            
            if sum(id) >= ThresholdGauges            
                try                    
                    %% Create Empiric Variogram                
                    v       = variogram([obj.X(ID_Se(id))' obj.Y(ID_Se(id))'],Data2(i,id)','plotit',false, 'nrbins',sum(id),'maxdist',Maxdist);

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
                    [Zhat,~]    = kriging(vstruct,obj.X(ID_Se(id)), obj.Y(ID_Se(id)), Data2(i,id), obj.X(ii), obj.Y(ii));                    
                    
%                     if isnan(Mean_Day)
%                         Mean_Day = Zhat;
%                     end
                    
                    Data(i) = Zhat;

                    %% Disp
                    %disp(['Ok Complect Kriging Date -> ', datestr(obj.Date(i))])

                catch
                    %disp(['No Hay datos sufcientes para construir el Semivariograma en la fecha -> ', datestr(obj.Date(i))])
                    continue
                end
            else
                %disp(['Todas las estaciones estan vacias en la fecha -> ', datestr(obj.Date(i))])
                continue
            end
        end

        obj.Data(idii(1):idii(end),PoPo(ii)) = Data;
        
        disp([num2str((ii/length(PoPo))*100,'%.2f'),'% -> Ok Complect Kriging for Gauges ->',num2str(obj.Code(PoPo(ii)))])        
    catch
        disp(['Error Complect Kriging for Gauges ->',num2str(obj.Code(PoPo(ii)))])
    end
end

%% Remove Max and Min Data
for i = 1:12
    id = find(M == i);

    %% Ckeck Max data
    for j = 1:length(MaxData(1,:))
        idd = (obj.Data(M==i,j) > MaxData(i,j));
        obj.Data(id(idd), j) = MaxData(i,j);
    end

    %% Ckeck Min data
    for j = 1:length(MinData(1,:))
        idd = (obj.Data(M==i,j) < MinData(i,j));
        obj.Data(id(idd), j) = MinData(i,j);
    end
end

%% only for rainfall data
if NaNStatus
    for i = 1:length(obj.Code)    
        if InitData(i) == 1
            obj.Data(InitData(i),i)     = NaN;

        elseif InitData(i) > 1
            obj.Data(1:InitData(i),i)   = NaN;
        end

        if EndData(i) == fil
            obj.Data(EndData(i),i)      = NaN;

        elseif EndData(i) < fil
            obj.Data(EndData(i):fil,i)  = NaN;
        end    
    end
end

%% Save
if SaveStatus
    NameFile = fullfile(obj.PathProject,'RESULTS','ComplectData_Kriging.csv');
    obj.WriteData(NameFile);
end

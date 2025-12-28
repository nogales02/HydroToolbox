function DataFilling_LinealRegressionTemporal(obj,varargin)
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

if nargin > 2
    NaNStatus = varargin{2};
else
    NaNStatus = true;
end

if nargin > 3
    SaveStatus = varargin{3};
else
    SaveStatus = true;
end

%% size
[fil, col] = size(obj.Data);

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
        idii    = find(~isnan(obj.Data(:,PoPo(ii))));
        Data    = obj.Data(idii(1):idii(end),PoPo(ii));   
        Date    = obj.Date(idii(1):idii(end));
        
        %% NaN        
        NaNValue = isnan(Data);
        Meses    = month(Date);
        YearD    = year(Date);
        for m = 1:12
            id =  logical(NaNValue.*(Meses == m));
            if sum(i) == 1
                Data(id) = mean(Data(Meses == m),'omitnan');
                continue
            end

            %% Days               
            choco       = logical(ismember(day(Date), day(Date(id))).*ismember(Meses, month(Date(id))).*(~isnan(Data)));
            Val_d       = Data(choco);
            Val_Mean    = year(Date(choco));
            Val_Mean    = year(Date(choco));
            
            yu      = unique(year(Date(choco)));
            for y = 1:length(yu)
                oo = logical((YearD == yu(y)).*(Meses == m));
                Val_MM(Val_MM == yu(y)) = mean(Data(oo));
            end

            %% Month
            choco   = ismember(Meses, month(Date(id)));
            M       = Meses(choco);
            Val_m   = Data(choco);

            Input   = [ones(sum(id),1) mean(Val_d1,'omitnan')' std(Val_d1,'omitnan')',...
                       mean(Val_m1,'omitnan')' std(Val_m1,'omitnan')' obj.Z(ID_Se(id))'];                 
            Outputs = Data2(i,id)';
            Params  = mldivide(Input,Outputs);

            Input   = [1 mean(Val_d,'omitnan') std(Val_d,'omitnan'),...
                        mean(Val_m,'omitnan') std(Val_m,'omitnan') obj.Z(ii)];
            Data(i) = Input*Params;     

        end

        obj.Data(idii(1):idii(end),PoPo(ii)) = Data;
        
        disp([num2str((i/length(obj.Code(PoPo(ii))))*100,'%.2f') ,'% -> Ok Complect Temporal Lineal Regressition for Gauges ->',num2str(obj.Code(PoPo(ii)))]) 
        
    catch
        disp(['Error Complect Lineal-Regressition for Gauges ->',num2str(obj.Code(PoPo(ii)))])
    end
end

%% Remove Max and Min Data
M = month(obj.Date);
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

if SaveStatus
    NameFile = fullfile(obj.PathProject,'RESULTS','ComplectData_LinealRegressionTemporal.csv');
    obj.WriteData(NameFile);
end
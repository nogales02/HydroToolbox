function Metric_Cal   = FunctionObj(Basin, Param,varargin)
% -------------------------------------------------------------------------
% Matlab Version - R2018b 
% -------------------------------------------------------------------------
%                              BASE DATA 
% -------------------------------------------------------------------------
% 
% Author      : Jonathan Nogales Pimentel
% Email       : jonathannogales02@gmail.com
% Date        : November, 2017
% 
% -------------------------------------------------------------------------
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the 
% Free Software Foundation, either version 3 of the License, or option) any 
% later version. This program is distributed in the hope that it will be 
% useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
% ee the GNU General Public License for more details. You should have 
% received a copy of the GNU General Public License along with this program
% If not, see http://www.gnu.org/licenses/.
% -------------------------------------------------------------------------
%                               DESCRIPTION 
% -------------------------------------------------------------------------
% This is the obeject function by perform the Calibration of the ABCD-FP-D
% Model through of the Shuffled complex evolution
%
% -------------------------------------------------------------------------
% INPUT DATA
% -------------------------------------------------------------------------
% Param         [1, 9]      = Parameters of the Models
% UserData      [Struct]
%   .CalMode        [1 or 9]        = 1 for the Thomas Model Parameters 
%                                     0 for the Floodplains Model Parameters
%   .Date           [t,1]           = Date                                                                      [Datenum]
%   .ArcID          [Cat,1]         = ArcID                                                                     [Ad]
%   .BasinArea      [Cat,1]         = Basin Area                                                                [m^2]
%   .P              [t,Cat]         = Precipitation                                                             [mm]
%   .ET             [t,Cat]         = Potential Evapotranspiration                                              [mm]
%   .DemandSup      [t,Cat]         = Demand                                                                    [m^3]
%   .Returns        [t,Cat]         = Returns                                                                   [m^3]
%   .IDExtAgri      [Cat,1]         = ID of the HUA where to extraction Agricultural Demand                     [Ad]
%   .IDExtDom       [Cat,1]         = ID of the HUA where to extraction Domestic Demand                         [Ad]
%   .IDExtLiv       [Cat,1]         = ID of the HUA where to extraction Livestock Demand                        [Ad]
%   .IDExtMin       [Cat,1]         = ID of the HUA where to extraction Mining Demand                           [Ad]
%   .IDExtHy        [Cat,1]         = ID of the HUA where to extraction Hydrocarbons Demand                     [Ad]
%   .IDRetDom       [Cat,1]         = ID of the HUA where to return Domestic Demand                             [Ad]
%   .IDRetLiv       [Cat,1]         = ID of the HUA where to return Livestock Demand                            [Ad]
%   .IDRetMin       [Cat,1]         = ID of the HUA where to return Mining Demand                               [Ad]
%   .IDRetHy        [Cat,1]         = ID of the HUA where to return Hydrocarbons Demand                         [Ad]
%   .FloodArea      [t,Cat]         = Floodplain Area                                                           [m^2]
%   .Arc_InitNode   [t,Cat]         = Initial node of each section of the network                               [Ad]
%   .Arc_EndNode    [t,Cat]         = End node of each section of the network                                   [Ad] 
%   .DownGauges     [t,Cat]         = ID of the end node of accumulation                                        [Ad]
%   .PoPo           [n,1]           = ID of the HUA to calibrate                                                [Ad]
%   .PoPoFlood      [n,1]           = ID of the HUA to calibrate with floodplains                               [Ad]
%   .IDPoPo         [n,1]           = ID of the HUA where signate the model parameters to calibrate             [Ad]
%   .IDPoPoFlood    [n,1]           = ID of the HUA where signate the model parameters to calibrate floodplains [Ad]
%   .a              [Cat,1]         = Soil Retention Capacity                                                   [Ad]
%   .b              [Cat,1]         = Maximum Capacity of Soil Storage                                          [Ad]
%   .c              [Cat,1]         = Flow Fraction Soil - Aquifer                                              [Ad]
%   .d              [Cat,1]         = Flow Fraction Aquifer - Soil                                              [Ad]
%   .Trp            [CatFlood,1]    = Percentage lateral flow between river and floodplain                      [Ad]
%   .Tpr            [CatFlood,1]    = Percentage return flow from floodplain to river                           [Ad]
%   .Q_Umb          [CatFlood,1]    = Threshold lateral flow between river and floodplain                       [mm]
%   .V_Umb          [CatFlood,1]    = Threshold return flow from floodplain to river                            [mm]
%   .ParamExtSup    [t,Cat]         = Porcentage of Superficial Water Extraction                                [Ad]
%   .ArcIDFlood     [CatFlood,1]    = ID basins with floodplain                                                 [Ad]
%   .Sg             [Cat,1]         = Aquifer Storage                                                           [mm]
%   .Sw             [Cat,1]         = Soil Moinsture                                                            [mm]
%   .Vh             [Cat,1]         = Volume of the floodplain Initial                                          [mm]
%
% -------------------------------------------------------------------------
% OUTPUT DATA
% -------------------------------------------------------------------------
%   Nash            [1,1]           =   Function Object     [Ad]

if nargin>2
    Index = varargin{1};
end

global count

tic
%% Posición de unidades a calibrar
IDPoPo      = Basin.IDPoPo;

%% Asignación de parámetros de planicies inundables
if Basin.Status_ModelFlood        
    for i = 1:4
        IDPoPo_tmp  = IDPoPo;
        IDPoPo_tmp(~isnan(Basin.ParamsFlood(:,i))) = false;
        if sum(IDPoPo_tmp) > 0
            Basin.ParamsFlood(IDPoPo_tmp,i) = repmat(Param(i),sum(IDPoPo_tmp),1);
        end
    end
    Choco = length(Param(5:end));
else
    Choco = length(Param);
end

%% Asiganción de parámetros de unidad de modelación
for i = 1:Choco
    IDPoPo_tmp = IDPoPo;
    IDPoPo_tmp(~isnan(Basin.ParamsBasin(:,i))) = false;
    if Basin.Status_ModelFlood       
        Basin.ParamsBasin(IDPoPo_tmp,i) = repmat(Param(i + 4),sum(IDPoPo_tmp),1);    
    else
        Basin.ParamsBasin(IDPoPo_tmp,i) = repmat(Param(i),sum(IDPoPo_tmp),1);
    end
end

a = Basin.ParamsBasin(1,end-1);
b = Basin.ParamsBasin(1,end);

%% Ejecuación de modelo hidrológico - GR4J
if strcmp(Basin.NameModel,'GR4J')
    Basin.GR4J;
elseif strcmp(Basin.NameModel,'Thomas')
    Basin.Thomas;
end

%% Qobs
id          = Basin.Code == Basin.RiverMouth;
IDGaugesCal = Basin.GaugesCal(id);
id1         = Basin.GaugesID == IDGaugesCal;
Qobs        = Basin.Qobs(:,id1);

%% Qsim
Qsim        = sum(Basin.Qsim,2);

%% Balance de reservorio
VolSim      = Qsim*(3600*24);
VolR        = VolSim*0;
CotaMin     = 66.5;
Vol_i       = interp1(Basin.Reservoir_Level,...
                      Basin.Reservoir_Vol,....
                      CotaMin);

Vmin        = interp1(Basin.Reservoir_Level,...
                      Basin.Reservoir_Vol,....
                      CotaMin);
Cota = VolSim*0;
Descarga = VolSim*0;
for i = 1:length(Qsim)
    % Update volumen time i
    Vol_i   = Vol_i + VolSim(i);
    
    % Cota
    Cota_i      = interp1(Basin.Reservoir_Vol,Basin.Reservoir_Level,Vol_i);
    
    % Vertedero 1
    if (Cota_i > 65.5) && (Basin.Date(i) <= datetime(2010,12,31))
        % Output volumen
        % Vout        = interp1(Basin.Gasto_Level,Basin.Gasto_Q,Cota_i)*3600*24;
        % Vout        =  2*13*((Cota_i - CotaMin)^(2/3))*3600*24;
        % Vout        =  a*13*((Cota_i - CotaMin)^b)*3600*24;               
        Vout        =  a*13.65*((Cota_i - 65.5)^b)*3600*24;
        
        if (Vol_i - Vout) < Vmin
            Vout = Vol_i - Vmin;
        end

        Vol_i       = Vol_i - Vout;        
    end

    % Vertedero 1
    if (Cota_i > CotaMin) && (Basin.Date(i) > datetime(2010,12,31))
        % Output volumen
        % Vout        = interp1(Basin.Gasto_Level,Basin.Gasto_Q,Cota_i)*3600*24;
        % Vout        =  2*13*((Cota_i - CotaMin)^(2/3))*3600*24;
        % Vout        =  a*13*((Cota_i - CotaMin)^b)*3600*24;
        Vout        =  a*13.65*((Cota_i - CotaMin)^b)*3600*24;
        
        if (Vol_i - Vout) < Vmin
            Vout = Vol_i - Vmin;
        end

        Vol_i       = Vol_i - Vout;        
    end

    % % Vertedero 2
    % if Cota_i > 68.119
    %     % Output volumen
    %     % Vout        = interp1(Basin.Gasto_Level,Basin.Gasto_Q,Cota_i)*3600*24;
    %     % Vout        =  2*13*((Cota_i - CotaMin)^(2/3))*3600*24;
    %     % Vout        =  a*13*((Cota_i - CotaMin)^b)*3600*24;               
    %     Vout        =  a*7.46*((Cota_i - 68.119)^b)*3600*24;
    % 
    %     if (Vol_i - Vout) < Vmin
    %         Vout = Vol_i - Vmin;
    %     end
    % 
    %     Vol_i       = Vol_i - Vout;        
    % end


    VolR(i)     = Vol_i;   
    Cota(i)     = interp1(Basin.Reservoir_Vol,Basin.Reservoir_Level,Vol_i);
    Descarga(i)    = Vout;
end

Descarga    = Descarga/(3600*24);
Qsim        = VolR/(3600*24); 
Qobs        = interp1(Basin.Reservoir_Level,Basin.Reservoir_Vol,Qobs)/(3600*24);
% Qsim        = interp1(Basin.Reservoir_Vol,Basin.Reservoir_Level,VolR);
% figure, plot(Qsim)

%% Guardar
if nargin>2    
    ID_File = fopen(fullfile(Basin.PathProject, 'OUTPUTS','AllQsim',Basin.OptMethod,...
        num2str(Basin.CodeQobs),['Qsim_',num2str(Basin.CodeQobs),'_',num2str(Index),'.csv']),'w');
    fprintf(ID_File,'Year,Moth,Day,Qsim\n');
    fprintf(ID_File,'%f,%f,%f,%f\n',[year(Basin.Date) month(Basin.Date) day(Basin.Date) Qsim]');
    fclose(ID_File);
end

%% Date Cal
id1         = Basin.GaugesID == IDGaugesCal;
in          = find(Basin.Date == Basin.DateCal_Init(id1));
en          = find(Basin.Date == Basin.DateCal_End(id1));

%% Calculo de metrica
Metrics     = Basin.EstimationMetric(Qobs(in:en), Qsim(in:en));
Metric_Cal  = eval(['Metrics.',Basin.CalMetricSelect,';']);

if strcmp(Basin.CalMetricSelect, 'Nash')
    Metric_Cal = 1 - Metric_Cal;
elseif strcmp(Basin.CalMetricSelect,'AME')
elseif strcmp(Basin.CalMetricSelect,'PDIFF')
elseif strcmp(Basin.CalMetricSelect,'MAE')
elseif strcmp(Basin.CalMetricSelect,'MSE')
elseif strcmp(Basin.CalMetricSelect,'RMSE')
elseif strcmp(Basin.CalMetricSelect,'R4MS4E')
elseif strcmp(Basin.CalMetricSelect,'RAE')
elseif strcmp(Basin.CalMetricSelect,'PEP')
elseif strcmp(Basin.CalMetricSelect,'MARE')
elseif strcmp(Basin.CalMetricSelect,'MRE')
elseif strcmp(Basin.CalMetricSelect,'MSRE')
elseif strcmp(Basin.CalMetricSelect,'PBIAS')
    Metric_Cal = abs(Metric_Cal);
elseif strcmp(Basin.CalMetricSelect,'R')
elseif strcmp(Basin.CalMetricSelect,'CE')
elseif strcmp(Basin.CalMetricSelect,'PBE')
elseif strcmp(Basin.CalMetricSelect,'AARE')
elseif strcmp(Basin.CalMetricSelect,'TS1')
elseif strcmp(Basin.CalMetricSelect,'TS25')
elseif strcmp(Basin.CalMetricSelect,'TS50')
elseif strcmp(Basin.CalMetricSelect,'TS100')
end

%% Reiniciar set de parámetros
Basin.ParamsBasin = Basin.ParamsBasinCal;
Basin.ParamsFlood = Basin.ParamsFloodCal;

%% Imprimir tiempo de ejecución
if Basin.Status_ModelFlood  
    disp([num2str(count,'%0.5d'),' | ',num2str(IDGaugesCal,'%d'), ' | Time Execution -> ',num2str(toc,'%0.5f'),' seg | ',...
            'X1 = ', num2str(Param(1),'%04.0f'),...
            ' | X2 = ', num2str(Param(2),'%07.2f'),...
            ' | X3 = ', num2str(Param(3),'%04.0f'),...
            ' | X4 = ', num2str(Param(4),'%06.2f'),...
            ' | FunObj = ',num2str((1-Metric_Cal),'%.2f')])
else
      disp([num2str(count,'%0.5d'),' | ',num2str(IDGaugesCal,'%d'), ' | Time Execution -> ',num2str(toc,'%0.5f'),' seg | ',...
            'X1 = ', num2str(Param(1),'%04.0f'),...
            ' | X2 = ', num2str(Param(2),'%07.2f'),...
            ' | X3 = ', num2str(Param(3),'%04.0f'),...
            ' | X4 = ', num2str(Param(4),'%06.2f'),...
            ' | FunObj = ',num2str((1-Metric_Cal),'%.2f')])
end

count = count + 1;
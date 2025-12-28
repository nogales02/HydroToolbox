function Signature = HydroSig_All(Obj, varargin)
%calc_All calculates all signatures in the toolbox.
%   If a signature function can calculate multiple signatures
%   (e.g. sig_x_percentile) only one signature is calculated (e.g. Q95).
%   Note: This function is primarily intended to test all signatures and 
%   not all functionalities are used (e.g. plotting).
%
%   INPUT
%   Q_mat: streamflow [mm/timestep] matrix (cell array)
%   t_mat: time [Matlab Date_inum] matrix (cell array)
%   P_mat: precipitation [mm/timestep] matrix (cell array)
%   PET_mat: pot. evapotranspiration [mm/timestep] matrix (cell array)
%   T_mat: temperature [degC] matrix (cell array)
%   OPTIONAL
%   start_water_year: first month of water year, default = 10 (October)
%   plot_results: whether to plot results, default = false
%
%   OUTPUT
%   results: struc array with all results (each signature for each time
%       series and associated error strings)
%
%   EXAMPLE
%   % load example data
%   data = load('example/example_data/33029_daily.mat');
%   % create consistent cell arrays
%   Q_mat = {data.Q};
%   t_mat = {data.t};
%   P_mat = {data.P};
%   PET_mat = {data.PET};
%   T_mat = {data.T};
%   results = calc_All(Q_mat,t_mat,P_mat,PET_mat,T_mat);
%
%   Copyright (C) 2020
%   This software is distributed under the GNU Public License Version 3.
%   See <https://www.gnu.org/licenses/gpl-3.0.en.html> for details.

% check input parameters
% if nargin < 4
%     error('Not enough input arguments.')
% end

% -------------------------------------------------------------------------
% Check para datos de entrada
% -------------------------------------------------------------------------
ip = inputParser;
% addRequired(ip, 'Q', @(Q) ismatrix(Q))
% addRequired(ip, 'P', @(P_mat) ismatrix(P))
% addRequired(ip, 'Date', @(Date) isdatetime(Date))
addParameter(ip, 'Codes',[],@ismatrix)
addParameter(ip,'start_water_year', 10, @isnumeric)
addParameter(ip,'plot_results', false, @islogical) 
% Check de datos de entrada
% parse(ip, Q, P, Date, varargin{:})
parse(ip,varargin{:})
% Check para graficas
plot_results        = ip.Results.plot_results;
% Check para inicio de año hidrológico
start_water_year    = ip.Results.start_water_year;
% Códigos específicos
Code_PoPo           = ip.Results.Codes;

% Otros Check
if ~isempty(Code_PoPo)
    [~, PoPo] = ismember(Code_PoPo, Obj.Code);
else
    PoPo = 1:length(Obj.Code);
end
PoPo(PoPo == 0) = [];

% -------------------------------------------------------------------------
% Almacenar firmas
% -------------------------------------------------------------------------
Signature = NaN(length(PoPo),67);

for ii = 1:length(PoPo)
    tic
    id          = find(~isnan(Obj.Q(:,PoPo(ii))));
    Qi          = Obj.Q(id(1):id(end),PoPo(ii));
    Pi          = Obj.P(id(1):id(end),PoPo(ii));
    Date_i      = Obj.Date(id(1):id(end));

       
    % ---------------------------------------------------------------------
    % Hydrological Siganture - Autocorrelación
    % ---------------------------------------------------------------------
    [AC1,~,AC1_error_str] = sig_Autocorrelation(Qi,Date_i);
    Signature(ii,1) = AC1;

    % ---------------------------------------------------------------------
    % Coeficiente de recesión
    % ---------------------------------------------------------------------
    [BaseflowRecessionK, error_flag, error_str, Fig] = ...
        sig_BaseflowRecessionK(Qi,Date_i,'eps',0.001*median(Qi,'omitnan'),'plot_results',plot_results);
    Signature(ii,2) = BaseflowRecessionK;

    if plot_results
        mkdir(fullfile(Obj.PathProject,'FIGURES','BaseFlow'))
        saveas(Fig,fullfile(Obj.PathProject,'FIGURES','BaseFlow',['BaseFlow_Recession_',num2str(Obj.Code(PoPo(ii))),'.jpg']));
    end

    % ---------------------------------------------------------------------
    % Magnitud del flujo base
    % ---------------------------------------------------------------------
    [BaseflowMagnitude,~,BaseflowMagnitude_error_str] = sig_BaseflowMagnitude(Qi,Date_i);
    Signature(ii,3) = BaseflowMagnitude;

    % ---------------------------------------------------------------------
    % Índice de flujo base
    % ---------------------------------------------------------------------
    [BFI,~,BFI_error_str,Fig] = sig_BFI(Qi,Date_i,'plot_results',plot_results);
    Signature(ii,4) = BFI;

    if plot_results
        mkdir(fullfile(Obj.PathProject,'FIGURES','BaseFlow'))
        saveas(Fig,fullfile(Obj.PathProject,'FIGURES','BaseFlow',['BaseFlow_BFI_',num2str(Obj.Code(PoPo(ii))),'.jpg']));
    end

    % ---------------------------------------------------------------------
    % Pendiente de la curva de duración
    % ---------------------------------------------------------------------
    [FDC_slope,~,FDC_slope_error_str,Fig] = sig_FDC_slope(Qi,Date_i,'plot_results',plot_results);
    Signature(ii,5) = FDC_slope;

    if plot_results
        mkdir(fullfile(Obj.PathProject,'FIGURES','CDC'))
        saveas(Fig,fullfile(Obj.PathProject,'FIGURES','CDC',['Slope_CDC_',num2str(Obj.Code(PoPo(ii))),'.jpg']));
    end

    % ---------------------------------------------------------------------
    % Índice Flashiness
    % ---------------------------------------------------------------------
    [FlashinessIndex,~,FlashinessIndex_error_str] = sig_FlashinessIndex(Qi,Date_i);
    Signature(ii,6) = FlashinessIndex;

    % ---------------------------------------------------------------------
    % Fecha del flujo medio
    % ---------------------------------------------------------------------
    [HFD_mean,~,HFD_mean_error_str] = sig_HFD_mean(Qi,Date_i);
    Signature(ii,7) = HFD_mean;

    % ---------------------------------------------------------------------
    % Lapso de tiempo entre descaga promedio 
    % ---------------------------------------------------------------------
    [HFI_mean,~,HFI_mean_error_str] = sig_HFI_mean(Qi,Date_i);   
    Signature(ii,8) = HFI_mean;

    % ---------------------------------------------------------------------
    % Pendiente entre el 10 y 50 de la curva de duración de los picos
    % ---------------------------------------------------------------------
    [PeakDistribution,~,PeakDistribution_error_str] = sig_PeakDistribution(Qi,Date_i);
    Signature(ii,9) = PeakDistribution;

    % ---------------------------------------------------------------------
    % Pendiente de la curva acumulada de preciptiación y caudal 
    % ---------------------------------------------------------------------
    PQ_Curve = NaN(1,4);
    [PQ_Curve(1),PQ_Curve(2),PQ_Curve(3),PQ_Curve(4),~,PQ_Curve_error_str] = ...
        sig_PQ_Curve(Qi,Date_i,Pi);
    Signature(ii,10:13) = PQ_Curve;

    % ---------------------------------------------------------------------
    % Desviación estandar normalizada por los promedios
    % ---------------------------------------------------------------------
    [Q_CoV,~,Q_CoV_error_str] = sig_Q_CoV(Qi,Date_i);
    Signature(ii,14) = Q_CoV;

    % ---------------------------------------------------------------------
    % Caudal promedio
    % ---------------------------------------------------------------------
    [Q_mean,~,Q_mean_error_str] = sig_Q_mean(Qi,Date_i);
    Signature(ii,15) = Q_mean;

    % ---------------------------------------------------------------------
    % Caudal promedio mensual
    % ---------------------------------------------------------------------
    [Q_mean_monthly,~,Q_mean_monthly_error_str] = sig_Q_mean_monthly(Qi,Date_i,1:12);
    Signature(ii,16:27) = Q_mean_monthly;

    % ---------------------------------------------------------------------
    % Caudal máximo en un ventana de 7 días
    % ---------------------------------------------------------------------
    [Q_7_day_max,~,Q_7_day_max_error_str] = sig_Q_n_day_max(Qi,Date_i,7);
    Signature(ii,28) = Q_7_day_max;

    % ---------------------------------------------------------------------
    % Caudal mínimo en una ventana de 7 días
    % ---------------------------------------------------------------------
    [Q_7_day_min,~,Q_7_day_min_error_str] = sig_Q_n_day_min(Qi,Date_i,7);
    Signature(ii,29) = Q_7_day_min;

    % ---------------------------------------------------------------------
    % Cálcula la oblicuidad de caudales
    % ---------------------------------------------------------------------
    [Q_skew,~,Q_skew_error_str] = sig_Q_skew(Qi,Date_i);
    Signature(ii,30) = Q_skew;

    % ---------------------------------------------------------------------
    % Varianza de caudales
    % ---------------------------------------------------------------------
    [Q_var,~,Q_var_error_str] = sig_Q_var(Qi,Date_i);
    Signature(ii,31) = Q_var;

    % ---------------------------------------------------------------------
    % Elasticidad de caudale vs precipitación
    % ---------------------------------------------------------------------
    [QP_elasticity,~,QP_elasticity_error_str] = sig_QP_elasticity(Qi,Date_i,Pi);
    Signature(ii,32) = QP_elasticity;

    % ---------------------------------------------------------------------
    % Curva de recesión de caudales
    % ---------------------------------------------------------------------
    [RecessionParameters,~,~,RecessionParameters_error_str] = ...
        sig_RecessionAnalysis(Qi,Date_i,'fit_individual',false);
    Signature(ii,33:34) = RecessionParameters;

    % ---------------------------------------------------------------------
    % Ajuste exponencial de la curva de recesión
    % ---------------------------------------------------------------------
    [RecessionK_early,~,RecessionK_early_error_str] = sig_RecessionParts(Qi,Date_i,'early');
    Signature(ii,35) = RecessionK_early;

    % ---------------------------------------------------------------------
    % Correlación
    % ---------------------------------------------------------------------
    [Spearmans_rho,~,Spearmans_rho_error_str] = sig_RecessionUniqueness(Qi,Date_i);
    Signature(ii,36) = Spearmans_rho;

    % ---------------------------------------------------------------------
    % Timepo de respuesta
    % ---------------------------------------------------------------------
    [ResponseTime,~,ResponseTime_error_str] = sig_ResponseTime(Qi,Date_i,Pi);
    Signature(ii,37) = ResponseTime;

    % ---------------------------------------------------------------------
    % Rising limb density
    % ---------------------------------------------------------------------
    [RLD,~,RLD_error_str] = sig_RisingLimbDensity(Qi,Date_i);
    Signature(ii,38) = RLD;

    % ---------------------------------------------------------------------
    % Ratio between summer and winter runoff ratio 
    % ---------------------------------------------------------------------
    [RR_Seasonality,~,RR_Seasonality_error_str] = sig_RR_Seasonality(Qi,Date_i,Pi);   
    Signature(ii,39) = RR_Seasonality;

    % ---------------------------------------------------------------------
    % Variación estacional de la curva de duración 
    % ---------------------------------------------------------------------
    [Recession_a_Seasonality,~,Recession_a_Seasonality_error_str] = sig_SeasonalVarRecessions(Qi,Date_i);              
    Signature(ii,40) = Recession_a_Seasonality;

    % ---------------------------------------------------------------------
    % Fracción de precipitación que deja la cuenca como caudal
    % ---------------------------------------------------------------------
    [TotalRR,~,TotalRR_error_str] = sig_TotalRR(Qi,Date_i,Pi);
    Signature(ii,41) = TotalRR;

    % ---------------------------------------------------------------------
    % Indice de variabilidad
    % ---------------------------------------------------------------------
    [VariabilityIndex,~,VariabilityIndex_error_str] = sig_VariabilityIndex(Qi,Date_i);
    Signature(ii,42) = VariabilityIndex;
    
    % ---------------------------------------------------------------------
    % Caudal del Q95
    % ---------------------------------------------------------------------
    [Q95,~,Q95_error_str] = sig_x_percentile(Qi,Date_i,95:-5:5);
    Signature(ii,43:61) = Q95;

    % ---------------------------------------------------------------------
    % Duración de flujo alto
    % ---------------------------------------------------------------------    
    [high_Q_duration,~,high_Q_duration_error_str] = sig_x_Q_duration(Qi,Date_i,'custom_high','threshold',Signature(ii,43));
    Signature(ii,62) = high_Q_duration;

    % ---------------------------------------------------------------------
    % Frecuencias
    % ---------------------------------------------------------------------
    [high_Q_frequency,~,high_Q_frequency_error_str] = sig_x_Q_frequency(Qi,Date_i,'custom_high','threshold',Signature(ii,43));  
    Signature(ii,63) = high_Q_frequency;
    
    % ---------------------------------------------------------------------
    % Duración de flujo bajos
    % ---------------------------------------------------------------------
    [Low_Q_duration,~,high_Q_duration_error_str] = sig_x_Q_duration(Qi,Date_i,'low');
    Signature(ii,64) = Low_Q_duration;

    % ---------------------------------------------------------------------
    % Frecuencias de flujos bajos
    % ---------------------------------------------------------------------
    [Low_Q_frequency,~,high_Q_frequency_error_str] = sig_x_Q_frequency(Qi,Date_i,'low');  
    Signature(ii,65) = Low_Q_frequency;
    
    % ---------------------------------------------------------------------
    % Duración de flujo bajos
    % ---------------------------------------------------------------------
    [Low_Q_duration,~,high_Q_duration_error_str] = sig_x_Q_duration(Qi,Date_i,'no');
    Signature(ii,66) = Low_Q_duration;

    % ---------------------------------------------------------------------
    % Frecuencias de flujos bajos
    % ---------------------------------------------------------------------
    [Low_Q_frequency,~,high_Q_frequency_error_str] = sig_x_Q_frequency(Qi,Date_i,'no');  
    Signature(ii,67) = Low_Q_frequency;
    
    Progress = round((ii/length(PoPo))*100,2);
    disp(['Hydrological Signature - Basin ',num2str(Obj.Code(PoPo(ii))),' - Progress: ',num2str(Progress,'%.2f'),'% -> Sec ',num2str(toc,'%.4f')])
end

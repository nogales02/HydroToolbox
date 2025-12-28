function Signature = HydroSig_Representativeness(Obj, varargin)
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
Signature = NaN(length(PoPo),5);

for ii = 1:length(PoPo)
    tic
    id          = find(~isnan(Obj.Q(:,PoPo(ii))));
    Qi          = Obj.Q(id(1):id(end),PoPo(ii));
    Date_i      = Obj.Date(id(1):id(end));
       
    % ---------------------------------------------------------------------
    % Caudal promedio anual (Magnitud)
    % ---------------------------------------------------------------------
    [Q_mean,~,~]    = sig_Q_mean(Qi,Date_i);
    Signature(ii,1) = Q_mean;   
    
    % ---------------------------------------------------------------------
    % Duración en meses de los periodos húmedos (Duracción)
    % ---------------------------------------------------------------------
    dt  = 30;
    cf  = ones(1, dt)/dt;
    Q7  = filter(cf, 1, Qi);
    Qm  = mean(Qi);
    Signature(ii,2) = (sum(Q7 > Qm)/length(Q7))*12;
    
    % ---------------------------------------------------------------------
    % Fecha del flujo medio (Frecuencia) - monomodal o unimodal
    % ---------------------------------------------------------------------
    Q7      = abs(fft(Qi));
    Star    = 20;
    Q7      = Q7(Star:ceil(length(Q7)/2));
    F       = Star - 1 + find(Q7 == max(Q7));
    Signature(ii,3) = (F/36);
    
    % ---------------------------------------------------------------------
    % Pendiente de la curva de duración (Tasa de Cambio)
    % ---------------------------------------------------------------------
    [FDC_slope,~,~,~]   = sig_FDC_slope(Qi,Date_i,'plot_results',false);
    Signature(ii,4)     = FDC_slope;
    
    % ---------------------------------------------------------------------
    % Meses en el cual se alcanza el caudal medio (Tiempo)
    % ---------------------------------------------------------------------
    [HFD_mean,~,~]  = sig_HFD_mean(Qi,Date_i);
    Signature(ii,5) = HFD_mean.*(12/365);
    
    % ---------------------------------------------------------------------
    % Progreso
    % ---------------------------------------------------------------------
    Progress = round((ii/length(PoPo))*100,2);
    disp(['Hydrological Signature - Basin ',num2str(Obj.Code(PoPo(ii))),' - Progress: ',num2str(Progress,'%.2f'),'% -> Sec ',num2str(toc,'%.4f')])
end

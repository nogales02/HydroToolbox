function [Alfa, F_Alfa, Delta, H, Tau, q, Miu, Dq, Fig] = MassExponent(obj, Data)
% -------------------------------------------------------------------------
% Programado en Matlab - R2019b 
% -------------------------------------------------------------------------
%                           Informaci�n Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Fecha         : 01-Enero-2019
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los t�rminos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener. Para mayor informaci�n revisar 
% http://www.gnu.org/licenses/
%
% -------------------------------------------------------------------------
% Descripci�n del Codigo
% -------------------------------------------------------------------------
%
% -------------------------------------------------------------------------
% Input Data
% -------------------------------------------------------------------------
% 
% -------------------------------------------------------------------------
% Output Data
% -------------------------------------------------------------------------        

id          = find(~isnan(Data));
Data        = Data(id(1):id(end));

%% Paramters
qmin    = -4.1;
qmax    = 4.1;
qnum    = 100;

%% Parameters
% Data Number
N       = length(Data);
% Moments
q       = round(sort(unique(linspace(qmin,qmax,qnum)')),2);
q       = q(q ~= 0);
% 
ni      = floor( log(N/2) / log(2) );
% Number of Segments
Delta   = floor(N ./ (2.^((1:ni)')));
% Miu
Miu     = NaN(ni,length(q));

R2      = NaN(ni - 1,1);
for n = 1:ni
    Ns  = (2^n);
    s   = floor(N ./ (2.^n));    

    % Meassured
    Miu_Tmp = sum(reshape(Data(1:Ns*s),s,Ns), 'omitnan')' / sum(Data(1:Ns*s), 'omitnan');

    if sum(Miu_Tmp <= 0) > 0
        break
    else
        %% Original 
        Miu(n,:) = sum(bsxfun(@power, Miu_Tmp, q'), 'omitnan');
    end

    if n >= 2
        %% Check Fitting
        Params  = polyfit(log(Delta(1:n)), log(Miu(1:n,end)),1);    
        sim     = polyval(Params, log(Delta(1:n)));

        R2(n - 1) = rsquare( log(Miu(1:n,end)), sim);
    end    
end
id = isnan(Miu(:,1)) == 0;
Miu = Miu(id,:);
Delta = Delta(id);
Delta = Delta./N;

%% Mass Exponents [Tau]
ji = sum(R2 > 0.998) + 1;
Tau = NaN(length(q),1);
for i = 1:length(q)
    Tmp     = polyfit(log(Delta(1:ji)), log(Miu(1:ji,i)),1);    
    Tau(i)  = -Tmp(1);
end

%% Horton Exponents [H]
H = -((Tau - 1)./q);

%% Lipschitz-Holder Exponents [Alfa]
Alfa = (Tau(1:end - 1) - Tau(2:end))/(abs(q(2) - q(1)));

%% Correction Alfa
Jo      = (Alfa (1:end - 1) - Alfa (2:end));
Alfa(find(Jo < 0) + 1  ) = NaN;
q1      = q(1:end-1);
q1      = q1( ~isnan(Alfa));
Alfa    = Alfa( ~isnan(Alfa));
Alfa    = interp1(q1, Alfa, q(1:end-1));

%% Fractal Dimension
F_Alfa = (Alfa.*q(1:end-1)) + Tau(1:end-1);

%% Generalised Fractal dimension
Dq = (Tau./(1 - q));

%% Interpolation
qmin    = -4;
qmax    = 4;
Tau     = interp1(q, Tau,               (qmin:0.01:qmax)');
H       = interp1(q, H,                 (qmin:0.01:qmax)');
Alfa    = interp1(q(1:end-1), Alfa,     (qmin:0.01:qmax)');
F_Alfa  = interp1(q(1:end-1), F_Alfa,   (qmin:0.01:qmax)');
Dq      = interp1(q, Dq,                (qmin:0.01:qmax)');
q       = (qmin:0.01:qmax)';   

%% Plot
if obj.StatusPlot
    Fig = obj.Plot_MultifractalSpectrum(Alfa, F_Alfa, q);
else
    Fig = [];
end


end 

function R2 = rsquare(X,Y)
% Filname: 'rsquare.m'. This file can be used for directly calculating
% the coefficient of determination (R2) of a dataset.
%
% Two input arguments: 'X' and 'Y'
% One output argument: 'R2'
%
% X:    Vector of x-parameter
% Y:    Vector of y-paramter
% R2:   Coefficient of determination
%
% Input syntax: rsquare(X,Y)
%
% Developed by Joris Meurs BASc (2016)
% Limitations
if length(X) ~= length(Y), error('Vector should be of same length');end
if nargin < 2, error('Not enough input parameters');end
if nargin > 2, error('Too many input parameters');end
% Linear regression according to the model: a + bx
A = [ones(length(X),1) X];
b = pinv(A'*A)*A'*Y;
Y_hat = A*b;
% Calculation of R2 according to the formula: SSreg/SStot
SSreg = sum((Y_hat - mean(Y)).^2);
SStot = sum((Y - mean(Y)).^2);
R2 = SSreg/SStot;
% Output limitations
% if R2 > 1, error('Irregular value, check your data');end
if R2 < 0, error('Irregular value, check your data');end

end
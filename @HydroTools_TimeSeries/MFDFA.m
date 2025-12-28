function [Alfa, F_Alfa, Delta, H, Tau, q, Fq, Dq] = MFDFA(obj,varargin)
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
%

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

%% Create Folder
mkdir(fullfile(obj.PathProject,'FIGURES','Multifractal_MFDFA'))
mkdir(fullfile(obj.PathProject,'RESULTS','Multifractal_MFDFA'))

for ii = 1:length(PoPo)
    %% Data
    id          = find(~isnan(obj.Data(:,PoPo(ii))));
    Data        = obj.Data(id(1):id(end),PoPo(ii));
    
    %% Cumulated [Y]
    Data = cumsum(Data - mean(Data, 'omitnan'), 'omitnan');
%     Data = cumsum(Data, 'omitnan');
    
    %% Paramters
    qmin = -2.1;
    qmax = 2.1;
    qnum = 100;

    %% Parameters
    % Data Number
    N       = length(Data);
    % Moments
    q       = round(sort(unique(linspace(qmin,qmax,qnum)')),2);
%     q       = q(q ~= 0);

    ni  = floor( log(N/10) / log(2) );
    % Fq
    Fq  = NaN(length(q),ni);
    % Number of Segments
    Delta = floor(N ./ (2.^((1:ni)')));
    
    R2      = NaN(ni - 1,1);
    for n = 1:ni
        Ns  = (2^n);
        s   = floor(N ./ (2.^n));
        F   = NaN(Ns, 1);
        
%         plot(Data)
%         hold on 
        for i = 1:Ns
            Pv      = Data(1 + (s*(i - 1)):s + (s*(i - 1)));
            Params  = polyfit((1 + (s*(i - 1)):s + (s*(i - 1)))',Pv,1); 
            yo      = polyval(Params, (1 + (s*(i - 1)):s + (s*(i - 1)))');
            F(i)    = (1/s)*sum((Pv - yo).^2, 'omitnan');    
            
%             plot((1 + (s*(i - 1)):s + (s*(i - 1)))', yo)
        end
%         close(gcf)
        
        for i = 1:length(q)
            if q(i) ~= 0
                Fq(i,n) = ((1/Ns)*sum(F.^(q(i)/2), 'omitnan'))^(1/q(i));
            else
                Fq(i,n) = exp((1/(2*Ns))*sum(log(F), 'omitnan'));
            end
        end
        
        %% Check Lineal Regression R2
        if n >= 2
            %% Check Fitting
            Params  = polyfit(Delta(1:n), Fq(end, 1:n)',1);    
            sim     = polyval(Params, log(Delta(1:n)));

            R2(n - 1) = rsquare( log(Fq(end,1:n)'), sim);
        end 
    end

    %% Horton Exponents
    ji = sum(R2 > 0.99) + 1;
%     ji = sum(R2 > 0.998) + 1;
    H = NaN(length(q),1);
    for i = 1:length(q)
        Tmp     = polyfit(log(Delta(1:ji)), log(Fq(i,1:ji)'),1);    
        H(i)    = Tmp(1);
    end

    %% Mass Exponents [Tau]
    Tau = -((q.*H) -  1);
        
    %% Lipschitz-Holder Exponents [Alfa]
    Alfa = (Tau(1:end - 1) - Tau(2:end))/(abs(q(2) - q(1)));
%     dh_dq = ((H(1:end-1) - H(2:end))/(abs(q(2) - q(1))));
%     Alfa = H(1:end-1) + (q(1:end-1).*dh_dq);    
    
    %% Correction Alfa
    Jo  = (Alfa (1:end - 1) - Alfa (2:end));
    Alfa(find(Jo < 0) + 1  ) = NaN;
    q1 = q(1:end-1);
    q1 = q1( ~isnan(Alfa));
    Alfa = Alfa( ~isnan(Alfa));
    Alfa    = interp1(q1, Alfa, q(1:end-1));
    
    %% Fractal Dimension
%     F_Alfa = ((Alfa - H(1:end-1)).*q(1:end-1)) + 1;
    F_Alfa = (Alfa.*q(1:end-1)) + Tau(1:end-1);
    
    %% Generalised Fractal dimension
    Dq = (Tau./(1 - q));

    %% Interpolation
    qmin    = -2;
    qmax    = 2;
    Tau     = interp1(q, Tau,               (qmin:0.01:qmax)');
    H       = interp1(q, H,                 (qmin:0.01:qmax)');
    Alfa    = interp1(q(1:end-1), Alfa,     (qmin:0.01:qmax)');
    F_Alfa  = interp1(q(1:end-1), F_Alfa,   (qmin:0.01:qmax)');
    Dq      = interp1(q, Dq,                (qmin:0.01:qmax)');
    q       = (qmin:0.01:qmax)';       
    
    %% Save Data
    NameFolfer  = fullfile(obj.PathProject,'RESULTS','Multifractal_MFDFA');    
    NameFile    = fullfile(NameFolfer,[num2str(obj.Code(PoPo(ii))),'.csv']);
    ID_File     = fopen(NameFile,'w');
    fprintf(ID_File,'%s\n','Moments,Tau,H,Alfa,F_Alfa,Dq');
    
    fprintf(ID_File, ['%f',repmat(',%f',1,5),'\n'],[q, Tau,H,Alfa,F_Alfa,Dq]');
    fclose(ID_File);
    
    if obj.StatusPlot
        %% Plot Data
        Fig = obj.Plot_MultifractalSpectrum(Alfa, F_Alfa, q);
        saveas(Fig, fullfile(obj.PathProject,'FIGURES','Multifractal_MFDFA',[num2str(obj.Code(PoPo(ii))),'.jpg']))
        close(Fig)
    end
    
    disp(['Multifractal Spectrum Ok Gauges ->',num2str(obj.Code(PoPo(ii)))])
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
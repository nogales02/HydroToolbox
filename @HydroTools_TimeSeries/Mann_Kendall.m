function [H,p_value] = Mann_Kendall(obj, varargin)
% -------------------------------------------------------------------------
% Programado en Matlab - R2019b 
% -------------------------------------------------------------------------
%                           Informaci�n Basica
%--------------------------------------------------------------------------
%   Simone Fatichi -- simonef@dicea.unifi.it
%   Copyright 2009
%   $Date: 2009/10/03 $
%
% -------------------------------------------------------------------------
% Input Data
% -------------------------------------------------------------------------
% V = time series [vector]
% alpha =  significance level of the test [scalar]
%
% -------------------------------------------------------------------------
% Output Data
% -------------------------------------------------------------------------
% H = test result [1] Reject of Null Hypthesis [0] Insufficient evidence 
 %      to reject the null hypothesis
% p_value = p-value of the test
%
% -------------------------------------------------------------------------
% Descripci�n del Codigo
% -------------------------------------------------------------------------
% Performs original Mann-Kendall test of the null hypothesis of trend
% absence in the vector V,  against the alternative of trend. 
% The result of the test is returned in H = 1 indicates
% a rejection of the null hypothesis at the alpha significance level. 
% H = 0 indicates
% a failure to reject the null hypothesis at the alpha significance level.
%
% The p-value of a test is the probability, under the null hypothesis, 
% of obtaining a value of the test statistic as extreme or more extreme 
% than the value computed from the sample.
%
% The significance level of a test is a threshold of probability a agreed
% to before the test is conducted. A typical value of alpha is 0.05. 
% If the p-value of a test is less than alpha, the test rejects the null 
% hypothesis. If the p-value is greater than alpha, there is insufficient 
% evidence to reject the null hypothesis. 
% -------------------------------------------------------------------------
% References
% ------------------------------------------------------------------------- 
% Mann, H. B. (1945), Nonparametric tests against trend, Econometrica, 13, 
% 245? 259.
% Kendall, M. G. (1975), Rank Correlation Methods, Griffin, London.

warning off

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
    NameLabel = varargin{2};
else
    NameLabel = [];
end

if isempty(NameLabel)
    NameLabel = '\bf Precipitation(mm)';
end

%% Create folders
mkdir(fullfile(obj.PathProject,'FIGURES','Mann_Kendall'))

%% Alpha
alpha = 0.05;

m = 90;

%% Storage
p_value = zeros(length(PoPo), 1);
H       = zeros(length(PoPo), 1);

for ii = 1:length(PoPo)
    try
        id      = find(~isnan(obj.Data(:,PoPo(ii))));
        Data    = obj.Data(id(1):id(end),PoPo(ii));
        Date    = obj.Date(id(1):id(end));

        %% Fitting NAN Value
        Data(isnan(Data)) = mean(Data(~isnan(Data)));

        %% Clear NaN
        id      = ~isnan(Data);
        Data    = Data(id);
        Data(Data == 0) = 0.1;

        %% Log
        Data = log(Data);

        %% Average Moving
        w = ((2*m) + 1);
        n = length(Data);

    %         Results = zeros(n-w+1,1);
        Results = zeros(n-m-w+1,1);
        for i = m+1:n-w+1
            Results(i-m) = mean(Data(i-m:i+m),'omitnan');
        end
    %     Data = Data(m+1:n-m) - Results;
        Data = Results;

        %% Tranformation Series
        % Centralizamos
        Data = Data - mean(Data, 'omitnan');
        % Estandarizamos
        Data = Data./std(Data, 'omitnan');

        V       = reshape(Data,length(Data),1); 
        alpha   = alpha/2; %
        n       = length(V); 
        S = 0; 
        for i = 1:n-1
           for j = i+1:n 
              S = S + sign(V(j)-V(i)); 
           end
        end

        VarS = (n*(n-1)*(2*n+5))/18;
        StdS = sqrt(VarS); 
        %%%% Note: ties are not considered 
        if S >= 0
           Z = ((S-1)/StdS)*(S~=0);
        else
           Z = (S+1)/StdS;
        end
        p_value(ii) = 2*(1-normcdf(abs(Z),0,1)); %% Two-tailed test 
        pz          = norminv(1-alpha,0,1); 
        H(ii)       = abs(Z)>pz;        

        %% Plot
        if obj.StatusPlot
            %% Lineal Regression
            Params  = polyfit(datenum(Date),Data,1);
            Psim    = polyval(Params,datenum(Date));
            
            %% Plot
            Fig     = figure('color',[1 1 1]);
            T       = [16, 8];
            set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
            [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off') 

            plot(Date, Data,'Linewidth',1.2, 'color',obj.ColorsF('light sea green'))
            hold on 
            plot(Date, Psim,'Linewidth',2, 'color',obj.ColorsF('carmine'))

            xlabel('\bf Time','interpreter','latex', 'Fontsize',20)
            ylabel(NameLabel, 'interpreter','latex', 'Fontsize',20)
            title(['\bf Equation [ Y = X', num2str(Params(1),'%0.4f'),' + (' num2str(Params(2),'%0.4f'),') ]'],'interpreter','latex', 'Fontsize',20)
            le = legend('\bf Time Series', '\bf Lineal Regression ');
            set(le,'interpreter','latex','FontSize',15, 'FontWeight','bold','box','off','color','none', 'Location','northwest')
            set(gca, 'TickLabelInterpreter','latex', 'FontWeight','bold','Color','none', 'box','on','FontSize',18)

            %% Save
            saveas(Fig, fullfile(obj.PathProject,'FIGURES','Mann_Kendall',[num2str(obj.Code(PoPo(ii))),'.jpg']))
            close(Fig)
        end
        
        disp(['Mann-Kendall ok for Gauges ->',num2str(obj.Code(PoPo(ii)))])
    catch
        disp(['Mann-Kendall Error for Gauges ->',num2str(obj.Code(PoPo(ii)))])
    end
end

Code = obj.Code(PoPo);
Code = reshape(Code,length(Code),1);

%% Save Data
NameFile    = fullfile(obj.PathProject,'RESULTS','Teste_Train_Mann-Kendall.csv');
ID_File     = fopen(NameFile,'w');

fprintf(ID_File,'%s\n','Code, Test Result - Null Hypthesis, P-Value');
fprintf(ID_File, '%f,%d,%f\n',[Code, H, p_value]');
fclose(ID_File);

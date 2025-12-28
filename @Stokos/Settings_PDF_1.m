function [Mejorpdf, Error, NamePDF, Fig] = Settings_PDF_1(obj,Data,varargin)

if nargin == 3
    StatusPlot = varargin{1};
else
    StatusPlot = false;
end

%% AJUSTE FDP
% Error
Error = 1E12;

% Pdf a evaluar
CDF = { 'Nakagami','GeneralizedExtremeValue',...
        'Normal','Lognormal','Gamma', 'ExtremeValue', 'Weibull',...
        'Exponential', 'tLocationScale','GeneralizedPareto',...
        'Logistic','LogLogistic'};

NameP = {   'Nakagami','G-ExtremeValue',...
            'Normal','Lognormal','Gamma', 'Gumbel', 'Weibull',...
            'Exponential', 'tLocationScale','GeneralizedPareto',...
            'Logistic','LogLogistic'};


%% Fitting NAN Value
Data(isnan(Data)) = mean(Data(~isnan(Data)));

% Distribucion empirica 
[Fe,x_values] = ecdf(Data);

if StatusPlot
    T   = [60 30];
    Fig = figure('color',[1 1 1], 'Units', 'centimeters',...
        'Position',[0, 0, T], 'visible','off');
end

POO = [1:3:11 12:3:22 23:3:33 ];
PO  = [2:3:11 13:3:22 24:3:33 ];
for i = 1:length(CDF)
    % Parametros de la pdf evaluada
    test_cdf    = fitdist(Data,CDF{i});
    % Prueba de Kolmog�rov-Smirnov
    [h, p]      = kstest(Data,'CDF',test_cdf,'Alpha',0.05);
    % Distribucion teorica con la pdf evaluada
    Ft          = cdf(test_cdf, x_values);
    % Error Cuadratico Medio del ajuste 
    RMSE        = sqrt(sum((Fe - Ft).^2));

    % Mejor ajuste 
    if RMSE < Error 
        Mejorpdf    = test_cdf; 
        Error       = RMSE;
        NamePDF     = CDF{i};
        idNamePDF   = i;
    end

    %% Plotting
    if StatusPlot
        subplot(3,4,i)
        plot(x_values,Fe,'-','Color',[0.5 0.5 0.5],'linewidth',1.5); 
        hold on 
        plot(x_values,Ft,':','Color',[1 0.5 0],'linewidth',1.5);
        axis([min(x_values) max(x_values) 0 1])

        title(['\bf ',NameP{i},' - RMSE = ',num2str(RMSE,'%0.2f')], 'interpreter','latex', 'Fontsize',18)
        Leg = legend('Fe','Ft');
        set(Leg,  'location','southeast','Fontsize',10);

        if (i == 1) || (i == 5) || (i == 9)
            ylabel(sprintf('Frecuencia\nAcumulada'),'interpreter','latex', 'Fontsize',18)
        end

        if (i >= 9)
            xlabel('Value','interpreter','latex', 'Fontsize',18)
        end

        if (i == 9)
            xlabel('Value','interpreter','latex', 'Fontsize',18)
            ylabel(sprintf('Frecuencia\nAcumulada'),'interpreter','latex', 'Fontsize',18)
        end

        if i < 9
            set(gca,'xticklabel','')
        end

        if ((2<=i)&&(i<=4))||((6<=i)&&(i<=8))||((10<=i)&&(i<=12))
            set(gca,'yticklabel','')
        end
%         grid on, grid minor
        box on 
        set(gca,'TickLabelInterpreter','latex', 'Fontsize',16)                                
    end

end

if ~StatusPlot
    Fig = [];
end
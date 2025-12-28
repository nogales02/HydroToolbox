function [NamePDF,Error,ParamBestPDF,Fig] = Fit_PDF(obj,Data,StatusPlot)
% -------------------------------------------------------------------------
% Matlab - R2023b 
% -------------------------------------------------------------------------
%                           Información Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Fecha         : abril-2024
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los términos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener. Para mayor información revisar 
% http://www.gnu.org/licenses/
%
% -------------------------------------------------------------------------
% Descripción del Código
% -------------------------------------------------------------------------
% Este código ajusta un conjunto de datos a la mejor distribución de
% probabilidad de un conjunto de 12 funciones, a saber:
%   -> Nakagami
%   -> G-ExtremeValue
%   -> Normal
%   -> Lognormal
%   -> Gamma
%   -> Gumbel
%   -> Weibull
%   -> Exponential
%   -> tLocationScale
%   -> GeneralizedPareto
%   -> Logistic
%   -> LogLogistic
% 
% -------------------------------------------------------------------------
% Input Data
% -------------------------------------------------------------------------
% Data : Vector de datos 
%
% -------------------------------------------------------------------------
% Output Data
% -------------------------------------------------------------------------
% NamePDF       : Nombre de Matlab de la pdf que mejor se ajusto a los datos
% Error         : Error de ajuste de la mejor pdf
% ParamBestPDF  : Parámetros de la pdf que mejor se ajusto a los datos
% Fig           : Figura con los ajustes de todas las pdf evaluadas

% -------------------------------------------------------------------------
% Pdf a evaluar
% -------------------------------------------------------------------------
CDF = { 'Nakagami','GeneralizedExtremeValue',...
        'Normal','Lognormal','Gamma', 'ExtremeValue', 'Weibull',...
        'Exponential', 'tLocationScale','GeneralizedPareto',...
        'Logistic','LogLogistic'};

NameP = {   'Nakagami','G-ExtremeValue',...
            'Normal','Lognormal','Gamma', 'Gumbel', 'Weibull',...
            'Exponential', 'tLocationScale','GeneralizedPareto',...
            'Logistic','LogLogistic'};

% -------------------------------------------------------------------------
% Llenado de datos NaN con el valor promedio
% -------------------------------------------------------------------------
Data(isnan(Data)) = mean(Data(~isnan(Data)));

% -------------------------------------------------------------------------
% Estimación de distribucion empirica 
% -------------------------------------------------------------------------
[Fe,x_values] = ecdf(Data);

% -------------------------------------------------------------------------
% Error de ajuste inicial
% -------------------------------------------------------------------------
Error = 1E12;

if StatusPlot
        T   = [60 30];
        Fig = figure('color',[1 1 1], 'Units', 'centimeters',...
        'Position',[0, 0, T], 'visible','off');
end

for i = 1:length(CDF)
    % Parametros de la pdf evaluada
    test_cdf    = fitdist(Data,CDF{i});

    % Prueba de Kolmog�rov-Smirnov
    [h, p]      = kstest(Data,'CDF',test_cdf,'Alpha',0.05);
    
    % Distribucion teorica con la pdf evaluada
    Ft          = cdf(test_cdf, x_values);
    
    % Error Cuadratico Medio del ajuste 
    RMSE        = sqrt(mean((Fe - Ft).^2));

    % Mejor ajuste 
    if RMSE < Error 
        ParamBestPDF    = test_cdf; 
        Error           = RMSE;
        NamePDF         = CDF{i};
    end

    % ---------------------------------------------------------------------
    % Graficar ajustes
    % ---------------------------------------------------------------------
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

        box on 
        set(gca,'TickLabelInterpreter','latex', 'Fontsize',16)                                
    end

end

if ~obj.StatusPlot
    Fig = [];
end
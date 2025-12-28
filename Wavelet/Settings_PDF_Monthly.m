function [Name_Best,Mejorpdf, Error, NamePDF] = Settings_PDF_Monthly(obj, varargin)

%% AJUSTE FDP
% Error
Error = 1E12;

% Pdf a evaluar
CDF = {'Nakagami','GeneralizedExtremeValue',...
    'Normal','Lognormal','Gamma', 'ExtremeValue', 'Weibull',...
    'Exponential', 'tLocationScale','GeneralizedPareto',...
    'Logistic','LogLogistic'};

NameP = {'Nakagami','G-ExtremeValue',...
    'Normal','Lognormal','Gamma', 'Gumbel', 'ExtremeValue', 'Weibull',...
    'Exponential', 'tLocationScale','GeneralizedPareto',...
    'Logistic','LogLogistic'};

% CDF = {'Nakagami','GeneralizedExtremeValue',...
%     'Normal','Lognormal','Gamma', 'ExtremeValue', 'Weibull',...
%     'Exponential',...
%     'Logistic','LogLogistic'};

% NameP = {'Nakagami','G-ExtremeValue',...
%     'Normal','Lognormal','Gamma', 'Gumbel', 'Weibull',...
%     'Logistic','LogLogistic'};
if nargin > 1
    mes = varargin{1}; 
else
    mes = [];
end

if nargin > 2
    Code_PoPo = varargin{2}; 
else
    Code_PoPo = [];
end

if ~isempty(Code_PoPo)
    [~, PoPo] = ismember(Code_PoPo, obj.Code);
else
    PoPo = 1:length(obj.Code);
end

if nargin > 3
    NameLabel = varargin{3};
else
    NameLabel = [];
end

%% Create Folder
mkdir(fullfile(obj.PathProject,'FIGURES','PDF_TimeSeries'))
mkdir(fullfile(obj.PathProject,'RESULTS','PDF_TimeSeries'))

RMSE_All_Best   = zeros(length(PoPo),1);
Name_Best       = cell(length(PoPo),1);
for ii = 1:length(PoPo)
    try
        id          = find(~isnan(obj.Data(:,PoPo(ii))));
        Data        = obj.Data(id(1):id(end),PoPo(ii));

        %% Fitting NAN Value
        Data(isnan(Data)) = mean(Data(~isnan(Data)));
                
        %% Remove Zeros
%         Data = Data(Data>0);
        Data = reshape(Data(25:end,:),12,[]);
        Data = [Data(mes,:)]';
        % Distribucion empirica 
        [Fe,x_values] = ecdf(Data);

        if obj.StatusPlot
            T   = [60 30];
            Fig = figure('color',[1 1 1], 'Units', 'centimeters',...
                'Position',[0, 0, T], 'visible','off');
        end

        RMSE_All = zeros(length(CDF),1);
        for i = 1:length(CDF)
            % Parametros de la pdf evaluada
            test_cdf    = fitdist(Data,CDF{i});
            % Prueba de Kolmog�rov-Smirnov
            [h, p]      = kstest(Data,'CDF',test_cdf,'Alpha',0.05);
            % Distribucion teorica con la pdf evaluada
            Ft          = cdf(test_cdf, x_values);
            % Error Cuadratico Medio del ajuste 
            RMSE        = sqrt(sum((Fe - Ft).^2));
            RMSE_All(i) = RMSE;
            % Mejor ajuste 
            if RMSE < Error 
                Mejorpdf    = test_cdf; 
                Error       = RMSE;                
                NamePDF     = CDF{i};
                idNamePDF   = i;
            end

            %% Plotting
            if obj.StatusPlot
                subplot(3,4,i)
                plot(x_values,Fe,'-','Color',[0 0.5 0.5],'linewidth',1.5); 
                hold on 
                plot(x_values,Ft,':','Color',obj.ColorsF('carmine red'),'linewidth',1.5);
                axis([min(x_values) max(x_values) 0 1])

                title(['\bf ',NameP{i},newline,'RMSE = ',num2str(RMSE,'%0.2f')], 'interpreter','latex', 'Fontsize',15)
                Leg = legend('Fe','Ft');
                set(Leg,  'location','southeast','Fontsize',10);

                if (i == 1) || (i == 5) || (i == 9)
                    ylabel(sprintf('Frecuencia\nAcumulada'),'interpreter','latex', 'Fontsize',18)
                end

                if (i >= 9)
                    xlabel(NameLabel,'interpreter','latex', 'Fontsize',18)
                end

                if (i == 9)
                    xlabel(NameLabel,'interpreter','latex', 'Fontsize',18)
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
        %% Save
        if obj.StatusPlot
            saveas(Fig, fullfile(obj.PathProject,'FIGURES','PDF_TimeSeries',[num2str(obj.Code(PoPo(ii))),'_Mes_',num2str(mes),'_QL_',num2str(obj.Tipo),'.jpg']))
            close(Fig)
        end
        
        %% Save Data
%         NameFile    = fullfile(obj.PathProject,'RESULTS','PDF_TimeSeries',[num2str(obj.Code(PoPo(ii))),'_Mes_',num2str(mes),'_QL_',num2str(obj.Tipo),'.csv']);
%         ID_File     = fopen(NameFile,'w');
% 
%         fprintf(ID_File,'%s\n','Name PDF,Error');
%         for i = 1:length(CDF)
%             fprintf(ID_File, '%s,',NameP{i});
%             fprintf(ID_File, '%f\n',RMSE_All(i));
%         end
%         fclose(ID_File);
        
        %% Save Best
        RMSE_All_Best(ii)   = Error;
        Name_Best{ii}       = NamePDF;
        
        disp(['PDF Ok Gauges ->',num2str(obj.Code(PoPo(ii)))])
    catch
        disp(['PDF Error Gauges ->',num2str(obj.Code(PoPo(ii)))])
    end
end

Code = obj.Code(PoPo);
Code = reshape(Code,length(Code),1);

%% Save Data
NameFile    = fullfile(obj.PathProject,'RESULTS','PDF_TimeSeries',['Best_PDF','_Mes_',num2str(mes),'_QL_',num2str(obj.Tipo),'.csv']);
ID_File     = fopen(NameFile,'w');

fprintf(ID_File,'%s\n','Code,Name PDF,Error');
for i = 1:length(Code)
    fprintf(ID_File, '%f,',Code(i));
    fprintf(ID_File, '%s,',Name_Best{i});
    fprintf(ID_File, '%f\n',RMSE_All_Best(i));
end
fclose(ID_File);
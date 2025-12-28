function [TimeError, varargout] = Wavelets(obj, varargin)
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
%WAVETEST Example Matlab script for WAVELET, using NINO3 SST dataset
%
% See "http://paos.colorado.edu/research/wavelets/"
% Written January 1998 by C. Torrence
%
% Modified Oct 1999, changed Global Wavelet Spectrum (GWS) to be sideways,
%   changed all "log" to "log2", changed logarithmic axis on GWS to
%   a normal axis.

%% Addpath
% addpath( genpath(
TimeError = 0;

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
    NameLabelY = varargin{2};
else
    NameLabelY = '\bf Precipitaci\''on Total (mm)';
end

%% Create Folder
mkdir(fullfile(obj.PathProject,'FIGURES','Wavelets'))
mkdir(fullfile(obj.PathProject,'RESULTS','Wavelets'))

for ii = 1:length(PoPo)
    try
        id          = find(~isnan(obj.Data(:,PoPo(ii))));
        Data        = obj.Data(id(1):id(end),PoPo(ii));
        Date        = obj.Date(id(1):id(end));

        %% Fitting NAN Value
        Data(isnan(Data)) = mean(Data(~isnan(Data)));

        %% Paremeters
        % Delta time
        dt      = 1;
        % pad the time series with zeroes (recommended)
        pad     = 1;
        % this will do 4 sub-octaves per octave
        dj      = 0.05;
        % this says start at a scale of 6 months
        s0      = 2*dt;
        % this says do 7 powers-of-two with dj sub-octaves each
        n1      = length(Data);
        j1      = fix((log(n1*dt/s0)/log(2))/dj);%20/dj;
        % lag-1 autocorrelation for red noise background
        lag1    = 0.72;
        % Name Mother Wavelet 'MORLET' or 'PAUL' or 'DOG'
        mother  = 'MORLET';

        %% Normalize by standard deviation
        DataRaw = Data;
        variance = var(Data);
        Data     = (Data - mean(Data))/std(Data);
        n        = length(Data);
        
        %% Load Data 
%         NameFolfer = fullfile(obj.PathProject,'RESULTS','Wavelets', num2str(obj.Code(PoPo(ii))));
%         NameFile    = fullfile(NameFolfer,'Wave.csv');
%         wave        = dlmread(NameFile,',',0,0);
%         fclose('all');
        
        %% Wavelet transform
        [wave,period,scale,coi] = wavelet(Data,dt,pad,dj,s0,j1,mother);
        % compute wavelet power spectrum
        power = (abs(wave)).^2;
        
        global_ws = variance*(sum(power,2)/n);
        
        %% Significance levels: (variance=1 for the normalized SST)
        [signif,fft_theor] = wave_signif(1.0,dt,scale,0,lag1,-1,-1,mother);
        % expand signif --> (J+1)x(N) array
        sig95 = (signif')*(ones(1,n));  
        % where ratio > 1, power is significant
        sig95 = power ./ sig95;         

        %% Global wavelet spectrum & significance levels:
        global_ws = variance*(sum(power,2)/n);   % time-average over all times
        % The -scale corrects for padding at edges
        dof = n - scale;
        global_signif = wave_signif(variance,dt,scale,1,lag1,-1,dof,mother);

        %% Scale-average between El Nino periods of 2--8 years
        avg         = ((scale >= 2) & (scale < 8));
        % this is for the MORLET wavelet
        Cdelta      = 0.776;
        % expand scale --> (J+1)x(N) array
        scale_avg   = (scale')*(ones(1,n));
        % [Eqn(24)]
        scale_avg   = power ./ scale_avg;   
        % [Eqn(24)]
        scale_avg   = variance*dj*dt/Cdelta*sum(scale_avg(avg,:));   
        scaleavg_signif = wave_signif(variance,dt,scale,2,lag1,-1,[2,7.9],mother);

        if obj.StatusPlot
            %% Create Figure
            Fig     = figure('color',[1 1 1]);
            T       = [16, 8];
            set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
            [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off')

            %% Plot Time Series
            subplot(2,22,1:10)
%             area(Date,Data,'EdgeColor', [0 0.5 0.5], 'FaceColor', [0 0.75 0.75],...
%                 'FaceAlpha', 0.3, 'LineWidth',2)
            plot(Date,DataRaw,'Color', [0 0.75 0.75],'LineWidth',2)
            xlabel('\bf Time', 'Interpreter','latex', 'FontSize',20)
            ylabel(NameLabelY, 'Interpreter','latex', 'FontSize',20)
            title('\bf [a] Time Series','Interpreter','latex', 'FontSize',20)
            xlim([min(Date) max(Date)])
            set(gca, 'TickLabelInterpreter','latex', 'FontWeight','bold', 'box','on','FontSize',15)

            %% Plot Scale-average time series
            subplot(2,22,12:22)
            hold on 
%             area(Date,scale_avg,'EdgeColor', obj.ColorsF('carmine red'), 'FaceColor',...
%                 obj.ColorsF('carmine'), 'FaceAlpha', 0.3, 'LineWidth',2)
            plot(Date,scale_avg,'Color', obj.ColorsF('carmine red'),'LineWidth',2)
%             plot([Date(1) Date(end)],scaleavg_signif+[0,0],'--', 'Color', obj.ColorsF('orange-red'), 'LineWidth',2)
            xlabel('\bf Time','Interpreter','latex', 'FontSize',20)
            ylabel('\bf Average Variance','Interpreter','latex', 'FontSize',20)
            title('\bf [b] Average Time Series Scale', 'Interpreter','latex', 'FontSize',20)
            xlim([min(Date) max(Date)])
            set(gca, 'TickLabelInterpreter','latex', 'FontWeight','bold', 'box','on','FontSize',15)

            %% Plot Contour wavelet power spectrum
            subplot(2,22,23:32)
            hold on
            Date    = datenum(Date);
            levels  = [0.0625,0.125,0.25,0.5,1,2,4,8,16] ;
            Yticks  = 2.^(fix(log2(min(period))):fix(log2(max(period))));
            contourf(Date,log2(period),log2(power),log2(levels),...
                'Fill','on', 'LineStyle','none'); 
            % 95% significance contour, levels at -99 (fake) and 1 (95% signif)
            contour(Date,log2(period),sig95,[-99,1],'-.k','LineWidth',2);
            % cone-of-influence, anything "below" is dubious
            plot(Date,log2(coi),'-.r', 'LineWidth',2)
            set(gca,'XLim',[Date(1) Date(end)],...
                'YLim',log2([min(period),max(period)]), ...
                'YDir','reverse', ...
                'YTick',log2(Yticks(:)), ...
                'YTickLabel',Yticks)
            colormap('bone')
            datetick('x','yyyy')
            xlabel('\bf Time','Interpreter','latex', 'FontSize',20)
            ylabel('\bf Period ','Interpreter','latex', 'FontSize',20)
            title('\bf [c] Spectrum Power - Wavelet','Interpreter','latex', 'FontSize',20)
            PosiX = round(linspace(1, length(Data),9));
            DateName = cell(1, length(PosiX));
            for i = 1:length(PosiX)
                DateName{i} = datestr(Date(PosiX(i)), 'yyyy');
            end
            xlim([min(Date) max(Date)])
            set(gca, 'TickLabelInterpreter','latex', 'FontWeight','bold', 'box','on',...
                'FontSize',15,'XTick',Date(PosiX), ...
                'XTickLabel',DateName)

            %% Plot global wavelet spectrum
            subplot(2,22,34:39)
            hold on
            plot(global_ws,log2(period),'Color',obj.ColorsF('orange (ryb)'), 'LineWidth',2)
            %% Ojo !!!!  esta es la grafica del expectro global
%             plot(global_signif,log2(period),'-.','Color',obj.ColorsF('purple heart'), 'LineWidth',2)
            set(gca,'YLim',log2([min(period),max(period)]), ...
                'YDir','reverse', ...
                'YTick',log2(Yticks(:)), ...
                'YTickLabel','')
            xlabel('Power','Interpreter','latex', 'FontSize',20)
            title('\bf [d] Global Wavelet Spectrum','Interpreter','latex', 'FontSize',20)
            set(gca,'XLim',[0,1.25*max(global_ws)], 'TickLabelInterpreter','latex', 'FontWeight','bold', 'box','on','FontSize',15)

            %% Save
            saveas(Fig, fullfile(obj.PathProject,'FIGURES','Wavelets',[num2str(obj.Code(PoPo(ii))),'.jpg']))
            close(Fig)
        end

        %% Outputs
        varargout{1} = wave;
        varargout{2} = period;
        varargout{3} = scale;
        varargout{4} = coi;
        varargout{5} = signif;
        varargout{6} = fft_theor;
        varargout{7} = global_signif;
        varargout{8} = scaleavg_signif;

        %% Create Folder 
        NameFolfer = fullfile(obj.PathProject,'RESULTS','Wavelets', num2str(obj.Code(PoPo(ii))));
        mkdir(NameFolfer)

        %% Save Summary
        NameFile    = fullfile(NameFolfer,'Wave.csv');
        ID_File     = fopen(NameFile,'w');
        fprintf(ID_File, ['%f',repmat(',%f',1,length(wave(1,:))-1),'\n'],wave');
        fclose(ID_File);

        NameFile    = fullfile(NameFolfer,'Period.csv');
        ID_File     = fopen(NameFile,'w');
        fprintf(ID_File, '%f\n',period);
        fclose(ID_File);

        NameFile    = fullfile(NameFolfer,'Scale.csv');
        ID_File     = fopen(NameFile,'w');
        fprintf(ID_File, '%f\n',scale);
        fclose(ID_File);

        NameFile    = fullfile(NameFolfer,'coi.csv');
        ID_File     = fopen(NameFile,'w');
        fprintf(ID_File, '%f\n',coi);
        fclose(ID_File);

        NameFile    = fullfile(NameFolfer,'signif.csv');
        ID_File     = fopen(NameFile,'w');
        fprintf(ID_File, '%f\n',signif);
        fclose(ID_File);

        NameFile    = fullfile(NameFolfer,'fft_theor.csv');
        ID_File     = fopen(NameFile,'w');
        fprintf(ID_File, '%f\n',fft_theor);
        fclose(ID_File);

        NameFile    = fullfile(NameFolfer,'global_signif.csv');
        ID_File     = fopen(NameFile,'w');
        fprintf(ID_File, '%f\n',global_signif);
        fclose(ID_File);
        
        NameFile    = fullfile(NameFolfer,'global_ws_Fourier.csv');
        ID_File     = fopen(NameFile,'w');
        fprintf(ID_File, '%f\n',global_ws);
        fclose(ID_File);
        
        NameFile    = fullfile(NameFolfer,'global_ws_Fourier_Porc.csv');
        ID_File     = fopen(NameFile,'w');
        fprintf(ID_File, '%f\n',global_ws./sum(global_ws));
        fclose(ID_File);
        
        NameFile    = fullfile(NameFolfer,'scaleavg_signif.csv');
        ID_File     = fopen(NameFile,'w');
        fprintf(ID_File, '%f\n',scaleavg_signif);
        fclose(ID_File);

        disp(['Wavelet Ok Gauges ->',num2str(obj.Code(PoPo(ii)))])
    catch
        disp(['Wavelet Error Gauges ->',num2str(obj.Code(PoPo(ii)))])
    end
end

end

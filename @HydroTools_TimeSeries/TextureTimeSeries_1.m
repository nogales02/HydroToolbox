function TextureTimeSeries_1(obj,varargin)

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
    NameLabel = '\bf Data';
end

%% Create Folder
mkdir(fullfile(obj.PathProject,'FIGURES','TimeSeries'))

for ii = 1:length(PoPo)
    id          = find(~isnan(obj.Data(:,PoPo(ii))));
    Data        = obj.Data(id(1):id(end),PoPo(ii));
    Date        = obj.Date(id(1):id(end));

    %% Create Figure
    Fig     = figure('color',[1 1 1]);
    T       = [18, 10];
    set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
    [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off')    

    %% Plot Series
    subplot(2,20,1:14)   
    plot(Date,Data,'Color',[0 0.5 0.5],'LineWidth',1);
    % Label X
    xlabel('\bf Tiempo','Interpreter','latex','FontSize',20)
    % Label y
    ylabel(NameLabel,'Interpreter','latex','FontSize',20)
    % Properties
    set(gca, 'TickLabelInterpreter','latex', 'FontWeight','bold','Color','none', 'box','on','FontSize',18)    

    %% Plot Boxplot
    subplot(2,20,36:40)
    boxplot(Data,'PlotStyle','compact')
    % Label y
    ylabel(NameLabel,'Interpreter','latex','FontSize',20)
    % Properties
    set(gca,'Xtick',1:12,'Xticklabel',{'\bf Year'},'TickLabelInterpreter','latex', 'Fontsize',18)

    %% Plot Histogram
    subplot(2,20,17:20)
    h = histogram(Data);
    h.LineStyle = 'none';
    xlabel(NameLabel,'interpreter','latex', 'Fontsize',20)
    ylabel('\bf Frecuency','interpreter','latex', 'Fontsize',20)
    set(gca,'TickLabelInterpreter','latex', 'Fontsize',18)

    %% Plot Boxplot Monthly
    subplot(2,20,21:34)
    Months = month(Date)';
    PT    = NaN(31*length(unique(year(Date))),12);
    for j = 1:12
        PT(1:length(Data(Months == j)),j) = Data(Months == j);
    end

    boxplot(PT,'PlotStyle','compact')
    % Label y
    ylabel(NameLabel,'Interpreter','latex','FontSize',20)

    NameMes = {'\bf ENE', '\bf FEB','\bf MAR','\bf ABR','\bf MAY','\bf JUN',...
        '\bf JUL','\bf AGO','\bf SEP','\bf OCT','\bf NOV','\bf DIC'};
    set(gca,'Xtick',1:12,'Xticklabel',NameMes, 'TickLabelInterpreter','latex', 'Fontsize',18)
    
    %% Save    
    saveas(Fig, fullfile(obj.PathProject,'FIGURES','TimeSeries',[num2str(obj.Code(PoPo(ii))),'.jpg']))
    close(Fig)
    
end

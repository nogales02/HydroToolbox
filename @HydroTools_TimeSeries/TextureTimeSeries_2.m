function Fig = TextureTimeSeries_2(obj,varargin)

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
mkdir(fullfile(obj.PathProject,'FIGURES','TimeSeries_2'))

for ii = 1:length(PoPo)
    try
        id          = find(~isnan(obj.Data(:,PoPo(ii))));
        Data        = obj.Data(id(1):id(end),PoPo(ii));
        Date        = obj.Date(id(1):id(end));

        %% Create Figure
        Fig     = figure('color',[1 1 1]);
        T       = [18, 10];
        set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
        [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off')    

        %% Complet
        subplot(10,20,1:20)
        MyMap = [0.5 0.5 0.5; 1 1 1];
        colormap(MyMap)
        P = pcolor( bsxfun(@times, ~isnan([Data ones(length(Data(:,1)),1)]), (1:length(Data(1,:)) +1 ) )' );
        P.LineStyle = 'none';    
        set(gca,'YTicklabels','','XTicklabels','', 'box','on','linewidth',2)

        %% Plot Series
        subplot(10,20,21:200)  
        plot(Date,Data,'Color',[0 0.5 0.5],'LineWidth',1);
        % Label X
        xlabel('\bf Time','Interpreter','latex','FontSize',20)
        % Label y
        ylabel(NameLabel,'Interpreter','latex','FontSize',20)
        % Properties
        set(gca, 'TickLabelInterpreter','latex', 'FontWeight','bold','Color','none', 'box','on','FontSize',18)      

        %% Save    
        saveas(Fig, fullfile(obj.PathProject,'FIGURES','TimeSeries_2',[num2str(obj.Code(PoPo(ii))),'.jpg']))
        close(Fig)
        
        disp(['Plot Time Series - ', num2str(obj.Code(PoPo(ii))),' Ok'])
    catch
        disp(['Plot Time Series - ', num2str(obj.Code(PoPo(ii))),' Error'])
    end
    
end
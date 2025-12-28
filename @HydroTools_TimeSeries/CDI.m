function Results = CDI(obj, varargin)


%% Input
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
mkdir(fullfile(obj.PathProject,'FIGURES','CDI'))

for ii = 1:length(PoPo)
    id          = find(~isnan(obj.Data(:,PoPo(ii))));
    Data        = obj.Data(id(1):id(end),PoPo(ii));
    Date        = obj.Date(id(1):id(end));
    
    %% Fitting NAN Value
    Data(isnan(Data)) = mean(Data(~isnan(Data)));
    
    % Medias
    medias = mean(Data, 'omitnan');
    % Coeficiente de Variavion
    Cv = std(Data, 'omitnan')/medias;
    % Modularizamos
    k = Data./medias;
    % Centralizamos
    z = k - 1;
    % Estandarizamos
    z = z./Cv;
    % Suma acumulada
    Results = cumsum(z);
    
    %% Download ONI
    [DateONI, ONI] = obj.Download_ONI;
    
    %% Scale ONI
    dmax = max(Results)/max(ONI);
    dmin = max(Results)/max(ONI);
    
    %% NINO NINA
    NINO = ONI; NINO(NINO<0) = NaN;
    NINA = ONI; NINA(NINA>0) = NaN;
    NINO = NINO*dmax;
    NINA = NINA*dmin;
    
    %% Create Figure
    Fig     = figure('color',[1 1 1]);
    T       = [18, 10];
    set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
    [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off')        
    
    %% Plot Area
    area(DateONI, NINO, 'FaceColor','red','FaceAlpha',0.3,'LineStyle','none')
    hold on 
    area(DateONI, NINA, 'FaceColor','blue','FaceAlpha',0.3,'LineStyle','none')
    
    %% Plot Series
    plot(Date,Results,'Color',[0 0.5 0.5],'LineWidth',1.5,'LineStyle',':');
    % Label X
    xlabel('\bf Time','Interpreter','latex','FontSize',20)
    % Label y
    ylabel(NameLabel,'Interpreter','latex','FontSize',20)
    % Label y
    title('\bf Ciclos Seculares','Interpreter','latex','FontSize',24)
    % Properties
    set(gca, 'TickLabelInterpreter','latex', 'FontWeight','bold','Color','none', 'box','on','FontSize',18)      
    
    %% Save    
    saveas(Fig, fullfile(obj.PathProject,'FIGURES','CDI',[num2str(obj.Code(PoPo(ii))),'.jpg']))
    close(Fig)
end

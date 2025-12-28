function Summary_HydrologicalRegime_Month(obj, varargin)
% -------------------------------------------------------------------------
% Matlab - R2018b 
% -------------------------------------------------------------------------
%                           Informaci�n Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Componente    : Modelaci�n Hidrologica
% Organizaci�n  : The Nature Conservancy - TNC
% Fecha         : 01- July - 2019
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los t�rminos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener.Para mayor informaci�n revisar 
% http://www.gnu.org/licenses/.
%
% -------------------------------------------------------------------------
% Proyecto
%--------------------------------------------------------------------------
% Consultor�a t�cnica para el an�lisis de la cuenca alta y propuesta de 
% medidas de conservaci�n que contribuyan a la resiliencia de la cuenca del
% r�o Juan D�az en ciudad de Panam� para la mitigaci�n del riesgo por 
% inundaci�n
%
% -------------------------------------------------------------------------
% Descripci�n del Codigo
% -------------------------------------------------------------------------
% Este c�digo permite descargar la informaci�n de precipitaci�n, temperatura 
% m�nima y m�xima a resoluci�n diaria de los modelos meteorol�gicos globales 
% que modelan el cambio clim�tico (GCM). En total son 21 GCM de los cuales 
% se descarga la informaci�n, tanto para el hist�rico como para los 
% escenarios rcp45 y rcp85 
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
mkdir(fullfile(obj.PathProject,'FIGURES','Hydrological_Regime'))
mkdir(fullfile(obj.PathProject,'OUTPUTS','Hydrological_Regime'))

IRH_Total       = NaN(length(PoPo),1);
QAmb_Total      = NaN(length(PoPo),1);
Summary_Min     = NaN(length(PoPo),12);
Summary_Mean    = NaN(length(PoPo),12);
Summary_Max     = NaN(length(PoPo),12);

for ii = 1:length(PoPo)
    %% Input Data
    Date    = obj.Date;
    Q       = obj.Data(:,PoPo(ii));    
    IdDate  = find(~isnan(Q));
    Q       = Q(IdDate(1):IdDate(end));
    Date    = Date(IdDate(1):IdDate(end));
    Code    = obj.Code(PoPo(ii));
    XBasin  = obj.XBasin;
    YBasin  = obj.YBasin;
    CodeBasin = obj.Code;
    
    %% Plot    
%     [Fig, IRH, QAmb, SummaryQ] = Summary_Regimen(Date, Data, obj.Code(PoPo(ii)),...
%                 obj.XBasin, obj.YBasin, obj.Code);  

    %% Time Series Daily and Boxplot
    Fig     = figure('color',[1 1 1]);
    T       = [16, 22];
    set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
    [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off')    

    %% Plot Basin 
    subplot('position',[0.72 0.8 .25 .16])
    for Choco = 1:length(CodeBasin)        
        plot(polyshape(XBasin{Choco}, YBasin{Choco}),'FaceColor',[0.85 0.85 0.85],'FaceAlpha',0.2)
        hold on
    end
    id = CodeBasin == Code;
    plot(polyshape(XBasin{id}, YBasin{id}),'FaceColor','r','FaceAlpha',0.4)
    axis off
    title('\bf Ubicaci\''on','Interpreter','latex','FontSize',15,'Color',obj.ColorsF('jasper'))
    set(gca, 'Xticklabels', '','Yticklabels', '','linewidth',0.0001,'Color',[1 1 1],'box','off') 

    %% Histogram
    subplot('position',[0.78 0.64 .17 .12])
    histogram(Q)
    ylabel('\bf Frecuencia','Interpreter','latex','FontSize',15)
    xlabel('\bf Caudal $\bf {(m^3/s)}$','Interpreter','latex','FontSize',15)
    title('\bf Histograma','Interpreter','latex','FontSize',18,'Color',obj.ColorsF('jasper'))
    set(gca, 'TickLabelInterpreter','latex','FontSize',15, 'FontWeight','bold','linewidth',2,'Color','none','box','off')    

    %% Plot Other
    subplot('position',[0.05 0.82 .65 .16])    
    Month   = {'\bf ENE','\bf FEB','\bf MAR','\bf ABR','\bf MAY','\bf JUN',...
               '\bf JUL','\bf AGO','\bf SEP','\bf OCT','\bf NOV','\bf DIC'};
    % Data    = Qmon = reshape(Q(:,1),12,[])';
    Y       = unique(year(Date));
    DataTmp = NaN(length(Y),12);
    M       = month(Date);
    for i = 1:12
        Tmp = Q(M == i);
        DataTmp(1:length(Tmp),i) = Tmp; 
    end
    DataC   = [quantile(DataTmp,0.1); nanmean(DataTmp); quantile(DataTmp,0.95)];

    plot(1:12, DataC(1,:),'o-','Color',obj.ColorsF('jasper'), 'LineWidth', 2, 'MarkerEdgeColor',obj.ColorsF('blanched almond'),...
        'MarkerFaceColor',obj.ColorsF('jasper'),...
        'MarkerSize',5);
    hold on,
    plot(1:12, DataC(2,:),'o-','Color',obj.ColorsF('blue gray'), 'LineWidth', 2, 'MarkerEdgeColor',obj.ColorsF('blanched almond'),...
        'MarkerFaceColor',obj.ColorsF('jasper'),...
        'MarkerSize',5);
    plot(1:12, DataC(3,:),'o-','Color',obj.ColorsF('orange (web color)'), 'LineWidth', 2, 'MarkerEdgeColor',obj.ColorsF('blanched almond'),...
        'MarkerFaceColor',obj.ColorsF('jasper'),...
        'MarkerSize',5);
    xlim([0.5 12.5])
    ylabel('\bf Caudal $\bf {(m^3/s)}$','Interpreter','latex','FontSize',18)
    title('\bf Caudales m\''inimos, medios y m\''aximos mensuales multianuales','Interpreter','latex','FontSize',25,'Color',obj.ColorsF('jasper'))
    set(gca, 'TickLabelInterpreter','latex','FontSize',15, 'FontWeight','bold','linewidth',2,'Color','none','box','off') 
    Month   = {'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'};
    set(gca, 'Xtick',1:12,'Xticklabels',Month);
    ln = legend('\bf M\''inimo','\bf Medio','\bf M\''aximo');
    set(ln, 'interpreter','latex','FontSize',10,'location','northwest','orientation','horizontal')

    %% Table Summary
%     subplot('position',[0.05 0.8 .65 0.04]) 
%     Month   = {'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'};
    DataC   = round(DataC,2);
%     heatmap(Month,{'Qmin','Qmed','Qmax'},DataC,'Colormap',repmat((0.95:-0.01:0.5)',1,3));
%     set(gca, 'FontSize',12)
%     colorbar off
    SummaryQ = DataC;

    %% Boxplot
    subplot('position',[0.045 0.64 .65 0.12]) 
    boxplot(reshape(Q,12,[])','Labels',{'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'});
    ylabel('\bf Caudal $\bf {(m^3/s)}$','Interpreter','latex','FontSize',18)
    title('\bf Boxplot de caudales medios mensuales','Interpreter','latex','FontSize',25,'Color',obj.ColorsF('jasper'))
    set(gca, 'TickLabelInterpreter','latex','FontSize',15, 'FontWeight','bold','linewidth',2,'Color','none','box','off')  

    %% Time Series
    subplot('position',[0.05 0.49 .89 0.12]) 
    h = area(Date,Q);
    h(1).FaceColor = obj.ColorsF('blue gray');
    h(1).FaceAlpha = 0.4;
    % plot(Date,Q(:,1),'Color',[0 0.6 0.7],'LineWidth',1);
    xlabel('\bf Tiempo (meses)','Interpreter','latex','FontSize',18)
    ylabel('\bf Caudal $\bf {(m^3/s)}$','Interpreter','latex','FontSize',18)
    title('\bf Serie de tiempo de caudales medios mensuales','Interpreter','latex','FontSize',25,'Color',obj.ColorsF('jasper'))
    set(gca, 'TickLabelInterpreter','latex','FontSize',15,'linewidth',2,'Color','none','box','off') 

    %% Duration Curve Mensual
    subplot('position',[0.05 0.225 .89 0.22])
    [Por_Q,Qd]      = hist(Q,length(unique(Q)));
    [Qsort, id ]    = sort(Qd, 'descend');
    PQ              = (cumsum(Por_Q(id))/sum(Por_Q(id)))*100;
    [~, id]         = unique(PQ);

    Porcentaje      = [10 50 75 85 95];
    DataQ           = interp1(PQ(id), Qsort(id), Porcentaje);

    h = area(PQ, Qsort);
    h.FaceColor = obj.ColorsF('orange (web color)');
    h.FaceAlpha = 0.4;
    hold on 
    plot(PQ, Qsort,'k','Linewidth',2);
    axis([0 100 0 (max(Qsort) + (0.1*max(Qsort))) ])
    xlabel('\bf Frecuencia (\%)', 'interpreter', 'latex','fontsize',25)
    ylabel('\bf Caudal $\bf {(m^3/s)}$', 'interpreter', 'latex', 'fontsize',25)
    title('\bf Curva de duraci\''on de caudales medios mensuales','Interpreter','latex','FontSize',25,'Color',obj.ColorsF('jasper'))
    set(gca, 'TickLabelInterpreter','latex','FontSize',15,'linewidth',2,'Color','none','box','off') 

    ly = 0.95:-0.05:0.9 -(0.05*(length(DataQ)-1));
    scatter(Porcentaje,DataQ,15,[0 0.5 0.5],'filled')
    % plot(Porcentaje,DataQ, 'ro')
    for i = 1:length(Porcentaje)
        text(20 ,(ly(i)*(max(Qsort) + (0.1*max(Qsort))) ), ...
            ['\bf Q',num2str(Porcentaje(i),'%0.0f'),' = ', num2str(DataQ(i),'%0.2f')],  'interpreter', 'latex', 'fontsize',13)
    end      
    
    %% IRH
    Qmean           = mean(Q);
    Dife            = Qsort - Qmean;
    Dife(Dife<0)    = NaN;
    posi            = find(Dife == min(Dife));

    Vt  = trapz(PQ, Qsort);
    Vp  = (Qmean*PQ(posi)) + trapz(PQ(posi:end), Qsort(posi:end));
    IRH = Vp/Vt;

    %% Caudal Ambiental
    if IRH<0.70
        QAmb = DataQ(3);
    else
        QAmb = DataQ(4);
    end
    
    %% Total
    IRH_Total(ii)       = IRH;
    QAmb_Total(ii)      = QAmb;
    Summary_Min(ii,:)   = SummaryQ(1,:);
    Summary_Mean(ii,:)  = SummaryQ(2,:);
    Summary_Max(ii,:)   = SummaryQ(3,:);

    %% Save
    saveas(Fig, fullfile(obj.PathProject,'FIGURES','Hydrological_Regime',...
            ['Ficha-',num2str(obj.Code(PoPo(ii))),'.jpg']) )
    
    close all
    %% Disp
    disp(['Fichas de Regimen Hidrologico -> UHA-',num2str(obj.Code(PoPo(ii)))])
end

%% Save IRH y QAmb
NameParamsR = 'Code,IRH,Q_Amb\n';

fileID = fopen( fullfile(obj.PathProject, 'OUTPUTS','IRH_QAmb.csv'),'w');
Format = '%d,%f,%f\n';
fprintf(fileID,NameParamsR);
fprintf(fileID,Format,[obj.Code(PoPo), IRH_Total, QAmb_Total]');
fclose(fileID);

%% Save Qmin, Qmean y Qmax
NameParamsR = 'Code,ENE,FEB,MAR,ABR,MAY,JUN,JUL,AGO,SEP,OCT,NOV,DIC\n';
Format = '%d,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n';
fileID = fopen( fullfile(obj.PathProject, 'OUTPUTS','Qmin.csv'),'w');
fprintf(fileID,NameParamsR);
fprintf(fileID,Format,[obj.Code(PoPo), Summary_Min ]');
fclose(fileID);

fileID = fopen( fullfile(obj.PathProject, 'OUTPUTS','QMean.csv'),'w');
fprintf(fileID,NameParamsR);
fprintf(fileID,Format,[obj.Code(PoPo), Summary_Mean ]');
fclose(fileID);

fileID = fopen( fullfile(obj.PathProject, 'OUTPUTS','QMax.csv'),'w');
fprintf(fileID,NameParamsR);
fprintf(fileID,Format,[obj.Code(PoPo), Summary_Max]');
fclose(fileID);
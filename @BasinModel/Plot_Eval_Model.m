function [Fig, Summary, ResultsModel] = Plot_Eval_Model(obj, DateInit, DateEnd)
% -------------------------------------------------------------------------
% Matlab Version - R2018b 
% -------------------------------------------------------------------------
% Input Data
%     1 -> Model_Daily_BUCKET
%     2 -> Model_Daily_CREC
%     3 -> Model_Daily_GARDENIA
%     4 -> Model_Daily_GR4J
%     5 -> Model_Daily_HBV
%     6 -> Model_Daily_MARTINE
%     7 -> Model_Daily_MOHYSE
%     8 -> Model_Daily_MORD6
%     9 -> Model_Daily_SACRAMENTO
%     10 -> Model_Daily_QsimHYD
%     11 -> Model_Daily_TANK
%     12 -> Model_Daily_WAGENINGEN
%     13 -> Model_Daily_XINANJIANG

% NameModel = {   'MD_BUCKET';
%                 'MD_CREC';
%                 'MD_GARDENIA';
%                 'MD_GR4J';
%                 'MD_HBV';
%                 'MD_MARTINE';
%                 'MD_MOHYSE';
%                 'MD_MORD6';
%                 'MD_SACRAMENTO';
%                 'MD_QsimHYD';
%                 'MD_TANK';
%                 'MD_WAGENINGEN';
%                 'MD_XINANJIANG'};
        
%% Run Model
% Qsim        = zeros(length(obj.P(:,1)),length(obj.P(1,:)));
% for j = 1:length(obj.P(1,:))
%     eval(['[Qsim(:,j),inter,param] = obj.',NameModel{obj.NumberModel},...
%         '(obj.Parms, obj.P(:,j), obj.ETP(:,j), obj.Qb(:,j), obj.Area(j), obj.States_Init);']);
% end

a = obj.ParamsBasinCal(1, end-1);
b = obj.ParamsBasinCal(1, end);

%% GR4J
if strcmp(obj.NameModel,'GR4J')
    obj.GR4J;
elseif strcmp(obj.NameModel,'Thomas')
    obj.Thomas;
end                   

%% Qobs
id          = obj.Code == obj.RiverMouth;
IDGaugesCal = obj.GaugesCal(id);
id1         = obj.GaugesID == IDGaugesCal;
obs         = obj.Qobs(DateInit:DateEnd,id1);

%% Qsim
Qsim        = sum(obj.Qsim,2);
Qsim        = Qsim(DateInit:DateEnd);

%% Balance de reservorio
Basin       = obj;
VolSim      = Qsim*(3600*24);
VolR        = VolSim*0;
VolROut     = VolSim*0;
CotaMin     = 66.5;
Vol_i       = interp1(Basin.Reservoir_Level,...
                      Basin.Reservoir_Vol,....
                      CotaMin);

Vmin        = interp1(Basin.Reservoir_Level,...
                      Basin.Reservoir_Vol,....
                      CotaMin);
Cota = VolSim*0;
for i = 1:length(Qsim)
    % Update volumen time i
    Vol_i   = Vol_i + VolSim(i);
    
    % Cota
    Cota_i      = interp1(Basin.Reservoir_Vol,Basin.Reservoir_Level,Vol_i);

    % Vertedero 1
    if (Cota_i > 65.5) && (Basin.Date(i) <= datetime(2010,12,31))
        % Output volumen
        % Vout        = interp1(Basin.Gasto_Level,Basin.Gasto_Q,Cota_i)*3600*24;
        % Vout        =  2*13*((Cota_i - CotaMin)^(2/3))*3600*24;
        % Vout        =  a*13*((Cota_i - CotaMin)^b)*3600*24;               
        Vout        =  a*13.65*((Cota_i - 65.5)^b)*3600*24;
        
        if (Vol_i - Vout) < Vmin
            Vout = Vol_i - Vmin;
        end

        Vol_i       = Vol_i - Vout;        
    end

    % Vertedero 1
    if (Cota_i > CotaMin) && (Basin.Date(i) > datetime(2010,12,31))
        % Output volumen
        % Vout        = interp1(Basin.Gasto_Level,Basin.Gasto_Q,Cota_i)*3600*24;
        % Vout        =  2*13*((Cota_i - CotaMin)^(2/3))*3600*24;
        % Vout        =  a*13*((Cota_i - CotaMin)^b)*3600*24;               
        Vout        =  a*13.65*((Cota_i - CotaMin)^b)*3600*24;
        
        if (Vol_i - Vout) < Vmin
            Vout = Vol_i - Vmin;
        end

        Vol_i       = Vol_i - Vout;        
    end

    % % Vertedero 2
    % if Cota_i > 68.119
    %     % Output volumen
    %     % Vout        = interp1(Basin.Gasto_Level,Basin.Gasto_Q,Cota_i)*3600*24;
    %     % Vout        =  2*13*((Cota_i - CotaMin)^(2/3))*3600*24;
    %     % Vout        =  a*13*((Cota_i - CotaMin)^b)*3600*24;               
    %     Vout        =  a*7.46*((Cota_i - 68.119)^b)*3600*24;
    % 
    %     if (Vol_i - Vout) < Vmin
    %         Vout = Vol_i - Vmin;
    %     end
    % 
    %     Vol_i       = Vol_i - Vout;        
    % end
    VolROut(i) = Vout/(3600*24);

    VolR(i) = Vol_i;   
    Cota(i) = interp1(Basin.Reservoir_Vol,Basin.Reservoir_Level,Vol_i);
end

Qsim       = VolR; 
obs        = interp1(Basin.Reservoir_Level,Basin.Reservoir_Vol,obs);

%% Duration Curve
[Por_Q,Qd]          = hist(obs,length(unique(obs)));
[Q_Qobs, id ]   = sort(Qd, 'descend');
PQ_Qobs             = (cumsum(Por_Q(id))/sum(Por_Q(id)))*100;

[Por_Q,Qd]          = hist(Qsim,length(unique(Qsim)));
[Q_Qsim, id ]   = sort(Qd, 'descend');
PQ_Qsim             = (cumsum(Por_Q(id))/sum(Por_Q(id)))*100;

%% Date
Date        = datenum(obj.Date(DateInit:DateEnd));

%% Coefficient Nash
Nash        = 1 - ((mean((obs - Qsim).^2, 'omitnan'))./var(obs( ~isnan(obs) )));

%% Absolute Mean error 
Fuc_AME     = max(abs(obs-Qsim));
    
%% unlike peaks 
Fuc_PDIFF   = max(obs)-max(Qsim);

%% Mean Absolute Error 
Fuc_MAE     = mean(abs(obs-Qsim),'omitnan');

%% Mean Square Error 
Fuc_MSE     = mean((obs-Qsim).^2,'omitnan');

%% Mean Error
% Fuc_ME      = nanmean(obs-Qsim);

%% Root Mean Square Error
Fuc_RMSE    = sqrt(Fuc_MSE);

%% Root Fourth Mean Square Fourth Error
Fuc_R4MS4E  = nthroot((mean((obs-Qsim).^4,'omitnan')),4);

%% Root Absolute Error 
Fuc_RAE     = sum(abs(obs-Qsim),'omitnan')/sum(abs(obs-mean(obs,'omitnan')),'omitnan');

%% percent Error in peak 
Fuc_PEP     = ((max(obs)-max(Qsim))/max(obs))*100;

%% Mean Absolute Relative Error
Fuc_MARE    = mean(sum((abs(obs-Qsim))/obs,'omitnan'),'omitnan');

%% Mean Relative Error 
Fuc_MRE     = mean(sum((obs-Qsim)/obs,'omitnan'),'omitnan');

%% Mean Square Relative Error 
Fuc_MSRE    = mean(sum(((obs-Qsim)/obs).^2,'omitnan'),'omitnan');

%% PBIAS
Fuc_PBIAS   = (sum(obs-Qsim,'omitnan')/sum(obs,'omitnan'))*100;

%% Nash-Sutcliffe Coefficient of Efficiency
Enum        = sum((obs-Qsim).^2,'omitnan');
Edenom      = sum((obs-mean(obs,'omitnan')).^2,'omitnan');
Fuc_CE      = 1-Enum/Edenom;

%% Correlation Coefficient
Rnum        = sum((obs-mean(obs,'omitnan')).*(Qsim-mean(Qsim,'omitnan')),'omitnan');
Rdenom      = sqrt(sum((obs-mean(obs,'omitnan')).^2,'omitnan')*sum((Qsim-mean(Qsim,'omitnan')).^2,'omitnan'));
Fuc_R       = Rnum/Rdenom;

%% Percentage Bias Error
Fuc_PBE     = sum(Qsim-obs,'omitnan')/sum(obs,'omitnan')*100;

%% Average Absolute Relative Error
Fuc_ARE     = abs(((Qsim-obs)./obs)*100);
Fuc_ARE(isnan(Fuc_ARE)) = 0; Fuc_ARE(isinf(Fuc_ARE)) = 0;
Fuc_AARE    = mean(Fuc_ARE,'omitnan');

%% Threshold Statistics
p = zeros(1,size(obs,1)); 
q = zeros(1,size(obs,1)); 
r = zeros(1,size(obs,1)); 
s = zeros(1,size(obs,1));

for l = 1:size(obs,1)
   if Fuc_ARE(l)<1;   p(l) = 1; else, p(l) = 0; end
   if Fuc_ARE(l)<25;  q(l) = 1; else, q(l) = 0; end
   if Fuc_ARE(l)<50;  r(l) = 1; else, r(l) = 0; end
   if Fuc_ARE(l)<100; s(l) = 1; else, s(l) = 0; end      
end

Fuc_TS1   = mean(p,'omitnan')*100;
Fuc_TS25  = mean(q,'omitnan')*100;
Fuc_TS50  = mean(r,'omitnan')*100;
Fuc_TS100 = mean(s,'omitnan')*100;

%% Plot 
Fig     = figure('color',[1 1 1]);
T       = [20, 8];
set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
[0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off')

FontLabels = 22;
FontTick   = 15;
FontLegend = 16;

Carajo = (1:13);

%% Precipitacion
subplot(10,20,[Carajo (Carajo + 20) (Carajo + 40) (Carajo + 60)]);

Ax1 = plot(PQ_Qobs, Q_Qobs,'Color',obj.ColorsF('persian blue'),'LineWidth', 1.1);
hold on
Ax2 = plot(PQ_Qsim,Q_Qsim ,'-','Color',obj.ColorsF('orange (web color)'), 'LineWidth', 1);

axis([0 100 0 (max([obs; Qsim]) + (max([obs; Qsim])*0.2))])
box off
set(gca, 'TickLabelInterpreter','latex','FontSize',FontTick, 'FontWeight','bold','linewidth',2,'Color','none')
xlabel('\bf Frequency (\%)','interpreter','latex','FontSize',FontLabels, 'FontWeight','bold','FontName','Arial');
ylabel('\bf Volumen $\bf {(m^3)}$','interpreter','latex','FontSize',FontLabels, 'FontWeight','bold','FontName','Arial');

le = legend([Ax1 Ax2],'\bf Observed', '\bf Simulated');
set(le,'interpreter','latex','FontSize',FontLegend, 'FontWeight','bold', 'NumColumns',2,'box','off','color','none')

%% Caudales
subplot(10,20,[(Carajo + 100) (Carajo + 120) (Carajo + 140) (Carajo + 160) (Carajo + 180)])

% h = area(Date, Qsim);
% h.FaceColor = ColorsF('orange (web color)');
% h.FaceAlpha = 0.1   ;
% hold on

Ax1 = plot(Date, obs,'Color',obj.ColorsF('persian blue'),'LineWidth', 1.1);
hold on

Ax2 = plot(Date,Qsim ,'s-','Color',obj.ColorsF('orange (web color)'), 'LineWidth', 1, 'MarkerEdgeColor',obj.ColorsF('jasper'),...
    'MarkerFaceColor',obj.ColorsF('jasper'),...
    'MarkerSize',1.5);

datetick('x','yyyy')
xtickangle(45)
axis([min(Date), (max(Date) + 365),...
    (min([obs; Qsim]) - (min([obs; Qsim])*0.2)), (max([obs; Qsim]) + (max([obs; Qsim])*0.2))])
box off
set(gca, 'TickLabelInterpreter','latex','FontSize',FontTick, 'FontWeight','bold','linewidth',2,'Color','none')
if strcmp(obj.dt,'day')
    xlabel('\bf Time (D\''ay)','interpreter','latex','FontSize',FontLabels, 'FontWeight','bold','FontName','Arial');
elseif strcmp(obj.dt,'month')
    xlabel('\bf Time (Month)','interpreter','latex','FontSize',FontLabels, 'FontWeight','bold','FontName','Arial');
end
ylabel('\bf Volumen $\bf {(m^3)}$','interpreter','latex','FontSize',FontLabels, 'FontWeight','bold','FontName','Arial');

le = legend([Ax1 Ax2],'\bf Observed', '\bf Simulated');
set(le,'interpreter','latex','FontSize',FontLegend, 'FontWeight','bold', 'NumColumns',2,'box','off','color','none')


%% Obs Vs Qsim
subplot(10,20,[((16:20) + 100) ((16:20) + 120) ((16:20) + 140) ((16:20) + 160) ((16:20) + 180)])
Limit   = max([max(obs); max(Qsim)]);
x       = [0; Limit];
plot(x,x,'k','LineWidth',1.5)
hold on
scatter(obs, Qsim, 25,obj.ColorsF('jasper'),'filled', 'MarkerEdgeColor',obj.ColorsF('jazzberry jam'),'LineWidth',2)
axis([0 Limit 0 Limit])
set(gca, 'TickLabelInterpreter','latex','FontSize',FontTick, 'FontWeight','bold', 'linewidth',2)
xlabel('\bf Observed Flow $\bf {(m^3/s)}$','interpreter','latex','FontSize',FontLabels, 'FontWeight','bold');
ylabel('\bf Simulated Flow $\bf {(m^3/s)}$','interpreter','latex','FontSize',FontLabels, 'FontWeight','bold');

box off

%% Tabla
% %{
subplot(10,20,[16:20 ((16:20) + 20) ((16:20) + 40) ((16:20) + 60) ((16:20) + 80)]);
plot(0:1, 0:1.2, '.', 'color', [1 1 1])
set(gca, 'box','off','XTickLabel',[],'XTick',[],'YTickLabel',[],'YTick',[], 'XColor','none','YColor','none','linewidth',2)
Coor_X = 0.2;
maxcor = 1; max(max(obs),max(Qsim));
mincor = 0; min(min(obs),min(Qsim));

FnZ = 12;
lkn = 0.05;
% Dont change the spaces after the words 
text(Coor_X,((lkn*20*(maxcor-mincor))+ mincor),'\bf NASH', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*19*(maxcor-mincor))+ mincor),'\bf AME', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*18*(maxcor-mincor))+ mincor),'\bf PDIFF', 'interpreter','latex', 'FontSize',FnZ)
text(Coor_X,((lkn*17*(maxcor-mincor))+ mincor),'\bf MAE', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*16*(maxcor-mincor))+ mincor),'\bf MSE', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*15*(maxcor-mincor))+ mincor),'\bf RMSE', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*14*(maxcor-mincor))+ mincor),'\bf R4MS4E', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*13*(maxcor-mincor))+ mincor),'\bf RAE', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*12*(maxcor-mincor))+ mincor),'\bf PEP', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*11*(maxcor-mincor))+ mincor),'\bf MARE', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*10*(maxcor-mincor))+ mincor),'\bf MRE', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*9*(maxcor-mincor))+ mincor),'\bf MSRE', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*8*(maxcor-mincor))+ mincor),'\bf PBIAS', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*7*(maxcor-mincor))+ mincor),'\bf R', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*6*(maxcor-mincor))+ mincor),'\bf CE', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*5*(maxcor-mincor))+ mincor),'\bf PBE', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*4*(maxcor-mincor))+ mincor),'\bf AARE', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*3*(maxcor-mincor))+ mincor),'\bf TS1', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*2*(maxcor-mincor))+ mincor),'\bf TS25', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((lkn*1*(maxcor-mincor))+ mincor),'\bf TS50', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.00*(maxcor-mincor))+ mincor),'\bf TS100', 'interpreter','latex', 'FontSize', FnZ)

Coor_X = 0.5;

text(Coor_X,((1.00*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.95*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.90*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.85*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.80*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.75*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.70*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.65*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.60*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.55*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.50*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.45*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.40*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.35*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.30*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.25*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.20*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.15*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.10*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.05*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.00*(maxcor-mincor))+ mincor),'=', 'interpreter','latex', 'FontSize', FnZ)

Coor_X = 0.6;

text(Coor_X,((1.00*(maxcor-mincor))+ mincor),num2str(Nash,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.95*(maxcor-mincor))+ mincor),num2str(Fuc_AME,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.90*(maxcor-mincor))+ mincor),num2str(Fuc_PDIFF,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.85*(maxcor-mincor))+ mincor),num2str(Fuc_MAE,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.80*(maxcor-mincor))+ mincor),num2str(Fuc_MSE,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.75*(maxcor-mincor))+ mincor),num2str(Fuc_RMSE,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.70*(maxcor-mincor))+ mincor),num2str(Fuc_R4MS4E,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.65*(maxcor-mincor))+ mincor),num2str(Fuc_RAE,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.60*(maxcor-mincor))+ mincor),num2str(Fuc_PEP,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.55*(maxcor-mincor))+ mincor),num2str(Fuc_MARE,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.50*(maxcor-mincor))+ mincor),num2str(Fuc_MRE,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.45*(maxcor-mincor))+ mincor),num2str(Fuc_MSRE,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.40*(maxcor-mincor))+ mincor),num2str(Fuc_PBIAS,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.35*(maxcor-mincor))+ mincor),num2str(Fuc_R,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.30*(maxcor-mincor))+ mincor),num2str(Fuc_CE,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.25*(maxcor-mincor))+ mincor),num2str(Fuc_PBE/100,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.20*(maxcor-mincor))+ mincor),num2str(Fuc_AARE,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.15*(maxcor-mincor))+ mincor),num2str(Fuc_TS1/100,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.10*(maxcor-mincor))+ mincor),num2str(Fuc_TS25/100,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.05*(maxcor-mincor))+ mincor),num2str(Fuc_TS50/100,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)
text(Coor_X,((0.00*(maxcor-mincor))+ mincor),num2str(Fuc_TS100/100,'%0.2f'), 'interpreter','latex', 'FontSize', FnZ)

%}

%% Summary metric 
Summary = [ Nash,...
            Fuc_AME, Fuc_PDIFF, Fuc_MAE, Fuc_MSE, Fuc_RMSE, Fuc_R4MS4E, Fuc_RAE,...
            Fuc_PEP, Fuc_MARE, Fuc_MRE, Fuc_MSRE, Fuc_PBIAS, Fuc_R, Fuc_CE, Fuc_PBE/100,...
            Fuc_AARE, Fuc_TS1/100, Fuc_TS25/100, Fuc_TS50/100, Fuc_TS100/100];
        
ResultsModel = [obs Qsim];
        
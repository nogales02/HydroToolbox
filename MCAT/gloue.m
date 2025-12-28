function gloue;

% function gloue
%
% Calculation and plotting of GLUE confidence limits
%
% Thorsten Wagener & Matthew Lees, Imperial College London, May 2000

% CALCULATE LIKELIHOOD
gvs=get(0,'userdata');
of=gvs.dat(:,gvs.ff(1)+gvs.LS);  % criteria (low values indicate better models)
of=1-of; % likelihood (high values indicate more likely [probable] models)
if min(of)<0, of=of-min(of);end; % transform negative lhoods
if min(of)==0 % move slightly above zero so that the CFD is monotonic 
   [junk]=sort(of);
   cc=find(junk>0);cc=min(cc);
   of=of+junk(cc);
end
of=of./max(of); % scaling from 0 to 1

% BEST MODEL
cc=find(of==max(of));
bestm=gvs.mct(:,cc);

% TIME STEP
if ~isempty(gvs.dt)
  ustr='minutes';
  if gvs.dt>59&gvs.dt<1440
    ustr='hours';gvs.dt=gvs.dt/60;
  elseif gvs.dt>1439&gvs.dt<10079
    ustr='days';gvs.dt=gvs.dt/1440;
  elseif gvs.dt>10079&gvs.dt<40000
    ustr='weeks';gvs.dt=gvs.dt/10080;
  elseif gvs.dt>40000
    ustr='months';gvs.dt=gvs.dt/10080;
  end
else
   ustr='samples';
end

% CALCULATE CONFIDENCE LIMITS AND MEAN VALUES FOR EACH TIME STEP

% create objective function matrix
[ndt,junk] =size(gvs.mct);
of_matrix_1=of(:,ones(1,ndt))';    % Tony's trick
of_matrix_2=of_matrix_1;           % Intialisation
[sq,index] =sort(gvs.mct');
sq         =sq';
index      =index';
S          =size(of_matrix_1);

% try
for i=1:S(1)
   for j=1:S(2)
      of_matrix_2(i,j)=of_matrix_1(i,index(i,j));
   end
end
% catch
%     kopo =1;
% end

%% Tester Ojo !!!!!
% gvs.lci = 0.01;
% gvs.uci = 0.99;

% create mean and CIs
for i=1:ndt
   pcsof(i,:)=cumsum(of_matrix_2(i,:))./sum(of_matrix_2(i,:));
   cc=find(pcsof(i,:)<gvs.lci);pclci(i)=sq(i,max(cc));
   cc=find(pcsof(i,:)>gvs.uci);pcuci(i)=sq(i,min(cc));
   %pclci(i)  =interp1(pcsof(i,:),sq(i,:),gvs.lci);
   %pcuci(i)  =interp1(pcsof(i,:),sq(i,:),gvs.uci);
   mq(i)     =mean(sq(i,:));
end

% calculate the (normalized) width of the confidence limits
dq=(pcuci-pclci)./(max(pcuci-pclci));

% PLOT FIGURE
if isempty(gvs.t),t=1:length(bestm);else,t=gvs.t;end

%% Plot ABCD
% subplot('position',[0.13 0.22 .775 .7]);
% 
% area(t,pcuci,'faceColor',[.8 .8 .8],'edgeColor','k');hold on;
% area(t,pclci,'faceColor','w','edgeColor','k');hold on;
% if ~isempty(gvs.obs),plot(t,gvs.obs,'o','markeredgecolor','k','markerfacecolor','b','markersize',5);hold on;end
% %plot(t,bestm,'k--','linewidth',2);
% set(gca,'xlim',[min(t) max(t)]);
% ln = legend('Observed','Confidence Limits','Location','best');
% set(ln, 'interpreter','latex','FontSize',25, 'FontWeight','bold')
% title(['Model output and associated confidence limits' ' (UCI=' num2str(gvs.uci) ', LCI=' num2str(gvs.lci) ')'],...
%      'interpreter','latex','FontSize',28, 'FontWeight','bold');
% set(gca,'xticklabel',' ');
% 
% %% EDIT 
% set(gca, 'TickLabelInterpreter','latex','FontSize',28, 'FontWeight','bold')
%     
% subplot('position',[0.13 0.11 .775 .1]);
% area(t,dq,'facecolor',[0.8 0.8 0.8],'edgecolor','k');
% xlabel(['Time [' ustr ']'],  'interpreter','latex','FontSize',25, 'FontWeight','bold');
% ylabel('dCFL',  'interpreter','latex','FontSize',25, 'FontWeight','bold');
% set(gca,'xlim',[min(t) max(t)]);
% 
% %% EDIT 
% datetick('x','yyyy')
% xtickangle(45)
% set(gca, 'TickLabelInterpreter','latex','FontSize',28, 'FontWeight','bold')


%% Plot HEC-HMS
TTi       = [20, 10];
set(gcf, 'Units', 'Inches', 'PaperPosition', [0, 0, TTi],'Position',...
[0, 0, TTi],'PaperUnits', 'Inches','PaperSize', TTi,'PaperType','usletter')

subplot('position',[0.13 0.24 .775 .7]);

Ax = area(t,pcuci,'faceColor',ColorsF('cinnamon'),'edgeColor',ColorsF('cinnamon'),'FaceAlpha',0.3,'LineWidth',1);hold on;
area(t,pclci,'faceColor','w','edgeColor',ColorsF('cinnamon'),'LineWidth',2);hold on;
if ~isempty(gvs.obs)
    Qobs = gvs.obs;
%     plot(t,gvs.obs,'o','markeredgecolor','k','markerfacecolor','b','markersize',5);hold on;
    Ax2 = scatter(t, Qobs, 5,ColorsF('green (pigment)'),'filled','MarkerEdgeColor',ColorsF('green (pigment)'));
%     tt1 = find( Qobs(1:length(Qobs) - 1) == max(Qobs(1:length(Qobs)-1)));
%     scatter(tt1, Qobs(end), 50,ColorsF('dark sienna'),'filled','MarkerEdgeColor',ColorsF('dark sienna'))    
end
%plot(t,bestm,'k--','linewidth',2);
set(gca,'xlim',[min(t) max(t)]);
ln = legend([Ax Ax2],'Limite de Confianza','Observado','Location','best');
set(ln, 'interpreter','latex','FontSize',25, 'FontWeight','bold')
title(['\bf Salida del modelo y l\''imites de confianza asociados' ' (UCI=' num2str(gvs.uci) ', LCI=' num2str(gvs.lci) ')'],...
     'interpreter','latex','FontSize',28, 'FontWeight','bold','Interpreter','latex');
ylabel('\bf Caudal $\bf {(m^3/s)}$','Interpreter','latex');
set(gca,'xticklabel',' ');

%% EDIT 
set(gca, 'TickLabelInterpreter','latex','FontSize',28, 'FontWeight','bold')
    
subplot('position',[0.13 0.11 .775 .1]);
area(t,dq,'facecolor',ColorsF('french blue'),'edgecolor',ColorsF('french blue'), 'FaceAlpha',0.3);
xlabel(['\bf Tiempo'],  'interpreter','latex','FontSize',25, 'FontWeight','bold');
ylabel('\bf dCFL',  'interpreter','latex','FontSize',25, 'FontWeight','bold');
set(gca,'xlim',[min(t) max(t)]);

%% EDIT 
Vau = round(linspace(1,length(pcuci),10));
% NaVau = cell(1, length(Vau));
% for s = 1:length(Vau)
%     NaVau{s} = num2str(Vau(s)*5);
% end
set(gca,'XTick',t(Vau), 'XTickLabel',datestr(t(Vau),'yyyy'))

% xtickangle(45)
set(gca, 'TickLabelInterpreter','latex','FontSize',28, 'FontWeight','bold')

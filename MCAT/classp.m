function class;

% function class
%
% Plotting of time series output by likelihood/variable class
%
% Matthew Lees & Thorsten Wagener, Imperial College London, May 2000

gvs=get(0,'userdata');
perfs=str2mat(gvs.lhoods,gvs.vars);
lp=gvs.PS;

% CALCULATE LIKELIHOOD
of=gvs.dat(:,gvs.ff(1)+lp);  % criteria (low values indicate better models)
of=1-of; % likelihood (high values indicate more likely [probable] models)
if min(of)<0|min(of)==0, of=of-min(of)+1000*eps;end; % transform negative lhoods 

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

% 10 MODELS OVER THE LIKELIHOOD/VARIABLE RANGE
[of,i]=sort(of);
smod=gvs.mct';smod=smod(i,:);
obfrange=max(of)-min(of);
for i=0:9
   boundary=min(of)+(obfrange/10)*i;
   cc=find(of>boundary);
   cc=min(cc);
   modclass(i+1,:)=smod(cc,:);
end
modclass(11,:)=smod(max(find(of==max(of))),:);
if gvs.PS>gvs.ff(2),modclass=flipud(modclass);end % variable

% PLOT FIGURE
if isempty(gvs.t),cc=size(gvs.mct);t=1:cc(1);else,t=gvs.t;end

%% Create Figure
% set(gcf,'DefaultAxesColorOrder',cool(12))
set(gcf,'DefaultAxesColorOrder',colormap(flipud(jet(11))))
TTi       = [20, 10];
set(gcf, 'Units', 'Inches', 'PaperPosition', [0, 0, TTi],'Position',...
[0, 0, TTi],'PaperUnits', 'Inches','PaperSize', TTi,'PaperType','usletter')

plot(t,modclass','LineWidth',2);hold on;
if ~isempty(gvs.obs),
   if length(t)~=length(gvs.obs), 
      t=1:length(gvs.obs);
   end
   plot(t,gvs.obs,'o','markeredgecolor',ColorsF('jasper'),'markerfacecolor',ColorsF('blue gray'),'markersize',7),hold on,
end

set(gca, 'TickLabelInterpreter','latex','FontSize',28, 'FontWeight','bold')
%plot(modclass(11,:),'m','linewidth',3);
hold off;
set(gca,'xlim',[min(t) max(t)]);
ylabel('\bf Caudal $\bf {(m^3/s)}$','Interpreter','latex');
xlabel(['\bf Tiempo [' ustr ']'], 'Interpreter','latex');
title('\bf Class output simulations','Interpreter','latex')

% colormap(cool(11));
colormap(flipud(jet(11)))
h=axes('position',[.96 .117 .02 .780]);
set(h, 'TickLabelInterpreter','latex','FontSize',22, 'FontWeight','bold')
h=colorbar(h);
set(h,'ytick',[2 11]);
set(h,'yticklabel',['L';'H']);
set(h,'yaxislocation','left');
set(get(gca,'ylabel'),'verticalalignment','top');
lstr=perfs(lp,:);lstr=unpad(lstr,' ','b');lstr=unpad(lstr,' ','e');
if lp<gvs.ff(2)+1
   ko = ylabel(['\bf Likelihood(' lstr ')'], 'Interpreter','latex','FontSize',15);
   ko.Position(1) = ko.Position(1) - 5;
else
   ylabel(lstr)
end

set(gca, 'TickLabelInterpreter','latex','FontSize',20, 'FontWeight','bold')

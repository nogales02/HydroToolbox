%% Plot Multifractal spectrum
function Fig = Plot_MultifractalSpectrum(obj, Alfa, F_Alfa,q)

Fig     = figure('color',[1 1 1], 'Visible','off');
T       = [10, 8];
set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
    [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','e')

subplot(1,10,1:9)
hold on
% box on

% Plot Multifractal spectrum
scatter(Alfa, F_Alfa,5,'filled','MarkerFaceColor',[0 0.7 0.7])

% Plor line tan
plot([0 max([max(Alfa); max(F_Alfa)])*10], [0 max([max(Alfa); max(F_Alfa)])*10],...
    'Color',obj.ColorsF('jasper'), 'LineWidth',1.5)

% Limit
Factor = 0.1;
Factor2 = 0.15;

xlabel('\bf ${\alpha}$', 'interpreter', 'latex','fontsize',25)
ylabel('\bf f(\bf ${\alpha}$)', 'interpreter', 'latex', 'fontsize',25)

set(gca,'TickLabelInterpreter','latex', 'fontsize',20, 'FontWeight','bold','linewidth',2,'Color','none')

xlim([min(Alfa) - Factor*max(Alfa), max(Alfa)+ Factor2*max(Alfa)])
% ylim([min(F_Alfa) - Factor*max(F_Alfa), max(F_Alfa)+ Factor*max(F_Alfa)])
ylim([0, max(F_Alfa)+ Factor*max(F_Alfa)])

% 
Po = length(Alfa);
Po1 = 1;
POPO = max(Alfa)+ Factor2*max(Alfa);
Factor = 0.01;
scatter(Alfa(Po), F_Alfa(Po),30,'filled','MarkerFaceColor',obj.ColorsF('carmine'))
% text(Alfa(Po) + Alfa(Po)*Factor, F_Alfa(Po) - F_Alfa(Po)*Factor, ['q = ',num2str(q(Po),'%0.f'),sprintf('\n'),...
text(POPO, 1, ['q = ',num2str(q(Po),'%0.f'),sprintf('\n'),...
    '${\alpha_{min}}$ = ',num2str(Alfa(Po),'%0.2f'), sprintf('\n'),...
    'f(${\alpha_{min}}$) = ',num2str(F_Alfa(Po),'%0.2f')],...
    'Interpreter','latex', 'FontSize',15, 'Color', obj.ColorsF('carmine'))

Po = 1;
Factor = 0.01;
scatter(Alfa(Po), F_Alfa(Po),30,'filled','MarkerFaceColor',obj.ColorsF('orange (ryb)'))
% text(Alfa(Po) + Alfa(Po)*Factor, F_Alfa(Po), ['q = ',num2str(q(Po),'%0.f'),sprintf('\n'),...
text(POPO, 0.85, ['q = ',num2str(q(Po),'%0.f'),sprintf('\n'),...
    '${\alpha_{max}}$ = ',num2str(Alfa(Po),'%0.2f'), sprintf('\n'),...
    'f(${\alpha_{max}}$) = ',num2str(F_Alfa(Po),'%0.2f')],...
    'Interpreter','latex', 'FontSize',15, 'Color',obj.ColorsF('orange (ryb)'))


Po = find(q == 0);
Factor = 0.05;
scatter(Alfa(Po), F_Alfa(Po),30,'filled','MarkerFaceColor',obj.ColorsF('blue'))
% text(Alfa(Po) + Alfa(Po)*Factor, F_Alfa(Po), ['q = ',num2str(q(Po),'%0.f'),sprintf('\n'),...
text(POPO, 0.7, ['q = ',num2str(q(Po),'%0.f'),sprintf('\n'),...
    '${\alpha}$ = ',num2str(Alfa(Po),'%0.2f'), sprintf('\n'),...
    'f(${\alpha}$) = ',num2str(F_Alfa(Po),'%0.2f')],...
    'Interpreter','latex', 'FontSize',15, 'Color',obj.ColorsF('blue'))

Po = find(q == 1);
Factor = 0.11;
scatter(Alfa(Po), F_Alfa(Po),30,'filled','MarkerFaceColor',obj.ColorsF('black'))
% text(Alfa(Po) - Alfa(Po)*Factor, F_Alfa(Po), ['q = ',num2str(q(Po),'%0.f'),sprintf('\n'),...
text(POPO, 0.55, ['q = ',num2str(q(Po),'%0.f'),sprintf('\n'),...
    '${\alpha}$ = ',num2str(Alfa(Po),'%0.2f'), sprintf('\n'),...
    'f(${\alpha}$) = ',num2str(F_Alfa(Po),'%0.2f')],...
    'Interpreter','latex', 'FontSize',15, 'Color',obj.ColorsF('black'))
end

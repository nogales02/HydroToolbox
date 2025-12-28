function Plot_SummaryDataEmpty(obj, varargin)
% -------------------------------------------------------------------------
% Matlab - R2019b 
% -------------------------------------------------------------------------
%                           Informaciónn Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los tï¿½rminos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener.Para mayor informaciï¿½n revisar 
% http://www.gnu.org/licenses/.
%
% -------------------------------------------------------------------------
% Descripción del Codigo
% -------------------------------------------------------------------------
% 
% -------------------------------------------------------------------------
% Input
% -------------------------------------------------------------------------
% 
% -------------------------------------------------------------------------
% Output obj.Data
% -------------------------------------------------------------------------
% 

%% Check Inputs
if nargin > 1
%     NameLabel = 'Time (Days)';
    NameLabel = varargin{1};    
else
    % NameLabel = "A\~no";
    NameLabel = "Year";
end


if nargin > 2
%     NameLabel = 'Time (Days)';
    SaveName = varargin{2};
else
    SaveName = 'SummaryDataEmpty_RawData.jpg';
end

%% Emptys
% Figure_English
Fig     = figure('color',[1 1 1]);
T       = [18, length(obj.Code)*0.3];
set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
[0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off')   

P = pcolor( bsxfun(@times, ~isnan([obj.Data ones(length(obj.Data(:,1)),1)]), (1:length(obj.Data(1,:)) +1 ) )' );
P.LineStyle = 'none';
% MyMap = lines;
MyMap = [0.5 0.5 0.5];
while length(MyMap(:,1)) < length(obj.Data(1,:))
    MyMap = [MyMap; MyMap];
end
MyMap = MyMap(1:length(obj.Data(1,:)),:);
MyMap(1,:) = 1;
colormap(MyMap)
yticks(linspace(0.5,length(obj.Data(1,:)) + 0.5,length(obj.Data(1,:)) + 1))
yticklabels({'Tmp',obj.Name{:}});
ID = round(linspace(1,length(obj.Date),10));
xticks(ID)
SD = datestr(obj.Date(ID),'yyyy');
La = cell(1,length(ID));
for i = 1:length(ID)
    La{i} = SD(i,:);
end

xticklabels(SD)
xlabel(NameLabel,'interpreter','latex', 'Fontsize',20)
set(gca, 'TickLabelInterpreter','latex', 'FontWeight','bold', 'box','on','FontSize',18, 'linewidth',2)

%% SaveData
mkdir(fullfile(obj.PathProject,'FIGURES','Summary'))
saveas(Fig, fullfile(obj.PathProject,'FIGURES','Summary',SaveName))
close(Fig)

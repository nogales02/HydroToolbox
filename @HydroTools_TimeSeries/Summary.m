function [Summary, Sdate] = Summary(obj, varargin)
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

%% Create Folder
mkdir(fullfile(obj.PathProject,'RESULTS'))

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
    NameFile = fullfile(obj.PathProject,'RESULTS',[varargin{2},'.csv']);
    NameFig  = fullfile(obj.PathProject,'FIGURES',[varargin{2},'.jpg']);
else
    NameFile = fullfile(obj.PathProject,'RESULTS','Summary_Raw.csv');
    NameFig  = fullfile(obj.PathProject,'FIGURES','Summary_Raw.jpg');
end

if nargin > 3
    NamFun = varargin{3};
else
    NamFun = 'Mean';
end

%% Storage
Summary = zeros(length(PoPo), 10 + 12);
Sdate   = cell(length(PoPo), 2);

for ii = 1:length(PoPo)      
    id          = find(~isnan(obj.Data(:,PoPo(ii))));
    if isempty(id)
        continue
    end
    Data        = obj.Data(id(1):id(end),PoPo(ii));
    Date        = obj.Date(id(1):id(end));

    Summary(ii,1)  = min(Data);
    Summary(ii,2)  = max(Data);
    Summary(ii,3)  = mean(Data,'omitnan');
    Summary(ii,4)  = std(Data(~isnan(Data)));
    Summary(ii,5)  = var(Data(~isnan(Data)));
    Summary(ii,6)  = sum(~isnan(Data));    
    Summary(ii,7)  = (sum(~isnan(Data))/length(Data))*100;
    Summary(ii,8)  = length(unique(year(Date)));
    Summary(ii,9)  = sum(isnan(Data));
    Summary(ii,10) = (sum(isnan(Data))/length(Data))*100;

    m = month(Date);
    for i = 1:12
        if strcmp(NamFun,'Mean')
            Summary(ii,10+i) = mean(Data(m == i),'omitnan');
        elseif strcmp(NamFun,'Max')
            Summary(ii,10+i) = max(Data(m == i));
        elseif strcmp(NamFun,'Min')
            Summary(ii,10+i) = min(Data(m == i),'omitnan');
        elseif strcmp(NamFun,'Sum')
            Summary(ii,10+i) = sum(Data(m == i),'omitnan');
        end
    end

    Sdate{ii,1}    = datestr(Date(1), 'yyyy/mm/dd HH:MM:SS');
    Sdate{ii,2}    = datestr(Date(end),'yyyy/mm/dd HH:MM:SS');
end

if obj.StatusPlot
    mkdir(fullfile(obj.PathProject,'FIGURES'))
    
    %% Plot Datos faltantes
    Fig     = figure('color',[1 1 1], 'Visible','off');
    T       = [10, 8];
    set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
        [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','e')

    h = histogram(Summary(:,10),'BinEdges',0:5:100);
    h.FaceColor = [0.5 0.5 0.5];
    h.FaceAlpha = 0.5;
    h.EdgeColor = [0.5 0.5 0.5];
    set(gca,'TickLabelInterpreter','latex', 'fontsize',26)
    ylabel('\bf Number of stations', 'interpreter', 'latex','fontsize',28)
    xlabel('\bf Missing data ${(\%)}$', 'interpreter', 'latex', 'fontsize',28)

    saveas(Fig, NameFig)
    close(Fig)
end

%%
Code = obj.Code(PoPo);
Code = reshape(Code,length(Code),1);

%% Save Summary
Name        = [ 'Code,X,Y,Z,Min,Max,Mean,Std,Var,Data (Number),Data (Porc),Record  Relative (Year),',...
                'Empty (Number),Empty (Porc),ENE,FEB,MAR,ABR,MAY,JUN,JUL,AGO,SEP,OCT,NOV,DIC,Date_Init,Date_End'];

ID_File     = fopen(NameFile,'w');

fprintf(ID_File,'%s\n',Name);

for i = 1:length(PoPo)
    fprintf(ID_File, ['%f',repmat(',%f',1,3+22)],[Code(i),obj.X(i),obj.Y(i),obj.Z(i) Summary(i,:)]);
    fprintf(ID_File,',%s', datestr(Sdate{i,1},'dd/mm/yyyy HH:MM:SS'));  
    fprintf(ID_File,',%s\n', datestr(Sdate{i,2},'dd/mm/yyyy HH:MM:SS'));  
end
fclose(ID_File);

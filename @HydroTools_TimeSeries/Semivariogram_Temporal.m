function Semivariogram_Temporal(obj, varargin)
% -------------------------------------------------------------------------
% Matlab - R2018b 
% -------------------------------------------------------------------------
%                           Informaci?n Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Componente    : Modelaci?n Hidrologica
% Organizaci?n  : The Nature Conservancy - TNC
% Fecha         : 01- July - 2019
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los t?rminos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener.Para mayor informaci?n revisar 
% http://www.gnu.org/licenses/.
%
% -------------------------------------------------------------------------
% Proyecto
%--------------------------------------------------------------------------
% Consultor?a t?cnica para el an?lisis de la cuenca alta y propuesta de 
% medidas de conservaci?n que contribuyan a la resiliencia de la cuenca del
% r?o Juan D?az en ciudad de Panam? para la mitigaci?n del riesgo por 
% inundaci?n
%
% -------------------------------------------------------------------------
% Descripci?n del Codigo
% -------------------------------------------------------------------------
% Este c?digo permite descargar la informaci?n de precipitaci?n, temperatura 
% m?nima y m?xima a resoluci?n diaria de los modelos meteorol?gicos globales 
% que modelan el cambio clim?tico (GCM). En total son 21 GCM de los cuales 
% se descarga la informaci?n, tanto para el hist?rico como para los 
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
% Var: variable, 1 para precipitacion, 0 para las demas

warning off

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
    Maxdist = varargin{2};
else
    Maxdist = 360;
end

% moving average of order 
if nargin > 3
    m = floor(varargin{3});
else
    m = 10;
end

%% Create Folder
mkdir(fullfile(obj.PathProject,'RESULTS','Semivariogram_Temporal'))
mkdir(fullfile(obj.PathProject,'FIGURES','Semivariogram_Temporal'))

Scale = zeros(length(PoPo),100);

for ii = 1:length(PoPo)  
    try
        id          = find(~isnan(obj.Data(:,PoPo(ii))));
        Data        = obj.Data(id(1):id(end),PoPo(ii));   
        Date        = obj.Date(id(1):id(end));
        
        %% Clear NaN
        id      = ~isnan(Data);
        Data    = Data(id);
        Date    = datenum(Date(id));        
        Data(Data == 0) = 0.1;

        %% Log
        Data = log(Data);            
        
        %% Average Moving        
        w = ((2*m) + 1);
        n = length(Data);

        Results = NaN(n-w+1,1);
        for i = 1:length(Data)
            PoInit  = i-m;
            PoEnd   = i+m;
            if PoInit < 1
                PoInit  = i;
                PoEnd   = 2*m + i - 1; 
            elseif PoEnd > length(Data)
                PoInit  = i - 2*m + 1 ;
                PoEnd   = i;
            end
            Results(i) = mean(Data(PoInit:PoEnd),'omitnan');
        end
        
        Data = Data - Results;
        
        %% Tranformation Series
        % Centralizamos
        Data = Data - mean(Data, 'omitnan');
        % Estandarizamos
        Data = Data./std(Data, 'omitnan');

        %% Remove   
        v = variogram([((Date*0) + 1), Date],Data,'plotit',false, 'nrbins',1000,'maxdist',Maxdist);
        
        [~,vstruct] = variogramfit(v.distance,v.val,[],[],[],'model','exponential','plotit',false);
        
        %% Scale 
        d = (1 - (1/exp(1)))*var(Data,'omitnan');
        Scale(ii) = interp1([0; v.val(1:10)],[0; v.distance(1:10)], d);

        %% Plot
        if obj.StatusPlot
            Fig     = figure('color',[1 1 1],'Visible','off');
            T       = [10, 8];
            set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
            [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter')    
            
            plot( [0.1; vstruct.h], [0.1; vstruct.gammahat],'Color',[0.6 0.6 0.6],'LineWidth',2)
            hold on 
            scatter(v.distance,v.val,25,obj.ColorsF('carmine'));
            set(gca, 'YScale','log','XScale','log')
            ylim([0.001 5])
            xlim([0.1 10000])
            xlabel('\bf Time Lag (Days)','Interpreter','latex');
            ylabel('\bf ${\gamma}$','Interpreter','latex');
            title('(Semi-)Variogram','Interpreter','latex');
            
            
            set(gca, 'TickLabelInterpreter','latex', 'FontWeight','bold','Color',...
                'none', 'box','off','FontSize',18, 'linewidth',2) 
            set(gca, 'XTickLabel',{'0.1','1','10','100','1000'},'XTick',[0.1 1 10 100 1000])
            set(gca, 'YTickLabel',{'0.001','0.01','0.1','1'},'YTick',[0.001 0.01 0.1 1])
            
            %% Save
            saveas(Fig, fullfile(obj.PathProject,'FIGURES','Semivariogram_Temporal',[num2str(obj.Code(PoPo(ii))),'.jpg']))
            close(Fig)
        end

        %% Save Data
        NameFolfer  = fullfile(obj.PathProject,'RESULTS','Semivariogram_Temporal');
        NameFile    = fullfile(NameFolfer,[num2str(obj.Code(PoPo(ii))),'.csv']);
        ID_File     = fopen(NameFile,'w');
        fprintf(ID_File,'%s\n','Lag,Variancia\n');

        fprintf(ID_File, '%f,%f\n',[v.distance v.val]');
        fclose(ID_File);
        
        disp(['Semivariogram ok for Gauges ->',num2str(obj.Code(PoPo(ii)))])
    catch
        disp(['Error in Gauges ->',num2str(obj.Code(PoPo(ii)))])
    end
    
end

Code = obj.Code(PoPo);
Code = reshape(Code,length(Code),1);

%% Save Data
NameFile    = fullfile(obj.PathProject,'RESULTS','Semivariogram_Temporal','Electronic_Scale.csv');
ID_File     = fopen(NameFile,'w');

fprintf(ID_File,'%s\n','Code,Scale');
fprintf(ID_File, '%d,%f\n',[Code, Scale]');
fclose(ID_File);

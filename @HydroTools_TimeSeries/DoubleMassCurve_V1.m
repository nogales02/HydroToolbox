function DoubleMassCurve(obj, varargin)
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

if nargin > 2
    NameLabel = varargin{2};
else
    NameLabel = [];
end

if isempty(NameLabel)
    NameLabel = '\bf Lluvia Acumulada(mm)';
end

%% Create Folder
mkdir(fullfile(obj.PathProject,'FIGURES','MassCurve'))


rPearson = zeros(length(PoPo), 1);
for ii = 1:length(PoPo)
    try
        %% Input Data
        Date = obj.Date;
        Data = obj.Data(:,PoPo(ii));

        %% Accum
        IdDate  = find(~isnan(Data));
        Data    = Data(IdDate(1):IdDate(end));
        Date    = Date(IdDate(1):IdDate(end));

        Table_i = table(Date, Data, year(Date), month(Date),'VariableNames',{'Date','Value','Year','Month'});
        P       = table2array(varfun(@sum,Table_i,'GroupingVariables',{'Year','Month'},'InputVariable','Value'));       

        Datec   = datetime(P(:,1), P(:,2), P(:,3));
        Pcm     = cumsum(P(:,4), 'omitnan');

        % Fit Lineal Model
        Params  = polyfit(datenum(Datec),Pcm,1);
        Psim    = polyval(Params,datenum(Datec));
        
        %%
        P       = table2array(varfun(@sum,Table_i,'GroupingVariables',{'Year'},'InputVariable','Value'));
        Datec   = P(:,1);
        Pcm     = cumsum(P(:,3), 'omitnan');

        % Fit Lineal Model
        Params  = polyfit(Datec,Pcm,1);
        Psim    = polyval(Params,Datec);
        
        %% rPearson 
        % Nash(ii) = 1 - ((mean((Pcm - Psim).^2, 'omitnan'))./var(Pcm( isnan(Pcm) == 0)));
        
        % Calcular la correlación de Pearson
        correlacion = corrcoef(Pcm, Psim);
        
        % Extraer el coeficiente de correlación (elemento fuera de la diagonal)
        rPearson(ii) = correlacion(1, 2);

        %% Plot in Spanish
        if obj.StatusPlot
            Fig     = figure('color',[1 1 1]);
            T       = [10, 8];
            set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
            [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off') 

            plot(Datec, Pcm,'Linewidth',2, 'color',obj.ColorsF('carmine'))
            hold on 
            plot(Datec,Psim,'--','Linewidth',1, 'color','black')          
            ylim([min(Pcm) max(Pcm)])

            xlabel('\bf Tiempo','interpreter','latex', 'Fontsize',20)
            ylabel(NameLabel, 'interpreter','latex', 'Fontsize',20)
            le = legend('\bf Mass Curve', '\bf Modelo Lineal ');
            set(le,'interpreter','latex','FontSize',15, 'FontWeight','bold','box','off','color','none', 'Location','northwest')
            set(gca, 'TickLabelInterpreter','latex', 'FontWeight','bold','Color','none', 'box','on','FontSize',18)

            %% Save
%             R2 = rsquare(Pcm, Psim);            
            saveas(Fig, fullfile(obj.PathProject,'FIGURES','MassCurve',[num2str(obj.Code(PoPo(ii))),'.jpg']))
            close(Fig)
        end
        
        disp(['Mass Curves Ok Gauges ->',num2str(obj.Code(PoPo(ii)))])
    catch
        disp(['Mass Curves Error Gauges ->',num2str(obj.Code(PoPo(ii)))])
    end
end

Code = obj.Code(PoPo);
Code = reshape(Code,length(Code),1);

% Save Data
NameFile    = fullfile(obj.PathProject,'RESULTS','Correlation_MassCurves.csv');
ID_File     = fopen(NameFile,'w');

fprintf(ID_File,'%s\n','Code,r-Pearson');
fprintf(ID_File, '%d,%0.3f\n',[Code, rPearson]');
fclose(ID_File);

end

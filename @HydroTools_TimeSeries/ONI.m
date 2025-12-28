function ONI(obj, varargin)
% -------------------------------------------------------------------------
% Matlab - R2018b 
% -------------------------------------------------------------------------
%                           Informaciï¿½n Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Componente    : Modelaciï¿½n Hidrologica
% Organizaciï¿½n  : The Nature Conservancy - TNC
% Fecha         : 01- July - 2019
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los tï¿½rminos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener.Para mayor informaciï¿½n revisar 
% http://www.gnu.org/licenses/.
%
% -------------------------------------------------------------------------
% Proyecto
%--------------------------------------------------------------------------
% Consultorï¿½a tï¿½cnica para el anï¿½lisis de la cuenca alta y propuesta de 
% medidas de conservaciï¿½n que contribuyan a la resiliencia de la cuenca del
% rï¿½o Juan Dï¿½az en ciudad de Panamï¿½ para la mitigaciï¿½n del riesgo por 
% inundaciï¿½n
%
% -------------------------------------------------------------------------
% Descripciï¿½n del Codigo
% -------------------------------------------------------------------------
% Este cï¿½digo permite descargar la informaciï¿½n de precipitaciï¿½n, temperatura 
% mï¿½nima y mï¿½xima a resoluciï¿½n diaria de los modelos meteorolï¿½gicos globales 
% que modelan el cambio climï¿½tico (GCM). En total son 21 GCM de los cuales 
% se descarga la informaciï¿½n, tanto para el histï¿½rico como para los 
% escenarios rcp45 y rcp85 
%
% -------------------------------------------------------------------------
% Input Data
% -------------------------------------------------------------------------
% 
% -------------------------------------------------------------------------
% Output Data
% -------------------------------------------------------------------------

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
    NameLabel = '\bf \''Indice Oce\''anico El Ni\~no (ONI)';
end

%% Create Folder
mkdir(fullfile(obj.PathProject,'FIGURES','ONI'))

Nash = zeros(length(PoPo), 1);
for ii = 1:length(PoPo)
    try
        %% Input Data
        Date = obj.Date;
        Data = obj.Data(:,PoPo(ii));

        %% Accum
        IdDate  = find(~isnan(Data));
        Data    = Data(IdDate(1):IdDate(end));
        Date    = Date(IdDate(1):IdDate(end));                

        %% Calculo de promedio movil
        ONI = zeros(size(Data));
        k   = 1;
        kk  = 0;
        YY  = year(Date(1));
        for j = 1:length(Date)-1
            
            if kk == 4
                YY = year(Date(j));
            end
            
            %% Calculo de anomlia
            dt = (datetime(YY-29,1,1):calmonths:datetime(YY,12,1))';
            [posi,~] = ismember(Date, dt);

            M = month(Date);
            Data_M = Data*0;
            for jj = 1:12
                % Estimación de media
                id = (M == jj);
                Data_M(M == jj) = mean(Data(logical(id.*posi)),'omitnan');           
            end

            % Calculo de anomalia
            Ano = Data - Data_M;
                    
            if j == 1
                ONI(k) = mean(Ano(1:j+1));
            else
                ONI(k) = mean(Ano(j-1:j+1));
            end
            k = k + 1;
            kk = year(Date(j)) - YY;
            
        end
        
        %% Save
        obj.Data(IdDate(1):IdDate(end),PoPo(ii)) = ONI;
        
        %% Plot in Spanish
        NINO = ONI; NINO(ONI<=0.5) = NaN; NINO(isnan(NINO)) = 0.5;
        NINA = ONI; NINA(ONI>=-0.5) = NaN; NINA(isnan(NINA)) = -0.5;

        if obj.StatusPlot
            
            Fig     = figure('color',[1 1 1]);
            T       = [15, 8];
            set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
            [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off')         
            hold on
               
            
            Ax1 = area(Date, NINO, 0.5,  'FaceColor','red','FaceAlpha',0.5,'LineStyle','none');
            Ax2 = area(Date, NINA, -0.5, 'FaceColor','blue','FaceAlpha',0.5,'LineStyle','none');
            Ax3 = area(Date, ONI*0 + 0.5, 0.0,  'FaceColor','white','LineStyle','none');
            Ax4 = area(Date, ONI*0 - 0.5, 0.0,  'FaceColor','white','LineStyle','none');
            Ax5 = plot(Date, ONI,'Linewidth',1, 'color',[0.5 0.5 0.5]);
            Ax6 = plot(Date, ONI*0,'Linewidth',1, 'color','k');
            
            xlabel('\bf Tiempo','Interpreter','latex','FontSize',20)
            ylabel(NameLabel,'Interpreter','latex','FontSize',20)
    
            legend([Ax1 Ax2],{'\bf Ni\~no','\bf Ni\~na'},'Location','southwest','NumColumns',2,'Interpreter','latex','FontSize',10);
            xlim([min(Date) - 12, max(Date) + 12])     
            box off

            set(gca, 'TickLabelInterpreter','latex', 'FontWeight','bold','Color','none', 'box','on','FontSize',14)

            %% Save
            saveas(Fig, fullfile(obj.PathProject,'FIGURES','ONI',['ONI_',obj.Name{PoPo(ii)},'.jpg']))
            close(Fig)
        end
        
        disp(['ONI Ok Gauges ->',num2str(obj.Code(PoPo(ii)))])
    catch
        disp(['ONI Error Gauges ->',num2str(obj.Code(PoPo(ii)))])
    end
end

end

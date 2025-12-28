function Index_SPI(obj, varargin)
% -------------------------------------------------------------------------
% Matlab - R2023b 
% -------------------------------------------------------------------------
%                           Información Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Fecha         : abril-2024
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los términos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener. Para mayor información revisar 
% http://www.gnu.org/licenses/
%
% -------------------------------------------------------------------------
% Descripción del Codigo
% -------------------------------------------------------------------------
% Esta función calcula el SPI utilizando las series de precipitación.
% 
% -------------------------------------------------------------------------
% Input Data
% -------------------------------------------------------------------------
% obj
%   .Data   [mm]        Precipitación Mensual
%   .Date   [datetime]  Fecha en meses
%
% -------------------------------------------------------------------------
% Output Data
% -------------------------------------------------------------------------
% SPI - Inidice estandarizado de precipitación

% -------------------------------------------------------------------------
% Validación parámetros de entrada opcionales
% -------------------------------------------------------------------------
% Reglas de verificación
ip = inputParser;    
% Códigos de estaciones a analizar
addParameter(ip,'CodeGauges',obj.Code,@ismatrix)
% Indicador SPI o SDI
List_Index = {'SPI','SDI','RDI'};
addParameter(ip,'Index',1,@(x) any(validatestring(x,List_Index)))
% Valor de la ventana temporal de análisis [1, 2, 3, 6 12]
addParameter(ip,'SizeStep',1,@double)

% Check de datos opcionales
parse(ip,varargin{:})
% Codigos especificos
Code_PoPo   = ip.Results.CodeGauges;
% Valor de la ventana temporal de análisis
SizeStep    = ip.Results.SizeStep;

% Selección de estacional
switch SizeStep
    case 1
        nseas = 12;
    case 2
        nseas = 6;
    case 3
        nseas = 4;
    case 6
        nseas = 2;
    case 12
        nseas = 1;
end

List_NameIndex = {'Standardized Precipitation Index (SPI)',...
                  'Streamflow Drought Index (SDI)',...
                  'Reconnaissance Drought Index (RDI)'};

if ischar(ip.Results.Index)
    [~,Posi]    = ismember(ip.Results.Index, List_Index);
    Index       = List_Index{Posi};
    NameIndex   = List_NameIndex{Posi};
else
    Index       = List_Index{ip.Results.Index};
    NameIndex   = List_NameIndex{ip.Results.Index};
end

% Seleccionar solo códigos que estan en los datos de entrada
[~, PoPo] = ismember(Code_PoPo, obj.Code);
% PoPo = PoPo(1:3);

% Create Folder
FigPathIndex    = fullfile(obj.PathProject,'FIGURES',Index,[Index,'_Step-',num2str(SizeStep)]);
FigPathPDF      = fullfile(obj.PathProject,'FIGURES',Index,['PDF_',Index,'_Step-',num2str(SizeStep)]);
PathIndex       = fullfile(obj.PathProject,'RESULTS','Index');
mkdir(FigPathIndex)
mkdir(FigPathPDF)
mkdir(PathIndex)

% -------------------------------------------------------------------------
% Almacenadores de compilados
% -------------------------------------------------------------------------
Total_SPI       = obj.copy(); Total_SPI.Data   = Total_SPI.Data*NaN;
Total_Class     = obj.copy(); Total_Class.Data = Total_Class.Data*NaN;
BestPDF         = cell(nseas,size(obj.Data,2));
ErrorPDF        = zeros(nseas,size(obj.Data,2));
for ii = 1:length(PoPo)
    FigPathPDFGauges = fullfile(FigPathPDF,obj.Name{PoPo(ii)});
    mkdir(FigPathPDFGauges)
    try
        % -----------------------------------------------------------------
        % Selección de periodo con datos para la estación ii
        % -----------------------------------------------------------------
        id          = find( ~isnan(obj.Data(:,PoPo(ii))) );   
        % Datos
        RawData     = obj.Data(id(1):id(end),PoPo(ii));
        % Fechas
        RawDate     = obj.Date(id(1):id(end));
        
        % -----------------------------------------------------------------
        % Agregar datos a la ventana temporal indicada
        % -----------------------------------------------------------------
        % Meses
        M       = month(RawDate);
        % Date1   = [(1:M(1)-1)'; M; (M(end)+1:12)'];
        Data    = [(1:M(1)-1)'*NaN; RawData; (M(end)+1:12)'*NaN];
        % Acumular datos
        if SizeStep ~= 1
            Data    = sum(reshape(Data,SizeStep,[]),'omitnan')';
        end
        % Fechas nuevas
        Date    = datetime(year(RawDate(1)),1,1):calmonths(SizeStep):datetime(year(RawDate(end)),12,1);
        % filtrar NaN
        id      = find(~isnan(Data));
        Data    = Data(id(1):id(end));
        Date    = Date(id(1):id(end))';

        % -----------------------------------------------------------------
        % Cálculo del SPI
        % -----------------------------------------------------------------
        % SPI
        % XS = (Data - mean(Data,'omitmissing'))./std(Data,'omitmissing');
        SPI     = Data*NaN; 
        for is = 1:nseas
            % Selección de datos de acuerdo con la ventana temporal
            tind        = is:nseas:length(Data);
            Xn          = Data(tind);
            % Encontrar datos que son cero
            [zeroa]     = find(Xn==0);
            % Selección de datos que no son ceros
            Xn_nozero   = Xn; Xn_nozero(zeroa)=[];
            % Estimación de q para corrección
            q           = length(zeroa)/length(Xn);
            % Ajustar función densidad de probabilidad
            [NamePDF,Error,~,Fig] = obj.Fit_PDF(Xn_nozero, obj.StatusPlot);
            % Estimación de distribución teoría con mejor ajuste pdf
            test_cdf    = fitdist(Xn_nozero,NamePDF);
            % Evalua los valores con la mejor función de probabildiad
            BestCDF     = q+(1-q)*cdf(test_cdf, Xn);
            % Se normalizan los datos a una función normar
            SPI(tind)   = norminv(BestCDF);
            % guardar mejor pdf
            BestPDF{is,ii}  = NamePDF;
            ErrorPDF(is,ii) = Error;
            % Guardar grafica
            if obj.StatusPlot
                saveas(Fig, fullfile(FigPathPDFGauges,[Index,'_',obj.Name{PoPo(ii)},'_Step_',num2str(is),'.jpg']))
            end
            % Cerrar y eliminar
            close(Fig); delete(Fig)
        end

        % Guardar compilado
        Total_SPI.Data(id(1):id(end),PoPo(ii)) = SPI;
    
        % -----------------------------------------------------------------
        % Clasificación de sequias
        % -----------------------------------------------------------------
        % La clasificación se realiza de acuerdo con los rangos presentados
        % en la Tabla 1. del paper: https://doi.org/10.3390/w15020255
        %________________________________________________
        % ID | Clasifiación      |        Rango         |
        % 1  | Período Húmedo    | SPI > 0              |
        % 2  | Sequía Leve       | 0 > SPI >= -0.99     |
        % 3  | Sequía Moderada   | -0.99 > SPI >= -1.49 |
        % 4  | Sequía Severa     | -1.49 > SPI >= -1.99 |
        % 5  | Sequía Extrema    | -2.0 > SPI           |
        %-----------------------------------------------|
    
        % Clasificación
        DroughtClass = zeros(size(Data));
        % Período Húmedo    | SPI > 0
        DroughtClass(SPI >= 0)                      = 1;
        % Sequía Leve       | 0 > SPI >= -0.99}
        DroughtClass((0 > SPI)&(SPI >= -0.99))      = 2;
        % Sequía Moderada   | -0.99 > SPI >= -1.49
        DroughtClass((-0.99 > SPI)&(SPI >= -1.49))  = 3;
        % Sequía Severa     | -1.49 > SPI >= -1.99
        DroughtClass((-1.49 > SPI)&(SPI >= -1.99))  = 4;
        % Sequía Extrema    | -2.0 > SPI
        DroughtClass(SPI < -1.99)                   = 5;
    
        % Guardar compilado
        Total_Class.Data(id(1):id(end),PoPo(ii)) = DroughtClass;
    
        if obj.StatusPlot
                
            % Configurar gráfica
            Fig     = figure('color',[1 1 1]);
            T       = [15, 8];
            set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
            [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off')         
            hold on
            
            % Plot de categorias de SPI
            Ax1 = bar(Date, SPI.*(DroughtClass==1), 'FaceColor',[82 140 86]/255,'FaceAlpha',0.8,'EdgeColor',[82 140 86]/255,'ShowBaseLine','off','BarWidth', 1);
            Ax2 = bar(Date, SPI.*(DroughtClass==2), 'FaceColor',[255 230 153]/255,'FaceAlpha',0.8,'EdgeColor',[255 230 153]/255,'ShowBaseLine','off','BarWidth', 1);
            Ax3 = bar(Date, SPI.*(DroughtClass==3), 'FaceColor',[243 221 221]/255,'FaceAlpha',0.85,'EdgeColor',[243 221 221]/255,'ShowBaseLine','off','BarWidth', 1);
            Ax4 = bar(Date, SPI.*(DroughtClass==4), 'FaceColor',[217 134 134]/255,'FaceAlpha',0.95,'EdgeColor',[217 134 134]/255,'ShowBaseLine','off','BarWidth', 1);
            Ax5 = bar(Date, SPI.*(DroughtClass==5), 'FaceColor',[180 82 82]/255,'FaceAlpha',0.99,'EdgeColor',[180 82 82]/255,'ShowBaseLine','off','BarWidth', 1);
            
            % Etiqueta del eje X
            xlabel('\bf Tiempo','Interpreter','latex','FontSize',20)
    
            % Etiqueta del eje Y
            ylabel(['\bf ',NameIndex],'Interpreter','latex','FontSize',20)
            
            % Leyenda
            legend([Ax1 Ax2 Ax3 Ax4 Ax5],{'\bf Periodo H\''umedo','\bf Sequ\''ia Leve','\bf Sequ\''ia Moderada','\bf Sequ\''ia Severa','\bf Sequ\''ia Extrema'},...
                   'Location','northwest','NumColumns',5,'Interpreter','latex','FontSize',10);
    
            % Limitar rango a la fecha
            xlim([min(Date) - 12, max(Date) + 12])     
            box off
            
            % Configuración de ejes
            set(gca, 'TickLabelInterpreter','latex', 'FontWeight','bold','Color','none', 'box','on','FontSize',14)
    
            % Guardar grafica
            saveas(Fig, fullfile(FigPathIndex,[Index,'_',obj.Name{PoPo(ii)},'.jpg']))
    
            % Cerrar y eliminar
            close(Fig); delete(Fig)
        end
        
        % Mensaje de ejecución
        fprintf('%s Processing | Gauge: %d | Status: Correct | Progress (%%): %.2f%%\n',Index,obj.Code(PoPo(ii)),(ii/length(PoPo))*100);

    catch
        fprintf('%s Processing | Gauge: %d | Status: Error | Progress (%%): %.2f%%\n',Index,obj.Code(PoPo(ii)),(ii/length(PoPo))*100);
    end
end

% -------------------------------------------------------------------------
% Guardar datos
% -------------------------------------------------------------------------
% Variable
Total_SPI.Var       = NameIndex;
% Unidad
Total_SPI.Unit      = 'Adimensional';
% Fuente
Total_SPI.Source    = 'Calculado';
% Guardar
Total_SPI.WriteData(fullfile(PathIndex,[Index,'_Step-',num2str(SizeStep),'.csv']));

% Variable
Total_Class.Var     = ['Drought Classification - ',NameIndex];
% Unidad
Total_Class.Unit    = '1-Período Húmedo | 2-Sequía Leve | 3-Sequía Moderada | 4-Sequía Severa | 5-Sequía Extrema';
% Fuente
Total_Class.Source  = 'Calculado';
% Guardar
Total_Class.WriteData(fullfile(PathIndex,[Index,'_Step-',num2str(SizeStep),'_DroughtClass.csv']));

% Mejor PDF
ID_File = fopen(fullfile(PathIndex,[Index,'_Step-',num2str(SizeStep),'_BestPDF.csv']),'w');
fprintf(ID_File,['%f',repmat(',%f',1,numel(PoPo)-1),'\n'],obj.Code(PoPo));
for i = 1:nseas
    fprintf(ID_File,'%s',BestPDF{i,1});
    for j = 2:numel(obj.Code)
        fprintf(ID_File,',%s',BestPDF{i,j});
    end
    fprintf(ID_File,'\n');
end
fclose(ID_File);
    
% Mejor PDF error
ID_File = fopen(fullfile(PathIndex,[Index,'_Step-',num2str(SizeStep),'_BestPDF_FittingError.csv']),'w');
fprintf(ID_File,'Code');
for i = 1:12
    fprintf(ID_File,[',RMSE_Step_',num2str(i)]);
end
fprintf(ID_File,'\n');
fprintf(ID_File,['%d',repmat(',%f',1,12),'\n'],[obj.Code(PoPo) ErrorPDF']');
fclose(ID_File);
function InterpolationField(obj, Method, PathDEM, varargin)         
% -------------------------------------------------------------------------
% Matlab - R2019b 
% -------------------------------------------------------------------------
%                           Información basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Fecha         : Noviembre-2021
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los términos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener.Para mayor información revisar 
% http://www.gnu.org/licenses/.
%
% -------------------------------------------------------------------------
% Descripción del código
% -------------------------------------------------------------------------
% Este código permite construir campos por las metodologías de Kriging 
% ordinario, IDW y regresiones lineales múltiples (por elevación). La salida 
% se expresa en archivos rasters. Sin embargo, dado que Matlab no permite 
% asignar valores nulos, se utiliza un código en Python para realizar esta 
% asignación. En este orden de ideas, es necesario configurar un ambiente 
% Python de la siguiente manera:
%       conda create --name Matlab python=3.7
%       conda activate Matlab
%       conda install -c conda-forge gdal=2.4.4
%       conda install -c conda-forge rasterio
%
% -------------------------------------------------------------------------
% Entrada
%--------------------------------------------------------------------------
% Method        =   Metodológica de interpolación. Lo valores validos son
%                   - 'Kriging'
%                   - 'IDW'
%                   - 'Lineal'
% PathDEM       =   Ruta del archivo raster que se usara como base para 
%                   realizar la interpolación. Generalmente se usa el modelo 
%                   de elevación digital para poder realizar la interpolación 
%                   por el método de regresión lineal. Este raster debe estar 
%                   en coordenadas planas y deben ser las mismas que se estan 
%                   utilizando en las series de tiempo
% Suffix        =   (Opcional) Sufijo para la salida de los rasters. Por
%                   defecto se asigna sin sufijo
% DataType      =   (Opcional) Tipo de dato para la salida de los rasters.
%                   Por defecto se asigna un tipo de datos 'int16'; sin
%                   embargo, se aceptan las siguintes opciones:
%                   - 'int8'
%                   - 'int16'
%                   - 'int32'
%                   - 'int64'
%                   - 'single'
%                   - 'double'
%                   - 'int8'
% ThresholdDist =   (opcional) Es la distancia en metros para el buffer de 
%                   interpolación. Es decir, es la distancia máxima a la cual 
%                   el algoritmo va tomar los puntos para interpolar. Por
%                   defecto se esta tomando una distancia de 50000 m.
%
%--------------------------------------------------------------------------
% Salidas
%--------------------------------------------------------------------------
%


%% Parametros de intrada del código
% Sufijo para guardar los rasters generados
if nargin > 3
    Suffix = varargin{1};
else
    Suffix = '';
end

% Tipo de dato de salida del Raster
if nargin > 4
    DataType = varargin{2};
else
    DataType = 'int16';
end

% Umbral de distancia para interpolación
if nargin > 5
    ThresholdDist = varargin{3};
else
    ThresholdDist = 50000;
end

%% Crear folder de proyecto
mkdir( fullfile(obj.PathProject) )

%% Crear Script de python para corrección de valores nulos
if isunix
    ScriptPython = @(PathR) ['import rasterio',newline,...
            'Path_Raster = r"',PathR,'"',newline,...
            'Tmp     = rasterio.open(Path_Raster)',newline,...
            'Data    = Tmp.read(1)',newline,...
            'height  = Tmp.shape[0]',newline,...
            'width   = Tmp.shape[1]',newline,...
            'crs     = Tmp.crs',newline,...
            'transform = Tmp.transform',newline,...
            'Tmp.close()',newline,...
            'with rasterio.open(',newline,...
            '    Path_Raster,"w",',newline,...
            '    driver="GTiff",',newline,...
            '    height=height,',newline,...
            '    width=width,',newline,...
            '    count=1,',newline,...
            '    dtype=Data.dtype,',newline,...
            '    crs=crs,',newline,...
            '    transform=transform,',newline,...
            '    nodata= -99',newline,...
            ') as dst:',newline,...
            '    dst.write(Data, 1)'];
else
    ScriptPython = @(PathR) ['import rasterio',newline,...
            'Path_Raster = r"',PathR,'"',newline,...
            'Tmp     = rasterio.open(Path_Raster)',newline,...
            'Data    = Tmp.read(1)',newline,...
            'height  = Tmp.shape[0]',newline,...
            'width   = Tmp.shape[1]',newline,...
            'crs     = Tmp.crs',newline,...
            'transform = Tmp.transform',newline,...
            'Tmp.close()',newline,...
            'with rasterio.open(',newline,...
            '    Path_Raster,"w",',newline,...
            '    driver="GTiff",',newline,...
            '    height=height,',newline,...
            '    width=width,',newline,...
            '    count=1,',newline,...
            '    dtype=Data.dtype,',newline,...
            '    crs=crs,',newline,...
            '    transform=transform,',newline,...
            '    nodata= -99',newline,...
            ') as dst:',newline,...
            '    dst.write(Data, 1)'];
end
    
%% Lectura de DEM
DEM     = GRIDobj(PathDEM);
DEM.Z(DEM.Z < -99) = NaN;
% Lectura de sistema de coordinadas 
Tmp     = DEM.georef.SpatialRef;
% Creación de vectores de X y Y
XDEM    = linspace(Tmp.XWorldLimits(1), Tmp.XWorldLimits(2),DEM.size(2))';
YDEM    = linspace(Tmp.YWorldLimits(2), Tmp.YWorldLimits(1),DEM.size(1))';
% Creación de grilla de coordenadas
[XDEM, YDEM] = meshgrid(XDEM, YDEM);
% Reformado de matrices de coordenadas a vectores
XDEM    = reshape(XDEM, [],1);
YDEM    = reshape(YDEM, [],1);

%% Read Info Gauges 
XGauges = reshape(obj.X,[],1);
YGauges = reshape(obj.Y,[],1);

%% Creación de matriz de resultados
Results = DEM;

%% Interpolación por metodo - Kriging
if strcmp(Method, 'Kriging')    
    for i = 1:length(obj.Date)
        Value = reshape(obj.Data(i,:),[],1);
        if sum(~isnan(Value)) > 2
            % Selección de los datos que no tienen valor NaN
            id          = ~isnan(obj.Data(i,:));
            % Semivarigrama
            vstruct     = SemivariogramSetting(XGauges(id), YGauges(id), Value(id));
            % Tamaño de memoria disponible para creear matrix
            Info        = memory;
            MaxMemory   = Info.MemAvailableAllArrays;
            % Tamaño maximo de matrix a crear usando el 60% de la memoria
            % disponible
            MaxMatrix   = floor((MaxMemory/8)*0.05);
            n           = (length(XGauges(id))*length(XDEM));
            if  n > MaxMatrix
                nn = ceil(n/MaxMatrix);
                PosiPixel = round(linspace(0,length(XDEM),nn));
                PosiPixel([1 end]) = [0 length(XDEM)];
                for  j = 1:length(PosiPixel)-1
                    Results.Z(PosiPixel(j)+1:PosiPixel(j+1)) =...
                                PrecipitationFields(XGauges(id), YGauges(id),...
                                Value(id), XDEM(PosiPixel(j)+1:PosiPixel(j+1)),...
                                YDEM(PosiPixel(j)+1:PosiPixel(j+1)),...
                                vstruct);
                    disp( ['Proceso ',num2str((j/(length(PosiPixel)-1))*100,'%0.2f'),'% | Fecha: ', datestr(obj.Date(i),'mm')] )
                end
            else                
                Results.Z   = reshape(PrecipitationFields(XGauges(id), YGauges(id),...
                    Value(id), XDEM, YDEM, vstruct),DEM.size(1), DEM.size(2));
            end
            
            %% Convertir al tipo de dato para guardar
            if strcmp(DataType,'int8')
                Results.Z   = int8(round(Results.Z));
                Results.Z(isnan(DEM.Z)) = -99;
            elseif strcmp(DataType,'int16')
                Results.Z   = int16(round(Results.Z));
                Results.Z(isnan(DEM.Z)) = -99;
            elseif strcmp(DataType,'int32')
                Results.Z   = int32(round(Results.Z));
                Results.Z(isnan(DEM.Z)) = -99;
            elseif strcmp(DataType,'int64')
                Results.Z   = int64(round(Results.Z));
                Results.Z(isnan(DEM.Z)) = -99;
            elseif strcmp(DataType,'single')
                Results.Z   = single(round(Results.Z,2));
                Results.Z(isnan(DEM.Z)) = -99;
            elseif strcmp(DataType,'double')
                Results.Z   = double(round(Results.Z,2));
                Results.Z(isnan(DEM.Z)) = -99;
            end
            
            %% Guardar raster
            Results.GRIDobj2geotiff(fullfile(obj.PathProject,[datestr(obj.Date(i),'mm'),'_',Suffix,'.tif']))            
            
            NameFile = fullfile(obj.PathProject,[datestr(obj.Date(i),'mm'),'_',Suffix,'.tif']);
            Results.GRIDobj2geotiff(NameFile) 
            NameFile = strrep(NameFile,'\','\\');
            NewScript = ScriptPython(NameFile);
            
            pause(1)
            
            %% Save New BasinFile    
            NameFile = fullfile(obj.PathProject,'Script_Python.py');
            ID_File = fopen(NameFile, 'w');
            fprintf(ID_File,'%s', NewScript);
            fclose(ID_File);                        
            
            system(['conda activate Matlab && python "',fullfile(obj.PathProject,'Script_Python.py"')]);
            
            disp([num2str((i/length(obj.Date))*100,'%.2f'),'% -> Ok Interpolation Kriging']) 
            disp('-------------------------------------')
        else
            disp([num2str((i/length(obj.Date))*100,'%.2f'),'% -> Error Interpolation Kriging'])  
        end
    end

%% Interpolación por metodo - IDW
elseif strcmp(Method, 'IDW')   
    for i = 1:length(obj.Date)
        % Check que exitan mas de dos puntos para realizar la interpolación
        if sum(~isnan(obj.Data(i,:))) > 2
            % Selección de los datos que no tienen valor NaN
            id          = ~isnan(obj.Data(i,:));
            % Tamaño de memoria disponible para creear matrix
            Info        = memory;
            MaxMemory   = Info.MemAvailableAllArrays;
            % Tamaño maximo de matrix a crear usando el 60% de la memoria
            % disponible
            MaxMatrix   = floor((MaxMemory/8)*0.05);
            n           = (length(XGauges(id))*length(XDEM));
            if  n > MaxMatrix
                nn = ceil(n/MaxMatrix);
                PosiPixel = round(linspace(0,length(XDEM),nn));
                PosiPixel([1 end]) = [0 length(XDEM)];
                for  j = 1:length(PosiPixel)-1
                    % Creación de matriz de distancias 
                    Dist    = sqrt( bsxfun(@minus,XDEM(PosiPixel(j)+1:PosiPixel(j+1)), XGauges(id)').^2 +...
                                    bsxfun(@minus,YDEM(PosiPixel(j)+1:PosiPixel(j+1)), YGauges(id)').^2 );
                    % Estimation Values 
                    Beta    = 2;
                    dis     = 1 ./ (Dist .^ Beta);
                    dis(Dist > ThresholdDist) = 0; 
                    dis(isinf(dis)) = 0;    
                    Results.Z(PosiPixel(j)+1:PosiPixel(j+1)) = sum(bsxfun(@times, obj.Data(i,id),dis),2)./sum(dis,2);
                    
                    disp( ['Proceso ',num2str((j/(length(PosiPixel)-1))*100,'%0.2f'),'% | Fecha: ', datestr(obj.Date(i),'mm')] )
                end                
            else
                % Creación de matriz de distancias 
                Dist    = sqrt( bsxfun(@minus,XDEM, XGauges(id)').^2 +...
                                bsxfun(@minus,YDEM, YGauges(id)').^2 );
                % Estimation Values 
                Beta    = 2;
                dis     = 1 ./ (Dist .^ Beta);
                dis(Dist > ThresholdDist) = 0;
                dis(isinf(dis)) = 0;
                Results.Z(1:end) = sum(bsxfun(@times, obj.Data(i,id),dis),2)./sum(dis,2);
            end
            
            %% Convertir al tipo de dato para guardar
            if strcmp(DataType,'int8')
                Results.Z   = int8(round(Results.Z));
                Results.Z(isnan(DEM.Z)) = -99;
            elseif strcmp(DataType,'int16')
                Results.Z   = int16(round(Results.Z));
            elseif strcmp(DataType,'int32')
                Results.Z   = int32(round(Results.Z));
            elseif strcmp(DataType,'int64')
                Results.Z   = int64(round(Results.Z));
            elseif strcmp(DataType,'single')
                Results.Z   = single(round(Results.Z,2));
            elseif strcmp(DataType,'double')
                Results.Z   = double(round(Results.Z,2));
            end
            Results.Z(isnan(DEM.Z)) = -99;
            
            %% Guardar raster
            Results.GRIDobj2geotiff(fullfile(obj.PathProject,[datestr(obj.Date(i),'mm'),'_',Suffix,'.tif']))            
            
            NameFile = fullfile(obj.PathProject,[datestr(obj.Date(i),'mm'),'_',Suffix,'.tif']);
            % Results.GRIDobj2geotiff(NameFile) 
            NameFile = strrep(NameFile,'\','\\');
            NewScript = ScriptPython(NameFile);            
            
            pause(1)

            %% Save New BasinFile    
            NameFile = fullfile(obj.PathProject,'Script_Python.py');
            ID_File = fopen(NameFile, 'w');
            fprintf(ID_File, NewScript);
            fclose(ID_File);  
            
            system(['conda activate Matlab && python "',fullfile(obj.PathProject,'Script_Python.py"')]);
            
            disp([num2str((i/length(obj.Date))*100,'%.2f'),'% -> Ok Interpolation IDW'])
            disp('-------------------------------------')            
        else
            disp([' Error'])            
        end
    end
    
elseif strcmp(Method, 'Lineal')  
    
    for i = 1:length(obj.Date)
        
        if sum(~isnan(obj.Data(i,:))) > 2
            id = ~isnan(obj.Data(i,:));
        else
            disp(['Date ', datestr(obj.Date(i)),' Error']) 
            continue
        end
        
        %% Setting Parameters Temperature
        ParamT      = TemperatureSetting(obj.Z(id)', obj.Data(i,id)');
        
        %% Plot Figure
        Fig     = figure('color',[1 1 1]);
        T       = [10, 8];
        set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
        [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off')

        FontLabels = 22;
        FontTick   = 15;
        FontLegend = 16;
        
        ZZ = [0, max(obj.Z(id)')];
        plot(ZZ,polyval(ParamT, ZZ),'k','LineWidth',1.5)
        hold on 
        scatter(obj.Z(id)', obj.Data(i,id)', 25,obj.ColorsF('jasper'),'filled', 'MarkerEdgeColor',obj.ColorsF('jazzberry jam'),'LineWidth',2)
        set(gca, 'TickLabelInterpreter','latex','FontSize',FontTick, 'FontWeight','bold', 'linewidth',2)
        xlabel('\bf Elevaci\''on $\bf {(m.s.n.m)}$','interpreter','latex','FontSize',FontLabels, 'FontWeight','bold');
        ylabel('\bf Variable','interpreter','latex','FontSize',FontLabels, 'FontWeight','bold');
        
        NameFile = fullfile(obj.PathProject,['ScatterSetting_',datestr(obj.Date(i),'mm'),'_',Suffix,'.jpg']);
        saveas(Fig,NameFile)
        
        %% Interpolation
        Results.Z   = polyval(ParamT,DEM.Z);     
        
        %% Convertir al tipo de dato para guardar
        if strcmp(DataType,'int8')
            Results.Z   = int8(round(Results.Z));
            Results.Z(isnan(DEM.Z)) = -99;
        elseif strcmp(DataType,'int16')
            Results.Z   = int16(round(Results.Z));
            Results.Z(isnan(DEM.Z)) = -99;
        elseif strcmp(DataType,'int32')
            Results.Z   = int32(round(Results.Z));
            Results.Z(isnan(DEM.Z)) = -99;
        elseif strcmp(DataType,'int64')
            Results.Z   = int64(round(Results.Z));
            Results.Z(isnan(DEM.Z)) = -99;
        elseif strcmp(DataType,'single')
            Results.Z   = single(round(Results.Z,2));
            Results.Z(isnan(DEM.Z)) = -99;
        elseif strcmp(DataType,'double')
            Results.Z   = double(round(Results.Z,2));
            Results.Z(isnan(DEM.Z)) = -99;
        end

        %% Guardar raster
        Results.GRIDobj2geotiff(fullfile(obj.PathProject,[datestr(obj.Date(i),'mm'),'_',Suffix,'.tif']))            

        NameFile = fullfile(obj.PathProject,[datestr(obj.Date(i),'mm'),'_',Suffix,'.tif']);
        Results.GRIDobj2geotiff(NameFile) 
        NameFile = strrep(NameFile,'\','\\');
        NewScript = ScriptPython(NameFile);
        
        pause(1)

        %% Save New BasinFile    
        NameFile = fullfile(obj.PathProject,'Script_Python.py');
        ID_File = fopen(NameFile, 'w');
        fprintf(ID_File, NewScript);
        fclose(ID_File);                        

        system(['conda activate Matlab && python "',fullfile(obj.PathProject,'Script_Python.py"')]);

        disp([num2str((i/length(obj.Date))*100,'%.2f'),'% -> Ok Interpolation Lineal'])
        disp('-------------------------------------')        
    end    
    
end


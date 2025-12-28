function Teleconexiones(obj,ENSO_Index,varargin)
% -------------------------------------------------------------------------
% Matlab - R2019b 
% -------------------------------------------------------------------------
%                           Información Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Componente    : Modelación Hidrologica
% Fecha         : Marzo-2022
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los términos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener.Para mayor información revisar 
% http://www.gnu.org/licenses/.
%
% -------------------------------------------------------------------------
% Descripción del Codigo
% -------------------------------------------------------------------------
% Este código calcula si existen teleconexiones entre los indicadores del 
% ENSO y la variable de análisis
%

warning off

if nargin > 3
    Code_PoPo = varargin{1}; 
else
    Code_PoPo = [];
end

if ~isempty(Code_PoPo)
    [~, PoPo] = ismember(Code_PoPo, obj.Code);
else
    PoPo = 1:length(obj.Code);
end

if nargin > 4
    StaVar = varargin{2};
else
    StaVar = 'Mean';
end

%% Create Folder
mkdir(fullfile(obj.PathProject,'RESULTS','Teleconnections'))
mkdir(fullfile(obj.PathProject,'FIGURES','Teleconnections'))   

%% Agregar datos a nivel mensual
DataMoths = obj.copy();
DataMoths.AggregationData('Monthly',StaVar); 

%% Clip de indicadores ENSO en el periodo de analisis
[id,posi] = ismember(DataMoths.Date,ENSO_Index.Date);   
ENSO_Index.Data = ENSO_Index.Data(posi(id),:); 
ENSO_Index.Date = DataMoths.Date;

%% Normalization de datos de variable
DataVar     = DataMoths.Data';
[fil,npat]  = size(DataVar);    
mii = min(DataVar,[],2); 
maa = max(DataVar,[],2);
ma  = zeros(fil,npat);
mi  = ma;
for w = 1:npat      
    ma(:,w) = maa; 
    mi(:,w) = mii;
end
m = (ma - mi); 
% Entradas
DataVar = (((DataVar - mi) .* ((1 ./ m) .* 6)) - 3)'; 

%% Normalization de indicadores ENSO
ENSOVar     = ENSO_Index.Data';
[fil,npat]  = size(ENSOVar);    
mii = min(ENSOVar,[],2); 
maa = max(ENSOVar,[],2);
ma  = zeros(fil,npat);
mi  = ma;
for w = 1:npat      
    ma(:,w) = maa; 
    mi(:,w) = mii;
end
m = (ma - mi); 
% Entradas
ENSOVar = (((ENSOVar - mi) .* ((1 ./ m) .* 6)) - 3)'; 

for ii = 1:length(PoPo)
    try
        id          = find( ~isnan(DataVar(:,PoPo(ii))) );    
        Data        = DataVar(id(1):id(end),PoPo(ii));   
        Date        = DataMoths.Date(id(1):id(end));

        %% Clip Data ENSO a longitud de estación
        [id,~]      = ismember(ENSO_Index.Date,Date);   
        ENSOVar_i   = ENSOVar(id,:); 

        %% Detectar correlación
        R       = zeros(11,length(ENSOVar_i(1,:)));
        Pvalue  = ones(11,length(ENSOVar_i(1,:)));
        cont    = 1; 
        for j = [-6:-2, 1:6]
            if j < 0
                X   = Data(abs(j):end,:);
                Y   = ENSOVar_i(1:end+j+1,:);
                id  = ~isnan(X); 
            else
                X   = Data(1:end-j+1,:);
                Y   = ENSOVar_i(abs(j):end,:);
                id  = ~isnan(X);             
            end
            [R(cont,:),Pvalue(cont,:)] = corr(X(id,:),Y(id,:));
            cont = cont + 1;
        end
        R       = round(R,2)';
        Pvalue  = round(Pvalue,4)';

        %% Guardar resultados
        NameFile    = fullfile(obj.PathProject, 'RESULTS','Teleconnections',['Coef_Pearson_',num2str(obj.Code(PoPo(ii))),'.csv']);
        ID_File     = fopen(NameFile,'w');
        Tmp = 'Index,Lag -5,Lag -4,Lag -3,Lag -2,Lag -1,Lag 0,Lag 1,Lag 2,Lag 3,Lag 4,Lag 5';
        fprintf(ID_File,'%s\n',Tmp);
        for j = 1:length(R(:,1))
            fprintf(ID_File,'%s',ENSO_Index.Name{j});
            fprintf(ID_File,[repmat(',%f',1,length(R(1,:))),'\n'],R(j,:));
        end
        fclose(ID_File);

        NameFile    = fullfile(obj.PathProject, 'RESULTS','Teleconnections',['Pvalue_',num2str(obj.Code(PoPo(ii))),'.csv']);
        ID_File     = fopen(NameFile,'w');
        fprintf(ID_File,'%s\n',Tmp);
        for j = 1:length(R(:,1))
            fprintf(ID_File,'%s',ENSO_Index.Name{j});
            fprintf(ID_File,[repmat(',%f',1,length(Pvalue(1,:))),'\n'],Pvalue(j,:));
        end
        fclose(ID_File);

        %% Create Figure
        if obj.StatusPlot
            Fig     = figure('color',[1 1 1]);
            T       = [18, 8];
            set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
            [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off') 

            NameLag = {'Lag -5';'Lag -4';'Lag -3';'Lag -2';'Lag -1';'Lag 0';...
                        'Lag 1';'Lag 2';'Lag 3';'Lag 4';'Lag 5'};

            subplot(1,2,1)
            h = heatmap(R);
            h.XDisplayLabels    = NameLag;
            h.YDisplayLabels    = ENSO_Index.Name;
            h.Colormap          = flipud(pink);
            h.Title             = 'Coeficiente de correlación de Pearson';
            colorbar off            

            subplot(1,2,2)
            h = heatmap(Pvalue);
            h.XDisplayLabels    = NameLag;
            h.YDisplayLabels    = ENSO_Index.Name;
            h.Colormap          = [0 0.5 0.5; 0.9 0.9 0.9];
            h.ColorLimits       = [0 0.05];
            h.Title             = 'Pvalue';
            colorbar off        

            %% Save    
            saveas(Fig, fullfile(obj.PathProject,'FIGURES','Teleconnections',['Teleconnections_',num2str(obj.Code(PoPo(ii))),'.jpg']))
            close(Fig)
        end

        %% Disp
        disp(['Ok Telconexiones -> ',num2str(obj.Code(PoPo(ii)))])
    catch
        disp(['Error Telconexiones -> ',num2str(obj.Code(PoPo(ii)))])
    end
end
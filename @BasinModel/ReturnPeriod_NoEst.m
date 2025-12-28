function ReturnPeriod_NoEst(obj1, varargin)

mkdir( fullfile(obj1.PathProject,'OUTPUTS','Return-Period-NoEst') )
mkdir( fullfile(obj1.PathProject,'FIGURES','Return-Period-NoEst') )

if nargin > 1
    Code_PoPo = varargin{1}; 
else
    Code_PoPo = [];
end

if ~isempty(Code_PoPo)
    [~, PoPo] = ismember(Code_PoPo, obj1.Code);
else
    PoPo = 1:length(obj1.Code);
end

if nargin > 2
    TypePeriod = varargin{2};
else
    TypePeriod = 'Max';
end

if nargin > 3
    TR = varargin{3};
else
    TR = [2 5 10 25 50 100];
end

%% Descargar indicadores ENSO
ENSO_Index = obj1.Download_ENSO_Index(fullfile(obj1.PathProject,'OUTPUTS','Return-Period-NoEst'));

%% Agregation Data  
obj     = obj1.copy();
obj.AggregationData('Monthly', TypePeriod);
Y       = unique(year(obj.Date));
Date    = (datetime(Y(1),1,1):calmonths:datetime(Y(end),12,1))';

%% Clip de indicadores ENSO en el periodo de analisis
[id,posi]       = ismember(Date,ENSO_Index.Date);   
ENSO_Index.Data = ENSO_Index.Data(posi(id),:); 
ENSO_Index.Date = Date;

%% Selección NiÑo o Niña
ONI         = NaN(size(ENSO_Index.Data(:,9)));
ONI(:,1)    = double(ENSO_Index.Data(:,9) >= 0.5);
ONI(:,2)    = double(ENSO_Index.Data(:,9) <= -0.5);
ONI(:,3)    = double((ENSO_Index.Data(:,9) > -0.5)&(ENSO_Index.Data(:,9) < 0.5));
ONI(ONI==0) = NaN;

%% Storage
NameENSO    = {'NINO','NINA','NEUTRO'};
TR_TR       = NaN(length(PoPo),3,length(TR));
NameBest    = cell(length(PoPo),3);
TotalError  = NaN(length(PoPo),3);

for jio = 1:3
    %% Select data
    obj_ONI         = obj.copy();
    obj_ONI.Data    = bsxfun(@times,obj.Data, ONI(:,jio));

    %% Agregation Data      
    obj_ONI.AggregationData('Years', TypePeriod);
    
    %% Storage
    Total_TR        = NaN(length(PoPo),length(TR));
    for ii = 1:length(PoPo)
        
        %% Input Data
        Data        = obj_ONI.Data(:,PoPo(ii));
        Data        = Data(~isnan(Data));                
    
        %% Guardar grafico
        if obj.StatusPlot
            %% Ajuste de PDF
            [CDF, TotalError(ii,jio), NameBest{ii,jio}, Fig] = obj.Settings_PDF_1(Data,true);

            saveas(Fig, fullfile(obj.PathProject,'FIGURES','Return-Period-NoEst',...
            ['TR_',NameENSO{jio},'_',TypePeriod,'_Basin-',num2str(obj.Code(PoPo(ii))),'.jpg']))
            
            close all
            clearvars Fig
        else
            %% Ajuste de PDF
            [CDF, TotalError(ii,jio), NameBest{ii,jio}, Fig] = obj.Settings_PDF_1(Data,true);
        end
        
        %% Calculo de periodo de retorno
        if strcmp(TypePeriod, 'Max')
            Total_TR(ii,:)    = icdf(CDF, 1 - (1./TR) );
        else
            Total_TR(ii,:)    = icdf(CDF, (1./TR) );
        end                              
        Total_TR(Total_TR<0) = 0;

        disp(['OK - > ',NameENSO{jio},' | Code - ', num2str(obj.Code(PoPo(ii)))])              
        
    end
    TR_TR(:,jio,:) = Total_TR;  
    
    %% Export Totals
    NameFile = fullfile(obj.PathProject,'OUTPUTS','Return-Period-NoEst',['TR_',TypePeriod,'_',NameENSO{jio},'.csv']);
    ID_File  = fopen(NameFile,'w');
    fprintf(ID_File,'Code,2,5,10,25,50,100\n');
    fprintf(ID_File,'%d,%f,%f,%f,%f,%f,%f\n',[obj.Code(PoPo), Total_TR]');    
    fclose(ID_File);

end

%% Calculo de periodo e retorno no estacionario
ONI(isnan(ONI)) = 0;
ONI = logical(ONI);
FactorPDF = [length(unique(year(ENSO_Index.Date(ONI(:,1))))),...
             length(unique(year(ENSO_Index.Date(ONI(:,2))))),...
             length(unique(year(ENSO_Index.Date(ONI(:,3)))))];
FactorPDF = FactorPDF/sum(FactorPDF);
TTRR = sum(bsxfun(@times,TR_TR, FactorPDF),2);
TTRR = permute(TTRR,[1, 3, 2]);

%% Save Error
NameFile = fullfile(obj.PathProject,'OUTPUTS','Return-Period-NoEst',['TR_',TypePeriod,'_Error-PDF.csv']);
ID_File  = fopen(NameFile,'w');
fprintf(ID_File,'Code,NINO,NINA,NEUTRO\n');
fprintf(ID_File,'%d,%f,%f,%f\n',[obj.Code(PoPo) TotalError]');
fclose(ID_File);

%% Save Best PDF
NameFile = fullfile(obj.PathProject,'OUTPUTS','Return-Period-NoEst',['TR_',TypePeriod,'_Best-PDF.csv']);
ID_File  = fopen(NameFile,'w');
fprintf(ID_File,'Code,NINO,NINA,NEUTRO\n');
for w = 1:length(PoPo)
    fprintf(ID_File,'%d,',obj.Code(PoPo(w)));
    for ww = 1
        fprintf(ID_File,'%s,',NameBest{w,ww});
    end
    fprintf(ID_File,'\n');
end
fclose(ID_File);

%% Export Totals
NameFile = fullfile(obj.PathProject,'OUTPUTS','Return-Period-NoEst',['TR_',TypePeriod,'_Total.csv']);
ID_File  = fopen(NameFile,'w');
fprintf(ID_File,'Code,2,5,10,25,50,100\n');
fprintf(ID_File,'%d,%f,%f,%f,%f,%f,%f\n',[obj.Code(PoPo), TTRR]');    
fclose(ID_File);

disp('Total Ok')
function ReturnPeriod(obj1, varargin)

mkdir( fullfile(obj1.PathProject,'OUTPUTS','Return-Period') )
mkdir( fullfile(obj1.PathProject,'FIGURES','Return-Period') )

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

%% Creamos un Pack de Serie de Tiempo Manualt
Months = {'ENE','FEB','MAR','ABR','MAY','JUN','JUL',...
          'AGO','SEP','OCT','NOV','DIC'};

%% Agregation Data  
obj = obj1.copy();
obj.AggregationData('Monthly', TypePeriod);
Y       = unique(year(obj.Date));
Date    = (datetime(Y(1),1,1):calmonths:datetime(Y(end),12,1))';
Data    = NaN(length(Date),1);

%% Storage
TR_TR       = NaN(12,length(TR),length(PoPo));
NameBest    = cell(length(PoPo),12);
TotalError  = NaN(length(PoPo),12);
for ii = 1:length(PoPo)
    
    %% Input Data
    Date_ii = obj.Date;
    Data_ii = obj.Data(:,PoPo(ii));

    %% Accum
    IdDate  = find(~isnan(Data_ii));
    Data_ii = Data_ii(IdDate(1):IdDate(end));
    Date_ii = Date_ii(IdDate(1):IdDate(end));
    
    %% ismam
    [id, posi] = ismember(Date_ii,Date);
    Data(posi) = Data_ii(id);
    Data = reshape(Data,12,[])';
    
    %% Storage
    Total_TR = NaN(12,length(TR));
    for jj = 1:12
        %% pdf
        if obj.StatusPlot
            [CDF, TotalError(ii,jj), NameBest{ii,jj}, Fig] = obj.Settings_PDF_1(Data(:,jj),true);
            
            saveas(Fig, fullfile(obj.PathProject,'FIGURES','Return-Period',...
            [TypePeriod,'_',Months{jj},'_Basin-',num2str(obj.Code(PoPo(ii))),'.jpg']))
            
            close all
            clearvars Fig
        else
            [CDF, TotalError(ii,jj), NameBest{ii,jj},~] = obj.Settings_PDF_1(Data(:,jj));
        end
        
        %% Cal TR
        if strcmp(TypePeriod, 'Max')
            Total_TR(jj,:)    = icdf(CDF, 1 - (1./TR) );
        else
            Total_TR(jj,:)    = icdf(CDF, (1./TR) );
        end                              
        
        disp(['OK - > TR - ',Months{jj},' | Code - ', num2str(obj.Code(PoPo(ii)))])
    end
    TR_TR(:,:,ii) = Total_TR;
    
    %% Save Return Period
    NameFile = fullfile(obj.PathProject,'OUTPUTS','Return-Period',...
        ['ReturnPeriod_',TypePeriod,'_Basin-',num2str(obj.Code(PoPo(ii))),'.csv']);
    ID_File  = fopen(NameFile,'w');
    
    Tmp  = 'Code';
    Format = '';
    for jj = 1:length(TR)
        Tmp = [Tmp,',TR_',num2str(TR(jj))];
        Format = [Format,',%f'];
    end
    Tmp     = [Tmp,'\n'];
    Format  = [Format,'\n'];
    
    fprintf(ID_File,Tmp);
    for jj = 1:12
        fprintf(ID_File,'%s',Months{jj});
        fprintf(ID_File,Format,Total_TR(jj,:));
    end
    fclose(ID_File);
    
    disp(['OK - > Total | Code - ', num2str(obj.Code(PoPo(ii)))])
    disp('--------------------------------------------')
    
end

%% Save Error
NameFile = fullfile(obj.PathProject,'OUTPUTS','Return-Period',[TypePeriod,'_Error-PDF.csv']);
ID_File  = fopen(NameFile,'w');
fprintf(ID_File,'Code,ENE,FEB,MAR,ABR,MAY,JUN,JUL,AGO,SEP,OCT,NOV,DIC\n');
fprintf(ID_File,'%d,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n',[obj.Code(PoPo) TotalError]');
fclose(ID_File);

%% Save Best PDF
NameFile = fullfile(obj.PathProject,'OUTPUTS','Return-Period',[TypePeriod,'_Best-PDF.csv']);
ID_File  = fopen(NameFile,'w');
fprintf(ID_File,'Code,ENE,FEB,MAR,ABR,MAY,JUN,JUL,AGO,SEP,OCT,NOV,DIC\n');
for w = 1:length(PoPo)
    fprintf(ID_File,'%d,',obj.Code(PoPo(w)));
    for ww = 1:12
        fprintf(ID_File,'%s,',NameBest{w,ww});
    end
    fprintf(ID_File,'\n');
end
fclose(ID_File);

disp('Total Ok')

%% Export Totals
for i = 1:length(TR)
    Tmp_TR = reshape(TR_TR(:,i,:),12,[])';
    NameFile = fullfile(obj.PathProject,'OUTPUTS','Return-Period',[TypePeriod,'_TR-',num2str(TR(i)),'_Total.csv']);
    ID_File  = fopen(NameFile,'w');
    fprintf(ID_File,'Code,ENE,FEB,MAR,ABR,MAY,JUN,JUL,AGO,SEP,OCT,NOV,DIC\n');
    fprintf(ID_File,'%d,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n',[obj.Code(PoPo), Tmp_TR]');    
    fclose(ID_File);

    disp(['Total TR - ', num2str(TR(i))])
end
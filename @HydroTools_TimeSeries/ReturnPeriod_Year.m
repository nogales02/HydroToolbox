function ReturnPeriod_Year(obj1, varargin)

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
    TR = [2 2.33 5 10 25 50 100];
end

%% Agregation Data  
obj = obj1.copy();
obj.AggregationData('Years', TypePeriod);

%% Storage
TR_TR       = NaN(length(PoPo),length(TR));
NameBest    = cell(length(PoPo),1);
TotalError  = NaN(length(PoPo),1);
for ii = 1:length(PoPo)
    tic
    try
        %% Input Data    
        Data    = obj.Data(:,PoPo(ii));

        %% Accum
        IdDate  = find(~isnan(Data));
        % Data    = Data(IdDate(1):IdDate(end)); 
        Data    = Data(IdDate); 

        %% pdf
        if obj.StatusPlot
            [CDF, TotalError(ii), NameBest{ii}, Fig] = obj.Settings_PDF_1(Data,obj.StatusPlot);

            saveas(Fig, fullfile(obj.PathProject,'FIGURES','Return-Period',...
            ['TR_YEAR_',TypePeriod,'_Basin-',num2str(obj.Code(PoPo(ii))),'.jpg']))

            close all
            clearvars Fig
        else
            [CDF, TotalError(ii), NameBest{ii},~] = obj.Settings_PDF_1(Data);
        end

        %% Cal TR
        if strcmp(TypePeriod, 'Max')
            TR_TR(ii,:)    = icdf(CDF, 1 - (1./TR) );
        else
            TR_TR(ii,:)    = icdf(CDF, (1./TR) );
        end                              
        
        disp(['OK - > Code - ', num2str(obj.Code(PoPo(ii))),' | Time: ',num2str(toc,'%.4f'),' seg'])
    catch
        TR_TR(ii,:) = -999;
        disp(['Error - > Code - ', num2str(obj.Code(PoPo(ii))),' | Time: ',num2str(toc,'%.4f'),' seg'])
    end
end

% %{
%% Encabezado
NameCol = ['Code'];
FormatFile = ['%d'];
for i = 1:length(TR)        
    NameCol     = [NameCol,',TR_', num2str(TR(i))];
    FormatFile  = [FormatFile, ',%f'];
end
NameCol     = [NameCol,'\n'];
FormatFile  = [FormatFile,'\n'];


%% Save Error
NameFile = fullfile(obj.PathProject,'OUTPUTS','Return-Period',[TypePeriod,'_Error-PDF.csv']);
ID_File  = fopen(NameFile,'w');
fprintf(ID_File,'Code,RMSE_PDF\n');
fprintf(ID_File,'%d,%f\n',[obj.Code(PoPo), TotalError]');    
fclose(ID_File);

%% Save Best PDF
NameFile = fullfile(obj.PathProject,'OUTPUTS','Return-Period',[TypePeriod,'_Best-PDF.csv']);
ID_File  = fopen(NameFile,'w');
fprintf(ID_File,'Code,Name_Best_PDF\n');
for w = 1:length(PoPo)
    fprintf(ID_File,'%d,',obj.Code(PoPo(w)));
    fprintf(ID_File,'%s,',NameBest{w});   
    fprintf(ID_File,'\n');
end
fclose(ID_File);

%% Export Totals
NameFile = fullfile(obj.PathProject,'OUTPUTS','Return-Period',[TypePeriod,'_Total.csv']);
ID_File  = fopen(NameFile,'w');
fprintf(ID_File,NameCol);
fprintf(ID_File,FormatFile,[obj.Code(PoPo), TR_TR]');    
fclose(ID_File);
disp('Total Ok')
%}

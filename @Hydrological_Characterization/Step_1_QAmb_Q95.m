function Step_1_QAmb_Q95(obj, varargin)

mkdir( fullfile(obj.PathProject,'OUTPUTS','QAmb') )

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


%% Creamos un Pack de Serie de Tiempo Manualt
Months = {'ENE','FEB','MAR','ABR','MAY','JUN','JUL',...
          'AGO','SEP','OCT','NOV','DIC'};

Porcentaje  = [5 10 50 75 85 95];
Data_Q95    = NaN(12,length(PoPo));
for ii = 1:length(PoPo)
    
    %% Input Data
    Date = obj.Date;
    Data = obj.Data(:,PoPo(ii));

    %% Accum
    IdDate  = find(~isnan(Data));
    Data = Data(IdDate(1):IdDate(end));
    Date = Date(IdDate(1):IdDate(end));
        
    %% Storage
    DataQ = NaN(12,6);
    for j = 1:12            
        pos = find(month(Date)==j);
        Q   = Data(pos);
                         
        %%
        [Por_Q,Qd]      = hist(Q,length(unique(Q)));
        [Qsort, id ]    = sort(Qd, 'descend');
        PQ              = (cumsum(Por_Q(id))/sum(Por_Q(id)))*100;
        [~, id]         = unique(PQ);
        DataQ(j,:)      = interp1(PQ(id), Qsort(id), Porcentaje); 
    end          
    
    Data_Q95(:,ii) = DataQ(:,end);
    
    %% 
%     ID_File = fopen(fullfile(obj.PathProject,'OUTPUTS','QAmb',['QAmb_',num2str(obj.Code(PoPo(ii))),'.csv']),'w');        
%     fprintf(ID_File,'Month,Q5,Q10,Q50,Q75,Q85,Q95\n');
%     for j = 1:12
%         fprintf(ID_File,Months{j});
%         fprintf(ID_File,',%0.4f,%0.4f,%0.4f,%0.4f,%0.4f,%0.4f\n',DataQ(j,:));
%     end
%     fclose(ID_File);  

    disp(['OK - > CDC | Code - ', num2str(obj.Code(PoPo(ii)))])
    disp('--------------------------------------------')
end

%% Save data
NameFile    = fullfile(obj.PathProject,'OUTPUTS','QAmb','Q95_Months.csv');
ID_File     = fopen(NameFile,'w'); 

Tmp = ['Month'];
for k = 1:length(PoPo)
    Tmp = [Tmp,',', num2str(obj.Code(PoPo(k)))];
end
Tmp = [Tmp, '\n'];
fprintf(ID_File,Tmp);

FTmp = [',%0.4f'];
for k = 1:length(PoPo)-1
    FTmp = [FTmp,',%0.4f'];
end
FTmp = [FTmp, '\n'];

for j = 1:12
    fprintf(ID_File,Months{j});
    fprintf(ID_File,FTmp,Data_Q95(j,:));
end
fclose(ID_File); 

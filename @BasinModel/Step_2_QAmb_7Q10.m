function Step_2_QAmb_7Q10(obj, varargin)

mkdir( fullfile(obj.PathProject,'OUTPUTS','QAmb') )
mkdir( fullfile(obj.PathProject,'FIGURES','QAmb','CDF_7Q10') )

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

%% Storage
I_7Q10 = NaN(length(PoPo),1);
for ii = 1:length(PoPo)
    
    %% Input Data
    Date = obj.Date;
    Data = obj.Data(:,PoPo(ii));

    %% Accum
    IdDate  = find(~isnan(Data));
    Q       = Data(IdDate(1):IdDate(end));
    Date1   = Date(IdDate(1):IdDate(end));    
    
    Resolution  = 7;
    Fil     = length(Q);
    Step    = ceil(Fil/Resolution);
    Tmp     = NaN(Step*Resolution, 1);
    Tmp(1:Fil) = Q;
    Tmp     = reshape(Tmp,Resolution,[]);    
    Date    = Date1(1:Resolution:(Step*Resolution)); 
    Data    = mean(Tmp,'omitnan')';
    
    Ys      = year(Date)';
    Yu      = unique(Ys)'; 
    QTc     = NaN(length(Yu),1);
    
    for i = 1:length(Yu)
        Posi    = find(Ys == Yu(i));
        QTc(i)  = min(Data(Posi)); 
    end
    
    if obj.StatusPlot
        [CDF, ~, ~, Fig] = obj.Settings_PDF_1(QTc,true);
        
        saveas(Fig, fullfile(obj.PathProject,'FIGURES','QAmb','CDF_7Q10',...
            ['CDF-',num2str(obj.Code(PoPo(ii))),'.jpg']))
        
        close all
    else 
        [CDF, ~, ~, ~] = obj.Settings_PDF(QTc);
    end        
    
    Tc = 10;
    I_7Q10(ii)    = icdf(CDF, (1./Tc) );
        
end

%% Save Error
NameFile = fullfile(obj.PathProject,'OUTPUTS','QAmb','7Q10.csv');
ID_File = fopen(NameFile,'w'); 
fprintf(ID_File,'Basin,7Q10\n');
fprintf(ID_File,'%0.4f,%0.4f\n',[obj.Code(PoPo), I_7Q10]');
fclose(ID_File);
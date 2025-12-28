function Test_Rachas(obj, varargin)
%% Input
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

%% Create Folder
Results = zeros(length(PoPo), 1);

for ii = 1:length(PoPo)
    try
        id          = find(~isnan(obj.Data(:,PoPo(ii))));
        Data        = obj.Data(id(1):id(end),PoPo(ii));
        
        %% Fitting NAN Value
%         Data(isnan(Data)) = mean(Data(~isnan(Data)));   
        
%         %% Tranformation Series
%         % Centralizamos
%         Data = Data - mean(Data, 'omitnan');
%         % Estandarizamos
%         Data = Data./std(Data, 'omitnan');

        [N,~] = size(Data);
        if mod(N,2) ~= 0
            Data    = Data(1:end-1);
        end

        medias  = mean(Data, 'omitnan');
        bins    = Data >= medias;
        a       = bins(1:end-1);
        p       = bins(2:end);
        re      = a == p;
        re      = sum(re);
        n       = length(Data);
        rt      = (n+1)/2.0;
        srt     = sqrt(n-1)/2.0;

        % Calculo del cuantil de tel
        alfa    = 0.95;
        q       = tinv(alfa, n-1);
        Results(ii) = (re >= rt - q*srt) & (re <= rt + q*srt);    
    
        disp(['Rachas ok for Gauges ->',num2str(obj.Code(PoPo(ii)))])
    catch
        disp(['Rachas Error in Gauges ->',num2str(obj.Code(PoPo(ii)))])
    end
end

Code = obj.Code(PoPo);
Code = reshape(Code,length(Code),1);

%% Save Data
NameFile    = fullfile(obj.PathProject,'RESULTS','Test_Rachas.csv');
ID_File     = fopen(NameFile,'w');

fprintf(ID_File,'%s\n','Code, True|False');
fprintf(ID_File, '%f,%d\n',[Code, Results]');
fclose(ID_File);
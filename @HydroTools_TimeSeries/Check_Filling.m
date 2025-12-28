function Check_Filling(obj, varargin)

% [Data, Date, Params_All, F, Posi] = Check_Filling(obj, varargin)
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

%% Threshold Change
if nargin > 2
    Threshold_Change = varargin{2};
else
    Threshold_Change = [];
end

%% Create Folder
mkdir(fullfile(obj.PathProject,'FIGURES','TimeSeries'))

for ii = 1:length(PoPo)
    try
        id          = find(~isnan(obj.Data(:,PoPo(ii))));
        Data        = obj.Data(id(1):id(end),PoPo(ii));
        Date        = obj.Date(id(1):id(end));
        
        %%
        Table_i = table(Date, Data, year(Date), month(Date),'VariableNames',{'Date','Value','Year','Month'});
        P       = table2array(varfun(@sum,Table_i,'GroupingVariables',{'Year','Month'},'InputVariable','Value'));       

        Datec   = datetime(P(:,1), P(:,2), P(:,3));
        Data    = cumsum(P(:,4), 'omitnan');

        nDay = 12;

        %% Parameters
        % Data Number
        N   = length(Data);
        ni  = floor(N/(1*nDay));
        s   = (1*nDay);

        Params_All = NaN(ni, 2);
        Posi = NaN(ni, 2);

        for i = 1:ni
            Posi(i,:) = [1 + (s*(i - 1)), s + (s*(i - 1))];
            Pv      = Data(1 + (s*(i - 1)):s + (s*(i - 1)));
            Params  = polyfit((1 + (s*(i - 1)):s + (s*(i - 1)))',Pv,1); 
            Params_All(i,:) = Params; 
        end
        ji = Params_All(:,1) < 0.1;
        PosiDate = Posi;

%         plot(obj.Date, obj.Data(:,PoPo(ii)))
                
        %% Remove Time Series
        ChangeS = Params_All(:,1);
        ChangeS(ji,1) = 999;
        
        if isempty(Threshold_Change)
            Threshold_Change = mean(Params_All(:,1)) + std(P(:,4));
        end
        
        Pochis = (ChangeS > (mean(Params_All(:,1)) + std(P(:,4)))) | (ChangeS < (mean(Params_All(:,1)) - std(P(:,4))));
        if sum(Pochis) > 0
            tmp = cumsum(Pochis);
            id  = unique(tmp);
            SZ  = NaN(length(id),1);
            for j = 1:length(id)
                SZ(j) = sum(tmp == id(j));
            end
            tmp1 = find(SZ == max(SZ));
            id1  = id(tmp1(1));

            if id == 0
                id      = find(tmp == id1);
                Datec   = Datec(PosiDate(id(1),1):PosiDate(id(end),2));
                Datec   = unique(year(Datec));
            else
                id      = find(tmp == id1);
                if length(id) ~= 1                    
                    Datec   = Datec(PosiDate(id(1),1):PosiDate(id(end),2));
                    Datec   = unique(year(Datec));
                end                
            end
        else
            Datec   = unique(year(Datec));
        end

        %% Asignation Values
        [id, ~] = ismember(year(obj.Date), Datec);
        Data    = obj.Data(:,PoPo(ii));
        obj.Data(:,PoPo(ii))    = NaN;
        obj.Data(id,PoPo(ii))   = Data(id);
%         hold on, plot(obj.Date, obj.Data(:,PoPo(ii)))
%         close all 
        
        disp([num2str((ii/length(obj.Code))*100,'%.2f'),'% -> Ok Complect ->',num2str(obj.Code(PoPo(ii)))]) 
    catch
        disp([num2str((ii/length(obj.Code))*100,'%.2f'),'% -> Error ->',num2str(obj.Code(PoPo(ii)))])
    end
    
end
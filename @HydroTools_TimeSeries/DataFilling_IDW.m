function DataFilling_IDW(obj, varargin)

%% Preliminary
warning off

%% Codes
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

%% Mas Distance (meters)
if nargin > 2
    Maxdist = varargin{2};
else
    Maxdist = 50000;    
end

if nargin > 3
    NaNStatus = varargin{3};
else
    NaNStatus = true;
end

if nargin > 4
    SaveStatus = varargin{4};
else
    SaveStatus = true;
end

%% Initial Date
InitData    = zeros(length(obj.Code), 1);
EndData     = zeros(length(obj.Code), 1);
for i = 1:length(obj.Code)
    Ident           = (1:length(obj.Date));
    tmp             = Ident(~isnan(obj.Data(:,i)));
    if isempty(tmp)
        InitData(i,1)   = 1;
        EndData(i,1)    = length(obj.Date);
        continue
    end
    InitData(i,1)   = tmp(1) -1;
    EndData(i,1)    = tmp(end) + 1;
end

%% Estimate Max
M = month(obj.Date);
MaxData = zeros(12, length(obj.Code));
MinData = zeros(12, length(obj.Code));
for i = 1:12
    MaxData(i,:) = max(obj.Data(M==i,:));
    MinData(i,:) = min(obj.Data(M==i,:));
end

%% size
[fil, col] = size(obj.Data);

%% Initial Complementation
for ii = 1:length(PoPo) 
    try
        if NaNStatus
            idii    = find(~isnan(obj.Data(:,PoPo(ii))));
        else
            idii    = (1:length(obj.Date))';
        end
        
        Data    = obj.Data(idii(1):idii(end),PoPo(ii));   
        Date    = obj.Date(idii(1):idii(end));

        %% NaN
        NaNValue = find(isnan(Data));
        SiValue  = find(~isnan(Data));
        
        if isempty(NaNValue)
            disp([num2str((ii/length(PoPo))*100,'%.2f'),'% -> Ok Complect IDW for Gauges ->',num2str(obj.Code(PoPo(ii)))])
            continue
        end
        %% Select Gauges by Interpolation
        X1      = obj.X(PoPo(ii));
        Y1      = obj.Y(PoPo(ii));

        % Distance
        Dist    = sqrt( (obj.X - X1).^2 + (obj.Y - Y1).^2 );
        Dist(PoPo(ii)) = 1E50;
        ID_Se   = find(Dist <= Maxdist);

        %% Data Select
        Data2   = obj.Data(idii(1):idii(end),ID_Se); 
    %     Data2(isnan(Data2)) = 0;    

        %% Calibration exponent
        Param = -10:0.1:10;
        RMSE  = NaN(size(Param));
        parfor i = 1:length(Param)
            dis = 1 ./ ((sqrt(((obj.X(ID_Se) - obj.X(ii)).^ 2) + ((obj.Y(ID_Se) - obj.Y(ii)) .^ 2) )) .^ Param(i));
            dis(isinf(dis)) = 0;    
            dis = dis';
            Value = NaN(length(SiValue),1);
            for j = 1:length(SiValue)
                Tmp = Data2(SiValue(j),:)';
                idd = ~isnan(Tmp);
                if sum(idd) == 0
                    continue
                end
                Value(j) = sum( Tmp(idd).*(dis(idd)./ sum(dis(idd))));
            end        
            RMSE(i) = mean((Value - Data(SiValue)).^2,'omitnan'); 
        end
        Beta = Param(RMSE == min(RMSE));

        %% Verification
    %     dis = 1 ./ ((sqrt(((obj.X(ID_Se) - obj.X(ii)).^ 2) + ((obj.Y(ID_Se) - obj.Y(ii)) .^ 2) )) .^ Beta);
    %     dis(isinf(dis)) = 0;    
    %     dis = dis';
    %     Value = NaN(length(SiValue),1);
    %     for j = 1:length(SiValue)
    %         Tmp = Data2(SiValue(j),:)';
    %         idd = ~isnan(Tmp);
    %         if sum(idd) == 0
    %             continue
    %         end
    %         Value(j) = sum( Tmp(idd).*(dis(idd)./ sum(dis(idd))));
    %     end

        %% Estimation Values 
        dis = 1 ./ ((sqrt(((obj.X(ID_Se) - obj.X(ii)).^ 2) + ((obj.Y(ID_Se) - obj.Y(ii)) .^ 2) )) .^ Beta);
        dis(isinf(dis)) = 0;    
        dis = dis';
        Value = NaN(length(NaNValue),1);
        parfor j = 1:length(NaNValue)
            Tmp = Data2(NaNValue(j),:)';
            idd = ~isnan(Tmp);
            if sum(idd) == 0
                continue
            end
            Value(j) = sum( Tmp(idd).*(dis(idd)./ sum(dis(idd))));
        end

        Data(NaNValue)  = Value;

        obj.Data(idii(1):idii(end),PoPo(ii)) = Data;
        
        %% Disp
        disp([num2str((ii/length(PoPo))*100,'%.2f'),'% -> Ok Complect IDW for Gauges ->',num2str(obj.Code(PoPo(ii)))])        
    catch
        disp([num2str((ii/length(PoPo))*100,'%.2f'),'% -> Ok Complect IDW for Gauges ->',num2str(obj.Code(PoPo(ii)))]) 
    end
end

%% Remove Max and Min Data
for i = 1:12
    id = find(M == i);
    
    %% Ckeck Max data
    for j = 1:length(MaxData(1,:))
        idd = (obj.Data(M==i,j) > MaxData(i,j));
        obj.Data(id(idd), j) = MinData(i,j);
    end

    %% Ckeck Min data
    for j = 1:length(MinData(1,:))
        idd = (obj.Data(M==i,j) < MinData(i,j));
        obj.Data(id(idd), j) = MinData(i,j);
    end
end

%% only for rainfall data
if NaNStatus
    for i = 1:length(obj.Code)    
        if InitData(i) == 1
            obj.Data(InitData(i),i)     = NaN;

        elseif InitData(i) > 1
            obj.Data(1:InitData(i),i)   = NaN;
        end

        if EndData(i) == fil
            obj.Data(EndData(i),i)      = NaN;

        elseif EndData(i) < fil
            obj.Data(EndData(i):fil,i)  = NaN;
        end    
    end
end

%% Save
if SaveStatus
    NameFile = fullfile(obj.PathProject,'RESULTS','ComplectData_IDW.csv');
    obj.WriteData(NameFile);
end

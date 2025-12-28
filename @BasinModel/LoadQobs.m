function LoadQobs(Basin)

NameFile    = fullfile(Basin.PathProject, 'INPUTS','7_Qobs.csv');
% Load Date
ID_File = fopen(NameFile,'r');
for i = 1:4
    LineText = fgetl(ID_File);
    LineText = strsplit(LineText,',');
    LineText = LineText(4:end);
    
    if i == 1
        DateCal_Init    = datetime(LineText, 'InputFormat', 'dd-MM-yyyy');
    elseif i == 2
        DateCal_End     = datetime(LineText, 'InputFormat', 'dd-MM-yyyy');
    elseif i == 3
        DateVal_Init    = datetime(LineText, 'InputFormat', 'dd-MM-yyyy');
    elseif i == 4
        DateVal_End     = datetime(LineText, 'InputFormat', 'dd-MM-yyyy');
    end
end
fclose(ID_File);

% Load Data
Tmp         = dlmread(NameFile,',',4,3);
CodeObs     = Tmp(1,:);
Tmp         = dlmread(NameFile,',',5);
Qobs        = Tmp(:,4:end);
DateObs     = datetime(Tmp(:,1:3));

% Check Data
[id, posi] = ismember(Basin.Date, DateObs);
if sum(id) ~= length(Basin.Date)
    error('Error Date')
end

% Check code
GaugesID = Basin.GaugesCal(Basin.GaugesCal~=0);
[id, posi1] = ismember(GaugesID, CodeObs);
if sum(id) ~= length(GaugesID)
    error('Error Code Gauges')
end

Qobs = Qobs(posi,posi1);
Qobs(Qobs == Basin.NoValue) = NaN;

% Date
DateCal_Init = DateCal_Init(posi1);
DateCal_End  = DateCal_End(posi1);
DateVal_Init = DateVal_Init(posi1);
DateVal_End  = DateVal_End(posi1);

% Date Calibration
Basin.DateCal_Init  = DateCal_Init;
Basin.DateCal_End   = DateCal_End;
% Date Validation 
Basin.DateVal_Init  = DateVal_Init;
Basin.DateVal_End   = DateVal_End;
% Observation Flow (m3/seg)
Basin.Qobs          = Qobs;
% Gauges Calibration
Basin.GaugesID      = GaugesID;


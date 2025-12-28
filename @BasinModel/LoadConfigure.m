function LoadConfigure(Basin)

% -------------------------------------------------------------------------
% Crear carpetas de salida
% -------------------------------------------------------------------------
mkdir(fullfile(Basin.PathProject, 'OUTPUTS','Variables'))
mkdir(fullfile(Basin.PathProject, 'FIGURES','Hydrological_Regime'))

%% Read Configure Model   
NameFile = fullfile(Basin.PathProject,'INPUTS','1_Configure.txt');
ID_File = fopen(NameFile,'r');

% Check Configure.MoHiTo File
if ID_File == -1    
    ErrorMessage    = 'The Configure not found';
    errordlg(ErrorMessage,'!! Error !!')
    return
end

Jo = 0;
Po1 = 1;
LineFile = fgetl(ID_File);
while ischar(LineFile)        
    if contains( LineFile, '*')        
        LineFile = strrep(LineFile,'*','');
        LineFile = strrep(LineFile,' ','');
        LineFile = strsplit(LineFile,'>');
        Po = str2double(LineFile{1});
        if Po == Po1
            Jo = Jo + 1;
        else
            Jo = 1;
        end
        
        Tmp = strsplit(LineFile{2},'|');
        
        if Po == 1
            NameModel   = LineFile{2};
        elseif Po == 2
            DateInit    = datetime(LineFile{2}, 'InputFormat', 'yyyy-MM-dd');
        elseif Po == 3
            DateEnd     = datetime(LineFile{2}, 'InputFormat', 'yyyy-MM-dd'); 
        elseif Po == 4
            dt          = str2double(LineFile{2});
        elseif Po == 5
            Status_ModelFlood = logical(str2double(LineFile{2}));
        elseif Po == 6
            % DateInit Calibration
            PorcCal     = str2double(Tmp{1});
            % Date Days
            PorcOmit    = str2double(Tmp{2});
            % MaxIter
            MaxIter     = str2double(Tmp{3});
            % Calibration metric
            CalMetricSelect = Tmp{4};
        elseif Po == 7
            Tmp = strsplit(LineFile{2},'|');
            for i = 1:length(Tmp)
                RangeParamsFlood(i,:)   = (cellfun(@str2double,strsplit(Tmp{i},','))); 
            end  
        elseif Po == 8
            Tmp = strsplit(LineFile{2},'|');
            for i = 1:length(Tmp)
                RangeParamsBasin(i,:)   = (cellfun(@str2double,strsplit(Tmp{i},','))); 
            end             
        end
        Po1 = Po;
    end
    LineFile = fgetl(ID_File);
end
fclose(ID_File);

% Date
if dt == 2
    Basin.dt            = 'month';
    Basin.Date          = (DateInit:calmonths:DateEnd)';
else
    Basin.dt            = 'day';
    Basin.Date          = (DateInit:caldays:DateEnd)';
end
% NumberModel
Basin.NameModel         = NameModel;
% DateInit Calibration
Basin.PorcCal           = PorcCal;
% Date Days
Basin.PorcOmit          = PorcOmit;
% Status Flood Plains Model
Basin.Status_ModelFlood = Status_ModelFlood;
% Range Parameters
Basin.RangeParamsBasin  = RangeParamsBasin;
% Range Parameters
Basin.RangeParamsFlood  = RangeParamsFlood;
% MaxIter
Basin.maxIter           = MaxIter;
% Calibration Metric
Basin.CalMetricSelect   = CalMetricSelect;

%% Configure Parameters Optmization
% the lower bound of the parameters
Basin.bl = [Basin.RangeParamsFlood(:,1)' Basin.RangeParamsBasin(:,1)'];
% the upper bound of the parameters
Basin.bu = [Basin.RangeParamsFlood(:,2)' Basin.RangeParamsBasin(:,2)'];

end
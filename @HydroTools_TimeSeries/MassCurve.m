function MassCurve(obj, varargin)
%MASSCURVE Generates mass curves (cumulative precipitation) for time series analysis
%
%   MASSCURVE(obj) generates mass curves for all stations in the object
%   using default parameters.
%
%   MASSCURVE(obj, 'Parameter', Value, ...) specifies additional
%   parameter-value pairs:
%
%   Parameters:
%   -----------
%   'Code'      - Vector of station codes to process (default: all codes)
%                 Example: [1001, 1002, 1003]
%
%   'YLabel'    - String for Y-axis label (default: '\bf Lluvia Acumulada(mm)')
%                 Example: '\bf Precipitación Acumulada (mm)'
%
%   Description:
%   ------------
%   Mass curves are cumulative plots that show the total accumulation of
%   precipitation over time. They are useful for:
%   - Detecting systematic errors or inconsistencies in data
%   - Identifying periods of instrument malfunction
%   - Quality control of long-term precipitation records
%   - Comparing precipitation patterns between stations
%
%   The function fits a linear model to the cumulative data and calculates
%   Pearson correlation coefficient to assess linearity.
%
%   Output Files:
%   -------------
%   - Plot figures: FIGURES/MassCurve/[Code].jpg
%   - Correlation results: RESULTS/Correlation_MassCurves.csv
%
%   Example:
%   --------
%   % Generate mass curves for all stations
%   MassCurve(myObject);
%
%   % Generate for specific stations with custom label
%   MassCurve(myObject, 'Code', [1001, 1005], ...
%             'YLabel', '\bf Precipitación Acumulada (mm)');
%
%   Requirements:
%   -------------
%   MATLAB R2018b or later
%   Statistics and Machine Learning Toolbox (for corrcoef)
%
%   Author: Jonathan Nogales Pimentel
%   Email:  jonathannogales02@gmail.com
%   Date:   01-July-2019
%   Version: 2.0

%% Input validation and parsing
p = inputParser;
addRequired(p, 'obj', @(x) isstruct(x) || isobject(x));
addParameter(p, 'Code', [], @(x) isnumeric(x) || isempty(x));
addParameter(p, 'YLabel', '\bf Lluvia Acumulada(mm)', @(x) ischar(x) || isstring(x));

parse(p, obj, varargin{:});

Code_PoPo = p.Results.Code;
NameLabel = char(p.Results.YLabel);

%% Station selection
if ~isempty(Code_PoPo)
    [~, PoPo] = ismember(Code_PoPo, obj.Code);
    PoPo(PoPo == 0) = []; % Remove non-existent codes
else
    PoPo = 1:length(obj.Code);
end

%% Create Folder
mkdir(fullfile(obj.PathProject,'FIGURES','MassCurve'));
mkdir(fullfile(obj.PathProject,'RESULTS'));

% Initialize correlation storage
rPearson = zeros(length(PoPo), 1);

%% Main processing loop
for ii = 1:length(PoPo)
    try
        %% Input Data
        Date = obj.Date;
        Data = obj.Data(:,PoPo(ii));
        
        %% Data preparation
        idx_1  = find( (~isnan(Data)&(month(Date)==1)&(day(Date)==1)));
        idx_2  = find( (~isnan(Data)&(month(Date)==12)&(day(Date)==31)));
        IdDate = idx_1(1):idx_2(end);
        % IdDate = find(~isnan(Data));
        if isempty(IdDate)
            continue; % Skip stations with no data
        end
        
        Data = Data(IdDate(1):IdDate(end));
        Date = Date(IdDate(1):IdDate(end));
        
        %% Monthly aggregation and cumulative calculation
        Table_i = table(Date, Data, year(Date), month(Date), ...
                       'VariableNames', {'Date','Value','Year','Month'});
        P = table2array(varfun(@sum, Table_i, 'GroupingVariables', {'Year','Month'}, ...
                              'InputVariable', 'Value'));       
        Datec = datetime(P(:,1), P(:,2), P(:,3));
        Pcm = cumsum(P(:,4), 'omitnan');
        
        % Linear model fit (monthly data)
        Params = polyfit(datenum(Datec), Pcm, 1);
        Psim = polyval(Params, datenum(Datec));
        
        %% Annual aggregation for correlation analysis
        P = table2array(varfun(@sum, Table_i, 'GroupingVariables', {'Year'}, ...
                              'InputVariable', 'Value'));
        Datec_annual = P(:,1);
        Pcm_annual = cumsum(P(:,3), 'omitnan');
        
        % Linear model fit (annual data)
        Params_annual = polyfit(Datec_annual, Pcm_annual, 1);
        Psim_annual = polyval(Params_annual, Datec_annual);
        
        %% Pearson correlation calculation
        correlacion = corrcoef(Pcm_annual, Psim_annual);
        rPearson(ii) = correlacion(1, 2);
        
        %% Generate plot
        if obj.StatusPlot
            Fig = figure('color', [1 1 1], 'Visible', 'off');
            T = [10, 8];
            set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T], ...
                'Position', [0, 0, T], 'PaperUnits', 'Inches', ...
                'PaperSize', T, 'PaperType', 'usletter');
            
            plot(Datec_annual, Pcm_annual, 'LineWidth', 2, ...
                 'Color', obj.ColorsF('carmine'));
            hold on;
            plot(Datec_annual, Psim_annual, '--', 'LineWidth', 1, ...
                 'Color', 'black');
            
            ylim([min(Pcm_annual) max(Pcm_annual)]);
            xlabel('\bf Time', 'Interpreter', 'latex', 'FontSize', 20);
            ylabel(NameLabel, 'Interpreter', 'latex', 'FontSize', 20);
            
            le = legend('\bf Mass Curve', '\bf Linear regression', ...
                       'Interpreter', 'latex', 'FontSize', 15, ...
                       'FontWeight', 'bold', 'Box', 'off', ...
                       'Color', 'none', 'Location', 'northwest');
            set(gca, 'TickLabelInterpreter', 'latex', 'FontWeight', 'bold', ...
                'Color', 'none', 'Box', 'on', 'FontSize', 18);
            
            %% Save figure
            saveas(Fig, fullfile(obj.PathProject, 'FIGURES', 'MassCurve', ...
                                [num2str(obj.Code(PoPo(ii))), '.jpg']));
            close(Fig);
        end
        
    catch ME
        % Continue processing other stations if one fails
        continue;
    end
end

%% Save correlation results
Code = reshape(obj.Code(PoPo), length(PoPo), 1);
NameFile = fullfile(obj.PathProject, 'RESULTS', 'Correlation_MassCurves.csv');
ID_File = fopen(NameFile, 'w');
fprintf(ID_File, 'Code,r-Pearson\n');
fprintf(ID_File, '%d,%0.3f\n', [Code, rPearson]');
fclose(ID_File);

end
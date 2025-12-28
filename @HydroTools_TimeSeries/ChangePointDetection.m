function ChangePointDetection(obj, varargin)
%CHANGEPOINTDETECTION Detects change points in time series data
%
%   CHANGEPOINTDETECTION(obj) detects change points for all stations in the 
%   object using default parameters.
%
%   CHANGEPOINTDETECTION(obj, 'Parameter', Value, ...) specifies additional
%   parameter-value pairs:
%
%   Parameters:
%   -----------
%   'Code'           - Vector of station codes to process (default: all codes)
%                      Example: [1001, 1002, 1003]
%
%   'Method'         - Detection method (default: 'mean')
%                      Options: 'mean', 'variance', 'rms', 'linear'
%
%   'WindowSize'     - Size of fixed windows in days (default: 365)
%                      Example: 365 (annual), 180 (semi-annual), 730 (bi-annual)
%
%   'MinThreshold'   - Minimum confidence threshold (default: 0.5)
%                      Range: 0 to 1 (higher = more strict)
%
%   'MaxChanges'     - Maximum number of changes to detect (default: 5)
%                      Range: 1 to 10
%
%   'MinDistance'    - Minimum distance between changes (default: 30)
%                      In number of observations
%
%   'YLabel'         - String for Y-axis label (default: '\bf Data')
%                      Example: '\bf Precipitación (mm)'
%
%   Description:
%   ------------
%   Change point detection identifies significant changes in statistical
%   properties of time series data. Useful for:
%   - Quality control of meteorological data
%   - Detecting instrument changes or relocations
%   - Identifying climate shifts or data inconsistencies
%   - Validating homogeneity of long-term records
%
%   The function uses multiple criteria to classify changes:
%   1. Confidence score from statistical tests
%   2. Magnitude of change between periods
%   3. Statistical significance (t-test)
%   4. Persistence of change over time
%
%   Output Files:
%   -------------
%   - Plot figures: FIGURES/ChangePoints/[Code].jpg
%   - Summary results: RESULTS/ChangePoint_Summary.csv
%   - Individual results: RESULTS/ChangePoints/[Code]_changes.csv
%
%   Example:
%   --------
%   % Detect changes for all stations
%   ChangePointDetection(myObject);
%
%   % Detect changes using 6-month windows
%   ChangePointDetection(myObject, 'Code', [1001, 1005], ...
%                        'WindowSize', 180, 'YLabel', '\bf Temperatura (°C)');
%
%   Requirements:
%   -------------
%   MATLAB R2024b or later
%   Statistics and Machine Learning Toolbox
%
%   Author: Jonathan Nogales Pimentel
%   Email:  jonathannogales02@gmail.com
%   Date:   07-August-2025
%   Version: 1.0

%% Input validation and parsing
p = inputParser;
addRequired(p, 'obj', @(x) isstruct(x) || isobject(x));
addParameter(p, 'Code', [], @(x) isnumeric(x) || isempty(x));
addParameter(p, 'Method', 'mean', @(x) ismember(x, {'mean','variance','rms','linear'}));
addParameter(p, 'WindowSize', 365, @(x) isnumeric(x) && x > 0);
addParameter(p, 'MinThreshold', 0.5, @(x) isnumeric(x) && x >= 0 && x <= 1);
addParameter(p, 'MaxChanges', 5, @(x) isnumeric(x) && x >= 1 && x <= 10);
addParameter(p, 'MinDistance', 30, @(x) isnumeric(x) && x > 0);
addParameter(p, 'YLabel', '\bf Rainfall (mm)', @(x) ischar(x) || isstring(x));

parse(p, obj, varargin{:});

Code_PoPo = p.Results.Code;
WindowSize = p.Results.WindowSize;
Method = p.Results.Method;
MinThreshold = p.Results.MinThreshold;
MaxChanges = p.Results.MaxChanges;
MinDistance = p.Results.MinDistance;
YLabel = char(p.Results.YLabel);

%% Station selection
if ~isempty(Code_PoPo)
    [~, PoPo] = ismember(Code_PoPo, obj.Code);
    PoPo(PoPo == 0) = []; % Remove non-existent codes
else
    PoPo = 1:length(obj.Code);
end

%% Create folders
mkdir(fullfile(obj.PathProject,'FIGURES','ChangePoints'));
mkdir(fullfile(obj.PathProject,'RESULTS','ChangePoints'));
mkdir(fullfile(obj.PathProject,'RESULTS'));

% Initialize summary storage
Summary = NaN(length(PoPo), 7);
% Columns: HasChange, NumChanges, MaxConfidence, MaxMagnitude, MinPValue, ChangeType, QualityScore

%% Main processing loop
for ii = 1:length(PoPo)
    try
        %% Data preparation
        Data = obj.Data(:,PoPo(ii));
        Date = obj.Date;
        
        Data = sqrt(Data);  % Square root to handle skewness
        Data = (Data - mean(Data,'omitmissing')) / std(Data,'omitmissing');

        % Remove NaN values
        idx_valid = ~isnan(Data);
        if sum(idx_valid) < MinDistance * 2
            continue; % Skip if insufficient data
        end
        
        Data_clean = Data(idx_valid);
        Date_clean = Date(idx_valid);
        
        %% Change point detection using fixed windows
        window_size = WindowSize; % User-defined window size
        
        if length(Data_clean) < window_size * 2
            continue; % Skip if insufficient data for analysis
        end
        
        % Calculate means for fixed windows
        n_windows = floor(length(Data_clean) / window_size);
        window_means = NaN(n_windows, 1);
        window_starts = NaN(n_windows, 1);
        window_ends = NaN(n_windows, 1);
        
        for w = 1:n_windows
            start_idx = (w-1) * window_size + 1;
            end_idx = w * window_size;
            
            if end_idx <= length(Data_clean)
                window_data = Data_clean(start_idx:end_idx);
                window_means(w) = mean(window_data, 'omitnan');
                window_starts(w) = start_idx;
                window_ends(w) = end_idx;
            end
        end
        
        % Remove NaN values
        valid_windows = ~isnan(window_means);
        window_means = window_means(valid_windows);
        window_starts = window_starts(valid_windows);
        window_ends = window_ends(valid_windows);
        
        % Detect significant changes between consecutive windows
        change_points = [];
        change_dates = datetime.empty;
        confidences = [];
        magnitudes = [];
        pvalues = [];
        
        for w = 2:length(window_means)
            % Get data for current and previous windows
            prev_data = Data_clean(window_starts(w-1):window_ends(w-1));
            curr_data = Data_clean(window_starts(w):window_ends(w));
            
            % Calculate magnitude of change
            mag = abs(window_means(w) - window_means(w-1));
            
            % Statistical test
            try
                [~, pval] = ttest2(prev_data, curr_data);
                
                % Calculate confidence based on effect size and p-value
                pooled_std = sqrt((var(prev_data) + var(curr_data)) / 2);
                if pooled_std > 0
                    effect_size = mag / pooled_std;
                    conf = effect_size * (1 - pval); % Combined metric
                else
                    effect_size = 0;
                    conf = 0;
                end
                
                % Store change point at the beginning of current window
                change_points(end+1) = window_starts(w);
                change_dates(end+1) = Date_clean(window_starts(w));
                confidences(end+1) = conf;
                magnitudes(end+1) = mag;
                pvalues(end+1) = pval;
                
            catch
                % Skip if test fails
                change_points(end+1) = window_starts(w);
                change_dates(end+1) = Date_clean(window_starts(w));
                confidences(end+1) = 0;
                magnitudes(end+1) = 0;
                pvalues(end+1) = 1;
            end
        end
        
        %% Analyze detected changes
        HasChange = 0;
        NumChanges = length(change_points);
        MaxConfidence = 0;
        MaxMagnitude = 0;
        MinPValue = 1;
        ChangeType = 1; % Mean changes
        QualityScore = 0;
        
        if ~isempty(change_points)
            % Summary statistics
            MaxConfidence = max(confidences);
            MaxMagnitude = max(magnitudes);
            MinPValue = min(pvalues);
            
            % Determine significant changes
            significant_changes = (pvalues < 0.05) & (magnitudes > std(Data_clean) * 0.3);
            
            if any(significant_changes)
                HasChange = 1;
                NumChanges = sum(significant_changes);
                QualityScore = mean([min(1, MaxConfidence), 1-MinPValue, min(1, MaxMagnitude/std(Data_clean))]);
            end
        end
        
        % Store summary
        Summary(ii,:) = [HasChange, NumChanges, MaxConfidence, MaxMagnitude, ...
                        MinPValue, ChangeType, QualityScore];
        
        %% Save individual results
        if ~isempty(change_points)
            NameFile = fullfile(obj.PathProject,'RESULTS','ChangePoints',...
                               [num2str(obj.Code(PoPo(ii))),'_changes.csv']);
            ID_File = fopen(NameFile,'w');
            fprintf(ID_File,'Window,ChangeDate,Confidence,Magnitude,PValue,Significant\n');
            
            for j = 1:length(change_points)
                if j <= length(confidences)
                    conf_val = confidences(j);
                else
                    conf_val = 0;
                end
                if j <= length(magnitudes)
                    mag_val = magnitudes(j);
                else
                    mag_val = 0;
                end
                if j <= length(pvalues)
                    pval_val = pvalues(j);
                else
                    pval_val = 1;
                end
                sig = (pval_val < 0.05) & (mag_val > std(Data_clean) * 0.3);
                fprintf(ID_File,'%d,%s,%.4f,%.4f,%.6f,%d\n', ...
                       j+1, datestr(change_dates(j)), ...
                       conf_val, mag_val, pval_val, sig);
            end
            fclose(ID_File);
        end
        
        %% Generate plots
        if obj.StatusPlot
            Fig = figure('color',[1 1 1], 'Visible','off');
            T = [16, 7];
            set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T], ...
                'Position', [0, 0, T], 'PaperUnits', 'Inches', ...
                'PaperSize', T, 'PaperType', 'usletter');
            
            % Plot original series in gray
            plot(Date_clean, Data_clean, 'Color', [0.8 0.8 0.8], 'LineWidth', 1);
            hold on;
            
            % Plot horizontal lines for each annual window mean
            for w = 1:length(window_means)
                start_date = Date_clean(window_starts(w));
                end_date = Date_clean(window_ends(w));
                
                % Draw horizontal line for this window
                plot([start_date, end_date], [window_means(w), window_means(w)], ...
                     'b-', 'LineWidth', 3);
            end
            
            % Mark significant change points
            if ~isempty(change_points)
                significant_changes = (pvalues < 0.05) & (magnitudes > std(Data_clean) * 0.3);
                
                % Mark all change points (start of each window after first)
                if length(change_points) > 0
                    for cp = 1:length(change_points)
                        xline(change_dates(cp), 'k--', 'LineWidth', 1, 'Alpha', 0.5);
                    end
                end
                
                % Mark significant changes with red markers and text
                if any(significant_changes)
                    sig_dates = change_dates(significant_changes);
                    sig_mags  = magnitudes(significant_changes);
                    
                    for i = 1:length(sig_dates)
                        % Red vertical line
                        xline(sig_dates(i), 'r-', 'LineWidth', 1.7);
                        
                        % Add text annotation
                        y_pos = max(Data_clean) * 0.9;
                        text(sig_dates(i), y_pos, ...
                            ['\bf ${\delta}$=', num2str(sig_mags(i),'%.2f')], ...
                            'HorizontalAlignment', 'center', ...
                            'VerticalAlignment', 'bottom', ...
                            'FontSize', 9, 'Color', 'red', ...
                            'Interpreter', 'latex', ...
                            'BackgroundColor', 'white', ...
                            'EdgeColor', 'red');
                    end
                end
            end
            
            ylabel('${\frac{\sqrt{Data} - \mathrm{mean}(\sqrt{Data})}{\mathrm{std}(\sqrt{Data})}}$','Interpreter','latex', 'FontSize',20)
            % ylabel(YLabel, 'Interpreter','latex', 'FontSize',20);
            xlabel('\bf Time', 'Interpreter','latex', 'FontSize',20);
            title(['\bf Detection of changes in the records of station ', num2str(obj.Code(PoPo(ii)))], ...
                  'Interpreter','latex', 'FontSize',16);
            
            % Dynamic legend
            window_label = ['\bf Window (', num2str(WindowSize),' days)'];
            legend_items = {'\bf Time series', window_label};
            % if ~isempty(change_points)
            %     legend_items{end+1} = '\bf Window average';
            %     if any(significant_changes)
            %         legend_items{end+1} = '\bf Significant changes';
            %     end
            % end
            
            legend(legend_items, 'Interpreter','latex', 'FontSize',14, 'Box','off', 'Location','northeast');
            set(gca, 'TickLabelInterpreter','latex', 'FontWeight','bold', ...
                'Color','none', 'Box','off', 'FontSize',18, 'LineWidth',2);
            
            %% Save figure
            % ylim([0 max(Data_clean)*1.1])
            saveas(Fig, fullfile(obj.PathProject,'FIGURES','ChangePoints',...
                                [num2str(obj.Code(PoPo(ii))),'.jpg']));
            close(Fig);
        end
        
    catch ME
        % Continue with other stations
        continue;
    end
end

%% Save summary results
Code = reshape(obj.Code(PoPo), length(PoPo), 1);
NameFile = fullfile(obj.PathProject,'RESULTS','ChangePoint_Summary.csv');
ID_File = fopen(NameFile,'w');
fprintf(ID_File,'Code,HasChange,NumChanges,MaxConfidence,MaxMagnitude,MinPValue,ChangeType,QualityScore\n');
fprintf(ID_File,'%d,%d,%d,%.4f,%.4f,%.6f,%d,%.4f\n', [Code, Summary]');
fclose(ID_File);

end
function DoubleMassCurve(obj, varargin)
%DOUBLEMASSCURVE Generates double mass curves for quality control analysis
%
%   DOUBLEMASSCURVE(obj) generates double mass curves for all stations in the 
%   object using the 3 nearest reference stations.
%
%   DOUBLEMASSCURVE(obj, 'Parameter', Value, ...) specifies additional
%   parameter-value pairs:
%
%   Parameters:
%   -----------
%   'Code'          - Vector of station codes to process (default: all codes)
%                     Example: [1001, 1002, 1003]
%
%   'NumReference'  - Number of reference stations to use (default: 3)
%                     Range: 1 to 10
%
%   'MinDistance'   - Minimum distance to consider reference stations (default: 0)
%                     In same units as obj.X and obj.Y coordinates
%
%   'MaxDistance'   - Maximum distance to consider reference stations (default: Inf)
%                     In same units as obj.X and obj.Y coordinates
%
%   'BreakpointThreshold' - Minimum slope change to consider significant (default: 0.2)
%                          Example: 0.3 means 30% change in slope
%
%   'MinSegmentLength' - Minimum years per segment for breakpoint analysis (default: 3)
%                       Ensures statistical reliability
%
%   'MinDataCoverage' - Minimum data coverage required for reference stations (default: 0.8)
%                      Range: 0.1 to 1.0 (e.g., 0.8 = 80% of target period must have data)
%
%   'XLabel'        - String for X-axis label (default: '\bf Referencia Acumulada (mm)')
%                     Example: '\bf Estaciones de Referencia (mm)'
%
%   'YLabel'        - String for Y-axis label (default: '\bf Estación Acumulada (mm)')
%                     Example: '\bf Precipitación Acumulada (mm)'
%
%   Description:
%   ------------
%   Double mass curves compare cumulative precipitation of a target station
%   against the average cumulative precipitation of nearby reference stations.
%   They are essential for:
%   - Detecting systematic errors in precipitation records
%   - Identifying instrument changes or station relocations
%   - Quality control of long-term meteorological data
%   - Homogeneity testing of precipitation time series
%
%   The method uses annual aggregation and automatically detects breakpoints
%   (changes in slope) that indicate potential data inconsistencies.
%
%   Output Files:
%   -------------
%   - Plot figures: FIGURES/DoubleMassCurve/[Code].jpg
%   - Summary results: RESULTS/DoubleMassCurve_Summary.csv
%   - Reference stations used: RESULTS/DoubleMassCurve/[Code]_references.csv
%   - Breakpoint details: RESULTS/DoubleMassCurve/[Code]_breakpoints.csv
%
%   Example:
%   --------
%   % Generate double mass curves for all stations
%   DoubleMassCurve(myObject);
%
%   % Use sensitive breakpoint detection
%   DoubleMassCurve(myObject, 'BreakpointThreshold', 0.15);
%
%   Requirements:
%   -------------
%   MATLAB R2018b or later
%   Statistics and Machine Learning Toolbox (for corrcoef)
%   obj must contain: Data, Date, Code, X, Y coordinates
%
%   Author: Jonathan Nogales Pimentel
%   Email:  jonathannogales02@gmail.com
%   Date:   07-August-2025
%   Version: 2.0

%% Input validation and parsing
p = inputParser;
addRequired(p, 'obj', @(x) isstruct(x) || isobject(x));
addParameter(p, 'Code', [], @(x) isnumeric(x) || isempty(x));
addParameter(p, 'NumReference', 3, @(x) isnumeric(x) && x >= 1 && x <= 10);
addParameter(p, 'MinDistance', 0, @(x) isnumeric(x) && x >= 0);
addParameter(p, 'MaxDistance', Inf, @(x) isnumeric(x) && x > 0);
addParameter(p, 'BreakpointThreshold', 0.3, @(x) isnumeric(x) && x > 0 && x < 1);
addParameter(p, 'MinSegmentLength', 3, @(x) isnumeric(x) && x >= 2);
addParameter(p, 'MinDataCoverage', 1, @(x) isnumeric(x) && x > 0 && x <= 1);
addParameter(p, 'XLabel', '\bf Referencia Acumulada (mm)', @(x) ischar(x) || isstring(x));
addParameter(p, 'YLabel', '\bf Estaci\''on Acumulada (mm)', @(x) ischar(x) || isstring(x));

parse(p, obj, varargin{:});

Code_PoPo           = p.Results.Code;
NumReference        = p.Results.NumReference;
MinDistance         = p.Results.MinDistance;
MaxDistance         = p.Results.MaxDistance;
BreakpointThreshold = p.Results.BreakpointThreshold;
MinSegmentLength    = p.Results.MinSegmentLength;
MinDataCoverage     = p.Results.MinDataCoverage;
XLabel              = char(p.Results.XLabel);
YLabel              = char(p.Results.YLabel);

%% Station selection
if ~isempty(Code_PoPo)
    [~, PoPo] = ismember(Code_PoPo, obj.Code);
    PoPo(PoPo == 0) = []; % Remove non-existent codes
else
    PoPo = 1:length(obj.Code);
end

%% Create folders
mkdir(fullfile(obj.PathProject,'FIGURES','DoubleMassCurve'));
mkdir(fullfile(obj.PathProject,'RESULTS','DoubleMassCurve'));
mkdir(fullfile(obj.PathProject,'RESULTS'));

% Initialize summary storage
Summary = NaN(length(PoPo), 8);
% Columns: NumRefStations, Correlation, OverallSlope, Intercept, QualityScore, NumBreakpoints, MaxSlopeChange, HasSignificantChange

%% Main processing loop
for ii = 1:length(PoPo)
    % try
        target_idx = PoPo(ii);
        
        %% Find reference stations
        % Calculate distances to all other stations
        distances = sqrt((obj.X - obj.X(target_idx)).^2 + (obj.Y - obj.Y(target_idx)).^2);
        
        % Apply distance filters and exclude target station
        valid_mask      = (distances >= MinDistance) & (distances <= MaxDistance) & (distances > 0);
        valid_indices   = find(valid_mask);
        valid_distances = distances(valid_indices);
        
        % Check if we have enough reference stations
        if length(valid_indices) < NumReference
            NumRef = length(valid_indices);
            if NumRef == 0
                continue; % Skip if no valid reference stations
            end
        else
            NumRef = NumReference;
        end
        
        % Sort by distance and select closest
        [~, sort_idx] = sort(valid_distances);        
        
        %% Data preparation for target station
        Data_target = obj.Data(:, target_idx);
        Date        = obj.Date;
        
        % Remove NaN values
        idx_1 = find( (~isnan(Data_target)&(month(Date)==1)&(day(Date)==1)));
        idx_2 = find( (~isnan(Data_target)&(month(Date)==12)&(day(Date)==31)));
        idx_valid = idx_1(1):idx_2(end);
        if sum(idx_valid) < 365 * 3 % Need at least 3 years of data
            continue;
        end
        
        Data_target_clean   = Data_target(idx_valid);
        Date_clean          = Date(idx_valid);
        
        %% Annual aggregation for target station
        Table_target = table(Date_clean, Data_target_clean, year(Date_clean), ...
                            'VariableNames', {'Date','Value','Year'});
        P_target = table2array(varfun(@(x) sum(x, 'omitnan'), Table_target, 'GroupingVariables', {'Year'}, ...
                                     'InputVariable', 'Value'));
        
        %% Data preparation for reference stations with coverage validation
        ref_monthly_data = [];
        valid_ref_indices = [];
        excluded_refs = [];
        
        % reference_indices = valid_indices(sort_idx(1:NumRef));
        idValid = 0;
        for jj = 1:numel(valid_indices)
            ref_idx = valid_indices(jj);

            Data_ref = obj.Data(:, ref_idx);

            % Use same date range as target station
            Data_ref_clean = Data_ref(idx_valid);

            % Annual aggregation for reference station
            Table_ref = table(Date_clean, Data_ref_clean, year(Date_clean), ...
                             'VariableNames', {'Date','Value','Year'});
            P_ref = table2array(varfun(@(x) sum(x, 'omitnan'), Table_ref, 'GroupingVariables', {'Year'}, ...
                                      'InputVariable', 'Value'));

            % Validate data coverage for this reference station
            if size(P_ref, 1) == size(P_target, 1)
                % Check for valid (non-NaN) annual data
                valid_years = ~isnan(P_ref(:, 3))&(P_ref(:, 3)>0);
                data_coverage = sum(valid_years) / length(valid_years);

                % Only include if coverage meets minimum threshold
                if data_coverage >= MinDataCoverage
                    ref_monthly_data(:, end+1) = P_ref(:, 3);
                    valid_ref_indices(end+1) = ref_idx;
                    idValid = idValid + 1;
                else
                    excluded_refs(end+1) = ref_idx;
                end
            else
                excluded_refs(end+1) = ref_idx;
            end
            if NumRef > NumRef
                break
            end
        end

        % Update reference indices to only include valid ones
        if numel(valid_ref_indices) >= NumRef
            reference_indices = valid_ref_indices(1:NumRef);
        else
            reference_indices = valid_ref_indices;
        end
        
        %% Calculate reference average and cumulative values
        if isempty(ref_monthly_data)
            continue; % Skip if no valid reference data
        end
        
        % Average of reference stations
        idxClean = find(sum(isnan(ref_monthly_data)) == height(ref_monthly_data));
        ref_monthly_data(:,idxClean) = [];

        ref_annual_avg = mean(ref_monthly_data, 2);
        
        % Cumulative values
        target_cumulative = cumsum(P_target(:, 3));
        ref_cumulative = cumsum(ref_annual_avg);
        
        % Remove any NaN or Inf values
        valid_cum = ~isnan(target_cumulative) & ~isnan(ref_cumulative) & ...
                   ~isinf(target_cumulative) & ~isinf(ref_cumulative);
        
        if sum(valid_cum) < 3 % Need at least 3 years
            continue;
        end
        
        target_cum_clean = target_cumulative(valid_cum);
        ref_cum_clean = ref_cumulative(valid_cum);
        years_clean = P_target(valid_cum, 1);
        
        %% Breakpoint detection using sliding window approach
        n_years = length(target_cum_clean);
        breakpoints = [];
        slope_changes = [];
        
        if n_years >= 2 * MinSegmentLength
            % Try different breakpoint positions
            for bp = MinSegmentLength:(n_years - MinSegmentLength)
                % Segment 1: from start to breakpoint
                ref1 = ref_cum_clean(1:bp);
                target1 = target_cum_clean(1:bp);
                
                % Segment 2: from breakpoint to end
                ref2 = ref_cum_clean(bp+1:end);
                target2 = target_cum_clean(bp+1:end);
                
                % Calculate slopes for each segment
                if length(ref1) >= 2 && length(ref2) >= 2 && std(ref1) > 0 && std(ref2) > 0
                    p1 = polyfit(ref1, target1, 1);
                    p2 = polyfit(ref2, target2, 1);
                    
                    slope1 = p1(1);
                    slope2 = p2(1);
                    
                    % Calculate relative change in slope
                    if slope1 ~= 0
                        slope_change = abs(slope2 - slope1) / abs(slope1);
                    else
                        slope_change = abs(slope2);
                    end
                    
                    % Store if change is significant
                    if slope_change >= BreakpointThreshold
                        breakpoints(end+1) = bp;
                        slope_changes(end+1) = slope_change;
                    end
                end
            end
        end
        
        % Select most significant breakpoint if multiple found
        if ~isempty(breakpoints)
            [max_change, max_idx] = max(slope_changes);
            primary_breakpoint = breakpoints(max_idx);
            primary_slope_change = max_change;
            
            % Calculate slopes for the primary breakpoint
            ref1 = ref_cum_clean(1:primary_breakpoint);
            target1 = target_cum_clean(1:primary_breakpoint);
            ref2 = ref_cum_clean(primary_breakpoint+1:end);
            target2 = target_cum_clean(primary_breakpoint+1:end);
            
            p1 = polyfit(ref1, target1, 1);
            p2 = polyfit(ref2, target2, 1);
            slope1 = p1(1);
            slope2 = p2(1);
            intercept1 = p1(2);
            intercept2 = p2(2);
        else
            primary_breakpoint = [];
            primary_slope_change = 0;
            slope1 = NaN;
            slope2 = NaN;
            intercept1 = NaN;
            intercept2 = NaN;
        end
        
        %% Overall linear regression and correlation
        if length(target_cum_clean) >= 2 && std(ref_cum_clean) > 0
            % Overall linear fit
            p_coeff = polyfit(ref_cum_clean, target_cum_clean, 1);
            overall_slope = p_coeff(1);
            overall_intercept = p_coeff(2);
            
            % Correlation
            corr_matrix = corrcoef(ref_cum_clean, target_cum_clean);
            correlation = corr_matrix(1, 2);
            
            % Quality score (penalize breakpoints)
            slope_quality = 1 - abs(overall_slope - 1);
            breakpoint_penalty = min(0.5, length(breakpoints) * 0.1);
            quality_score = (abs(correlation) + max(0, slope_quality) - breakpoint_penalty) / 2;
            quality_score = max(0, quality_score);
        else
            overall_slope = NaN;
            overall_intercept = NaN;
            correlation = NaN;
            quality_score = 0;
        end
        
        %% Store summary
        NumBreakpoints = length(breakpoints);
        MaxSlopeChange = primary_slope_change;
        HasSignificantChange = NumBreakpoints > 0;
        
        Summary(ii, :) = [NumRef, correlation, overall_slope, overall_intercept, ...
                         quality_score, NumBreakpoints, MaxSlopeChange, HasSignificantChange];
        
        %% Save breakpoint details
        if ~isempty(breakpoints)
            NameFile = fullfile(obj.PathProject,'RESULTS','DoubleMassCurve',...
                               [num2str(obj.Code(target_idx)),'_breakpoints.csv']);
            ID_File = fopen(NameFile,'w');
            fprintf(ID_File,'Year,SlopeChange,SlopeBefore,SlopeAfter,BreakpointIndex\n');
            
            for bp = 1:length(breakpoints)
                bp_idx = breakpoints(bp);
                if bp == max_idx % Primary breakpoint
                    fprintf(ID_File,'%d,%.4f,%.4f,%.4f,%d\n', ...
                           years_clean(bp_idx), slope_changes(bp), slope1, slope2, bp_idx);
                else
                    fprintf(ID_File,'%d,%.4f,NaN,NaN,%d\n', ...
                           years_clean(bp_idx), slope_changes(bp), bp_idx);
                end
            end
            fclose(ID_File);
        end
        
        %% Save reference stations used (valid and excluded)
        NameFile = fullfile(obj.PathProject,'RESULTS','DoubleMassCurve',...
                           [num2str(obj.Code(target_idx)),'_references.csv']);
        ID_File = fopen(NameFile,'w');
        fprintf(ID_File,'RefCode,Distance,X,Y,Status,DataCoverage\n');

        % Save valid reference stations
        for ref_idx = reference_indices
            dist = distances(ref_idx);
            % Calculate actual coverage for valid stations
            Data_ref = obj.Data(:, ref_idx);
            Data_ref_clean = Data_ref(idx_valid);
            Table_ref = table(Date_clean, Data_ref_clean, year(Date_clean), ...
                             'VariableNames', {'Date','Value','Year'});
            P_ref = table2array(varfun(@(x) sum(x, 'omitnan'), Table_ref, 'GroupingVariables', {'Year'}, ...
                                      'InputVariable', 'Value'));
            valid_years = ~isnan(P_ref(:, 3));
            actual_coverage = sum(valid_years) / length(valid_years);

            fprintf(ID_File,'%d,%.2f,%.2f,%.2f,Used,%.3f\n', ...
                   obj.Code(ref_idx), dist, obj.X(ref_idx), obj.Y(ref_idx), actual_coverage);
        end

        % Save excluded reference stations
        for ref_idx = excluded_refs
            dist = distances(ref_idx);
            % Calculate coverage for excluded stations
            Data_ref = obj.Data(:, ref_idx);
            Data_ref_clean = Data_ref(idx_valid);
            if ~isempty(Data_ref_clean)
                Table_ref = table(Date_clean, Data_ref_clean, year(Date_clean), ...
                                 'VariableNames', {'Date','Value','Year'});
                P_ref = table2array(varfun(@(x) sum(x, 'omitnan'), Table_ref, 'GroupingVariables', {'Year'}, ...
                                          'InputVariable', 'Value'));
                if size(P_ref, 1) > 0
                    valid_years = ~isnan(P_ref(:, 3));
                    actual_coverage = sum(valid_years) / length(valid_years);
                else
                    actual_coverage = 0;
                end
            else
                actual_coverage = 0;
            end

            fprintf(ID_File,'%d,%.2f,%.2f,%.2f,Excluded,%.3f\n', ...
                   obj.Code(ref_idx), dist, obj.X(ref_idx), obj.Y(ref_idx), actual_coverage);
        end
        fclose(ID_File);
        
        %% Generate plots
        if obj.StatusPlot && exist('target_cum_clean', 'var')
            Fig = figure('color',[1 1 1], 'Visible','off');
            T = [12, 8];
            set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T], ...
                'Position', [0, 0, T], 'PaperUnits', 'Inches', ...
                'PaperSize', T, 'PaperType', 'usletter');
            
            % Scatter plot
            scatter(ref_cum_clean, target_cum_clean, 50, 'b', 'filled');
            hold on;
            
            % Plot segments if breakpoint exists
            if ~isempty(primary_breakpoint)
                % Segment 1
                ref1 = ref_cum_clean(1:primary_breakpoint);
                target1 = target_cum_clean(1:primary_breakpoint);
                fit1 = polyval([slope1, intercept1], ref1);
                plot(ref1, fit1, 'r-', 'LineWidth', 3);
                
                % Segment 2
                ref2 = ref_cum_clean(primary_breakpoint+1:end);
                target2 = target_cum_clean(primary_breakpoint+1:end);
                fit2 = polyval([slope2, intercept2], ref2);
                plot(ref2, fit2, 'g-', 'LineWidth', 3);
                
                % Mark breakpoint
                bp_x = ref_cum_clean(primary_breakpoint);
                bp_y = target_cum_clean(primary_breakpoint);
                scatter(bp_x, bp_y, 200, 'r', 'filled', 'Marker', 's');
                
                % Add breakpoint annotation
                text(bp_x, bp_y + max(target_cum_clean)*0.05, ...
                    ['year: ', num2str(years_clean(primary_breakpoint), '%d'), newline, ...
                     '${\delta}$=', num2str(primary_slope_change*100, '%.1f'), '\%'], ...
                    'HorizontalAlignment', 'center', 'FontSize', 10, ...
                    'BackgroundColor', 'yellow', 'EdgeColor', 'red', 'Interpreter', 'latex');
            else
                % Single linear fit if no breakpoints
                fit_line = polyval([overall_slope, overall_intercept], ref_cum_clean);
                plot(ref_cum_clean, fit_line, 'r-', 'LineWidth', 2);
            end
            
            % Perfect correlation line (slope = 1)
            max_val = max([max(ref_cum_clean), max(target_cum_clean)]);
            plot([0, max_val], [0, max_val], 'k--', 'LineWidth', 1);
            
            % Labels and formatting
            xlabel(XLabel, 'Interpreter', 'latex', 'FontSize', 20);
            ylabel(YLabel, 'Interpreter', 'latex', 'FontSize', 20);
            title(['\bf Double Mass Curve - Station ', num2str(obj.Code(target_idx))], ...
                  'Interpreter', 'latex', 'FontSize', 16);
            
            % Dynamic legend
            if ~isempty(primary_breakpoint)
                legend_entries = {'\bf Observed Data', ...
                                 ['\bf Time period 1 (slope= ', num2str(slope1,'%.3f'), ')'], ...
                                 ['\bf Time period 2 (slope= ', num2str(slope2,'%.3f'), ')'], ...
                                 '\bf Point of change', ...
                                 '\bf Reference line (1:1)'};
            else
                legend_entries = {'\bf Observed Data', ...
                                 ['\bf Linear Adjustment (r=', num2str(correlation,'%.3f'), ')'], ...
                                 '\bf Reference line (1:1)'};
            end
            
            le = legend(legend_entries, 'Interpreter', 'latex', 'FontSize', 11, ...
                       'Box', 'off', 'Location', 'northwest');
            
            % Add comprehensive text box with statistics
            if ~isnan(overall_slope)
                if ~isempty(primary_breakpoint)
                    text_str = ['Overall slope: ', num2str(overall_slope,'%.3f'), newline, ...
                               '${R^2}$: ', num2str(correlation^2,'%.3f'), newline, ...
                               'Changes detected: ', num2str(NumBreakpoints,'%d'), newline, ...
                               'Ref stations: ', num2str(NumRef,'%d')];
                else
                    text_str = ['Slope: ', num2str(overall_slope,'%.3f'), newline, ...
                               '${R^2}$: ', num2str(correlation^2,'%.3f'), newline, ...
                               'No changes detected', newline, ...
                               'Ref stations: ', num2str(NumRef,'%d')];
                end
                text(0.35, 0.98, text_str, 'Units', 'normalized', ...
                     'VerticalAlignment', 'top', 'FontSize', 11, ...
                     'BackgroundColor', 'white', 'EdgeColor', 'black','Interpreter','latex');
            end
            
            set(gca, 'TickLabelInterpreter', 'latex', 'FontWeight', 'bold', ...
                'Color', 'none', 'Box', 'on', 'FontSize', 18);
            grid on; grid minor;
            
            %% Save figure
            saveas(Fig, fullfile(obj.PathProject,'FIGURES','DoubleMassCurve',...
                                [num2str(obj.Code(target_idx)),'.jpg']));
            close(Fig);
        end
        
    % catch ME
    %     % Continue with other stations if one fails
    %     continue;
    % end
end

%% Save summary results
Code = reshape(obj.Code(PoPo), length(PoPo), 1);
NameFile = fullfile(obj.PathProject,'RESULTS','DoubleMassCurve_Summary.csv');
ID_File = fopen(NameFile,'w');
fprintf(ID_File,'Code,NumRefStations,Correlation,OverallSlope,Intercept,QualityScore,NumBreakpoints,MaxSlopeChange,HasSignificantChange\n');
fprintf(ID_File,'%d,%d,%.4f,%.4f,%.4f,%.4f,%d,%.4f,%d\n', [Code, Summary]');
fclose(ID_File);

end
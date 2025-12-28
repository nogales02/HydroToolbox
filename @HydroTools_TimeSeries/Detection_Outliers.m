function Detection_Outliers(obj, varargin)
% DETECTION_OUTLIERS Detecta valores atípicos en series de tiempo usando múltiples métodos
%
% SINTAXIS:
%   Detection_Outliers(obj)
%   Detection_Outliers(obj, 'Code', codigosEstacion)
%   Detection_Outliers(obj, 'StatusPcp', true, 'NumNeighbors', 5, 'SpatialThreshold', 0.75)
%
% PARÁMETROS DE ENTRADA:
%   obj               - Objeto HydroTools_TimeSeries
%   'Code'            - Códigos de estaciones a analizar (por defecto: todas las estaciones)
%   'StatusPcp'       - Bandera para datos de precipitación (por defecto: false)
%   'StatusQ'         - Bandera para datos de caudal (por defecto: false) 
%   'Labels'          - Etiquetas para gráficos (por defecto: {'\bf Time','\bf Data'})
%   'NumNeighbors'    - Número de estaciones vecinas para análisis espacial (por defecto: 3)
%   'SpatialThreshold'- Umbral de desviación relativa para método espacial (por defecto: 0.75)
%
% MÉTODOS DE DETECCIÓN:
%   1. MAD (Desviación Absoluta de la Mediana)
%   2. Tukey (Rango Intercuartílico)
%   3. Grubbs (Prueba de Grubbs)
%   4. GESD (Desviación Estudentizada Extrema Generalizada)
%   5. Correlación espacial con estaciones vecinas más cercanas
%
% ARCHIVOS DE SALIDA:
%   - Archivos CSV individuales con banderas de outliers en RESULTS/Outliers/
%   - Gráficos en FIGURES/Outliers/ (si obj.StatusPlot = true)
%   - Summary.csv con total de outliers por método por estación
%
% EJEMPLO:
%   % Análisis básico de todas las estaciones
%   Detection_Outliers(obj);
%
%   % Análisis de precipitación con 5 vecinos y umbral espacial del 50%
%   Detection_Outliers(obj, 'StatusPcp', true, 'NumNeighbors', 5, 'SpatialThreshold', 0.75);
%
%   % Análisis de estaciones específicas
%   codigos = [233200, 233213, 233215];
%   Detection_Outliers(obj, 'Code', codigos, 'StatusQ', true);
%
% NOTA:
%   - Para datos de precipitación use 'StatusPcp', true
%   - Para datos de caudal use 'StatusQ', true
%   - El método espacial compara cada valor con la mediana de sus vecinos más cercanos
%   - SpatialThreshold = 0.75 significa 75% de diferencia relativa para marcar outlier

%% Input validation and parsing
p = inputParser;
addRequired(p, 'obj', @(x) isstruct(x) || isobject(x));
addParameter(p, 'Code', [], @(x) isnumeric(x) || isempty(x));
addParameter(p, 'StatusPcp', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'StatusQ', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'Labels', {'\bf Time','\bf Data'}, @(x) iscell(x) && length(x)==2);
addParameter(p, 'NumNeighbors', 3, @(x) isnumeric(x) && x > 0);
addParameter(p, 'SpatialThreshold', 0.75, @(x) isnumeric(x) && x > 0);
addParameter(p, 'Algoritms', {'MAD','Tukey','Grubbs','GESD','Spatial'}, @(x) iscell(x));

parse(p, obj, varargin{:});

keySet      = {'MAD','Tukey','Grubbs','GESD','Spatial'};
valueSet    = [1, 2, 3, 4, 5];
SelectAlg   = containers.Map(keySet,valueSet);

valueSet    = {'MAD','Tukey','Grubbs','GESD','Spatial'};
keySet      = [1, 2, 3, 4, 5];
SelectAlg2  = containers.Map(keySet,valueSet);

Code_PoPo         = p.Results.Code;
StatusP           = logical(p.Results.StatusPcp);
StatusQ           = logical(p.Results.StatusQ);
NameLabel         = p.Results.Labels;
numNeighbors      = p.Results.NumNeighbors;
spatialThreshold  = p.Results.SpatialThreshold;
Tmp               = p.Results.Algoritms;

Algoritms = false(5,1);
for i = 1:numel(Tmp)
    Algoritms(SelectAlg(Tmp{i}))  = true;
end

warning('off','all');

%% Station selection
if ~isempty(Code_PoPo)
    [~, PoPo] = ismember(Code_PoPo, obj.Code);
    PoPo(PoPo == 0) = []; % Remove non-existent codes
else
    PoPo = 1:length(obj.Code);
end

%% Directory creation
mkdir(fullfile(obj.PathProject,'RESULTS','Outliers'));
mkdir(fullfile(obj.PathProject,'FIGURES','Outliers'));

% Initialize summary matrix [MAD, Tukey, Grubbs, GESD, Spatial]
Summary = NaN(length(PoPo), sum(Algoritms));

%% Pre-transform all data for spatial analysis
obj1        = copy(obj);
nStations   = length(obj.Code);
Mes         = month(obj.Date);

for i = 1:nStations
    for j = 1:12
        monthIdx = find(Mes == j);
        monthData = obj1.Data(monthIdx, i);
        
        % Apply transformation according to data type
        if StatusP
            monthData = sqrt(monthData);
        elseif StatusQ
            monthData = log(monthData);
        end
        
        % Standardize with monthly statistics
        monthMean = mean(monthData, 'omitmissing');
        monthStd  = std(monthData, 'omitmissing');
        if monthStd > 0
            obj1.Data(monthIdx, i) = (monthData - monthMean) / monthStd;
        else
            obj1.Data(monthIdx, i) = NaN;
        end
    end
end

%% Pre-calculate distances between all stations
distanceMatrix = NaN(nStations, nStations);
for i = 1:nStations
    for j = 1:nStations
        if i ~= j
            distanceMatrix(i,j) = sqrt((obj.X(i) - obj.X(j))^2 + (obj.Y(i) - obj.Y(j))^2);
        end
    end
end

%% Main processing loop
for ii = 1:length(PoPo)
    try
        % Data extraction and preparation
        id          = find(~isnan(obj.Data(:,PoPo(ii))));
        Data        = obj.Data(:,PoPo(ii));
        Date        = obj.Date;
        DateReal    = obj.Date(id(1):id(end));
                
        % Handle zero values for precipitation data
        idZ = [];
        if StatusP
            idZ = Data == 0;
            Data(idZ) = NaN;
        end
        
        % Monthly processing setup
        DataOutliers = zeros(length(Data), sum(Algoritms));        

        %% Monthly outlier detection
        for j = 1:12
            % Indicador de algoritmo
            kp = 1;

            Posi    = find((Mes == j)&(~isnan(Data)));
            % Posi = find(Mes >= j);
            Tmp     = Data(Posi);
            Tmp1    = Data(Posi);

            % Data transformation
            if StatusP
                Tmp = log1p(Tmp);
                Tmp = (Tmp - mean(Tmp,'omitmissing')) / std(Tmp,'omitmissing');
            elseif StatusQ
                Tmp = log1p(Tmp);
                Tmp = (Tmp - mean(Tmp,'omitmissing')) / std(Tmp,'omitmissing');
            end
            
            % Method 1: MAD (Median Absolute Deviation)
            if Algoritms(1)
                try
                    TF = isoutlier(Tmp, 'median');
                    DataOutliers(Posi, kp) = TF;
                catch
                    % Skip if insufficient data
                end
                kp = kp + 1;
            end
            
            % Method 2: Tukey (Interquartile Range)
            if Algoritms(2)
                D25     = quantile(Tmp, 0.25);
                D75     = quantile(Tmp, 0.75);
                RIC     = 1.5 * (D75 - D25);
                % if StatusP
                %     RIC     = 3 * (D75 - D25);
                % else
                %     RIC     = 1.5 * (D75 - D25);
                % end
                OutMin  = D25 - RIC;
                OutMax  = D75 + RIC;
                TF      = (Tmp <= OutMin) | (Tmp >= OutMax);
                DataOutliers(Posi, kp) = TF;
                kp = kp + 1;
            end

            % Method 3: Grubbs test
            if Algoritms(3)
                try
                    TF = isoutlier(Tmp, 'grubbs');
                    DataOutliers(Posi, kp) = TF;
                catch
                    % Skip if insufficient data
                end
                kp = kp + 1;
            end
            
            % Method 4: GESD (Generalized Extreme Studentized Deviate)
            if Algoritms(4)
                try
                    TF = isoutlier(Tmp, 'gesd');
                    DataOutliers(Posi, kp) = TF;
                catch
                    % Skip if insufficient data
                end
                kp = kp + 1;
            end
            
            % Method 5: Spatial correlation check
            if Algoritms(5)
                try
                    currentStationIdx   = PoPo(ii);
                    distances           = distanceMatrix(currentStationIdx, :);
                    [~, sortedIdx]      = sort(distances);
                    
                    for k = 1:length(Posi)                    
                        dayIdx = Posi(k);
                        if isnan(Tmp1(k))
                            DataOutliers(dayIdx, kp) = 0;
                            continue
                        end
                        if ~isnan(obj.Data(dayIdx, currentStationIdx))
                            
                            % Find numNeighbors nearest stations with valid data on this day
                            nearestStations = [];
                            for s = 1:nStations
                                stationIdx = sortedIdx(s);
                                if stationIdx ~= currentStationIdx && ~isnan(obj.Data(dayIdx, stationIdx))
                                    nearestStations(end+1) = stationIdx;
                                    if length(nearestStations) == numNeighbors
                                        break;
                                    end
                                end
                            end
                            
                            % Check outlier if we have enough neighbors
                            if length(nearestStations) == numNeighbors
                                % Use pre-transformed data from obj1
                                neighborValues = obj.Data(dayIdx, nearestStations);
                                currentTransformed = Tmp1(k);
                                
                                % Apply spatial threshold criterion
                                medianNeighbor = median(neighborValues);
                                
                                if abs(medianNeighbor) > 0.01
                                    relativeDiff = abs(currentTransformed - medianNeighbor) / abs(medianNeighbor);
                                    if relativeDiff > spatialThreshold
                                        DataOutliers(dayIdx, kp) = 1;
                                    end
                                else
                                    % When median is near zero, use absolute difference
                                    if abs(currentTransformed - medianNeighbor) > 10
                                        DataOutliers(dayIdx, kp) = 1;
                                    end
                                end
                            end
                        end
                    end
                    kp = kp + 1;
                catch
                    % Skip spatial analysis if error occurs
                end
            end
        end
        
        % Restore zero values for precipitation data
        if StatusP && ~isempty(idZ)
            Data(idZ) = 0;
        end
        
        %% Save individual results
        NameFile = fullfile(obj.PathProject,'RESULTS','Outliers',...
                           [num2str(obj.Code(PoPo(ii))),'.csv']);
        ID_File = fopen(NameFile, 'w');
        popo = find(Algoritms);
        co = 1;
        for ij = 1:numel(popo)
            if co == 1
                fprintf(ID_File, SelectAlg2(popo(ij)));
            else
                fprintf(ID_File, [',',SelectAlg2(popo(ij))]);
            end
            co = co + 1;
        end
        fprintf(ID_File, ',Total\n');
        fprintf(ID_File, ['%d',repmat(',%d',1,sum(Algoritms)),'\n'], ...
                [DataOutliers, all(DataOutliers,2)]');
        fclose(ID_File);
        
        % Update summary statistics
        Summary(ii,:) = sum(DataOutliers);
        
        %% Generate plots if enabled
        if obj.StatusPlot
            Fig = figure('color', [1 1 1], 'Visible', 'off');
            T = [16, 7];
            set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T], ...
                'Position', [0, 0, T], 'PaperUnits', 'Inches', ...
                'PaperSize', T, 'PaperType', 'usletter');
            
            % Plot time series
            plot(Date, Data, 'Color', [0.8 0.8 0.8], 'LineWidth', 1);
            hold on;
            
            % Plot outliers by method
            Mar = {'*', 'o', '+', '.', 'x'};
            Col = {'r', 'b', 'k', 'g', 'm'};
            for i = 1:numel(popo)
                idx = DataOutliers(:,i) == 1;
                if any(idx)
                    plot(Date(idx), Data(idx), 'Marker', Mar{popo(i)}, ...
                         'MarkerEdgeColor', Col{popo(i)}, 'LineStyle', 'none', ...
                         'MarkerSize', 6);
                end
            end
            
            % Plot consensus outliers (detected by all methods)
            consensus_idx = all(DataOutliers, 2);
            if any(consensus_idx)
                plot(Date(consensus_idx), Data(consensus_idx), ...
                     'Marker', '.', 'MarkerEdgeColor', 'k', ...
                     'LineStyle', 'none', 'MarkerSize', 20);
            end
            
            % Formatting
            xlabel(NameLabel{1}, 'Interpreter', 'latex', 'FontSize', 20);
            ylabel(NameLabel{2}, 'Interpreter', 'latex', 'FontSize', 20);
            set(gca, 'TickLabelInterpreter', 'latex', 'FontWeight', 'bold', ...
                'Color', 'none', 'Box', 'off', 'FontSize', 18, 'LineWidth', 2);
            
            % Dynamic legend creation
            legend_entries = {'\bf Time Series'};
            method_names = {'\bf MAD', '\bf Tukey', '\bf Grubbs', '\bf GESD', '\bf Spatial'};
            for i = 1:sum(Algoritms)
                if sum(DataOutliers(:,i)) > 0
                    legend_entries{end+1} = method_names{popo(i)};
                end
            end
            if any(consensus_idx)
                legend_entries{end+1} = '\bf Consensus Outlier';
            end
            
            le = legend(legend_entries, 'Interpreter', 'latex', ...
                       'FontSize', 14, 'Box', 'off', 'Color', 'none');
            xlim([DateReal(1), DateReal(end)]);
            
            % Save figure
            saveas(Fig, fullfile(obj.PathProject,'FIGURES','Outliers',...
                                [num2str(obj.Code(PoPo(ii))),'.jpg']));
            close(Fig);
        end
        
        %% Display progress
        disp([num2str((ii/length(PoPo))*100 ,'%2f'),'% Outliers Detection ',num2str(obj.Code(PoPo(ii)),'%d'), ' -> Ok'])
        
    catch ME
        disp([num2str((ii/length(PoPo))*100 ,'%2f'),'% Outliers Detection ',num2str(obj.Code(PoPo(ii)),'%d'), ' -> Error'])
        % Continue processing other stations if one fails
        continue;
    end
end

%% Save summary results
Code = reshape(obj.Code(PoPo), length(PoPo), 1);
NameFile = fullfile(obj.PathProject,'RESULTS','Outliers','Summary.csv');
ID_File = fopen(NameFile, 'w');
fprintf(ID_File, 'Code');
for ij = 1:numel(popo)
    fprintf(ID_File, [',',SelectAlg2(popo(ij))]);
end
fprintf(ID_File, '\n');
% fprintf(ID_File, 'Code,MAD,Tukey,Grubbs,GESD,Spatial\n');
fprintf(ID_File, ['%f',repmat(',%d',1,numel(popo)),'\n'], [Code, Summary]');
fclose(ID_File);

warning('on','all');

end
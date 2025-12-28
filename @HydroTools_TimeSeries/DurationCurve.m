function [PQ, Qsort, Porcentaje, DataQ] = DurationCurve(obj, varargin)
% DURATIONCURVE Genera curvas de duración de caudales con análisis estadístico
%
% SYNTAX:
%   [PQ, Qsort, Porcentaje, DataQ] = DurationCurve(obj)
%   [PQ, Qsort, Porcentaje, DataQ] = DurationCurve(obj, StationCodes)
%   [PQ, Qsort, Porcentaje, DataQ] = DurationCurve(obj, StationCodes, YLabel)
%   [PQ, Qsort, Porcentaje, DataQ] = DurationCurve(obj, 'Verbose', true)
%   [PQ, Qsort, Porcentaje, DataQ] = DurationCurve(obj, 'SaveFigures', false)
%
% DESCRIPTION:
%   Esta función calcula y visualiza curvas de duración de caudales, mostrando
%   la frecuencia de excedencia de diferentes valores. Incluye análisis estadístico
%   con percentiles, histograma y boxplot.
%
% INPUT PARAMETERS:
%   obj        - [HydroTools_TimeSeries] Objeto con datos de series de tiempo que debe contener:
%                * Date: [datetime array] Vector de fechas
%                * Data: [double matrix] Matriz de datos (filas=tiempo, columnas=estaciones)
%                * Code: [numeric array] Códigos numéricos de identificación de estaciones
%                * PathProject: [char] Ruta del proyecto para guardar figuras
%
% OPTIONAL PARAMETERS:
%   StationCodes - [numeric array, default: []] Códigos numéricos de estaciones específicas
%   YLabel       - [char, default: '\bf Caudal ${\bf (m^3/seg)}$'] Etiqueta del eje Y
%   'Verbose'    - [logical, default: false] Muestra información detallada
%   'SaveFigures'- [logical, default: true] Guarda figuras en disco
%
% OUTPUT PARAMETERS:
%   PQ         - [cell array] Probabilidades de excedencia para cada estación
%   Qsort      - [cell array] Datos ordenados de mayor a menor para cada estación  
%   Porcentaje - [double array] Percentiles calculados [1 5 10 50 75 95]
%   DataQ      - [cell array] Valores de caudal para cada percentil por estación
%
% EXAMPLES:
%   % Curva de duración básica
%   [PQ, Qsort, Perc, Values] = DurationCurve(obj);
%   
%   % Para estaciones específicas
%   codes = [233200, 233213, 233215];
%   [PQ, Qsort, Perc, Values] = DurationCurve(obj, codes);
%   
%   % Con información detallada
%   DurationCurve(obj, 'Verbose', true, 'SaveFigures', false);
%
% SEE ALSO:
%   histogram, boxplot, interp1, area
%
% -------------------------------------------------------------------------
% Matlab - R2024b y versiones superiores
% -------------------------------------------------------------------------
%                           Información del Autor
%--------------------------------------------------------------------------
% Autor Original: Jonathan Nogales Pimentel (The Nature Conservancy - TNC)
% Email         : jonathannogales02@gmail.com
% Versión       : 2.0 - Simplificada bajo filosofía "simple es mejor"
% Fecha         : 2025
%--------------------------------------------------------------------------

    % =====================================================================
    % PARSING SIMPLE DE PARÁMETROS 
    % =====================================================================
    
    % Crear inputParser básico
    p = inputParser;
    p.KeepUnmatched = false;
    
    % Validaciones simples
    addRequired(p, 'obj', @isobject);
    addOptional(p, 'StationCodes', [], @(x) isempty(x) || isnumeric(x));
    addOptional(p, 'YLabel', '\bf Caudal ${\bf (m^3/seg)}$', @ischar);
    addParameter(p, 'Verbose', false, @islogical);
    addParameter(p, 'SaveFigures', true, @islogical);
    
    parse(p, obj, varargin{:});
    
    % Extraer parámetros
    stationCodes = p.Results.StationCodes;
    yLabel = p.Results.YLabel;
    verbose = p.Results.Verbose;
    saveFigures = p.Results.SaveFigures;
    
    % =====================================================================
    % PROCESAMIENTO DE ESTACIONES
    % =====================================================================
    
    if ~isempty(stationCodes)
        [~, stationIdx] = ismember(stationCodes, obj.Code);
    else
        stationIdx = 1:length(obj.Code);
    end
    
    nStations = length(stationIdx);
    
    if verbose
        fprintf('\n=== CURVAS DE DURACIÓN ===\n');
        fprintf('Estaciones: %d\n', nStations);
        fprintf('=========================\n');
    end
    
    % =====================================================================
    % CREAR CARPETA
    % =====================================================================
    
    if saveFigures && isprop(obj, 'PathProject')
        mkdir(fullfile(obj.PathProject,'FIGURES','DurationCurve'));
    end
    
    % =====================================================================
    % INICIALIZAR SALIDAS
    % =====================================================================
    
    PQ          = cell(nStations, 1);
    Qsort       = cell(nStations, 1);
    DataQ       = cell(nStations, 1);
    Porcentaje  = [1 5 10 50 75 95];
    
    % =====================================================================
    % PROCESAMIENTO POR ESTACIÓN
    % =====================================================================
    
    for ii = 1:nStations
        
        currentIdx = stationIdx(ii);
        
        if verbose
            fprintf('Procesando estación %d/%d: %s\n', ii, nStations, string(obj.Code(currentIdx)));
        end
        
        % Input Data
        validData = find(~isnan(obj.Data(:,currentIdx)));
        Q = obj.Data(validData(1):validData(end),currentIdx);
        
        % Cálculo de curva de duración
        [Por_Q,Qd] = hist(Q,length(unique(Q)));
        [QsortCurrent, id] = sort(Qd, 'descend');
        PQCurrent = (cumsum(Por_Q(id))/sum(Por_Q(id)))*100;
        [~, uniqueIdx] = unique(PQCurrent);
        
        % Almacenar resultados
        PQ{ii} = PQCurrent;
        Qsort{ii} = QsortCurrent;
        DataQ{ii} = interp1(PQCurrent(uniqueIdx), QsortCurrent(uniqueIdx), Porcentaje);
        
        % ================================================================= 
        % CREAR FIGURA
        % ================================================================= 
        
        Fig = figure('color',[1 1 1], 'Visible','off');
        T = [15, 8];
        set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
            [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','e');

        subplot(1,20,1:17);
        h = area(PQCurrent, QsortCurrent);
        h.FaceColor = 'y';
        h.FaceAlpha = 0.5;
        hold on;
        plot(PQCurrent, QsortCurrent,'k','Linewidth',2);
        axis([0 100 0 (max(QsortCurrent) + (0.1*max(QsortCurrent)))]);
        xlabel('\bf Frecuency (\%)', 'interpreter', 'latex','fontsize',25);
        ylabel(yLabel, 'interpreter', 'latex', 'fontsize',25);
        set(gca,'TickLabelInterpreter','latex', 'fontsize',22);

        ly = 0.95:-0.05:0.9 -(0.05*(length(DataQ{ii})-1));
        plot(Porcentaje,DataQ{ii}, 'r*');
        plot(Porcentaje,DataQ{ii}, 'ro');
        for i = 1:length(Porcentaje)
            text(20 ,(ly(i)*(max(QsortCurrent) + (0.1*max(QsortCurrent)))), ...
                ['\bf Value',num2str(Porcentaje(i),'%0.0f'),' = ', num2str(DataQ{ii}(i),'%0.2f')], 'interpreter', 'latex', 'fontsize',15);
        end

        subplot(1,20,19:20);
        boxplot(Q, 'PlotStyle','compact');
        set(gca,'XTick',1,'XTickLabel','\bf Boxplot', 'TickLabelInterpreter','latex', 'fontsize',20);

        axes('Position',[0.46 0.58 0.3 0.3]);
        h = histogram(Q);
        h.FaceColor = [0 0.75 0.75];
        h.FaceAlpha = 0.5;
        h.EdgeColor = [0 0.5 0.5];
        set(gca,'TickLabelInterpreter','latex', 'fontsize',16);
        ylabel('\bf Frecuency', 'interpreter', 'latex','fontsize',20);
        xlabel(yLabel, 'interpreter', 'latex', 'fontsize',20);

        % Guardar figura
        if saveFigures && isprop(obj, 'PathProject')
            saveas(Fig, fullfile(obj.PathProject,'FIGURES','DurationCurve',[num2str(obj.Code(currentIdx)),'.jpg']));
        end
        close(Fig);
    end
    
    if verbose
        fprintf('Procesamiento completado.\n\n');
    end

end
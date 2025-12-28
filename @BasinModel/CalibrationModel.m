function CalibrationModel(Basin)
% -------------------------------------------------------------------------
% Programado en Matlab - R2019b 
% -------------------------------------------------------------------------
%                           Informaciï¿½n Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Fecha         : 01-Enero-2019
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los términos de la licencia publica general GNU. El autor no se 
% hace responsable de los usos que pueda tener. Para mayor información 
% revisar http://www.gnu.org/licenses/
%
% -------------------------------------------------------------------------
% Descripciï¿½n del Codigo
% -------------------------------------------------------------------------
% 
% -------------------------------------------------------------------------
% Input Data
% -------------------------------------------------------------------------
% 
% -------------------------------------------------------------------------
% Output Data
% -------------------------------------------------------------------------
%

% -------------------------------------------------------------------------
% Crear carpetas de calibración
% -------------------------------------------------------------------------
mkdir(fullfile(Basin.PathProject,'OUTPUTS','Best-Parameters',Basin.OptMethod))
mkdir(fullfile(Basin.PathProject,'OUTPUTS','AllEvals',Basin.OptMethod))
mkdir(fullfile(Basin.PathProject,'FIGURES','Calibration',Basin.OptMethod))
mkdir(fullfile(Basin.PathProject,'FIGURES','Validation',Basin.OptMethod))
mkdir(fullfile(Basin.PathProject,'OUTPUTS','Variables'))

% -------------------------------------------------------------------------
% Estimación de la jerarquia de las estaciones de calibración
% -------------------------------------------------------------------------
Choco = double(Basin.GaugesCal ~=0);
Basin.AccumVar = Choco;
Basin.AnalysisNetwork_Obj;
Basin.CatGauges = Basin.AccumVar;

% -------------------------------------------------------------------------
% Lista de estaciones de calibración
% -------------------------------------------------------------------------
Basin.CatGauges = Basin.CatGauges.*Choco;
NumberCat       = unique(Basin.CatGauges(Basin.CatGauges>0));

% -------------------------------------------------------------------------
% Inicialización de array para determinar las cuencas calibradas
% -------------------------------------------------------------------------
PoPo    = zeros(length(Basin.Code),1); 
PoPoID  = PoPo;

% -------------------------------------------------------------------------
% Array de metricas de calibración
% -------------------------------------------------------------------------
SummaryCal  = NaN(length(Basin.GaugesID), 22);
SummaryVal  = NaN(length(Basin.GaugesID), 22);

for i = 1:length(NumberCat)
    % -----------------------------------------------------------------
    % Selcción de los puntos de calibración de jerarquia i 
    % -----------------------------------------------------------------
    id = find(Basin.CatGauges == NumberCat(i) );    

    for j = 1:length(id)
        % -----------------------------------------------------------------
        % Selección de la estación de calibración j de la jerarquia i
        % -----------------------------------------------------------------
        Basin.CodeQobs          = Basin.GaugesCal(id(j));
        
        % -----------------------------------------------------------------
        % Asignar RiverMouth hasta el arco de la estación j de la jerarquia i    
        % -----------------------------------------------------------------
        Basin.RiverMouth        = Basin.Code(id(j));
        
        % -----------------------------------------------------------------
        % Selección de tramos de red que confluyen a la estación j de la 
        % jerarquia i
        % -----------------------------------------------------------------
        Basin.AccumVar          = []; 
        [Tmp,PoPo]              = Basin.AnalysisNetwork_Obj;
        
        % -----------------------------------------------------------------
        % Inicialización de un array para saber cuales cuencas se han
        % calibrado
        % -----------------------------------------------------------------
        PoPoID                  = (PoPoID + PoPo);
        Basin.IDPoPo            = logical((PoPoID  == 1).*PoPo);
        Basin.PoPo              = logical(PoPo);
        
        disp([num2str(sum(Basin.PoPo~=0)),' - ',num2str(sum(Basin.IDPoPo~=0))])

        % -----------------------------------------------------------------
        % Asiganción del codigo de estación j en el array de metricas
        % -----------------------------------------------------------------
        SummaryCal(j,1)         = Basin.CodeQobs;
        SummaryVal(j,1)         = Basin.CodeQobs;
        
        % -----------------------------------------------------------------
        % Crear carpeta para guardar caudales simulados con los parámetros
        % evaluados
        % -----------------------------------------------------------------
        mkdir(fullfile(Basin.PathProject, 'OUTPUTS','AllQsim',Basin.OptMethod,...
                num2str(Basin.CodeQobs)))

        % -----------------------------------------------------------------
        % Optimización matematica
        % -----------------------------------------------------------------
        % LHS
        global count
        count = 1;
        if strcmp(Basin.OptMethod,'LHS')
            [Param, Bestf, allbest, allEvals] = Basin.Opt_LHS;    
        elseif strcmp(Basin.OptMethod,'DDS')              
            [Param, Bestf, allbest, allEvals] = Basin.Opt_DDS;
        elseif strcmp(Basin.OptMethod,'Load')                    
            load(fullfile(Basin.PathProject, 'OUTPUTS','AllEvals',Basin.OptMethod,[num2str(Basin.CodeQobs),'.mat']))
        end
        
%         %{
        % -----------------------------------------------------------------
        % Save mat 
        % -----------------------------------------------------------------
        save( fullfile(Basin.PathProject, 'OUTPUTS','AllEvals',Basin.OptMethod,...
                        [num2str(Basin.CodeQobs),'.mat']),...
                        'Param', 'Bestf', 'allbest', 'allEvals')
        
        % -----------------------------------------------------------------
        % Guardar Datos
        % -----------------------------------------------------------------
        % Update Parameters table
        NameParams = 'Trp (Porc),Tpr (Porc),Q_Umb (mm), V_Umb (mm)';
        FormatFile = '%f,%f,%f,%f';
        for ki = 1:length(Param(5:end))
            NameParams = [NameParams,',Params-',num2str(ki)];
            FormatFile = [FormatFile,',%f'];
        end
        NameParams = [NameParams,'\n'];
                
        fileID = fopen( fullfile(Basin.PathProject, 'OUTPUTS','Best-Parameters',Basin.OptMethod,...
                        [num2str(Basin.CodeQobs),'.csv']),'w');
        fprintf(fileID,NameParams);
        fprintf(fileID,FormatFile,Param);
        fclose(fileID);        
        
        % -----------------------------------------------------------------
        % Guardar todas las evaluaciones
        % -----------------------------------------------------------------
        % Update Parameters table        
        NameParams = 'Trp (Porc),Tpr (Porc),Q_Umb (mm), V_Umb (mm)';
        FormatFile = '%f,%f,%f,%f';
        for ki = 1:length(Param(5:end))
            NameParams = [NameParams,',Params-',num2str(ki)];
            FormatFile = [FormatFile,',%f'];
        end
        FormatFile = [FormatFile,',%f\n'];
        NameParams = [NameParams,',',Basin.CalMetricSelect,'\n'];
        
        fileID = fopen( fullfile(Basin.PathProject, 'OUTPUTS','AllEvals',Basin.OptMethod,...
                        [num2str(Basin.CodeQobs),'.csv']),'w');
        fprintf(fileID,NameParams);
        fprintf(fileID,FormatFile,allEvals');
        fclose(fileID);
        
        disp(['Calibración Ok -> ', num2str(Basin.CodeQobs)])
        
        % -----------------------------------------------------------------
        % Asignacion de parametros 
        % -----------------------------------------------------------------
        % Asignación de parametros de planicies inundables
        IDPoPo_tmp = Basin.IDPoPo;
        IDPoPo_tmp(~isnan(Basin.ParamsFloodCal(:,1))) = false;
        if sum(IDPoPo_tmp) > 0
            Basin.ParamsFloodCal(IDPoPo_tmp,:) = repmat(Param(1:4),sum(IDPoPo_tmp),1);
        end
        
        % Asignación de paramteros de la cuenca
        for jii = 1:length(Param(5:end))
            IDPoPo_tmp = Basin.IDPoPo;
            IDPoPo_tmp(~isnan(Basin.ParamsBasinCal(:,jii))) = false;
            if sum(IDPoPo_tmp) > 0
                Basin.ParamsBasinCal(IDPoPo_tmp,jii) = repmat(Param(4 + jii),sum(IDPoPo_tmp),1);
            end
        end
        
        % Asignación de paramteros a la matriz de parametros finales
        Basin.ParamsBasin = Basin.ParamsBasinCal;
        Basin.ParamsFlood = Basin.ParamsFloodCal;
        %}
        
        % -----------------------------------------------------------------
        % Grafica de calibración
        % -----------------------------------------------------------------
        id1         = Basin.GaugesID == Basin.CodeQobs;
        DateInit    = find(Basin.Date == Basin.DateCal_Init(id1));
        DateEnd     = find(Basin.Date == Basin.DateCal_End(id1));  
        [Fig, SummaryCal(j,2:end)] = Basin.Plot_Eval_Model(DateInit, DateEnd);        
        
        % Guardar grafica de calibración
        saveas(Fig, fullfile(Basin.PathProject,'FIGURES','Calibration',Basin.OptMethod, ...
            ['Calibration-',num2str(Basin.CodeQobs),'.jpg']))
        
        disp(['Plot Time Series Calibración Ok -> ', num2str(Basin.CodeQobs)])
        
        % -----------------------------------------------------------------
        % Grafica de validación
        % -----------------------------------------------------------------
        DateInit    = find(Basin.Date == Basin.DateVal_Init(id1));
        DateEnd     = find(Basin.Date == Basin.DateVal_End(id1));
        [Fig, SummaryVal(j,2:end)] = Basin.Plot_Eval_Model(DateInit, DateEnd);
        
        % Guardar grafica de validación
        saveas(Fig, fullfile(Basin.PathProject,'FIGURES','Validation',Basin.OptMethod, ...
            ['Validation-',num2str(Basin.CodeQobs),'.jpg']))
        
        disp(['Plot Time Series Validación Ok -> ', num2str(Basin.CodeQobs)])    

        % -----------------------------------------------------------------
        % Organizar datos para análisis de incertidumbre
        % ----------------------------------------------------------------- 
%         %{
        if strcmp(Basin.OptMethod,'LHS')
            Results.Code = (1:Basin.maxIter)'; 
            for ji = 1:Basin.maxIter
                Data = readmatrix(fullfile(Basin.PathProject, 'OUTPUTS','AllQsim',Basin.OptMethod,...
                    num2str(Basin.CodeQobs),['Qsim_',num2str(Basin.CodeQobs),'_',num2str(ji),'.csv']));
        
                if ji == 1
                    Results.Data = NaN(length(Data(:,1)),Basin.maxIter);
                end
                Results.Data(:,ji) = Data(:,4);
                
            end        
            Results.Date = datetime(Data(:,1:3));
            save(fullfile(Basin.PathProject, 'OUTPUTS','AllQsim',Basin.OptMethod,[num2str(Basin.CodeQobs),'.mat']),'Results');
        end
        %}
    end    
    
    % -----------------------------------------------------------------
    % Asignación nuevamente el rivermouth de la cuenca
    % -----------------------------------------------------------------
    Basin.RiverMouth     = Basin.RiverMouthBasin;
    
    % ---------------------------------------------------------------------
    % Guardar parametros finales
    % ---------------------------------------------------------------------
    %% Save Calibration Metric
    NameParamsR = 'Code Gauges,Nash,AME,PDIFF,MAE,MSE,RMSE,R4MS4E,RAE,PEP,MARE,MRE,MSRE,PBIAS,R,CE,PBE,AARE,TS1,TS25,TS50,TS100\n';

    fileID = fopen( fullfile(Basin.PathProject, 'OUTPUTS',['Calibration_Metric_',Basin.OptMethod,'.csv']),'w');
    Format = '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n';
    fprintf(fileID,NameParamsR);
    fprintf(fileID,Format,SummaryCal');
    fclose(fileID);
    
    %% Save Validation Metric
    NameParamsR = 'Code Gauges,Nash,AME,PDIFF,MAE,MSE,RMSE,R4MS4E,RAE,PEP,MARE,MRE,MSRE,PBIAS,R,CE,PBE,AARE,TS1,TS25,TS50,TS100\n';

    fileID = fopen( fullfile(Basin.PathProject, 'OUTPUTS',['Validation_Metric_',Basin.OptMethod,'.csv']),'w');
    Format = '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n';
    fprintf(fileID,NameParamsR);
    fprintf(fileID,Format,SummaryVal');
    fclose(fileID);
    
end

%% Asignar parámetros 
if sum(Basin.GroupCal) > 0
    Code    = unique(Basin.GroupCal);
    Code(Code == 0) = [];
    for i = 1:length(Code)
        % Parámetros de planicies inundables
        if Basin.Status_ModelFlood
            Basin.ParamsFlood(Basin.GroupCal == Code(i),:) = Basin.ParamsFlood(Basin.Code == Code(i),:);
        end
        % Parámetros de unidades de modelación
        Jo = sum(Basin.GroupCal == Code(i));
        Basin.ParamsBasin(Basin.GroupCal == Code(i),:) = repmat(Basin.ParamsBasin(Basin.Code == Code(i),:),Jo,1);
    end
end   

% -----------------------------------------------------------------
% Guardar tabla de parametros
% -----------------------------------------------------------------
% Update Parameters table        
NameParams = ['Code,FromNode,ToNode,BasinArea (m2),FloodplainsArea (m2),',...
    'RiverMouth,GaugesCalibration,GroupCal,Similary_Params,ID_Demand,ID_',...
    'Returns,Trp (Porc),Tpr (Porc),Q_Umb (mm), V_Umb (mm)'];
FormatFile = '%d,%d,%d,%f,%f,%d,%f,%f,%f,%f,%f,%f,%f,%f,%f';
for ki = 1:length(Basin.ParamsBasin(1,:))
    NameParams = [NameParams,',X',num2str(ki)];
    FormatFile = [FormatFile,',%f'];
end
FormatFile = [FormatFile,'\n'];

fileID = fopen( fullfile(Basin.PathProject, 'OUTPUTS',['2_Parameters_',Basin.OptMethod,'.csv']),'w');
fprintf(fileID,NameParams);
fprintf(fileID,'\n');
fprintf(fileID,FormatFile,[Basin.Code,Basin.FromNode,Basin.ToNode,Basin.BasinArea, ...
    Basin.FloodArea,sum(Basin.Code == Basin.RiverMouth',2),Basin.GaugesCal,Basin.GroupCal,...
    zeros(size(Basin.Code)),Basin.ID_Demand,Basin.ID_Return,Basin.ParamsFlood Basin.ParamsBasin]');
fclose(fileID);

%% Ejecutar modelo calibrado
Basin.IDPoPo    = true(size(Basin.Code)); 
Basin.PoPo      = Basin.IDPoPo;
if strcmp(Basin.NameModel,'GR4J')
    Basin.GR4J;
elseif strcmp(Basin.NameModel,'Thomas')
    Basin.Thomas;
end  

% Acumular caudales en la red
Basin.AccumVar  = Basin.Qsim';
Basin.AnalysisNetwork_Obj;
Basin.Qsim      = Basin.AccumVar';
Basin.AccumVar  = [];
% obligatorio para que funcione como serie
Basin.Data      = Basin.Qsim;

%% Save Model
save(fullfile(Basin.PathProject,['CalibrationModel_',Basin.OptMethod,'.mat']),'Basin')

%% Guardar Resultados
if length(Basin.Code) > 5000
    NameFile    = fullfile(Basin.PathProject,'OUTPUTS','Variables','Qsim.mat');
    Tmp         = matfile(NameFile,'Writable',true);
    Tmp.Code    = Basin.Code;
    Tmp.Date    = Basin.Date;
    Tmp.Qsim    = Qsim;
    Tmp.info    = 'Caudal medio diario (m3/s)';
else                
    NameFile        = fullfile(Basin.PathProject,'OUTPUTS','Variables',['Qsim_Accum_Calibration_',Basin.OptMethod,'.csv']);
    Basin.Var       = 'Caudal medio diario (m3/s)';
    Basin.Unit      = '(m3/s)';
    Basin.EPSG      = 'CTM12';
    Basin.Source    = 'Modelación Hidrológica - GR4J';
    Basin.WriteData(NameFile);
end
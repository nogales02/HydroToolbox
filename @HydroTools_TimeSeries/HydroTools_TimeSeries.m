classdef HydroTools_TimeSeries < ClassNetwork&matlab.mixin.Copyable
% -------------------------------------------------------------------------
% Matlab - R2019b 
% -------------------------------------------------------------------------
%                           Información Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los términos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener.Para mayor información revisar 
% http://www.gnu.org/licenses/.
%
% -------------------------------------------------------------------------
% Descripción del código
% -------------------------------------------------------------------------
% Este código permite construir campos por las metodologías de Kriging 
% ordinario, IDW y regresiones lineales múltiples (por elevación). La salida 
% se expresa en archivos rasters. Sin embargo, dado que Matlab no permite 
% asignar valores nulos, se utiliza un código en Python para realizar esta 
% asignación. En este orden de ideas, es necesario configurar un ambiente 
% Python de la siguiente manera:
%       conda create --name Matlab python=3.7
%       conda activate Matlab
%       conda install -c conda-forge gdal=2.4.4
%       conda install -c conda-forge rasterio
%
% -------------------------------------------------------------------------
% Descripción
% -------------------------------------------------------------------------
% Esta clase es para el tratameinto de series de tiempo

    %% Library
    properties
        % Path Project
        PathProject char
        % Status Plot
        StatusPlot logical = true        
    end
        
    %% Time Series
    properties
        % Variable
        Var char
        % Unit
        Unit char
        % Source
        Source char
        % No Value
        NoValue double
        % EPSG        
        EPSG
        % Name
        Name cell
        % Type
        Type cell                
        % Longitude
        Longitude
        % Latitude
        Latitude
        % Coordinate X
        X 
        % Coordinate Y
        Y 
        % Elevation
        Z
        % Date
        Date datetime
        % Data
        Data       
        % dt (days)
        dt string
    end
    
    %% Intanciar Variable
    methods
        %% TimeSeries
        function obj = HydroTools_TimeSeries(varargin)
            
            if nargin == 1
                % Path Project
                obj.PathProject = PathProject;

                % Check Folder 
                if ~exist(PathProject,'dir')
                    mkdir(PathProject)
                end
            end
            
            if nargin > 1
                % NameFile
                NameFile  = varargin{1};
            
                if ischar(NameFile) || isstring(NameFile)                 
                    % Read Data
                    obj             = obj.ReadData(NameFile);
                    % Delta time
                    obj.dt          = obj.Date(2) - obj.Date(1); 
                else
                    error('Path information system')
                end   
            end
        end
        
    end
    
    %% Funciones
    methods
        %% Colors
        c = ColorsF(obj, colorname)                
        
        %% Leer Sistema de Información
        obj = ReadData(obj, NameFile, varargin)
        
        %% Escribir Sistema de Información
        WriteData(obj, NameFile, varargin)
        
        %% Agregación Temporal
        AggregationData(obj, Resolution, Type, varargin)
        
        %% Clip de Sistema de Información
        Clipping_InfoSystem(obj, PathWindows) 
        
        %% Grafica de vacios del Sistema de Información
        Plot_SummaryDataEmpty(obj, varargin)
        
        %% Detección de datos Outliers
        Remove_Seasonal_Components(obj, varargin)
        Detection_Outliers(obj, varargin)
        
        %% Resumen Estadistico de Series
        [Summary, Sdate] = Summary(obj, varargin)
        
        %% Teleconexiones
        Teleconexiones(obj,ENSO_Index,varargin)
        
        %% Download ENSO Index
        IndexResults = Download_ENSO_Index(obj, varargin)
        
        %% Integration
        IntegrationMonthly(obj, varargin)                                           
        
        %% Time Series 1
        TextureTimeSeries_1(obj,varargin);
        
        %% Time Series 2
        Fig = TextureTimeSeries_2(obj,varargin);
        
        %% Mass Curves
        MassCurve(obj, varargin)
        DoubleMassCurve(obj, varargin)
        
        %% Boxplot
        
        %% Duration Curves
        [PQ, Qsort, Porcentaje, DataQ] = DurationCurve(obj, varargin);
        
        %% IDF
        
        %% Fitting PDF
        [Mejorpdf, Error, NamePDF] = Settings_PDF_TimeSeries(obj, varargin)
        [Mejorpdf, Error, NamePDF, Fig] = Settings_PDF_1(obj,Data,varargin)
        
        %% AMI
        [v,lag] = ami(obj, Code, varargin)
        [v,lag] = Auto_Ami(obj, varargin)
        
        %% Covariogram - Integral Scale
        Iw = Integral_Scale(obj, varargin)
        
        %% Correlogram
        
        %% Semivarigrams 
        Semivariogram_Temporal(obj, varargin)
        Semivariogram_Temporal_Multiresolution(obj, varargin)
        
        %% Multifractal Spectrum MFDFA
        [Alfa, F_Alfa, Delta, H, Tau, q, Fq, Dq] = MFDFA(obj, Data)
        
        %% Multifractal Spectrum MassExponents
        [Alfa, F_Alfa, Delta, H, Tau, q, Miu, Dq, Fig] = MassExponent(obj, Data);
        [Alfa, F_Alfa, Delta, H, Tau, q, Miu, Dq, Fig] = TS_MassExponent(obj, Data);
        
        %% Plot Multifractal Spectrum
        Fig = Plot_MultifractalSpectrum(obj, Alfa, F_Alfa,q)
        
        %% Wavelet
        [TimeError, varargout] = Wavelets(obj, varargin)
        
        %%
        Check_Filling(obj, varargin)
        
        %% Complementation Data
        InterpolationField(obj, Method, PathDEM, varargin) 
        
        % IDW
        DataFilling_IDW(obj, varargin)
        
        % Kriging
        DataFilling_Kriging(obj,varargin)
        
        % Lienal Regression
        DataFilling_LinealRegressionSpatial(obj,varargin)
        DataFilling_LinealRegressionTemporal(obj,varargin)
        
        % Normal Proporcional 
        ProporcionNormal(obj, varargin)
        
        %% Correct Raster With Python
        ScriptPython = CorrectRater_Python(obj, PathR, NoData)

        %% PCA
        
        %% Time Series descomposition
        Periodograma(obj, varargin)
        
        %% Test Mann-Kendal Train
        [H, p_value] = Mann_Kendall(obj, varargin)
        
        %% Rachas Test
        Test_Rachas(obj, varargin)
        
        %% CDI 
        Results = CDI(obj, varargin)
        
        %% Desaagregation 
        
        %% Zipf
        Zipf_Scale(obj,varargin)
        
        %% Deltas
        DeltasEnergy_Scale(obj,varargin)
        
        %%
        Remove_Seasonality(obj, varargin)
        
        %%  
        [Date, Data] = Synthetic_TimeSeries_Kriging(obj,Coor_X, Coor_Y, varargin)
        
        %% Anomaly
        Anomaly(obj)
        
        %% ONI
        ONI(obj, varargin)
        
        %% Peridos de retorno 
        ReturnPeriod_Year(obj, varargin)

        ReturnPeriod_Months(obj, varargin)
        
        %% Cambio de tendencía
        ChangePointDetection(obj, varargin)
        % DoubleMassCurve(obj, varargin)
    end
end
classdef WaterQuality < ClassNetwork & matlab.mixin.Copyable
    % ---------------------------------------------------------------------
    % Matlab - R2019b 
    % ---------------------------------------------------------------------
    %                            INFORMACION
    %----------------------------------------------------------------------
    % Autor         : Jonathan Nogales Pimentel
    % Email         : jonathannogales02@gmail.com
    % Fecha         : Dec - 2022
    %
    %----------------------------------------------------------------------
    % Este programa es de uso libre: Usted puede redistribuirlo y/o 
    % modificarlo bajo los t?rminos de la licencia publica general GNU. 
    % El autor no se hace responsable de los usos que pueda tener. 
    % Para mayor informaci?n revisar http://www.gnu.org/licenses/.

    % ---------------------------------------------------------------------
    % Atributos de Status de variables y variables temporales
    % ---------------------------------------------------------------------
    properties
        % Status para acumular area [1 true or 0 false]
        StatusAccArea(1,1) logical = false
        % Estatus para identificar las cuencas de cabecera o de condición
        % de contorno [1 true or 0 false]
        BC_Status(:,1) logical
        % Caudalacumulativo para calculo de cargas [m3/s]
        Qaccum(:,1) double
    end
    
    % ---------------------------------------------------------------------
    % Atributos de la UHM y de la corriente asociada que deben ser
    % suministrados por el usuario
    % ---------------------------------------------------------------------
    properties
        % Area UHM [m^2]
        A(:,1) double         
        % Longitud de la corriente [m]
        L(:,1) double                
        % Caudal a la salida de la UHM [m3/s]
        Q(:,1) double                
        % Elevación de la UHM [m.s.n.m]
        Z(:,1) double  
        % Pendiente de la corriente [m/m]
        S(:,1) double          
        % Tipo de río [montaña - 1, plano 0]
        RiverType(:,1) logical
    end
    
    % ---------------------------------------------------------------------
    % Atributos de la UHM y de la corriente asociada que pueden ser
    % suministrados por el usuario, no obstante, si no son proporcionados,
    % se calcularán mediante metodos indirectos
    % ---------------------------------------------------------------------
    properties
        % Ancho de la corriente [m]
        WB(:,1) double
        % Profundidad de la corriente [m]
        H(:,1) double
        % Velocidad de flujo de la corriente [m/s]
        v(:,1) double
        % Temperatura del aire de la UHM [°C]
        T(:,1) double
        % Tiempo de arribo o de advección de la corriente [d]
        tao(:,1) double
        % Tiempo de viaje de la corriente [d]
        tb(:,1) double
        % Tiempo de residencia en zona muerta de la corriente [d]
        Tr(:,1) double
        % Fracción dispersiva [Ad]
        DF(:,1) double
        % Velosidad del soluto en la corriente [m/s]
        Vs(:,1) double
        % Coeficiente de retraso efectivo
        Beta          
        % Turbiedad unidades nefelométricas de turbiedad [UNT]
        Turb
    end
    
    % ---------------------------------------------------------------------
    % Variables de concentración de los determinantes
    % ---------------------------------------------------------------------
    properties         
        % Concentración de Coliformes Totales [UFC/l]
        C_CT(:,1) double
        % Concentración de Sólidos Suspendidos Totales [mg/l]
        C_SST(:,1) double
        % Concentración de Fósforo Inorgánico [mg/l]
        C_PO(:,1) double
        % Concentración de Fórforo Orgánico [mg/l]
        C_PI(:,1) double
        % Concentración de Nitrógeno Orgánico [mg/l]
        C_NO(:,1) double    
        % Concentración de Nitrógeno Amoniacal [mg/l]
        C_NH4(:,1) double
        % Concentración Nitratos [mg/l]
        C_NO3(:,1) double
        % Concentración de Materia Organica [mg/l]
        C_MO(:,1) double
        % Concentración de Deficit de Oxígeno Disuelto [mg/l]
        C_DO(:,1) double
        % Concentración de Oxígeno Disuelto de Saturación [mg/l]
        C_OD(:,1) double
        % Concentración de Oxígeno Disuelto [mg/l]
        C_OS(:,1) double
        % Concentración de Temperatura del Agua[°C]
        C_T(:,1) double
        % Concentración de Mercurio Elemental [mg/l]
        C_Hg0(:,1) double
        % Concentración de Mercurio Divalente [mg/l]
        C_Hg2(:,1) double
        % Concentración de Metil Merurio [mg/l]
        C_MeHg(:,1) double
    end
    
    % ---------------------------------------------------------------------
    % Cargas de determinantes
    % ---------------------------------------------------------------------
    properties         
        % Carga de Coliformes Totales [UFC]
        W_CT(:,1) double
        % Carga de Sólidos Suspendidos Totales [mg]
        W_SST(:,1) double
        % Carga de Fósforo Inorgánico [mg]
        W_PO(:,1) double
        % Carga de Fórforo Orgánico [mg]
        W_PI(:,1) double
        % Carga de Nitrógeno Orgánico [mg]
        W_NO(:,1) double    
        % Carga de Nitrógeno Amoniacal [mg]
        W_NH4(:,1) double
        % Carga Nitratos [mg]
        W_NO3(:,1) double
        % Carga de Materia Organica [mg]
        W_MO(:,1) double
        % Carga de Deficit de Oxígeno Disuelto [mg]
        W_DO(:,1) double
        % Carga de Oxígeno Disuelto de Saturación [mg]
        W_OD(:,1) double
        % Carga de Oxígeno Disuelto [mg]
        W_OS(:,1) double
        % Carga de Temperatura del Agua[°C]
        W_T(:,1) double
        % Carga de Mercurio Elemental [mg]
        W_Hg0(:,1) double
        % Carga de Mercurio Divalente [mg]
        W_Hg2(:,1) double
        % Carga de Metil Merurio [mg]
        W_MeHg(:,1) double
    end
    
    % ---------------------------------------------------------------------
    % Carga de determinantes que componen un vertimientos
    % ---------------------------------------------------------------------
    properties         
        % Carga de Coliformes Totales [UFC]
        Ver_CT(:,1) double
        % Carga de Sólidos Suspendidos Totales [mg]
        Ver_SST(:,1) double
        % Carga de Fósforo Inorgánico [mg]
        Ver_PO(:,1) double
        % Carga de Fórforo Orgánico [mg]
        Ver_PI(:,1) double
        % Carga de Nitrógeno Orgánico [mg]
        Ver_NO(:,1) double    
        % Carga de Nitrógeno Amoniacal [mg]
        Ver_NH4(:,1) double
        % Carga Nitratos [mg]
        Ver_NO3(:,1) double
        % Carga de Materia Organica [mg]
        Ver_MO(:,1) double
        % Carga de Deficit de Oxígeno Disuelto [mg]
        Ver_DO(:,1) double
        % Carga de Oxígeno Disuelto de Saturación [mg]
        Ver_OD(:,1) double
        % Carga de Oxígeno Disuelto [mg]
        Ver_OS(:,1) double
        % Carga de Temperatura del Agua[°C]
        Ver_T(:,1) double
        % Carga de Mercurio Elemental [mg]
        Ver_Hg0(:,1) double
        % Carga de Mercurio Divalente [mg]
        Ver_Hg2(:,1) double
        % Carga de Metil Merurio [mg]
        Ver_MeHg(:,1) double
        % Status de vertimiento
        Ver_Status(:,1) logical
    end
    
    % ---------------------------------------------------------------------
    % Carga de los determinantes en las condiciones de frontera
    % ---------------------------------------------------------------------
    properties    
        % Carga de Coliformes Totales [UFC]
        BC_CT(:,1) double
        % Carga de Sólidos Suspendidos Totales [mg]
        BC_SST(:,1) double
        % Carga de Fósforo Inorgánico [mg]
        BC_PO(:,1) double
        % Carga de Fórforo Orgánico [mg]
        BC_PI(:,1) double
        % Carga de Nitrógeno Orgánico [mg]
        BC_NO(:,1) double    
        % Carga de Nitrógeno Amoniacal [mg]
        BC_NH4(:,1) double
        % Carga Nitratos [mg]
        BC_NO3(:,1) double
        % Carga de Materia Organica [mg]
        BC_MO(:,1) double
        % Carga de Deficit de Oxígeno Disuelto [mg]
        BC_DO(:,1) double
        % Carga de Oxígeno Disuelto de Saturación [mg]
        BC_OD(:,1) double
        % Carga de Oxígeno Disuelto [mg]
        BC_OS(:,1) double
        % Carga de Temperatura del Agua[°C]
        BC_T(:,1) double
        % Carga de Mercurio Elemental [mg]
        BC_Hg0(:,1) double
        % Carga de Mercurio Divalente [mg]
        BC_Hg2(:,1) double
        % Carga de Metil Merurio [mg]
        BC_MeHg(:,1) double
    end
    
    % ---------------------------------------------------------------------
    % Factores de Asimilación de los Determinantes
    % ---------------------------------------------------------------------
    properties         
        % Factor de Asimilación de Coliformes Totales (CT)
        FactorCT(:,1) double
        % Factor de Asimilación de Sólidos Suspendidos Totales (SST)
        FactorSST(:,1) double
        % Factor de Asimilación de Fósforo Inorgánico (PI)
        FactorPO(:,1) double
        % Factor de Asimilación de Fórforo Orgánico (PO)
        FactorPI(:,1) double
        % Factor de Asimilación de Nitrógeno Orgánico (NO)
        FactorNO(:,1) double  
        % Factor de Asimilación de Nitrógeno Amoniacal (NH4)
        FactorNH4(:,1) double        
        % Factor de Asimilación de Nitratos (NO3)
        FactorNO3(:,1) double
        % Factor de Asimilación de Materia Orgánico (MO)
        FactorMO(:,1) double
        % Factor de Asimilación de Deficit de Oxígeno Disuelto (DO)
        FactorDO(:,1) double
        % Factor de Asimilación de Temperatura del agua (T)
        FactorT(:,1) double
        % Factor de Asimilación de Mercurio Elemental
        FactorHg0(:,1) double
        % Factor de Asimilación de Mercurio Divalente
        FactorHg2(:,1) double
        % Factor de Asimilación de Metil Mercurio
        FactorMeHg(:,1) double
        % Factor de conversión de Caudal - [m3/s] - [lts/día]
        FactorQ = 1000*3600*24;
    end    
    
    % ---------------------------------------------------------------------
    % Inicialización de objeto Calidad del Agua
    % ---------------------------------------------------------------------
    methods
        function obj = WaterQuality(Code, FromNode, ToNode, RiverMouth,...
                       A, L, Q, Z, Slope, RiverType, varargin)
            
            % Asignar datos de entrada obligatorios
            % Código de la UHM
            obj.Code        = Code;
            % Nodo de inicio del tramo de la UHM
            obj.FromNode    = FromNode;
            % Nodo de finalización del tramo de la UHM
            obj.ToNode      = ToNode;
            % Código de desembocadura de la cuenca
            obj.RiverMouth  = RiverMouth;
            % Tipo de río [montaña - 1, plano 0]
            obj.RiverType   = RiverType;
            % Area UHM [m^2]
            obj.A           = A;
            % Longitud de la corriente [m]
            obj.L           = L;
            % Caudal a la salida de la UHM [m3/s]
            obj.Q           = Q;
            % Elevación de la UHM [m.s.n.m]
            obj.Z           = Z;
            % Pendiente de la corriente [m/m]
            obj.S           = Slope;          
            
            % Check de datos de entrada opcionales
            ip = inputParser;    
            % Check de Ancho de la corriente [m]
            addParameter(ip, 'WB',[],@ismatrix)   
            % Check de Profundidad de la corriente [m]
            addParameter(ip, 'H',[],@ismatrix)            
            % Check de Velocidad de flujo de la corriente [m/s]
            addParameter(ip, 'v',[],@ismatrix)
            % Check de Temperatura del aire de la UHM [°C]
            addParameter(ip, 'T',[],@ismatrix)  
            % Check de Velosidad del soluto en la corriente [m/s]
            addParameter(ip, 'Vs',[],@ismatrix)
            % Check de Fracción dispersiva [Ad]
            addParameter(ip, 'DF',[],@ismatrix)
            % Check de Tiempo de viaje de la corriente [d]
            addParameter(ip, 'tb',[],@ismatrix)
            % Check de Tiempo de arribo o de advección de la corriente [d]
            addParameter(ip, 'tao',[],@ismatrix)   
            % Check de Carga de Coliformes Totales del vertimiento [UFC]
            addParameter(ip, 'Ver_CT',zeros(size(Code)),@ismatrix)
            % Check de Carga de Sólidos Suspendidos Totales del vertimiento [mg]
            addParameter(ip, 'Ver_SST',zeros(size(Code)),@ismatrix)
            % Check de Carga de Fósforo Inorgánico del vertimiento [mg]
            addParameter(ip, 'Ver_PO',zeros(size(Code)),@ismatrix)
            % Check de Carga de Fórforo Orgánico del vertimiento [mg]
            addParameter(ip, 'Ver_PI',zeros(size(Code)),@ismatrix)
            % Check de Carga de Nitrógeno Orgánico del vertimiento [mg]
            addParameter(ip, 'Ver_NO',zeros(size(Code)),@ismatrix)
            % Check de Carga de Nitrógeno Amoniacal del vertimiento [mg]
            addParameter(ip, 'Ver_NH4',zeros(size(Code)),@ismatrix)
            % Check de Carga Nitratos del vertimiento [mg]
            addParameter(ip, 'Ver_NO3',zeros(size(Code)),@ismatrix)
            % Check de Carga de Materia Organica del vertimiento [mg]
            addParameter(ip, 'Ver_MO',zeros(size(Code)),@ismatrix)
            % Check de Carga de Deficit de Oxígeno Disuelto del vertimiento [mg]
            addParameter(ip, 'Ver_DO',zeros(size(Code)),@ismatrix)
            % Check de Carga de Temperatura del Agua del vertimiento [°C]
            addParameter(ip, 'Ver_T',zeros(size(Code)),@ismatrix)
            % Check de Carga de Mercurio Elemental del vertimiento [mg]
            addParameter(ip, 'Ver_Hg0',zeros(size(Code)),@ismatrix)
            % Check de Carga de Mercurio Divalente del vertimiento [mg]
            addParameter(ip, 'Ver_Hg2',zeros(size(Code)),@ismatrix)
            % Check de Carga de Metil Merurio del vertimiento [mg]
            addParameter(ip, 'Ver_MeHg',zeros(size(Code)),@ismatrix)               
            % Check de Carga de Coliformes Totales en las condiciones de frontera [UFC]
            addParameter(ip, 'BC_CT',zeros(size(Code)),@ismatrix)
            % Check de Carga de Sólidos Suspendidos Totales en las condiciones de frontera [mg]
            addParameter(ip, 'BC_SST',zeros(size(Code)),@ismatrix)
            % Check de Carga de Fósforo Inorgánico en las condiciones de frontera [mg]
            addParameter(ip, 'BC_PO',zeros(size(Code)),@ismatrix)
            % Check de Carga de Fórforo Orgánico en las condiciones de frontera [mg]
            addParameter(ip, 'BC_PI',zeros(size(Code)),@ismatrix)
            % Check de Carga de Nitrógeno Orgánico en las condiciones de frontera [mg]
            addParameter(ip, 'BC_NO',zeros(size(Code)),@ismatrix)
            % Check de Carga de Nitrógeno Amoniacal en las condiciones de frontera [mg]
            addParameter(ip, 'BC_NH4',zeros(size(Code)),@ismatrix)
            % Check de Carga Nitratos en las condiciones de frontera [mg]
            addParameter(ip, 'BC_NO3',zeros(size(Code)),@ismatrix)
            % Check de Carga de Materia Organica en las condiciones de frontera [mg]
            addParameter(ip, 'BC_MO',zeros(size(Code)),@ismatrix)
            % Check de Carga de Deficit de Oxígeno Disuelto en las condiciones de frontera [mg]
            addParameter(ip, 'BC_DO',zeros(size(Code)),@ismatrix)
            % Check de Carga de Temperatura del Agua en las condiciones de frontera [°C]
            addParameter(ip, 'BC_T',zeros(size(Code)),@ismatrix)
            % Check de Carga de Mercurio Elemental en las condiciones de frontera [mg]
            addParameter(ip, 'BC_Hg0',zeros(size(Code)),@ismatrix)
            % Check de Carga de Mercurio Divalente en las condiciones de frontera [mg]
            addParameter(ip, 'BC_Hg2',zeros(size(Code)),@ismatrix)
            % Check de Carga de Metil Merurio en las condiciones de frontera [mg]
            addParameter(ip, 'BC_MeHg',zeros(size(Code)),@ismatrix) 
            
            % Check de datos opcionales
            parse(ip,varargin{:})
            % Temperatura del aire de la UHM [°C]
            T   = ip.Results.T;
            % Profundidad de la corriente [m]
            WB  = ip.Results.WB;
            % Profundidad de la corriente [m]
            H   = ip.Results.H;
            % Velocidad de flujo de la corriente [m/s]
            v   = ip.Results.v;
            % Fracción dispersiva [Ad]
            DF  = ip.Results.DF;
            % Velosidad del soluto en la corriente [m/s]
            Vs  = ip.Results.Vs;
            % Tiempo de viaje de la corriente [d]
            tb  = ip.Results.tb;
            % Tiempo de arribo o de advección de la corriente [d]
            tao = ip.Results.tao;
            
            % Carga de Coliformes Totales del vertimiento [UFC]
            obj.Ver_CT      = ip.Results.Ver_CT;
            % Carga de Sólidos Suspendidos Totales del vertimiento [mg]
            obj.Ver_SST     = ip.Results.Ver_SST;
            % Carga de Fósforo Inorgánico del vertimiento [mg]
            obj.Ver_PO      = ip.Results.Ver_PO;
            % Carga de Fórforo Orgánico del vertimiento [mg]
            obj.Ver_PI      = ip.Results.Ver_PI;
            % Carga de Nitrógeno Orgánico del vertimiento [mg]
            obj.Ver_NO      = ip.Results.Ver_NO;
            % Carga de Nitrógeno Amoniacal del vertimiento [mg]
            obj.Ver_NH4     = ip.Results.Ver_NH4;
            % Carga Nitratos del vertimiento [mg]
            obj.Ver_NO3     = ip.Results.Ver_NO3;
            % Carga de Materia Organica del vertimiento [mg]
            obj.Ver_MO      = ip.Results.Ver_MO;
            % Carga de Deficit de Oxígeno Disuelto del vertimiento [mg]
            obj.Ver_DO      = ip.Results.Ver_DO;
            % Carga de Temperatura del Agua del vertimiento [°C]
            obj.Ver_T       = ip.Results.Ver_T;
            % Carga de Mercurio Elemental del vertimiento [mg]
            obj.Ver_Hg0     = ip.Results.Ver_Hg0;
            % Carga de Mercurio Divalente del vertimiento [mg]
            obj.Ver_Hg2     = ip.Results.Ver_Hg2;
            % Carga de Metil Merurio del vertimiento [mg]
            obj.Ver_MeHg    = ip.Results.Ver_MeHg;            
            
            % Asignar status de vertimientos
            obj.Update_VerStatus;            
                        
            % Carga de Coliformes Totales en las condiciones de frontera [UFC]
            obj.BC_CT       = ip.Results.BC_CT;
            % Carga de Sólidos Suspendidos Totales en las condiciones de frontera [mg]
            obj.BC_SST      = ip.Results.BC_SST;
            % Carga de Fósforo Inorgánico en las condiciones de frontera [mg]
            obj.BC_PO       = ip.Results.BC_PO;
            % Carga de Fórforo Orgánico en las condiciones de frontera [mg]
            obj.BC_PI       = ip.Results.BC_PI;
            % Carga de Nitrógeno Orgánico en las condiciones de frontera [mg]
            obj.BC_NO       = ip.Results.BC_NO;
            % Carga de Nitrógeno Amoniacal en las condiciones de frontera [mg]
            obj.BC_NH4      = ip.Results.BC_NH4;
            % Carga Nitratos en las condiciones de frontera [mg]
            obj.BC_NO3      = ip.Results.BC_NO3;
            % Carga de Materia Organica en las condiciones de frontera [mg]
            obj.BC_MO       = ip.Results.BC_MO;
            % Carga de Deficit de Oxígeno Disuelto en las condiciones de frontera [mg]
            obj.BC_DO       = ip.Results.BC_DO;
            % Carga de Temperatura del Agua en las condiciones de frontera [°C]
            obj.BC_T        = ip.Results.BC_T;
            % Carga de Mercurio Elemental en las condiciones de frontera [mg]
            obj.BC_Hg0      = ip.Results.BC_Hg0;
            % Carga de Mercurio Divalente en las condiciones de frontera [mg]
            obj.BC_Hg2      = ip.Results.BC_Hg2;
            % Carga de Metil Merurio en las condiciones de frontera [mg]
            obj.BC_MeHg     = ip.Results.BC_MeHg;
            
            % Inicialización de cargas de los determinantes
            % Carga de Coliformes Totales en las condiciones de frontera [UFC]
            obj.W_CT       = zeros(size(Code));
            % Carga de Sólidos Suspendidos Totales en las condiciones de frontera [mg]
            obj.W_SST      = zeros(size(Code));
            % Carga de Fósforo Inorgánico en las condiciones de frontera [mg]
            obj.W_PO       = zeros(size(Code));
            % Carga de Fórforo Orgánico en las condiciones de frontera [mg]
            obj.W_PI       = zeros(size(Code));
            % Carga de Nitrógeno Orgánico en las condiciones de frontera [mg]
            obj.W_NO       = zeros(size(Code));
            % Carga de Nitrógeno Amoniacal en las condiciones de frontera [mg]
            obj.W_NH4      = zeros(size(Code));
            % Carga Nitratos en las condiciones de frontera [mg]
            obj.W_NO3      = zeros(size(Code));
            % Carga de Materia Organica en las condiciones de frontera [mg]
            obj.W_MO       = zeros(size(Code));
            % Carga de Deficit de Oxígeno Disuelto en las condiciones de frontera [mg]
            obj.W_DO       = zeros(size(Code));
            % Carga de Temperatura del Agua en las condiciones de frontera [°C]
            obj.W_T        = zeros(size(Code));
            % Carga de Mercurio Elemental en las condiciones de frontera [mg]
            obj.W_Hg0      = zeros(size(Code));
            % Carga de Mercurio Divalente en las condiciones de frontera [mg]
            obj.W_Hg2      = zeros(size(Code));
            % Carga de Metil Merurio en las condiciones de frontera [mg]
            obj.W_MeHg     = zeros(size(Code));
            
            % Inicialización de Concentraciones de los determinantes
            % Carga de Coliformes Totales en las condiciones de frontera [UFC/l]
            obj.C_CT       = zeros(size(Code));
            % Carga de Sólidos Suspendidos Totales en las condiciones de frontera [mg/l]
            obj.C_SST      = zeros(size(Code));
            obj.Turb       = zeros(size(Code));
            % Carga de Fósforo Inorgánico en las condiciones de frontera [mg/l]
            obj.C_PO       = zeros(size(Code));
            % Carga de Fórforo Orgánico en las condiciones de frontera [mg/l]
            obj.C_PI       = zeros(size(Code));
            % Carga de Nitrógeno Orgánico en las condiciones de frontera [mg/l]
            obj.C_NO       = zeros(size(Code));
            % Carga de Nitrógeno Amoniacal en las condiciones de frontera [mg/l]
            obj.C_NH4      = zeros(size(Code));
            % Carga Nitratos en las condiciones de frontera [mg/l]
            obj.C_NO3      = zeros(size(Code));
            % Carga de Materia Organica en las condiciones de frontera [mg/l]
            obj.C_MO       = zeros(size(Code));
            % Carga de Deficit de Oxígeno Disuelto en las condiciones de frontera [mg/l]
            obj.C_DO       = zeros(size(Code));
            obj.C_OD       = zeros(size(Code));
            % Carga de Temperatura del Agua en las condiciones de frontera [°C/l]
            obj.C_T        = zeros(size(Code));
            % Carga de Mercurio Elemental en las condiciones de frontera [mg/l]
            obj.C_Hg0      = zeros(size(Code));
            % Carga de Mercurio Divalente en las condiciones de frontera [mg/l]
            obj.C_Hg2      = zeros(size(Code));
            % Carga de Metil Merurio en las condiciones de frontera [mg/l]
            obj.C_MeHg     = zeros(size(Code));
                        
            % Inicialización de factores de asimilación de los determinantes
            % Factor de Coliformes Totales en las condiciones de frontera [Ad]
            obj.FactorCT       = zeros(size(Code));
            % Factor de Sólidos Suspendidos Totales en las condiciones de frontera [Ad]
            obj.FactorSST      = zeros(size(Code));
            % Factor de Fósforo Inorgánico en las condiciones de frontera [Ad]
            obj.FactorPO       = zeros(size(Code));
            % Factor de Fórforo Orgánico en las condiciones de frontera [Ad]
            obj.FactorPI       = zeros(size(Code));
            % Factor de Nitrógeno Orgánico en las condiciones de frontera [Ad]
            obj.FactorNO       = zeros(size(Code));
            % Factor de Nitrógeno Amoniacal en las condiciones de frontera [Ad]
            obj.FactorNH4      = zeros(size(Code));
            % Factor Nitratos en las condiciones de frontera [Ad]
            obj.FactorNO3      = zeros(size(Code));
            % Factor de Materia Organica en las condiciones de frontera [Ad]
            obj.FactorMO       = zeros(size(Code));
            % Factor de Deficit de Oxígeno Disuelto en las condiciones de frontera [Ad]
            obj.FactorDO       = zeros(size(Code));
            % Factor de Temperatura del Agua en las condiciones de frontera [Ad]
            obj.FactorT        = zeros(size(Code));
            % Factor de Mercurio Elemental en las condiciones de frontera [Ad]
            obj.FactorHg0      = zeros(size(Code));
            % Factor de Mercurio Divalente en las condiciones de frontera [Ad]
            obj.FactorHg2      = zeros(size(Code));
            % Factor de Metil Merurio en las condiciones de frontera [Ad]
            obj.FactorMeHg     = zeros(size(Code));
            
            % -------------------------------------------------------------
            % Cálculo de parámetros
            % -------------------------------------------------------------            
            % Acumular área de la unidades
            obj.AccumArea;
            
            % Cálculo de Temperatura [°C]
            if isempty(T)
                obj.T_BarcoCuartasModel;
            else
                obj.T = T;
            end                        
            
            % Cálculo de Oxígeno de Saturación [mg/l]
            obj.Cal_OS
            
            % Cálculo de Profundidad de la corriente [m]
            if isempty(H)
                obj.H_GiraldoModel;
            else
                obj.H = H;
            end
            
            % Cálculo de la velocidad de flujo de la corriente [m/s]
            if isempty(v)
                obj.v_RojasModel;
            else
                obj.v = v;
            end
            
            % Cálculo de ancho de la corriente [m]
            if isempty(WB)
                obj.Cal_WB;
            else
                obj.WB = WB;
            end
                                    
            % Cálculo de la Velocidad del Soluto [m/s]
            if isempty(DF)
                obj.Beta_Gonzalez;
                obj.Vs_Lees;
            else
                obj.Vs = Vs;
            end         
            
            % Cálculo de la Fracción dispersiva (Ad)
            if isempty(DF) 
                obj.DF_Gonzalez;
            else
                obj.DF = DF;
            end
            
            % Cálculo de parámetros de transporte
            if isempty(tao) && ~isempty(tb) 
                % Tiempo de viaje de la corriente [d]
                obj.tb  = tb;
                % Tiempo de arribo o de advección de la corriente [d]
                obj.tao = obj.tb.*(1 - obj.DF);
            elseif ~isempty(tao) && isempty(tb) 
                % Tiempo de arribo o de advección de la corriente [d]
                obj.tao = tao;
                % Tiempo de viaje de la corriente [d]
                obj.tb = obj.tao./(1 - obj.DF);
            else
                % Factor Seg -> d
                Factor_1 = 1./(3600*24);
                % Tiempo de viaje de la corriente [d]
                obj.tb = (obj.L./obj.Vs).*Factor_1;  
                % Tiempo de arribo o de advección de la corriente [d]
                obj.tao = obj.tb.*(1 - obj.DF);
            end                                           
            
            % Cálculo de tiempo de residencia en zona muerta [d]
            obj.Tr = obj.DF.*obj.tb;                        
        end
    end         
        
    % ---------------------------------------------------------------------
    % Factor de asimilación para determinantes que no dependen de la
    % concentración de otros determinantes
    % ---------------------------------------------------------------------
    methods
        function Factor = Cal_Factor_CoIndependent(obj,Q,tao,Tr,K)
            % ENTRADAS
            % tao       [d]     : Tiempo de arribo o de advección
            % Tr        [d]     : Tiempo de residencia en zona muerta
            % K         [/d]    : Constante de decaimiento del determinante
            % Q         [l/d]   : Caudal del tramo de río
            % Factor    [mg/l]  : Factor de asimilación del determinante
            
            Part_1  = Q.*(1 + (K.*Tr));
            Part_2  = exp(-K.*tao);
            Factor  = Part_1./Part_2;
        end
    end
    
    % ---------------------------------------------------------------------
    % Factor de asimilación para determinantes que no dependen de la
    % concentración de otros determinantes
    % ---------------------------------------------------------------------
    methods
        function Factor = Cal_Factor_CoDependent(obj,Q,tao,Tr,Kd,K,Factor,Factor2)
            % ENTRADAS
            % tao       [d]     : Tiempo de arribo o de advección
            % Tr        [d]     : Tiempo de residencia en zona muerta
            % Kd        [/d]    : Constante de decaimiento del determinante
            %                     dependiente
            % K         [/d]    : Constante de decaimiento del determinante
            % Q         [l/d]   : Caudal del tramo de río
            % Factor    [mg/l]  : Factor de asimilación del determinante            
            
            Part_1  = ((Kd.*Tr) + 1);
            Part_2  = exp(K.*tao) + (Tr.*(Factor2.*(K*Factor) + Kd));
            Factor  = Q.*(Part_1./Part_2);
         end
    end
    
    % ---------------------------------------------------------------------
    % Función acumulativa para determinantes que no dependen de la
    % concentración de otros determinantes
    % ---------------------------------------------------------------------
    methods
        function FunctionNetwork_CoIndependent(obj, Npre, Posi,varargin)
            % Esta función realiza el cálculo acumulativo de las
            % concentraciones, cargas y factores de asimilación de los
            % determinantes de calidad del agua que son independientes, en
            % el esquema acumulativo del Functional Branch.
            % Model     [String]: Sigla del modelo a utilizar. Por defecto se asigana
            
            % Check de entrada
            ip = inputParser;
            % Sigla del modelo a utilizar. Por defecto se asigana
            % coliformes totales
            addParameter(ip,'Model','CT',@ischar)
            parse(ip,varargin{:})
            Model = ip.Results.Model;
            
            % Cálculo de cargas de determinante
            if isempty(Posi)        
                % Cálculo de cargas para tramos de orden 1 (cabecera) -
                % Condiciones de frontera
                if obj.Ver_Status(Npre)       
                    % Cálculo de carga del determinante aguas arriba del 
                    % tramo, cuando se tienen vertimientos [mg]
                    eval(['obj.W_',Model,'(Npre)  = (obj.BC_',Model,'(Npre)) + (obj.Ver_',Model,'(Npre));'])
                    % Cambio de status para no volver a considerar el
                    % vertimeinto en la cumulación 
                    obj.Ver_Status(Npre) = false;
                else
                    % Cálculo de carga del determinante aguas arriba del 
                    % tramo, cuando no se tienen vertimientos [mg]
                    eval(['obj.W_',Model,'(Npre)  = (obj.BC_',Model,'(Npre));'])                    
                end
            else  
                % Check para Posi mayor que dos
                if length(Posi)~=1
                    return
                end
                % Cálculo de cargas para tramos de orden >1
                if obj.Ver_Status(Npre)    
                    % Cálculo de carga del determinante aguas arriba del 
                    % tramo, cuando se tienen vertimientos [mg]
                    eval(['obj.W_',Model,'(Npre) = obj.W_',Model,'(Npre) + (obj.C_',Model,'(Posi).*obj.Q(Posi).*obj.FactorQ) + (obj.Ver_',Model,'(Npre));']) 
                    % Cambio de status para no volver a considerar el
                    % vertimeinto en la cumulación 
                    obj.Ver_Status(Npre) = false;
                else
                    % Cálculo de carga del determinante aguas arriba del 
                    % tramo, cuando no se tienen vertimientos [mg]
                    eval(['obj.W_',Model,'(Npre) = obj.W_',Model,'(Npre) + (obj.C_',Model,'(Posi).*obj.Q(Posi).*obj.FactorQ);'])
                end  
            end

            % Cálculo de concentración del determinante en el tramo [mg/l]
            eval(['obj.C_',Model,'(Npre) = obj.W_',Model,'(Npre)./obj.Factor',Model,'(Npre);'])                         
%             disp('-------------------------------------------------')
%             disp(['Code: ',num2str(obj.Code(Npre)),' | W: ',num2str(obj.W_SST(Npre)),' | C: ',num2str(obj.C_SST(Npre)),' | Q: ',num2str(obj.Q(Npre)),...
%                 ' | Code: ',num2str(obj.Code(Posi)),' | W: ',num2str(obj.W_SST(Posi)),' | C: ',num2str(obj.C_SST(Posi)),' | Q: ',num2str(obj.Q(Posi).*obj.FactorQ)])
        end
    end 
    
    % ---------------------------------------------------------------------
    % Función acumulativa para determinantes que dependen de la
    % concentración de otros determinantes
    % ---------------------------------------------------------------------
    methods
        function FunctionNetwork_CoDependent(obj, Npre, Posi,varargin)
            % Esta función realiza el cálculo acumulativo de las
            % concentraciones, cargas y factores de asimilación de los
            % determinantes de calidad del agua que son dependientes, en
            % el esquema acumulativo del Functional Branch.
            
            % Check de entrada
            ip = inputParser;
            % Sigla del modelo a utilizar. Por defecto se asigna Nitrógeno
            % Amoniacal            
            addParameter(ip,'Model','NH4',@ischar)
            parse(ip,varargin{:})
            Model = ip.Results.Model;
            
            % Parámetros de acuerdo con el determinante
            if strcmp(Model,'NH4')
                % Determinante del cual depende el Nitrógeno Amoniacal
                Model_d = 'NO';
                % Factor multiplicador del la constante de decaimiento 1
                Factor  = 1;
                % Factor multiplicador del la constante de decaimiento 2
                Factor2 = 1;
            elseif strcmp(Model,'NO3')
                % Determinante del cual depende los Nitratos
                Model_d = 'NH4';
                % Factor multiplicador del la constante de decaimiento 1
                Factor  = 1;
                % Factor multiplicador del la constante de decaimiento 2
                Factor2 = 1;
            elseif strcmp(Model,'PI')
                % Determinante del cual depende el Fósforo Inorgánico
                Model_d = 'PO';
                % Factor multiplicador del la constante de decaimiento 1
                Factor  = 1;
                % Factor multiplicador del la constante de decaimiento 2
                Factor2 = 1;
            elseif strcmp(Model,'MO')
                % Determinante del cual depende la Matería Orgánica
                Model_d = 'NO3';
                % Factor multiplicador del la constante de decaimiento 1
                Factor  = 1;
                % Factor multiplicador del la constante de decaimiento 2
                Factor2 = 1;
            elseif strcmp(Model,'Hg0')
                % Determinante del cual depende la Matería Orgánica
                Model_d = 'Hg2';
                % Factor multiplicador del la constante de decaimiento 1
                Factor  = 1;
                % Factor multiplicador del la constante de decaimiento 2
                Factor2 = 1;
            elseif strcmp(Model,'Hg2')
                % Determinante del cual depende la Matería Orgánica
                Model_d = 'Hg0';
                % Factor multiplicador del la constante de decaimiento 1
                Factor  = 1;
                % Factor multiplicador del la constante de decaimiento 2
                Factor2 = 1;
            elseif strcmp(Model,'MeHg')
                % Determinante del cual depende la Matería Orgánica
                Model_d = 'Hg2';
                % Factor multiplicador del la constante de decaimiento 1
                Factor  = 1;
                % Factor multiplicador del la constante de decaimiento 2
                Factor2 = 1;
            end
            
            % Cálculo de cargas del determinante
            if isempty(Posi)        
                % Cálculo de cargas para tramos de orden 1 (cabecera) -
                % Condiciones de frontera
                if obj.Ver_Status(Npre)   
                    % Cálculo de carga del determinante aguas arriba del 
                    % tramo, cuando se tienen vertimientos [mg]
                    eval(['obj.W_',Model,'(Npre)  = (obj.BC_',Model,'(Npre)) + (obj.Ver_',Model,'(Npre));'])                    
                    % Cambio de status para no volver a considerar el
                    % vertimeinto en la cumulación 
                    obj.Ver_Status(Npre)    = false;
                else
                    % Cálculo de carga del determinante aguas arriba del 
                    % tramo, cuando no tienen vertimientos [mg]
                    eval(['obj.W_',Model,'(Npre)  = (obj.BC_',Model,'(Npre));'])
                end  
                % Acumulación de caudales para cálculo de
                % concentraciones aguas arriba del tramo [m3/s]
                obj.Qaccum(Npre)        = obj.Q(Npre);
            else  
                % Check para Posi mayor que dos
                if length(Posi)~=1
                    return
                end
                % Cálculo de cargas para tramos de orden >1
                if obj.Ver_Status(Npre)  
                    % Cálculo de carga del determinante aguas arriba del 
                    % tramo, cuando se tienen vertimientos [mg]
                    eval(['obj.W_',Model,'(Npre) = obj.W_',Model,'(Npre) + (obj.C_',Model,'(Posi).*obj.Q(Posi).*obj.FactorQ) + (obj.Ver_',Model,'(Npre));'])                     
                     % Cambio de status para no volver a considerar el
                    % vertimeinto en la cumulación 
                    obj.Ver_Status(Npre)    = false;
                else
                    % Cálculo de carga del determinante aguas arriba del 
                    % tramo, cuando no se tienen vertimientos [mg]
                    eval(['obj.W_',Model,'(Npre) = obj.W_',Model,'(Npre) + (obj.C_',Model,'(Posi).*obj.Q(Posi).*obj.FactorQ);'])
                end
                % Acumulación de caudales para cálculo de
                % concentraciones aguas arriba del tramo [m3/s]
                obj.Qaccum(Npre)        = obj.Qaccum(Npre) + obj.Q(Posi);
            end

            % Cálculo de concentración aguas arriba del determinante [mg]
            eval(['',Model,'u = obj.W_',Model,'(Npre)./(obj.Qaccum(Npre).*obj.FactorQ);'])
            
            % Cálculo de constante de decaimiento 1 del determinante [1/d]
            eval(['obj.K__',Model,'(Npre) = obj.Params_K__',Model,'(obj.C_',Model_d,'(Npre),',Model,'u,obj.K_',Model_d,'(Npre),obj.K_',Model,'(Npre));'])
                
            % Cálculo del factor de asimilación del determinante [Ad]
            eval(['obj.Factor',Model,'(Npre) = obj.Cal_Factor_CoDependent((obj.Q(Npre).*obj.FactorQ),obj.tao(Npre),obj.Tr(Npre),obj.K_',Model,'(Npre),obj.K__',Model,'(Npre),Factor,Factor2);'])

            % Cálculo de la concentración del determinante [mg/l]
            eval(['obj.C_',Model,'(Npre) = obj.W_',Model,'(Npre)./obj.Factor',Model,'(Npre);'])
        end
    end        
    
    % ---------------------------------------------------------------------
    % Módulo - Sólidos Suspendidos Totales [SST]
    % ---------------------------------------------------------------------
    properties
        % Tasa de decaimiento de sólidos suspendidos totales por 
        % sedimentación [1/d]
        K_SST
    end
    
    methods               
        function Params_KSST(obj,varargin)
            % Esta función cálcula la tasa de decaimiento de sólidos 
            % supendidos totales por sedimentación
            % H         [m]     : Profundidad
            % Vss       [m/d]   : Velocidad de sedimentación de sólidos
            % Kd_sst    [1/d]   : Tasa de reacción de sedimentos
            % K_SST     [1/d]   : Constante de decaimiento de sólidos 
            %                     suspendidos totales                             

            ip = inputParser;
            % Velocidad de sedimentación de sólidos suspendidos Vss [m/d]
            % Se toma valor por defecto el valor indicado en Qual2Kw [0.1]
            addParameter(ip,'Vss',0.1,@isnumeric)
            % Tasa de reacción de sólidos suspendidos sedimentos [1/d]. 
            % Se toma por defecto el valor indicado en Qual2Kw [0]
            addParameter(ip,'Kd_sst',0,@isnumeric)
            % Check de datos de entrada
            parse(ip,varargin{:})
            %  Velocidad de sedimentación de solidos [m/d]
            Vss         = ip.Results.Vss;
            % Tasa de reacción de sólidos suspendidos [1/d]
            Kd_sst      = ip.Results.Kd_sst;
            % Tasa de decaimiento de sólidos suspendidos totales por 
            % sedimentación[1/d]
            obj.K_SST   = Kd_sst + (Vss./obj.H);
        end
        
        function Model_SST(obj)
            tic
            % Esta función aplica el modelo de sólidos suspendidos totales
            % Inicialización de cargas en 0           
            obj.W_SST       = zeros(size(obj.Code));
            % Inicialización de concentraciones en 0  
            obj.C_SST       = zeros(size(obj.Code));
            % Inicialización de factores de asimilación en 0  
            obj.FactorSST   = zeros(size(obj.Code));
            % Inicialización de caudales acumulados en 0 
            obj.Qaccum      = zeros(size(obj.Code));
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Cálculo de tasa de decaimiento [1/d]
            obj.Params_KSST
            % Cálculo de factor de asimilación
            obj.FactorSST        = obj.Cal_Factor_CoIndependent(obj.Q.*obj.FactorQ,obj.tao,obj.Tr,obj.K_SST);
            % Activar modalidad de función del FunctionNetwork
            obj.StatusFun       = true;
            % Función para acumulación en 1 y 2 tramos
            obj.FunNetwork_1    = 'obj.FunctionNetwork_CoIndependent(Npre, Posi(i),''Model'',''SST'');';
            % Función para tramo de cabecera (cuando Posi = [])
            obj.FunNetwork_2    = 'if isempty(Posi), obj.FunctionNetwork_CoIndependent(Npre, Posi,''Model'',''SST''), end;';
            % Aplicar esquema acumulativo
            obj.AnalysisNetwork_Obj;
            % Deshabilitar modalidad de función del FunctionNetwork
            obj.StatusFun       = false;
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Estimar turbiedad
            obj.Cal_Turbiedad;
            % Mostrar resultados
            disp(['Modelo de Solidos Suspendidos Totales - Ok| Time: ',num2str(toc,'%.4f'),' Seg']);
        end
    end
    
    % ---------------------------------------------------------------------
    % Módulo - Coliformes Totales
    % ---------------------------------------------------------------------
    properties
        % Tasa de decaimiento de los coliformes totales por muerte y 
        % sedimentación [1/d]
        K_CT 
    end
            
    methods                                    
        function Params_KCT(obj,varargin)
            % Esta función cálcula la tasa de decaimiento de los coliformes 
            % totales por muerte y sedimentación
            % H         [m]     : Profundidad
            % Kd        [1/d]   : Tasas de reacción de coliformes totales
            % vx        [m/d]   : Velocidad de sedimentación de patógenos 
            % Fp        [Ad]    : Fracción adsorbida de bacterias a las 
            %                     partículas sólidas
            % Kd_CT     [1/d]   : Tasa de reacción de coliformes totales
            % K_CT      [1/d]   : Tasa de decaimiento de coliformes totales

            ip = inputParser;
            % Velocidad de sedimentación de patógenos [m/d]
            % Se toma valor por defecto indicado en Qual2Kw [1]
            addParameter(ip,'vx',1,@isnumeric)
            % Fracción adsorbida de bacterias a las partículas sólidas
            % Considerando lo indicado por Rojas (2011) y en el documento 
            % publicado por MADS y ANLA (2013), un valor típico de 0.7
            % puede ser adoptado
            addParameter(ip,'Fp', 0.7, @isnumeric)
            % Check de datos de entrada
            parse(ip,varargin{:})
            % Velocidad de sedimentación de patógenos [m/d]
            vx          = ip.Results.vx;
            % Fracción adsorbida de bacterias a las partículas sólidas
            Fp          = ip.Results.Fp;
            % Cálculo de la tasa de reacción de coliformes totales [1/d]
            Kd_CT       = obj.Kd_ArrheniusModel('NameParam','CT');
            % Tasa de decaimiento de coliformes totales por muerte y 
            % sedimentación [1/d]
            obj.K_CT    = Kd_CT + ((Fp.*vx)./obj.H);
        end
        
        function Model_CT(obj) 
            tic
            % Esta función aplica el modelo de coliformes totales
            % Inicialización de cargas en 0           
            obj.W_CT       = zeros(size(obj.Code));
            % Inicialización de concentraciones en 0  
            obj.C_CT       = zeros(size(obj.Code));
            % Inicialización de factores de asimilación en 0  
            obj.FactorCT   = zeros(size(obj.Code));
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Cálculo de tasa de decaimiento [1/d]
            obj.Params_KCT;
            % Cálculo de factor de asimilación
            obj.FactorCT        = obj.Cal_Factor_CoIndependent(obj.Q.*obj.FactorQ,obj.tao,obj.Tr,obj.K_CT);
            % Activar modalidad de función del FunctionNetwork
            obj.StatusFun       = true;
            % Función para acumulación en 1 y 2 tramos
            obj.FunNetwork_1    = 'obj.FunctionNetwork_CoIndependent(Npre, Posi(i),''Model'',''CT'');';
            % Función para tramo de cabecera (cuando Posi = [])
            obj.FunNetwork_2    = 'if isempty(Posi), obj.FunctionNetwork_CoIndependent(Npre, Posi,''Model'',''CT''), end;';
            % Aplicar esquema acumulativo
            obj.AnalysisNetwork_Obj;
            % Deshabilitar modalidad de función del FunctionNetwork
            obj.StatusFun       = false;
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Mostrar resultados
            disp(['Modelo de Coliformes Totales - Ok | Time: ',num2str(toc,'%.4f'),' Seg']);
        end
        
    end   
    
    % ---------------------------------------------------------------------
    % Modulo - Nitrógeno Orgánico
    % ---------------------------------------------------------------------
    properties
        % Tasa de reacción del Nitrógeno Orgánico [1/d]
        K_NO
        % Tasa de decaimiento del Nitrógeno Orgánico por hidrolisis y 
        % sedimentación [1/d]
        K__NO      
    end
    
    methods              
        function Params_KNO(obj,varargin)
            % Este código cálcula la tasa de decaimiento del nitrógeno 
            % orgánico por hidrolisis
            % H         [m]     : Profundidad
            % K_NO      [1/d]   : Tasa de reacción por hidrólisis
            % vno       [m/d]   : Velocidad de sedimentación del nitrógeno 
            %                     orgánico
            % K__NO     [1/d]   : Tasa de decaimiento del nitrógeno orgánico
            %                     por hidrolisis y sedimentación

            ip = inputParser;
            % Velocidad de sedimentación de nitrógeno orgánico [m/d]
            % Se toma valor por defecto indicado en Qual2Kw [0.0005]
            addParameter(ip,'vno',0.0005 ,@isnumeric)
            % Check de datos de entrada
            parse(ip,varargin{:})
            % Velocidad de sedimentación del nitrógeno orgánico [m/d]
            vno         = ip.Results.vno;
            % Tasa de reacción por hidrólisis [1/d]
            obj.K_NO    = obj.Kd_ArrheniusModel('NameParam','NO');
            % Tasa de decaimiento del Nitrógeno Orgánico por hidrolisis y 
            % sedimentación [1/d]
            obj.K__NO   = obj.K_NO + (vno./obj.H);
        end
        
        function Model_NO(obj)    
            tic
            % Esta función aplica el modelo de nitrógeno orgánico
            % Inicialización de cargas en 0           
            obj.W_NO       = zeros(size(obj.Code));
            % Inicialización de concentraciones en 0  
            obj.C_NO       = zeros(size(obj.Code));
            % Inicialización de factores de asimilación en 0  
            obj.FactorNO   = zeros(size(obj.Code));
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Cálculo de tasa de decaimiento [1/d]
            obj.Params_KNO;
            % Cálculo de factor de asimilación
            obj.FactorNO        = obj.Cal_Factor_CoIndependent(obj.Q.*obj.FactorQ,obj.tao,obj.Tr,obj.K_NO);
            % Activar modalidad de función del FunctionNetwork
            obj.StatusFun       = true;
            % Función para acumulación en 1 y 2 tramos
            obj.FunNetwork_1    = 'obj.FunctionNetwork_CoIndependent(Npre, Posi(i),''Model'',''NO'');';
            % Función para tramo de cabecera (cuando Posi = [])
            obj.FunNetwork_2    = 'if isempty(Posi), obj.FunctionNetwork_CoIndependent(Npre, Posi,''Model'',''NO''), end;';
            % Aplicar esquema acumulativo
            obj.AnalysisNetwork_Obj;
            % Deshabilitar modalidad de función del FunctionNetwork
            obj.StatusFun       = false;
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Mostrar resultados
            disp(['Modelo de Nitrógeno Orgánico- Ok | Time: ',num2str(toc,'%.4f'),' Seg']);
        end
    end       
    
    % ---------------------------------------------------------------------
    % Modulo - Nitrógeno Amoniacal
    % ---------------------------------------------------------------------
    properties        
        % Tasa de decaimiento del Nitrógeno Amoniacal por nitrificación [1/d]
        K_NH4
        % Tasa de decaimiento del Nitrógeno Amoniacal que combina Hidrolisis 
        % del nitrógeno orgánico y Nitrificación del Nitrógeno Amoniacal [1/d]
        K__NH4
    end
    
    methods               
        function Params_KNH4(obj,varargin)
            % Esta función cálcula la tasa de decaimiento por nitrificación 
            % H         [m]     : Profundidad            
            % v         [m/s]   : Velocidad de la corriente
            % K_NH4     [1/d]   : Tasa de decaimiento por nitrificación             

            % Robles y Camacho (2005) y Medina y Camacho (2008) demostraron 
            % que la ecuación de Bansal no tiene un buen comportamiento para
            % ríos de montaña. En sus estudios, Robles y Camacho (2005), 
            % utilizando el método de Couchaine, propusieron, para ríos de 
            % montaña, la expresión que se indica a continuación:
            obj.K_NH4  = (0.4381.*(obj.v./obj.H)) + 0.5394;
        end
        
        function K__NH4 = Params_K__NH4(obj,C_NO,NH4u,K_NO,K_NH4)
            % Esta función cálcula la tasa de decaimiento del Nitrógeno 
            % Amoniacal que combina Hidrolisis y Nitrificación [1/d]
            % C_NO  [mg/l] : Concentración de Nitrógeno Orgánico
            % NH4u  [mg/l] : Concentración de Nitrógeno Amoniacal aguas
            %                arriba 
            % K_NO  [1/d]  : Tasa de decaimiento del nitrógeno orgánico por
            %                Hidrolisis 
            % K_NH4 [1/d]  : Tasa de decaimiento del Nitrógeno Amoniacal por 
            %                nitrificación
            % K__NH4[1/d]  : Tasa de decaimiento del Nitrógeno Amoniacal 
            %                que combina Hidrolisis del nitrógeno orgánico 
            %                y Nitrificación del Nitrógeno Amoniacal
            
            % Controles para cuando las concentraciones sean cero
            if NH4u == 0
                Var = 1;
            elseif C_NO == 0
                Var = 0;
            else
                Var = (C_NO./NH4u);
            end
            
            % Control para que no se genere materia del determinante
            if Var > 1
                Var = 1;
            end
            
            % Tasa de decaimiento del Nitrógeno Amoniacal que combina 
            % Hidrolisis del nitrógeno orgánico y Nitrificación del 
            % Nitrógeno Amoniacal [1/d]
            K__NH4  = (K_NO*Var) - K_NH4;
        end
                        
        function Model_NH4(obj)
            tic
            % Esta función aplica el modelo de nitrógeno amoniacal
            % Inicialización de cargas en 0        
            obj.W_NH4       = zeros(size(obj.Code));
            % Inicialización de concentraciones en 0 
            obj.C_NH4       = zeros(size(obj.Code));
            % Inicialización de factores de asimilación en 0
            obj.FactorNH4   = zeros(size(obj.Code));
            % Inicialización de acumulador de caudales
            obj.Qaccum      = zeros(size(obj.Code));
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Cálculo de tasa de decaimiento por nitrificación 
            obj.Params_KNH4
            % Activar modalidad de función del FunctionNetwork
            obj.StatusFun       = true;
            % Funciones para acumulación en 1 y 2 tramos
            obj.FunNetwork_1    = 'obj.FunctionNetwork_CoDependent(Npre, Posi(i),''Model'',''NH4'');';
            % Función para tramo de cabecera (cuando Posi = [])
            obj.FunNetwork_2    = 'if isempty(Posi), obj.FunctionNetwork_CoDependent(Npre, Posi,''Model'',''NH4''), end;';
            % Aplicar esquema acumulativo
            obj.AnalysisNetwork_Obj;
            % Deshabilitar modalidad de función del FunctionNetwork
            obj.StatusFun       = false;
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Mostrar resultados
            disp(['Modelo de Nitrógeno Amoniacal - Ok | Time: ',num2str(toc,'%.4f'),' Seg']);
        end
    end
    
    % ---------------------------------------------------------------------
    % Módulo - Nitratos
    % ---------------------------------------------------------------------
    properties        
        % Tasa de decaimiento de los nitratos por Desnitrificación [1/d]
        K_NO3
        % Tasa de decaimiento de nitratos que combina Nitrificación del 
        % nitrógeno amonical y Desnitrificación de los nitratos [1/d]
        K__NO3
    end
    
    methods               
        function Params_KNO3(obj,varargin)
            % Este código cálcula la tasa de decaimiento de los nitratos por 
            % nitrificación con efecto de oxígeno
            % Foxd_NO3  [Ad]    : Efecto de oxígeno bajo en la desnitrificación
            % Fd_NO3    [1/d]   : Tasa de desnitrificación
            % K_NO3     [1/d]   : Tasa de decaimiento por desnitrificación 
            %                     con efecto de oxígeno            
            
            % Efecto de oxígeno bajo en la desnitrificación
            Foxd_NO3    = exp(-0.60);
            % la tasa de desnitrificación kd_NO3 es la indicada en Qual2Kw 
            % como valor por defecto [0.1]
            Fd_NO3      = 0.1;
            % Tasa de decaimiento de los nitratos por nitrificación con 
            % efecto de oxígeno
            obj.K_NO3   = obj.Code*0;
            obj.K_NO3(:)= Foxd_NO3.*Fd_NO3;
        end
        
        function K__NO3 = Params_K__NO3(obj,C_NH4,NO3u,K_NH4,K_NO3)
            % Esta función cálcula la tasa de decaimiento de nitratos que 
            % combina Nitrificación del nitrógeno amonical y desnitrificación 
            % de los nitratos
            % C_NH4  [mg/l] : Concentración de Nitrógeno Amoniacal
            % NO3u   [mg/l] : Concentración de Nitratos aguas arriba 
            % K_NH4  [1/d]  : Tasa de decaimiento del Nitrógeno Amoniacal 
            %                 por nitrificación
            % K_NO3  [1/d]  : Tasa de decaimiento de los nitratos por 
            %                 desnitrificación 
            % K__NO3 [1/d]  : tasa de decaimiento de nitratos que combina 
            %                 Nitrificación del nitrógeno amonical y 
            %                 desnitrificación de los nitratos
            
            % Controles para cuando las concentraciones sean cero
            if NO3u == 0
                Var = 1;
            elseif C_NH4 == 0
                Var = 0;
            else
                Var = (C_NH4./NO3u);
            end
            
            % Control para que no se genere materia del determinante
            if Var > 1
                Var = 1;
            end
            
            % Cálculo de tasa de decaimiento de nitratos que combina 
            % Nitrificación del nitrógeno amonical y Desnitrificación de 
            % los nitratos [1/d]
            K__NO3    = (K_NH4*Var) - K_NO3;
        end
        
        function Model_NO3(obj)
            tic
            % Esta función aplica el modelo de nitrógeno amoniacal
            % Inicialización de cargas en 0        
            obj.W_NO3       = zeros(size(obj.Code));
            % Inicialización de concentraciones en 0 
            obj.C_NO3       = zeros(size(obj.Code));
            % Inicialización de factores de asimilación en 0
            obj.FactorNO3   = zeros(size(obj.Code));
            % Inicialización de acumulador de caudales
            obj.Qaccum      = zeros(size(obj.Code));
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Cálculo de tasa de decaimiento por nitrificación 
            obj.Params_KNO3
            % Activar modalidad de función del FunctionNetwork
            obj.StatusFun       = true;
            % Funciones para acumulación en 1 y 2 tramos
            obj.FunNetwork_1    = 'obj.FunctionNetwork_CoDependent(Npre, Posi(i),''Model'',''NO3'');';
            % Función para tramo de cabecera (cuando Posi = [])
            obj.FunNetwork_2    = 'if isempty(Posi), obj.FunctionNetwork_CoDependent(Npre, Posi,''Model'',''NO3''), end;';
            % Aplicar esquema acumulativo
            obj.AnalysisNetwork_Obj;
            % Deshabilitar modalidad de función del FunctionNetwork
            obj.StatusFun       = false;
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Mostrar resultados
            disp(['Modelo de Nitritos - Ok | Time: ',num2str(toc,'%.4f'),' Seg']);
        end
    end
    
    % ---------------------------------------------------------------------
    % Modulo - Fósforo Orgánico
    % ---------------------------------------------------------------------
    properties
        % Tasa de decaimiento del fósforo orgánico por hidrolisis y
        % sedimentación [1/d]
        K_PO
    end
    
    methods                
        function Params_KPO(obj,varargin)
            % Este código cálcula la constante de decaimiento de  fósforo 
            % orgánico por hidrolisis y sedimentación
            % H         [m]     : Profundidad
            % Khpo      [1/d]   : Tasa de reacción por hidrólisis
            % vpo       [m/d]   : Velocidad de sedimentación del fósforo 
            %                     orgánico
            % K_PO      [1/d]   : Tasa de decaimiento del fósforo orgánico
            %                     por hidrolisis y sedimentación 

            ip = inputParser;
            % Velocidad de sedimentación de fósforo orgánico (m/d)
            % Se toma valor por defecto indicado en Qual2Kw [0.001]
            addParameter(ip,'vpo',0.001,@isnumeric)
            % Tasa de reacción por hidrólisis [1/d]
            % Se toma valor por defecto indicado en Qual2Kw [0.03]
            addParameter(ip,'Khpo',0.03,@isnumeric)
            % Check de datos de entrada
            parse(ip,varargin{:})
            % Velocidad de sedimentación de fósforo orgánico [m/d]
            vpo         = ip.Results.vpo;
            % Tasa de reacción por hidrólisis [1/d]
            Khpo        = ip.Results.Khpo;
            % Constante de decaimiento del fósforo orgánico por hidrolisis 
            % y sedimentación[1/d]
            obj.K_PO    = Khpo + (vpo./obj.H);
        end
        
        function Model_PO(obj) 
            tic
            % Esta función aplica el modelo de fósforo orgánico
            % Inicialización de cargas en 0           
            obj.W_PO       = zeros(size(obj.Code));
            % Inicialización de concentraciones en 0  
            obj.C_PO       = zeros(size(obj.Code));
            % Inicialización de factores de asimilación en 0  
            obj.FactorPO   = zeros(size(obj.Code));
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Cálculo de tasa de decaimiento [1/d]
            obj.Params_KPO;
            % Cálculo de factor de asimilación
            obj.FactorPO        = obj.Cal_Factor_CoIndependent(obj.Q.*obj.FactorQ,obj.tao,obj.Tr,obj.K_PO);
            % Activar modalidad de función del FunctionNetwork
            obj.StatusFun       = true;
            % Función para acumulación en 1 y 2 tramos
            obj.FunNetwork_1    = 'obj.FunctionNetwork_CoIndependent(Npre, Posi(i),''Model'',''PO'');';
            % Función para tramo de cabecera (cuando Posi = [])
            obj.FunNetwork_2    = 'if isempty(Posi), obj.FunctionNetwork_CoIndependent(Npre, Posi,''Model'',''PO''), end;';
            % Aplicar esquema acumulativo
            obj.AnalysisNetwork_Obj;
            % Deshabilitar modalidad de función del FunctionNetwork
            obj.StatusFun       = false;
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Mostrar resultados
            disp(['Modelo de Fósforo Orgánico - Ok | Time: ',num2str(toc,'%.4f'),' Seg']);
        end
    end
    
    % ---------------------------------------------------------------------
    % Modulo - Fósforo Inorgánico
    % ---------------------------------------------------------------------
    properties        
        % Tasa de decaimiento del fósforo inorgánico por sedimentación [1/d]
        K_PI
        % Tasa de decaimiento del fósforo inorgánico que combina hidrolisis 
        % del fosforó orgánico y sedimentación del fósforo inorgánico [1/d]
        K__PI
    end
    
    methods               
        function Params_KPI(obj,varargin)
            % Este código cálcula la tasa de decaimiento del fósforo 
            % inorgánico por sedimentación [1/d]
            % H         [m]     : Profundidad
            % vpi       [m/d]   : Velocidad de sedimentación del fósforo
            %                     Inorgánico 
            % K_PI      [1/d]   : Tasa de decaimiento del fósforo inorgánico 
            %                     por sedimentación            

            ip = inputParser;
            % velocidad de sedimentación de fósforo inorgánico [m/d]
            % Se toma valor por defecto indicado en Qual2Kw [0.8]
            addParameter(ip,'vpi',0.8,@isnumeric)
            % Check de datos de entrada
            parse(ip,varargin{:})
            % velocidad de sedimentación de fósforo Inorgánico [m/d]
            vpi         = ip.Results.vpi;
            % Tasa de decaimiento del fósforo inorgánico por sedimentación 
            % [1/d]
            obj.K_PI    = (vpi./obj.H);
        end
        
        function K__PI = Params_K__PI(obj,C_PO,PIu,K_PO,K_PI)                        
            % Esta función cálcula la tasa de decaimiento del fósforo 
            % inorgánico que combina hidrolisis del fosforó orgánico y 
            % sedimentación del fósforo inorgánico [1/d]
            % C_PO  [mg/l] : Concentración de fósforo orgánico
            % PIu   [mg/l] : Concentración de fósforo inorgánico aguas arriba 
            % K_PO  [1/d]  : Tasas de decaimiento del fósforo orgánico por 
            %                hidrolisis
            % K_PI  [1/d]  : Tasa de decaimiento del fósforo inorgánico 
            %                por sedimentación
            % K__PI  [1/d] : Tasa de decaimiento del fósforo inorgánico 
            %                que combina hidrolisis del fosoforó orgánico 
            %                y sedimentación del fósforo inorgánico
            
            % Controles para cuando las concentraciones sean cero
            if PIu == 0
                Var = 1;
            elseif C_PO == 0
                Var = 0;
            else
                Var = (C_PO./PIu);
            end
            
            % Control para que no se genere materia del determinante
            if Var > 1
                Var = 1;
            end
            
            % Cálculo de tasa de decaimiento del fósforo inorgánico que combina 
            % hidrolisis del fosoforó orgánico y sedimentación del fósforo
            % inorgánico [1/d]
            K__PI    = (K_PO*Var) - K_PI;
        end
        
        function Model_PI(obj)    
            tic
            % Esta función aplica el modelo de fósforo inorgánico
            % Inicialización de cargas en 0        
            obj.W_PI       = zeros(size(obj.Code));
            % Inicialización de concentraciones en 0 
            obj.C_PI       = zeros(size(obj.Code));
            % Inicialización de factores de asimilación en 0
            obj.FactorPI   = zeros(size(obj.Code));
            % Inicialización de acumulador de caudales
            obj.Qaccum     = zeros(size(obj.Code));
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Cálculo de tasa de decaimiento por nitrificación 
            obj.Params_KPI
            % Activar modalidad de función del FunctionNetwork
            obj.StatusFun       = true;
            % Funciones para acumulación en 1 y 2 tramos
            obj.FunNetwork_1    = 'obj.FunctionNetwork_CoDependent(Npre, Posi(i),''Model'',''PI'');';
            % Función para tramo de cabecera (cuando Posi = [])
            obj.FunNetwork_2    = 'if isempty(Posi), obj.FunctionNetwork_CoDependent(Npre, Posi,''Model'',''PI''), end;';
            % Aplicar esquema acumulativo
            obj.AnalysisNetwork_Obj;
            % Deshabilitar modalidad de función del FunctionNetwork
            obj.StatusFun       = false;
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Mostrar resultados
            disp(['Modelo de Fósforo Inorgánico - Ok | Time: ',num2str(toc,'%.4f'),' Seg']);
        end
    end
    
    % ---------------------------------------------------------------------
    % Modulo - Materia orgánica
    % ---------------------------------------------------------------------
    properties
        % Tasa de decaimiento por descomposición de la materia orgánica [1/d]
        KdMO
        % Tasa de decaimiento por nitrificación de nitratos considerando 
        % oxígeno [1/d]
        K_NO3_MO
        % Tasa de decaimiento de materia orgánica por oxidación [1/d]
        K_MO        
        % tasa de decaimiento de la materia orgánica considerando 
        % nitrificación de nitratos y oxidación de la materia orgánica [1/d]
        K__MO
        % Variable temporal para guaradar datos
        VarTmp        
    end
    
    methods   
        function KdMO_WrightMcDonnell(obj)
            % Esta función cálcula la tasa de decaimiento por descomposición 
            % de la materia orgánica
            % La tasa de descomposición puede estimarse como función del caudal 
            % siguiendo la expresión propuesta por Wright y McDonnell (1979)
            % Q     [m3/s]  : Caudal
            % KdMo  [1/d]   : Tasa de decaimiento por descomposición
            
            % El rango de aplicación de esta expresión es para caudales 
            % entre 0.3 y 23 m3/s.
            id              = (obj.Q <= 23);
            % Tasa de decaimiento por descomposición de la materia orgánica
            % [1/d]
            obj.KdMO        = obj.Code.*0;
            obj.KdMO(id)    = 1.796.*(obj.Q(id).^-0.49);
            % por encima del mayor caudal, Wright y McDonnell demostraron 
            % que kdMo es independiente del caudal y las tasas encontradas 
            % son consistentes con las tasas de laboratorio. 
            % Por encima del rango de la ecuación, para propósitos prácticos, 
            % puede suponerse un valor constante de 0.30 1/d. 
            % El máximo valor de kdMo se sugiere de 3.5 1/d.
            obj.KdMO(~id)   = 0.3;            
            obj.KdMO(obj.KdMO > 3.5) = 3.5;
        end
        
        function Cal_ro_MO(obj)
            % Esta función calcula la constante de decaimiento de la
            % materia organica por oxidación
            % FoxdMO [Ad] : Factor que considera el efecto de oxígeno. 
            % KdMo  [1/d] : Tasa de decaimiento por descomposición
            % K_MO  [1/d] : Tasa de decaimiento por descomposición
            %               considerando oxígeno
            
            % Cálculo de tasa de decaimiento por descomposición siguiendo 
            % la expresión propuesta por Wright y McDonnell (1979) [1/d]
            obj.KdMO_WrightMcDonnell;
            % Factor que considera el efecto de oxígeno [Ad]
            FoxdMO     = 1 - exp(-0.6);   
            % Tasa de decaimiento por descomposición considerando oxígeno
            obj.K_MO   = FoxdMO.*obj.KdMO;
        end
        
        function Cal_teta_MO(obj)    
            % Esta función cálcula la tasa de decaimiento por nitrificación 
            % considerando oxígeno
            % FoxdNO3   [Ad]  : Factor que considera el efecto de oxígeno
            % Fd_NO3    [1/d] : Tasa de decaimiento por nitrificación de 
            %                   nitratos considerando oxígeno 
            % K_NO3_MO  [1/d] : Tasa de decaimiento por nitrificación 
            %                   considerando oxígeno
            
            % Factor que considera el efecto de oxígeno [Ad]
            FoxdNO3         = exp(-0.6);  
            % indicada en Qual2Kw como valor por defecto.
            Fd_NO3          = 0.1;
            % tasa de decaimiento por nitrificación considerando oxígeno
            % [1/d]
            obj.K_NO3_MO    = obj.Code.*0;
            obj.K_NO3_MO(:) = (0.00286.*(1-FoxdNO3).*Fd_NO3);
        end
        
        function K__MO = Params_K__MO(obj,C_NO3,MOu,K_NO3_MO,K_MO)
            % Esta función cálcula la tasa de decaimiento de la materia 
            % orgánica considerando nitrificación de nitratos y oxidación
            % de la materia orgánica
            % C_NO3     [mg/l] : Concentración de nitratos
            % MOu       [mg/l] : Concentración de materia orgánica aguas 
            %                    arriba 
            % K_NO3_MO  [1/d]  : Tasas de decaimiento de nitratos por
            %                    nitrificación considerando oxígeno 
            % K_MO      [1/d]  : Tasa de decaimiento de materia organica
            %                    por descomposición 
            % K__MO     [1/d]  : Tasa de decaimiento del fósforo inorgánico 
            %                    que combina hidrolisis del fosoforó orgánico 
            %                    y sedimentación del fósforo inorgánico
            
            % Controles para cuando las concentraciones sean cero            
            if MOu == 0
                Var = 1;
            elseif C_NO3 == 0
                Var = 0;
            else
                Var = (C_NO3./MOu);
            end
            
            % Control para que no se genere materia del determinante
            if Var > 1
                Var = 1;
            end
            
            % Tasa de decaimiento de la materia orgánica considerando 
            % nitrificación de nitratos y oxidación de la materia orgánica
            K__MO   = -(K_NO3_MO*Var) - K_MO;
        end
        
        function Model_MO(obj)
            tic
            % Esta función aplica el modelo de fósforo inorgánico
            % Inicialización de cargas en 0        
            obj.W_MO       = zeros(size(obj.Code));
            % Inicialización de concentraciones en 0 
            obj.C_MO       = zeros(size(obj.Code));
            % Inicialización de factores de asimilación en 0
            obj.FactorMO   = zeros(size(obj.Code));
            % Inicialización de acumulador de caudales
            obj.Qaccum     = zeros(size(obj.Code));
            % Inicialización de tasa de decaimiento combinada
            obj.K__MO      = zeros(size(obj.Code));
            % Asignar status de vertimientos
            obj.Update_VerStatus;
            % Cálculo parámetros
            obj.Cal_ro_MO;
            obj.Cal_teta_MO;
            % Guardar datos originales de K_NO3
            obj.VarTmp = obj.K_NO3;
            obj.K_NO3  = obj.K_NO3_MO;            
            % Activar modalidad de función
            obj.StatusFun       = true;
            % Funciones para acumulación en 1 y 2 tramos
            obj.FunNetwork_1    = 'obj.FunctionNetwork_CoDependent(Npre, Posi(i),''Model'',''MO'');';
            % Función para tramo de cabecera (cuando Posi = [])
            obj.FunNetwork_2    = 'if isempty(Posi), obj.FunctionNetwork_CoDependent(Npre, Posi,''Model'',''MO''), end;';
            % Aplicar esquema acumulativo
            obj.AnalysisNetwork_Obj;
            % Deshabilitar esquema de función
            obj.StatusFun       = false;
            % Asignar status de vertimientos
            obj.Update_VerStatus;
            % Asignar valores originlaes de KNO3
            obj.K_NO3 = obj.VarTmp;
            % Mostrar resultados
            disp(['Modelo de Materia Orgánica - Ok | Time: ',num2str(toc,'%.4f'),' Seg']);
        end
    end
    
    % ---------------------------------------------------------------------
    % Modulo - Oxígeno disuelto
    % ---------------------------------------------------------------------
    properties
        % Tasa de reaireación [1/d]
        Ka_OD
        % Tasa de decaimiento del deficit de oxígeno disuelto [1/d]
        K_DO
        % 
        K_NO3_OD
        % tasa de decaimiento del deficit de oxígeno disuelto de acuerdo 
        % con el contenido de nitrógeno amoniacal y materia orgánica 
        K__DO
    end
    
    methods            
        function Ka_OD_Model(obj,varargin)
            % Esta función cálcula la tasa de reaireación de acuerdo con
            % la expresión formulada por Tsivoglou y Neal (1976). para ríos
            % de montaña y las de O’Connor – Dubbins, Churchill y de 
            % Owens - Gibbs para ríos de planicie
            % H      [m]     : Profundidad de la lamina de agua del tramo 
            %                  de corriente
            % v      [m/s]   : Velocidad del flujo del tramo de corriente
            % Q      [m3/s]  : Caudal del tramo de corriente
            % S      [m/m]   : Pendiente del tramo de corriente
            % Ka_OD  [1/d]   : Tasa de reaireación 
            
            obj.Ka_OD       = obj.Code.*NaN;
            % Ríos de montaña
            % Formulada por Tsivoglou y Neal (1976). 
            id              = obj.RiverType&...
                              (0.0283<=obj.Q)&...
                              (obj.Q < 0.4247);
            obj.Ka_OD(id)   = 31.183.*obj.v(id).*obj.S(id);
            id              = obj.RiverType&...
                              (0.4247<=obj.Q)&...
                              (obj.Q < 84.938);
            obj.Ka_OD(id)   = 15.308.*obj.v(id).*obj.S(id);

            % Ríos de planicie         
            % O’Connor – Dubbins
            id              = ~obj.RiverType&...
                              (0.30<=obj.H)&(obj.H < 9.14)&...
                              (0.15<=obj.v)&(obj.v < 0.49);
            obj.Ka_OD(id)   = 3.95.*((obj.v(id).^0.5)./(obj.H(id).^1.5));
            
            % Churchill
            id              = ~obj.RiverType&...
                             (0.31<=obj.H)&(obj.H < 3.35)&...
                             (0.55<=obj.v)&(obj.v < 1.52);
            obj.Ka_OD(id)   = 5.026.*(obj.v(id)./(obj.H(id).^1.67));
            
            % Owens - Gibbs
            id              = ~obj.RiverType&...
                              (0.12<=obj.H)&(obj.H < 0.73)&...
                              (0.03<=obj.v)&(obj.v < 0.55);
            obj.Ka_OD(id)   = 5.32.*((obj.v(id).^0.67)./(obj.H(id).^1.85));
            
            % Thackston & Dawson, 2001
            % Aceleración de la gravedad [m/s^2]
            g   = 9.81;
            % Radio hidráulico (asumiendo cauce rectangular)
            Rn  = (obj.WB.*obj.H)./(obj.WB + (2*obj.H));
            % Velocidad de corte 
            Vc = sqrt(g.*Rn.*obj.S);
            % Número de Froude
            Fr = (obj.v.^2)./(g.*obj.L);
            % Cálculo de tasa de reaireación
            id = isnan(obj.Ka_OD);
            obj.Ka_OD(id) = 2.16.*( 1 + (9.*(Fr(id).^0.25))).*(Vc(id)./obj.H(id));
        end
        
        function K__DO = Params_K__DO(obj,C_MO,C_NH4,ODu,KdMO,K_NH4,Ka)
            % Esta función cálcula la tasa de decaimiento del deficit de 
            % oxígeno disuelto de acuerdo con el contenido de nitrógeno 
            % amoniacal y materia orgánica                        
            % C_MO      [mg/l] : Concentración de materia orgánica
            % C_NH4     [mg/l] : Concentración de nitrógeno amoniacal
            % ODu       [mg/l] : Concentración de oxígeno disuelto
            % KdMo      [1/d]  : Tasa de decaimiento por descomposición de
            %                    la amteria orgánica
            % K_NH4     [1/d]  : Tasas de decaimiento del nitrógeno amoniacal
            %                    por nitrificación considerando oxígeno 
            % Ka        [1/d]  : Tasa de reaireación
            % K__DO     [1/d]  : Tasa de decaimiento del deficit de oxígeno 
            %                    disuelto de acuerdo con el contenido de 
            %                    nitrógeno amoniacal y materia orgánica
            
            % Controles para cuando las concentraciones sean cero de
            % materia orgánica
            if ODu == 0
                Var_1 = 1;
            elseif C_MO == 0
                Var_1 = 0;
            else
                Var_1 = (C_MO./ODu);
            end
            
            % Control para que no se genere materia del determinante
            if Var_1 > 1
                Var_1 = 1;
            end
            
            % Controles para cuando las concentraciones sean cero de
            % nitrógeno amoniacal
            if ODu == 0
                Var_2 = 1;
            elseif C_NH4 == 0
                Var_2 = 0;
            else
                Var_2 = (C_NH4./ODu);
            end
            
            % Control para que no se genere materia del determinante
            if Var_2 > 1
                Var_2 = 1;
            end
            
            % Tasa de decaimiento del deficit de oxígeno disuelto de acuerdo 
            % con el contenido de nitrógeno amoniacal y materia orgánica [1/d]
            K__DO   = (KdMO*Var_1) + (4.57.*K_NH4*Var_2) - Ka;
        end
        
        function Factor = Cal_Factor_DO(obj,Q,C_ODu,C_OS,tao,Tr,Ka,Ko)
            % Esta función estima el factor de asimilación para deficit de 
            % oxígeno disuelto
            % ODu       [mg/l]  : Oxígeno disuelto aguas arriba
            % Os        [mg/l]  : Oxígeno de saturación
            % tao       [d]     : Tiempo de arribo o de advección
            % Tr        [d]     : Tiempo de residencia en zona muerta
            % Ka        [/d]    : Constante de reaireación
            % Ko        [/d]    : Constante de decaimiento del oxígeno por
            %                     consumo de la matería orgánica y por el 
            %                     nitrógeno amoniacal
            % Q         [lts]   : Caudal del tramo de río
            % Factor    [mg/l]  : Factor de asimilación del determinante            
            
            Du      = C_OS - C_ODu;
            Part_1  = ((Tr.*Ka) + 1);
            Part_2  = (Du.*exp(Ko.*tao)) + (Tr.*C_ODu.*(Ka+Ko));
            Factor  = Du.*Q.*(Part_1./Part_2);
        end
         
        function FunctionNetwork_CoDependent_DO(obj, Npre, Posi,varargin)
            % Esta función realiza el cálculo acumulativo de las
            % concentración, carga y factor de asimilación del deficit de
            % oxígeno disuelto, en el esquema acumulativo del 
            % Functional Branch.                               
            
            % Cálculo de cargas del oxígeno disuelto
            if isempty(Posi)       
                % Asignación de oxígeno de saturación en los tramos de
                % orden 1 (cabecera) - Condiciones de frontera [mg]
                obj.W_OD(Npre)  = obj.C_OS(Npre).*(obj.Q(Npre).*obj.FactorQ).*0.99;  
                % Acumulación de caudales para cálculo de
                % concentraciones aguas arriba del tramo [m3/s]
                obj.Qaccum(Npre)  = obj.Q(Npre);
            else  
                % Check para Posi mayor que dos
                if length(Posi)~=1
                    return
                end    
                % Cálculo de cargas para tramos de orden >1 [mg]
                obj.W_OD(Npre) = obj.W_OD(Npre) + (obj.C_OD(Posi).*obj.Q(Posi).*obj.FactorQ);   
                % Acumulación de caudales para cálculo de
                % concentraciones aguas arriba del tramo [m3/s]
                obj.Qaccum(Npre) = obj.Qaccum(Npre) + obj.Q(Posi);
            end
            
            % Cálculo de la concentración de oxígeno disuelto [mg]
            obj.C_OD(Npre) = obj.W_OD(Npre)./(obj.Qaccum(Npre).*obj.FactorQ); 
            
            % Check si la concentración del oxígeno disuelto es mayor a la
            % de saturación [mg/l]
            if obj.C_OD(Npre) >= obj.C_OS(Npre)
                % la C_OD nunca puede ser igual a la C_OS
                obj.C_OD(Npre) = obj.C_OS(Npre) - 0.1; %[0.1 mg/l]
                % recálculo de carga de oxígeno disuelto
                obj.W_OD(Npre) = obj.C_OD(Npre).*(obj.Q(Npre).*obj.FactorQ);
            elseif obj.C_OD(Npre) <=0
                % [0.1 mg/l]
                obj.C_OD(Npre) = 0.1; 
                % recálculo de carga de oxígeno disuelto
                obj.W_OD(Npre) = obj.C_OD(Npre).*(obj.Q(Npre).*obj.FactorQ);
            end
            
            % Cálculo de concentración de oxígeno disuelto aguas arriba [mg]
            ODu                 = obj.C_OD(Npre);       
            
            % Cálculo de constante de decaimiento [1/d]
            obj.K__DO(Npre)     = obj.Params_K__DO(obj.C_MO(Npre),obj.C_NH4(Npre),ODu,obj.KdMO(Npre),obj.K_NH4(Npre),obj.Ka_OD(Npre));
            
            % Cálculo del factor de asimilación [Ad]
            obj.FactorDO(Npre)  = obj.Cal_Factor_DO((obj.Q(Npre).*obj.FactorQ),ODu,obj.C_OS(Npre),obj.tao(Npre),obj.Tr(Npre),obj.Ka_OD(Npre),obj.K__DO(Npre));
            
%             obj.FactorDO(Npre)  = obj.Cal_Factor_CoDependent((obj.Q(Npre).*obj.FactorQ),obj.tao(Npre),obj.Tr(Npre),obj.Ka_OD(Npre),obj.K__DO(Npre),Factor,Factor2);
            
            % Cálculo de la concentración del deficit de oxígeno disuelto
            obj.C_DO(Npre)      = obj.C_OS(Npre) - obj.C_OD(Npre);                        
            
            % recálculo de carga de deficit de oxígeno disuelto [mg]
            obj.W_DO(Npre)      = obj.C_DO(Npre).*(obj.Qaccum(Npre).*obj.FactorQ);                        
            
            % Cálcular concentración de deficit de oxígeno disuelto [mg/l]
            obj.C_DO(Npre)      = obj.W_DO(Npre)./obj.FactorDO(Npre);   
            
            % Check se el deficit de oxígeno disuelo es igual a cero o a
            % oxígeno de saturación
            if obj.C_DO(Npre) <= 0
                % la C_DO nunca debe ser igual a cero [mg/l]
                % [0.1 mg/l]
                obj.C_DO(Npre) = 0.1;                 
            elseif obj.C_DO(Npre) >= obj.C_OS(Npre)
                % la C_OD nunca debe ser igual a cero [mg/l]
                % [0.1 mg/l]
                obj.C_DO(Npre) = obj.C_OS(Npre) - 0.1;           
            end
            
            % Cálcular concentración de  oxígeno disuelto [mg/l]
            obj.C_OD(Npre) = obj.C_OS(Npre) - obj.C_DO(Npre);  
            
            % Cálcular carga del oxígeno disuelto
            obj.W_OD(Npre) = obj.C_OD(Npre).*(obj.Q(Npre).*obj.FactorQ);
           
        end
        
        function Model_DO(obj)
            tic
            % Inicializar variables
            obj.Qaccum       = zeros(size(obj.Code));
            obj.W_DO       = zeros(size(obj.Code));
            obj.C_DO       = zeros(size(obj.Code));
            obj.W_OD       = zeros(size(obj.Code));
            obj.C_OD       = zeros(size(obj.Code));
            obj.FactorDO   = zeros(size(obj.Code));
            obj.K__DO      = zeros(size(obj.Code));
            % Asignar status de vertimientos
            obj.Update_VerStatus;
            % Tasa de reaireación 
            obj.Ka_OD_Model
            % Tasa de decaimiento por oxidación de materia orgánica 
            obj.KdMO_WrightMcDonnell   
            % Oxígeno de saturación
            obj.Cal_OS
            % Cla K_NH4
            obj.Params_KNH4
            % Activar modalidad de función
            obj.StatusFun       = true;
            % Funciones para acumulación en 1 y 2 tramos
            obj.FunNetwork_1    = 'obj.FunctionNetwork_CoDependent_DO(Npre, Posi(i));';
            % Función para tramo de cabecera (cuando Posi = [])
            obj.FunNetwork_2    = 'if isempty(Posi), obj.FunctionNetwork_CoDependent_DO(Npre, Posi), end;';
            % Aplicar esquema acumulativo
            obj.AnalysisNetwork_Obj;
            % Deshabilitar esquema de función
            obj.StatusFun       = false;
            % Corregir tramos paa que tengan el oxigeno de saturación
            % Asignar status de vertimientos
            obj.Update_VerStatus;
            % Mostrar resultados
            disp(['Modelo de Deficit de Oxígeno Disuelto - Ok | Time: ',num2str(toc,'%.4f'),' Seg']);
        end
    end      
        
    % ---------------------------------------------------------------------
    % Modulo - Mercurio Elemental
    % ---------------------------------------------------------------------
    properties        
        % Tasa de decaimiento del mercurio elemental por volatilización y
        % oxidación [1/d]
        K_Hg0
        % Tasa de decaimiento del mercurio elemental que combina reducción 
        % del mercurío divalente y, volatilización y oxidación del mercurío 
        % elemental [1/d]
        K__Hg0
    end
    
    methods               
        function Params_KHg0_V1(obj,varargin)
            % Tasa de decaimiento del mercurio elemental por volatilización
            % y oxidación [1/d]
            % H         [m]     : Profundidad
            % Vv        [m/d]   : Velocidad de volatilización del mercurío 
            %                     elemental
            % Kox       [1/d]   : Tasa de reacción por oxidación del 
            %                     mercurio elemental
            % Fd        [Ad]    : Fracción de mercurio elemental que se 
            %                     encuntra disuelta en el agua.
            % K_Hg0     [1/d]   : Tasa de decaimiento del mercurio elemental
            %                     por volatilización y oxidación           

            ip = inputParser;
            % Velocidad de volatilización del mercurío elemental [m/d]
            % Se toma valor por defecto indicado en WASP [10]
            addParameter(ip,'Vv',10,@isnumeric)            
            % Tasa de reacción por oxidación del mercurio elemental [1/d]
            % Se toma valor por defecto indicado en WASP [0.01]
            addParameter(ip,'Kox',0.01,@isnumeric)
            % Fracción de mercurio elemental que se encuntra disuelta en el
            % agua [Ad]. Se toma el valor de acuerdo con los datos 
            % presetnados en la Tabla del paper 
            % https://doi.org/10.3390/w13182471 De otro lado, los Kd puende
            % Ser encontrados en https://semspub.epa.gov/work/01/460491.pdf
            %
            % Es frecuente expresar el valor del logaritmo en
            % base 10 del coeficiente de partición (log Kd), dado
            % el amplio rango de valores que puede tomar Kd.
            % Valores de log Kd menores a 2.0 se asocian con
            % sustancias químicas completamente disueltas, en
            % tanto que valores superiores a 5.0 indican que la
            % especie se encuentra principalmente unida al material 
            % particulado (Thomann y Di Toro, 1983). 
%             addParameter(ip,'Fd',0.9,@isnumeric)
            % Check de datos de entrada
            parse(ip,varargin{:})
            % Velocidad de volatilización del mercurío elemental [m/d]
            Vv  = ip.Results.Vv;
            % Tasa de reacción por oxidación del mercurio elemental [1/d]
            Kox = ip.Results.Kox;
            % Fracción de mercurio elemental que se encuntra disuelta en el
            % agua [Ad]. [0 log10 (L/Kg)] - Tabla 3.
            % https://cfpub.epa.gov/si/si_public_record_report.cfm?Lab=NERL&dirEntryId=135783
            Kd  = 0;
            Fd  = 1./(1 + ((10^Kd).*(obj.C_SST./1000000)));
            % Tasa de decaimiento del mercurio elemental por volatilización
            % y oxidación [1/d]
            % [1/d]
            obj.K_Hg0    = (Fd.*(Vv./obj.H)) + Kox;
        end
        
        function Params_KHg2_V1(obj,varargin)
            % Tasa de decaimiento del mercurio divalente a mercurio 
            % elemental por reducción
            % Krx       [1/d]   : Tasa de decaimiento por reducción
            % K_Hg2     [1/d]   : Tasa de decaimiento del mercurio divalente 
            %                     a mercurio elemental por reducción        

            ip = inputParser;          
            addParameter(ip,'Krx',0.01,@isnumeric)          
            parse(ip,varargin{:})
            Krx          = ip.Results.Krx;
            obj.K_Hg2    = obj.Code.*0;
            obj.K_Hg2(:) = Krx;
        end
        
        function K__Hg0 = Params_K__Hg0(obj,C_Hg2,Hg0u,K_Hg2,K_Hg0)                        
            % Tasa de decaimiento del mercurio elemental que combina reducción 
            % del mercurío divalente y, volatilización y oxidación del mercurío 
            % elemental
            % C_Hg2 [mg/l] : Concentración de mercurio divalente
            % Hg0u  [mg/l] : Concentración de mercurio elemental aguas arriba 
            % K_Hg2 [1/d]  : Tasa de decaimiento del mercurio divalente a 
            %                mercurio elemental por reducción
            % K_Hg0 [1/d]  : Tasa de decaimiento del mercurio elemental por 
            %                volatilización y oxidación 
            % K__Hg0[1/d]  : Tasa de decaimiento del mercurio elemental que 
            %                combina reducción del mercurío divalente y, 
            %                volatilización y oxidación del mercurío 
            %                elemental
            
            % Controles para cuando las concentraciones sean cero
            if Hg0u == 0
                Var = 1;
            elseif C_Hg2 == 0
                Var = 0;
            else
                Var = (C_Hg2./Hg0u);
            end
            
            % Control para que no se genere materia del determinante
            if Var > 1
                Var = 1;
            end
            
            % Tasa de decaimiento del mercurio elemental que combina reducción 
            % del mercurío divalente y, volatilización y oxidación del mercurío 
            % elemental [1/d]
            K__Hg0    = (K_Hg2*Var) - K_Hg0;
        end
        
        function Model_Hg0(obj)  
            tic
            % Esta función aplica el modelo de mercurio elemental
            % Inicialización de cargas en 0        
            obj.W_Hg0      = zeros(size(obj.Code));
            % Inicialización de concentraciones en 0 
            obj.C_Hg0      = zeros(size(obj.Code));
            % Inicialización de factores de asimilación en 0
            obj.FactorHg0  = zeros(size(obj.Code));
            % Inicialización de acumulador de caudales
            obj.Qaccum     = zeros(size(obj.Code));
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Cálculo de tasa de decaimiento por nitrificación 
            obj.Params_KHg0_V1
            obj.Params_KHg2_V1
            % Activar modalidad de función del FunctionNetwork
            obj.StatusFun       = true;
            % Funciones para acumulación en 1 y 2 tramos
            obj.FunNetwork_1    = 'obj.FunctionNetwork_CoDependent(Npre, Posi(i),''Model'',''Hg0'');';
            % Función para tramo de cabecera (cuando Posi = [])
            obj.FunNetwork_2    = 'if isempty(Posi), obj.FunctionNetwork_CoDependent(Npre, Posi,''Model'',''Hg0''), end;';
            % Aplicar esquema acumulativo
            obj.AnalysisNetwork_Obj;
            % Deshabilitar modalidad de función del FunctionNetwork
            obj.StatusFun       = false;
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Mostrar resultados
            disp(['Modelo de Mercurio Elemental (o Metálico) - Ok | Time: ',num2str(toc,'%.4f'),' Seg']);
        end
    end
    
    % ---------------------------------------------------------------------
    % Modulo - Mercurio Divalente
    % ---------------------------------------------------------------------
    properties        
        % Tasa de decaimiento del mercurio divalente que combina,
        % sedimentación, reducción y metilización del mercurio divalente 
        % [1/d]
        K_Hg2
        % Tasa de decaimiento del mercurio divalente que combina, oxidación
        % del mercurio elemental, sedimentación, reducción y metilización 
        % del mercurio divalente [1/d]
        K__Hg2
    end
    
    methods  
        function Params_KHg0_V2(obj,varargin)
            % Tasa de decaimiento del mercurio elemental a mercurio
            % divalente por oxidación
            % Kox       [1/d]   : Tasa de decaimiento por oxidación
            % K_Hg0     [1/d]   : Tasa de decaimiento del mercurio elemental 
            %                     a mercurio divalente por oxidación       

            ip = inputParser;          
            addParameter(ip,'Kox',0.01,@isnumeric)          
            parse(ip,varargin{:})
            Kox          = ip.Results.Kox;
            obj.K_Hg0    = obj.Code.*0;
            obj.K_Hg0(:) = Kox;
        end
        
        function Params_KHg2_V2(obj,varargin)
            % Tasa de decaimiento del mercurio divalente que combina,
            % sedimentación, reducción y metilización del mercurio 
            % divalente [1/d]
            % H         [m]     : Profundidad
            % Vv        [m/d]   : Velocidad de sedimentación
            % Krx       [1/d]   : Tasa de reducción
            % Kme       [1/d]   : Tasa de metilización
            % Fp        [Ad]    : Fracción de mercurio divalente que se 
            %                     encuntra particulada en el agua.
            % K_Hg2     [1/d]   : Tasa de decaimiento del mercurio divalente 
            %                     que combina, oxidación del mercurio 
            %                     elemental, reducción y metilización del
            %                     mercurio divalente          

            ip = inputParser;
            % Velocidad de sedimentación del mercurio divalente [m/d]
            % Se toma valor por defecto indicado en WASP [10]
            addParameter(ip,'vs',0.6,@isnumeric)            
            % Tasa de reacción por reducción del mercurio divalente [1/d]
            % Se toma valor por defecto indicado en WASP [0.01]
            addParameter(ip,'Krx',0.01,@isnumeric)            
            % Tasa de metilación HgII Disuelto [1/d]
            % Se toma valor por defecto indicado en WASP [0.001]
            addParameter(ip,'Kme_d',0.001,@isnumeric)
            % Tasa de metilación HgII Adsorbido [1/d]
            % Se toma valor por defecto indicado en WASP [0.01]
            addParameter(ip,'Kme_p',0.01,@isnumeric)            
            % Fracción de mercurio divalente que se encuntra particulada
            % https://cfpub.epa.gov/si/si_public_record_report.cfm?Lab=NERL&dirEntryId=135783
            % [3.6 log10 (L/Kg)] - Tabla 3.
            Kd  = 3.6;
            Fp  = ((10^Kd).*(obj.C_SST./1000000))./(1 + ((10^Kd).*(obj.C_SST./1000000)));
            
            % Check de datos de entrada
            parse(ip,varargin{:})
            vs      = ip.Results.vs;
            Krx     = ip.Results.Krx;
            Kme_d   = ip.Results.Kme_d;
            Kme_p   = ip.Results.Kme_p;
            
            % Tasa de reacción por metilización del mercurio divalente [1/d]
            Kme     = (Fp.*Kme_p) + ((1 - Fp).*Kme_d);
            
            % Tasa de decaimiento del mercurio divalente que combina,
            % sedimentación, reducción y metilización del mercurio 
            % divalente [1/d]           
            obj.K_Hg2    = (Fp.*(vs./obj.H)) + Krx + Kme;
        end
        
        function K__Hg2 = Params_K__Hg2(obj,C_Hg0,Hg2u,K_Hg2,K_Hg0)                        
            % Esta función cálcula la tasa de decaimiento del mercurio 
            % divalente que combina, oxidación del mercurio elemental,
            % sedimentación, reducción y metilización del mercurio 
            % divalente [1/d]
            % C_Hg2  [mg/l] : Concentración de mercurio divalente
            % Hg0u   [mg/l] : Concentración de mercurio elemental aguas arriba 
            % K_Hg2  [1/d]  : Tasa de decaimiento del mercurio divalente que 
            %                 combina,sedimentación, reducción y metilización 
            %                 del mercurio divalente [1/d]
            % K_Hg0  [1/d]  : Tasa de decaimiento del mercurio elemental a 
            %                 mercurio divalente por oxidación
            % K__Hg2  [1/d] : Tasa de decaimiento del mercurio divalente que 
            %                 combina, oxidación del mercurio elemental, 
            %                 sedimentación, reducción y metilización 
            %                 del mercurio divalente [1/d]
            
            % Controles para cuando las concentraciones sean cero
            if Hg2u == 0
                Var = 1;
            elseif C_Hg0 == 0
                Var = 0;
            else
                Var = (C_Hg0./Hg2u);
            end
            
            % Control para que no se genere materia del determinante
            if Var > 1
                Var = 1;
            end
            
            % Tasa de decaimiento del mercurio divalente que combina, oxidación
            % del mercurio elemental, sedimentación, reducción y metilización 
            % del mercurio divalente [1/d]
            K__Hg2    = (K_Hg0*Var) - K_Hg2;
        end
        
        function Model_Hg2(obj)  
            tic
            % Esta función aplica el modelo de mercurio divalente
            % Inicialización de cargas en 0        
            obj.W_Hg2      = zeros(size(obj.Code));
            % Inicialización de concentraciones en 0 
            obj.C_Hg2      = zeros(size(obj.Code));
            % Inicialización de factores de asimilación en 0
            obj.FactorHg2  = zeros(size(obj.Code));
            % Inicialización de acumulador de caudales
            obj.Qaccum     = zeros(size(obj.Code));
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Cálculo de tasa de decaimiento por nitrificación 
            obj.Params_KHg0_V2
            obj.Params_KHg2_V2
            % Activar modalidad de función del FunctionNetwork
            obj.StatusFun       = true;
            % Funciones para acumulación en 1 y 2 tramos
            obj.FunNetwork_1    = 'obj.FunctionNetwork_CoDependent(Npre, Posi(i),''Model'',''Hg2'');';
            % Función para tramo de cabecera (cuando Posi = [])
            obj.FunNetwork_2    = 'if isempty(Posi), obj.FunctionNetwork_CoDependent(Npre, Posi,''Model'',''Hg2''), end;';
            % Aplicar esquema acumulativo
            obj.AnalysisNetwork_Obj;
            % Deshabilitar modalidad de función del FunctionNetwork
            obj.StatusFun       = false;
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Mostrar resultados
            disp(['Modelo de Mercurio Divalente - Ok | Time: ',num2str(toc,'%.4f'),' Seg']);
        end
    end
    
    % ---------------------------------------------------------------------
    % Modulo - Metil Mercurio
    % ---------------------------------------------------------------------
    properties        
        % Tasa de decaimiento del mercurio divalente que combina,
        % sedimentación, reducción y metilización del mercurio divalente 
        % [1/d]
        K_MeHg
        % Tasa de decaimiento del mercurio divalente que combina, oxidación
        % del mercurio elemental, sedimentación, reducción y metilización 
        % del mercurio divalente [1/d]
        K__MeHg
    end
    
    methods  
        function Params_KHg2_V3(obj,varargin)
            % Tasa de metilización del mercurio divalente           
            % Kme       [1/d]   : Tasa de metilización
            % K_Hg2     [1/d]   : Tasa de metilización del mercurio divalente          

            ip = inputParser;
            addParameter(ip,'Kme_d',0.001,@isnumeric)
            % Tasa de metilación HgII Adsorbido [1/d]
            % Se toma valor por defecto indicado en WASP [0.01]
            addParameter(ip,'Kme_p',0.01,@isnumeric)            
            % Fracción de mercurio divalente que se encuntra particulada
            % Se toma valor por defecto indicado en WASP [0.01]
            % https://cfpub.epa.gov/si/si_public_record_report.cfm?Lab=NERL&dirEntryId=135783
            % [2.7 log10 (L/Kg)] - Tabla 3.
            Kd  = 2.7;
            Fp  = ((10^Kd).*(obj.C_SST./1000000))./(1 + ((10^Kd).*(obj.C_SST./1000000)));
            
            % Check de datos de entrada
            parse(ip,varargin{:})
            Kme_d   = ip.Results.Kme_d;
            Kme_p   = ip.Results.Kme_p;
            
            % Tasa de reacción por metilización del mercurio divalente [1/d]
            Kme     = (Fp.*Kme_p) + ((1 - Fp).*Kme_d);
            
            obj.K_Hg2    = obj.Code.*0;
            obj.K_Hg2(:) = Kme;
        end
        
        function Params_KMeHg(obj,varargin)
            % Tasa de decaimiento del metil mercurio por sedimentación y
            % bioacumulación [1/d]
            % H         [m]     : Profundidad
            % Vv        [m/d]   : Velocidad de sedimentación
            % Krx       [1/d]   : Tasa de reducción
            % Kme       [1/d]   : Tasa de metilización
            % Fp        [Ad]    : Fracción de mercurio divalente que se 
            %                     encuntra particulada en el agua.
            % K_Hg2     [1/d]   : Tasa de decaimiento del mercurio divalente 
            %                     que combina, oxidación del mercurio 
            %                     elemental, reducción y metilización del
            %                     mercurio divalente          

            ip = inputParser;
            % Velocidad de sedimentación del metil mercurio [m/d]
            % Se toma valor por defecto indicado en WASP [10]
            addParameter(ip,'vs',0.5,@isnumeric)                     
            % Tasa de bioacumulación del metil mercurio [1/d]
            % Se deja cero. Es decir este proceso no se considera en el
            % modelo
            addParameter(ip,'Ku',0,@isnumeric)          
            % Fracción de metil mercurio que se encuntra particulada
            % Se toma valor por defecto indicado en WASP [0.01]
            % https://cfpub.epa.gov/si/si_public_record_report.cfm?Lab=NERL&dirEntryId=135783
            % [2.7 log10 (L/Kg)] - Tabla 3.
            Kd  = 2.7;
            Fp  = ((10^Kd).*(obj.C_SST./1000000))./(1 + ((10^Kd).*(obj.C_SST./1000000)));
            
            % Check de datos de entrada
            parse(ip,varargin{:})
            vs      = ip.Results.vs;
            Ku      = ip.Results.Ku;
        
            obj.K_MeHg    = (Fp.*(vs./obj.H)) + Ku;
        end
        
        function K__MeHg = Params_K__MeHg(obj,C_Hg2,MeHgu,K_Hg2,K_MeHg)                        
            % Esta función cálcula la tasa de decaimiento del mercurio 
            % divalente que combina, oxidación del mercurio elemental,
            % sedimentación, reducción y metilización del mercurio 
            % divalente [1/d]
            % C_Hg2  [mg/l] : Concentración de mercurio divalente
            % Hg0u   [mg/l] : Concentración de mercurio elemental aguas arriba 
            % K_Hg2  [1/d]  : Tasa de decaimiento del mercurio divalente que 
            %                 combina,sedimentación, reducción y metilización 
            %                 del mercurio divalente [1/d]
            % K_Hg0  [1/d]  : Tasa de decaimiento del mercurio elemental a 
            %                 mercurio divalente por oxidación
            % K__Hg2  [1/d] : Tasa de decaimiento del mercurio divalente que 
            %                 combina, oxidación del mercurio elemental, 
            %                 sedimentación, reducción y metilización 
            %                 del mercurio divalente [1/d]
            
            % Controles para cuando las concentraciones sean cero
            if MeHgu == 0 
                Var = 1;
            elseif C_Hg2 == 0
                Var = 0;
            else
                Var = (C_Hg2./MeHgu);
            end
            
            % Control para que no se genere materia del determinante
            if Var > 1
                Var = 1;
            end
            
            % Tasa de decaimiento del mercurio divalente que combina, oxidación
            % del mercurio elemental, sedimentación, reducción y metilización 
            % del mercurio divalente [1/d]
            K__MeHg = (K_Hg2*Var) - K_MeHg;
        end
        
        function Model_MeHg(obj) 
            tic
            % Esta función aplica el modelo de mercurio divalente
            % Inicialización de cargas en 0        
            obj.W_MeHg      = zeros(size(obj.Code));
            % Inicialización de concentraciones en 0 
            obj.C_MeHg      = zeros(size(obj.Code));
            % Inicialización de factores de asimilación en 0
            obj.FactorMeHg  = zeros(size(obj.Code));
            % Inicialización de acumulador de caudales
            obj.Qaccum      = zeros(size(obj.Code));
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Cálculo de tasa de decaimiento por nitrificación 
            obj.Params_KMeHg
            obj.Params_KHg2_V3
            % Activar modalidad de función del FunctionNetwork
            obj.StatusFun       = true;
            % Funciones para acumulación en 1 y 2 tramos
            obj.FunNetwork_1    = 'obj.FunctionNetwork_CoDependent(Npre, Posi(i),''Model'',''MeHg'');';
            % Función para tramo de cabecera (cuando Posi = [])
            obj.FunNetwork_2    = 'if isempty(Posi), obj.FunctionNetwork_CoDependent(Npre, Posi,''Model'',''MeHg''), end;';
            % Aplicar esquema acumulativo
            obj.AnalysisNetwork_Obj;
            % Deshabilitar modalidad de función del FunctionNetwork
            obj.StatusFun       = false;
            % Asignación de status de vertimientos
            obj.Update_VerStatus;
            % Mostrar resultados
            disp(['Modelo de Metil Mercurio - Ok | Time: ',num2str(toc,'%.4f'),' Seg']);
        end
    end
    
    % ---------------------------------------------------------------------
    % Funciones transversales
    % ---------------------------------------------------------------------
    methods             
        % Tasa de reacción        
        function k = Kd_ArrheniusModel(obj,varargin)
            % Esta función cálcula la tasas de reacción de diferentes 
            % determinantes 
            % T         [°C]    : Temperatura
            % Teta      [Ad]    : Factor de corrección por temperatura
            % k         [1/d]   : Tasa de interés calculada para una 
            %                     temperatura de referencia de 20°C            
            
            ip = inputParser;
            % Nombre del parámetro de entrada
            addParameter(ip, 'NameParam','CT',@ischar) 
            % Check data
            parse(ip,varargin{:})
            NameParam   = ip.Results.NameParam;

            % Parámetros internos
            switch NameParam
                case 'MO'
                    % Factor de corrección por temperatura
                    Teta    = 1.047;
                    k       = obj.Code*0;   
                    % Wright y McDonnell (1979). 
                    % El rango de aplicación de esta expresión es para caudales 
                    % entre 0.3 y 23 m3/s,
                    id      = (obj.Q >= 0.3)&(obj.Q < 23);
                    k(id)   = 1.796.*(obj.Q.^(-0.49));
                    % Por encima del rango de la ecuación, para propósitos 
                    % prácticos, puede suponerse un valor constante de 
                    % 0.30 [1/d]
                    k(~id)  = 0.3;
                    % El máximo valor de k se sugiere de 3.5 [1/d]
                    k(k>3.5)= 3.5;
                case 'NO'
                    % Factor de corrección por temperatura
                    Teta    = 1.047;
                    % Tasa de decamiento por hidrólisis para nitrógeno 
                    % orgánico (1/d)
                    k       = 0.020;
                case 'NH4'
                    % Factor de corrección por temperatura
                    Teta    = 1.047;
                    % Tasa de decamiento por hidrólisis para nitrógeno 
                    % orgánico (1/d)
                    k       = 0.020;
                case 'NO3'
                    % Factor de corrección por temperatura
                    Teta    = 1.0698;
                    % Tasa de decamiento por hidrólisis para nitrógeno 
                    % orgánico (1/d)
                    k       = 0.1;
                case 'CT'
                    % Factor de corrección por temperatura
                    Teta    = 1.07;
                    % Tasa de interés calculada para una temperatura de 20°C
                    k       = 0.8;
                case 'OD'
                    % Factor de corrección por temperatura
                    Teta    = 1.024;
            end

            % Tasas de reacción [1/d]
            k = k.*(Teta.^(obj.T - 20));   
        end
        
        
        % Update status de vertimientos        
        function Update_VerStatus(obj)
            % Esta función determina que UHM tiene presencia de
            % vertimientos para poder considerarlas en el esquema
            % acumulativo
            Tmp = obj.Ver_CT + obj.Ver_PO + obj.Ver_PI + obj.Ver_NH4 + ...
                  obj.Ver_NO + obj.Ver_MO + obj.Ver_DO + obj.Ver_T + ... 
                  obj.Ver_Hg0 + obj.Ver_Hg2 + obj.Ver_MeHg + ...
                  obj.Ver_SST;
              
            % Vector Booleano
            obj.Ver_Status = (Tmp~=0);
        end
                
        % Fracción dispersiva        
        function DF_Gonzalez(obj)
            % Esta función asigna la fracción dispersiva de acuerdo con el
            % tipo de río (Montaña o Planicie)
            % En trabajos previamente realizados (González, 2008) se ha 
            % encontrado que la fracción dispersiva (DF) para ríos de 
            % montaña tiene una magnitud global de 0.27 mientras que para 
            % ríos de planicie es de 0.40.
            % DF   [Ad] : Fracción dispersiva
            
            % Fracción dispersiva para ríos de montaña
            DF_MR   = 0.27;
            % Fracción dispersiva para ríos de planicie
            DF_PR   = 0.40;
            % Asignar valoresde fracción dispersiva
            obj.DF = obj.Code*0;
            obj.DF(obj.RiverType)   = DF_MR;
            obj.DF(~obj.RiverType)  = DF_PR;              
        end
                
        % Coeficiente de retraso efectivo       
        function Beta_Gonzalez(obj)
            % Esta función asigna el coeficiente de retraso efectivo de 
            % acuerdo con el tipo de río (Montaña o Planicie)
            % En trabajos previamente realizados (Gonzalez, 2008) se ha 
            % encontrado que el coeficiente de retraso efectivo para ríos 
            % de montaña tiene una magnitud global de 1.10 mientras que 
            % para ríos de planicie es de 2.0.
            % Beta   [Ad] : coeficiente de retraso efectivo
            
            % Coeficiente de retraso efectivo para ríos de montaña
            Beta_MR   = 1.1;
            % Coeficiente de retraso efectivo para ríos de planicie
            Beta_PR   = 2.0;
            % Asignar valores
            obj.Beta = obj.Code*0;
            obj.Beta(obj.RiverType)   = Beta_MR;
            obj.Beta(~obj.RiverType)  = Beta_PR;            
        end
                
        % Velocidad del soluto
        function Vs_Lees(obj)
            % Esta función estima la velocidad del soluto de acuerdo con la
            % relación propuesta por Lees et al. (2000),
            % Lees et al. (2000) presentó una relación entre la velocidad 
            % del flujo y la del soluto basada en la técnica de igualación 
            % de momentos entre los modelos ADZ-QUASAR y TS. De este trabajo 
            % se concluye que la relación de velocidades, tanto para ríos de 
            % planicie como para ríos de montaña, se expresa mediante el 
            % coeficiente efectivo de retraso ? (correspondiente a la 
            % relación entre las áreas transversales del canal principal y 
            % de las zonas muertas) (Camacho, 2000) (Rojas, 2011)
            % v  [m/s] : Velocidad del flujo
            % Vs [m/s] : Velocidad del soluto
            
            % Velocidad del soluto [m/s]
            obj.Vs = obj.v./(1 + obj.Beta);         
        end
                
        % Temperatura                
        function T_BarcoCuartasModel(obj)
            % Esta función estima la temperatura ambiental de acuerdo con la 
            % propuesta de Barco y Cuartas (1998). Esta corresponde a una 
            % única relación para todo el país a partir de información de 
            % 45 estaciones hidroclimatológicas del IDEAM.
            % Z     [m.s.n.m] : Elevación
            % T     [Celsius] : Temperatura media del aire
            
            obj.T = 28.3079 - (0.0056517.*obj.Z);
        end
    
        % Profundidad        
        function H_GiraldoModel(obj)    
            % Esta función estima la profundidad media de la corriente (H)
            % de acuerdo con la propuesta de Giraldo (2003).
            % A   [m2]  : Área de la UHM
            % H   [m]   : Profundidad de la corriente
            
            % Factor Área m2 -> Ha
            FactorA = 1/10000;
            k       = 1.72.*((obj.A.*FactorA).^-0.25);
            h       = 0.30.*((obj.A.*FactorA).^0.05);
            obj.H   = k.*(obj.Q.^h);
        end
            
        % Velocidad de la corriente    
        function v_RojasModel(obj) 
            % Esta función estima la velocidad de la corriente de acuerdo
            % con la propuesta de Leopold y Maddock (1953).
            % A   [m2]   : Área de la UHM
            % Q   [m3/s] : Caudal de la corriente
            % v   [m/s]  : Velocidad de la corriente 
            
            % Factor Area m2 -> Km2
            FactorA = 1/1000000;
            
            % Caudal (m3/s)
            a       = 1.4917.*((obj.A.*FactorA).^-0.275);
            b       = 2/5;
            obj.v   = a.*(obj.Q.^b);
        end
            
        % Aumulación de Área        
        function AccumArea(obj)  
            % Esta función acumila el área de los tramos hacia aguas abajo
            % A   [m2]  : Área de la UHM
            
            % Solo acumula una vez
            if ~obj.StatusAccArea
                tic
                obj.AccumVar = obj.A;
                obj.AnalysisNetwork_Obj;
                obj.BC_Status = (obj.A == obj.AccumVar);
                obj.A = obj.AccumVar;
                
                % Estado que el área ya esta cumulada
                obj.StatusAccArea = true;
                
                % Mostrar resultados
                disp(['Acumulación Ok | Time: ',num2str(toc,'%.4f'),' Seg']);
            end
        end
                
        % Oxígeno de saturación        
        function Cal_OS(obj)
            % Esta función estima la concentración de el oxígeno de 
            % saturación de la corriente de acuerdo con la propuesta de 
            % Zison et al. (1978) la cual considera corrección por elevación
            % T     [°C]        : Temperatura 
            % Z     [m.s.n.m]   : Elevación de la corriente
            % C_OS  [mg/l]      : Concentración de oxígeno disuelto
            
            % Celsius -> Kelvin
            Factor = 273.15;
            % Solo acumula 1 vez
            obj.C_OS = (1-(0.0001148.*obj.Z)).*...
                exp(-139.34411 + ...
                (1.575701E5./ ((obj.T+Factor).^1)) -...
                (6.642308E7./ ((obj.T+Factor).^2)) +...
                (1.243800E10./((obj.T+Factor).^3))-...
                (8.621949E11./((obj.T+Factor).^4)));
        end
              
        function Cal_Turbiedad(obj)
            % Esta función estima la turbiedad haciendo uso de una relación 
            % empírica con los datos recolectados por Cornare en campañas 
            % de medición ejecutadas con periodicidad variable entre 
            % 2008 y 2018 en la cuenca Fe-Pantanillo. 
            % SST  [mg/l] : Solidos suspendidos Totales
            % Turb [UNF]  : Turbiedad unidades nefelométricas de turbiedad
            
            % Factor de conversión de [mg/l] -> [Kg/m3]
            Factor = 1/1000;
            obj.Turb = 304.90*((obj.C_SST.*Factor).^0.81);
        end
        
        function Cal_WB(obj)
            % Esta función estima el ancho de banca llena de la corrinte,
            % siguindo la relación utilziada en el MCAD por John Chavarro. 
            % A   [m2]  : Área de la UHM
            % W   [m]   : ancho de banca llena
            
            % Factor Area m2 -> Km2
            FactorA = 1/1000000;
            obj.WB = 17.748*((obj.A.*FactorA).^0.3508);
        end
    end
end
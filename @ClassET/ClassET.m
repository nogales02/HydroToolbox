classdef ClassET
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
% Descripción
% -------------------------------------------------------------------------
% Esta clase es para el tratameinto de series de tiempo
%
% -------------------------------------------------------------------------
% Entradas
% -------------------------------------------------------------------------
%
% -------------------------------------------------------------------------
% Salidas
% -------------------------------------------------------------------------             
    
    methods
        function [ status ] = leapyear(obj, year )
            status = year*0;
            for i = 1:length(status)
                if mod(year(i), 400) == 0
                    status(i) = true;
                elseif mod(year(i), 4) == 0 && mod(year(i), 100) ~= 0
                    status(i) = true;
                else
                    status(i) = false;
                end
            end
        end
    end
    
    methods
        %% Evapotranspiración - Hargreaves
        ETP     = ETP_Hargreaves(obj, Tavg, TD, Ra)
        
        %% Evapotranspiración - Hargreaves Modificado
        ETP     = ETP_Hargreaves_Mod(obj, Tavg, TD, Ra, P)
        
        %% Evapotranspiración - Hargreaves Colombia
        ETP     = ETP_Hargreaves_Colombia(obj, Tavg, TD, Ra)
        
        %% Evapotranspiración - Hargreaves Samani
        ETP     = ETP_HargreavesSamani(obj, Tmax, Tmin, J, lat)

        %% Evapotranspiración - Budyko
        ETR     = ETR_Budyko_Colombia(obj, ETP, P)
        
        %% Evapotranspiración - Thornthwaite
        ETP     = ETP_Thornthwaite(obj, Tavg)
        
        %% Evapotranspiración - Blaney Criddle
        ETP     = ETP_Blaney_Criddle(obj, Tavg)
        
        %% Evapotranspiración - Jensen Haise
        ETP     = ETP_Jensen_Haise(obj, Tavg, Ra)
        
        %% Evapotranspiración - McCloud
        ETP     = ETP_McCloud(obj,Tavg)
        
        %% Evapotranspiración - McGuiness
        ETP     = ETP_McGuiness(obj, Tavg, Ra)
        
        %% Evapotranspiración - Turc Annual
        ETP     = ETP_TurcAnnual(obj, Tavg, P)
        
        %% Evaporación Autralia Linacre
        EV = EV_linacreLake(obj, Tmax, Tmin, lat, z)

        %% Radiación Extraterrestre
        [Ra, N] = Extraterrestrial_Radiation(obj, Lat, J)    
        
        %% Dias Julianos
        J       = JulianDay(obj, Date)        
    end
end
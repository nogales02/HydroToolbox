function [Ra, N] = Extraterrestrial_Radiation(obj, Lat, J)

Gsc     = 0.082; %MJ/(m^2*dia) 
Lat     = (pi()/180).*Lat;
dr      = 1 + (0.0033.*cos((2*pi()*J)/365));
decli   = 0.409.*sin( ((2*pi()*J)/365) - 1.39);
ws      = acos(-tan(Lat).*tan(decli));
% Extraterrestrial_Radiation MJ/(m^2*dia)
Ra      = ((24*60)./pi()).*Gsc.*dr.*...
          ((ws.*sin(Lat).*sin(decli)) + (cos(Lat).*cos(decli).*sin(ws))); 

%% Duración máxima de la insolación (N)
N       = (24./pi()).*ws;
      
end

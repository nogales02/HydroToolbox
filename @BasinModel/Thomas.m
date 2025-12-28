function Thomas(Basin)
% -------------------------------------------------------------------------
% Model Of Thomas - (1981) - "abcd"
%
% -------------------------------------------------------------------------
% BASE DATA
% -------------------------------------------------------------------------
% Project               : Landscape planning for agro-industrial expansion 
%                         in a large, well-preserved savanna: how to plan 
%                         multifunctional landscapes at scale for nature and 
%                         people in the Orinoquia region, Colombia
% Author                : Jonathan Nogales Pimentel
% Email                 : nogales02@hotmail.com
% Supervisor            : Carlos Andrés Rogéliz
% Company               : The Nature Conservancy - TNC
% 
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the 
% Free Software Foundation, either version 3 of the License, or option) any 
% later version. This program is distributed in the hope that it will be 
% useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
% ee the GNU General Public License for more details. You should have 
% received a copy of the GNU General Public License along with this program.  
% If not, see http://www.gnu.org/licenses/.
%
% -------------------------------------------------------------------------
% INPUT DATA 
% -------------------------------------------------------------------------
%   P       [Cat,1] = Precipitation                     [mm]
%   ETP     [Cat,1] = Potential Evapotranspiration      [mm]
%   a       [Cat,1] = Soil Retention Capacity           [Ad]
%   b       [Cat,1] = Maximum Capacity of Soil Storage  [Ad]
%   c       [Cat,1] = Flow Fraction Soil - Aquifer      [Ad]
%   d       [Cat,1] = Flow Fraction Aquifer - Soil      [Ad]
%   Sw      [Cat,1] = Soil Moinsture                    [mm]
%   Sg      [Cat,1] = Aquifer Storage                   [mm]
%
% -------------------------------------------------------------------------
% OUTPUT DATA
% -------------------------------------------------------------------------
%   Qsim    [Cat,1] = Runoff Simulated                  [mm]
%   ETR     [Cat,1] = Actual Evapotranspiration         [mm]
%   States  [Cat,1] = States Variables                  [mm]
%

%% PoPo
PoPo        = Basin.PoPo;

%% Date Cal
Date        = Basin.Date;
P           = Basin.P(:,PoPo);
ETP         = Basin.ETP(:,PoPo);

%% Dias
DayMonth = [31 28 31 30 31 30 31 31 30 31 30 31];

%% Parameters
ParamsBasin = Basin.ParamsBasin(PoPo,:);

%% Initialization of variables de estado
Sw      = P(1,:)'*0 + 100;
Sg      = Sw;

% Factor mm -> m
Factor  = 1/1000;

%% Apply GR4J for all time steps
Esc    = zeros( size(Basin.P) );
Vsim   = zeros( size(Basin.P) );
Qsim   = zeros( size(P) );

for i = 1 : length( Date )
    %% Thomas
    % Esc [mm]
    [EscTmp, Sw, Sg] = ThomasOneStep(  P(i,:)',...
                                       ETP(i,:)',...
                                       ParamsBasin,...
                                       Sw, Sg) ;    
        
    % Esc
    Esc(i,PoPo)     = EscTmp;
    
    % Volumen Basin mm -> [m^3]
    Vsim(i,PoPo)    = (Esc(i,PoPo)'.*Factor) .* (Basin.BasinArea(PoPo));
    Qsim(i,:)       = Vsim(i,PoPo)./(3600*24*DayMonth(month(Date(i))));
end

% m^3 -> m^3/s
Basin.Qsim = Qsim;

%% plot Time
% disp(['Time Execution -> ',num2str(toc,'%0.5f'),' seg'])

end

%% Step
function [Qsim, Sw, Sg] = ThomasOneStep(P, ETP, Params, Sw, Sg)

a = Params(:,1);
b = Params(:,2);
c = Params(:,3);
d = Params(:,4);

%% THOMAS HYDROLOGICAL MODEL 
% Available Soil Water
W       = P + Sw;
% Evapotranspiration Potential
Y       = ((W + b) ./ (2 * a)) - sqrt((((W + b) ./ (2 * a)).^2) - ((W .* b) ./ a));
% Soil Moisture 
Sw      = Y .* exp((-1*ETP) ./ b);
% Direct Runoff
Ro      = (1 - c) .* (W - Y);
% Aquifer reload
Rg      = c .* (W - Y); 
% Groundwater Storage
Sg      = (Rg + Sg) ./ (1 + d);
% Groundwater Discharge
Qg      = d .* Sg;
% Runoff Simulated 
Qsim    = Ro + Qg;
% Actual Evapotrasnpiration
% ETR     = Y .* (1 - exp((-1*ETP) ./ b) );


end

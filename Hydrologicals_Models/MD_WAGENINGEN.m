function [Qs,inter,param] = MD_WAGENINGEN(obj, x, P, E, Qb, states)
%
% WAGENINGEN (Wageningen Agricultural University, Netherlands)
%
% Modified version : only 8 parameters
% Delay on final discharge
%
%
% INPUTS (time series of daily observations [n,1])
% P = mean areal rainfall (mm)
% E = mean areal evapotranspiration (mm)
% Q = stream flow (mm)
% x = the ten model parameters (see "param" below) - [8,1]
%
% OUTPUTS
% Qs = simulated stream flow (mm)
% perf = model performances
% inter = WAGENINGEN's internal values
% param -->
% .x(1) = seuil de vidange des percolations
% .x(2) = capacité maximale du réservoir sol
% .x(3) = constante de vidange des infiltrations
% .x(4) = paramètre des remontées capillaires
% .x(5) = paramètre de dissociation des écoulements
% .x(6) = constante de vidange de l’écoulement rapide
% .x(7) = constante de vidange de l’écoulement lent
% .x(8) = délai
%
% .S = Réservoir sol (mm)
% .R = Réservoir de routage rapide (mm)
% .T = Réservoir de routage lent (mm)
%
% FOLLOWING
% Warmerdam et al. (1993)
% 
%
% Program : G. Seiller (U. Laval, 2010)

%% Input 
param.x = x;

if isempty(states)
    param.S = 100;
    param.R = 0;
    param.T = 100;
else
    param.S = states.S;
    param.R = states.R;
    param.T = states.T;
end

x(8) = round(x(8));

% Apply WAGENINGEN for all time steps
%
lP = length( P ) ;
Qs = zeros(lP+x(8),1);
inter = zeros( lP+x(8),7);

for i = 1 : lP
    [Qs(i+x(8)),param,inter(i+x(8),:)] = WAGENINGENonestep( P(i), E(i), param, Qb(i) ) ;
end

%% mm to m3/seg
Qs = Qs*(1/1000)*obj.Area*(1/(3600*24));
end


function [Q,param,inter] = WAGENINGENonestep( P, E, param, Qb ) % Introduce Flowbase
% [Q,param,inter] = WAGENINGENonestep( P, E, param )
%
% The WAGE model as such.
%

% get parameters
%
x = param.x ;
S = param.S ;
R = param.R ;
T = param.T ;

%%% PRODUCTION PART

% Soil storage (S)
%
S = S+P;

if S >= x(1)
    Is = (S/x(2))*((S-x(1))/x(3));
    It = 0;
else
    Is = 0;
    It = (T/x(4))*(x(1)-S);
end

S = S+It-Is;

if S >= x(1)
    Es = E;
else
    Es = E*cos((pi/2)*((x(1)-S)/x(1)));
end
    
S = max(0,S-Es);

DIV = min(1,T/x(5));

T = T+(1-DIV)*Is;

R = R+DIV*Is;

%%% ROUTING
%
% Quick routing storage (R)
%
Qr = R/x(6);
R = R-Qr;

% Slow routing storage (T)
%
Qt = T/(x(6)*x(7));
T = T-Qt;

% Total discharge
%
Q = Qr + Qt + Qb;

% Data
param.S = S;
param.R = R;
param.T = T;

inter = [ S R T Is It Qr Qt ];
end

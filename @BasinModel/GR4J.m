function GR4J(Basin)
%
% GR4J global hydrological model
%
% INPUTS (time series of daily observations [n,1])
% P       = mean areal rainfall (mm)
% E       = mean areal evapotranspiration (mm)
% Q       = stream flow (mm)
% x       = the four model parameters (see "param" below) - [4,1]
% 
% OUTPUTS
% Qs      = simulated stream flow (mm)
% perf    = model performances
% inter   = GR4J's internal values
% param -->
%   .x(1) = maximum capacity of the production store (mm)
%   .x(2) = groundwater exchange coefficient (mm)
%   .x(3) = one-day-ahead maximum capacity of the routing store (mm)
%   .x(4) = time base of unit hydrograph UH1 (day)
%   .B    = fraction of Pr routed by UH1 (fixed to 0.9)
%   .S    = production store level (mm)
%   .R    = routing store level (mm)
%   .UH1  = Unit hydrograph 1 - rapid flow
%   .UH2  = Unit hydrograph 2 - slower flow
%   .H1   = Hydrograph 1 values (mm) - updated at each time step
%   .H2   = Hydrograph 2 values (mm) - updated at each time step
%
% FOLLOWING
% Perrin C, Michel C & Andréassian V. 2003. Improvement of a parsimonious 
%    model for stramflow simulation. J. Hydrol. 279, 275-289.
%
% F.Anctil, Univ. Laval (01-2009)

%% PoPo
PoPo        = Basin.PoPo;

%% Date Cal
Date        = Basin.Date;
P           = Basin.P(:,PoPo);
ETP         = Basin.ETP(:,PoPo);

%% Parameters
ParamsBasin = Basin.ParamsBasin(PoPo,:);

%% Initialization of the reservoir states
B   = 0.9 + (ParamsBasin(:,1).*0);
S   = 0.5 .* ParamsBasin(:,1);
R   = 0.5 .* ParamsBasin(:,3);
UH1 = {};
H1  = {};
UH2 = {};
H2  = {};
x4c = ceil( ParamsBasin(:,4) ) ;
for i = 1:length(x4c)
    % UH1 initialization --> the last one always has a value of 1   
    t       = ( 0:x4c(i) )' ;
    SH1     = [( t(1:end-1)./ParamsBasin(i,4) ) .^2.5; 1] ;
    UH1{i}  = diff(SH1) ;
    H1{i}   = zeros(size(UH1{i})) ;
    
    % UH2 initialization --> An imaginary part is produced when t > 2x4 
    t2      = ( x4c(i) + 1:2*x4c(i) )' ;
    SH2     = [ 0.5*(t/ParamsBasin(i,4)).^2.5; 1-0.5*(2-t2/ParamsBasin(i,4)).^2.5 ] ;
    SH2     = real( SH2 ) ;
    UH2{i}  = diff( SH2 ) ;
    H2{i}   = zeros( size(UH2{i}) ) ;
end

% Factor mm -> m
Factor      = 1/1000;

%% Apply GR4J for all time steps
Esc    = zeros( size(Basin.P) );
Vsim   = zeros( size(Basin.P) );
if Basin.Status_ModelFlood
    EscB   = zeros( size(Basin.P) );
    Vh     = zeros( size(Basin.P) );
end

tic 
for i = 1 : length( Date )       
    %% GR4J
    % Esc [mm]
    [EscTmp, S, R, H1, H2] = GR4Jonestep(  P(i,:)',...
                                           ETP(i,:)',...
                                           ParamsBasin,...
                                           S, R, B, UH1, UH2, H1, H2) ;    
        
    % Esc
    Esc(i,PoPo)   = EscTmp;
    
    % Volumen Basin mm -> [m^3]
    Vsim(i,PoPo)  = (Esc(i,PoPo)'.*Factor) .* (Basin.BasinArea(PoPo));

    %% Network 
    if Basin.Status_ModelFlood
        [~,VAcc,States] = Basin.AnalysisNetwork_Flood(...
                            [Basin.BasinArea, Vsim, Basin.Demands(i,:)', Basin.Returns(i,:)'],...
                            [Basin.FloodArea,...
                            Basin.P(i,:)',...
                            Basin.ETP(i,:)',...
                            Vh(i,:)',... 
                            Basin.ParamsFlood,...
                            Basin.ID_Demand,...
                            Basin.ID_Return]);
    
        %% Asigantion
        Vh(i,:)     = States(:,4);
    
        %% Flow
        EscB(i,:)   = VAcc(:,2);
    else
        if ~isempty(Basin.Demands)&&~isempty(Basin.Returns)
            Vsim(i,PoPo)  = Vsim(i,PoPo) - Basin.Demands(i,PoPo) + Basin.Returns(i,PoPo);
        end
    end

end
% Varible States Flood
if Basin.Status_ModelFlood
    Basin.StatesFlood   = Vh;
end

% m^3 -> m^3/s
Basin.Qsim          = Vsim(:,PoPo)./(3600*24);

%% plot Time
% disp(['Time Execution -> ',num2str(toc,'%0.5f'),' seg'])

end

%% Step
function [Q, S, R, H1, H2] = GR4Jonestep( P, E, x, S, R, B, UH1, UH2, H1, H2)
%
% The GR4J model as such.
% F.Anctil, Univ. Laval (01-2009)
E       = round(E, 2);
P       = round(P, 2);
x       = round(x, 2);

%% PRODUCTION PART
Pn      = NaN(size(P));
En      = NaN(size(P));
tilap1  = NaN(size(P));
tilap2  = NaN(size(P));
Ps      = NaN(size(P));
Es      = NaN(size(P));
Perc    = NaN(size(P));
Qd      = NaN(size(P));

%% Net inputs
Pn( P >= E )    = P( P >= E ) - E( P >= E );
En( P >= E )    = 0;
En( P < E )     = E( P < E ) - P( P < E );
Pn( P < E )     = 0;

%% Soil moisture accounting
tilap1(Pn > 0)  = S(Pn > 0) ./ x((Pn > 0),1) ;
tilap2(Pn > 0)  = tanh( Pn(Pn > 0) ./ x((Pn > 0),1) ) ;
Ps(Pn > 0)      = ( x((Pn > 0),1).*( 1 - tilap1(Pn > 0).^2 ).*tilap2(Pn > 0) ) ./ ( 1 + tilap1(Pn > 0).*tilap2(Pn > 0) ) ;
Es(Pn > 0)      = 0 ;

tilap1(Pn <= 0) = S(Pn <= 0) ./ x((Pn <= 0),1) ;
tilap2(Pn <= 0) = tanh( En(Pn <= 0) ./ x((Pn <= 0),1) ) ;
Es(Pn <= 0)     = ( S(Pn <= 0).*(2-tilap1(Pn <= 0)).*tilap2(Pn <= 0) ) ./ ( 1+(1-tilap1(Pn <= 0)).*tilap2(Pn <= 0) ) ;
Ps(Pn <= 0)     = 0 ;
    
S = S - Es + Ps ;

%% Percolation
Choco           = x(:,1)./S > 0.001 ;
Choco1          = x(:,1)./S <= 0.001 ;
Perc( Choco )   = S(Choco) .* ( 1- ( 1+ (4.*S(Choco)./9./x(Choco,1)).^4).^-0.25 ) ;
S( Choco )      = S(Choco) - Perc(Choco) ;
Perc( Choco1 )  = 0 ;

Pr = Pn - Ps + Perc ;

%% ROUTING
% Mise à jour des hydrogrammes 1 & 2
for i = 1:length(P)
    H1{i} = [H1{i}(2:end); 0] + UH1{i} .* Pr(i) .* B(i);
    H2{i} = [H2{i}(2:end); 0] + UH2{i} .* Pr(i) .* (1-B(i));
end

% Calcul de l'échange
F = x(:,2) .* (R./x(:,3)).^3.5 ;
      
% Mise à jour du niveau du réservoir de routage
for i = 1:length(P)
    R(i) = max( [0.001.*x(i,3); R(i) + H1{i}(1) + F(i)] ) ;
end


% Calcul de la vidange du réservoir de routage et mise à jour du niveau
Qr  = R .* ( 1 - ( 1 + (R./x(:,3)).^4 ).^-0.25 ) ;
R   = R - Qr ;
     
% Calcul de la composante pseudo-direct de l'écoulement
for i = 1:length(P)
    Qd(i) = max( [0; H2{i}(1) + F(i)] ) ;
end

% Calcul du débit total
Q = Qr + Qd;

Q = round(Q,1);
%inter = [Es Ps S Perc Pr F R Qr Qd ];

end

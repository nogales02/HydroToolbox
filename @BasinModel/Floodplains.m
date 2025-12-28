function [Q, Vh, Ql, Rl] = Floodplains(P, ETP, Q, AreaFlood, Vh, Trp, Tpr, Q_Umb, V_Umb)
% -------------------------------------------------------------------------
% Matlab Version - R2018b 
% -------------------------------------------------------------------------
%                              BASE DATA 
% -------------------------------------------------------------------------
% 
% Author      : Jonathan Nogales Pimentel
% Email       : jonathannogales02@gmail.com
% Date        : November, 2017
% 
% -------------------------------------------------------------------------
%                               DESCRIPTION 
% -------------------------------------------------------------------------
%
% This function estimates the precipitation fields through the Ordinary 
% Kriging method.
%
%--------------------------------------------------------------------------
%                               INPUT DATA 
%--------------------------------------------------------------------------
%
%   P           [1,1]   = Precipitation                                         [mm]
%   ETP         [1,1]   = Potential Evapotranspiration                          [mm]
%   Q           [1,1]   = Streamflow                                            [m^3]
%   AreaFlood   [1,1]   = Area of the Floodplain                                [m^2]
%   Vh          [1,1]   = Volume of the floodplain Initial                      [mm]
%   Trp         [1,1]   = Percentage lateral flow between river and floodplain  [dimensionless]
%   Tpr         [1,1]   = Percentage return flow from floodplain to river       [dimensionless]
%   Q_Umb       [1,1]   = Threshold lateral flow between river and floodplain   [m^3]
%   V_Umb       [1,1]   = Threshold return flow from floodplain to river        [mm]
%   b           [1,1]   = Maximum Capacity of Soil Storage                      [dimensionless]
%   Y           [1,1]   = Evapotranspiration Potential                          [mm]
%
%--------------------------------------------------------------------------
%                              OUTPUT DATA 
%--------------------------------------------------------------------------
%
%   Q           [1,1]   = Streamflow                                 [m^3]
%   Vh          [1,1]   = Volume of the floodplain Initial           [mm]
%   Ql          [1,1]   = Lateral flow between river and floodplain  [mm]
%   Rl          [1,1]   = Return flow from floodplain to river       [mm]
%
%--------------------------------------------------------------------------
%                              REFERENCES
%--------------------------------------------------------------------------
%
% Floodplains hydrologic dynamics (Angarita, 2017)
% http://revistas.javeriana.edu.co/index.php/iyu/article/view/1137/807
%

%% Lateral flow between river and floodplain
if Q > Q_Umb
    Ql = Trp * (Q - Q_Umb);
else
    Ql = 0;
end

%% Return flow from floodplain to river
if Vh > V_Umb
    Rl = Tpr * (Vh - V_Umb);
else
    Rl = 0;
end

%% Streamflow
Q       = Q - Ql + Rl;

%% Volume of the floodplain
Vh      = Vh + Ql - Rl + (AreaFlood*((P - ETP)/1000));

%% Filter
if Vh < 0 
    Vh = 0;
end

if Q < 0 
    Q = 0;
end

end
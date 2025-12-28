function E0 = EV_linacreLake(obj, Tmax, Tmin, lat, z)
% LINACRELAKEEVAPMAT  Evaporación de lámina libre (lago/embalse) según Linacre (matricial).
%
%   E0 = linacreLakeEvapMat(Tmax, Tmin, lat, z)
%
% Descripción:
%   Estima la evaporación de un lago o embalse (E0, mm/día) usando la
%   formulación simplificada de Penman propuesta por Linacre (1977, 1993),
%   para condiciones con datos limitados. La función está vectorizada para
%   trabajar con múltiples estaciones y series largas sin bucles explícitos.
%
% Entradas:
%   Tmax : Matriz [Ndias x Nest] con temperatura máxima diaria (°C).
%   Tmin : Matriz [Ndias x Nest] con temperatura mínima diaria (°C).
%          Debe tener la misma dimensión que Tmax.
%   lat  : Vector [1 x Nest] o [Nest x 1] con latitud en grados decimales
%          (N > 0, S < 0) para cada estación.
%   z    : Vector [1 x Nest] o [Nest x 1] con altitud (m s.n.m.) de cada
%          estación.
%
% Salida:
%   E0   : Matriz [Ndias x Nest] con evaporación de lámina libre (mm/día)
%          para cada día y estación.
%
% Detalles del método:
%   - Temperatura media:  T = (Tmax + Tmin)/2
%   - Rango diario:      R = Tmax - Tmin
%   - Rango anual (Rann) para cada estación: diferencia entre la T media
%     diaria máxima y mínima del periodo disponible:
%       Rann(j) = max(T(:,j)) - min(T(:,j))
%   - Estimación (T - Td) (Linacre):
%       (T - Td) = 0.0023*z + 0.37*T + 0.53*R + 0.35*Rann - 10.9
%   - Ajuste por altitud: Tm = T + 0.006*z
%   - Latitud absoluta:   A = |lat|
%   - Evaporación de lago (mm/día):
%       E0 = [500*Tm/(100 - A) + 15*(T - Td)] / (80 - T)
%
% Referencias:
%   Linacre, E.T. (1977). A simple formula for estimating evaporation
%     rates in various climates, using temperature data alone.
%     Agricultural Meteorology, 18: 409–424.
%   Linacre, E.T. (1993). Data-sparse estimation of lake evaporation,
%     using a simplified Penman equation. Agricultural and Forest
%     Meteorology, 64: 237–256.
%
% Notas:
%   - Probado en MATLAB R2024b.
%   - El método se desarrolló originalmente para promedios mensuales;
%     aplicado a datos diarios introduce más ruido, pero es útil cuando
%     solo se dispone de Tmax/Tmin.
%
% ---------------------------------------------------------------------

% -------- 1. Comprobaciones básicas de dimensiones ----------------
if ~isequal(size(Tmax), size(Tmin))
    error('Tmax y Tmin deben tener la misma dimensión [Ndias x Nestaciones].');
end

[Ndias, Nest] = size(Tmax);

lat = lat(:).';  % asegurar fila [1 x Nest]
z   = z(:).';    % asegurar fila [1 x Nest]

if numel(lat) ~= Nest || numel(z) ~= Nest
    error('lat y z deben tener tantas entradas como columnas (estaciones) tiene Tmax/Tmin.');
end

% -------- 2. Temperatura media y rango diario ---------------------
T = (Tmax + Tmin) / 2;   % [Ndias x Nest]
R = Tmax - Tmin;         % [Ndias x Nest]

% -------- 3. Rango anual por estación (Rann) ----------------------
% Rann(j) = max(T(:,j)) - min(T(:,j))
Tmax_mean = max(T, [], 1);   % [1 x Nest]
Tmin_mean = min(T, [], 1);   % [1 x Nest]
Rann = Tmax_mean - Tmin_mean; % [1 x Nest]

% Expandir Rann, z y lat a [Ndias x Nest] por broadcasting
Rann_mat = ones(Ndias, 1) * Rann;  % [Ndias x Nest]
z_mat    = ones(Ndias, 1) * z;     % [Ndias x Nest]
A_mat    = ones(Ndias, 1) * abs(lat); % [Ndias x Nest]

% -------- 4. Ajuste por altitud (Tm) ------------------------------
Tm = T + 0.006 .* z_mat;      % [Ndias x Nest]

% -------- 5. (T - Td) según Linacre -------------------------------
% (T - Td) = 0.0023*z + 0.37*T + 0.53*R + 0.35*Rann - 10.9
T_minus_Td = 0.0023 .* z_mat + 0.37 .* T + 0.53 .* R + ...
             0.35 .* Rann_mat - 10.9;    % [Ndias x Nest]

% -------- 6. Evaporación de lago (mm/día) -------------------------
% E0 = (500*Tm/(100 - A) + 15*(T - Td)) / (80 - T)
denom1 = (100 - A_mat);   % evita divisiones repetidas
denom2 = (80  - T);

E0 = (500 .* Tm ./ denom1 + 15 .* T_minus_Td) ./ denom2;


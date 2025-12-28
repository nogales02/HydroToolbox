function ETo = ETP_HargreavesSamani(obj, Tmax, Tmin, J, lat)
% ETP_HARGREAVESSAMANI  Evapotranspiración de referencia (ETo) con
%                        Hargreaves-Samani (1985), vectorizada.
%
%   ETo = ETP_HargreavesSamani(Tmax, Tmin, J, lat)
%
% Entradas:
%   Tmax : [Ndias x Nest] temperatura máxima diaria (°C)
%   Tmin : [Ndias x Nest] temperatura mínima diaria (°C)
%   J    : [Ndias x 1]  o [Ndias x Nest] día juliano (1–365/366)
%   lat  : [1 x Nest] o [Nest x 1] latitud en grados decimales
%          (N positivo, S negativo)
%
% Salida:
%   ETo  : [Ndias x Nest] evapotranspiración de referencia (mm/día)
%
% Notas:
%   - Ra se calcula en MJ/m²/día (FAO-56) y luego se pasa a mm/día
%     con el factor 0.408.
%   - Si en algún día Tmin > Tmax, se INTERCAMBIAN (no se pone 0),
%     porque es claramente un problema de datos.
%
% Referencias:
%   Hargreaves & Samani (1985), Allen et al. (1998, FAO-56).

% ---------- 1. Comprobaciones de dimensiones ----------
if ~isequal(size(Tmax), size(Tmin))
    error('Tmax y Tmin deben tener la misma dimensión [Ndias x Nest].');
end
[Ndias, Nest] = size(Tmax);

% J puede venir como vector columna [Ndias x 1] o matriz [Ndias x Nest]
if isvector(J)
    if numel(J) ~= Ndias
        error('J debe tener Ndias elementos.');
    end
    J = J(:);                       % [Ndias x 1]
    J = repmat(J, 1, Nest);         % [Ndias x Nest]
else
    if ~isequal(size(J), size(Tmax))
        error('J debe ser [Ndias x 1] o [Ndias x Nest].');
    end
end

% lat como fila [1 x Nest]
lat = lat(:).';                     % fila
if numel(lat) ~= Nest
    error('lat debe tener una entrada por estación (Nest columnas).');
end

% ---------- 2. Corregir casos Tmin > Tmax ----------
Tmax_corr = Tmax;
Tmin_corr = Tmin;
maskSwap  = Tmin_corr > Tmax_corr;  % mismos [Ndias x Nest]

if any(maskSwap(:))
    tmp              = Tmax_corr(maskSwap);
    Tmax_corr(maskSwap) = Tmin_corr(maskSwap);
    Tmin_corr(maskSwap) = tmp;
    warning('Se intercambiaron Tmax y Tmin en algunos días (Tmin > Tmax).');
end

% Temperatura media y rango
Tmean = (Tmax_corr + Tmin_corr) ./ 2;   % [Ndias x Nest]
Tdiff = Tmax_corr - Tmin_corr;         % >= 0 garantizado

% ---------- 3. Parámetros astronómicos ----------
phi = deg2rad(lat);       % [1 x Nest] en radianes
phi = repmat(phi, Ndias, 1);   % [Ndias x Nest]

% Día juliano como double
Jd = double(J);

% Declinación solar (delta) [rad]
delta = 0.409 .* sin((2.*pi./365) .* Jd - 1.39);  % [Ndias x Nest]

% Distancia relativa Tierra–Sol
dr = 1 + 0.033 .* cos((2.*pi./365) .* Jd);        % [Ndias x Nest]

% Ángulo horario al ocaso (ws) [rad]
x  = -tan(phi) .* tan(delta);
% Por seguridad numérica, acotar a [-1, 1]
x  = max(min(x, 1), -1);
ws = acos(x);                                     % [Ndias x Nest]

% ---------- 4. Radiación extraterrestre Ra ----------
Gsc = 0.0820;  % MJ m-2 min-1
Ra_MJ = (24.*60./pi) .* Gsc .* dr .* ...
        (ws .* sin(phi) .* sin(delta) + cos(phi) .* cos(delta) .* sin(ws));
% convertir a mm/día equivalente
Ra_mm = 0.408 .* Ra_MJ;

% ---------- 5. Ecuación de Hargreaves–Samani ----------
ETo = 0.0023 .* (Tmean + 17.8) .* sqrt(Tdiff) .* Ra_mm;

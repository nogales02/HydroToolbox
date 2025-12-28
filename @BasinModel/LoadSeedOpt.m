function LoadSeedOpt(Basin)

NameFile    = fullfile(Basin.PathProject, 'INPUTS','8_SeedOpt');

% Leer semilla 
Data    = readmatrix(NameFile);
Code    = Data(:,1);
Data    = Data(:,2:end);

% Asignar datos semilla
nG = length(Basin.GaugesID);
nF = length(Basin.ParamsFlood(1,:));
nB = length(Basin.ParamsBasin(1,:));
Basin.ParamsSeed   = NaN(nG,nF + nB);

[id, posi] = ismember(Code,Basin.GaugesID);

Basin.ParamsSeed(posi(id),1:nF) = Data(id,1:nF);
Basin.ParamsSeed(posi(id),nF + 1:nF + nB) = Data(id,nF + 1:nF + nB);

for i = 1:nF + nB
    id = isnan(Basin.ParamsSeed(:,i));
    
    if sum(id)>0
        bl  = Basin.bl(i);
        bu  = Basin.bu(i);

        % Número de variables a optimizar
        nopt    = length(bl);
        % Máximo número de iteraciones
        npt     = sum(id);
        % Rango de variación de los parámetros
        bound   = bu-bl;

        %% Generación de parametros a evaluar con latin hypercube design
        try    
            rlhs    = lhsdesign(npt, nopt);
            x       = repmat(bl, npt, 1) + repmat(bound, npt, 1).*rlhs;
        catch
            x       = repmat(bl, npt, 1) + repmat(bound, npt, 1).*rand(npt, nopt);
        end
        Basin.ParamsSeed(id,i) = x;
    end
end
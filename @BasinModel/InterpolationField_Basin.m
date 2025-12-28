function Values = InterpolationField_Basin(Basin, TimeSeriesGauges, Method, Var, PathDEM, varargin)

%% INPUT
if nargin==6
    ThresholdDist_Min  = varargin{1};    
else
    ThresholdDist_Min   = 30000;
end
if nargin==7
    Threshol_NumGauges = varargin{2};
else
    Threshol_NumGauges  = 3;
end
ThresholdDist       = ThresholdDist_Min;

%% Read DEM
DEM     = GRIDobj(PathDEM);
Z       = single(DEM.Z);
Tmp     = DEM.georef.SpatialRef;
XDEM    = linspace(Tmp.XWorldLimits(1), Tmp.XWorldLimits(2),DEM.size(2))';
YDEM    = linspace(Tmp.YWorldLimits(2), Tmp.YWorldLimits(1),DEM.size(1))';

%% Read UHA 
XGauges     = reshape(TimeSeriesGauges.X,[],1);
YGauges     = reshape(TimeSeriesGauges.Y,[],1);
XBasin      = Basin.XBasin;
YBasin      = Basin.YBasin;
BoundingBox = Basin.BoundingBox;

%% Clip Date Interpolation
[id, posi] = ismember(Basin.Date, TimeSeriesGauges.Date);
if sum(id) ~= length(Basin.Date)
    error('Error')
end
Data = TimeSeriesGauges.Data(posi,:);
Date = TimeSeriesGauges.Date(posi);

%% Create Grid
Xp = cell(length(Basin.Code),1);
Yp = cell(length(Basin.Code),1);
Zp = cell(length(Basin.Code),1);

for k = 1:length(Basin.Code) 
    % Extent
    ExtentBasin = BoundingBox{k};

    % Select Box
    x           = [ExtentBasin(1,1), ExtentBasin(2,1)];
    y           = [ExtentBasin(1,2), ExtentBasin(2,2)];            
    Tmp1        = find( (XDEM >= x(1)) & (XDEM <= x(2)) );
    Tmp2        = find( (YDEM >= y(1)) & (YDEM <= y(2)) );

    if ~isempty(Tmp1) && ~isempty(Tmp2)
        [P1,~]      = ind2sub(size(XDEM), Tmp1([1, end]));
        [P2,~]      = ind2sub(size(YDEM), Tmp2([1, end]));
        [XX, YY]    = meshgrid(XDEM(P1(1):P1(2)), YDEM(P2(1):P2(2)));
        ZZ          = Z(P2(1):P2(2),P1(1):P1(2));            

        % Select Points
        id      = inpolygon(XX, YY, XBasin{k}, YBasin{k});
        if sum(id) == 0
            id = logical(id + 1);
        end
    else
        Tmp1        = find( (XDEM >= (x(1) - (1*(XDEM(2) - XDEM(1))))) & (XDEM <= (x(2)) + (1*(XDEM(2) - XDEM(1)))));
        Tmp2        = find( (YDEM >= (y(1) - (1*(XDEM(2) - XDEM(1))))) & (YDEM <= (y(2)) + (1*(XDEM(2) - XDEM(1))))); 
        [P1,~]      = ind2sub(length(XDEM), Tmp1([1, end]));
        [P2,~]      = ind2sub(length(YDEM), Tmp2([1, end]));
        [XX, YY]    = meshgrid(XDEM(P1(1):P1(2)), YDEM(P2(1):P2(2)));
        ZZ          = Z(P2(1):P2(2),P1(1):P1(2));

        id = logical(ZZ*1);
    end

    Xp{k}       = reshape(XX(id),[],1);
    Yp{k}       = reshape(YY(id),[],1);
    Zp{k}       = reshape(ZZ(id),[],1);
    
    %% Disp
    disp(['Code - ', num2str(Basin.Code(k))])
end

% Porcentaje de aumento 
FactorDist = [1.2 1.4 1.6 1.8 2 3 4 5 6 7 8 9 10 15 20 30 50 100 500 1000];

%% Interpolation
Values = NaN(length(Basin.Date),length(Basin.Code));

if strcmp(Method, 'Kriging')
    for w = 1:length(Date)
        if sum(~isnan(Data(w,:))) > 2
            id = ~isnan(Data(w,:));
            vstruct = SemivariogramSetting(XGauges(id), YGauges(id), Data(w,id)');
            DataTmp = Data(w,:)';

            parfor k = 1:length(Basin.Code) 
                Values(w,k) = mean(PrecipitationFields(XGauges, YGauges, DataTmp, Xp{k}, Yp{k}, vstruct), 'omitnan');
            end
            disp(['Date ', datestr(Date(w)),' Ok'])
        else
            disp(['Date ', datestr(Date(w)),' Error'])
        end
    end
    
elseif strcmp(Method, 'IDW_Dinamic')    
        
    for w = 1:length(Date)
        % Poco = cell(1,length(Basin.Code));
        if sum(~isnan(Data(w,:))) > 2
            id = ~isnan(Data(w,:));
            
            % Distance
            tic
            parfor k = 1:length(Basin.Code)
                % Estimación de distancia a las estaciones que tiene datos
                % disponibles
                Dist    = sqrt( (Xp{k} - XGauges(id)').^2 + (Yp{k} - YGauges(id)').^2 );
                
                ThresholdDist = Dist*0 + ThresholdDist_Min;                
                for j = 1:length(FactorDist)
                    Tre = sum(Dist < ThresholdDist,2);
                    ThresholdDist(Tre<2,:) = ThresholdDist_Min.*FactorDist(j);
                    if min(Tre) > Threshol_NumGauges
                        break
                    end
                end

                % Estimation Values  
                Beta    = 2;
                dis     = 1 ./ (Dist .^ Beta);
                dis(Dist > ThresholdDist) = 0; 
                dis(isinf(dis)) = 0;    
                % Poco{k} = sum( Data(w,id).*(dis./ sum(dis,2,'omitnan')), 2, 'omitnan');
                Values(w,k) = mean( sum( Data(w,id).*(dis./ sum(dis,2,'omitnan')), 2, 'omitnan'), 'omitnan');
            end            
            
            % Fig = figure('Visible','off');
            % hold on
            % for wo = 1:length(Basin.Code)
            %     scatter(Xp{wo},Yp{wo},2,Poco{wo},'filled')
            %     disp(['Code - ', num2str(Basin.Code(wo))])
            % end
            disp(['Date ', datestr(Date(w)),' Ok | Time = ', num2str(toc),' seg'])
        else
            disp(['Date ', datestr(Date(w)),' Error | Time = ', num2str(toc),' seg'])            
        end
    end    
    
elseif strcmp(Method, 'IDW')    

    for w = 1:length(Date)
        if sum(~isnan(Data(w,:))) > 2
            id = ~isnan(Data(w,:));
            
            % Distance
            tic
            for k = 1:length(Basin.Code)
                
                Dist    = sqrt( (Xp{k} - XGauges(id)').^2 + (Yp{k} - YGauges(id)').^2 );
                               
                % Estimation Values  
                Beta    = 2;
                dis     = 1 ./ (Dist .^ Beta);
                dis(Dist > ThresholdDist) = 0; 
                dis(isinf(dis)) = 0;    
                Values(w,k) = mean( sum( Data(w,id).*(dis./ sum(dis,2,'omitnan')), 2, 'omitnan'), 'omitnan');
            end
            
            disp(['Date ', datestr(Date(w)),' Ok | Time = ', num2str(toc),' seg'])
        else
            disp(['Date ', datestr(Date(w)),' Error | Time = ', num2str(toc),' seg'])            
        end
    end

elseif strcmp(Method, 'Lineal') && strcmp(Var, 'TS')    
    
    for w = 1:length(Date)
        
        if sum(~isnan(Data(w,:))) >= 2
            id = ~isnan(Data(w,:));
        else
            disp(['Date ', datestr(Basin.Date(w)),' Error']) 
            continue
        end
        
        % Setting Parameters Temperature
        ParamT = TemperatureSetting(TimeSeriesGauges.Z(id)', Data(w,id)');
        
        tic
        for k = 1:length(Basin.Code)             
            % Temperature to Evapotranspiration
            Values(w,k)    = mean(polyval(ParamT,Zp{k}), 'omitnan');
        end        
        disp(['Date ', datestr(Date(w)),' Ok | Time = ', num2str(toc),' seg'])
        
    end    
    
end

end


function Values = InterpolationField_Basin_Tester(Basin, TimeSeriesGauges, Method, Var, PathDEM, varargin)

%% INPUT
%% INPUT
if nargin>5
    ThresholdDist_Min = varargin{1};
    Threshol_NumGauges = varargin{2};
else
    ThresholdDist_Min = 30000;
    Threshol_NumGauges = 5;
end

%% Clip Date Interpolation
[id, posi] = ismember(Basin.Date, TimeSeriesGauges.Date);
if sum(id) ~= length(Basin.Date)
    error('Error')
end
Data = TimeSeriesGauges.Data(posi,:);
Date = TimeSeriesGauges.Date(posi);

%% Coordenadas Puntos
XGauges     = reshape(TimeSeriesGauges.X,[],1);
YGauges     = reshape(TimeSeriesGauges.Y,[],1);

%% Porcentaje de aumento 
FactorDist = [1.2 1.4 1.6 1.8 2 3 4 5 6 7 8 9 10 15 20 30 50 100 500 1000];

%% Interpolation
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
    
elseif strcmp(Method, 'IDW')    
    
    Values = NaN(length(Basin.Date),length(XGauges));
    for w = 1:length(Date)
        if sum(~isnan(Data(w,:))) > 2
            id = find(~isnan(Data(w,:)));
            
            Xp = XGauges(id);
            Yp = YGauges(id);
            Zp = Data(w,id);

            % Distance
            tic
            for k = 1:length(Xp)
                % Estimación de distancia a las estaciones que tiene datos
                % disponibles
                Xp_k = Xp; Xp_k(k) = [];
                Yp_k = Yp; Yp_k(k) = [];
                Zp_k = Zp; Zp_k(k) = [];

                Dist    = sqrt( (Xp(k) - Xp_k').^2 + (Yp(k) - Yp_k').^2 );
                
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
                Values(w,id(k)) = Zp(k) - mean( sum(Zp_k.*(dis./ sum(dis,2,'omitnan')), 2, 'omitnan'), 'omitnan');
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
% 
% figure
% plot(mean(Values,'omitnan') )

end


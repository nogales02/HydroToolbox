function Values = Interpolation_Field(obj, DataGauges, Method, Var, varargin)

BasinArea   = obj.Area;
CodeBasin   = obj.Code;
XBasin      = obj.XBasin;
YBasin      = obj.YBasin;
XGauges     = DataGauges.X;
YGauges     = DataGauges.Y;
ZGauges     = DataGauges.Z;
Pixel       = 250;
Date        = DataGauges.Date;
Data        = DataGauges.Data;
BoundingBox = obj.BoundingBox;

if nargin == 5
    % Input DEM
    PathDEM     = varargin{1};
    
    % Read DEM
    [Z,~,~,ExtentRaster] = geotiffread( PathDEM );
end

%% Lineal Equation 
Top_Min = 3;
Top_Max = round(sqrt(max(BasinArea)/(Pixel*Pixel)),0) + 2;

Params  = polyfit([ min(BasinArea)  max(BasinArea)], [Top_Min Top_Max],1);

Xp = cell(length(CodeBasin),1);
Yp = cell(length(CodeBasin),1);

%% Create Grid
if ~strcmp(Method, 'Lineal') && strcmp(Var, 'TS')
    for k = 1:length(CodeBasin) 
        ExtentBasin = BoundingBox{k};
        x           = linspace(ExtentBasin(1,1), ExtentBasin(2,1),polyval(Params, BasinArea(k)));
        y           = linspace(ExtentBasin(2,2), ExtentBasin(1,2),polyval(Params, BasinArea(k)));
        [x, y]      = meshgrid(x, y);
        x           = reshape(x,[],1);
        y           = reshape(y,[],1);
        id          = inpolygon(x, y, XBasin{k}, YBasin{k});

        cont  = 1;
        while sum(id) <= 1
            Choco = polyval(Params, BasinArea(k)) + cont;
            ExtentBasin = BoundingBox{k};
            x           = linspace(ExtentBasin(1,1), ExtentBasin(2,1),Choco);
            y           = linspace(ExtentBasin(2,2), ExtentBasin(1,2),Choco);
            [x, y]      = meshgrid(x, y);
            x           = reshape(x,[],1);
            y           = reshape(y,[],1);
            id          = inpolygon(x, y, XBasin{k}, YBasin{k});
            cont = cont + 1;
        end

        Xp{k}       = x(id);
        Yp{k}       = y(id);
    end
end

%% Interpolation
Values          = NaN(length(Date),length(CodeBasin));

if strcmp(Method, 'Kriging')
    for w = 1:length(Data(:,1))

        if sum(~isnan(Data(w,:))) > 2
            id = ~isnan(Data(w,:));
            vstruct = SemivariogramSetting(XGauges(id), YGauges(id), Data(w,id)');
            DataTmp = Data(w,:)';

            for k = 1:length(CodeBasin) 
                Values(w,k) = mean(PrecipitationFields(XGauges, YGauges, DataTmp, Xp{k}, Yp{k}, vstruct), 'omitnan');
            end
            disp(['Date ', datestr(Date(w)),' Ok'])
        else
            disp(['Date ', datestr(Date(w)),' Error'])
        end
    end
    
    % Save Data
    NameFile = fullfile(obj.PathProject,[Var,'.mat']);
    save(NameFile, 'Values','Date')
    
elseif strcmp(Method, 'IDW')    

    for w = 1:length(Data(:,1))
        if sum(~isnan(Data(w,:))) > 2
            id = ~isnan(Data(w,:));
            
            % Distance
            for k = 1:length(CodeBasin)
                
                Dist    = sqrt( (Xp{k} - XGauges(id)).^2 + (Yp{k} - YGauges(id)).^2 );
                
                %Threshold
                iidd = (Dist > 50000);
                
                % Estimation Values 
                Beta    = 2;
                dis     = 1 ./ (Dist .^ Beta);
                dis(iidd) = 0; 
                dis(isinf(dis)) = 0;    
                Values(w,k) = mean( sum( Data(w,id).*(dis./ sum(dis,2)), 2, 'omitnan'), 'omitnan');
            end
            
            disp(['Date ', datestr(Date(w)),' Ok'])
        else
            disp(['Date ', datestr(Date(w)),' Error'])            
        end
    end
    
    % Save Data
    NameFile = fullfile(obj.PathProject,[Var,'.mat']);
    save(NameFile, 'Values','Date')
    
elseif strcmp(Method, 'Lineal') && strcmp(Var, 'TS')
            
    % Create Grid DEM
    Z(Z<0) = NaN;
    [RowDEM, ColDEM]    = size(Z);
    XDEM                = linspace(ExtentRaster(1,1), ExtentRaster(2,1),ColDEM);
    YDEM                = linspace(ExtentRaster(2,2), ExtentRaster(1,2),RowDEM);
%     [XDEM, YDEM]        = meshgrid(XDEM, YDEM);

%     Zetp = cell(length(CodeBasin),1);
    
%     for k = 1:length(CodeBasin) 
%         ExtentBasin = BoundingBox{k};
%         x           = linspace(ExtentBasin(1,1), ExtentBasin(2,1),10);
%         y           = linspace(ExtentBasin(2,2), ExtentBasin(1,2),10);
%         [x, y]      = meshgrid(x, y);
%         x           = reshape(x,[],1);
%         y           = reshape(y,[],1);
%         id          = inpolygon(x, y, XBasin{k}, YBasin{k});
% 
%         Zetp{k}     = interp2(XDEM, YDEM, Z, x(id), y(id), 'nearest');
%         
%         disp( ['Points Basin - ', num2str( (k/length(CodeBasin))*100, '%.2f' ),' - ' , num2str(CodeBasin(k))] )
%     end
        
    for w = 1:length(Data(:,1))
        if sum(~isnan(Data(w,:))) > 2
            id = ~isnan(Data(w,:));
        else
            disp(['Date ', datestr(Date(w)),' Error']) 
            continue
        end
        % Setting Parameters Temperature
        ParamT = TemperatureSetting(ZGauges(id)', Data(w,id)');

        for k = 1:length(CodeBasin) 
            % Extent
            ExtentBasin = BoundingBox{k};
            
            % Select Box
            x       = [ExtentBasin(1,1), ExtentBasin(2,1)];
            y       = [ExtentBasin(1,2), ExtentBasin(2,2)];
            
            Tmp1    = find( (XDEM >= x(1)) & (XDEM <= x(2)) );
            Tmp2    = find( (YDEM >= y(1)) & (YDEM <= y(2)) );  
            [P1,~]  = ind2sub(length(XDEM), Tmp1([1, end]));
            [P2,~]  = ind2sub(length(YDEM), Tmp2([1, end]));
            
            % Select Points
            id      = inpolygon(x(P1(1):P1(2), P2(1):P2(2)), y(P1(1):P1(2), P2(1):P2(2)), XBasin{k}, YBasin{k});
        
            % Temperature to Evapotranspiration
            Values(w,k)    = mean(polyval(ParamT,double(Z(id))), 'omitnan');
        end
        disp(['Date ', datestr(Date(w)),' Ok'])
        
    end
    
    % Save Data
    NameFile = fullfile(obj.PathProject,[Var,'.mat']);
    save(NameFile, 'Values','Date')
    
end

end


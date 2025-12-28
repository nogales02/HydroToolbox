function Semivariogram_Temporal_Multiresolution(obj, varargin)
% -------------------------------------------------------------------------
% Matlab - R2018b 
% -------------------------------------------------------------------------
%                           Informaci?n Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Componente    : Modelaci?n Hidrologica
% Organizaci?n  : The Nature Conservancy - TNC
% Fecha         : 01- July - 2019
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los t?rminos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener.Para mayor informaci?n revisar 
% http://www.gnu.org/licenses/.
%
% -------------------------------------------------------------------------
% Proyecto
%--------------------------------------------------------------------------
% Consultor?a t?cnica para el an?lisis de la cuenca alta y propuesta de 
% medidas de conservaci?n que contribuyan a la resiliencia de la cuenca del
% r?o Juan D?az en ciudad de Panam? para la mitigaci?n del riesgo por 
% inundaci?n
%
% -------------------------------------------------------------------------
% Descripci?n del Codigo
% -------------------------------------------------------------------------
% Este c?digo permite descargar la informaci?n de precipitaci?n, temperatura 
% m?nima y m?xima a resoluci?n diaria de los modelos meteorol?gicos globales 
% que modelan el cambio clim?tico (GCM). En total son 21 GCM de los cuales 
% se descarga la informaci?n, tanto para el hist?rico como para los 
% escenarios rcp45 y rcp85 
%
% -------------------------------------------------------------------------
% Input Data
% -------------------------------------------------------------------------
% 
% -------------------------------------------------------------------------
% Output Data
% -------------------------------------------------------------------------
%
% Var: variable, 1 para precipitacion, 0 para las demas

warning off

if nargin > 1
    Code_PoPo = varargin{1}; 
else
    Code_PoPo = [];
end

if ~isempty(Code_PoPo)
    [~, PoPo] = ismember(Code_PoPo, obj.Code);
else
    PoPo = 1:length(obj.Code);
end

if nargin > 2
    Maxdist = varargin{2};
else
    Maxdist = 360;
end

% moving average of order 
if nargin > 3
    m = floor(varargin{3});
else
    m = 10;
end

%% Create Folder
mkdir(fullfile(obj.PathProject,'RESULTS','Semivariogram_Temporal'))
mkdir(fullfile(obj.PathProject,'FIGURES','Semivariogram_Temporal'))

Scale = zeros(length(PoPo),100);

Fig     = figure('color',[1 1 1]);
T       = [10, 8];
set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
[0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off')

ScaleValue = NaN(length(obj.Date)/2, length(PoPo));
for ii = 1:length(PoPo)  
%     try
    id          = find(~isnan(obj.Data(:,PoPo(ii))));
    Data        = obj.Data(id(1):id(end),PoPo(ii));   
%     Date        = obj.Date(id(1):id(end));
    
    %% Clear NaN
    id      = ~isnan(Data);
    Data    = Data(id);
%     Date    = datenum(Date(id));        
    Data(Data == 0) = 0.1;
    
    %% Log
    Data = log(Data); 

     %% Average Moving        
    w = ((2*m) + 1);
    nn = length(Data);

    Results = NaN(nn-w+1,1);
    for i = 1:length(Data)
        PoInit  = i-m;
        PoEnd   = i+m;
        if PoInit < 1
            PoInit  = i;
            PoEnd   = 2*m + i - 1; 
        elseif PoEnd > length(Data)
            PoInit  = i - 2*m + 1 ;
            PoEnd   = i;
        end
        Results(i) = mean(Data(PoInit:PoEnd),'omitnan');
    end

    Data = Data - Results;
                              

    %% Tranformation Series
    % Centralizamos
    Data = Data - mean(Data, 'omitnan');
    % Estandarizamos
    Data1 = Data./std(Data, 'omitnan');
    
    N           = length(Data1);
    ni          = floor( log(N/2) / log(2) );
    parfor n = 1:(2^ni)%ni
        
        %% Aggregation
        Ns  = 2*n;%(2^n);
        s   = floor(N ./ (2*n));%floor(N ./ (2.^n));    

        % Meassured
%         Data = sum(reshape(Data1(1:Ns*s),s,Ns),2, 'omitnan');
        Data = mean(reshape(Data1(1:Ns*s),s,Ns),2, 'omitnan');
        
        %% FFT
        NN      = length(Data);
        F       = fft(Data);
        F       = real(F).^2 + imag(F).^2;        
		F       = F(2:end,1);
        F       = var(Data)*(F/sum(F));
        F       = F/var(Data);
		temp    = 1:floor((NN-1));
		K       = (temp' / NN) ;         		
        F       = F(1:floor(NN/4));
        K       = 1./K(1:floor(NN/4));   
        
        if length(F) > 1 
            ScaleValue(n, ii)     = K(F == max(F))*Ns;
        end
        
    end
%     plot((2.^(0:length(ScaleValue)-1)), ScaleValue)
%     plot( 2:2:2*length(ScaleValue), ScaleValue)
%     plot(sort(ScaleValue),'Color',[0.5 0.5 0.5])
%     hold on 
%     set(gca,'XScale','log','YScale','log')
%     set(gca,'YScale','log')
    disp(['Semivariogram ok for Gauges ->',num2str(obj.Code(PoPo(ii)))])
end
% 
plot(sort(ScaleValue),'Color',[0.5 0.5 0.5])
set(gca,'XScale','log','YScale','log')
Code = obj.Code(PoPo);
% Code = reshape(Code,length(Code),1);
% 
% %% Save Data
% NameFile    = fullfile(obj.PathProject,'RESULTS','Semivariogram_Temporal','Electronic_Scale.csv');
% ID_File     = fopen(NameFile,'w');
% 
% fprintf(ID_File,'%s\n','Code,Scale');
% fprintf(ID_File, '%d,%f\n',[Code, Scale]');
% fclose(ID_File);

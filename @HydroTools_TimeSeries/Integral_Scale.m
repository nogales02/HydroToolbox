function Iw = Integral_Scale(obj, varargin)
% -------------------------------------------------------------------------
% Matlab - R2018b 
% -------------------------------------------------------------------------
%                           Informaci�n Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Componente    : Modelaci�n Hidrologica
% Organizaci�n  : The Nature Conservancy - TNC
% Fecha         : 01- July - 2019
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los t�rminos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener.Para mayor informaci�n revisar 
% http://www.gnu.org/licenses/.
%
% -------------------------------------------------------------------------
% Proyecto
%--------------------------------------------------------------------------
% Consultor�a t�cnica para el an�lisis de la cuenca alta y propuesta de 
% medidas de conservaci�n que contribuyan a la resiliencia de la cuenca del
% r�o Juan D�az en ciudad de Panam� para la mitigaci�n del riesgo por 
% inundaci�n
%
% -------------------------------------------------------------------------
% Descripci�n del Codigo
% -------------------------------------------------------------------------
% Este c�digo permite descargar la informaci�n de precipitaci�n, temperatura 
% m�nima y m�xima a resoluci�n diaria de los modelos meteorol�gicos globales 
% que modelan el cambio clim�tico (GCM). En total son 21 GCM de los cuales 
% se descarga la informaci�n, tanto para el hist�rico como para los 
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
    NameLabel = varargin{2};
else
    NameLabel = [];
end

if isempty(NameLabel)
    NameLabel = '\bf Lag Time (Day)';
end

%% Create Folder
warning off
mkdir(fullfile(obj.PathProject,'FIGURES','Covariogram'))
mkdir(fullfile(obj.PathProject,'RESULTS','Covariogram'))

Iw = zeros(length(PoPo),4);
for ii = 1:length(PoPo)
    try
        id          = find(~isnan(obj.Data(:,PoPo(ii))));
        Data        = obj.Data(id(1):id(end),PoPo(ii));

        %% Fitting NAN Value
        Data(isnan(Data)) = mean(Data(~isnan(Data)));        
    
        %%
        m = 30;
        w = ((2*m) + 1);
        n = length(Data);

        Results = NaN(n-w+1,1);
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
        
        %% Step
        Tad = floor(length(Data) - 10);
        if Tad > 2000
            Tad = 2000;
        end        
        
        %% Covariance Funtion
        Cw      = zeros(Tad,1);
        Cw(1) = cov(Data);
        for i = 2:Tad
            Tmp = cov(Data(1:end-i), Data(i+1:end));
            Cw(i) = Tmp(1,2);
        end
        
        %% Integral Scale Total Covariogram
        Iw(ii,1)    = trapz(Cw./var(Data));
        
        %% Integral Scale Only Positive Covariogram
        Cw_1        = Cw; Cw_1(Cw_1<0) = 0;
        Iw(ii,2)    = trapz(Cw_1./var(Data));
        
        %% Integral Scale Point zero Covariogram
        Cw_2        = Cw;
        id          = find(Cw_2 < 0);
        Cw_2        = Cw_2(1:id(1)-1);
        Iw(ii,3)    = trapz(Cw_2./var(Data));
        
        %% Integral Scale (1/e)*var Covariogram
        Cw_3        = Cw;
        id          = find(Cw_3 <= ((1/exp(1))*max(Cw_3)));
        Cw_3        = Cw_3(1:id(1));
        Iw(ii,4)    = trapz(Cw_3./var(Data));
        
        %% Plot
        if obj.StatusPlot
            Fig     = figure('color',[1 1 1]);
            T       = [10, 6];
            set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
            [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off') 

%             plot((-1*Tad + 1:Tad-1),Cw,'Linewidth',2, 'color',obj.ColorsF('carmine'))
            plot((1:Tad)*10,Cw,'Linewidth',2, 'color',obj.ColorsF('carmine'))
            
            xlabel(NameLabel,'interpreter','latex', 'Fontsize',20)
            ylabel('\bf Covariance', 'interpreter','latex', 'Fontsize',20)
            set(gca, 'TickLabelInterpreter','latex', 'FontWeight','bold','Color','none', 'box','on','FontSize',18)
            set(gca, 'XScale','Log')
            
            xlim([10, Tad*10])
            
            %% Save
            saveas(Fig, fullfile(obj.PathProject,'FIGURES','Covariogram',[num2str(obj.Code(PoPo(ii))),'.jpg']))
            close(Fig)
        end

        %% Save Data
        NameFolfer  = fullfile(obj.PathProject,'RESULTS','Covariogram');    
        NameFile    = fullfile(NameFolfer,[num2str(obj.Code(PoPo(ii))),'.csv']);
        ID_File     = fopen(NameFile,'w');
        fprintf(ID_File,'%s\n','Lag,Cw');

        fprintf(ID_File, '%f,%f\n',[(1:Tad)' Cw]');
        fclose(ID_File);
        
        disp(['Integral Scale Ok Gauges ->',num2str(obj.Code(PoPo(ii)))])
    catch
        disp(['Integral Scale Error Gauges ->',num2str(obj.Code(PoPo(ii)))])
    end
end

Code = obj.Code(PoPo);
Code = reshape(Code,length(Code),1);

%% Save Data
NameFile    = fullfile(obj.PathProject,'RESULTS','Covariogram','Integral_Scale.csv');
ID_File     = fopen(NameFile,'w');

fprintf(ID_File,'%s\n','Code,Total,Positive,zero,1/e');
fprintf(ID_File, '%d,%0.4f,%0.4f,%0.4f,%0.4f\n',[Code, Iw]');
fclose(ID_File);
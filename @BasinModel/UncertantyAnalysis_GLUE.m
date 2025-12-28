function UncertantyAnalysis_GLUE(Basin)
% -------------------------------------------------------------------------
% Programado en Matlab - R2019b 
% -------------------------------------------------------------------------
%                           Informaciï¿½n Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Fecha         : 01-Enero-2019
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los términos de la licencia publica general GNU. El autor no se 
% hace responsable de los usos que pueda tener. Para mayor información 
% revisar http://www.gnu.org/licenses/
%
% -------------------------------------------------------------------------
% Descripciï¿½n del Codigo
% -------------------------------------------------------------------------
% 
% -------------------------------------------------------------------------
% Input Data
% -------------------------------------------------------------------------
% 
% -------------------------------------------------------------------------
% Output Data
% -------------------------------------------------------------------------

warning off

% -------------------------------------------------------------------------
% Carpeta para el guardado
% -------------------------------------------------------------------------
mkdir(fullfile(Basin.PathProject,'FIGURES','Uncertanty'))
mkdir(fullfile(Basin.PathProject,'FIGURES','Uncertanty','Dotty'))
mkdir(fullfile(Basin.PathProject,'FIGURES','Uncertanty','Sensitivity'))
mkdir(fullfile(Basin.PathProject,'FIGURES','Uncertanty','GLUE'))

for i = 1:length(Basin.GaugesID)
    % -----------------------------------------------------------------
    % Leer los mejores parámetros de la estación i
    % -----------------------------------------------------------------
    BestParams = readmatrix(fullfile(Basin.PathProject,'OUTPUTS','Best-Parameters',Basin.OptMethod,[num2str(Basin.GaugesID(i)),'.csv']));
    if ~Basin.Status_ModelFlood
        BestParams = BestParams(5:end);
    end

    % -----------------------------------------------------------------
    % Leer parámetros evaluados para la estación i
    % -----------------------------------------------------------------
    Tmp     = matfile(fullfile(Basin.PathProject,'OUTPUTS','AllEvals',Basin.OptMethod,[num2str(Basin.GaugesID(i)),'.mat']));
    Params  = Tmp.allEvals;
    
    if ~Basin.Status_ModelFlood
        Params = Params(:,5:end);
    end
    Metric = Params(:,end);
    Params(:,end) = [];

    % ---------------------------goo--------------------------------------
    % encontrar posición de los mejores parámetros
    % -----------------------------------------------------------------
%     dist    = sqrt(sum(bsxfun(@minus,BestParams,Params).^2,2));
%     Posi    = find(dist == min(dist));

    % -----------------------------------------------------------------
    % Leer caudales evaluados para la estación i
    % -----------------------------------------------------------------
    Tmp     = matfile(fullfile(Basin.PathProject,'OUTPUTS','AllQsim',Basin.OptMethod,[num2str(Basin.GaugesID(i)),'.mat']));
    Qsim    = Tmp.Results; 
    Date    = Qsim.Date;
    Qsim    = Qsim.Data;       
    
    % Verificar si las fechas de la serie de tiempo coinciden con las definidas
    % en el objeto Basin
    [id, posi1] = ismember(Basin.Date, Date);
    if sum(id) ~= length(Basin.Date)
        error('Error')
    end
    Qsim = Qsim(posi1,:);

    % -----------------------------------------------------------------
    % Función objetivo para análisis
    % -----------------------------------------------------------------
    Title_Cal   = 'Calibration';
    cstr        = str2mat( '1 - Nash');
    StartDate   = floor(length(Basin.Date)*(Basin.PorcOmit/100));
    EndDate     = length(Basin.Date);
    Qobs        = Basin.Qobs(StartDate:EndDate,i);
    Nash        = ((mean(bsxfun(@minus,Qobs,Qsim(StartDate:EndDate,:)).^2, 'omitnan'))...
                    ./var( Qobs(~isnan(Qobs)) ))';

    % Nash            
    pstr = str2mat('X1', 'X2', 'X3', 'X4'); 
    JoJo = {'new','sensi', 'ouncert' };
    for ii = 1:3
        mcat(Params, Nash, [], Qsim(StartDate:EndDate,:)', [], Qobs', Title_Cal, pstr, cstr, [], 1440, datenum(Basin.Date(StartDate:EndDate)), JoJo{ii});
        set(gcf,  'Visible','off')

        if ii == 1
            saveas(gcf, fullfile(Basin.PathProject,'FIGURES','Uncertanty','Dotty',[num2str(Basin.GaugesID(i)),'_Dotty.jpg']))
        elseif ii == 2
            saveas(gcf, fullfile(Basin.PathProject,'FIGURES','Uncertanty','Sensitivity',[num2str(Basin.GaugesID(i)),'_Sensitivity.jpg']))
        else 
            saveas(gcf, fullfile(Basin.PathProject,'FIGURES','Uncertanty','GLUE',[num2str(Basin.GaugesID(i)),'GLUE.jpg']))
        end
        close all 

    end    
    disp(['OK Uncentanty - MCAT - GLUE - ',num2str(Basin.GaugesID(i))])
end


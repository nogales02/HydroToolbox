function [Alfa, F_Alfa, Delta, H, Tau, q, Miu, Dq] = TS_MassExponent(obj, varargin)
% -------------------------------------------------------------------------
% Programado en Matlab - R2019b 
% -------------------------------------------------------------------------
%                           Informaci�n Basica
%--------------------------------------------------------------------------
% Autor         : Jonathan Nogales Pimentel
% Email         : jonathannogales02@gmail.com
% Fecha         : 01-Enero-2019
%
%--------------------------------------------------------------------------
% Este programa es de uso libre: Usted puede redistribuirlo y/o modificarlo 
% bajo los t�rminos de la licencia publica general GNU. El autor no se hace 
% responsable de los usos que pueda tener. Para mayor informaci�n revisar 
% http://www.gnu.org/licenses/
%
% -------------------------------------------------------------------------
% Descripci�n del Codigo
% -------------------------------------------------------------------------
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

%% Create Folder
mkdir(fullfile(obj.PathProject,'FIGURES','Multifractal_Moments'))
mkdir(fullfile(obj.PathProject,'RESULTS','Multifractal_Moments'))

%% Storage
PropMF_q        = zeros(length(PoPo),4);
PropMF_Tau      = PropMF_q;
PropMF_H        = PropMF_q;
PropMF_Alfa     = PropMF_q;
PropMF_F_Alfa   = PropMF_q;
        
for ii = 1:length(PoPo)
    
    try
        id          = find(~isnan(obj.Data(:,PoPo(ii))));
        Data        = obj.Data(id(1):id(end),PoPo(ii));
        Data        = round(Data,1);
        
        %% Multifractal
        [Alfa, F_Alfa, Delta, H, Tau, q, Miu, Dq, Fig] = MassExponent(Data);
        
        %% Save Data
        NameFolfer  = fullfile(obj.PathProject,'RESULTS','Multifractal_Moments');    
        NameFile    = fullfile(NameFolfer,[num2str(obj.Code(PoPo(ii))),'.csv']);
        ID_File     = fopen(NameFile,'w');
        fprintf(ID_File,'%s\n','Moments,Tau,H,Alfa,F_Alfa,Dq');

        fprintf(ID_File, ['%f',repmat(',%f',1,5),'\n'],[q, Tau,H,Alfa,F_Alfa,Dq]');
        fclose(ID_File);    

        %% Plot 
        if obj.StatusPlot
            saveas(Fig, fullfile(obj.PathProject,'FIGURES','Multifractal_Moments',[num2str(obj.Code(PoPo(ii))),'.jpg']))
            close(Fig)
        end
                
        %% Factores
        Po = [length(Alfa),1, find(q == 0), find(q == 1)];
        PropMF_q(ii,:)        = q(Po);
        PropMF_Tau(ii,:)      = Tau(Po);
        PropMF_H(ii,:)        = H(Po);
        PropMF_Alfa(ii,:)     = Alfa(Po);
        PropMF_F_Alfa(ii,:)   = F_Alfa(Po);
                
        disp(['Multifractal Spectrum Ok Gauges ->',num2str(obj.Code(PoPo(ii)))])
    catch
        disp(['Error Multifractal Spectrum Gauges ->',num2str(obj.Code(PoPo(ii)))])
    end
end

Code = obj.Code(PoPo);
Code = reshape(Code,length(Code),1);

%% Moments
NameFolfer  = fullfile(obj.PathProject,'RESULTS','Multifractal_Moments');    
NameFile    = fullfile(NameFolfer,'1-q.csv');
ID_File     = fopen(NameFile,'w');
fprintf(ID_File,'%s\n','Code,Min,Max,Zero,One');

fprintf(ID_File, ['%d',repmat(',%f',1,4),'\n'],[Code PropMF_q]');
fclose(ID_File);

%% Tau
NameFolfer  = fullfile(obj.PathProject,'RESULTS','Multifractal_Moments');    
NameFile    = fullfile(NameFolfer,'2-Tau.csv');
ID_File     = fopen(NameFile,'w');
fprintf(ID_File,'%s\n','Code,Min,Max,Zero,One');

fprintf(ID_File, ['%d',repmat(',%f',1,4),'\n'],[Code PropMF_Tau]');
fclose(ID_File);

%% H
NameFolfer  = fullfile(obj.PathProject,'RESULTS','Multifractal_Moments');    
NameFile    = fullfile(NameFolfer,'3-H.csv');
ID_File     = fopen(NameFile,'w');
fprintf(ID_File,'%s\n','Code,Min,Max,Zero,One');

fprintf(ID_File, ['%d',repmat(',%f',1,4),'\n'],[Code PropMF_H]');
fclose(ID_File);

%% Alfa
NameFolfer  = fullfile(obj.PathProject,'RESULTS','Multifractal_Moments');    
NameFile    = fullfile(NameFolfer,'4-Alfa.csv');
ID_File     = fopen(NameFile,'w');
fprintf(ID_File,'%s\n','Code,Min,Max,Zero,One');

fprintf(ID_File, ['%d',repmat(',%f',1,4),'\n'],[Code PropMF_Alfa]');
fclose(ID_File);

%% F_Alfa
NameFolfer  = fullfile(obj.PathProject,'RESULTS','Multifractal_Moments');    
NameFile    = fullfile(NameFolfer,'5-F_Alfa.csv');
ID_File     = fopen(NameFile,'w');
fprintf(ID_File,'%s\n','Code,Min,Max,Zero,One');

fprintf(ID_File, ['%d',repmat(',%f',1,4),'\n'],[Code PropMF_F_Alfa]');
fclose(ID_File);

end 
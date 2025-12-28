function Remove_Seasonality(obj, varargin)
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
mkdir(fullfile(obj.PathProject,'RESULTS','Multifractal_Moments'))
        
for ii = 5:length(PoPo)
    
    try
        id          = find(~isnan(obj.Data(:,PoPo(ii))));
        Data        = obj.Data(id(1):id(end),PoPo(ii));
        Date        = obj.Date(id(1):id(end));
        
        %% Fourier
        [N,~] = size(Data);
		if mod(N,2) ~= 0
			Data    = Data(1:end-1);
			[N,~]   = size(Data);
        end
        
        %% Clear NaN
        id      = ~isnan(Data);
        Data    = Data(id);
        Data(Data == 0) = 0.1;
        
        %% Log
        Data = log(Data);
        
        %%
        F       = fft(Data);
        Fr      = real(F);
        Fi      = imag(F);
        F       = Fr.^2 + Fi.^2;
        F       = F(2:end,1);
        Ang     = atan(Fi./Fr);
        Ang     = Ang(2:end,1);
        F       = var(Data)*(F/sum(F));
        Alfa    = cos(Ang).*sqrt(F)  .* Fr(2:end,1)./abs(Fr(2:end,1));
        Beta    = sin(Ang).*sqrt(F)  .* Fi(2:end,1)./abs(Fi(2:end,1));
        Alfa    = [cos(atan(Fi(1)./Fr(1)))*mean(Data); Alfa];
        Beta    = [0; Beta];
        
        n = (0:(N-1))';
        k   = find(F == max(F));
        
        Part_1 = 0;
        Part_2 = 0;
        for i = 0:k + 1
            Part_1 = Part_1 + Alfa(i+1)*cos( (2 * pi * i .* n) / N );
            Part_2 = Part_2 + Beta(i+1)*sin( (2 * pi * i .* n) / N );
        end

        Armo =(Part_1 + Part_2);
        
        Data = Data - Armo;
        
        Tad = floor(length(Data) - 10);
        if Tad > 2000
            Tad = 2000;
        end
        
        Cw      = zeros(Tad,1);
        Cw(1) = cov(Data);
        for i = 2:Tad
            Tmp = cov(Data(1:end-i), Data(i+1:end));
            Cw(i) = Tmp(1,2);
        end
        
        plot(Cw)
        
        %%
%         
%         temp    = 0:(N-1);
%         n       = repmat(temp',[1 N]); k = n';
% 		Alfa    = ((cos( (2 * pi * k .* n) / N ) * Data) / N);
% 		Beta    = -((sin( (2 * pi * k .* n) / N ) * Data) / N);
%         F       = Alfa.^2 + Beta.^2;
%         F       = F(2:end,1);
% %         
%         F       = F(1:floor(N/2));
% %         
%         n = (0:(N-1))';
%         k   = find(F == max(F));
%         
%         Part_1 = 0;
%         Part_2 = 0;
%         for i = 0:k + 1
%             Part_1 = Part_1 + Alfa(i+1)*cos( (2 * pi * i .* n) / N );
%             Part_2 = Part_2 + Beta(i+1)*sin( (2 * pi * i .* n) / N );
%         end
% 
%         Armo =(Part_1 - Part_2);
%         
%         figure
%         plot(Data),hold on, plot(Armo)
        
        %% Plot
        subplot(3,1,1)
        plot(Date,Data)
        
        %% Seasonal Remove
%         n1          = ceil(length(Data)/365);
%         n2          = (n1*365) - length(Data);
%         Day365      = reshape([Data; NaN(n2,1)],365,[])';
%         MeanData    = mean(Day365,'omitnan')';
%         
%         %%
%         m = 30;
%         w = ((2*m) + 1);
%         n = length(Data);
% 
%         Results = NaN(n-w+1,1);
%         for i = 1:length(Data)
%             PoInit  = i-m;
%             PoEnd   = i+m;
%             if PoInit < 1
%                 PoInit  = i;
%                 PoEnd   = 2*m + i - 1; 
%             elseif PoEnd > length(Data)
%                 PoInit  = i - 2*m + 1 ;
%                 PoEnd   = i;
%             end
%             Results(i) = mean(Data(PoInit:PoEnd),'omitnan');
%         end
%         
%         Data = Data - Results;
        %%
%         TiSM = repmat(Results, n1,1);
%         Data = Data - TiSM(1:length(Data));
        
        %% Tranformation Series
        % Centralizamos
        Data = Data - mean(Data, 'omitnan');
        % Estandarizamos
        Data = Data./std(Data, 'omitnan');
        
        %%
        subplot(3,1,2)
        plot(Date,Data)
        
        subplot(3,1,3)
        plot(Results)
%         hold on 
%         plot(Date,y)
        
        disp(['Multifractal Spectrum Ok Gauges ->',num2str(obj.Code(PoPo(ii)))])
    catch
        disp(['Error Multifractal Spectrum Gauges ->',num2str(obj.Code(PoPo(ii)))])
    end
end

% Code = obj.Code(PoPo);
% Code = reshape(Code,length(Code),1);
% 
% %% Moments
% NameFolfer  = fullfile(obj.PathProject,'RESULTS','Multifractal_Moments');    
% NameFile    = fullfile(NameFolfer,'1-q.csv');
% ID_File     = fopen(NameFile,'w');
% fprintf(ID_File,'%s\n','Code,Min,Max,Zero,One');
% 
% fprintf(ID_File, ['%d',repmat(',%f',1,4),'\n'],[Code PropMF_q]');
% fclose(ID_File);

end 

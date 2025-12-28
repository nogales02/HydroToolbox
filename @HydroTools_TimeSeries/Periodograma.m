%% PERIODOGRAMA 
function Periodograma(obj, varargin)
%% ENTRADAS 
% Data : Serie de tiempo en una vector columna 
% n     : cuanto quiere ampliar la frecuencia 

%% SALIDAS 
% Grafica del periodo grama
% F : frecuencia maxima

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
mkdir(fullfile(obj.PathProject,'FIGURES','Periodogram'))
mkdir(fullfile(obj.PathProject,'RESULTS','Periodogram'))

Summary1 = zeros(length(PoPo), 5);
Summary2 = zeros(length(PoPo), 5);
for ii = 1:length(PoPo)
	try
		id          = find(~isnan(obj.Data(:,PoPo(ii))));
		Data        = obj.Data(id(1):id(end),PoPo(ii));
		
		%% Fitting NAN Value
		Data(isnan(Data)) = mean(Data(~isnan(Data)));
		
		%% Tranformation Series
		% Centralizamos
		Data = Data - mean(Data, 'omitnan');
		% Estandarizamos
		Data = Data./std(Data, 'omitnan');
			
		%% INDEXAR k 
		% determinamos el tamño de la matriz columna de Data de entrada 
		[N,~] = size(Data);
		if mod(N,2) ~= 0
			Data    = Data(1:end-1);
			[N,~]   = size(Data);
        end
		
        %% FFT
        F       = fft(Data);
        Fr      = real(F);
        Fi      = imag(F);
        F       = Fr.^2 + Fi.^2;        
		F       = F(2:end,1);
        F       = var(Data)*(F/sum(F));
        F       = F/var(Data);
		temp    = 1:floor((N-1));
		K       = (temp' / N) ;         
		
        F       = F(1:floor(N/4));
        K       = K(1:floor(N/4));        

		%% Plot in Spanish
		if obj.StatusPlot
			%% Create Figure
			Fig     = figure('color',[1 1 1]);
			T       = [10, 8];
			set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
			[0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off') 
            
%             area(fliplr(1./K), F,'FaceColor',obj.ColorsF('carmine'),'FaceAlpha',0.3,'LineStyle','none')
%             hold on 
			plot(1./K, F,'.-','color',obj.ColorsF('carmine'),'LineWidth',1.3)
			xlabel('\bf Frecuencia (D\''ias)','Interpreter','latex','FontSize',20)
			ylabel('\bf Aporte a la varianza (\%)','Interpreter','latex','FontSize',20)
	%         title('\bf Periodogram','Interpreter','latex','FontSize',22)
			set(gca, 'TickLabelInterpreter','latex', 'FontWeight','bold', 'box','on','FontSize',18)        
			set(gca,'XScale','Log')
            xlim([min(1./K) max(1./K)])
			
            id = F == max(F);
            text((1./K(id))*1.05,max(F),['\bf ',num2str(1./K(id),'%.0f'),' Day'],...
                'interpreter','latex','color','k','FontSize',15)
            
			%% Save
			saveas(Fig, fullfile(obj.PathProject,'FIGURES','Periodogram',[num2str(obj.Code(PoPo(ii))),'.jpg']))
			close(Fig)
		end               
		
		%% Save Data
% 		NameFolfer  = fullfile(obj.PathProject,'RESULTS','Periodogram');
% 		NameFile    = fullfile(NameFolfer,[num2str(obj.Code(PoPo(ii))),'.csv']);
% 		ID_File     = fopen(NameFile,'w');
% 		fprintf(ID_File,'%s\n','Frecuencia (Time),Variancia');
% 		fprintf(ID_File, '%f,%f\n',[1./K, F]');
% 		fclose(ID_File);
			
	    [F, id] = sort(F,'descend');
	    K = K(id);
	        
	    Summary1(ii,:) = 1./K(1:5); 
	    Summary2(ii,:) = F(1:5);
		disp(['Periodogram ok for Gauges ->',num2str(obj.Code(PoPo(ii)))])
	catch
		disp(['Error Periodogram for Gauges ->',num2str(obj.Code(PoPo(ii)))])
	end
end

Code = obj.Code(PoPo);
Code = reshape(Code,length(Code),1);

%% Save Data
NameFile    = fullfile(obj.PathProject,'RESULTS','Periodogram','Principal_Armonics.csv');
ID_File     = fopen(NameFile,'w');

fprintf(ID_File,'%s\n','Code,Ar-1,Ar-2,Ar-3,Ar-4,Ar-5');
fprintf(ID_File, '%d,%f,%f,%f,%f,%f\n',[Code, Summary1]');
fclose(ID_File);

%% Save
NameFile    = fullfile(obj.PathProject,'RESULTS','Periodogram','Contribution_Variance.csv');
ID_File     = fopen(NameFile,'w');

fprintf(ID_File,'%s\n','Code,Var-1,Ar-2,Ar-3,Ar-4,Ar-5');
fprintf(ID_File, '%d,%f,%f,%f,%f,%f\n',[Code, Summary2]');
fclose(ID_File);

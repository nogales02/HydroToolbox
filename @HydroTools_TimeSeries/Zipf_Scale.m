function Zipf_Scale(obj,varargin)

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
    NameLabel = varargin{2};
else
    NameLabel = [];
end

if isempty(NameLabel)
    NameLabel = '\bf Lluvia Acumulada(mm)';
end

%% Create Folder
mkdir(fullfile(obj.PathProject,'FIGURES','Zipf'))
mkdir(fullfile(obj.PathProject,'RESULTS','Zipf'))

Params_All = zeros(length(PoPo),2);
for ii = 1:length(PoPo)
	try
		id          = find(~isnan(obj.Data(:,PoPo(ii))));
		Data        = obj.Data(id(1):id(end),PoPo(ii));
		
		%% Fitting NAN Value
		Data(isnan(Data)) = mean(Data(~isnan(Data)));
        
        %% Centralizar
        Data = Data - mean(Data);
        
        %% Normalizar
        Data = Data./std(Data);
        
        %% Tranformation Series
        % Centralizamos
%         Data = Data./sum(Data,'omitnan');
        
        %%
        % Data Number
        N       = length(Data);
        % 
        ni      = floor( log(N/2) / log(2) );
        % Number of Segments
        JaJa = 1;
        if ni > JaJa
            Delta   = unique([floor(N ./ (2.^((1:JaJa)'))); (floor(N ./ (2.^JaJa)):-1:floor(N ./ (2.^ni)))' ]);
        else
            Delta   = floor(N ./ (2.^((1:ni)')));
        end
        
        id = mod(Delta,1);
        Delta = Delta(id == 0);
        % Delta 
        Ns = floor(N./Delta);
%         ds = NaN(length(Ns)-1,length(Ns));
        
        Results = NaN(length(Ns),1);
        for n = 1:length(Ns)
            Tmp = reshape(Data(1:Ns(n)*Delta(n)),Delta(n),Ns(n));
            Miu = mean(Tmp, 'omitnan')';
%             Miu = sum(Tmp, 'omitnan')';
%             ds(1:length(Miu),n) = Miu;
            Miu( Miu == 0) = NaN ;  
            Results(n) = sum(Miu,'omitnan')';
%             Results(n) = mean(Miu,'omitnan')';
        end
%         ds( ds == 0) = NaN ;  
%         Results = sum(ds,'omitnan')';
        
        %% Fitting 
        % Fit Lineal Model
        Params  = polyfit(log(Delta),log(Results),1);
        Params  = [-1*Params(1), exp(Params(2))];
        Psim    = Params(2)./(Delta.^Params(1));        
        
        Params_All(ii,:) = Params;

        %% Plot
        if obj.StatusPlot
            Fig     = figure('color',[1 1 1]);
            T       = [10, 8];
            set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
            [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','on') 

            plot(Delta, Results,'.-','Linewidth',1.5, 'color',obj.ColorsF('carmine'),'MarkerEdgeColor','k')
%             hold on
%             plot(Delta, Psim,'Linewidth',2, 'color',[0.5 0.5 0.5])
            
            title(['log(f($\delta$t)) = log(',num2str(Params(2),'%.2f'),') - ',num2str(Params(1),'%.4f'),'*log($\delta$t)'],'interpreter','latex', 'Fontsize',20)
            xlabel('\bf Log($\delta$t (Day))','interpreter','latex', 'Fontsize',20)
            ylabel(NameLabel, 'interpreter','latex', 'Fontsize',20)
            le = legend('\bf Empirico', '\bf teorico');
            set(le,'interpreter','latex','FontSize',15, 'FontWeight','bold','box','off','color','none')
            set(gca, 'TickLabelInterpreter','latex', 'FontWeight','bold',...
                'Color','none', 'box','on','FontSize',18, 'Yscale','log','Xscale','log')

            %% Save
            saveas(Fig, fullfile(obj.PathProject,'FIGURES','Zipf',[num2str(obj.Code(PoPo(ii))),'.jpg']))
            close(Fig)
        end
        
        NameFolfer = fullfile(obj.PathProject,'RESULTS','Zipf', num2str(obj.Code(PoPo(ii))));
        mkdir(NameFolfer)
        
        %% Save
%         NameFile    = fullfile(NameFolfer,'Values.csv');
%         ID_File     = fopen(NameFile,'w');
%         fprintf(ID_File, ['%f',repmat(',%f',1,length(ds(1,:))-1),'\n'],[Delta ds']');
%         fclose(ID_File);
%         
        %% Save 
        NameFile    = fullfile(NameFolfer,'Values_Mean_Sum.csv');
        ID_File     = fopen(NameFile,'w');
        fprintf(ID_File,'%s\n','Delta,Value');

        fprintf(ID_File, '%f,%f\n',[Delta, Results]');
        fclose(ID_File);
        
        %% Save Paremeters
        NameFile    = fullfile(NameFolfer,'Parameters.csv');
        ID_File     = fopen(NameFile,'w');
        fprintf(ID_File,'%s\n','Parameter,Value');
        fprintf(ID_File,'%s\n',['C,',num2str(Params(2))]);
        fprintf(ID_File,'%s\n',['ro,',num2str(Params(1))]);
        fclose(ID_File);
        
        disp(['Zipf Ok for Gauges ->',num2str(obj.Code(PoPo(ii)))])
    catch
        disp(['Zipf Error for Gauges ->',num2str(obj.Code(PoPo(ii)))])
    end
end

Code = obj.Code(PoPo);
Code = reshape(Code,length(Code),1);

%% Save Data
NameFile    = fullfile(obj.PathProject,'RESULTS','Zipf','Zipf-Law.csv');
ID_File     = fopen(NameFile,'w');

fprintf(ID_File,'%s\n','Code,X,Y,ro,C');
fprintf(ID_File, '%d,%f,%f,%f,%f\n',[Code, obj.X', obj.Y', Params_All]');
fclose(ID_File);
        
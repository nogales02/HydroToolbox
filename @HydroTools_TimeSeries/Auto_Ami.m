function [v,lag] = Auto_Ami(obj, varargin)
%Usage: [v,lag]=ami(x,y,lag)
%
% Calculates the mutual average information of x and y with a possible lag.
% 
%
% v is the average mutual information. (relative units see below)
% x & y is the time series. (column vectors)
% lag is a vector of time lags.
%
% (A peak in V for lag>0 means y is leading x.)
% 
% v is given as how many bits x and y has in common relative to how 
% many bits is needed for the internally binned representation of x or y.
% This is done to make the result close to independent bin size.
%
% For optimal binning: transform x and y into percentiles prior to running
% ami. See e.g. boxpdf at matlab central.
%
% http://www.imt.liu.se/~magnus/cca/tutorial/node16.html
%
% Aslak Grinsted feb2006 
% http://www.glaciology.net
% (Inspired by mai.m by Alexandros Leontitsis)

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
    lag = varargin{1};
    lag=round(lag);
else
    lag = 0:50;
end

%% Create Folder
mkdir(fullfile(obj.PathProject,'FIGURES','AMI'))
mkdir(fullfile(obj.PathProject,'RESULTS','AMI'))

for wi = 1:length(PoPo)
    id      = find(~isnan(obj.Data(:,PoPo(wi))));
    Data    = obj.Data(id(1):id(end),PoPo(wi));
    
    %% Fitting NAN Value
    Data(isnan(Data)) = mean(Data(~isnan(Data)));
    
    x = Data;
    y = Data;
    
    x=x(:);
    y=y(:);
    n=length(x);
    if n~=length(y)
        error('x and y should be same length.');
    end

    % The mutual average information
    x = x-min(x);   
    x = x*(1-eps)/max(x);
    y = y-min(y);
    y = y*(1-eps)/max(y);

    v=zeros(size(lag));
    lastbins=nan;
    for ii=1:length(lag)

        abslag=abs(lag(ii));

        % Define the number of bins
        bins=floor(1+log2(n-abslag)+0.5);%as mai.m
        if bins~=lastbins
            binx=floor(x*bins)+1;
            biny=floor(y*bins)+1;
        end
        lastbins=bins;

        Pxy=zeros(bins);

        for jj=1:n-abslag
            kk=jj+abslag;
            if lag(ii)<0 
                temp=jj;
                jj=kk;
                kk=temp;%swap
            end
            Pxy(binx(kk),biny(jj))=Pxy(binx(kk),biny(jj))+1;
        end
        Pxy=Pxy/(n-abslag);
        Pxy=Pxy+eps; %avoid division and log of zero
        Px=sum(Pxy,2);
        Py=sum(Pxy,1);

        q=Pxy./(Px*Py);

        q=Pxy.*log2(q);

        v(ii)=sum(q(:))/log2(bins); %log2bins is what you get if x=y.
    end
    
    %% Save Data
    NameFolfer  = fullfile(obj.PathProject,'RESULTS','AMI');    
    NameFile    = fullfile(NameFolfer,[num2str(obj.Code(PoPo(wi))),'.csv']);
    ID_File     = fopen(NameFile,'w');
    fprintf(ID_File,'%s\n','Lag,Power');
    
    fprintf(ID_File, '%f%f\n',[lag,v]');
    fclose(ID_File);
    
    %% Plot
    if obj.StatusPlot
        Fig     = figure('color',[1 1 1]);
        T       = [10, 8];
        set(Fig, 'Units', 'Inches', 'PaperPosition', [0, 0, T],'Position',...
        [0, 0, T],'PaperUnits', 'Inches','PaperSize', T,'PaperType','usletter', 'Visible','off') 

        plot(lag, v,'Linewidth',2, 'color',obj.ColorsF('carmine'))

        xlabel('\bf Lag','interpreter','latex', 'Fontsize',20)
        ylabel('\bf Power', 'interpreter','latex', 'Fontsize',20)
        set(gca, 'xscale','log','yscale','log','TickLabelInterpreter','latex',...
            'FontWeight','bold','Color','none', 'box','on','FontSize',18)

        %% Save plot
        saveas(Fig, fullfile(obj.PathProject,'FIGURES','AMI',[num2str(obj.Code(PoPo(wi))),'.jpg']))
        close(Fig)
    end

end
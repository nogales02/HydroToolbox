function [QTR] = Return_Period(obj, varargin)
%% Periodos de retorno
if nargin > 1
    mes = varargin{1}; 
else
    mes = [];
end

if nargin > 2
    Code_PoPo = varargin{2};
else
    Code_PoPo = [];
end
if ~isempty(Code_PoPo)
    [~, PoPo] = ismember(Code_PoPo, obj.Code);
else
    PoPo = 1:length(obj.Code);
end

Code = obj.Code(PoPo);
Code = reshape(Code,length(Code),1);

%% Create Folder
mkdir(fullfile(obj.PathProject,'RESULTS','Periodos_de_Retorno'))

T       = [2, 5, 10, 25, 50, 100];
QTR = NaN(length(PoPo), length(T));
for ii = 1:length(PoPo)
        try
        id          = find(~isnan(obj.Data(:,PoPo(ii))));
        Data        = obj.Data(id(1):id(end),PoPo(ii));

        %% Fitting NAN Value
        Data(isnan(Data)) = mean(Data(~isnan(Data)));
                
        %% Remove Zeros
%         Data = Data(Data>0);
        Data = reshape(Data(25:end,:),12,[]);
        Data = [Data(mes,:)]';
        
       pdfm         = fitdist(Data,obj.Mejorpdf{ii});
       % Valores de caudal de los peridos de retorno evaluados
       eval    = 1 - (1./T);
       QTR(ii,:) = icdf(pdfm,eval);
    catch
    end
end




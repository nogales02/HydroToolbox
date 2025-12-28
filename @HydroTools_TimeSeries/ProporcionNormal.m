function ProporcionNormal(obj, varargin)
% OBJETIVO
% Complemntacion de datos faltantes por Proporcion Normal con datos de la misma estacion
% a resolucion Mensual 
%
%% DATOS BASICOS
% Nombre: Jonathan Nogales Pimentel
% 
%% DATOS DE ENTRADA 
% P 	: Precipitacion pivot (mm/mes)
%
%% DATOS DE SALIDA
% Pcom 	: Precipitacion Complementada (mm/mes)
%

%% Preliminary
warning off

%% Codes
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

%% Initial Date
InitData    = zeros(length(obj.Code), 1);
EndData     = zeros(length(obj.Code), 1);
for i = 1:length(obj.Code)
    Ident           = (1:length(obj.Date));
    tmp             = Ident(~isnan(obj.Data(:,i)));
    if isempty(tmp)
        InitData(i,1)   = 1;
        EndData(i,1)    = length(obj.Date);
        continue
    end
    InitData(i,1)   = tmp(1) -1;
    EndData(i,1)    = tmp(end) + 1;
end

%% Estimate Max
M = month(obj.Date);
MaxData = zeros(12, length(obj.Code));
MinData = zeros(12, length(obj.Code));
for i = 1:12
    MaxData(i,:) = max(obj.Data(M==i,:));
    MinData(i,:) = min(obj.Data(M==i,:));
end

%% Initial Complementation
for ii = 1:length(PoPo) 
    
    idii    = find(~isnan(obj.Data(:,PoPo(ii))));
    Data    = obj.Data(idii(1):idii(end),PoPo(ii));   
    Date    = obj.Date(idii(1):idii(end));
    
    %% Complect Date 
    Date_Init   = Date(1);
    Date_End    = Date(end);
    if obj.dt == duration(24,0,0)
        Date_Tmp    = (datetime(year(Date_Init),1,1):obj.dt:datetime(year(Date_End),12,31))';
    end
    id_1 = find( month(Date_Tmp) == 2 );
    id_2 = find( day(Date_Tmp(id_1)) == 29);
    id_b = id_1(id_2);
    
    [id_Nb,posi] = ismember( (1:length(Date_Tmp))', id_b);
    Date_Tmp = Date_Tmp(~id_Nb);
    
    Data_P = NaN(size(Date_Tmp));
    [id, posi] = ismember(Date, Date_Tmp);
    Data_P(posi(id)) = Data(id); 
    
    %% Pivot 
    Data_P = reshape(Data_P,365,[])';
    
    %% PROPORCION NORMAL
    Pcom = Data_P;
    [fil,~] = find(isnan(Data_P));
    fil = unique(sort(fil));
    for i = 1:length(fil)
        [~,col] = find(isnan(Data_P(fil(i),:)));
        n = length(col);
        k = 1;
        B = -1*ones(n,n);
        Xj = sum(Data_P(fil(i),:),2,'omitnan');
        Pa = mean(sum(Data_P,2,'omitnan'),'omitnan');
        for j = 1:length(col)
            Ni = mean(Data_P(:,col(j)),'omitnan');
            % Matriz
            B(k,k) = ((Pa/Ni) - 1);
            k = k + 1;
        end
        X = mldivide(B, repmat(Xj,[n,1]));
        Pcom(fil(i),col) = X;
    end   
    
    %% Pivot 
    Pcom = reshape(Pcom',[],1);

end

%% Remove Max and Min Data
M = month(obj.Date);
for i = 1:12
    id = find(M == i);

    %% Ckeck Max data
    for j = 1:length(MaxData(1,:))
        idd = (obj.Data(M==i,j) > MaxData(i,j));
        obj.Data(id(idd), j) = MaxData(i,j);
    end

    %% Ckeck Min data
    for j = 1:length(MinData(1,:))
        idd = (obj.Data(M==i,j) < MinData(i,j));
        obj.Data(id(idd), j) = MinData(i,j);
    end
end

%% only for rainfall data
for i = 1:length(obj.Code)    
    if InitData(i) == 1
        obj.Data(InitData(i),i)     = NaN;

    elseif InitData(i) > 1
        obj.Data(1:InitData(i),i)   = NaN;
    end

    if EndData(i) == fil
        obj.Data(EndData(i),i)      = NaN;

    elseif EndData(i) < fil
        obj.Data(EndData(i):fil,i)  = NaN;
    end    
end
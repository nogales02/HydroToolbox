function [bestx,bestf,allbest,allEvals] = Opt_LHS(Basin)
%        [bestx,bestf,allbest,allEvals] = sce(fctname,x0,bl,bu,ngs,Basin)
%
% Shuffled Complex Evolution (SCE-UA) METHOD
%
% written (MATLAB)  by Q.Duan   09.2004
% sligthly modified by F.Anctil 01.2009
% lhs initialisation and parallel version by D.Brochero 10.2015
%
% INPUTS
%  fctname = character string of the function to optimize
%  x0      = the initial parameter array at the start;
%          = the optimized parameter array at the end;
%  bl      = the lower bound of the parameters
%  bu      = the upper bound of the parameters
%  ngs     = number of complexes (sub-pop.)- between 2 and 20
%  Basin (optional) - for the function to optimize
%
%%% FA modifications
%
% 0. commented unused command lines
% 1. reduced the number of inputs by preselection
% 2. add the function name (to be optimized) to the input list
% 3. allow Basin to be passed to that function
% 4. keep track of each loop best f and x, and of number of trials
% 
% DB modifications
%
% 0. parallel version of complex evaluations
% 1. options to change directly algorithm parameters 
% 2. default parameters if they are not defined
% 3. LHS initialisation of points
% 4. initial population (x0) is correctly included if it is defined
% 5. stop for convergency is fixed by including a return command
%
% % PRESELECTED INPUTS (by FA according to the recommendation of Duan)
% %
% maxn   = 10000 ;
% kstop  = 10 ;
% pcento = 0.1 ;
% peps   = 0.001;
% iniflg = 0 ;
%
%  maxn   = maximum number of function evaluations allowed during optimization
%  kstop  = maximum number of evolution loops before convergency
%  pcento = percentage change allowed in kstop loops before convergency
%  peps   = preselected samll parameter space
%  iniflg = flag for initial parameter array
%           ==1 include it in initial population; otherwise, not included)
%
% LIST OF LOCAL VARIABLES
%  f0        = objective fct value corresponding to the initial parameters
%            = objective fct value corresponding to the optimized parameters
%  npg       = number of members in a complex
%  nps       = number of members in a simplex
%  nspl      = number of evolution steps for each complex before shuffling
%  mings     = minimum number of complexes required during the
%              optimization process
%  x(.,.)    = coordinates of points in the population
%  xf(.)     = function values of x(.,.)
%  xx(.)     = coordinates of a single point in x
%  cx(.,.)   = coordinates of points in a complex
%  cf(.)     = function values of cx(.,.)
%  s(.,.)    = coordinates of points in the current simplex
%  sf(.)     = function values of s(.,.)
%  bestx(.)  = best point at current shuffling loop
%  bestf     = function value of bestx(.)
%  worstx(.) = worst point at current shuffling loop
%  worstf    = function value of worstx(.)
%  xnstd(.)  = standard deviation of parameters in the population
%  gnrng     = normalized geometri%mean of parameter ranges
%  lcs(.)    = indices locating position of s(.,.) in x(.,.)
%  bound(.)  = bound on ith variable being optimized
%  ngs1      = number of complexes in current population
%  ngs2      = number of complexes in last population
%  iseed1    = current random seed
%  criter(.) = vector containing the best criterion values of the last
%              10 shuffling loops
%
% TODO: generate exemple and readme file to share easily this function

% PRESELECTED INPUTS (by FA according to the recommendation of Duan)
%  ngs     = number of complexes (sub-pop.)- between 2 and 20
%  npg     = number of members in a complex
%  nps     = number of members in a simplex
%  nspl    = number of evolution steps for each complex before shuffling

%% Datos de entrada
% Valor mínimo de parámetros
if Basin.Status_ModelFlood
    bl      = Basin.bl;
else
    bl      = Basin.bl(5:end);
end
% Valor máximo de parámetros
if Basin.Status_ModelFlood
    bu      = Basin.bu;
else
    bu      = Basin.bu(5:end);
end
% Número de variables a optimizar
nopt    = length(bl);
% Máximo número de iteraciones
npt     = Basin.maxIter;
% Rango de variación de los parámetros
bound   = bu-bl;

%% Generación de parametros a evaluar con latin hypercube design
try    
    rlhs    = lhsdesign(npt, nopt);
    x       = repmat(bl, npt, 1) + repmat(bound, npt, 1).*rlhs;
catch
    x       = repmat(bl, npt, 1) + repmat(bound, npt, 1).*rand(npt, nopt);
end

%% Guardar todos lo parámetros a evaluar
% Update Parameters table        
NameParams = 'Trp (Porc),Tpr (Porc),Q_Umb (mm), V_Umb (mm)';
FormatFile = '%f,%f,%f,%f';
for ki = 1:length(x(1,5:end))
    NameParams = [NameParams,',Params-',num2str(ki)];
    FormatFile = [FormatFile,',%f'];
end
FormatFile = [FormatFile,',%f\n'];
NameParams = [NameParams,',',Basin.CalMetricSelect,'\n'];

fileID = fopen( fullfile(Basin.PathProject, 'OUTPUTS','AllEvals',Basin.OptMethod,...
                [num2str(Basin.CodeQobs),'.csv']),'w');
fprintf(fileID,NameParams);
fprintf(fileID,FormatFile,[x zeros(Basin.maxIter,1)]');
fclose(fileID);

%% Evaluar parámetros
MatricsCal   = zeros(npt,1);
if Basin.parRuns
    parfor i = 1:npt        
        MatricsCal(i,1) = Basin.FunctionObj(x(i,:),i);
    end
else
    for i=1:npt        
        MatricsCal(i,1) = Basin.FunctionObj(x(i,:),i);
    end
end

if ~Basin.Status_ModelFlood
    x = [NaN(length(x(:,1)),4) x];
end

%% Resumen de parámetros
id          = find(MatricsCal == min(MatricsCal));
bestx       = x(id(1),:);
bestf       = MatricsCal(id(1));
allbest     = [x MatricsCal];
allEvals    = [x MatricsCal];

%% limpiar varable
Basin.Data = [];
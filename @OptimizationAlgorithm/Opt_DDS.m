function [bestx,bestf,allbest,allEvals] = Opt_DDS(Basin)

[best, allbest, solution] = Basin.dds;

bestf       = best(end);
bestx       = best(1:end-1);
allEvals    = solution(:,4:end);

if ~Basin.Status_ModelFlood
    allEvals = [NaN(length(allEvals(:,1)),4) allEvals];
    bestx    = [NaN(1,4) bestx];
end
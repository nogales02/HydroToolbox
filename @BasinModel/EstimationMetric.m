function Matrics = EstimationMetric(obj, Qobs, Qsim)

% %% Duration Curve
% [Por_Q,Qd]      = hist(Qobs,length(unique(Qobs)));
% [Q_QQobs, id ]  = sort(Qd, 'descend');
% PQ_QQobs        = (cumsum(Por_Q(id))/sum(Por_Q(id)))*100;
% 
% [Por_Q,Qd]      = hist(Qsim,length(unique(Qsim)));
% [Q_Qsim, id ]   = sort(Qd, 'descend');
% PQ_Qsim         = (cumsum(Por_Q(id))/sum(Por_Q(id)))*100;

%% Coefficient Nash
Matrics.Nash        = 1 - ((mean((Qobs - Qsim).^2, 'omitnan'))./var(Qobs( ~isnan(Qobs) )));

% 
% %% Absolute Mean error 
% Matrics.AME     = max(abs(Qobs-Qsim));
%     
% %% unlike peaks 
% Matrics.PDIFF   = max(Qobs)-max(Qsim);
% 
% %% Mean Absolute Error 
% Matrics.MAE     = mean(abs(Qobs-Qsim),'omitnan');
% 
% %% Mean Square Error 
% Matrics.MSE     = mean((Qobs-Qsim).^2,'omitnan');
% 
% %% Root Mean Square Error
% Matrics.RMSE    = sqrt(Matrics.MSE);
% 
% %% Root Fourth Mean Square Fourth Error
% Matrics.R4MS4E  = nthroot((mean((Qobs-Qsim).^4,'omitnan')),4);
% 
% %% Root Absolute Error 
% Matrics.RAE     = sum(abs(Qobs-Qsim),'omitnan')/sum(abs(Qobs-mean(Qobs,'omitnan')),'omitnan');
% 
% %% percent Error in peak 
% Matrics.PEP     = ((max(Qobs)-max(Qsim))/max(Qobs))*100;
% 
% %% Mean Absolute Relative Error
% Matrics.MARE    = mean(sum((abs(Qobs-Qsim))/Qobs,'omitnan'),'omitnan');
% 
% %% Mean Relative Error 
% Matrics.MRE     = mean(sum((Qobs-Qsim)/Qobs,'omitnan'),'omitnan');
% 
% %% Mean Square Relative Error 
% Matrics.MSRE    = mean(sum(((Qobs-Qsim)/Qobs).^2,'omitnan'),'omitnan');
% 
% %% PBIAS
% Matrics.PBIAS   = (sum(Qobs-Qsim,'omitnan')/sum(Qobs,'omitnan'))*100;
% 
% %% Nash-Sutcliffe Coefficient of Efficiency
% Enum        = sum((Qobs-Qsim).^2,'omitnan');
% Edenom      = sum((Qobs-mean(Qobs,'omitnan')).^2,'omitnan');
% Matrics.CE      = 1-Enum/Edenom;
% 
% %% Correlation Coefficient
% Rnum        = sum((Qobs-mean(Qobs,'omitnan')).*(Qsim-mean(Qsim,'omitnan')),'omitnan');
% Rdenom      = sqrt(sum((Qobs-mean(Qobs,'omitnan')).^2,'omitnan')*sum((Qsim-mean(Qsim,'omitnan')).^2,'omitnan'));
% Matrics.R       = Rnum/Rdenom;
% 
% %% Percentage Bias Error
% Matrics.PBE     = sum(Qsim-Qobs,'omitnan')/sum(Qobs,'omitnan')*100;
% 
% %% Average Absolute Relative Error
% ARE     = abs(((Qsim-Qobs)./Qobs)*100);
% ARE(isnan(ARE)) = 0; 
% ARE(isinf(ARE)) = 0;
% Matrics.AARE    = mean(ARE,'omitnan');

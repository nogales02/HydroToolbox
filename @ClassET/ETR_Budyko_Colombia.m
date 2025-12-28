function ETR = ETR_Budyko_Colombia(obj, ETP, P)
id      = (P == 0);
P(id)   = 0.01;
ETR     = (ETP.*P.*tanh(P./ETP)).*(1 - cosh(ETP./P) + sinh(ETP./P));
ETR(ETR < 0) = 0;
ETR     = sqrt(ETR);
ETR(id) = 0;
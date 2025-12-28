function ETP = ETP_TurcAnnual(obj, Tavg, P)

L = 300 + (20.*Tavg) + (0.05.*(Tavg.^2));

ETP = P./ sqrt(0.9 + ((P./L).^2));

ETP( ((P./L).^2) < 1 ) = P( ((P./L).^2) < 1 );
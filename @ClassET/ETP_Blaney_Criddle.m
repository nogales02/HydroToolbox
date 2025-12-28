function ETP = ETP_Blaney_Criddle(obj, Tavg)

ETP = 1.*(100.*(8./(365.*12))).*((0.46.*Tavg) + 8.13);
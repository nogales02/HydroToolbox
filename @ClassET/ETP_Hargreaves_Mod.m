function ETP = ETP_Hargreaves_Mod(obj, Tavg, TD, Ra, P)
    ETP = 0.0013.*0.408.*Ra.*(Tavg + 17).*((TD - 0.0123.*P).^0.76);
end
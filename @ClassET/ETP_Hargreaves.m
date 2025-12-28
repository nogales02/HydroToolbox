function ETP = ETP_Hargreaves(obj, Tavg, TD, Ra)
    ETP = 0.0023.*0.408.*Ra.*(Tavg + 17.78).*((TD).^0.5);
end

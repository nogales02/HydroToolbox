function ETP = ETP_McGuiness(obj, Tavg, Ra)
    ETP = (Ra./2.45).*((Tavg + 5)./68);
end

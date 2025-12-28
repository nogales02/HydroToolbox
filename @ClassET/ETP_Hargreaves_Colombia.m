function ETP = ETP_Hargreaves_Colombia(obj, Tavg, TD, Ra)
% P: Precipitación anual multianual (mm)
% Tavg mín – máx – med: Temperatura mínima máxima y media (°C)
% Ro: Radiación extraterrestre expresada MJ/(m^2*dia)
% ETP: Evapotranspiración Potencial anual multiananual de Hargreaves (mm)
% ETR: Evapotranspiración Real Potencial anual multiananual de Budyko (mm)

ETP = 0.00216.*0.408.*Ra.*(Tavg + 17.78).*((TD).^0.47);

end
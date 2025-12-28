function J = JulianDay(obj, Date)

A       = year(Date);
M       = month(Date);
D       = day(Date);
Leap    = obj.leapyear(A);
J       = ((275.*(M./9))-30+D)-2;
J       = floor(J);
J(M<3)  = J(M<3) + 2;
J(Leap & (M > 2)) = J(Leap & (M > 2)) + 1;

end

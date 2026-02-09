function p = my_fcdf(x, d1, d2)
% my_fcdf - F cumulative distribution function (no Statistics Toolbox needed)
% Uses the regularized incomplete beta function (betainc)
% p = my_fcdf(x, d1, d2) returns P(F <= x) for F(d1,d2) distribution

if x <= 0
    p = 0;
    return;
end

% F-CDF via regularized incomplete beta function
% P(F<=x) = betainc(d1*x/(d1*x+d2), d1/2, d2/2)
p = betainc(d1*x / (d1*x + d2), d1/2, d2/2);
end

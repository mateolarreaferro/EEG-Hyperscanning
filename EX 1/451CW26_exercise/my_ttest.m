function [h, p] = my_ttest(x, y)
% MY_TTEST Paired two-tailed t-test without Statistics Toolbox
%   [h, p] = my_ttest(x, y)
%   h = 1 if null hypothesis rejected at alpha=0.05, 0 otherwise
%   p = two-tailed p-value

d = x - y;
n = length(d);
d_bar = mean(d);
s_d = std(d);

if s_d == 0
    h = 0; p = 1;
    return;
end

t_stat = d_bar / (s_d / sqrt(n));
df = n - 1;

% Two-tailed p-value using incomplete beta function
p = betainc(df / (df + t_stat^2), df/2, 0.5);

h = double(p < 0.05);
end

function [sc,align]=compareimu(m,s)
% get pitch from data set
pm = m(:,2);
ps = s(:,2);
% align
[acorr, lags] = xcorr(pm, ps);
[maxcorr, idx] = max(abs(acorr));
lagDiff = lags(idx);
% score is the reported max correlation (corresponding to best alignment)
sc=maxcorr;
% align: which point in s corresponds to which point in m? 
% right now, it's the alignment offset from s to m,
% with the correspondence is given by t(s) = t(m) - lagDiff
% For example, if s lags m, lagDiff returned by xcorr 
% will be negative, and we have e.g.
% index 1 in master align with e.g. index 201 in student signal
align = ones(1, length(ps)) * lagDiff;
end


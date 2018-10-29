function [sc,align]=compareimu(m,s)
sc=1;
align=round((1:length(m))*length(s)/length(m),0);
end


function [sc,align]=compareimu(m,s)
sc=1;
align=round((1:length(s))*length(m)/length(s),0);
end


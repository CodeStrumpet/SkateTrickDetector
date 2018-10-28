function rpy=q2rpy(q)
rpy=zeros(size(q,1),3);
for i=1:size(q,1)
  [r,p,y]=dcm2angle(qGetR(q(i,:)));
  rpy(i,:)=[r,p,y];
end
for i=2:size(rpy,1)
  for j=1:3
    if rpy(i,j)-rpy(i-1,j) > pi
      rpy(i:end,j)=rpy(i:end,j)-2*pi;
    elseif rpy(i,j)-rpy(i-1,j) < -pi
      rpy(i:end,j)=rpy(i:end,j)+2*pi;
    end
  end
end
rpy=rpy(:,[3,2,1]);


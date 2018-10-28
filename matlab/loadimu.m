function rpy=loadimu(mmufile)
[time,q1,q2,q3,q4,tag]=textread(mmufile,'%d %f %f %f %f %s','delimiter',',');
quat=[q1,q2,q3,q4];
rpy=real(q2rpy(quat));
figure(1);clf;
plot((time-time(1))/1000,rpy);
legend('Roll','Pitch','Yaw');
title(mmufile);
figfile=strrep(strrep(mmufile,'imu','plt'),'csv','jpg');
fprintf('Saving to %s\n', figfile);
%mkinsert(gcf,'name',figfile,'width',100);



function quat=analyze(mmufile)
[time,q1,q2,q3,q4,tag]=textread(mmufile,'%d %f %f %f %f %s','delimiter',',');
quat=[q1,q2,q3,q4];
rpy=q2rpy(quat);
setfig(mmufile);clf;
plot((time-time(1))/1000,rpy);
legend('Roll','Pitch','Yaw');
title(mmufile);
imufig=gcf;
vidfile=strrep(strrep(mmufile,'imu','vid'),'csv','mov');
vidObj=VideoReader(vidfile);

 
% Specify that reading should start at 0.5 seconds from the
% beginning.
vidfig=1;
figure(vidfig);clf;
vidObj.CurrentTime = 0;

subplot(211);
plot(1,1);
% Create an axes
currAxes = axes;

% Read video frames until available
while true
  figure(imufig);
  t=ginput(1);
  if isempty(t)
    break;
  end
  vidObj.CurrentTime = t(1);
  vidFrame = readFrame(vidObj);
  image(vidFrame, 'Parent', currAxes);
  currAxes.Visible = 'off';
end

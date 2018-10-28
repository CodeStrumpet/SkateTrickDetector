function list=loadfiles(path)
  list=[];
  d=dir([path,'/imu*.csv']);
  for i=1:length(d)
    di=d(i);
    di.csv=di.name;
    di.rpy=loadimu([di.folder,'/',di.name]);
    di.vid=strrep(strrep(di.name,'csv','mov'),'imu','vid');
    di.json=strrep(strrep(di.name,'csv','json'),'imu','res');
    list=[list,di]; 
  end
end
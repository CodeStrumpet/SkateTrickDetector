% Run through files in 'unprocessed', compare against everything in 'master' and save results 
% in new file moved alongside called res_xxx.json, and plt_xxx.jpg, moved into 'results'
basedir='/Users/bst/Dropbox/InstallationArt/SkateTrickDetector/data';
unprocessed=loadfiles([basedir,'/','unprocessed']);
master=loadfiles([basedir,'/','master']);
fprintf('Have %d unprocessed files, %d master files]\n', length(unprocessed), length(master));
for i=1:length(unprocessed)
  scores=[];
  for j=1:length(master)
    [sc,align]=compareimu([master(j).folder,'/',master(j).csv],[unprocessed(i).folder,'/',unprocessed(i).csv]);
    scores=[scores,struct('master',master(j).name,'vid',[master(j).folder,'/',master(j).vid],'score',sc,'align',align,'rpy',master(j).rpy)];
  end
  [~,best]=max([scores.score]);
  unprocessed(i).scores=scores(best);
  savejson(unprocessed(i));
end


function savejson(d)
json=jsonencode(d,'ConvertInfAndNaN',true);
fd=fopen([d.folder,'/',d.json],'w');
fprintf(fd,'%s',json);
fclose(fd);
end


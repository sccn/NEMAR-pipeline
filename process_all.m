nemar_path = '/expanse/projects/nemar/openneuro';
children = dir(nemar_path);
folders = {children.name};
dsfolders = folders(startsWith(folders, 'ds'));
ignore = {'ds001787', 'ds002718', 'ds003645'};
for i=127:157 %96:126 %65:95 % numel(dsfolders)
    dsnumber = dsfolders{i};
    if ~any(strcmp(dsnumber, ignore))
	    fprintf("Processing %s\n", dsnumber);
	    system(['./create_and_submit_job.sh ' dsnumber]);
    end
end

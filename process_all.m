nemar_path = '/expanse/projects/nemar/openneuro';
children = dir(nemar_path);
folders = {children.name};
dsfolders = folders(startsWith(folders, 'ds'));
ignore = {'ds003645', 'ds002718', 'ds002691'};
for i=1:32 %16:25 %numel(dsfolders)
    dsnumber = dsfolders{i};
    if ~any(strcmp(dsnumber, ignore))
	    fprintf("Processing %s\n", dsnumber);
	    system(['./create_and_submit_job.sh ' dsnumber]);
    end
end

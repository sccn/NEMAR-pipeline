nemar_path = '/expanse/projects/nemar/openneuro';
children = dir(nemar_path);
folders = {children.name};
dsfolders = folders(startsWith(folders, 'ds'));

for i=1:5 %numel(dsfolders)
    dsnumber = dsfolders{i};
    fprintf("Processing %s\n", dsnumber);
    system(['./create_and_submit_job.sh ' dsnumber]);
end
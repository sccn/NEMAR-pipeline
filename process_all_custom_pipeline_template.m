nemar_path = '/expanse/projects/nemar/openneuro';
nemar_path = '/expanse/projects/nemar/openneuro/processed';
children = dir(nemar_path);
folders = {children.name};
dsfolders = folders(startsWith(folders, 'ds'));

addpath("/home/dtyoung/NEMAR-pipeline")

for i=1:numel(dsfolders)
    dsnumber = dsfolders{i};
    
	fprintf("Processing %s\n", dsnumber);
    try
    %         fcn_name = "test_function";
    %         options = {};
    % 	    run_pipeline_custom(dsnumber, fcn_name, options);
        run_pipeline(dsnumber, 'preprocess', false, 'vis', false, 'dataqual', true, 'maxparpool', 0, 'modeval', 'rerun');
    catch ME
        fprintf("%s\n", ME.identifier);
        fprintf("%s\n", ME.message);
        fprintf("%s\n", ME.getReport());
    end
end

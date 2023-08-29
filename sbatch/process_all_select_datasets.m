function process_all_select_datasets(varargin)
root_path = '/home/dtyoung/NEMAR-pipeline';
addpath(root_path);

dsfolders = {'ds003104','ds003805','ds004444','ds004554','ds003633','ds000246','ds004119','ds004106','ds004520','ds004521','ds004519','ds004368','ds004000','ds003374','ds003509','ds003568','ds003766','ds003505','ds004080','ds003848'};

for i=1:numel(dsfolders)
    dsnumber = dsfolders{i};
    
	fprintf('Processing %s\n', dsnumber);
    try
        ds_create_and_submit_job(dsnumber, varargin{:});
    catch ME
        fprintf('%s\n', ME.identifier);
        fprintf('%s\n', ME.message);
        fprintf('%s\n', ME.getReport());
    end
end
end

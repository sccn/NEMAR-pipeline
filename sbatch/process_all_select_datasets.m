function process_all_select_datasets(varargin)
root_path = '/home/dtyoung/NEMAR-pipeline';
addpath(root_path);

dsfolders = {'ds003645','ds002550','ds003568','ds003633','ds003104','ds000246','ds000247','ds000248','ds003682','ds003694','ds003703','ds003082','ds003483'}; % MEG datasets

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

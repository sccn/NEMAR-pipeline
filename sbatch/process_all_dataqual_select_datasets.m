root_path = '/home/dtyoung/NEMAR-pipeline';
addpath(root_path);

dsfolders = {'ds004532', 'ds004252', 'ds001785', 'ds003352', 'ds002885', 'ds002761', 'ds004317', 'ds003421', 'ds004262', 'ds004278', 'ds003505', 'ds002791', 'ds003420', 'ds002034', 'ds004502', 'ds004408', 'ds004357', 'ds004348', 'ds001849', 'ds000117', 'ds004477', 'ds002338', 'ds004256', 'ds004315', 'ds001810', 'ds004505', 'ds003392', 'ds004574', 'ds002158', 'ds004368', 'ds002578', 'ds004306', 'ds004347', 'ds003645', 'ds002799', 'ds004330', 'ds004446', 'ds004561', 'ds004381', 'ds004447', 'ds004473', 'ds004276', 'ds004575', 'ds002550', 'ds004460', 'ds000246', 'ds003029', 'ds001971', 'ds004504', 'ds004457', 'ds004356', 'ds004369', 'ds002712', 'ds004448', 'ds004295', 'ds002336', 'ds004346', 'ds004444', 'ds004551', 'ds001784', 'ds004196', 'ds004264', 'ds004398', 'ds004367', 'ds002001', 'ds004511'};
for i=1:numel(dsfolders)
    dsnumber = dsfolders{i};
    
	fprintf('Processing %s\n', dsnumber);
    try
	    system([root_path '/create_and_submit_job.sh ' dsnumber]);
        %run_pipeline(dsnumber, 'preprocess', false, 'vis', false, 'dataqual', true, 'maxparpool', 0, 'modeval', 'rerun');
    catch ME
        fprintf('%s\n', ME.identifier);
        fprintf('%s\n', ME.message);
        fprintf('%s\n', ME.getReport());
    end
end

% allow to inject custom code for a dataset

function check_dataset_custom_code(dsnumber)
dataset_code_dirname = 'dataset-code';
path = which("run_pipeline");
[path, ~] = fileparts(path);
custom_path = fullfile(path, dataset_code_dirname, dsnumber);
if exist(custom_path, 'dir')
   fprintf('Custom path found for %s, adding it to MATLAB path...\n', dsnumber);
   addpath(custom_path);
   cd(custom_path);
end
end
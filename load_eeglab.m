function load_eeglab(root_path)
if nargin < 1
    root_path = '/expanse/projects/nemar/dtyoung/NEMAR-pipeline';
end
addpath(fullfile(root_path,'eeglab'));
addpath(fullfile(root_path,'JSONio'));
eeglab nogui;
end

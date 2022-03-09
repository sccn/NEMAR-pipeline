function load_eeglab(root_path)
addpath(fullfile(root_path,'/eeglab'));
addpath(fullfile(root_path,'JSONio'));
eeglab nogui;
end

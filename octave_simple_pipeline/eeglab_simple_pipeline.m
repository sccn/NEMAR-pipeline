eeglabpath = fileparts(fileparts(fileparts(pwd)));
addpath(pwd);

addpath(fullfile( eeglabpath, [ 'functions' filesep 'adminfunc'        ]));
addpath(fullfile( eeglabpath, [ 'functions' filesep 'adminfunc'        ]));
addpath(fullfile( eeglabpath, 'functions'));
addpath(fullfile( eeglabpath, [ 'functions' filesep 'sigprocfunc'      ]));
addpath(fullfile( eeglabpath, [ 'functions' filesep 'guifunc'          ]));
addpath(fullfile( eeglabpath, [ 'functions' filesep 'studyfunc'        ]));
addpath(fullfile( eeglabpath, [ 'functions' filesep 'popfunc'          ]));
addpath(fullfile( eeglabpath, [ 'functions' filesep 'statistics'       ]));
addpath(fullfile( eeglabpath, [ 'functions' filesep 'timefreqfunc'     ]));
addpath(fullfile( eeglabpath, [ 'functions' filesep 'miscfunc'         ]));
addpath(fullfile( eeglabpath, [ 'functions' filesep 'supportfiles'     ]));
addpath(fullfile(eeglabpath, 'plugins', 'ICLabel'));
addpath(fullfile(eeglabpath, 'plugins', 'clean_rawdata'));
addpath(fullfile(eeglabpath, 'plugins', 'firfilt'));
addpath(fullfile(eeglabpath, 'plugins', 'firfilt'));
addpath(fullfile(eeglabpath, 'plugins', 'PICARD1.0'));
addpath(fullfile(eeglabpath, 'plugins', 'dipfit'));

EEG = pop_loadset(fullfile(eeglabpath, 'sample_data', 'eeglab_data.set'));

% compute average reference
EEG = pop_reref( EEG,[]);

% clean data using the clean_rawdata plugin
EEG = pop_clean_rawdata( EEG,'FlatlineCriterion',5,'ChannelCriterion',0.87, ...
    'LineNoiseCriterion',4,'Highpass',[0.25 0.75] ,'BurstCriterion',20, ...
    'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian', ...
    'WindowCriterionTolerances',[-Inf 7] ,'fusechanrej',1);

% recompute average reference interpolating missing channels (and removing
% them again after average reference - STUDY functions handle them automatically)
EEG = pop_reref( EEG,[],'interpchan',[]);

% run ICA reducing the dimension by 1 to account for average reference 
EEG = pop_runica(EEG, 'icatype','picard','concatcond','on','options',{'pca',-1});

% run ICLabel and flag artifactual components
EEG = pop_iclabel(EEG, 'default');
EEG = pop_icflag( EEG,[NaN NaN;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
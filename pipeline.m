function bids_preprocess(dsnumber, varargin)
nemar_path = '/expanse/projects/nemar/openneuro';
opt = finputcheck(varargin, { ...
    'bidspath'       'string'    {}    fullfile(nemar_path, dsnumber);  ...
    'eeglabroot'     'string'    {}    '/expanse/projects/nemar/dtyoung/NEMAR-pipeline'; ...
    'logdir'         'string'    {}    fullfile(nemar_path, 'processed', dsnumber, 'logs'); ...
    'outputdir'      'string'    { }   fullfile(nemar_path, 'processed', dsnumber); ...
    }, 'bids_preprocess');
if isstr(opt), error(opt); end

% check folder
addpath(fullfile(opt.eeglabroot,'eeglab'));
addpath(fullfile(opt.eeglabroot,'JSONio'));
eeglab nogui;
if ~exist(fullfile(opt.bidspath,'dataset_description.json'), 'file')
    error('Dataset description file not found');
end

% import data
[STUDY, ALLEEG, dsname] = load_dataset(opt.bidspath, opt.outputdir);

if ~exist(opt.logdir, 'dir')
    status = mkdir(opt.logdir);
    if ~status
        error('Could not create log directory');
    end
end

% pop_editoptions( 'option_storedisk', 0); % load all data
%[STUDY, ALLEEG] = pop_importbids(filepath, 'studyName','FirstEpisodePsychosisRestingEEG', 'bidsevent', 'off');

% % remove non-ALLEEG channels (it is also possible to process ALLEEG data with non-ALLEEG data
% get non-EEG channels
all_chans = {ALLEEG(1).chanlocs.labels};
types = {ALLEEG(1).chanlocs.type};
non_eeg_channels = all_chans(strcmp(types, 'EEG')); % relying on the import tool to import channel types. Currently there's issue
% remove non-EEG channels
options = {'nochannel', non_eeg_channels};
ALLEEG = parexec(ALLEEG, 'pop_select', 'logs', options{:});
% ALLEEG = pop_select( ALLEEG,'nochannel',{'VEOG', 'Misc', 'ECG', 'M2'});
% 
% % compute average reference
ALLEEG = pop_reref( ALLEEG,[]);

% clean data using the clean_rawdata plugin
options = {'FlatlineCriterion',5,'ChannelCriterion',0.85, ...
    'LineNoiseCriterion',4,'Highpass',[0.25 0.75] ,'BurstCriterion',20, ...
    'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian', ...
    'WindowCriterionTolerances',[-Inf 7] ,'fusechanrej',1};
ALLEEG = parexec(ALLEEG, 'pop_clean_rawdata', 'logs', options{:});
% ALLEEG = pop_clean_rawdata( ALLEEG,);
save_datasets(ALLEEG)

% recompute average reference interpolating missing channels (and removing
% them again after average reference - STUDY functions handle them automatically)
ALLEEG = pop_reref( ALLEEG,[],'interpchan',[]);
save_datasets(ALLEEG)

% run ICA reducing the dimention by 1 to account for average reference 
options = {'icatype','runica','concatcond','on','options',{'pca',-1}};
ALLEEG = parexec(ALLEEG, 'pop_runica', 'logs', options{:});
% ALLEEG = pop_runica(ALLEEG,);
save_datasets(ALLEEG)

% % run ICLabel and flag artifactual components
ALLEEG = pop_iclabel(ALLEEG, 'default');
ALLEEG = pop_icflag( ALLEEG,[NaN NaN;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);

% pop_editoptions( 'option_storedisk', 1); % only one dataset at a time

function save_datasets(ALLEEG)
    for i=1:numel(ALLEEG)
        pop_saveset(ALLEEG(i), 'filepath', ALLEEG(i).filepath, 'filename', ALLEEG(i).filename);
    end
end
end

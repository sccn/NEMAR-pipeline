function bids_preprocess(dsnumber, varargin)
nemar_path = '/expanse/projects/nemar/openneuro';
eeglabroot = '/expanse/projects/nemar/dtyoung/NEMAR-pipeline';

if isempty(which('finputcheck'))
    addpath(fullfile(eeglabroot,'eeglab'));
    addpath(fullfile(eeglabroot,'JSONio'));
    eeglab nogui;
end

opt = finputcheck(varargin, { ...
    'bidspath'       'string'    {}    fullfile(nemar_path, dsnumber);  ...
    'eeglabroot'     'string'    {}    eeglabroot; ...
    'logdir'         'string'    {}    fullfile(nemar_path, 'processed', 'logs', dsnumber); ...
    'outputdir'      'string'    { }   fullfile(nemar_path, 'processed', dsnumber); ...
    'verbose'        'boolean'   {}    false; ...
    }, 'bids_preprocess');
if isstr(opt), error(opt); end

% reload eeglab if different version specified
if ~strcmp(eeglabroot, opt.eeglabroot)
    addpath(fullfile(opt.eeglabroot,'eeglab'));
    addpath(fullfile(opt.eeglabroot,'JSONio'));
    eeglab nogui;
    if opt.verbose
	which pop_importbids;
    end
end

if ~exist(fullfile(opt.bidspath,'dataset_description.json'), 'file')
    error('Dataset description file not found');
end

if ~exist(opt.logdir, 'dir')
    status = mkdir(opt.logdir);
    if ~status
        error('Could not create log directory');
    end
end

% import data
pop_editoptions( 'option_storedisk', 1);
[STUDY, ALLEEG, dsname] = load_dataset(opt.bidspath, opt.outputdir);

if opt.verbose
    disp('Check channel location after importing\n');
    ALLEEG(1).chanlocs(1)
end

options = {};
try
    % % remove non-ALLEEG channels (it is also possible to process ALLEEG data with non-ALLEEG data
    % get non-EEG channels
    % keep only EEG channels
    rm_chan_types = {'AUDIO','MEG','EOG','ECG','EMG','EYEGAZE','GSR','HEOG','MISC','PPG','PUPIL','REF','RESP','SYSCLOCK','TEMP','TRIG','VEOG'};
    if isfield(ALLEEG(1).chanlocs, 'type')
        types = {ALLEEG(1).chanlocs.type};
        ALLEEG = pop_select(ALLEEG, 'rmchantype', rm_chan_types);
        eeg_indices = strmatch('EEG', types)';
        if size(eeg_indices,2) == 1 && size(eeg_indices,1) > 1
            eeg_indices = eeg_indices';
        end
        if ~isempty(eeg_indices)
            ALLEEG = pop_select(ALLEEG, 'channel', eeg_indices);
        else
            warning("No EEG channel type detected (for first EEG file). Keeping all channels");
        end
    else
        warning("Channel type not detected (for first EEG file)");
    end
    % ALLEEG = pop_select( ALLEEG,'nochannel',{'VEOG', 'Misc', 'ECG', 'M2'});

    if isfield(ALLEEG(1).chanlocs, 'theta')
        thetas = [ALLEEG(1).chanlocs.theta];
        if isempty(thetas)
            warning("No channel locations detected (for first EEG file)");
        end
    end

    % % compute average reference
    options = {[]};
    ALLEEG = pop_reref( ALLEEG,options{:});

    % clean data using the clean_rawdata plugin
    options = {'FlatlineCriterion',5,'ChannelCriterion',0.85, ...
        'LineNoiseCriterion',4,'Highpass',[0.75 1.25] ,'BurstCriterion',20, ...
        'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian', ...
        'WindowCriterionTolerances',[-Inf 7] ,'fusechanrej',1};
    % ALLEEG = parexec(ALLEEG, 'pop_clean_rawdata', opt.logdir, options{:});
    ALLEEG = pop_clean_rawdata( ALLEEG, options{:});
    save_datasets(ALLEEG)

    % recompute average reference interpolating missing channels (and removing
    % them again after average reference - STUDY functions handle them automatically)
    options = {[], 'interpchan', []}
    ALLEEG = pop_reref( ALLEEG,options{:});
    save_datasets(ALLEEG)

    % run ICA reducing the dimention by 1 to account for average reference 
    nChans = [ ALLEEG.nbchan ];
    lrate = 0.00065/log(mean(nChans))/10;
    options = {'icatype','runica','concatcond','on','options',{'pca',-1, 'extended', 'on', 'lrate', lrate, 'maxsteps', 2000}};
    % ALLEEG = parexec(ALLEEG, 'pop_runica', opt.logdir, options{:});
    ALLEEG = pop_runica(ALLEEG, options{:});
    save_datasets(ALLEEG)

    % % run ICLabel and flag artifactual components
    options = {'default'};
    ALLEEG = pop_iclabel(ALLEEG, options{:});
    options = {[NaN NaN;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]};
    ALLEEG = pop_icflag( ALLEEG, options{:});
    save_datasets(ALLEEG)

    fid = fopen(fullfile(fileparts(opt.logdir), 'pipeline_status.tsv'), 'a');
    fprintf(fid, '%s\t%d\n', dsnumber, 1);
    fclose(fid);
    % pop_editoptions( 'option_storedisk', 1); % only one dataset at a time
catch ME
    save(sprintf('%s/ALLEEG_%s_%s.mat', opt.logdir, ME.identifier, char(datetime('now','TimeZone','local','Format','d-MMM-y-HHmmss'))), 'ALLEEG');
    save(sprintf('%s/options_%s_%s.mat', opt.logdir, ME.identifier, char(datetime('now','TimeZone','local','Format','d-MMM-y-HHmmss'))), 'options');
    fid = fopen(fullfile(fileparts(opt.logdir), 'pipeline_status.tsv'), 'a');
    fprintf(fid, '%s\t%d', dsnumber, 0);
    fclose(fid);
    error('%s\n%s',ME.identifier, ME.getReport());
end
function save_datasets(ALLEEG)
    for i=1:numel(ALLEEG)
        pop_saveset(ALLEEG(i), 'filepath', ALLEEG(i).filepath, 'filename', ALLEEG(i).filename);
    end
end
end

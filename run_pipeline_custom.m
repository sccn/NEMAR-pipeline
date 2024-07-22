function run_pipeline_custom(dsnumber, fcn_name, options, varargin)
nemar_path = '/expanse/projects/nemar/openneuro';
eeglabroot = '/expanse/projects/nemar/eeglab';

if isempty(which('finputcheck'))
    addpath(fullfile(eeglabroot,'eeglab'));
    addpath(fullfile(eeglabroot,'JSONio'));
    eeglab nogui;
end

opt = finputcheck(varargin, { ...
    'bidspath'       'string'    {}    fullfile(nemar_path, 'processed', dsnumber);  ...
    'eeglabroot'     'string'    {}    eeglabroot; ...
    'outputdir'      'string'    { }   fullfile(pwd, dsnumber); ...
    'logdir'         'string'    {}    fullfile(pwd, dsnumber, 'logs'); ...
    'preprocess'     'boolean'   {}    true; ...
    'parallel'       'boolean'   {}    true; ...
    'maxparpool'     'integer'   {}    128; ...
    'verbose'        'boolean'   {}    true; ...
    }, 'run_pipeline');
if isstr(opt), error(opt); end
addpath('./JSONio');
% reload eeglab if different version specified
if ~strcmp(eeglabroot, opt.eeglabroot)
    addpath(opt.eeglabroot);
    eeglab nogui;
    if opt.verbose
	which pop_importbids;
    end
end

% create output directories
if opt.verbose
    fprintf('Output dir: %s\n', opt.outputdir);
end
if exist(opt.outputdir, 'dir')
    rmdir(opt.outputdir, 's');
end
status = mkdir(opt.outputdir);
if ~status
    error('Could not create output directory');
else
    disp("Output directory created");
end

eeg_logdir = fullfile(opt.logdir, 'eeg_logs');
log_file = fullfile(opt.logdir, [fcn_name '_matlab_log']);
if opt.verbose
    fprintf('Log dir: %s\n', opt.logdir);
end
if exist(opt.logdir, 'dir')
    rmdir(opt.logdir, 's')
end
status = mkdir(opt.logdir);
if ~status
    error('Could not create log directory');
end
mkdir(fullfile(opt.logdir, 'debug'));
mkdir(fullfile(opt.logdir, 'eeg_logs'));

% enable logging to file
if exist(log_file, 'file')
    delete(log_file)
end
diary(log_file);

% load dataset
status_file = fullfile(opt.logdir, 'pipeline_status.csv');
pop_editoptions( 'option_storedisk', 1);
studyFile = fullfile(opt.bidspath, [dsname '.study']);
if ~exist(studyFile, 'file')
    [STUDY, ALLEEG] = pop_loadstudy(studyFile);
end

% run pipeline
if opt.parallel
    p = gcp('nocreate');
    if isempty(p)
        parpool([1 opt.maxparpool]); % debug 1, compute 128 per node
    end
end

options = [options 'outputdir' opt.outputdir 'eeg_logdir' eeg_logdir];
if opt.parallel
    parfor i=1:numel(ALLEEG)
        EEG = pop_loadset('filepath', ALLEEG(i).filepath, 'filename', ALLEEG(i).filename);
        [EEGout, eeg_status(i,:)] = feval(fcn_name, EEG, options{:});
    end
    save(fullfile(opt.logdir, 'eeg_status.mat'), 'eeg_status');
else
    for i=1:numel(ALLEEG)
        EEG = pop_loadset('filepath', ALLEEG(i).filepath, 'filename', ALLEEG(i).filename);
        [EEGout, eeg_status(i,:)] = feval(fcn_name, EEG, options{:});
    end
    save(fullfile(opt.logdir, 'eeg_status.mat'), 'eeg_status');
end

% generate summary status report
disp('Generating status report tables');
eeg_status_file = fullfile(opt.logdir, 'eeg_status.mat');
if exist(eeg_status_file)
    load(eeg_status_file);
end

status_cols = ["dsnumber", fcn_name];
col_types = repelem("string", numel(status_cols)); % account for dsnumber column
status_tbl = table('Size', [0 numel(status_cols)], 'VariableTypes', col_types, 'VariableNames', status_cols);
vals = {dsnumber, "1"}; % if reached here, dataset was imported successfully
vals = [vals, arrayfun(@(i) sprintf("%d/%d", sum(preproc_status(:,i)), numel(ALLEEG)), 1:size(preproc_status,2), 'UniformOutput', false)];
status_tbl = [status_tbl; vals];
writetable(status_tbl, status_file);

set_status_file = fullfile(opt.logdir, 'ind_pipeline_status.csv');
set_files = {ALLEEG.filename}; 
set_files = reshape(set_files, [numel(ALLEEG),1]);
set_status = [set_files num2cell(eeg_status)];
set_status_headers = [{'set_file'} pipeline plots {'dataqual'}];
set_status_tbl = cell2table(set_status, 'VariableNames', set_status_headers);
writetable(set_status_tbl, set_status_file);
set_status_with_headers = [set_status_headers; set_status];
save(fullfile(opt.logdir, 'set_status.mat'), 'set_status_with_headers');

diary off

function create_status_table(status_file, columns, status_values)
    status_cols = ["dsnumber", columns{:}];
    col_types = repelem("string", numel(status_cols)); % account for dsnumber column
    status_tbl = table('Size', [0 numel(status_cols)], 'VariableTypes', col_types, 'VariableNames', status_cols);
    vals = {dsnumber}; 
    vals = [vals, arrayfun(@(i) sprintf("%d/%d", sum(status_values(:,i)), size(status_values,1)), 1:size(status_values,2), 'UniformOutput', false)];
    status_tbl = [status_tbl; vals];
    writetable(status_tbl, status_file);
end
end
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
    'logdir'         'string'    {}    fullfile(nemar_path, 'processed', dsnumber, 'logs'); ...
    'outputdir'      'string'    { }   fullfile(nemar_path, 'processed', dsnumber); ...
    'debug'          'struct'    {}    struct([]);    ... % if not empty, provide the ALLEEG array to debug on
    'pipeline'       'cell'      {}    {};    ...
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


if ~exist(opt.logdir, 'dir')
    status = mkdir(opt.logdir);
    if ~status
        error('Could not create log directory');
    end
    mkdir(fullfile(opt.logdir, 'debug'));
end
status_file = fullfile(opt.logdir, 'pipeline_status.csv');
% enable logging to file
log_file = fullfile(opt.logdir, 'matlab_log');
if exist(log_file, 'file')
    delete(log_file)
end
diary(log_file);

if isempty(opt.debug)
    if ~exist(fullfile(opt.bidspath,'dataset_description.json'), 'file')
        error('Dataset description file not found');
    end
    % import data
    pop_editoptions( 'option_storedisk', 1);
    [STUDY, ALLEEG, dsname] = load_dataset(opt.bidspath, opt.outputdir);
else
    ALLEEG = opt.debug;
end

if opt.verbose
    disp('Check channel location after importing\n');
    ALLEEG(1).chanlocs(1)
end

if isempty(opt.pipeline)
    pipeline = {'remove_chan', 'cleanraw', 'avg_ref', 'runica', 'iclabel'};
else
    pipeline = opt.pipeline;
end
status = zeros(numel(ALLEEG), numel(pipeline));
parfor i=1:numel(ALLEEG)
    EEG = pop_loadset('filepath', ALLEEG(i).filepath, 'filename', ALLEEG(i).filename);
    [~, status(i,:)] = eeg_nemar_preprocess(EEG, i, pipeline, opt.logdir);
end

status_cols = ["dsnumber", pipeline];
col_types = repelem("string", numel(status_cols));
status_tbl = table('Size', [0 numel(status_cols)], 'VariableTypes', col_types, 'VariableNames', status_cols);
vals = [{dsnumber}, arrayfun(@(i) sprintf("%d/%d", sum(status(i), 1), numel(ALLEEG)), 1:size(status,2), 'UniformOutput', false)];
status_tbl = [status_tbl; vals];
writetable(status_tbl, status_file);

fid = fopen(fullfile(opt.logdir, 'error_files.txt'),'w');
for i=1:size(status,1)
    if sum(status(i,:)) == 0
        fprintf(fid, '%s\n', fullfile(ALLEEG(i).filepath, ALLEEG(i).filename));
    end
end
fclose(fid);
diary off

end
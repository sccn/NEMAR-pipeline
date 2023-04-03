function run_pipeline(dsnumber, varargin)
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
    'outputdir'      'string'    { }   fullfile(nemar_path, 'processed', dsnumber); ...
    'logdir'         'string'    {}    fullfile(nemar_path, 'processed', dsnumber, 'logs'); ...
    'modeval'        'string'    {'import', 'rerun'}    'import'; ... % if import mode, pipeline will overwrite existing outputdir. rerun won't 
    'preprocess'     'boolean'   {}    true; ...
    'vis'            'boolean'   {}    true; ...
    'dataqual'       'boolean'   {}    true; ...
    'verbose'        'boolean'   {}    true; ...
    }, 'run_pipeline');
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

eeg_logdir = fullfile(opt.logdir, 'eeg_logs');
log_file = fullfile(opt.logdir, 'matlab_log');
codeDir = fullfile(opt.logdir, "code");
if strcmp(opt.modeval, "import")
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

    % create log dirs
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

    if opt.verbose
        disp("Creating code dir and copying pipeline code");
    end

    mkdir(codeDir)
    copyfile(fullfile(eeglabroot, 'load_eeglab.m'), codeDir);
    copyfile(fullfile(eeglabroot, 'load_dataset.m'), codeDir);
    copyfile(fullfile(eeglabroot, 'run_pipeline.m'), codeDir);
    copyfile(fullfile(eeglabroot, 'eeg_nemar_preprocess.m'), codeDir);
    copyfile(fullfile(eeglabroot, 'eeg_nemar_vis.m'), codeDir);
    copyfile(fullfile(eeglabroot, 'generate_report.m'), codeDir);
    % copyfile(fullfile('/expanse/projects/nemar/openneuro/processed/logs', [dsnumber 'sbatch']), codeDir);

    % import data
    if ~exist(fullfile(opt.bidspath,'dataset_description.json'), 'file')
        error('Dataset description file not found');
    end
end

% set up pipeline sequence and report
status_file = fullfile(opt.logdir, 'pipeline_status.csv');
pipeline = {'remove_chan', 'cleanraw', 'avg_ref', 'runica', 'iclabel'};
plots = {'midraw', 'spectra', 'icaact', 'icmap'};
if strcmp(opt.modeval, 'import')
    % if rerun, it's assumed import was already successful
    preproc_status = zeros(numel(ALLEEG), numel(pipeline));
    vis_status = zeros(numel(ALLEEG), numel(plots));
    dataqual_status = zeros(numel(ALLEEG), 1);
    create_status_table(status_file, "0", [pipeline plots "dataqual"], [preproc_status vis_status dataqual_status]);
end

pop_editoptions( 'option_storedisk', 1);
[STUDY, ALLEEG, dsname] = load_dataset(opt.bidspath, opt.outputdir, opt.modeval);

% if reached here, import was successful. Rewrite report table
if strcmp(opt.modeval, 'import')
    create_status_table(status_file, "1", [pipeline plots "dataqual"], [preproc_status vis_status dataqual_status]);
end

if opt.verbose
    disp('Check channel location after importing\n');
    ALLEEG(1).chanlocs(1)
end

% run pipeline
p = gcp('nocreate');
if isempty(p)
    parpool([1 128]); % debug 1, compute 128 per node
end
% preprocessing
if opt.preprocess
    parfor i=1:numel(ALLEEG)
        EEG = pop_loadset('filepath', ALLEEG(i).filepath, 'filename', ALLEEG(i).filename);
        [~, preproc_status(i,:)] = eeg_nemar_preprocess(EEG, pipeline, eeg_logdir);
    end
    save(fullfile(opt.logdir, 'preproc_status.mat'), 'preproc_status');
end

% visualization
if opt.vis
    parfor i=1:numel(ALLEEG)
        EEG = pop_loadset('filepath', ALLEEG(i).filepath, 'filename', ALLEEG(i).filename);
        [~, vis_status(i,:)] = eeg_nemar_vis(EEG, plots, eeg_logdir);
    end
    save(fullfile(opt.logdir, 'vis_status.mat'), 'vis_status');
end

% data quality
if opt.dataqual
    dataqual_status = generate_report(ALLEEG, opt.outputdir, eeg_logdir);
    save(fullfile(opt.logdir, 'dataqual_status.mat'), 'dataqual_status');
end

% generate summary status report
disp('Generating status report tables');
preproc_file = fullfile(opt.logdir, 'preproc_status.mat');
if exist(preproc_file)
    load(preproc_file);
end
vis_file = fullfile(opt.logdir, 'vis_status.mat');
if exist(vis_file)
    load(vis_file);
end
dataqual_file = fullfile(opt.logdir, 'dataqual_status.mat');
if exist(dataqual_file)
    load(dataqual_file);
end
status_cols = ["dsnumber", "imported", pipeline, plots, "dataqual"];
col_types = repelem("string", numel(status_cols)); % account for dsnumber column
status_tbl = table('Size', [0 numel(status_cols)], 'VariableTypes', col_types, 'VariableNames', status_cols);
vals = {dsnumber, "1"}; % if reached here, dataset was imported successfully
vals = [vals, arrayfun(@(i) sprintf("%d/%d", sum(preproc_status(:,i)), numel(ALLEEG)), 1:size(preproc_status,2), 'UniformOutput', false)];
vals = [vals, arrayfun(@(i) sprintf("%d/%d", sum(vis_status(:,i)), numel(ALLEEG)), 1:size(vis_status,2), 'UniformOutput', false)];
vals = [vals, {sprintf("%d/%d", sum(dataqual_status), numel(ALLEEG))}];
status_tbl = [status_tbl; vals];
writetable(status_tbl, status_file);

set_status_file = fullfile(opt.logdir, 'ind_pipeline_status.csv');
set_files = {ALLEEG.filename}; 
set_files = reshape(set_files, [numel(ALLEEG),1]);
set_status = [set_files num2cell(preproc_status) num2cell(vis_status) num2cell(dataqual_status)];
set_status_headers = [{'set_file'} pipeline plots {'dataqual'}];
set_status_tbl = cell2table(set_status, 'VariableNames', set_status_headers);
writetable(set_status_tbl, set_status_file);
set_status_with_headers = [set_status_headers; set_status];
save(fullfile(opt.logdir, 'set_status.mat'), 'set_status_with_headers');

diary off

function create_status_table(status_file, import_status, columns, status_values)
    status_cols = ["dsnumber", "imported", columns{:}];
    col_types = repelem("string", numel(status_cols)); % account for dsnumber column
    status_tbl = table('Size', [0 numel(status_cols)], 'VariableTypes', col_types, 'VariableNames', status_cols);
    vals = {dsnumber, import_status}; 
    vals = [vals, arrayfun(@(i) sprintf("%d/%d", sum(status_values(:,i)), size(status_values,1)), 1:size(status_values,2), 'UniformOutput', false)];
    status_tbl = [status_tbl; vals];
    writetable(status_tbl, status_file);
end
end
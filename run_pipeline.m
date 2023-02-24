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
    'modeval'        'string'    {}    'import'; ...
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

% create output directories
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
if exist(opt.logdir, 'dir')
    rmdir(opt.logdir, 's')
end
status = mkdir(opt.logdir);
if ~status
    error('Could not create log directory');
end
mkdir(fullfile(opt.logdir, 'debug'));
mkdir(fullfile(opt.logdir, 'eeg_logs'));
eeg_logdir = fullfile(opt.logdir, 'eeg_logs');

% enable logging to file
log_file = fullfile(opt.logdir, 'matlab_log');
if exist(log_file, 'file')
    delete(log_file)
end
diary(log_file);

if opt.verbose
    disp("Creating code dir and copying pipeline code");
end
codeDir = fullfile(opt.logdir, "code");
mkdir(codeDir)
copyfile(fullfile(eeglabroot, 'load_eeglab.m'), codeDir);
copyfile(fullfile(eeglabroot, 'run_pipeline.m'), codeDir);
copyfile(fullfile(eeglabroot, 'eeg_nemar_preprocess.m'), codeDir);
copyfile(fullfile(eeglabroot, 'eeg_nemar_vis.m'), codeDir);
copyfile(fullfile(eeglabroot, 'generate_report.m'), codeDir);
copyfile(fullfile('/expanse/projects/nemar/openneuro/processed/logs', [dsnumber 'sbatch']), codeDir);

% import data
if ~exist(fullfile(opt.bidspath,'dataset_description.json'), 'file')
    error('Dataset description file not found');
end
pop_editoptions( 'option_storedisk', 1);
[STUDY, ALLEEG, dsname] = load_dataset(opt.bidspath, opt.outputdir, opt.modeval);

if opt.verbose
    disp('Check channel location after importing\n');
    ALLEEG(1).chanlocs(1)
end

parpool([1 128]); % debug 1, compute 128 per node
% preprocessing
pipeline = {'remove_chan', 'cleanraw', 'avg_ref', 'runica', 'iclabel'};
preproc_status = zeros(numel(ALLEEG), numel(pipeline));
if opt.preprocess
    parfor i=1:numel(ALLEEG)
        EEG = pop_loadset('filepath', ALLEEG(i).filepath, 'filename', ALLEEG(i).filename);
        [~, preproc_status(i,:)] = eeg_nemar_preprocess(EEG, pipeline, eeg_logdir);
    end
    save(fullfile(opt.logdir, 'preproc_status.mat'), 'preproc_status');
end

% visualization
plots = {'midraw', 'spectra', 'icaact', 'icmap'};
vis_status = zeros(numel(ALLEEG), numel(plots));
if opt.vis
    parfor i=1:numel(ALLEEG)
        EEG = pop_loadset('filepath', ALLEEG(i).filepath, 'filename', ALLEEG(i).filename);
        [~, vis_status(i,:)] = eeg_nemar_vis(EEG, plots, eeg_logdir);
    end
    save(fullfile(opt.logdir, 'vis_status.mat'), 'vis_status');
end

% data quality
dataqual_status = zeros(numel(ALLEEG), 1);
if opt.dataqual
    dataqual_status = generate_report(ALLEEG, opt, eeg_logdir);
    save(fullfile(opt.logdir, 'dataqual_status.mat'), 'dataqual_status');
end

% generate summary status report
disp('Generating status report');
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
status_file = fullfile(opt.logdir, 'pipeline_status.csv');
status_cols = ["dsnumber", "imported", pipeline, plots, "dataqual"];
col_types = repelem("string", numel(status_cols)); % account for dsnumber column
status_tbl = table('Size', [0 numel(status_cols)], 'VariableTypes', col_types, 'VariableNames', status_cols);
vals = {dsnumber, "1"}; % if reached here, dataset was imported successfully
vals = [vals, arrayfun(@(i) sprintf("%d/%d", sum(preproc_status(:,i)), numel(ALLEEG)), 1:size(preproc_status,2), 'UniformOutput', false)];
vals = [vals, arrayfun(@(i) sprintf("%d/%d", sum(vis_status(:,i)), numel(ALLEEG)), 1:size(vis_status,2), 'UniformOutput', false)];
vals = [vals, {sprintf("%d/%d", sum(dataqual_status), numel(ALLEEG))}];
status_tbl = [status_tbl; vals];
writetable(status_tbl, status_file);

fid = fopen(fullfile(opt.logdir, 'error_files.txt'),'w');
for i=1:numel(ALLEEG)
    if sum(preproc_status(i,:)) + sum(vis_status(i,:)) + dataqual_status(i) < numel(status_cols)-2 % ignore dsnumber and imported
        fprintf(fid, '%s\n', fullfile(ALLEEG(i).filepath, ALLEEG(i).filename));
    end
end
fclose(fid);
diary off

end
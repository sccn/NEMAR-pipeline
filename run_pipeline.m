function run_pipeline(dsnumber, varargin)
nemar_path = '/expanse/projects/nemar/openneuro';
eeglabroot = '/expanse/projects/nemar/dtyoung/NEMAR-pipeline';

if isempty(which('finputcheck'))
    addpath(fullfile(eeglabroot,'eeglab'));
    addpath(fullfile(eeglabroot,'JSONio'));
    eeglab nogui;
end

opt = finputcheck(varargin, { ...
    'bidspath'                'string'    {}                      fullfile(nemar_path, dsnumber);  ...
    'eeglabroot'              'string'    {}                      eeglabroot; ...
    'outputdir'               'string'    { }                     fullfile(nemar_path, 'processed', dsnumber); ...
    'logdir'                  'string'    {}                      fullfile(nemar_path, 'processed', dsnumber, 'logs'); ...
    'copycode'                'boolean'   {}                      true; ...
    'modeval'                 'string'    {'import', 'rerun'}    'import'; ...                                                      % if import mode, pipeline will overwrite existing outputdir. rerun won't 
    'preprocess'              'boolean'   {}                      true; ...
    'preprocess_pipeline'     'cell'      {}                      {'remove_chan', 'cleanraw', 'avg_ref', 'runica', 'iclabel'}; ...  % preprocessing steps
    'vis'                     'boolean'   {}                      true; ...
    'vis_plots'               'cell'      {}                      {'midraw', 'spectra', 'icaact', 'icmap'}; ...                     % visualization plots
    'dataqual'                'boolean'   {}                      true; ...
    'maxparpool'              'integer'   {}                      127; ...  % if 0, sequential processing
    'verbose'                 'boolean'   {}                      true; ...
    }, 'run_pipeline');
if isstr(opt), error(opt); end

opt
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

    % import data
    if ~exist(fullfile(opt.bidspath,'dataset_description.json'), 'file')
        error('Dataset description file not found');
    end
end

% save the latest version of the pipeline
if opt.copycode
    if opt.verbose
        disp("Creating code dir and copying pipeline code");
    end
    mkdir(codeDir)
    scripts = {'load_dataset.m', 'run_pipeline.m', 'eeg_nemar_preprocess.m', 'eeg_nemar_vis.m', 'generate_report.m'};
    for s=1:numel(scripts)
        script_src = fullfile(eeglabroot, scripts{s});
        script_dest = fullfile(codeDir, scripts{s});
        if exist(script_dest, 'file')
            delete(script_dest);
        end
        copyfile(script_src, script_dest);
    end
end

% set up pipeline sequence and report
status_file = fullfile(opt.logdir, 'pipeline_status.csv');
pipeline = opt.preprocess_pipeline;
plots = opt.vis_plots; 
if strcmp(opt.modeval, 'import')
    % if rerun, it's assumed import was already successful
    preproc_status = -1*ones(1, numel(pipeline));
    vis_status = -1*ones(1, numel(plots));
    dataqual_status = -1*ones(1, 1);
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
if opt.maxparpool > 0
    p = gcp('nocreate');
    if isempty(p)
        parpool([1 opt.maxparpool]); % debug 1, compute 128 per node
    end
end

% preprocessing
if opt.preprocess
    parfor (i=1:numel(ALLEEG), opt.maxparpool)
        EEG = pop_loadset('filepath', ALLEEG(i).filepath, 'filename', ALLEEG(i).filename);
        [~, preproc_status(i,:)] = eeg_nemar_preprocess(EEG, pipeline, eeg_logdir);
    end
    write_alleeg_status_table(ALLEEG, opt.modeval, fullfile(opt.logdir, 'preproc_status.mat'), pipeline, preproc_status);
end

% visualization
if opt.vis
    parfor (i=1:numel(ALLEEG), opt.maxparpool)
        EEG = pop_loadset('filepath', ALLEEG(i).filepath, 'filename', ALLEEG(i).filename);
        [~, vis_status(i,:)] = eeg_nemar_vis(EEG, plots, eeg_logdir);
    end
    write_alleeg_status_table(ALLEEG, opt.modeval, fullfile(opt.logdir, 'vis_status.mat'), plots, vis_status);
end

% data quality
if opt.dataqual
    dataqual_status = generate_report(ALLEEG, opt.outputdir, eeg_logdir);
    write_alleeg_status_table(ALLEEG, opt.modeval, fullfile(opt.logdir, 'dataqual_status.mat'), {'dataqual'}, dataqual_status);
end

% final step: generate summary status report
disp('Generating status report tables');
preproc_file = fullfile(opt.logdir, 'preproc_status.mat');
if exist(preproc_file, 'file')
    tbl = load(preproc_file);
    if isfield(tbl, 'status_tbl')
        tbl = tbl.status_tbl;
        preproc_status = table2array(tbl);
    end
else
    preproc_status = zeros(1, numel(pipeline));
end
vis_file = fullfile(opt.logdir, 'vis_status.mat');
if exist(vis_file, 'file')
    tbl = load(vis_file);
    if isfield(tbl, 'status_tbl')
        tbl = tbl.status_tbl;
        vis_status = table2array(tbl);
    end
else
    vis_status = zeros(1, numel(plots));
end
dataqual_file = fullfile(opt.logdir, 'dataqual_status.mat');
if exist(dataqual_file, 'file')
    tbl = load(dataqual_file);
    if isfield(tbl, 'status_tbl')
        tbl = tbl.status_tbl;
        dataqual_status = table2array(tbl);
    end
else
    dataqual_status = zeros(1, 1);
end
pipeline = {'remove_chan', 'cleanraw', 'avg_ref', 'runica', 'iclabel'};
plots = {'midraw', 'spectra', 'icaact', 'icmap'};
create_status_table(status_file, "1", [pipeline plots "dataqual"], [preproc_status vis_status dataqual_status]);

set_status_file = fullfile(opt.logdir, 'ind_pipeline_status.csv');
set_files = {ALLEEG.filename}; 
set_files = reshape(set_files, [numel(ALLEEG),1]);
set_status = [set_files num2cell(preproc_status) num2cell(vis_status) num2cell(dataqual_status)];
set_status_headers = [{'set_file'} pipeline plots {'dataqual'}];
set_status_tbl = cell2table(set_status, 'VariableNames', set_status_headers);
writetable(set_status_tbl, set_status_file);
set_status_with_headers = [set_status_headers; set_status];
save(fullfile(opt.logdir, 'set_status.mat'), 'set_status_with_headers');

disp('Finished running pipeline.');
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

    function status_tbl = write_alleeg_status_table(ALLEEG, mode, status_file, status_cols, values)
        % mode: if 'rerun', check if there's a current status table from status_file and only modify it. 
        %       if 'import' (anything else then 'rerun'), create new table and write to status_file
        if strcmp(mode, 'rerun')
            status_tbl = load(status_file);
            status_tbl = status_tbl.status_tbl;
            for c=1:numel(status_cols)
                col = status_cols{c};      
                for e=1:numel(ALLEEG)
                    status_tbl.(col)(e) = values(e,c);
                end
            end
            save(status_file, 'status_tbl');
        else
            status_tbl = array2table(values);
            status_tbl.Properties.VariableNames = status_cols;
            save(status_file, 'status_tbl');
        end
    end
end
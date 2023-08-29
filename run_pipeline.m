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
    'modeval'                 'string'    {'new', 'resume'}       'new'; ...                                                      % if new mode, pipeline will overwrite existing outputdir. resume won't 
    'preprocess'              'boolean'   {}                      true; ...
    'preprocess_pipeline'     'cell'      {}                      {'check_chanloc', 'remove_chan', 'cleanraw', 'avg_ref', 'runica', 'iclabel'}; ...  % preprocessing steps
    'vis'                     'boolean'   {}                      true; ...
    'vis_plots'               'cell'      {}                      {'midraw', 'spectra', 'icaact', 'icmap'}; ...                     % visualization plots
    'dataqual'                'boolean'   {}                      true; ...
    'maxparpool'              'integer'   {}                      0; ...                                                           % if 0, sequential processing
    'legacy'                  'boolean'   {}                      false; ...                                                           % if 0, sequential processing
    'run_local'               'boolean'   {}                      false; ...
    'subjects'                'integer'  []                      []; ... 
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
if strcmp(opt.modeval, "new")
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

% set up pipeline sequence
pipeline = opt.preprocess_pipeline;
plots = opt.vis_plots; 

pop_editoptions( 'option_storedisk', 0);
disp(opt.modeval)
[STUDY, ALLEEG, dsname] = load_dataset(opt.bidspath, opt.outputdir, opt.modeval, opt.subjects);

if opt.verbose
    disp('Check channel location after importing\n');
    ALLEEG(1).chanlocs(1)
end

sbatch_logpath = '/expanse/projects/nemar/openneuro/processed/logs';
fid = fopen(fullfile(sbatch_logpath, [dsnumber '_jobids.csv']), 'w');
for i=1:numel(ALLEEG)
    filepath = fullfile(ALLEEG(i).filepath, ALLEEG(i).filename);
    if opt.run_local
        eeg_run_pipeline(dsnumber, filepath, varargin{:});
    else
        jobid = eeg_create_and_submit_job(dsnumber, filepath, varargin{:});
        fprintf(fid, '%s,%s\n', filepath, jobid);
    end
end
fclose(fid);
diary off
end

function run_pipeline(dsnumber, varargin)
nemar_path = '/expanse/projects/nemar/openneuro';
eeglabroot = '/expanse/projects/nemar/eeglab';
pipelineroot = fullfile(eeglabroot, 'plugins', 'NEMAR-pipeline');
addpath(fullfile(pipelineroot,'JSONio'));
if isempty(which('finputcheck'))
    addpath(eeglabroot);
    eeglab nogui;
end

opt = finputcheck(varargin, { ...
    'bidspath'                'string'    {}                      fullfile(nemar_path, dsnumber);  ...
    'eeglabroot'              'string'    {}                      eeglabroot; ...
    'outputdir'               'string'    { }                     fullfile(nemar_path, 'processed', dsnumber); ...
    'logdir'                  'string'    {}                      fullfile(nemar_path, 'processed', dsnumber, 'logs'); ...
    'modeval'                 'string'    {'new', 'resume', 'rerun'}       'resume'; ...                                                      % if new mode, pipeline will overwrite existing outputdir. resume won't 
    'import_options'          'cell'      {}                      {}; ...
    'preprocess'              'boolean'   {}                      true; ...
    'preprocess_pipeline'     'cell'      {}                      {'check_import', 'check_chanloc', 'remove_chan', 'cleanraw', 'runica', 'iclabel'}; ...  % preprocessing steps
    'plugin'                  'boolean'   {}                      true; ...
    'plugin_specific'         'cell'      {}                      {}; ...               % plugins to specifically run      
    'dataqual'                'boolean'   {}                      true; ...
    'maxparpool'              'integer'   {}                      0; ...                                                           % if 0, sequential processing
    'memory'                  'integer'   {}                      32; ...               % batch job memory size for each datarun
    'legacy'                  'boolean'   {}                      false; ...                                                           % if 0, sequential processing
    'run_local'               'boolean'   {}                      false; ...
    'ctffunc'                 'string'    {}                      'fileio'; ...
    'subjects'                'integer'  []                      []; ... 
    'verbose'                 'boolean'   {}                      true; ...
    }, 'run_pipeline');
if isstr(opt), error(opt); end

opt
% reload eeglab if different version specified
if ~strcmp(eeglabroot, opt.eeglabroot)
    addpath(opt.eeglabroot);
    eeglab nogui;
    if opt.verbose
	which pop_importbids;
    end
end

eeg_logdir = fullfile(opt.logdir, 'eeg_logs');
log_file = fullfile(opt.logdir, 'matlab_log');
codeDir = fullfile(opt.outputdir, "code");
if strcmp(opt.modeval, "new")
    % create output directories
    if opt.verbose
        fprintf('Output dir: %s\n', opt.outputdir);
    end
    if exist(opt.outputdir, 'dir')
	if exist(codeDir, 'dir') && exist(fullfile(codeDir, 'nemar.json'))
	    if ~exist(fullfile(pipelineroot, 'temp-nemar-json'), 'dir')
		mkdir(fullfile(pipelineroot, 'temp-nemar-json'));
	    end
	    [status, msg] = copyfile(fullfile(codeDir, 'nemar.json'), fullfile(pipelineroot, 'temp-nemar-json', [dsnumber '_nemar.json']))
	    if status ~= 1
		error('Error backing up nemar.json file');
	    end
	end
        rmdir(opt.outputdir, 's');
    end
    status = mkdir(opt.outputdir);
    if ~status
        error('Could not create output directory');
    else
	status = copyfile(fullfile(pipelineroot, 'temp-nemar-json', [dsnumber '_nemar.json'], fullfile(codeDir, 'nemar.json')));
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
    if exist(log_file)
        delete(log_file)
    end

    % import data
    if ~exist(fullfile(opt.bidspath,'dataset_description.json'), 'file')
        error('Dataset description file not found');
    end
end

diary(log_file);
fprintf('Pipeline run on %s\n', string(datetime('today')));
% set up pipeline sequence
pipeline = opt.preprocess_pipeline;

pop_editoptions( 'option_storedisk', 1);
[STUDY, ALLEEG, dsname] = load_dataset(opt.bidspath, opt.outputdir, opt.modeval, opt.subjects, opt.ctffunc, opt.import_options{:});

if opt.verbose
    disp('Check channel location after importing\n');
    ALLEEG(1).chanlocs(1)
end

% filter out varargin that don't apply to eeg_run_pipeline
eeg_run_params = {'eeglabroot', 'logdir', 'resave', 'modeval', 'preprocess', 'preprocess_pipeline', ...
                    'plugin', 'plugin_specific', 'dataqua', 'maxparpool', 'legacy', 'verbose'};
eeg_run_varargin = {};
for p=1:2:numel(varargin)
    if contains(varargin{p}, eeg_run_params)
        eeg_run_varargin = [eeg_run_varargin varargin{p} varargin{p+1}];
    end
end
sbatch_logpath = '/expanse/projects/nemar/openneuro/processed/logs';
fid = fopen(fullfile(sbatch_logpath, [dsnumber '_jobids.csv']), 'w');
for i=1:numel(ALLEEG)
    filepath = fullfile(ALLEEG(i).filepath, ALLEEG(i).filename);
    if opt.run_local
        eeg_run_pipeline(dsnumber, filepath, eeg_run_varargin{:});
    else
        jobid = eeg_create_and_submit_job(dsnumber, filepath, opt.memory, eeg_run_varargin{:});
        fprintf(fid, '%s,%s\n', filepath, jobid);
    end
end

fclose(fid);
diary off
end

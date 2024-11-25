function run_pipeline(dsnumber, varargin)
    nemar_path = '/expanse/projects/nemar/openneuro';
    eeglabroot = '/expanse/projects/nemar/eeglab';
    pipelineroot = fullfile(eeglabroot, 'plugins', 'NEMAR-pipeline');
    sbatch_logpath = '/expanse/projects/nemar/openneuro/processed/logs';
    nemar_json_backup_path = '/expanse/projects/nemar/openneuro/processed/nemar_json_backup';
    addpath(pipelineroot);
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
        'preprocess_pipeline'     'cell'      {}                      {'check_import', 'check_chanloc', 'cleanraw', 'runica', 'iclabel'}; ...  % preprocessing steps
        'plugin'                  'boolean'   {}                      true; ...
        'plugin_specific'         'cell'      {}                      {}; ...               % plugins to specifically run      
        'dataqual'                'boolean'   {}                      true; ...
        'maxparpool'              'integer'   {}                      0; ...                                                           % if 0, sequential processing
        'memory'                  'integer'   {}                      16; ...               % batch job memory size for each datarun
        'legacy'                  'boolean'   {}                      false; ...                                                           % if 0, sequential processing
        'run_local'               'boolean'   {}                      false; ...
        'ctffunc'                 'string'    {}                      'fileio'; ...
        'subjects'                'integer'  []                      []; ... 
        'mergeset'                'boolean'  []                       false; ... 
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
    
    if opt.verbose
        disp('Saving nemar.json file');
    end
    if exist(codeDir, 'dir') && exist(fullfile(codeDir, 'nemar.json'))
        if ~exist(nemar_json_backup_path, 'dir')
            mkdir(nemar_json_backup_path);
        end
        [status, msg] = copyfile(fullfile(codeDir, 'nemar.json'), fullfile(nemar_json_backup_path, [dsnumber '_nemar.json']));
        if status ~= 1
            error('Error backing up nemar.json file');
        end
    end
    if strcmp(opt.modeval, "new")
        % create output directories
        if opt.verbose
            fprintf('Output dir: %s\n', opt.outputdir);
        end
        if exist(opt.outputdir, 'dir')
            fprintf('Fresh run but output dir exists. Deleting...\n');
            if exist(codeDir, 'dir') && exist(fullfile(codeDir, 'nemar.json'))
                % if ~exist(fullfile(pipelineroot, 'temp-nemar-json'), 'dir')
                % mkdir(fullfile(pipelineroot, 'temp-nemar-json'));
                % end
                [status, msg] = copyfile(fullfile(codeDir, 'nemar.json'), fullfile(nemar_json_backup_path, [dsnumber '_nemar.json']))
                if status ~= 1
                    error('Error backing up nemar.json file. Aborted.');
                end
            end
            status = rmdir(opt.outputdir, 's');
            if status ~= 1
                error('Error deleting output directory. Aborted.');
            end
        end
        status = mkdir(opt.outputdir);
        if ~status
            error('Could not create output directory');
        else
            status = mkdir(codeDir)
            if ~status
                error('Could not create %s directory', codeDir);
            else
                fprintf('%s created\n', codeDir)
            end
            if exist(fullfile(nemar_json_backup_path, [dsnumber '_nemar.json']), 'file')
                [status, msg] = copyfile(fullfile(nemar_json_backup_path, [dsnumber '_nemar.json']), fullfile(codeDir, 'nemar.json'));
                if ~status
                    error('Could not restore nemar.json file');
                else
                    disp("Output directory created");
                end
            end
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

    % check for custom code of this dataset
    check_dataset_custom_code(dsnumber);
    
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
            eeg_run_varargin = [eeg_run_varargin varargin(p) varargin(p+1)]
        end
    end
    if ~opt.run_local
        fid = fopen(fullfile(sbatch_logpath, [dsnumber '_jobids.csv']), 'w');
    end
    if opt.mergeset
        subject = ALLEEG(1).subject
        EEG = pop_loadset('filename',ALLEEG(1).filename, 'filepath',ALLEEG(1).filepath);
        for i=2:numel(ALLEEG)
            if ~strcmp(ALLEEG(i).subject, subject)
                % save concatenated dataset
                filename = regexp(ALLEEG(i-1).filename, 'sub-([a-zA-Z0-9]+)', 'match');
                filename = [filename{1} '_task-combined_eeg.set'];
                filepath = ALLEEG(i-1).filepath;

                pop_saveset(EEG, 'filename', filename, 'filepath', filepath);
                subject = EEG.subject
                EEG = pop_loadset(ALLEEG(i).filename, ALLEEG(i).filepath)
                if opt.run_local
                    eeg_run_pipeline(dsnumber, fullfile(filepath, filename), eeg_run_varargin{:});
                else
                    jobid = eeg_create_and_submit_job(dsnumber, fullfile(filepath, filename), opt.memory, eeg_run_varargin{:});
                    fprintf(fid, '%s,%s\n', filepath, jobid);
                end
                
            else
                EEG = pop_mergeset(EEG, pop_loadset('filename',ALLEEG(i).filename, 'filepath',ALLEEG(i).filepath));
            end
        end

        % last subject
        filename = regexp(ALLEEG(i-1).filename, 'sub-([a-zA-Z0-9]+)', 'match');
        filename = [filename{1} '_task-combined_eeg.set'];
        filepath = ALLEEG(i-1).filepath;

        EEG = pop_saveset(EEG, 'filename', filename, 'filepath', filepath, 'savemode', 'onefile');
        if opt.run_local
            eeg_run_pipeline(dsnumber, fullfile(filepath, filename), eeg_run_varargin{:});
        else
            jobid = eeg_create_and_submit_job(dsnumber, fullfile(filepath, filename), opt.memory, eeg_run_varargin{:});
            fprintf(fid, '%s,%s\n', filepath, jobid);
        end
    else
        for i=1:numel(ALLEEG)
            if opt.run_local
                eeg_run_pipeline(dsnumber, fullfile(ALLEEG(i).filepath, ALLEEG(i).filename), eeg_run_varargin{:});
            else
                jobid = eeg_create_and_submit_job(dsnumber, fullfile(ALLEEG(i).filepath, ALLEEG(i).filename), opt.memory, eeg_run_varargin{:});
                fprintf(fid, '%s,%s\n', ALLEEG(i).filepath, jobid);
            end
        end
    end
    fclose(fid);

    if ~opt.run_local
        job_ids = readtable(fullfile(sbatch_logpath, [dsnumber '_jobids.csv']), 'Delimiter', 'comma');
        % get job ids from the second column
        job_ids = job_ids{:,2};
        % wait for all jobs to finish
        finished = false;
        while ~finished
            fprintf('Checking job status in PST timezone\n');
            datetime('now','TimeZone','America/Los_Angeles', 'Format','d-MMM-y HH:mm:ss Z')
            finished = true;
            for j=1:numel(job_ids)
                if isnumeric(job_ids)
                    job = job_ids(j);
                else
                    job = str2num(job_ids{j});
                end
                [status, result] = system(sprintf('squeue --job %d', job));
                if status == 0
                    finished = false;
                    break;
                end
            end
            if ~finished
                pause(600); % wait for 10 minutes before checking again
            end
        end
    end % if running on slurm and reach here, all processing jobs should have finished already

    % run dataset-level report after all individual recording processing finish
    if opt.dataqual
        fprintf('Running data quality check\n');
        nemar_dataqual(dsnumber, STUDY, ALLEEG);
    end
    eeg_logdir = fullfile(opt.logdir, 'eeg_logs');
    study_status_tbl = [];
    for i=1:numel(ALLEEG)
        filename = ALLEEG(i).filename;
        [~, filename, ext] = fileparts(filename);
        eeg_status_file = fullfile(eeg_logdir, [filename '_status_all.csv']);
        if exist(status_file, 'file')
            eeg_status_tbl = readtable(eeg_status_file);
            if isempty(study_status_tbl)
                study_status_tbl = eeg_status_tbl;
            else
                study_status_tbl = outerjoin(study_status_tbl,eeg_status_tbl,'MergeKeys',true);
            end
        end
    end
    STUDY.etc.nemar_pipeline_status = study_status_tbl;
    study_status_file = fullfile(opt.logdir, 'ind_pipeline_status_all.csv');
    writetable(study_status_tbl, study_status_file);

    diary off
    end
    
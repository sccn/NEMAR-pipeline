function eeg_run_pipeline(dsnumber, filepath, varargin)
    nemar_path = '/expanse/projects/nemar/openneuro';
    eeglabroot = '/expanse/projects/nemar/eeglab';
    pipelineroot = fullfile(eeglabroot,'plugins', 'NEMAR-pipeline');
    addpath(fullfile(pipelineroot,'JSONio'));

    % add path to custom code if exists
    check_dataset_custom_code(dsnumber);

    if isempty(which('finputcheck'))
        addpath(eeglabroot);
        eeglab nogui;
    end

    opt = finputcheck(varargin, { ...
        'eeglabroot'              'string'    {}                      eeglabroot; ...
        'logdir'                  'string'    {}                      fullfile(nemar_path, 'processed', dsnumber, 'logs'); ...
        'resave'                  'boolean'   {}                      true; ...
        'modeval'                 'string'    {'new', 'resume', 'rerun'}       'resume'; ...                                                      % if new mode, pipeline will overwrite existing outputdir. resume won't 
        'preprocess'              'boolean'   {}                      true; ...
        'preprocess_pipeline'     'cell'      {}                      {'check_import', 'check_chanloc', 'cleanraw', 'avg_ref', 'runica', 'iclabel'}; ...  % preprocessing steps
        'plugin'                  'boolean'   {}                      true; ...
        'plugin_specific'          'cell'      {}                      {}; ...                     % plugins to specifically run
        'dataqual'                'boolean'   {}                      true; ...
        'maxparpool'              'integer'   {}                      0; ...                                                           % if 0, sequential processing
        'legacy'                  'boolean'   {}                      false; ...                                                           % if 0, sequential processing
        'verbose'                 'boolean'   {}                      true; ...
        }, 'eeg_run_pipeline');
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

    % load data run
    EEG = pop_loadset(filepath)
    [~, filename, ext] = fileparts(EEG.filename);
    
    eeg_logdir = fullfile(opt.logdir, 'eeg_logs');
    log_file = fullfile(eeg_logdir, filename);
    if exist(log_file, 'file')
        delete(log_file)
    end
    
    diary(log_file);
    
    pipeline = opt.preprocess_pipeline;
    
    % run pipeline
    if opt.maxparpool > 0
        p = gcp('nocreate');
        if isempty(p)
            parpool([1 opt.maxparpool]); % debug 1, compute 128 per node
        end
    end
    
    % preprocessing
    if opt.preprocess
        [EEG, ~] = eeg_nemar_preprocess(EEG, 'pipeline', pipeline, 'logdir', eeg_logdir, 'modeval', opt.modeval, 'resave', opt.resave);
    end
    
    % data quality
    if opt.dataqual
        [EEG, ~] = eeg_nemar_dataqual(EEG, 'logdir', eeg_logdir, 'legacy', opt.legacy);
    end
    
    % plugins (including visualization)
    if opt.plugin
        EEG = eeg_nemar_plugin(EEG, 'logdir', eeg_logdir, 'specific', opt.plugin_specific);
    end
    
    % save status of pipeline
    if opt.resave
        pop_saveset(EEG, 'filepath', EEG.filepath, 'filename', EEG.filename, 'savemode', 'onefile');
    end
    status_file = fullfile(eeg_logdir, [filename '_status_all.csv']);
    if exist(status_file, 'file')
        delete(status_file)
    end
    writetable(EEG.etc.nemar_pipeline_status, status_file);

    disp('Finished running pipeline on EEG.');
    diary off
    end
    
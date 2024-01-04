function eeg_run_pipeline(dsnumber, filepath, varargin)
    nemar_path = '/expanse/projects/nemar/openneuro';
    eeglabroot = '/expanse/projects/nemar/eeglab';
    pipelineroot = fullfile(eeglabroot,'plugins', 'NEMAR-pipeline');
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
        'resave'                  'boolean'   {}                      true; ...
        'modeval'                 'string'    {'new', 'resume'}       'new'; ...                                                      % if new mode, pipeline will overwrite existing outputdir. resume won't 
        'preprocess'              'boolean'   {}                      true; ...
        'preprocess_pipeline'     'cell'      {}                      {'check_import', 'check_chanloc', 'remove_chan', 'cleanraw', 'avg_ref', 'runica', 'iclabel'}; ...  % preprocessing steps
        'vis'                     'boolean'   {}                      true; ...
        'vis_plots'               'cell'      {}                      {'midraw', 'spectra', 'icaact', 'icmap', 'icahist'}; ...                     % visualization plots
        'dataqual'                'boolean'   {}                      true; ...
        'maxparpool'              'integer'   {}                      0; ...                                                           % if 0, sequential processing
        'legacy'                  'boolean'   {}                      false; ...                                                           % if 0, sequential processing
        'verbose'                 'boolean'   {}                      true; ...
        'subjects'                'integer'   []                      []; ....
        'ctffunc'                 ''          []                      []; ....
        'run_local'               'boolean'   {}                      false; ...
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
    EEG = pop_loadset(filepath);
    [~, filename, ext] = fileparts(EEG.filename);
    
    eeg_logdir = fullfile(opt.logdir, 'eeg_logs');
    log_file = fullfile(eeg_logdir, filename);
    if exist(log_file, 'file')
        delete(log_file)
    end
    
    diary(log_file);
    
    pipeline = opt.preprocess_pipeline;
    plots = opt.vis_plots; 
    
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
    
    % visualization
    if opt.vis
        [EEG, ~] = eeg_nemar_vis(EEG, 'plots', plots, 'logdir', eeg_logdir, 'legacy', opt.legacy);
    end
    
    % data quality
    if opt.dataqual
        eeg_nemar_dataqual(EEG, 'logdir', eeg_logdir, 'legacy', opt.legacy);
    end
    
    disp('Finished running pipeline on EEG.');
    diary off
    end
    
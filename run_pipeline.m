function run_pipeline(dsnumber)
    nemar_path = '/expanse/projects/nemar/openneuro';
    eeglabroot = '/expanse/projects/nemar/dtyoung/NEMAR-pipeline';
    bidspath = fullfile(nemar_path, dsnumber);
    logdir = fullfile(nemar_path, 'processed', 'logs', dsnumber);
    outputdir = fullfile(nemar_path, 'processed', dsnumber);

    addpath(fullfile(eeglabroot,'eeglab'));
    addpath(fullfile(eeglabroot,'JSONio'));
    eeglab nogui;

    varargin = {'bidspath', bidspath, 'eeglabroot', eeglabroot, 'logdir', logdir, 'outputdir', outputdir, 'verbose', true};

    bids_preprocess(dsnumber, varargin{:});
    generate_vis(dsnumber, varargin{:});
    generate_report(dsnumber, varargin{:});

    % we want each part of the pipeline is runnable on its own
    % and we also want to trigger all of them sequentially in the main pipeline
end

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
        'logdir'         'string'    {}    fullfile(nemar_path, 'processed', dsnumber, 'logs'); ...
        'outputdir'      'string'    { }   fullfile(nemar_path, 'processed', dsnumber); ...
        'verbose'        'boolean'   {}    true; ...
        }, 'run_pipeline');
    if isstr(opt), error(opt); end

    if opt.verbose
        disp("");
        fprintf("EEGLAB root: %s\n", opt.eeglabroot);
        fprintf("Input BIDS dir: %s\n", opt.bidspath);
        fprintf("Output BIDS dir: %s\n", opt.outputdir);
        fprintf("Log dir: %s\n", opt.logdir);
    end

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
    if ~exist(opt.outputdir, 'dir')
        status = mkdir(opt.outputdir);
        if ~status
            error('Could not create output directory');
        end
        if opt.verbose
            disp("Output directory created");
        end
    end

    if ~exist(opt.logdir, 'dir')
        status = mkdir(opt.logdir);
        if ~status
            error('Could not create log directory');
        end
        if opt.verbose
            disp("Log dir created");
        end
    end

    % enable logging to files
    status_file = fullfile(opt.logdir, 'pipeline_status.csv');
    matlab_log_file = fullfile(opt.logdir, 'matlab_log');
    if ~exist(matlab_log_file, 'file')
        delete(matlab_log_file); % clear log file if exist
    end
    diary(matlab_log_file);
    if ~exist(status_file,'file')
        cols = ["dsnumber", "imported", "chanremoved", "avg_ref" , "cleanraw", "runica", "iclabel", "midraw", "spectra", "icact", "icmap", "dataqual"];
        col_types = ["string", "logical", "logical",   "logical", "logical", "logical", "logical", "logical", "logical", "logical", "logical", "logical"];
        status_tbl = table('Size', [0 numel(cols)], 'VariableTypes', col_types, 'VariableNames', cols);
        init_vals = [{dsnumber}, arrayfun(@(x) x, repelem(false, numel(cols)-1), 'UniformOutput', false)];
        if opt.verbose
            fprintf("Status file: (ncols - %d, nvals - %d)\n", numel(cols), numel(init_vals));
        end
        status_tbl = [status_tbl; init_vals];
        writetable(status_tbl, status_file);
    end

    % call pipeline components
    varargin = {'bidspath', opt.bidspath, 'eeglabroot', opt.eeglabroot, 'logdir', opt.logdir, 'outputdir', opt.outputdir, 'verbose', opt.verbose};

    bids_preprocess(dsnumber, varargin{:}, 'remove_chan', true, 'avg_ref', true, 'cleanraw', true, 'runica', true, 'iclabel', true);
    generate_vis(dsnumber, varargin{:});
    generate_report(dsnumber, varargin{:});

    % turn off logging
    diary off
end

% NEMAR visualization pipeline
% Required input:
%   EEG      - [struct]  input dataset
% Optional inputs:
%   plots - [cell]    list of measures to plot
%   logdir   - [string]  directory to log execution output
% Output:
%   EEG      - [struct]  plotted dataset
%   status   - [boolean] whether visualization was successfully generated (1) or not (0)
function EEG = eeg_nemar_plugin(EEG, varargin)
    opt = finputcheck(varargin, { ...
        'exclude'        'cell'      {}      {}; ...                     % visualization plots
        'logdir'         'string'    {}      './eeg_nemar_logs'; ...
    }, 'eeg_nemar_plugin');
    if isstr(opt), error(opt); end
    if ~exist(opt.logdir, 'dir')
        logdirstatus = mkdir(opt.logdir);
    end

    try
        which eeglab;
    catch
        warning('EEGLAB not found in path. Trying to add it from expanse...')
        addpath('/expanse/projects/nemar/eeglab');
        eeglab nogui;
    end
    
    [filepath, filename, ext] = fileparts(EEG.filename);
    log_file = fullfile(opt.logdir, filename);

    diary(log_file);

    fprintf('Running NEMAR plugins on %s\n', fullfile(EEG.filepath, EEG.filename));
    opt

    % retrieve plugin from nemar_plugins folder 
    path = fileparts(which('pop_run_pipeline'));
    files = dir(fullfile(path, 'nemar_plugins'));
    addpath(fullfile(path, 'nemar_plugins'));
    plugins = {};
    for i=1:numel(files)
        if startsWith(files(i).name, 'nemar_plugin') && endsWith(files(i).name, '.m')
            fcn = files(i).name(1:end-2);
            plugins = [plugins fcn(numel('nemar_plugin_')+1:end)];
        end
    end

    % run plugins on EEG
    splitted = split(EEG.filename(1:end-4), '_');
    modality = splitted{end};
    status = zeros(1,numel(plugins));
    for i=1:numel(plugins)
        if ~any(contains(opt.exclude, plugins{i}))
            fcn = ['nemar_plugin_' plugins{i}];
            try
                [finished, templateFields] = feval(fcn, EEG, modality);
                status(i) = finished;
            catch ME
                fprintf('Error running plugin %s\n', plugins{i});
                status(i) = 0;
                ME
            end
        end
    end

    % log results
    status_file = fullfile(opt.logdir, [EEG.filename(1:end-4) '_plugins.csv']);
    status_tbl = array2table(zeros(1, numel(plugins)));
    status_tbl.Properties.VariableNames = plugins;
    for p=1:numel(plugins)
        plugin = plugins{p};
        status_tbl.(plugin) = status(p);
    end
    disp(status_tbl)
    writetable(status_tbl, status_file);
end
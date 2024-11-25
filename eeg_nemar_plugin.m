% NEMAR plugin pipeline
% Required input:
%   EEG      - [struct]  input dataset
% Optional inputs:
%   specific - [cell]    plugins to specifically run
%   logdir   - [string]  directory to log execution output
% Output:
%   EEG      - [struct]  plotted dataset
function EEG = eeg_nemar_plugin(EEG, varargin)
    opt = finputcheck(varargin, { ...
        'specific'       'cell'      {}      {}; ...                     % plugins to specifically run
        'modeval'        'string'    {'new', 'resume', 'rerun'}    'resume'; ...                                                      % if import mode, pipeline will overwrite existing outputdir. rerun won't 
        'logdir'         'string'    {}      './eeg_nemar_logs'; ...
        'resave'         'boolean'   {}                      true; ...
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

    status_file = fullfile(opt.logdir, [EEG.filename(1:end-4) '_plugins.csv']);
    if exist(status_file, 'file') 
        status_tbl = readtable(status_file);
    else
        status_tbl = array2table(zeros(1, numel(plugins)));
        status_tbl.Properties.VariableNames = plugins;
    end
    disp(status_tbl)

    for i=1:numel(plugins)
        plugin = plugins{i};
        fcn = ['nemar_plugin_' plugins{i}];
        if ~isempty(opt.specific) && ~any(strcmp(opt.specific, plugins{i}))
            continue
        end
        if strcmp(opt.modeval, 'resume') && isfield(status_tbl, plugin) && status_tbl.(plugin) == 1
            continue
        end
        try
            [finished, templateFields] = feval(fcn, EEG, modality);
            status_tbl.(plugin) = finished;
            status(i) = finished;
        catch ME
            fprintf('Error running plugin %s\n', plugins{i});
            status(i) = 0;
            ME
        end
    end

    % % log results
    % status_file = fullfile(opt.logdir, [EEG.filename(1:end-4) '_plugins.csv']);
    % if exist(status_file, 'file') && strcmp(opt.modeval, 'resume')
    %     disp('status exist')
    %     status
    %     status_tbl = readtable(status_file);
    %     for p=1:numel(plugins)
    %         plugin = plugins{p}
    %         if ~isempty(opt.specific)
    %             if any(strcmp(opt.specific, plugin))
    %                 if strcmp(opt.modeval, 'resume') && isfield(status_tbl, plugin)
    %                 plugin
    %                 status(p)
    %                 status_tbl.(plugin) = status(p);
    %             end
    %         else

    %         end
    %     end
    % else
    %     status_tbl = array2table(zeros(1, numel(plugins)));
    %     status_tbl.Properties.VariableNames = plugins;
    %     for p=1:numel(plugins)
    %         plugin = plugins{p};
    %         status_tbl.(plugin) = status(p);
    %     end
    % end
    % disp(status_tbl)
    writetable(status_tbl, status_file);
    if opt.resave
        disp('Saving EEG file')
        if isfield(EEG.etc, 'nemar_pipeline_status')
            for j=1:numel(status_tbl.Properties.VariableNames)
                field = status_tbl.Properties.VariableNames{j};
                EEG.etc.nemar_pipeline_status.(field) = status_tbl.(field);
            end
        else
            EEG.etc.nemar_pipeline_status = status_tbl;
        end
        pop_saveset(EEG, 'filepath', EEG.filepath, 'filename', EEG.filename, 'savemode', 'onefile');
    end
end
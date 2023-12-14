function run_plugins(STUDY, ALLEEG)
    % retrieve plugin from nemar_plugins folder 
    files = dir('nemar_plugins');
    addpath('nemar_plugins');
    plugins = {};
    for i=1:numel(files)
        if startsWith(files(i).name, 'nemar_plugin') && endsWith(files(i).name, '.m')
            fcn = files(i).name(1:end-2);
            plugins = [plugins fcn(numel('nemar_plugin_')+1:end)];
        end
    end
    status = zeros(numel(ALLEEG), numel(plugins));
    for i=1:numel(plugins)
        fcn = ['nemar_plugin_' plugins{i}];
        try
            [nemarFields, templateFields] = feval(fcn, STUDY, ALLEEG);
            status(:,i) = check_plugin_results(ALLEEG, templateFields.extension)
        catch ME
            ME
        end
    end

    eeg_log_dir = fullfile(STUDY.filepath, 'logs', 'eeg_logs');
    for i=1:numel(ALLEEG)
        EEG = ALLEEG(i);
        % log results
        status_file = fullfile(eeg_log_dir, [EEG.filename(1:end-4) '_plugins.csv']);
        % Always run vis pipeline from scratch
        status_tbl = array2table(zeros(1, numel(plugins)));
        status_tbl.Properties.VariableNames = plugins;
        for p=1:numel(plugins)
            plugin = plugins{p};
            status_tbl.(plugin) = 1;
        end
        disp(status_tbl)
        writetable(status_tbl, status_file);
    end

    function status = check_plugin_results(ALLEEG, extension)
        status = zeros(numel(ALLEEG),1);
        for i=1:numel(ALLEEG)
            EEG = ALLEEG(i);
            result_basename = EEG.filename(1:end-4); % for plots
            outpath = EEG.filepath;
            filepath = fullfile(outpath, [ result_basename extension ]);
            if exist(filepath)
                status(i) = 1; 
            end
        end
    end
end
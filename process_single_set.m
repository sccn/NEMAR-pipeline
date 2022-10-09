function process_single_set(root_path,filepath, outpath, result_basename)
    addpath(root_path);
    load_eeglab(root_path);
    EEG = pop_loadset(filepath);
    report = Report(sprintf('%s/%s',outpath, result_basename));
    processedEEG = [result_basename '_processed'];
    try
        %% fresh preprocessing
        fprintf('Processing dataset %s\n', EEG.filename);
        Report.clear_report(outpath, result_basename);
        EEG = eeg_checkset(EEG, 'loaddata');
        
        % check channel locations and remove non-EEG channels
        EEG = Preprocessing.check_channels(EEG);

        % resample for high-frequency datasets
        if EEG.srate == 5000
            EEG = pop_resample(EEG, 250); % instead of 5000 Hz (ds002336 and ds002338)
        end

        % remove DC
        disp('Remove DC');
        EEG = pop_rmbase(EEG, [EEG.times(1) EEG.times(end)]);
        EEG.etc.orinbchan = EEG.nbchan;
        EEG.etc.oripnts   = EEG.pnts;
        pop_saveset(EEG, fullfile(outpath, processedEEG));

        %{
        Report.append_report('task', EEG.task, outpath, result_basename);
        Report.append_report('run', EEG.run, outpath, result_basename);
        Report.append_report('session', EEG.session, outpath, result_basename);
        Report.append_report('numChans', EEG.etc.orinbchan, outpath, result_basename);
        Report.append_report('numFrames', EEG.etc.oripnts, outpath, result_basename);

        % generate plots of un-cleaned data
        Visualizer.plot_raw_mid_segment(EEG, outpath, result_basename, report);
        Visualizer.plot_raw_all_segment(EEG, outpath, result_basename, report);
        Visualizer.plot_spectra(EEG, outpath, result_basename, report);
        %}

        % clean data and run ICA
        if any(any(EEG.data')) % not all data is 0
            % remove bad channels
            EEG = Preprocessing.run_clean_rawdata(EEG, outpath, result_basename, report);
            EEG = pop_reref(EEG, []);
            pop_saveset(EEG, fullfile(outpath, [processedEEG '_cleanraw_rerefavg']));
            EEG = Preprocessing.run_ICA(EEG, outpath, result_basename, report);
            pop_saveset(EEG, fullfile(outpath, [processedEEG '_amica']));

            % Visualizer.plot_IC_activation(EEG, outpath, result_basename, report);
            % Visualizer.plot_ICLabel(EEG, outpath, result_basename, report);
        end    
    catch ME
        l = lasterror;
        report.log_error(outpath, result_basename, 'Error during preprocessing', ME, l);
    end
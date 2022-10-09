function processing_pipeline_OO(filepath, outpath, root_path)
    [STUDY, ALLEEG, dsname] = load_dataset(filepath, outpath, root_path);
    regenerate_plots = true;
    rerun_processing = false;
    rerun_clean_raw = false;
    rerun_ICA = false;

    report = Report(sprintf('%s/%s',outpath, dsname));
    % start pipeline
    for iDat = 10%length(ALLEEG)
        EEG = ALLEEG(iDat);

        result_basename = EEG.filename(1:end-4); % for plots
        outpath = EEG.filepath;
        processedEEG = [ EEG.filename(1:end-4) '_processed.set' ];

        if exist(fullfile(EEG.filepath, processedEEG), 'file') && rerun_processing
            delete(fullfile(EEG.filepath, processedEEG));
        end

        if ~exist(fullfile(EEG.filepath, processedEEG), 'file')
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

                Report.append_report('task', EEG.task, outpath, result_basename);
                Report.append_report('run', EEG.run, outpath, result_basename);
                Report.append_report('session', EEG.session, outpath, result_basename);
                Report.append_report('numChans', EEG.etc.orinbchan, outpath, result_basename);
                Report.append_report('numFrames', EEG.etc.oripnts, outpath, result_basename);

                % generate plots of un-cleaned data
                Visualizer.plot_raw_mid_segment(EEG, outpath, result_basename, report);
                Visualizer.plot_raw_all_segment(EEG, outpath, result_basename, report);
                Visualizer.plot_spectra(EEG, outpath, result_basename, report);

                % clean data and run ICA
                if any(any(EEG.data')) % not all data is 0
                    % remove bad channels
                    EEG = Preprocessing.run_clean_rawdata(EEG, outpath, result_basename, report);
                    EEG = pop_reref(EEG, []);
                    EEG = Preprocessing.run_ICA(EEG, outpath, result_basename, report);

                    Visualizer.plot_IC_activation(EEG, outpath, result_basename, report);
                    Visualizer.plot_ICLabel(EEG, outpath, result_basename, report);
                end    
            catch ME
                l = lasterror;
                report.log_error(outpath, result_basename, 'Error during preprocessing', ME, l);
            end
            % run_processing(EEG, outpath, result_basename)
        else 
            %% regenerate report and visualization if already processed
            fprintf('Loading dataset %s\n', processedEEG);
            EEG = pop_loadset(fullfile(EEG.filepath, processedEEG));

            if rerun_clean_raw
                % re-run clean_rawdata
                Preprocessing.clean_rawdata(EEG, outpath, result_basename, report);
            end

            if rerun_ICA
                % re-run ICA
                Preprocessing.run_ICA(EEG, outpath, result_basename, report);
            end

            if regenerate_plots
                % regenerate plots
                % NOTE: new raw and spectra plots will be on cleaned data, while original plots uncleaned data
                % Visualizer.plot_raw_mid_segment(EEG, outpath, result_basename, report);
                Visualizer.plot_raw_all_segment(EEG, outpath, result_basename, report);
                % Visualizer.plot_spectra(EEG, outpath, result_basename, report);

                % IC maps
                % Visualizer.plot_IC_activation(EEG, outpath, result_basename, report);
                % Visualizer.plot_ICLabel(EEG, outpath, result_basename, report);
            end
        end
    end

    % function run_processing(EEG, outpath, result_basename)
    % end
end
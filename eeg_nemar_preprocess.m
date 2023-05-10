function [EEG, status] = eeg_nemar_preprocess(EEG, varargin)
    if nargin > 1
        pipeline = varargin{1};
    else
        pipeline = {'remove_chan', 'cleanraw', 'avg_ref', 'runica', 'iclabel'};
    end
    if nargin > 2
        logdir = varargin{2};
    else
        logdir = './eeg_nemar_preprocess_logs';
        status = mkdir(logdir)
    end

    try
        which eeglab;
    catch
        addpath('/expanse/projects/nemar/dtyoung/NEMAR-pipeline/eeglab');
        eeglab nogui;
    end

    [filepath, filename, ext] = fileparts(EEG.filename);
    log_file = fullfile(logdir, filename);
    if exist(log_file, 'file')
        delete(log_file)
    end

    diary(log_file);
    fprintf('Processing %s\n', fullfile(EEG.filepath, EEG.filename));
    if isempty(pipeline)
        error('No pipeline sequence provided')
    end
    status = zeros(1, numel(pipeline));

    fprintf('Running pipeline sequence %s\n', strjoin(pipeline, '->'));
    try
        for i=1:numel(pipeline)
            operation = pipeline{i};
            if strcmp(operation, "remove_chan")
                % % remove non-ALLEEG channels (it is also possible to process ALLEEG data with non-ALLEEG data
                % get non-EEG channels
                % keep only EEG channels
                rm_chan_types = {'AUDIO','MEG','EOG','ECG','EMG','EYEGAZE','GSR','HEOG','MISC','PPG','PUPIL','REF','RESP','SYSCLOCK','TEMP','TRIG','VEOG'};
                if isfield(EEG.chanlocs, 'type')
                    EEG = pop_select(EEG, 'rmchantype', rm_chan_types);
                    types = {EEG.chanlocs.type};
                    eeg_indices = strmatch('EEG', types)';
                    if ~isempty(eeg_indices)
                        EEG = pop_select(EEG, 'chantype', 'EEG');
                    else
                        warning("No EEG channel type detected (for first EEG file). Keeping all channels");
                    end
                else
                    warning("Channel type not detected (for first EEG file)");
                end
                % ALLEEG = pop_select( ALLEEG,'nochannel',{'VEOG', 'Misc', 'ECG', 'M2'});

                if isfield(EEG.chanlocs, 'theta')
                    thetas = [EEG.chanlocs.theta];
                    if isempty(thetas)
                        warning("No channel locations detected (for first EEG file)");
                    end
                end
            end

            if strcmp(operation, "cleanraw")
                if EEG.trials > 1
                    error('Epoched data given to cleanraw');
                end
		
		% remove offset
		EEG = pop_rmbase( EEG, [],[]);

                % clean data using the clean_rawdata plugin
                options = {'FlatlineCriterion',5,'ChannelCriterion',0.85, ...
                    'LineNoiseCriterion',4,'Highpass',[0.75 1.25] ,'BurstCriterion',50, ...
                    'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian', ...
                    'WindowCriterionTolerances',[-Inf 7] ,'fusechanrej',1}; % based on Arnaud paper
                % ALLEEG = parexec(ALLEEG, 'pop_clean_rawdata', opt.logdir, options{:});
                EEG = pop_clean_rawdata( EEG, options{:});
            end

            if strcmp(operation, "avg_ref")
                % recompute average reference interpolating missing channels (and removing
                % them again after average reference - STUDY functions handle them automatically)
                options = {[], 'interpchan', []};
                EEG = pop_reref( EEG,options{:});
            end

            if strcmp(operation, "runica")
                % status_tbl.runica(strcmp(status_tbl.dsnumber,dsname)) = false;
                % run ICA reducing the dimention by 1 to account for average reference 
                nChans = EEG.nbchan;
                lrate = 0.00065/log(mean(nChans))/10; % not the runica default - suggested by Makoto approximately 12/22
                options = {'icatype','runica','concatcond','on', 'pca',-1, 'extended', 1, 'lrate', lrate, 'maxsteps', 2000};
                EEG = pop_runica(EEG, options{:});
            end

            if strcmp(operation, "iclabel")
                % status_tbl.iclabel(strcmp(status_tbl.dsnumber,dsname)) = false;
                % % run ICLabel and flag artifactual components
                % if strcmp(EEG.etc.datatype, 'EEG')
                    options = {'default'};
                    EEG = pop_iclabel(EEG, options{:});
                    options = {[NaN NaN;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]};
                    EEG = pop_icflag( EEG, options{:});
                % end
            end

            % if reached, the operation finished with no error
            status(i) = 1;
            pop_saveset(EEG, 'filepath', EEG.filepath, 'filename', EEG.filename);
        end
    catch ME
        fprintf('%s\n%s\n',ME.identifier, ME.getReport());
    end
    diary off
end

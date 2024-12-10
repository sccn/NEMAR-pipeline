% NEMAR preprocessing pipeline
% Required input:
%   EEG      - [struct]  input dataset
% Optional inputs:
%   pipeline - [cell]    list of preprocessing steps in order
%   logdir   - [string]  directory to log execution output
%   resave   - [boolean] whether to save processed data back on disk. Default true
% Output:
%   EEG      - [struct]  processed dataset
%   status   - [boolean] whether dataset was processed successfully (1) or not (0)

% To do: ignore non-EEG channel types instead of removing them

function [EEG, status] = eeg_nemar_preprocess(EEG, varargin)
    pipeline_all = {'check_import', 'check_chanloc', 'channelsystem', 'cleanraw', 'runica', 'iclabel'};
    opt = finputcheck(varargin, { ...
        'pipeline'       'cell'      {}                      pipeline_all; ...  % preprocessing steps
        'logdir'         'string'    {}                      './eeg_nemar_logs'; ...
        'modeval'        'string'    {'new', 'resume', 'rerun'}    'resume'; ...                                                      % if import mode, pipeline will overwrite existing outputdir. rerun won't 
        'resave'         'boolean'   {}                      true; ...
    }, 'eeg_nemar_preprocess');
    if isstr(opt), error(opt); end
    if ~exist(opt.logdir, 'dir')
        logdirstatus = mkdir(opt.logdir);
    end

    try
        which eeglab;
    catch
        try
            addpath('/expanse/projects/nemar/eeglab');
            eeglab nogui;
        catch
            error('EEGLAB load failed.')
        end
    end

    resume = strcmp(opt.modeval, "resume");

    [filepath, filename, ext] = fileparts(EEG.filename);
    disp(filename)
    log_file = fullfile(opt.logdir, filename);
    if exist(log_file, 'file')
        delete(log_file)
    end

    diary(log_file);
    fprintf('Processing %s\n', fullfile(EEG.filepath, EEG.filename));

    status_file = fullfile(opt.logdir, [filename '_preprocess.csv']);
    % if status_file exists, read it
    if exist(status_file, 'file') && (strcmp(opt.modeval, "resume") || strcmp(opt.modeval, "rerun"))
        status_tbl = readtable(status_file);
        % accommodate legacy setup
        missing_column = {'remove_chan'};
        for c=1:numel(missing_column)
            col = missing_column{c};
            if ~ismember(col, status_tbl.Properties.VariableNames)
                status_tbl.(col) = 0;
            end
        end
    else
        status_tbl = array2table(zeros(1, numel(pipeline_all)));
        status_tbl.Properties.VariableNames = pipeline_all;
        writetable(status_tbl, status_file);
    end
    disp(status_tbl)
    status = table2array(status_tbl);

    splitted = split(EEG.filename(1:end-4),'_');
    modality = splitted{end};

    fprintf('Running pipeline sequence %s\n', strjoin(opt.pipeline, '->'));
    try
        for i=1:numel(opt.pipeline)
            disp(fullfile(EEG.filepath, EEG.filename))
            operation = opt.pipeline{i};
            if strcmp(operation, "check_import")
                % if check_import is not a field in status_tbl
                if ~isfield(status_tbl, 'check_import')
                    status_tbl.check_import = status_tbl.remove_chan;
                end
                if resume && status_tbl.check_import
                    fprintf('Skipping check_import\n');
                    continue
                end
                if exist(fullfile(EEG.filepath, EEG.filename), 'file')
                    status_tbl.check_import = 1;
                end
            end
            if strcmp(operation, "check_chanloc")
                if resume && isfield(status_tbl, 'check_chanloc') && status_tbl.check_chanloc
                    fprintf('Skipping check_chanloc\n');
                    continue
                end
                if isfield(EEG.chanlocs, 'theta') && (strcmp(modality, 'eeg') || strcmp(modality, 'meg'))
                    thetas = [EEG.chanlocs.theta];
                    if isempty(thetas)
                        error("Error: No channel locations detected");
                    end
                end
                status_tbl.check_chanloc = 1;
            end

            if strcmp(operation, "remove_chan")
                if resume && status_tbl.remove_chan
                    fprintf('Skipping remove_chan\n');
                    continue
                end
                % % remove non-ALLEEG channels (it is also possible to process ALLEEG data with non-ALLEEG data
                % get non-EEG channels
                % keep only EEG channels
                rm_chan_types = {'AUDIO','EOG','ECG','EMG','EYEGAZE','GSR','HEOG','MISC','PPG','PUPIL','REF','RESP','SYSCLOCK','TEMP','TRIG','VEOG'};
                if isfield(EEG.chanlocs, 'type')
                    EEG = pop_select(EEG, 'rmchantype', rm_chan_types);
                    if strcmp(modality, 'eeg')
                            types = {EEG.chanlocs.type};
                            eeg_indices = strmatch('EEG', types)';
                            if ~isempty(eeg_indices)
                                EEG = pop_select(EEG, 'chantype', 'EEG');
                            else
                                warning("No EEG channel type detected (for first EEG file). Keeping all channels");
                            end
                    end
                else
                    warning("Channel type not detected (for first recording file)");
                end
                status_tbl.remove_chan = 1;
            end

            if strcmp(operation, "cleanraw")
                if resume && status_tbl.cleanraw
                    fprintf('Skipping cleanraw\n');
                    continue
                end
                if EEG.trials > 1
                    error('Epoched data given to cleanraw');
                end
		
                % remove offset
                EEG = pop_rmbase( EEG, [],[]);

                % Highpass filter
                EEG = pop_eegfiltnew(EEG, 'locutoff',0.5);

                % clean data using the clean_rawdata plugin
                options = {'FlatlineCriterion',4,'ChannelCriterion',0.85, ...
                    'LineNoiseCriterion',4,'Highpass', 'off' ,'BurstCriterion',20, ...
                    'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian', ...
                    'WindowCriterionTolerances',[-Inf 7] ,'fusechanrej',1}; % based on Arnaud paper
                EEG = pop_clean_rawdata( EEG, options{:});

                status_tbl.cleanraw = 1;
            end

            if strcmp(operation, "runica")
                if resume && status_tbl.runica
                    fprintf('Skipping runica\n');
                    continue
                end
                % run ICA reducing the dimention by 1 to account for average reference 
                K = 4; % TODO: use Arno's formula
                if K >= 5
                    fprintf('Running amica\n');
                    options = {'batch', 1};
                    EEG = runamica17_nsg(EEG, options{:});
                else
                    fprintf('Running extended ICA\n');
                    nChans = EEG.nbchan;
                    lrate = 0.00065/log(mean(nChans))/10; % not the runica default - suggested by Makoto approximately 12/22
                    options = {'icatype','runica','concatcond','on', 'extended', 1, 'lrate', 1e-5, 'maxsteps', 2000};
                    EEG = pop_runica(EEG, options{:});
                end

                status_tbl.runica = 1;
            end

            if strcmp(operation, "iclabel") && strcmp(modality, 'eeg')
                if resume && status_tbl.iclabel
                    fprintf('Skipping iclabel\n');
                    continue
                end
                % % run ICLabel and flag artifactual components
                % if strcmp(EEG.etc.datatype, 'EEG')
                options = {'default'};
                EEG = pop_iclabel(EEG, options{:});
                options = {[NaN NaN;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]};
                EEG = pop_icflag( EEG, options{:});
                % end
                status_tbl.iclabel = 1;
            end

            % if reached, operation completed without error and result should be saved
            if opt.resave
                if strcmp(opt.modeval, "new") || ~isfield(EEG.etc, 'nemar_pipeline_status')
                    EEG.etc.nemar_pipeline_status = status_tbl;
                end
                if strcmp(opt.modeval, "rerun") || strcmp(opt.modeval, "resume")
                    % iterate through fields of status_tbl and add to EEG.etc.nemar_pipeline_status
                    for j=1:numel(status_tbl.Properties.VariableNames)
                        field = status_tbl.Properties.VariableNames{j};
                        EEG.etc.nemar_pipeline_status.(field) = status_tbl.(field);
                    end
                end
                disp('Saving EEG file')
                pop_saveset(EEG, 'filepath', EEG.filepath, 'filename', EEG.filename, 'savemode', 'onefile');
            end
            % write status file
            writetable(status_tbl, status_file);
            status = table2array(status_tbl);
        end
    catch ME
        fprintf('%s\n%s\n',ME.identifier, ME.getReport());
    end
    
    % close log file
    diary off
end
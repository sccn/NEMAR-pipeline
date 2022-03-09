classdef Preprocessing
    methods (Static = true)
        function EEG = check_channels(EEG)
            % remove non-EEG channels
            % and add channel locations
            disp('Selecting EEG channels...');
            try
                dipfit_path = fileparts(which('pop_dipplot'));
            catch
                dipfit_path = fullfile(root_path, 'eeglab','plugins','dipfit');
            end
            chanfile = [dipfit_path '/standard_BEM/elec/standard_1005.elc'];
            if ~exist(chanfile,'file')
                chanfile = '/home/octave/eeglab/plugins/dipfit/standard_BEM/elec/standard_1005.elc';
            end
            if isfield(EEG.chanlocs, 'theta')
                notEmpty = ~cellfun(@isempty, { EEG.chanlocs.theta });
                if any(notEmpty)
                    EEG = pop_select(EEG, 'channel', find(notEmpty));
                else
                    EEG = pop_chanedit(EEG, 'lookup',chanfile);
                end
            else
                EEG = pop_chanedit(EEG, 'lookup',chanfile);
            end
            notEmpty = ~cellfun(@isempty,  { EEG.chanlocs.theta });
            EEG = pop_select(EEG, 'channel', find(notEmpty));
        
            % disp(['num chans ' num2str(EEG.nbchan)]);
            % disp(['data size ']);
            % disp(size(EEG.data));
        end

        function EEG = run_ICA(EEG, outpath, result_basename, report)
            disp('Run ICA decomposition...');
            try
                amicaout = fullfile(outpath, 'amicaout');
                if exist(amicaout, 'dir')
                    EEG = eeg_loadamica(EEG, fullfile(outpath, 'amicaout'));
                else
                    EEG = pop_runamica(EEG,'numprocs',1, 'do_reject', 1, 'numrej', 5, 'rejint', 4,'rejsig', 3,'rejstart', 1, 'pcakeep',EEG.nbchan-1); % Computing ICA with AMICA
                    EEG = eeg_loadamica(EEG, fullfile(outpath, 'amicaout'));
                    % rmdir( fullfile(EEG.filepath, 'amicaout'), 's');
                end
                % EEG = pop_runica(EEG, 'icatype','picard','options',{'pca',EEG.nbchan-1});
                EEG = pop_iclabel(EEG,'default');
                EEG = pop_icflag(EEG,[0.75 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
                pop_saveset(EEG, fullfile(outpath, [result_basename '_processed.set']));

                rejected_ICs = sum(EEG.reject.gcompreject);
                numICs = EEG.nbchan-1;
                report.append_report('icaFail', 0, outpath, result_basename);
                report.append_report('nICs', numICs, outpath, result_basename);
                report.append_report('nGoodICs', numICs-rejected_ICs, outpath, result_basename);
                report.append_report('goodICA', 100*(numICs-rejected_ICs)/numICs, outpath, result_basename);
            catch ME
                l = lasterror;
                report.log_error(outpath, filename, 'ICA failed', ME, l);
                report.append_report('icaFail', 1, outpath, result_basename);
            end
        end
        
        function EEG = run_clean_rawdata(EEG, outpath, result_basename, report)
            disp('Call clean_rawdata...');
            try
                EEGTMP = pop_clean_rawdata( EEG,'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass',[0.25 0.75] ,...
                    'BurstCriterion',20,'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7] );
                EEG = EEGTMP;
                pop_saveset(EEG, fullfile(outpath, [result_basename '_processed.set']));

                report.append_report('asrFail', 0, outpath, result_basename);
                report.append_report('nGoodChans', EEG.nbchan, outpath, result_basename);
                report.append_report('goodChans', 100*EEG.nbchan/EEG.etc.orinbchan, outpath, result_basename);
                report.append_report('nGoodData', EEG.pnts, outpath, result_basename);
                report.append_report('goodData', 100*EEG.pnts/EEG.etc.oripnts, outpath, result_basename);
            catch ME
                l = lasterror
                report.log_error(outpath, filename, 'clean_rawdata failed', ME, l);
                report.append_report('asrFail', 1, outpath, result_basename);
            end
        end
    end
end
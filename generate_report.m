function status = generate_report(ALLEEG, varargin)
    import java.text.*
    if nargin > 1
        study_path = varargin{1}
    else 
        study_path = './dataqual_report'
        mkdir(study_path)
    end
    if nargin > 2
        eeg_logdir = varargin{2}
    else
        eeg_logdir = study_path;
    end

    if ~exist('eeglab')
        addpath('/expanse/projects/nemar/dtyoung/NEMAR-pipeline/eeglab');
        eeglab nogui;
    end
    if ~exist('jsonread')
        addpath('/expanse/projects/nemar/dtyoung/NEMAR-pipeline/JSONio');
    end

    status = zeros(numel(ALLEEG), 1);
    goodDataPs = zeros(numel(ALLEEG),1);
    goodChanPs = zeros(numel(ALLEEG),1);
    goodICPs = zeros(numel(ALLEEG),1);
    decFormatter = DecimalFormat;
    for i=1:numel(ALLEEG)
        EEG = ALLEEG(i);
        EEG = eeg_checkset(EEG, 'loaddata');
        [filepath, filename, ext] = fileparts(EEG.filename);
        log_file = fullfile(eeg_logdir, filename);

        diary(log_file);
        try
            fprintf('Generating reports for %s\n', fullfile(EEG.filepath, EEG.filename));
            report_file = fullfile(EEG.filepath, [EEG.filename(1:end-4) '_dataqual.json']);
            fid = fopen(report_file,'w');
            fprintf(fid,'{}');
            fclose(fid);

            status(i) = 1;

            % [dataP, chanP] = cleanraw_report(EEG, report_file);
            %report.append_report('asrFail', 0, outpath, result_basename);
            cur_report = jsonread(report_file);
            if isfield(EEG.etc, 'clean_sample_mask')
                goodDataPercent = round(100*EEG.pnts/numel(EEG.etc.clean_sample_mask), 2); % new change to clean_raw_data
                cur_report.nGoodData = char(decFormatter.format(EEG.pnts));
                cur_report.goodDataPercent = sprintf('%s of %s (%.0f%%)', char(decFormatter.format(EEG.pnts)), char(decFormatter.format(numel(EEG.etc.clean_sample_mask))), goodDataPercent);
                goodDataPs(i) = goodDataPercent;
            else
                cur_report.goodDataFail = 1;
                warning('Warning: clean_sample_mask not found');
                status(i) = 0;
            end
            jsonwrite(report_file, cur_report);

            if isfield(EEG.etc, 'clean_channel_mask')
                goodChanPercent = round(100*EEG.nbchan/numel(EEG.etc.clean_channel_mask), 2);
                cur_report.nGoodChans = EEG.nbchan;
                cur_report.goodChansPercent = goodChanPercent;
                cur_report.goodChansPercent= sprintf('%d of %d (%.0f%%)', EEG.nbchan, numel(EEG.etc.clean_channel_mask), goodChanPercent);
                goodChanPs(i) = goodChanPercent;
            else
                cur_report.goodChanFail = 1;
                warning('Warning: clean_channel_mask not found');
                status(i) = 0;
            end
            jsonwrite(report_file, cur_report);

            % icaP = ica_report(EEG, report_file);
            cur_report = jsonread(report_file);
            if isfield(EEG, 'icaact') && ~isempty(EEG.icaact)
                cur_report.icaFail = 0;
                rejected_ICs = sum(EEG.reject.gcompreject);
                numICs = EEG.nbchan-1;
                cur_report.nICs = numICs;
                cur_report.nGoodICs = numICs-rejected_ICs;
                cur_report.goodICA = sprintf('%d of %d (%.0f%%)', numICs-rejected_ICs, numICs, round(100*(numICs-rejected_ICs)/numICs, 2));

                goodICPercent = round(100*(numICs-rejected_ICs)/numICs, 2);
                goodICPs(i) = goodICPercent;
            else
                cur_report.icaFail = 1;
                warning('Warning: ICA report failed');
                status(i) = 0;
            end
            jsonwrite(report_file, cur_report);

            % magnitude of line noise
            cur_report = jsonread(report_file);
            g = finputcheck({}, { 'freq'    'integer' []         [6, 10, 22]; ...
                        'freqrange'   'integer'   []         [1 70]; ...
                        'percent'   'integer'    [], 10});
            [spec, freqs] = spectopo(EEG.data, 0, EEG.srate, 'freqrange', g.freqrange, 'title', '', 'chanlocs', EEG.chanlocs, 'percent', g.percent,'plot', 'off');
            [~,ind50]=min(abs(freqs-50));
            freq_50 = mean(spec(:, ind50));
            [~,ind60]=min(abs(freqs-60));
            freq_60 = mean(spec(:, ind60));
            if freq_50 > freq_60
                linenoise_magn = freq_50 - mean(mean(spec(:, [ind50-6:ind50-2 ind50+2:ind50+6]), 1));
            else
                linenoise_magn = freq_60 - mean(mean(spec(:, [ind60-6:ind60-2 ind60+2:ind60+6]), 1));
            end
            cur_report.linenoise_magn = sprintf('%.2fdB',linenoise_magn);
            jsonwrite(report_file, cur_report);

        catch ME
            fprintf('%s\n%s\n',ME.identifier, ME.getReport());
        end
        diary off;
    end

    % dataset level report
    if sum(goodDataPs) ~= 0
        report_file = fullfile(study_path, 'dataqual.json');
        fid = fopen(report_file,'w');
        fprintf(fid,'{}');
        fclose(fid);
        cur_report = jsonread(report_file);
        cur_report.goodDataPercentMin = min(goodDataPs);
        cur_report.goodDataPercentMax = max(goodDataPs);
        cur_report.goodChansPercentMin = min(goodChanPs);
        cur_report.goodChansPercentMax = max(goodChanPs);
        cur_report.goodICAPercentMin = min(goodICPs);
        cur_report.goodICAPercentMax = max(goodICPs);
        jsonwrite(report_file, cur_report);
    end

    function [goodDataPercent, goodChanPercent] = cleanraw_report(EEG, report_file)
        %report.append_report('asrFail', 0, outpath, result_basename);
        cur_report = jsonread(report_file);
        goodDataPercent = 100;
        goodChanPercent = 100;
        if isfield(EEG.etc, clean_sample_mask)
            goodDataPercent = round(100*EEG.pnts/numel(EEG.etc.clean_sample_mask), 2); % new change to clean_raw_data
        end
        if isfield(EEG.etc, clean_channel_mask)
            goodChanPercent = round(100*EEG.nbchan/numel(EEG.etc.clean_channel_mask), 2);
        end
        cur_report.nGoodData = EEG.pnts;
        cur_report.goodDataPercent = goodDataPercent;
        cur_report.nGoodChans = EEG.nbchan;
        cur_report.goodChansPercent = goodChanPercent;
        jsonwrite(report_file, cur_report);
    end

    function goodICPercent = ica_report(EEG, report_file)
        cur_report = jsonread(report_file);
        if isfield(EEG, 'icaact') && ~isempty(EEG.icaact)
            cur_report.icaFail = 0;
            rejected_ICs = sum(EEG.reject.gcompreject);
            numICs = EEG.nbchan-1;
            cur_report.nICs = numICs;
            cur_report.nGoodICs = numICs-rejected_ICs;
            cur_report.goodICA = 100*(numICs-rejected_ICs)/numICs;

            goodICPercent = 100*(numICs-rejected_ICs)/numICs;
        else
            cur_report.icaFail = 1;
            goodICPercent = -1;
        end
        jsonwrite(report_file, cur_report);
    end

    function append_report(key, val, outpath, result_basename)
        valid_keys = {'task', 'run', 'session', 'numChans', 'numFrames', 'goodChans', 'goodData', 'goodICA', 'nICs', 'asrFail', 'icaFail', 'nGoodChans', 'nGoodData'};
        if any(strcmp(key, valid_keys))
            disp(['Adding ' key ' to dataqual report..']);
            jsonfile = fullfile(outpath, [result_basename '_dataqual.json'] );
            if ~exist(jsonfile,'file')
                fid = fopen(jsonfile,'w');
                fprintf(fid,'{}');
                fclose(fid);
            end
            cur_report = jsonread(jsonfile);
            cur_report.(key) = val;
            jsonwrite(jsonfile, cur_report);
        else
            error(sprintf('Invalid key %s', key));
        end
    end
    function clear_report(outpath, result_basename)
        disp('Clearing dataqual.json...');
        jsonfile = fullfile(outpath, [result_basename '_dataqual.json'] );
        if exist(jsonfile,'file')
            fid = fopen(jsonfile,'w');
            fprintf(fid,'{}');
            fclose(fid);
        end
    end
end

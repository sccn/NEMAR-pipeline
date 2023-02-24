function status = generate_report(ALLEEG, opt)
    status = zeros(numel(ALLEEG), 1);
    goodDataPs = zeros(numel(ALLEEG),1);
    goodChanPs = zeros(numel(ALLEEG),1);
    goodICPs = zeros(numel(ALLEEG),1);
    parfor i=1:numel(ALLEEG)
        EEG = ALLEEG(i);

        [filepath, filename, ext] = fileparts(EEG.filename);
        log_file = fullfile(opt.logdir, filename);

        diary(log_file);
        try
            fprintf('Generating reports for %s\n', fullfile(EEG.filepath, EEG.filename));
            report_file = fullfile(EEG.filepath, [EEG.filename(1:end-4) '_dataqual.json']);
            fid = fopen(report_file,'w');
            fprintf(fid,'{}');
            fclose(fid);

            % [dataP, chanP] = cleanraw_report(EEG, report_file);
            %report.append_report('asrFail', 0, outpath, result_basename);
            cur_report = jsonread(report_file);
            goodDataPercent = round(100*EEG.pnts/numel(EEG.etc.clean_sample_mask), 2); % new change to clean_raw_data
            goodChanPercent = round(100*EEG.nbchan/numel(EEG.etc.clean_channel_mask), 2);
            cur_report.nGoodData = EEG.pnts;
            cur_report.goodDataPercent = goodDataPercent;
            cur_report.nGoodChans = EEG.nbchan;
            cur_report.goodChansPercent = goodChanPercent;
            jsonwrite(report_file, cur_report);

            % icaP = ica_report(EEG, report_file);
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

            goodDataPs(i) = goodDataPercent;
            goodChanPs(i) = goodChanPercent;
            goodICPs(i) = goodICPercent;

            status(i) = 1;
        catch ME
            fprintf('%s\n%s\n',ME.identifier, ME.getReport());
        end
        diary off;
    end

    % dataset level report
    if sum(goodDataPs) ~= 0
        report_file = fullfile(opt.bidspath, 'dataqual.json');
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
        goodDataPercent = round(100*EEG.pnts/numel(EEG.etc.clean_sample_mask), 2); % new change to clean_raw_data
        goodChanPercent = round(100*EEG.nbchan/numel(EEG.etc.clean_channel_mask), 2);
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

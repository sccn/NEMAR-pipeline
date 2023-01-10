function generate_report(dsnumber, varargin)
    nemar_path = '/expanse/projects/nemar/openneuro';
    eeglabroot = '/expanse/projects/nemar/dtyoung/NEMAR-pipeline';
    addpath(fullfile(eeglabroot,'eeglab'));
    addpath(fullfile(eeglabroot,'JSONio'));
    eeglab nogui;
    opt = finputcheck(varargin, { ...
        'bidspath'       'string'    {}    fullfile(nemar_path, dsnumber);  ...
        'eeglabroot'     'string'    {}    eeglabroot; ...
        'logdir'         'string'    {}    fullfile(nemar_path, 'logs', dsnumber); ...
        'outputdir'      'string'    { }   fullfile(nemar_path, dsnumber); ...
        'verbose'        'boolean'   {}    false; ...
        }, 'generate_report');
    if isstr(opt), error(opt); end

    % reload eeglab if different version specified
    if ~strcmp(eeglabroot, opt.eeglabroot)
        addpath(fullfile(opt.eeglabroot,'eeglab'));
        addpath(fullfile(opt.eeglabroot,'JSONio'));
        eeglab nogui;
    end

    % load data
    studyFile = fullfile(opt.bidspath, [dsnumber '.study']);
    if exist(studyFile, 'file')
	[STUDY, ALLEEG] = pop_loadstudy(studyFile);
    else
        error('Dataset has not been imported');
    end

    status_file = fullfile(opt.logdir, 'pipeline_status.csv');
    % enable logging to file
    diary(fullfile(opt.logdir, 'matlab_log'));
    disp("Generating data quality report...");

    if ~exist(status_file,'file')
        error("Log file not detected. Have you run preprocessing?")
    else
        status_tbl = readtable(status_file)
    end

    try
        status_tbl.dataqual(strcmp(status_tbl.dsnumber,dsnumber)) = false;
        goodDataPs = [];
        goodChanPs = [];
        goodICPs = [];
        for i=1:numel(ALLEEG)
            EEG = ALLEEG(i);
            report_file = fullfile(EEG.filepath, [EEG.filename(1:end-4) '_dataqual.json']);
            fid = fopen(report_file,'w');
            fprintf(fid,'{}');
            fclose(fid);

            [dataP, chanP] = cleanraw_report(EEG, report_file);
            icaP = ica_report(EEG, report_file);

            goodDataPs = [goodDataPs dataP];
            goodChanPs = [goodChanPs chanP];
            goodICPs = [goodICPs icaP];
        end

        % dataset level report
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

        status_tbl.dataqual(strcmp(status_tbl.dsnumber,dsnumber)) = true;

        writetable(status_tbl, fullfile(opt.logdir, 'pipeline_status.csv'));
        disp(status_tbl)
    catch ME
        writetable(status_tbl, fullfile(opt.logdir, 'pipeline_status.csv'));
        disp(status_tbl)

        error('%s\n%s',ME.identifier, ME.getReport());
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

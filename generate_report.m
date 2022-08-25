function generate_report(dsnumber, varargin)
    nemar_path = '/expanse/projects/nemar/openneuro';
    eeglabroot = '/expanse/projects/nemar/dtyoung/NEMAR-pipeline';
    addpath(fullfile(eeglabroot,'eeglab'));
    addpath(fullfile(eeglabroot,'JSONio'));
    eeglab nogui;
    opt = finputcheck(varargin, { ...
        'bidspath'       'string'    {}    fullfile(nemar_path, dsnumber);  ...
        'eeglabroot'     'string'    {}    eeglabroot; ...
        'reportdir'      'string'    {}    fullfile(nemar_path, 'processed', dsnumber); ...
        }, 'generate_report');
    if isstr(opt), error(opt); end

    % reload eeglab if different version specified
    if ~strcmp(eeglabroot, opt.eeglabroot)
        addpath(fullfile(opt.eeglabroot,'eeglab'));
        addpath(fullfile(opt.eeglabroot,'JSONio'));
        eeglab nogui;
    end

    report_file = fullfile(opt.reportdir, 'dataqual.json');
    % recreate
    fid = fopen(report_file,'w');
    fprintf(fid,'{}');
    fclose(fid);

    for i=1:numel(ALLEEG)
        EEG = ALLEEG(i);
        cleanraw_report(EEG, report_file);
        ica_report(EEG, report_file);
    end

    function cleanraw_report(EEG, report_file)
        %report.append_report('asrFail', 0, outpath, result_basename);
        cur_report = jsonread(report_file);
        cur_report.nGoodData = EEG.pnts;
        cur_report.goodDataPercent = 100*EEG.pnts/EEG.etc.oripnts;
        cur_report.nGoodChans = EEG.nbchan;
        cur_report.goodChansPercent = 100*EEG.nbchan/EEG.etc.orinbchan;
        jsonwrite(report_file, cur_report);
    end

    function ica_report(EEG, report_file)
        cur_report = jsonread(report_file);
        if isfield(EEG, 'icaact') && ~isempty(EEG.icaact)
            cur_report.icaFail = 0;
            rejected_ICs = sum(EEG.reject.gcompreject);
            numICs = EEG.nbchan-1;
            cur_report.nICs = numICs;
            cur_report.nGoodICs = numICs-rejected_ICs;
            cur_report.goodICA = 100*(numICs-rejected_ICs)/numICs;
        else
            cur_report.icaFail = 1;
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

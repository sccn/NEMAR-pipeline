function generate_report(dsnumber)
        function obj = Report(dspath)
            obj.dspath = dspath;
            if ~exist([dspath '/processing-log'], 'dir')
                mkdir([dspath '/processing-log']);
            end
            fid = fopen(sprintf('%s/processing-log/err.txt', dspath), 'w');
            fclose(fid);
        end % constructor

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
end

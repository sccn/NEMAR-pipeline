classdef Visualizer
    % properties (Access = public)
    %     outpath % directory containing the plots
    %     result_basename % basename of plot files
    % end

    methods (Static = true)
        function plot_raw_mid_segment(EEG, outpath, result_basename, report)
            disp('Plotting center EEG sample...');
            try
                % save EEGPLOT for 2 second segment in the middle of the recording
                % ------------
                bounds = strmatch('boundary', { EEG.event.type });
                startLat = round(length(EEG.times)/2);
                if ~isempty(bounds)
                    boundLat = [ EEG.event(bounds).latency ];
                    diffLat = diff(boundLat);
                    indLat = find(diffLat > EEG.srate*2); % 2 seconds of good data
                    if ~isempty(indLat)
                        startLat = boundLat(indLat(1));
                    end
                end
                % eegplot
                eegplot(EEG.data(:,startLat:startLat+EEG.srate*2), 'srate', EEG.srate, ...
                    'winlength', 2, 'eloc_file', EEG.chanlocs, 'noui', 'on', 'title','');
                print(gcf,'-dsvg','-noui',fullfile(outpath, [ result_basename '_eegplot_mid-sample.svg' ]));
                close
            catch ME
                report.log_error(outpath, result_basename, 'Error while plotting mid raw segment', ME, lasterror);
            end
        end

        function plot_raw_all_segment(EEG, outpath, result_basename, report)
            disp('Plotting all raw EEG...');
            try
                plot_outpath = [outpath '/' result_basename '_eegplot-all'];
                if ~exist(plot_outpath)
                    mkdir(plot_outpath);
                end
                % eegplot all segments
                startLat = 1;
                finalLat = size(EEG.data,2);
                while startLat < finalLat
                    endLat = startLat+EEG.srate*2;
                    if endLat > finalLat
                        endLat = finalLat;
                    end
                    eegplot(EEG.data(:,startLat:endLat), 'srate', EEG.srate, ...
                            'winlength', 2, 'eloc_file', EEG.chanlocs, 'noui', 'on', 'title','');

                    % print(gcf,'-dsvg','-noui',fullfile(plot_outpath, [ result_basename '_eegplot' '_lat-' num2str(startLat) '.svg' ]))
                    print(gcf,'-djpeg','-noui',fullfile(plot_outpath, [ result_basename '_eegplot' '_lat-' num2str(startLat) '.jpeg' ]))
                    close;
                    startLat = endLat;
                end
            catch ME
                report.log_error(outpath, result_basename, 'Error while plotting all raw segments', ME, lasterror)
            end
        end

        function plot_spectra(EEG, outpath, result_basename, report, varargin)
            disp('Plotting spectra...');
            try
                g = finputcheck(varargin, { 'freq'    'integer' []         [6, 10, 22, 60]; ...
                                'freqrange'   'integer'   []         [1 70]; ...
                                'percent'   'integer'    [], 10});
                % spectopo plot
                figure;
                [spec,~] = spectopo(EEG.data, 0, EEG.srate, 'freq', g.freq, 'freqrange', g.freqrange, 'title', '', 'chanlocs', EEG.chanlocs, 'percent', g.percent,'plot', 'on');
                print(gcf,'-dsvg','-noui',fullfile(EEG.filepath,[ result_basename '_spectopo.svg' ]));
                close
            catch ME
                report.log_error(outpath, result_basename, 'Error while plotting spectra', ME, lasterror);
            end
        end

        function plot_IC_activation(EEG, outpath, result_basename, report, varargin)
            disp('Plotting IC activations...');
            try
                if empty(EEG.icaweights)
                    error('No IC decomposition found for EEG')
                end

                EEG = pop_icflag(EEG,[0.75 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
                % IC activations plot
                iclocs = EEG.chanlocs;
                % trick to set plot X axis labels to be ICs instead of EEG channels
                for idx=1:numel(iclocs)
                    iclocs(idx).labels = ['IC' num2str(idx)];
                end
                figure;
                tmp = EEG.icaweights*EEG.icasphere*EEG.data(:,startLat:startLat+EEG.srate*2);
                eegplot(tmp, 'srate', EEG.srate, ...
                    'winlength', 2, 'eloc_file', iclocs, 'noui', 'on', 'title', '');
                h = findall(gcf,'-property','FontName');
                set(h,'FontName','San Serif');
                print(gcf,'-dsvg',fullfile(outpath, [ result_basename '_icaact.svg' ]))
                close
            catch ME
                report.log_error(outpath, result_basename, 'Error while plotting IC activations', ME, lasterror)
            end

        end

        function plot_ICLabel(EEG, outpath, result_basename, report, varargin)
            disp('Plotting ICLabel...');
            try
                if empty(EEG.icaweights)
                    error('No IC decomposition found for EEG')
                end
                % ICLabel plot (temp)
                figure;
                EEG.icawinv = bsxfun(@minus, EEG.icawinv, mean(EEG.icawinv,1));
                pop_viewprops( EEG, 0, [1:28], {'freqrange', [2 64]}, {}, 1, 'ICLabel', 0.51);
                print(gcf,'-dsvg','-noui',fullfile(outpath,[ result_basename '_icamaps.svg' ]))
                close
            catch ME
                report.log_error(outpath, result_basename, 'Error while plotting ICLabel', ME, lasterror)
            end
        end
    end
end
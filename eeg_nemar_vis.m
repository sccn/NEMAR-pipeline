% NEMAR visualization pipeline
% Required input:
%   EEG      - [struct]  input dataset
% Optional inputs:
%   plots - [cell]    list of measures to plot
%   logdir   - [string]  directory to log execution output
% Output:
%   EEG      - [struct]  plotted dataset
%   status   - [boolean] whether visualization was successfully generated (1) or not (0)
function [EEG, status] = eeg_nemar_vis(EEG, varargin)
    plots_all = {'midraw', 'spectra', 'icaact', 'icmap', 'icahist'};
    status = 0;
    opt = finputcheck(varargin, { ...
        'plots'          'cell'      {}                      plots_all; ...                     % visualization plots
        'logdir'         'string'    {}                      './eeg_nemar_logs'; ...
        'legacy'         'boolean'   {}                      false; ...
    }, 'eeg_nemar_vis');
    if isstr(opt), error(opt); end
    if ~exist(opt.logdir, 'dir')
        logdirstatus = mkdir(opt.logdir);
    end

    try
        which eeglab;
    catch
        warning('EEGLAB not found in path. Trying to add it from expanse...')
        addpath('/expanse/projects/nemar/eeglab');
        eeglab nogui;
    end

    EEG
    [filepath, filename, ext] = fileparts(EEG.filename);
    log_file = fullfile(opt.logdir, filename);

    diary(log_file);
    if isempty(opt.plots)
        error('No plots were requested')
    end

    if ~opt.legacy
        preprocess_status_file = fullfile(opt.logdir, [filename '_preprocess.csv']);
        % if preprocess status_file doesn't exists, we're not running visualization
        if ~exist(preprocess_status_file, 'file')
            error('Preprocess status file not found. Visualization cannot be run without preprocess.')
        end
    end

    fprintf('Generating plots for %s\n', fullfile(EEG.filepath, EEG.filename));
    status_file = fullfile(opt.logdir, [filename '_vis.csv']);
    % Always run vis pipeline from scratch
    status_tbl = array2table(zeros(1, numel(plots_all)));
    status_tbl.Properties.VariableNames = plots_all;
    writetable(status_tbl, status_file);
    disp(status_tbl)
    status = table2array(status_tbl);

    fprintf('Plots: %s\n', strjoin(opt.plots, ', '));

    splitted = split(EEG.filename(1:end-4), '_');
    modality = splitted{end};

    try
        for i=1:numel(opt.plots)
            plot = opt.plots{i};
            if strcmp(plot, 'midraw')
                plot_raw_mid_segment(EEG);
            end
                
            if strcmp(plot, 'spectra')
                plot_spectra(EEG);
            end

            if strcmp(plot, 'icaact')
                EEG.icaact = bsxfun(@rdivide, bsxfun(@minus, EEG.icaact, mean(EEG.icaact,2)), std(EEG.icaact, [], 2)); % normalize data to be same scale
                plot_IC_activation(EEG);
            end

            if strcmp(plot, 'icmap') && ~strcmp(modality, 'ieeg')
                plot_ICLabel(EEG);
            end

            if strcmp(plot, 'icahist') && ~strcmp(modality, 'ieeg')
                plot_ICLabelHistorgram(EEG);
            end

            % write status file
            status_tbl.(plot) = 1;
            writetable(status_tbl, status_file);
            status = table2array(status_tbl);
            disp(status_tbl)
        end
    catch ME
        fprintf('%s\n%s\n',ME.identifier, ME.getReport());
    end
    diary off

    function plot_raw_mid_segment(EEG)
        result_basename = EEG.filename(1:end-4); % for plots
        outpath = EEG.filepath;

        disp('Plotting center EEG sample...');
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
        data = EEG.data(:, startLat:startLat+EEG.srate*2);
        eegplot(data, 'srate', EEG.srate, ...
            'winlength', 2, 'eloc_file', EEG.chanlocs, 'noui', 'on', 'title','', 'events', EEG.event);
        print(gcf,'-dsvg','-noui',fullfile(outpath, [ result_basename '_eegplot_mid-sample.svg' ]));
        close
    end

    function plot_raw_all_segment(EEG)
        result_basename = EEG.filename(1:end-4); % for plots
        outpath = EEG.filepath;

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
                eegplot(EEG.data, 'srate', EEG.srate, ...
                        'winlength', 2, 'eloc_file', EEG.chanlocs, 'noui', 'on', 'title','', 'time', startLat/EEG.srate);

                % print(gcf,'-dsvg','-noui',fullfile(plot_outpath, [ result_basename '_eegplot' '_lat-' num2str(startLat) '.svg' ]))
                print(gcf,'-djpeg','-noui',fullfile(plot_outpath, [ result_basename '_eegplot' '_lat-' num2str(startLat) '.jpeg' ]))
                close;
                startLat = endLat;
            end
        catch ME
            report.log_error(outpath, result_basename, 'Error while plotting all raw segments', ME, lasterror)
        end
    end

    function plot_spectra(EEG, varargin)
        result_basename = EEG.filename(1:end-4); % for plots
        outpath = EEG.filepath;

        disp('Plotting spectra...');
        g = finputcheck(varargin, { 'freq'    'integer' []         [6, 10, 22]; ...
                        'freqrange'   'integer'   []         [1 70]; ...
                        'percent'   'integer'    [], 10});
	
	% average reference before plotting
        EEG = pop_reref(EEG,[], 'interpchan', []);

        % spectopo plot
        [spec, freqs] = spectopo(EEG.data, 0, EEG.srate, 'freqrange', g.freqrange, 'title', '', 'chanlocs', EEG.chanlocs, 'percent', g.percent,'plot', 'off');
        [~,ind50]=min(abs(freqs-50));
        freq_50 = sum(spec(:, ind50));
        [~,ind60]=min(abs(freqs-60));
        freq_60 = sum(spec(:, ind60));
        if freq_50 > freq_60
            selected_freqs = [g.freq 50];
        else
            selected_freqs = [g.freq 60];
        end
        figure;
        [spec,~] = spectopo(EEG.data, 0, EEG.srate, 'freq', selected_freqs, 'freqrange', g.freqrange, 'title', '', 'chanlocs', EEG.chanlocs, 'percent', g.percent,'plot', 'on');
        print(gcf,'-dsvg','-noui',fullfile(EEG.filepath,[ result_basename '_spectopo.svg' ]));
        close
    end

    % set(gcf, 'position', [0 0 2000 100], 'paperpositionmode', 'auto')
    % print(gcf,'-djpeg','-noui',fullfile(EEG.filepath,[ result_basename '_clean-sample-mask.jpeg' ]));

    function plot_IC_activation(EEG)
        result_basename = EEG.filename(1:end-4); % for plots
        outpath = EEG.filepath;

        disp('Plotting IC activations...');
        if isempty(EEG.icaweights)
            error('No IC decomposition found for EEG')
        end

	    % average reference before plotting
        EEG = pop_reref(EEG,[], 'interpchan', []);

        EEG = pop_icflag(EEG,[0.75 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
        % IC activations plot
        iclocs = EEG.chanlocs;
        % trick to set plot X axis labels to be ICs instead of EEG channels
        for idx=1:numel(iclocs)
            iclocs(idx).labels = ['IC' num2str(idx)];
        end
        figure;
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
        tmp = EEG.icaweights*EEG.icasphere*EEG.data(:, startLat:startLat+EEG.srate*2);
        tmp = tmp([1:min(35, size(EEG.icaweights,1))],:); % plot only maximally first 35 ICs
        tmp = normalize(tmp, 2); % normalize before plotting
        eegplot(tmp, 'srate', EEG.srate, ...
            'winlength', 2, 'eloc_file', iclocs([1:min(35, size(EEG.icaweights,1))]), 'noui', 'on', 'title', '');
        h = findall(gcf,'-property','FontName');
        set(h,'FontName','San Serif');
        print(gcf,'-dsvg',fullfile(outpath, [ result_basename '_icaact.svg' ]))
        close
    end

    function plot_ICLabel(EEG)
        result_basename = EEG.filename(1:end-4); % for plots
        outpath = EEG.filepath;
        disp('Plotting ICLabel...');
        if isempty(EEG.icaweights)
            error('No IC decomposition found for EEG')
        end
        % ICLabel plot (temp)
        figure;
        EEG.icawinv = bsxfun(@minus, EEG.icawinv, mean(EEG.icawinv,1));
        pop_viewprops( EEG, 0, [1:min(35, size(EEG.icaweights,1))], {'freqrange', [2 64]}, {}, 1, 'ICLabel');
        print(gcf,'-dsvg','-noui',fullfile(outpath,[ result_basename '_icamaps.svg' ]))
        close
    end

    function plot_ICLabelHistorgram(EEG)
        result_basename = EEG.filename(1:end-4); % for plots
        outpath = EEG.filepath;
        disp('Plotting ICLabel histogram...');
        if isempty(EEG.icaweights)
            error('No IC decomposition found for EEG')
        end
        figure('position', [629   759   896   578], 'color', 'w');
        colors = {[1 0 0] [0 1 0] [0 0 1] [0.5 0.5 1] [0 0.5 0.5] [0.5 0 0.5]};
        for iClass = 1:7
            subplot(2,4,iClass)
            [~,ind] = max(EEG.etc.ic_classification.ICLabel.classifications');
            indSelect = ind == iClass;
            probs = EEG.etc.ic_classification.ICLabel.classifications;
            probSelect1 = probs(indSelect, iClass);
            probSelect2 = probs(~indSelect, iClass);
            % adding up counts (should then use bar instead of hist)
            N1 = histc(probSelect1,10:10:100);
            N2 = histc(probSelect2,10:10:100);
            probSelect2(probSelect2 < 0.05) = [];
            hist2(probSelect1*100, probSelect2*100, -5:10:105);
            yl(iClass) = max(ylim);
            %, 'color', colors{iClass}
            title(EEG.etc.ic_classification.ICLabel.classes{iClass})
            ylabel('Number of components')
            xlabel('Percentage score range')
            xlim([10 100])
            if iClass == 7
                h = legend({'Selected components' 'Not selected components' });
                set(h, 'position', [0.75 0.3938 0.1618 0.0458]);
            end
        end

        for iClass = 1:7
            subplot(2,4,iClass)
        end
        print(gcf,'-dsvg','-noui',fullfile(outpath,[ result_basename '_icahist.svg' ]))
        close
    end
end
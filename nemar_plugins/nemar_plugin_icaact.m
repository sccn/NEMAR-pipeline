function [nemarFields, templateFields] = nemar_plugin_icaact(STUDY, ALLEEG)
    nemarFields = [];
    templateFields.title = 'IC activation plots';
    templateFields.extension  = '_icaact.svg';

    for i=1:numel(ALLEEG)
        EEG = pop_loadset(fullfile(ALLEEG(i).filepath, ALLEEG(i).filename));
        plot_IC_activation(EEG);
    end


    function plot_IC_activation(EEG)
        result_basename = EEG.filename(1:end-4); % for plots
        outpath = EEG.filepath;

        disp('Plotting IC activations...');
        if isempty(EEG.icaweights)
            error('No IC decomposition found for EEG')
        end

	    % average reference before plotting
        % EEG = pop_reref(EEG,[], 'interpchan', []);

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
end
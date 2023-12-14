function [nemarFields, templateFields] = nemar_plugin_midraw(STUDY, ALLEEG)
    nemarFields = [];
    templateFields.title = 'Raw segment plot';
    templateFields.extension  = '_eegplot_mid-sample.svg';

    for i=1:numel(ALLEEG)
        EEG = pop_loadset(fullfile(ALLEEG(i).filepath, ALLEEG(i).filename));
        plot_raw_mid_segment(EEG);
    end

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
end
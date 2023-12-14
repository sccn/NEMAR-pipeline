function [nemarFields, templateFields] = nemar_plugin_spectra(STUDY, ALLEEG)
    nemarFields = [];
    templateFields.title = 'Power spectrum plot';
    templateFields.extension  = '_spectopo.svg';

    for i=1:numel(ALLEEG)
        EEG = pop_loadset(fullfile(ALLEEG(i).filepath, ALLEEG(i).filename));
        plot_spectra(EEG);
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
end
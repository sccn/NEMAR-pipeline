function [status, templateFields] = nemar_plugin_spectra(EEG, modality)
    templateFields.title = 'Power spectrum plot';
    templateFields.extension  = '_spectopo.svg';

    status = 0;

    result_basename = EEG.filename(1:end-4); % for plots
    outpath = EEG.filepath;

    disp('Plotting spectra...');
    g.freq = [6, 10, 22]; 
    g.freqrange = [1 70];
    g.percent = 10;
	
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

    status = 1;
end
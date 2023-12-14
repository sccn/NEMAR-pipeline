function [nemarFields, templateFields] = nemar_plugin_iclabel(STUDY, ALLEEG)
    nemarFields = [];
    templateFields.title = 'IC Label plots';
    templateFields.extension  = '_icmaps.svg';

    for i=1:numel(ALLEEG)
        plot_ICLabel(ALLEEG(i));
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
end
function [status, templateFields] = nemar_plugin_iclabel(EEG, modality)
    templateFields.title = 'IC Label plots';
    templateFields.extension  = '_icmaps.svg';

    status = 0;

    if ~strcmp(modality, 'ieeg')
        result_basename = EEG.filename(1:end-4); % for plots
        outpath = EEG.filepath;
        disp('Plotting ICLabel...');
        if isempty(EEG.icaweights)
            error('No IC decomposition found for EEG')
        end
        EEG = pop_icflag(EEG, [NaN NaN;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
        % ICLabel plot (temp)
        figure;
        EEG.icawinv = bsxfun(@minus, EEG.icawinv, mean(EEG.icawinv,1));
        pop_viewprops( EEG, 0, [1:min(35, size(EEG.icaweights,1))], {'freqrange', [2 64]}, {}, 1, 'ICLabel');
        c = get(gcf, 'children');
        counter = 1;
        for i=numel(c)-1:-1:numel(c)-floor(numel(c)/2)
            subtitle(c(i), sprintf('IC %d', counter));
            counter = counter + 1;
        end
            
        fontname(gcf, 'Arial');
        print(gcf,'-dsvg','-noui',fullfile(outpath,[ result_basename '_icamaps.svg' ])) % not having -noui gave error
        % Printing of uicontrols is not supported on this platform.'
        close

        status = 1;
    end
end
function [status, templateFields] = nemar_plugin_iclabel_hist(EEG, modality)
    templateFields.title = 'IC Label Histogram plots';
    templateFields.extension  = '_icahist.svg';

    status = 0;
    if ~strcmp(modality, 'ieeg')
        result_basename = EEG.filename(1:end-4); % for plots
        outpath = EEG.filepath;
        disp('Plotting ICLabel histogram...');
        if isempty(EEG.icaweights)
            error('No IC decomposition found for EEG')
        end
        figure('position', [629   759   896   578], 'color', 'w');
        colors = {[1 0 0] [0 1 0] [0 0 1] [0.5 0.5 1] [0 0.5 0.5] [0.5 0 0.5]}; % change pink to gray
        % adjust ylimit, use max across plots divisible by 4 (tick marks)
        % show total number of components
        % show also components above 10% (e.g. heart for ds001785)
        for iClass = 1:7
            subplot(2,4,iClass)
            [~,ind] = max(EEG.etc.ic_classification.ICLabel.classifications');
            indSelect = ind == iClass;
            probs = EEG.etc.ic_classification.ICLabel.classifications;
            probSelect1 = probs(indSelect, iClass);
            probSelect2 = probs(~indSelect, iClass);
            % adding up counts (should then use bar instead of hist)
            N1 = histc(probSelect1,10:10:100); % enforce to be in the 10th
            N2 = histc(probSelect2,10:10:100);
            probSelect2(probSelect2 < 0.05) = [];
            hist2(probSelect1*100, probSelect2*100, -5:10:105);
            yl(iClass) = max(ylim);
            %, 'color', colors{iClass}
            title(EEG.etc.ic_classification.ICLabel.classes{iClass})
            ylabel('Numbers of components')
            xlabel('Likelihood (%)')
            xlim([10 100])
            if iClass == 7
                h = legend({'ICLabel labeled components' 'Unlabeled components (10-50%)' });
                set(h, 'position', [0.75 0.3938 0.1618 0.0458]);
            end
        end

        for iClass = 1:7
            subplot(2,4,iClass)
        end
        print(gcf,'-dsvg','-noui',fullfile(outpath,[ result_basename '_icahist.svg' ]))
        close

        status = 1;
    end
end
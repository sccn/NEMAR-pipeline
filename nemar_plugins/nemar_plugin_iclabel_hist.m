function [status, templateFields] = nemar_plugin_iclabel_hist(EEG, modality)
    templateFields.title = 'IC Label Histogram plots';
    templateFields.extension  = '_icahist.svg';

    status = 0;
    if ~strcmp(modality, 'ieeg')
        result_basename = EEG.filename(1:end-4); % for plots
        outpath = EEG.filepath;
        disp('Plotting ICLabel histogram...');
        if isempty(EEG.icaweights)
            warning('No IC decomposition found for EEG')
            return
        end
        figure('position', [629   759   896   578], 'color', 'w');
        colors = {[1 0 0] [0 1 0] [0 0 1] [0.5 0.5 1] [0 0.5 0.5] [0.5 0 0.5]}; % change pink to gray
        % adjust ylimit, use max across plots divisible by 4 (tick marks)
        % show total number of components
        % show also components above 10% (e.g. heart for ds001785)

        maxCount = 0;
        yticklabels_all = cell(7,1);
        yticks_all = cell(7,1);
        yticklabels_all_most_count = 0;
        yticklabels_all_most_count_idx = 0;
        for iClass = 1:7
            subplot(2,4,iClass)
            % ind: 1 x components, each containing the index of the class that has highest probability for that component
            % probability doesn't need to be in any range, just need to be highest for that component
            % Get the indices (from 1-7) of the class with highest likelihood for each component 
            [~,ind] = max(EEG.etc.ic_classification.ICLabel.classifications');
            indSelect = ind == iClass; % whether iClass is the class with highest prob for the component
            probs = EEG.etc.ic_classification.ICLabel.classifications; % - components x classes
            probSelect1 = probs(indSelect, iClass)*100; % components for which current class iClass have highest likelihood
            probSelect2 = probs(~indSelect, iClass)*100; % components for which current class iClass doesn't have highest likelihood

            % adding up counts (should then use bar instead of hist)
            virtual_one = 0.1;
            [prob1c, prob1c_edges] = histcounts(probSelect1, 0:10:100);
            prob1c_edges = prob1c_edges(1:end-1);
            prob1c_raw = prob1c;
            prob1clog = log10(prob1c);
            prob1clog(prob1clog == 0) = virtual_one; % log(0) = -Inf, set to 0 (log(1) = 0
            prob2c = histcounts(probSelect2, 0:10:100);
            prob2c_raw = prob2c;
            prob2clog = log10(prob2c);
            prob2clog(prob2clog == 0) = virtual_one; % log(0) = -Inf, set to 0 (log(1) = 0
            % bar(5:10:95, prob1c, 'facecolor', [0.4660 0.6740 0.1880], 'facealpha', 0.5)
            prob1clogGray = prob1clog;
            prob1clogGood = prob1clog;
            prob1clogGray(prob1c_edges >= 80) = 0;
            prob1clogGood(prob1c_edges < 80) = 0;
            bar(5:10:95, prob1clogGray, 'facecolor', [0.9290 0.6940 0.1250], 'facealpha', 0.8);
            hold on;
            bar(5:10:95, prob1clogGood, 'facecolor', [0.4660 0.6740 0.1880], 'facealpha', 0.8);
            hold on;
            % bar(5:10:95, prob2c, 'facecolor', [0.8 0.38 0.33]       , 'facealpha', 0.5)
            bar(5:10:95, prob2clog, 'facecolor', [0.8 0.38 0.33]       , 'facealpha', 0.8)
            set(gca, 'fontname', 'arial');
            set(gca, 'fontsize', 10);
            xlim([0 100])
            xticks(0:20:100)
            yticks_logs = yticks;
            if ~any(virtual_one == yticks_logs)
                yticks_logs = [yticks_logs(1) virtual_one yticks_logs(2:end)];
            end
            yticks(yticks_logs);
            yticklabels([' ' strsplit(num2str([1 round(10.^yticks_logs(3:end))]), ' ')])
            yticks_all{iClass} = yticks;
            yticklabels_all{iClass} = yticklabels;
            maxLabel = yticklabels_all{iClass};
            maxLabel = str2num(maxLabel{end});
            if yticklabels_all_most_count < maxLabel
                yticklabels_all_most_count = maxLabel;
                yticklabels_all_most_count_idx = iClass;
            end
            title(sprintf('%s (%d of %d)', EEG.etc.ic_classification.ICLabel.classes{iClass}, sum(prob1c_raw), numel(ind))); % subplot title
            if mod(iClass, 4) == 1
                ylabel('Number of components');
            else
                ylabel('');
            end
            
            xlabel('IC class likelihood (%)');
            logylim = ylim;
            if maxCount < max(logylim)
                maxCount = max(logylim);
            end
        end

        ticks = yticks_all{yticklabels_all_most_count_idx};
        labels = yticklabels_all{yticklabels_all_most_count_idx};
        for iClass = 1:7
            subplot(2,4,iClass)
            ylim([0 maxCount]);
            yticks(ticks);
            yticklabels(labels);
        end

        categories = 90:-10:50;
        pvafs = compute_pvaf(EEG, categories);
        subplot(2,4,8)
        bar(pvafs, 'BarLayout', 'stacked', 'FaceAlpha', 0.6);
        title(sprintf('%% Data var accounted for \nin each class (by likelihood)'))
        xticklabels(EEG.etc.ic_classification.ICLabel.classes)
        legend(cellfun(@(x) sprintf('%d-%d%%', x+1, x+10), num2cell(categories), 'UniformOutput', false), 'Location', 'best')
        ylabel('Percent (%)')

        print(gcf,'-dsvg','-noui',fullfile(outpath,[ result_basename '_icahist.svg' ]));
        close

        status = 1;
    end

    %% Compute percent variance accounted for 
    %  of most likely components of all ICLabel classes
    function pvafs = compute_pvaf(EEG, categories)
        pvafs = zeros(7, numel(categories));
        for iClass=1:7
            [~,ind] = max(EEG.etc.ic_classification.ICLabel.classifications'); % classes x components
            for iCat = 1:numel(categories)
                indSelect = find(ind == iClass & EEG.etc.ic_classification.ICLabel.classifications(:, iClass)' <= (categories(iCat)+10)/100 & EEG.etc.ic_classification.ICLabel.classifications(:, iClass)' > categories(iCat)/100); % whether iClass is the class with highest prob for the component
                if ~isempty(indSelect)
                    pvafs(iClass, iCat) = eeg_pvaf(EEG, indSelect, 'plot', 'off');
                end
            end
            % indSelect = find(ind == iClass); % whether iClass is the class with highest prob for the component
            % if ~isempty(indSelect)
            %     pvafs(iClass) = eeg_pvaf(EEG, indSelect, 'plot', 'off');
            % end
        end
    end
end

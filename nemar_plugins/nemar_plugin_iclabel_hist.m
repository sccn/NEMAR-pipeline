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
        for iClass = 1:7
            subplot(2,4,iClass)
            [~,ind] = max(EEG.etc.ic_classification.ICLabel.classifications');
            indSelect = ind == iClass; % whether iClass is the selected class for the components
            probs = EEG.etc.ic_classification.ICLabel.classifications;
            % EEG.etc.ic_classification.ICLabel.classifications - components x classes
            probSelect1 = probs(indSelect, iClass)*100; % labeled components
            probSelect2 = probs(~indSelect, iClass)*100; % unlabeled components

            % adding up counts (should then use bar instead of hist)
            virtual_one = 0.1;
            prob1c = histcounts(probSelect1, 0:10:100);
            prob1c_raw = prob1c;
            prob1clog = log10(prob1c);
            prob1clog(prob1clog == 0) = virtual_one; % log(0) = -Inf, set to 0 (log(1) = 0
            prob2c = histcounts(probSelect2, 0:10:100);
            prob2c_raw = prob2c;
            prob2clog = log10(prob2c);
            prob2clog(prob2clog == 0) = virtual_one; % log(0) = -Inf, set to 0 (log(1) = 0
            % bar(5:10:95, prob1c, 'facecolor', [0.4660 0.6740 0.1880], 'facealpha', 0.5)
            bar(5:10:95, prob1clog, 'facecolor', [0.4660 0.6740 0.1880], 'facealpha', 0.5)
            hold on;
            % bar(5:10:95, prob2c, 'facecolor', [0.8 0.38 0.33]       , 'facealpha', 0.5)
            bar(5:10:95, prob2clog, 'facecolor', [0.8 0.38 0.33]       , 'facealpha', 0.5)
            set(gca, 'fontname', 'arial');
            set(gca, 'fontsize', 10);
            xlim([0 100])
            xticks(0:10:100)
            yticks_logs = yticks;
            yticks_logs = [yticks_logs(1) virtual_one yticks_logs(2:end)]
            yticks(yticks_logs);
            yticklabels([' ' strsplit(num2str([1 round(10.^yticks_logs(3:end))]), ' ')])
            title(sprintf('%s (%d of %d)', EEG.etc.ic_classification.ICLabel.classes{iClass}, sum(prob1c_raw), numel(ind))); % subplot title
            if mod(iClass, 4) == 1
                ylabel('Number of components')
            else
                ylabel('')
            end
            
            xlabel('IC class likelihood (%)')
            logylim = ylim;
            if maxCount < max(logylim)
                maxCount = max(logylim);
            end
        end

        for iClass = 1:7
            subplot(2,4,iClass)
            ylim([0 maxCount])
        end
        print(gcf,'-dsvg','-noui',fullfile(outpath,[ result_basename '_icahist.svg' ]))
        close

        status = 1;
    end


    % HIST2 - draw superimposed histograms
    %
    % Usage:
    %   >> hist2(data1, data2, bins);
    %
    % Inputs:
    %   data1   - data to plot first process
    %   data2   - data to plot second process
    %
    % Optional inputs:
    %   bins    - vector of bin center
    %
    % Author: Arnaud Delorme (SCCN, UCSD)
    function hist2(data1, data2, bins);

        if nargin < 1
            help hist2;
            return;
        end
        if nargin < 3
            bins = linspace(min(min(data1), min(data2)), max(max(data1), max(data2)), 100);
        elseif length(bins) == 1
            bins = linspace(min(min(data1), min(data2)), max(max(data1), max(data2)), bins);
        end
        
        hist(data1, bins);
        hold on; hist(data2, bins);
        %figure; hist( [ measure{:,5} ], 20);
        %hold on; hist([ measure{:,2} ], 20);
        c = get(gca, 'children');
        set(gca, 'fontname', 'arial');
        numfaces = size(get(c(1), 'Vertices'),1);
        set(c(1), 'FaceVertexCData', repmat([1 0 0], [numfaces 1]), 'Cdatamapping', 'direct', 'facealpha', 0.5, 'edgecolor', 'k', 'facecolor', [0.5 0.5 0.5]);
        numfaces = size(get(c(2), 'Vertices'),1);
        set(c(2), 'FaceVertexCData', repmat([0 0 1], [numfaces 1]), 'Cdatamapping', 'direct', 'facealpha', 0.5, 'edgecolor', 'k');
        ylabel('Number of values');
        xlim([bins(1) bins(end)]);
        
        % yl = ylim;
        % xl = xlim;
        % line([xl(1) xl(1)]+(xl(2)-xl(1))/2000, yl, 'color', 'k');
        % line(xl, [yl(1) yl(1)]+(yl(2)-yl(1))/2000, 'color', 'k');
    end
    
    
    
end

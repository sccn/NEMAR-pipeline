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
        maxCount = 4*ceil(getMaxComponentCount(EEG)/4);

        for iClass = 1:7
            subplot(2,4,iClass)
            [~,ind] = max(EEG.etc.ic_classification.ICLabel.classifications');
            indSelect = ind == iClass; % whether iClass is the selected class for the components
            probs = EEG.etc.ic_classification.ICLabel.classifications;
            % EEG.etc.ic_classification.ICLabel.classifications - components x classes
            probSelect1 = probs(indSelect, iClass); % labeled components
            probSelect2 = probs(~indSelect, iClass); % unlabeled components
            
            % adding up counts (should then use bar instead of hist)
            %N1 = histc(probSelect1,10:10:100); % enforce to be in the 10th
            %N2 = histc(probSelect2,10:10:100);
            % probSelect2(probSelect2 < 0.05) = [];
            hist2(probSelect1*100, probSelect2*100, 0:10:100);
            yl(iClass) = max(ylim);
            %, 'color', colors{iClass}
            title(sprintf('%s (%d of %d)', EEG.etc.ic_classification.ICLabel.classes{iClass}, numel(probSelect1), numel(ind))); % subplot title
            if mod(iClass, 4) == 1
                ylabel('Numbers of components')
            else
                ylabel('')
            end
            
            xlabel('IC class likelihood (%)')
            xlim([0 100])
            xticks([0:10:100])
            ylim([0 maxCount])
            yticks([maxCount/4 maxCount/2 3*maxCount/4 maxCount])
            if iClass == 7
                h = legend({'Most likely class' 'Less likely class' });
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

    function maxCount = getMaxComponentCount(EEG)
        maxCount = 0;
        for iClass = 1:7
            subplot(2,4,iClass)
            [~,ind] = max(EEG.etc.ic_classification.ICLabel.classifications');
            indSelect = ind == iClass; % whether iClass is the selected class for the components
            probs = EEG.etc.ic_classification.ICLabel.classifications;
            % EEG.etc.ic_classification.ICLabel.classifications - components x classes
            probSelect1 = probs(indSelect, iClass); % labeled components
            probSelect2 = probs(~indSelect, iClass); % unlabeled components
            [prob1hist, edges] = histcounts(probSelect1*100, -5:10:105);
            [prob2hist, edges] = histcounts(probSelect2*100, -5:10:105);
            maxCount = max([maxCount max(prob1hist) max(prob2hist)]);
        end
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
        set(c(1), 'FaceVertexCData', repmat([1 0 0], [numfaces 1]), 'Cdatamapping', 'direct', 'facealpha', 0.5, 'edgecolor', 'none', 'facecolor', [0.5 0.5 0.5]);
        numfaces = size(get(c(2), 'Vertices'),1);
        set(c(2), 'FaceVertexCData', repmat([0 0 1], [numfaces 1]), 'Cdatamapping', 'direct', 'facealpha', 0.5, 'edgecolor', 'none');
        ylabel('Number of values');
        xlim([bins(1) bins(end)]);
        
        yl = ylim;
        xl = xlim;
        line([xl(1) xl(1)]+(xl(2)-xl(1))/2000, yl, 'color', 'k');
        line(xl, [yl(1) yl(1)]+(yl(2)-yl(1))/2000, 'color', 'k');
    end
    
    
    
end

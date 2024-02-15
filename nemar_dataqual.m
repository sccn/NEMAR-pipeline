function nemar_dataqual(dsnumber, STUDY, ALLEEG)
    outpath = sprintf('/expanse/projects/nemar/openneuro/processed/%s', dsnumber);
    eeglabroot = '/expanse/projects/nemar/eeglab';
    pipelineroot = fullfile(eeglabroot, 'plugins', 'NEMAR-pipeline');
    addpath(fullfile(pipelineroot,'JSONio'));
    if nargin < 2
        studyFile = fullfile(outpath, [dsnumber '.study']);
        [STUDY, ALLEEG] = pop_loadstudy(studyFile);
    end

    nGoodData = [];
    goodDataPercentRaw = [];
    nGoodChans = [];
    goodChansPercentRaw = [];
    icaFail = [];
    nICs = [];
    nGoodICs = [];
    goodICAPercentRaw = [];
    linenoise_magn = [];

    maxCount = 0;
    for i=1:numel(ALLEEG)
        EEG = ALLEEG(i);
        dataqual_path = fullfile(EEG.filepath, [EEG.filename(1:end-4) '_dataqual.json']);
        cur_report = jsonread(dataqual_path);
        
        if isfield(cur_report, 'nGoodData')
            nGoodData = [nGoodData str2num(cur_report.nGoodData)];
            [count, edges] = histcounts(nGoodData);
            %maxCount = max([maxCount max(count)]);
        end
        if isfield(cur_report, 'goodDataPercentRaw')
            goodDataPercentRaw = [goodDataPercentRaw str2num(cur_report.goodDataPercentRaw)];
            [count, edges] = histcounts(goodDataPercentRaw);
            maxCount = max([maxCount max(count)]);
        end
        if isfield(cur_report, 'nGoodChans')
            nGoodChans = [nGoodChans cur_report.nGoodChans];
            [count, edges] = histcounts(nGoodChans);
            maxCount = max([maxCount max(count)]);
        end
        if isfield(cur_report, 'goodChansPercentRaw')
            goodChansPercentRaw = [goodChansPercentRaw str2num(cur_report.goodChansPercentRaw)];
            [count, edges] = histcounts(goodChansPercentRaw);
            %maxCount = max([maxCount max(count)]);
        end
        if isfield(cur_report, 'icaFail')
            icaFail = [icaFail cur_report.icaFail];
            [count, edges] = histcounts(nICs);
            %maxCount = max([maxCount max(count)]);
        end
        if isfield(cur_report, 'nICs')
            nICs = [nICs cur_report.nICs];
            [count, edges] = histcounts(nICs);
            %maxCount = max([maxCount max(count)]);
        end
        if isfield(cur_report, 'nGoodICs')
            nGoodICs = [nGoodICs cur_report.nGoodICs];
            [count, edges] = histcounts(nGoodICs);
            %maxCount = max([maxCount max(count)]);
        end
        if isfield(cur_report, 'goodICAPercentRaw')
            goodICAPercentRaw = [goodICAPercentRaw str2num(cur_report.goodICAPercentRaw)]; 
            [count, edges] = histcounts(goodICAPercentRaw);
            maxCount = max([maxCount max(count)]);
        end
        if isfield(cur_report, 'linenoise_magn')
            linenoise_magn = [linenoise_magn str2num(cur_report.linenoise_magn(1:numel(cur_report.linenoise_magn)-2))]; 
            [count, edges] = histcounts(linenoise_magn);
            maxCount = max([maxCount max(count)]);
        end 
    end

    figure('position', [629   759   896   578], 'color', 'w');
    fontsize = 16;

    subplot(2,2,1)
    total_count = numel(ALLEEG);
    cleanraw_count = numel(goodDataPercentRaw);
    ica_count = numel(goodICAPercentRaw);
    process_status = [cleanraw_count total_count-cleanraw_count; ica_count total_count-ica_count];
    ba = bar(process_status, 'stacked');
    ba(1).FaceColor = [0 0.4470 0.7410];
    ba(2).FaceColor = [0.8500 0.3250 0.0980];
    ylim([0 total_count]);
    xlabel('Processing status');
    ylabel('Number of recordings');
    yticks([0:10:total_count total_count]);
    set(gca, 'XTickLabel',{"Data cleaning" "ICA"});
    legend({'Success' 'Failed' },'Location','southeast');
    set(gca, 'fontsize', fontsize);

    subplot(2,2,2)
    histogram(goodDataPercentRaw, linspace(0,100,10), 'FaceColor', [0 0.4470 0.7410]);
    ylim([0 maxCount]);
    xlabel('% Good recording frames');
    set(gca, 'fontsize', fontsize);

    subplot(2,2,3)
    linenoise_below_threshold = linenoise_magn(linenoise_magn<8);
    linenoise_above_threshold = linenoise_magn(linenoise_magn>8);
    if isempty(linenoise_above_threshold)
        bins = min(linenoise_below_threshold):2:max(linenoise_below_threshold);
    else
        bins = min(linenoise_below_threshold):2:max(linenoise_above_threshold);
    end
    hist2(linenoise_below_threshold, linenoise_above_threshold, bins);
    ylim([0 maxCount]);
    ylabel('Number of recordings');
    xlabel('Channel-mean line noise (dB)');
    set(gca, 'fontsize', fontsize);

    subplot(2,2,4)
    histogram(goodChansPercentRaw, linspace(0,100, 10), 'FaceColor', [0 0.4470 0.7410]);
    ylim([0 maxCount]);
    xlabel('% Good channels');
    set(gca, 'fontsize', fontsize);

    print(gcf,'-dsvg','-noui',fullfile(outpath, 'code', [ dsnumber '_histogram.svg' ]))
    print(gcf,'-dpng','-noui',fullfile(outpath, 'code', [ dsnumber '_histogram.png' ]))

    close

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
        set(c(1), 'FaceVertexCData', repmat([1 0 0], [numfaces 1]), 'Cdatamapping', 'direct', 'facealpha', 0.5, 'edgecolor', 'none', 'facecolor', [1 0 0]);
        numfaces = size(get(c(2), 'Vertices'),1);
        set(c(2), 'FaceVertexCData', repmat([0 0 1], [numfaces 1]), 'Cdatamapping', 'direct', 'facealpha', 0.5, 'edgecolor', 'none', 'facecolor', [0 0.4470 0.7410]);
        ylabel('Number of values');
        xlim([bins(1) bins(end)]);
        
        yl = ylim;
        xl = xlim;
        line([xl(1) xl(1)]+(xl(2)-xl(1))/2000, yl, 'color', 'k');
        line(xl, [yl(1) yl(1)]+(yl(2)-yl(1))/2000, 'color', 'k');
    end
end
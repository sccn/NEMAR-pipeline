function [STUDY, ALLEEG, error_code] = nemar_dataqual(dsnumber, STUDY, ALLEEG, outpath, participants_tsv)
    if nargin < 4
        outpath = sprintf('/expanse/projects/nemar/openneuro/processed/%s', dsnumber);
    end
    if nargin < 5
        participant_tsv = sprintf('/expanse/projects/nemar/openneuro/%s/participants.tsv', dsnumber);
    end
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
    check_chanlocs = [];
    error_code = 0;
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

    % generate histogram figures
    generate_figure(dsnumber, numel(ALLEEG), goodChansPercentRaw, goodDataPercentRaw, goodICAPercentRaw, linenoise_magn, maxCount);

    % update nemar.json
    nemarjson_path = fullfile(outpath, 'code', 'nemar.json');
    nemarjson = jsonread(nemarjson_path);
    if isfield(nemarjson, 'data_quality')
        nemarjson.data_quality.good_channels_lower_bound = min(nGoodChans);
        nemarjson.data_quality.good_channels_higher_bound = max(nGoodChans);
        nemarjson.data_quality.good_data_lower_bound = min(nGoodData);
        nemarjson.data_quality.good_data_higher_bound = max(nGoodData);
        nemarjson.data_quality.good_brain_ica_lower_bound = min(nGoodICs);
        nemarjson.data_quality.good_brain_ica_higher_bound = max(nGoodICs);
        nemarjson.data_quality.pipeline_n_dataset = numel(ALLEEG);
        nemarjson.data_quality.pipeline_import = numel(ALLEEG);

        preprocess_path = fullfile(outpath, 'logs', 'ind_pipeline_status.csv');
        if exist(preprocess_path, 'file') 
            status_tbl = readtable(preprocess_path);
            nemarjson.data_quality.check_import = sum(status_tbl.check_import);
            nemarjson.data_quality.check_chanloc = sum(status_tbl.check_chanloc);
        end
    end
    plot = [];
    plot.title = "Histogram of data quality measures";
    plot.extension = [dsnumber '_histogram.png'];
    nemarjson.plots = [plot];
    jsonwrite(nemarjson_path, nemarjson);    % it's collapsing the plots array right now. Not working

    function generate_figure(dsnumber, total_count, goodChansPercentRaw, goodDataPercentRaw, goodICAPercentRaw, linenoise_magn, maxCount)
        % figure('position', [629   759   896   578], 'color', 'w');
        fig = figure('position', [629   759   896   878], 'color', 'w');
        set(fig,'defaultAxesColorOrder',[[0 0 0]; [0 0 0]]);
        fontsize = 15;

        subplot(3,2,1)
        cleanraw_count = numel(goodDataPercentRaw);
        ica_count = numel(goodICAPercentRaw);
        process_status = [cleanraw_count total_count-cleanraw_count; ica_count total_count-ica_count];
        ba = bar(process_status, 'BarLayout', 'stacked', 'BarWidth', 0.4); %, 'FaceAlpha', 0.5);
        ba(1).FaceColor = [8/255, 135/255, 1/255];
        ba(2).FaceColor = [216/255, 44/255, 1/255];
        title('Pipeline success','FontWeight','Normal');
        ylabel(sprintf('Recordings (# of %d)', total_count));
        set(gca, 'XTickLabel',{sprintf("  Data\\newlinecleaning") sprintf("    ICA\\newlinedecomp")});
        legend({'Finished' 'Failed' }, 'Location', 'southeast');
        lims = ylim;
        ylim([lims(1) lims(2)+round(lims(2)/50)])
        set(gca, 'fontsize', fontsize);

        subplot(3,2,2)
        bins = 5:10:95;
        colorGood = [0.5 1 0.5]; % #088701
        colorBad = [0.5 0 0]; % #d82c01
        jetColor = jet;
        halfJet = jetColor(end:-1:129,:);
        [counts, edges] = histcounts(goodDataPercentRaw, bins)
        yyaxis right
        b = bar(edges(1:end-1), counts, 'BarWidth', 0.8, 'FaceColor', 'flat');%[0.4660 0.6740 0.1880]);
        colorsIdx = round(linspace(1,size(halfJet,1),numel(counts)));
        colorscheme = halfJet(colorsIdx, :); % interp1([0;1],[colorBad; colorGood],round(linspace(1,numel(halfJet),numel(bins))));
        colorscheme = colorscheme*0.9;
        colorscheme(colorscheme>1) = 1
        colorscheme
        colormap(colorscheme)
        colorbar('Location', 'westoutside', 'Ticks',[0, 1], 'TickLabels', {'Poor', 'Good'});
        % colorscheme = interp1([0;1],[colorBad; colorGood],linspace(0,1,numel(counts)));
        b.CData = colorscheme;
        xlim([0 100])
        xticks(0:20:100)
        limits = ylim;
        % title('Data frames','FontWeight','Normal');
        xlabel('Data frames retained (%)');
        ylabel(sprintf('Recordings (# of %d)', total_count), 'Color', 'k');

        set(gca, 'fontsize', fontsize);
        yyaxis left
        yticklabels({[]})

        subplot(3,2,3)
        bins = min(linenoise_magn):2:max(linenoise_magn);
        [counts, edges] = histcounts(linenoise_magn, bins)
        b = bar(edges(1:end-1), counts, 'BarWidth', 0.8, 'FaceColor', 'flat');%[0.4660 0.6740 0.1880]);
        colorsIdxLinenoise = round(linspace(1,size(halfJet,1),numel(counts)));
        colorschemeLinenoise = halfJet(flip(colorsIdxLinenoise), :) % interp1([0;1],[colorBad; colorGood],round(linspace(1,numel(halfJet),numel(bins))));
        colormap(colorschemeLinenoise);
        b.CData = colorschemeLinenoise;
        % title('Line noise','FontWeight','Normal');
        ylabel(sprintf('Recordings (# of %d)', total_count));
        xlabel('Line noise (channel RMS, dB)');
        set(gca, 'fontsize', fontsize);

        subplot(3,2,4)
        % chans_below_threshold = goodChansPercentRaw(goodChansPercentRaw<90);
        % chans_above_threshold = goodChansPercentRaw(goodChansPercentRaw>90);
        % max_chans = max([chans_below_threshold, chans_above_threshold]);
        bins = 5:10:95;
        [counts, edges] = histcounts(goodChansPercentRaw, bins)
        yyaxis right
        b = bar(edges(1:end-1), counts, 'BarWidth', 0.8, 'FaceColor', 'flat');%[0.4660 0.6740 0.1880]);
        % colorscheme = interp1([0;1],[colorBad; colorGood],linspace(0,1,numel(counts)));
        colormap(colorscheme);
        colorbar('Location', 'westoutside', 'Ticks',[0, 1], 'TickLabels', {'Poor', 'Good'});
        b.CData = colorscheme;
        % hist2(chans_above_threshold, chans_below_threshold, bins);
        % title('Data channels','FontWeight','Normal');
        xlabel(sprintf('Data channels retained (%%)\n  '));
        ylabel(sprintf('Recordings (# of %d)', total_count), 'Color', 'k');
        % legend({'Good' 'Problematic' },'Location','northeast');
        xlim([0 100])
        xticks(0:20:100)
        % limits = ylim
        % limits
        % yticks([1:round((limits(2)-1)/5):limits(2)])
        set(gca, 'fontsize', fontsize);

        yyaxis left
        yticklabels({[]})
        ylabel('');

        participant_ax = subplot(3,2,[5 6])
        try
            generateParticipantFig(dsnumber, participants_tsv) 
        catch ME
            warning('Failed to generate participant figure')
            fprint('Error: %s\n', ME.message)
            fprint('Stack: %s\n', ME.stack)
            error_code = 3;
            pause(3)
            delete(participant_ax)
        end
        set(gca, 'fontsize', fontsize);
        print(gcf,'-dsvg','-noui',fullfile(outpath, 'code', [ dsnumber '_histogram.svg' ]))
        print(gcf,'-dpng','-noui',fullfile(outpath, 'code', [ dsnumber '_histogram.png' ]))

        close
    end

    function res = has_file(dspath, fileext)
        res = 0;
        dsdir = dir(dspath);
        curfile = [];
        while ~isempty(dsdir)
            curfile = dsdir(1);
            dsdir(1) = [];
            if curfile.isdir 
                if ~any(strcmp(curfile.name, {'.','..'}))
                    child_dir = dir(fullfile(curfile.folder, curfile.name));
                    dsdir = [dsdir; child_dir];
                end
            else
                if endsWith(curfile.name, fileext)
                    res = 1;
                    return
                end
            end
        end
    end
    function res = has_hed(dspath)
        res = 0;
        dsdir = dir(dspath);
        curfile = [];
        while ~isempty(dsdir)
            curfile = dsdir(1);
            dsdir(1) = [];
            if curfile.isdir 
                if ~any(strcmp(curfile.name, {'.','..'}))
                    child_dir = dir(fullfile(curfile.folder, curfile.name));
                    dsdir = [dsdir; child_dir];
                end
            else
                if endsWith(curfile.name, 'events.json')
                    eventjson = jsonread(fullfile(curfile.folder, curfile.name));
                    % if any of the event key has HED. Structure format: column -> HED
                    columns = fieldnames(eventjson);
                    for c=1:numel(columns)
                        col_struct = eventjson.(columns{c});
                        if isfield(col_struct, 'HED')
                            res = 1;
                            return
                        end
                    end
                end
            end
        end
    end

    function hist2(data1, data2, bins);
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
        set(c(1), 'FaceVertexCData', repmat([1 0 0], [numfaces 1]), 'Cdatamapping', 'direct', 'edgecolor', 'k', 'facecolor',[0.64 0.13 0.08]); %[0.8500 0.3250 0.0980]); 
        numfaces = size(get(c(2), 'Vertices'),1);
        set(c(2), 'FaceVertexCData', repmat([0 0 1], [numfaces 1]), 'Cdatamapping', 'direct', 'edgecolor', 'k', 'facecolor', [0.4660 0.6740 0.1880]); 
        ylabel('Number of values');
        % xlim([bins(1) bins(end)]);
        
        % yl = ylim;
        % xl = xlim;
        % line([xl(1) xl(1)]+(xl(2)-xl(1))/2000, yl, 'color', 'k');
        % line(xl, [yl(1) yl(1)]+(yl(2)-yl(1))/2000, 'color', 'k');
    end
    function generateParticipantFig(dsnumber, participant_tsv)
        % read the participants.tsv file
        participant_tbl = readtable(participant_tsv, 'FileType', 'text', 'Delimiter', '\t');
        % get the participant_id column
        participant_id = participant_tbl.participant_id;
        % get the age column
        participant_columns = participant_tbl.Properties.VariableNames;
        participant_columns_lower = lower(participant_columns);
        if ismember('age', participant_columns_lower)
            age = participant_tbl.(participant_columns{strcmp(participant_columns_lower, 'age')})
        end
        % get the sex column
        if ismember('gender', participant_columns_lower)
            gender_col = participant_columns(strcmp(participant_columns_lower, 'gender'))
        end
        if ismember('sex', participant_columns_lower)
            gender_col = participant_columns(strcmp(participant_columns_lower, 'sex'))
        end
        gender = lower(participant_tbl.(gender_col{1}));
        if ismember('m', gender)
            age_male = age(strcmp(gender, 'm'));
            age_female = age(strcmp(gender, 'f'));
        elseif ismember('male', gender)
            age_male = age(strcmp(gender, 'male'));
            age_female = age(strcmp(gender, 'female'));
        end

        % create a figure
        gaps = 10;
        age_range = max(age) - min(age);
        age_range_increment = max(1,round(0.1*age_range))
        edges = min(age)-age_range_increment:age_range_increment:max(age)+age_range_increment %round(linspace(min(age)-1, max(age)+1, gaps))
        [~, edges] = histcounts(age, edges)
        [female_age_counts,~] = histcounts(age_female, edges)
        [male_age_counts,~] = histcounts(age_male, edges)
        % center_female = 0.5*(edges(1:end-1)+edges(2:end));
        % center_male = 0.5*(edges(1:end-1)+edges(2:end));
        % edges = round(edges)
        center = 0.5*(edges(1:end-1)+edges(2:end))
        age_hist = [male_age_counts; female_age_counts];
        b = bar(center, age_hist, 'BarLayout', 'stacked', 'BarWidth', 1);
        title({'';'Age and gender'},'FontWeight','Normal');
        b(1).FaceColor =[5/255 56/255 138/255]; % #05388a male 
        b(1).DisplayName = 'Male'; % #05388a male 
        b(2).FaceColor =[212/255 95/255 154/255]; % #D45F9A female
        b(2).DisplayName = 'Female'; % #D45F9A female

        %bar(center, male_age_counts, 'BarWidth', 0.8,'FaceColor',[0.64 0.13 0.08]); hold on; bar(center, female_age_counts, 'BarWidth', 0.8,'FaceColor', [0.4660 0.6740 0.1880]);
        xticks(edges);
        ylabel(sprintf('Subjects (# of %d)', numel(participant_id)));
        xlabel('Subject age by gender (years)')
        y = ylim;
        
        ylim([0 y(2) + ceil(y(2)*0.2)]);
        % legend({sprintf('%d Female', numel(age_female)) sprintf('%d Male', numel(age_male))});
        legend([b(2), b(1)]);
        % hist2(age_male, age_female)
    end
end

function [STUDY, ALLEEG] = nemar_dataqual(dsnumber, mergeset, STUDY, ALLEEG, outpath, participant_tsv)
    fprintf('Running nemar_dataqual\n');
    if nargin < 5
        outpath = sprintf('/expanse/projects/nemar/openneuro/processed/%s', dsnumber);
    end
    if nargin < 6
        participant_tsv = sprintf('/expanse/projects/nemar/openneuro/%s/participants.tsv', dsnumber);
    end
    eeglabroot = '/expanse/projects/nemar/eeglab';
    pipelineroot = fullfile(eeglabroot, 'plugins', 'NEMAR-pipeline');
    addpath(fullfile(pipelineroot,'JSONio'));
    if nargin < 4
        studyFile = fullfile(outpath, [dsnumber '.study']);
        [STUDY, ALLEEG] = pop_loadstudy(studyFile);
    end

    try 
        reports = [];
        maxCounts = [];

        % assume that subjects in ALLEEG are always sorted
        subjects = {ALLEEG.subject};
        cur_subject = ALLEEG(1).subject;
        total_count = 1;
        for i=2:numel(ALLEEG)
            if mergeset
                if ~strcmp(ALLEEG(i).subject, subjects{i})
                    error('Wrong subject indexing');
                end
                if ~strcmp(ALLEEG(i).subject, cur_subject)
                    total_count = total_count + 1;
                    % found a new subject, save merged dataset and process
                    filename = regexp(ALLEEG(i-1).filename, 'sub-([a-zA-Z0-9]+)', 'match');
                    filename = [filename{1} '_task-combined_eeg.set'];
                    filepath = ALLEEG(i-1).filepath;

                    EEG = pop_loadset('filename', filename, 'filepath', filepath, 'loadmode', 'info');
                    try 
                        [report, maxCount] = get_dataqual_status(EEG);
                        reports = [reports report];
                        maxCounts = [maxCounts maxCount];
                    catch ME1
                        warning('Cannot get data quality status %s', filename);
                    end

                    % load new subject
                    cur_subject = subjects{i};
                end
            else
                total_count = total_count + 1;
                EEG = ALLEEG(i);
                [report, maxCount] = get_dataqual_status(EEG);
                reports = [reports report];
                maxCounts = [maxCounts maxCount];
            end
        end

        % parse reports
        nGoodData = [reports.nGoodData]; nGoodData = nGoodData(~isnan(nGoodData));
        goodDataPercentRaw = [reports.goodDataPercentRaw]; goodDataPercentRaw = goodDataPercentRaw(~isnan(goodDataPercentRaw));
        nGoodChans = [reports.nGoodChans]; nGoodChans = nGoodChans(~isnan(nGoodChans));
        goodChansPercentRaw = [reports.goodChansPercentRaw]; goodChansPercentRaw = goodChansPercentRaw(~isnan(goodChansPercentRaw));
        icaFail = [reports.icaFail]; icaFail = icaFail(~isnan(icaFail));
        nICs = [reports.nICs]; nICs = nICs(~isnan(nICs));
        nGoodICs = [reports.nGoodICs]; nGoodICs = nGoodICs(~isnan(nGoodICs));
        goodICAPercentRaw = [reports.goodICAPercentRaw]; goodICAPercentRaw = goodICAPercentRaw(~isnan(goodICAPercentRaw));
        linenoise_magn = [reports.linenoise_magn]; linenoise_magn = linenoise_magn(~isnan(linenoise_magn));

        % generate histogram figures
        generate_figure(dsnumber, total_count, participant_tsv, goodChansPercentRaw, goodDataPercentRaw, goodICAPercentRaw, linenoise_magn, maxCount);

        % update nemar.json
        nemarjson_path = fullfile(outpath, 'code', 'nemar.json');
        nemarjson = jsonread(nemarjson_path);
        if mergeset
            nemarjson.data_quality.merged_dataset = true;
        end
        if ~isfield(nemarjson, 'data_quality')
            nemarjson.data_quality = [];
        end
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
        plot = [];
        plot.title = "Histogram of data quality measures";
        plot.extension = [dsnumber '_histogram.png'];
        nemarjson.plots = [plot];
        jsonwrite(nemarjson_path, nemarjson);    % it's collapsing the plots array right now. Not working
    catch ME
        warning('Dataset loaded but failed to generate data quality histogram')
        ME.message
        ME.stack
    end

    function [report, maxCount] = get_dataqual_status(EEG)
        dataqual_path = fullfile(EEG.filepath, [EEG.filename(1:end-4) '_dataqual.json']);
        cur_report = jsonread(dataqual_path);
        report = [];
        fields = {'nGoodData', 'goodDataPercentRaw', 'nGoodChans', 'goodChansPercentRaw', 'icaFail', 'nICs', 'nGoodICs', 'goodICAPercentRaw', 'linenoise_magn'};
        for f=1:numel(fields)
            report.(fields{f}) = nan;
        end
        maxCount = 0;
        
        if isfield(cur_report, 'nGoodData')
            report.nGoodData = str2num(cur_report.nGoodData);
        end
        if isfield(cur_report, 'goodDataPercentRaw')
            report.goodDataPercentRaw = str2num(cur_report.goodDataPercentRaw);
            [count, edges] = histcounts(report.goodDataPercentRaw);
            maxCount = max([maxCount max(count)]);
        end
        if isfield(cur_report, 'nGoodChans')
            report.nGoodChans = cur_report.nGoodChans;
            [count, edges] = histcounts(report.nGoodChans);
            maxCount = max([maxCount max(count)]);
        end
        if isfield(cur_report, 'goodChansPercentRaw')
            report.goodChansPercentRaw = str2num(cur_report.goodChansPercentRaw);
        end
        if isfield(cur_report, 'icaFail')
            report.icaFail = cur_report.icaFail;
        end
        if isfield(cur_report, 'nICs')
            report.nICs = cur_report.nICs;
        end
        if isfield(cur_report, 'nGoodICs')
            report.nGoodICs = cur_report.nGoodICs;
        end
        if isfield(cur_report, 'goodICAPercentRaw')
            report.goodICAPercentRaw = str2num(cur_report.goodICAPercentRaw);
            [count, edges] = histcounts(report.goodICAPercentRaw);
            maxCount = max([maxCount max(count)]);
        end
        if isfield(cur_report, 'linenoise_magn')
            report.linenoise_magn = str2num(cur_report.linenoise_magn(1:numel(cur_report.linenoise_magn)-2));
            [count, edges] = histcounts(report.linenoise_magn);
            maxCount = max([maxCount max(count)]);
        end 
    end

    function generate_figure(dsnumber, total_count, participant_tsv, goodChansPercentRaw, goodDataPercentRaw, goodICAPercentRaw, linenoise_magn, maxCount)
        fig = figure('position', [629   759   896   878], 'color', 'w');
        set(fig,'defaultAxesColorOrder',[[0 0 0]; [0 0 0]]);
        fontsize = 15;

        subplot(3,2,1)
        cleanraw_count = numel(goodDataPercentRaw);
        ica_count = numel(goodICAPercentRaw);
        process_status = [cleanraw_count total_count-cleanraw_count; ica_count total_count-ica_count];
        ba = bar(process_status, 'BarLayout', 'stacked', 'BarWidth', 0.4); 
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
        [counts, edges] = histcounts(goodDataPercentRaw, bins);
        yyaxis right
        b = bar(edges(1:end-1), counts, 'BarWidth', 0.8, 'FaceColor', 'flat');
        colorsIdx = round(linspace(1,size(halfJet,1),numel(counts)));
        colorscheme = halfJet(colorsIdx, :); 
        colorscheme = colorscheme*0.9;
        colorscheme(colorscheme>1) = 1;
        colormap(colorscheme);
        colorbar('Location', 'westoutside', 'Ticks',[0, 1], 'TickLabels', {'Poor', 'Good'});
        b.CData = colorscheme;
        xlim([0 100])
        xticks(0:20:100)
        limits = ylim;
        xlabel('Data frames retained (%)');
        ylabel(sprintf('Recordings (# of %d)', total_count), 'Color', 'k');

        set(gca, 'fontsize', fontsize);
        yyaxis left
        yticklabels({[]})

        subplot(3,2,3)
        bins = min(linenoise_magn):2:max(linenoise_magn);
        [counts, edges] = histcounts(linenoise_magn, bins);
        b = bar(edges(1:end-1), counts, 'BarWidth', 0.8, 'FaceColor', 'flat');
        colorsIdxLinenoise = round(linspace(1,size(halfJet,1),numel(counts)));
        colorschemeLinenoise = halfJet(flip(colorsIdxLinenoise), :); 
        colormap(colorschemeLinenoise);
        b.CData = colorschemeLinenoise;
        ylabel(sprintf('Recordings (# of %d)', total_count));
        xlabel('Line noise (channel RMS, dB)');
        set(gca, 'fontsize', fontsize);

        subplot(3,2,4)
        bins = 5:10:95;
        [counts, edges] = histcounts(goodChansPercentRaw, bins);
        yyaxis right
        b = bar(edges(1:end-1), counts, 'BarWidth', 0.8, 'FaceColor', 'flat');
        colormap(colorscheme);
        colorbar('Location', 'westoutside', 'Ticks',[0, 1], 'TickLabels', {'Poor', 'Good'});
        b.CData = colorscheme;
        xlabel(sprintf('Data channels retained (%%)\n  '));
        ylabel(sprintf('Recordings (# of %d)', total_count), 'Color', 'k');
        xlim([0 100])
        xticks(0:20:100)
        set(gca, 'fontsize', fontsize);

        yyaxis left
        yticklabels({[]})
        ylabel('');

        participant_ax = subplot(3,2,[5 6]);
        try
            generateParticipantFig(participant_tsv);
        catch ME
            warning('Failed to generate participant figure')
            ME.message
            ME.stack
            delete(participant_ax)
        end
        set(gca, 'fontsize', fontsize);
        print(gcf,'-dsvg','-noui',fullfile(outpath, 'code', [ dsnumber '_histogram.svg' ]))
        print(gcf,'-dpng','-noui',fullfile(outpath, 'code', [ dsnumber '_histogram.png' ]))

        close
    end

    function generateParticipantFig(participant_tsv)
        % read the participants.tsv file
        participant_tbl = readtable(participant_tsv, 'FileType', 'text', 'Delimiter', '\t');
        % get the participant_id column
        participant_id = participant_tbl.participant_id;
        % get the age column
        participant_columns = participant_tbl.Properties.VariableNames;
        participant_columns_lower = lower(participant_columns);
        if ismember('age', participant_columns_lower)
            age = participant_tbl.(participant_columns{strcmp(participant_columns_lower, 'age')});
        end
        % get the sex column
        if ismember('gender', participant_columns_lower)
            gender_col = participant_columns(strcmp(participant_columns_lower, 'gender'));
        end
        if ismember('sex', participant_columns_lower)
            gender_col = participant_columns(strcmp(participant_columns_lower, 'sex'));
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
        age_range_increment = max(1,round(0.1*age_range));
        edges = min(age)-age_range_increment:age_range_increment:max(age)+age_range_increment; 
        [~, edges] = histcounts(age, edges);
        [female_age_counts,~] = histcounts(age_female, edges);
        [male_age_counts,~] = histcounts(age_male, edges);
        center = 0.5*(edges(1:end-1)+edges(2:end));
        age_hist = [male_age_counts; female_age_counts];
        b = bar(center, age_hist, 'BarLayout', 'stacked', 'BarWidth', 1);
        title({'';'Age and gender'},'FontWeight','Normal');
        b(1).FaceColor =[5/255 56/255 138/255]; % #05388a male 
        b(1).DisplayName = 'Male'; % #05388a male 
        b(2).FaceColor =[212/255 95/255 154/255]; % #D45F9A female
        b(2).DisplayName = 'Female'; % #D45F9A female

        xticks(edges);
        ylabel(sprintf('Subjects (# of %d)', numel(participant_id)));
        xlabel('Subject age by gender (years)');
        y = ylim;
        
        ylim([0 y(2) + ceil(y(2)*0.2)]);
        legend([b(2), b(1)]);
    end
end

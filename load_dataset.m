function [STUDY, ALLEEG, dsname] = load_dataset(filepath, outpath, root_path)
    % set up EEGLAB environment
    addpath(root_path);
    load_eeglab(root_path);
    modeval = 'read';

    % set up output path
    [root_dir,dsname] = fileparts(filepath);
    if ~isempty(outpath)
        outputDir = fullfile(outpath, dsname);
    else
        outputDir = fullfile(root_dir, 'processed', dsname);
    end
    disp(['outputdir ' outputDir]);
    disp(['inputdir ' filepath]);

    % read or import data
    %pop_editoptions( 'option_storedisk', 1);
    useBidsChans = { 'ds002718' 'ds003190' 'ds002578' 'ds002887' 'ds003004' 'ds002833' 'ds002691' 'ds002791' 'ds001787' 'ds003474', 'ds003645' };
    studyFile = fullfile(outputDir, [dsname '.study']);
    if ~exist(studyFile, 'file') || strcmpi(modeval, 'import')
        if ismember(dsname, useBidsChans), bidsChan = 'on'; else bidsChan = 'off'; end
        disp(['bidsChan ' bidsChan]);
        [STUDY, ALLEEG] = pop_importbids(filepath, 'bidsevent','off','bidschanloc', bidsChan,'studyName',dsname,'outputdir', outputDir);
    else
        tic
        [STUDY, ALLEEG] = pop_loadstudy(studyFile);
    end
    if any([ ALLEEG.trials ] > 1)
        disp('Cannot process data epochs');
    end
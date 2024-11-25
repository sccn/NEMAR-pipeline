addpath('/home/dtyoung/NEMAR-pipeline')
addpath('/expanse/projects/nemar/eeglab')
eeglab nogui;

dsfolders = {'ds001785','ds001787','ds001810','ds001849','ds001971','ds002034','ds002094','ds002158','ds002218','ds002680','ds002691','ds002718','ds002720','ds002721','ds002722','ds002723','ds002724','ds002725','ds002778','ds002814','ds002893','ds003039','ds003061','ds003190','ds003194','ds003195','ds003343','ds003458','ds003474','ds003478','ds003506','ds003516','ds003517','ds003518','ds003519','ds003522','ds003523','ds003570','ds003574','ds003620','ds003626','ds003638','ds003645','ds003655','ds003670','ds003690','ds003702','ds003710','ds003739','ds003751','ds003753','ds003768','ds003774','ds003800','ds003801','ds003822','ds003825','ds003838','ds003885','ds003887','ds003944','ds004010','ds004015','ds004018','ds004019','ds004022','ds004033','ds004040','ds004043','ds004075','ds004105','ds004117','ds004121','ds004122','ds004147','ds004148','ds004151','ds004152','ds004196','ds004200','ds004252','ds004262','ds004264','ds004295','ds004315','ds004317','ds004324','ds004346','ds004347','ds004350','ds004357','ds004367','ds004369','ds004381','ds004457','ds004502','ds004504','ds004505','ds004515','ds004532','ds004572','ds004574','ds004577','ds004579','ds004580','ds004584','ds004588','ds004595','ds004657','ds004660','ds004752','ds004840','ds005170'};
failed_ds = {};
failed_participants = {};
for i=1:numel(dsfolders)
    dsnumber = dsfolders{i};
    fprintf('Processing %s\n', dsnumber);

    try
        [~, ~, error_code] = nemar_dataqual(dsnumber);
        if error_code == 3
            failed_participants = [failed_participants dsnumber];
        end
    catch ME
        failed_ds = [failed_ds dsnumber];
        
        fprintf('%s\n', ME.identifier);
        fprintf('%s\n', ME.message);
        fprintf('%s\n', ME.getReport());
    end
end

% integer error {'ds003039', 'ds004346', 'ds004252', 'ds004033', 'ds004022'
%{
MATLAB:histcounts:expectedInteger
Expected input number 2, m, to be integer-valued.
Error using histcounts
Expected input number 2, m, to be integer-valued.

Error in histcounts (line 139)
            validateattributes(in,{'numeric','logical'},{'integer', 'positive'}, ...

Error in nemar_dataqual/generate_figure (line 156)
        [counts, edges] = histcounts(linenoise_magn, bins)

Error in nemar_dataqual (line 76)
    generate_figure(dsnumber, numel(ALLEEG), goodChansPercentRaw, goodDataPercentRaw, goodICAPercentRaw, linenoise_magn, maxCount);

Error in process_all_dataqual (line 14)
        nemar_dataqual(dsnumber);
%}

% ds002722: sub-07_task-run4_eeg_dataqual.json not exist
% Could not open file /expanse/projects/nemar/openneuro/processed/ds003702/sub-01/eeg/sub-01_task-SocialMemoryCuing_eeg_dataqual.json. No such file or directory.
% Could not open file /expanse/projects/nemar/openneuro/processed/ds004657/sub-003/ses-SCMM/eeg/sub-003_ses-SCMM_task-Drive_eeg_dataqual.json. No such file or directory.
% Could not open file /expanse/projects/nemar/openneuro/processed/ds004579/sub-075/eeg/sub-075_task-IntervalTiming_eeg_dataqual.json. No such file or directory.
% Could not open file /expanse/projects/nemar/openneuro/processed/ds004572/sub-18/ses-01/eeg/sub-18_ses-01_task-experience1_eeg_dataqual.json. No such file or directory.
% Could not open file /expanse/projects/nemar/openneuro/processed/ds004532/sub-001/ses-01/eeg/sub-001_ses-01_task-PST_eeg_dataqual.json. No such file or directory.
% Could not open file /expanse/projects/nemar/openneuro/processed/ds004502/sub-040/eeg/sub-040_task-attexp_eeg_dataqual.json. No such file or directory.
% Could not open file /expanse/projects/nemar/openneuro/processed/ds004367/sub-S01/eeg/sub-S01_task-rdk_eeg_dataqual.json. No such file or directory.
% Could not open file /expanse/projects/nemar/openneuro/processed/ds004350/sub-3/ses-1/eeg/sub-3_ses-1_task-LG_eeg_dataqual.json. No such file or directory.
% Could not open file /expanse/projects/nemar/openneuro/processed/ds004075/sub-25/eeg/sub-25_task-context11_run-07_eeg_dataqual.json. No such file or directory.
% Could not open file /expanse/projects/nemar/openneuro/processed/ds003944/sub-2017/eeg/sub-2017_task-Rest_eeg_dataqual.json. No such file or directory.
% Could not open file /expanse/projects/nemar/openneuro/processed/ds003838/sub-087/eeg/sub-087_task-memory_eeg_dataqual.json. No such file or directory.
% Could not open file /expanse/projects/nemar/openneuro/processed/ds003825/sub-48/eeg/sub-48_task-rsvp_eeg_dataqual.json. No such file or directory.

% good ones {'ds004504', 'ds002158'
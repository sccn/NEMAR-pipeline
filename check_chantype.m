% addpath('/expanse/projects/nemar/eeglab');
% eeglab nogui;
addpath('JSONio');

folders = dir('/expanse/projects/nemar/openneuro/processed');
dsnumbers = {"ds004043","ds004368","ds003374","ds004284","ds004738","ds002094","ds000117","ds004120","ds004119","ds004194","ds004264","ds004215","ds004446","ds004505","ds002885","ds004019","ds003944","ds004279","ds004346","ds004572","ds004696","ds004745","ds004460","ds004447","ds004295","ds004107","ds004502","ds003004","ds003104","ds004015","ds002712","ds004444","ds003751","ds004475","ds004563","ds002158","ds004483","ds004624","ds004278","ds003774","ds004356","ds004123","ds004369","ds004381","ds002338","ds004022","ds003838","ds004752","ds003947","ds004229","ds004477","ds001785","ds003766","ds004276","ds002718","ds003352","ds003626","ds002691","ds003645","ds004551","ds001784","ds003922","ds004306","ds004642","ds004100","ds002761","ds003844","ds004706","ds004252","ds004448","ds003602","ds003380","ds004080","ds004324","ds003887","ds003775","ds004106","ds003688","ds002721","ds004395","ds003483","ds003885","ds004657","ds003498","ds003708","ds002001","ds004067","ds003078","ds003029","ds001810"};
% for i=1:numel(folders)
%     if folders(i).isdir && startsWith(folders(i).name, 'ds')
for i=1:numel(dsnumbers)
        % dsfolder = fullfile(folders(i).folder, folders(i).name);
        % dsnumber = folders(i).name;
        dsnumber = dsnumbers{i};
        dsfolder = fullfile('/expanse/projects/nemar/openneuro/processed', dsnumber);
        fprintf('Processing %s\n', dsnumber);

        % find first .set file in the folder recursively
        setfiles = dir(fullfile(dsfolder, '**', '*.set'));
        if numel(setfiles) == 0
            fprintf('No .set files found in %s\n', dsfolder);
            continue
        end
        setfile = fullfile(setfiles(1).folder, setfiles(1).name);
        EEG = pop_loadset(setfile);
        % {EEG.chanlocs.labels}

        chan_1020 = {'Fp1', 'Fpz', 'Fp2', 'Nz', 'AF9', 'AF7', 'AF3', 'AFz', 'AF4', 'AF8', 'AF10', 'F9', 'F7', 'F5', 'F3', 'F1', 'Fz', 'F2', 'F4', 'F6', 'F8', 'F10', 'FT9', 'FT7', 'FC5', 'FC3', 'FC1', 'FCz', 'FC2', 'FC4', 'FC6', 'FT8', 'FT10', 'T9', 'T7', 'Cz', 'T8', 'T10', 'TP9', 'TP7', 'CP5', 'CP3', 'CP1', 'CPz', 'CP2', 'CP4', 'CP6', 'TP8', 'TP10', 'P9', 'P7', 'P5', 'P3', 'P1', 'Pz', 'P2', 'P4', 'P6', 'P8', 'P10', 'PO9', 'PO7', 'PO3', 'POz', 'PO4', 'PO8', 'PO10', 'O1', 'Oz', 'O2', 'O9', 'O10', 'CB1', 'CB2', 'Iz'};
        for c=1:numel(EEG.chanlocs)
            % EEG.chanlocs(c).labels
            % any(strcmp(EEG.chanlocs(c).labels, chan_1020))

            if any(strcmp(EEG.chanlocs(c).labels, chan_1020))
                fprintf('Channel %s in 10-20 system\n\n', EEG.chanlocs(c).labels);
                nemar_json = ['/expanse/projects/nemar/openneuro/processed/nemar_json_temp/' char(dsnumber) '_nemar.json'];
                curjsondata = jsonread(nemar_json);
                curjsondata.channelsystem = '10-20';
                jsonwrite(nemar_json, curjsondata);
                break
            end
        end
    % end
end
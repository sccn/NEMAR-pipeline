function jobid = eeg_create_and_submit_job(dsnumber, filepath, varargin)
    path = ['/expanse/projects/nemar/openneuro/processed/logs/' dsnumber];
    if ~exist(path, 'dir')
        mkdir(path);
    end
    [~, filename, ~] = fileparts(filepath);
    sbatchfile = fullfile(path, [filename '_sbatch']);
    fid = fopen(sbatchfile, 'w');
    fprintf(fid,'#!/bin/bash\n');
    fprintf(fid,"#SBATCH -J %s\n", dsnumber);
    fprintf(fid,"#SBATCH --partition=shared\n");
    fprintf(fid,"#SBATCH --nodes=1\n");
    fprintf(fid,"#SBATCH --mem=32G\n");
    fprintf(fid,"#SBATCH -o %s/%s.out\n", path, filename);
    fprintf(fid,"#SBATCH -e %s/%s.err\n", path, filename);
    fprintf(fid,"#SBATCH -t 10:00:00\n");
    fprintf(fid,"#SBATCH --account=csd403\n");
    fprintf(fid,"#SBATCH --no-requeue\n");
    fprintf(fid,"#SBATCH --cpus-per-task=8\n");
    fprintf(fid,"#SBATCH --ntasks-per-node=1\n\n");

    fprintf(fid,"cd /home/dtyoung/NEMAR-pipeline\n");
    fprintf(fid,"module load matlab/2022b\n");
    fprintf(fid,'matlab -nodisplay -r "eeg_run_pipeline(''%s'', ''%s''', dsnumber, filepath);

    % add optional arguments
    if length(varargin) == 0
        fprintf(fid, '); exit;"\n');
    else
        fprintf(fid, ',');
        for i = 1:length(varargin)-1
            if islogical(varargin{i}) || isnumeric(varargin{i})
                fprintf(fid, '%d,', varargin{i});
            else
                fprintf(fid, '''%s'',', varargin{i});
            end
        end
        if islogical(varargin{end}) || isnumeric(varargin{end})
            fprintf(fid, '%d); exit;"\n', varargin{end});
        else
            fprintf(fid, '''%s''); exit;"\n', varargin{end});
        end
    end
    fclose(fid);

    [status, msg] = system(sprintf('sbatch %s', sbatchfile));
    if status == 0
        jobid = regexp(msg, '\d+', 'match');
        if length(jobid) == 1
            jobid = jobid{1};
        else
            jobid = "-1";
        end
    else
        jobid = "-1";
    end
end

import os
import pandas as pd
import subprocess
def scan_new_dataset_and_run():
    current_ds = pd.read_csv('pipeline_status_all.csv')
    current_ds = set(current_ds['dsnumber'])
    count = 0
    for f in os.listdir('/expanse/projects/nemar/openneuro'):
        if f.startswith('ds') and os.path.isdir(f'/expanse/projects/nemar/openneuro/{f}') and f not in current_ds:
            if count == 5:
                return
            print(f)
            result = subprocess.run(f'sbatch ds_create_and_submit_job_sbatch {f}', shell=True, capture_output=False, text=True)
            count += 1

    return 

if __name__ == "__main__":
    scan_new_dataset_and_run()
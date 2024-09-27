#!/expanse/projects/nemar/eeglab/plugins/NEMAR-pipeline/.conda/envs/web-scrapping/bin/python

import os
import pandas as pd
import subprocess
import argparse

def scan_new_dataset_and_run(datasets:str=''):
    if datasets:
        try:
            dsnumbers = datasets.split(',')
            for f in dsnumbers:
                result = subprocess.run(f'sbatch ds_create_and_submit_job_sbatch {f}', shell=True, capture_output=False, text=True)
        except:
            print('Error parsing dataset string.')
    else:
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

def main():
    # Create the argument parser
    parser = argparse.ArgumentParser(description="A simple example of parsing command line arguments")

    # Add arguments
    parser.add_argument('-ds', '--dataset', type=str, help='(Comma-separated list of) dataset to run pipeline on', required=False)
    
    # Parse the arguments
    args = parser.parse_args()

    scan_new_dataset_and_run(args.dataset)

if __name__ == "__main__":
    main()
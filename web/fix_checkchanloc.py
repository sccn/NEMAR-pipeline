#!/data/qumulo/dtyoung/NEMAR-pipeline/.conda/envs/web-scrapping/bin/python
#!/expanse/projects/nemar/dtyoung/NEMAR-pipeline/.conda/envs/web-scrapping/bin/python
import numpy as np
import pandas as pd
import os
import datetime
import argparse
import subprocess
import re
raw_dir = "/data/qumulo/openneuro"
processed_dir = "/data/qumulo/openneuro/processed"
sccn_dir = "/var/local/www/eeglab/NEMAR"
final_file = os.path.join(sccn_dir,"pipeline_status_all.csv") #"/data/qumulo/openneuro/processed/logs/pipeline_status_all.csv" #"/expanse/projects/nemar/dtyoung/NEMAR-pipeline/temp/processed/pipeline_status_all.csv"
final_file_html = os.path.join(sccn_dir,"pipeline_status_all.html") #"/data/qumulo/openneuro/processed/logs/pipeline_status_all.html" 
check_processing_flag = False
def get_processing_ds():
    result = subprocess.run(["ssh", "dtyoung@login.expanse.sdsc.edu", "squeue -u dtyoung | grep ds00*"], 
                        shell=False,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                        check=False)

    result = result.stdout
    pattern = rb"ds00\d{4}"
    matches = re.findall(pattern, result)
    return matches
    
def aggregate_ind_status(dsnumber):
    log_dir = os.path.join(processed_dir, dsnumber, 'logs', 'eeg_logs')
    frames = []
    # so we also append the viz and dataqual columns to the ind df
    all_cols = ['set_file', 'check_chanloc', 'remove_chan', 'cleanraw', 'avg_ref', 'runica', 'iclabel', 'midraw', 'spectra', 'icaact', 'icmap', 'dataqual']
    # print(log_dir)
    # print(os.path.exists(log_dir))
    if os.path.exists(log_dir):
        for f in os.listdir(log_dir):
            if f.endswith('preprocess.csv'): # get unique files
                df_preprocess = pd.read_csv(os.path.join(log_dir, f))
                if 'check_chanloc' in df_preprocess and df_preprocess['avg_ref'][0] == 1 and df_preprocess['check_chanloc'][0] == 0:
                    df_preprocess['check_chanloc'] = 1
                    with open(os.path.join(log_dir, f), 'w') as fout:
                        df_preprocess.to_csv(fout, index=False)



def get_pipeline_status(dsnumbers):
    if check_processing_flag:
        processing = get_processing_ds()
        processing = list(set([ds.decode('utf-8') for ds in processing]))
    else:
        processing = []
    if dsnumbers:
        all_status = pd.read_csv(final_file)
        for ds in dsnumbers:
            # print(f'processing {ds}')
            # aggregate ind status files (new setup)
            aggregate_ind_status(ds)
    else:
        for f in os.listdir(processed_dir):
            if f.startswith('ds'):
                print(f'processing {f}')

                # aggregate ind status files (new setup)
                aggregate_ind_status(f)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Aggregating NEMAR pipeline status files"
    )
    parser.add_argument(
        "--ds",
        help="Comma-separated, non whitespace list of datasets to regenerate",
        default=None
    )
    args = parser.parse_args()

    final_df = get_pipeline_status(args.ds.split(',') if args.ds else None)

#!/data/qumulo/dtyoung/NEMAR-pipeline/.conda/envs/web-scrapping/bin/python
#!/expanse/projects/nemar/dtyoung/NEMAR-pipeline/.conda/envs/web-scrapping/bin/python
import numpy as np
import pandas as pd
import os
import sys
import argparse
import subprocess
import re
from nemarapi.database import NEMARAPI

raw_dir = "/data/qumulo/openneuro"
processed_dir = "/data/qumulo/openneuro/processed"
sccn_dir = "/var/local/www/eeglab/NEMAR"
final_file = os.path.join(sccn_dir,"pipeline_status_all.csv") #"/data/qumulo/openneuro/processed/logs/pipeline_status_all.csv" #"/expanse/projects/nemar/dtyoung/NEMAR-pipeline/temp/processed/pipeline_status_all.csv"
final_file_html = os.path.join(sccn_dir,"pipeline_status_all.html") #"/data/qumulo/openneuro/processed/logs/pipeline_status_all.html" 
nemar_api = NEMARAPI()
check_processing_flag = False
try:
    logfile = open(os.path.join(sccn_dir,'log_database.txt'),'w')
except OSError:
    logfile = sys.stdout
print(logfile)

def check_status(df):
    '''
    Check if at least 80% of dataset has been processed
    '''
    status = []
    for (columnName, series) in df.items():
        if columnName not in ["manual_debug_note", "debug_note"] and isinstance(series[0], str):
            counts = series[0].split('/')
            if len(counts) == 2:
                status.append(int(counts[0]) / int(counts[1]))
    return all(np.array(status) > 0.8)
                

def update_database_status(df):
    '''
    Append custom columns to dataframe
    '''
    if len(df) > 1:
        raise ValueError('More than one dataset being processed')
    path = os.path.join(processed_dir, df['dsnumber'][0])
    notes = ""
    if os.path.isdir(path):
        if check_status(df):
            notes = "ok"
            nemar_api.update_ds_status(df['dsnumber'][0], {'has_viz':1})
        else:
            nemar_api.update_ds_status(df['dsnumber'][0], {'has_viz':0})
    return df
    
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
                # initialize
                df = pd.DataFrame()
                for col in all_cols:
                    if col == 'set_file':
                        df['set_file'] = [f.split('.')[0][:-len('_preprocess')]]
                    else:
                        df[col] = [0] # TODO might be string

                # populate data from log files
                df_preprocess = pd.read_csv(os.path.join(log_dir, f))
                for colname, val in df_preprocess.items():
                    if colname in df:
                        df[colname] = val[0]

                # hack fix to make backward compatible
                if 'check_chanloc' not in df_preprocess:
                    if df['avg_ref'][0] == 1:
                        df['check_chanloc'] = 1
                
                vis_status_file = os.path.join(log_dir, f[:-len('preprocess.csv')]+'vis.csv')
                if os.path.exists(vis_status_file):
                    df_vis = pd.read_csv(vis_status_file)
                    for colname, val in df_vis.items():
                        if colname in df:
                            df[colname] = val[0]

                dataqual_status_file = os.path.join(log_dir, f[:-len('preprocess.csv')]+'dataqual.csv')
                if os.path.exists(dataqual_status_file):
                    df_dataqual = pd.read_csv(dataqual_status_file)
                    for colname, val in df_dataqual.items():
                        if colname in df:
                            df[colname] = val[0]
                frames.append(df)
    if len(frames) > 0:
        all_status = pd.concat(frames)
        with open(os.path.join(processed_dir, dsnumber, 'logs', 'ind_pipeline_status.csv'), 'w') as out:
            all_status.to_csv(out, index=False)
        
        aggregated = all_status.sum()
        final_status_df = frames[0].copy()
        final_status_df = final_status_df.drop(columns=['set_file'])
        final_status_df.insert(0, 'dsnumber', dsnumber)
        final_status_df.insert(1, 'imported', 1 if aggregated['remove_chan'] > 0 else 0) # if start preprocessing, import must have been successful

        nsetfiles = len(all_status)
        for (col, val) in aggregated.items():
            if col != 'dsnumber' and col != 'imported' and col != 'set_file':
                final_status_df[col] = f'{int(val)}/{nsetfiles}'
        with open(os.path.join(processed_dir, dsnumber, 'logs', 'pipeline_status.csv'), 'w') as out:
            final_status_df.to_csv(out, index=False)
        # print(final_status_df)
        return final_status_df


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
            df_new = pd.read_csv(os.path.join(processed_dir, ds, 'logs', 'pipeline_status.csv'))
            df = all_status[all_status["dsnumber"] == ds].copy() 
            for col, _ in df.items():
                if col in df_new:
                    df[col] = df_new[col][0]
            df.index = [0]
            df = update_database_status(df)
            all_status.loc[all_status["dsnumber"] == ds] = df.to_numpy()
        return all_status
    else:
        frames = []
        for f in os.listdir(processed_dir):
            if f.startswith('ds'):
                logfile.write(f'processing {f}\n')
                # print(f'processing {f}')

                # aggregate ind status files (new setup)
                aggregate_ind_status(f)

                path = os.path.join(processed_dir, f)
                if os.path.isdir(path):
                    status_file = os.path.join(path, "logs", "pipeline_status.csv")
                    if os.path.isfile(status_file):
                        df = pd.read_csv(status_file)
                        df = update_database_status(df)
                        frames.append(df)

        all_status = pd.concat(frames)
        return all_status

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Check for pipeline compeletion and update nemar database"
    )
    parser.add_argument(
        "--ds",
        help="Comma-separated, non whitespace list of datasets to regenerate",
        default=None
    )
    args = parser.parse_args()

    final_df = get_pipeline_status(args.ds.split(',') if args.ds else None)

    logfile.close()
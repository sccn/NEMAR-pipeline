#!/data/qumulo/eeglab/plugins/NEMAR-pipeline/.conda/envs/web-scrapping/bin/python
#!/expanse/projects/nemar/eeglab/plugins/NEMAR-pipeline/.conda/envs/web-scrapping/bin/python
import numpy as np
import pandas as pd
import os
import sys
import datetime
import argparse
import subprocess
import re
import json

raw_dir = "/data/qumulo/openneuro"
processed_dir = "/data/qumulo/openneuro/processed"
sccn_dir = "/var/local/www/eeglab/NEMAR-pipeline/web"
final_file = os.path.join(sccn_dir,"pipeline_status_plugins_all.csv") #"/data/qumulo/openneuro/processed/logs/pipeline_status_all.csv" #"/expanse/projects/nemar/dtyoung/NEMAR-pipeline/temp/processed/pipeline_status_all.csv"
final_file_html = os.path.join(sccn_dir,"pipeline_status_plugins_all.html") #"/data/qumulo/openneuro/processed/logs/pipeline_status_all.html" 
manual_note_dir = "/var/local/www/eeglab/NEMAR-pipeline/web/manual_notes"
check_processing_flag = False
try:
    logfile = open(os.path.join(sccn_dir,'log.txt'),'w')
except OSError:
    logfile = sys.stdout

def write_nemar_json(df, is_processed, latest_date):
    note = ""
    path = os.path.join(processed_dir, df['dsnumber'][0]) 
    code_dir = path + '/code'
    if not os.path.exists(code_dir):
        os.mkdir(code_dir)
        try:
            # os.chmod(code_dir, 0o774) # add write permission to group
            completed = subprocess.run(['chmod', '-R 776', code_dir], capture_output=True)
            # os.system(f'chmod -R 776 {code_dir}') # add write permission to group
        except:
            note = f'Cannot change permission for code dir'

    status = {
        "error": "",
        "warning": "",
        "has_visualization": None,
        "latest_date": latest_date,
        "dataset_version": ""
    }
    status_file = code_dir + "/nemar.json"
    if os.path.exists(status_file):
        try:
            with open(status_file, 'r') as fin:
                status = json.load(fin)
        except:
            note += "\n" + f'Issue loading nemar.json'

    status["has_visualization"] = is_processed
    status["latest_date"] = latest_date
    try:
        with open(status_file, 'w') as fout:
            json.dump(status, fout, indent=4)
    except:
        note += "\n" + f'Cannot update nemar.json'
    try:
        # os.chmod(status_file, 0o664) # add write permission to group
        # os.system(f'chmod -R 776 {status_file}') # add write permission to group
        completed = subprocess.run(['chmod', '-R 776', status_file], capture_output=True)
    except:
        note += "\n" + f'Cannot change permission for nemar.json'
    return note

def append_debug(df, processing):
    '''
    Append debug note to dataframe
    '''
    if len(df) > 1:
        raise ValueError('More than one dataset being processed')
    path = os.path.join(processed_dir, df['dsnumber'][0])
    if not os.path.exists(os.path.join(path, 'logs', 'debug')):
        os.mkdir(os.path.join(path, 'logs', 'debug'))
        try:
            # os.system(f'chgrp -R nemar {os.path.join(path, "logs", "debug")}')
            # os.system(f'chmod -R 775 {os.path.join(path, "logs", "debug")}')
            completed = subprocess.run(['chgrp', '-R nemar', os.path.join(path, "logs", "debug")], capture_output=True)
            completed = subprocess.run(['chmod', '-R 776', os.path.join(path, "logs", "debug")], capture_output=True)
        except:
            print(f'Cannot change permission for debug logs')
            
    notes = ""
    if os.path.isdir(path):
        if check_status(df):
            notes = "ok"
        else:
            # get debug note
            debug_note = os.path.join(path, "logs", "debug", "debug_note")
            with open(debug_note, 'w') as file:
                if df['dsnumber'][0] in processing:
                    notes = "processing" 
                else:
                    # put in default note for known issues
                    matlab_log = os.path.join(path, "logs", "matlab_log")
                    batcherr_log = os.path.join(processed_dir, "logs", df['dsnumber'][0] + ".err")
                    # notes = get_known_errors(matlab_log, batcherr_log) # No need to get known_errors anymore because there's no central log file 
                file.write(notes)
            try:
                completed = subprocess.run(['chmod', '-R 776', debug_note], capture_output=True)
                # os.system(f'chmod -R 776 {debug_note}') # add write permission to group
                # os.chmod(debug_note, 0o664) # add write permission to group
            except:
                print(f'Cannot change permission for {debug_note}')

        df['debug_note'] = notes

        # manual debug note
        manual_debug_note = os.path.join(manual_note_dir, df['dsnumber'][0])
        manual_notes = ""
        if not os.path.isfile(manual_debug_note) or os.stat(manual_debug_note).st_size == 0:
            # (re)create debug note if not exists or is empty
            with open(manual_debug_note, 'w') as file:
                file.write("") # create empty file
            try:
                completed = subprocess.run(['chmod', '-R 776', manual_debug_note], capture_output=True)
                # os.system(f'chmod -R 776 {manual_debug_note}') # add write permission to group
                # os.chmod(manual_debug_note, 0o664) # add write permission to group
            except:
                print(f'Cannot change permission for {manual_debug_note}')

        with open(manual_debug_note, 'r') as file:
            data = file.read()
            # put in default note for known issues
            manual_notes = data
        df['manual_debug_note'] = manual_notes

    return df

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
    # 11/02/2023: if status is empty list that means there's no column in the df with valid values (*/*)
    # 11/02/2023: it means the columns contain -1
    return len(status) > 0 and all(np.array(status) > 0.8)
                

def reformat_cell(df):
    '''
    Reformat cell 
    @parameters:
        df: dataframe containing only one row of a dataset pipeline status
    '''
    for (columnName, series) in df.items():
        if isinstance(series[0], str):
            counts = series[0].split('/')
            if len(counts) == 2 and counts[0] == counts[1]:
                reformatted = "ok"
                df.at[0,columnName] = reformatted
    return df

def append_custom(df, processing):
    '''
    Append custom columns to dataframe
    '''
    if len(df) > 1:
        raise ValueError('More than one dataset being processed')
    df = append_debug(df, processing)
    # write nemar.json with processed status based on value of notes
    # note = write_nemar_json(df, is_processed=check_status(df), latest_date=latest_sbatch)
    # if note:
        # df['debug_note'] += "\n" + note
    return df
    
def get_processing_ds():
    result = subprocess.run(["ssh", "dtyoung@login.expanse.sdsc.edu", "squeue -u arno,dtyoung,asalazar | grep ds00*"], 
                        shell=False,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                        check=False)

    result = result.stdout
    pattern = rb"ds00\d{4}"
    matches = re.findall(pattern, result)
    return matches
    
def aggregate_ind_status(dsnumber) -> pd.DataFrame:
    '''
    Aggregate status files of individual datarun

    return
        aggregated DataFrame with dataset-level summary
    '''
    log_dir = os.path.join(processed_dir, dsnumber, 'logs', 'eeg_logs')
    frames = []
    if os.path.exists(log_dir):
        for f in os.listdir(log_dir):
            if f.endswith('plugins.csv'): # get unique files
                # populate data from log files
                df = pd.read_csv(os.path.join(log_dir, f))
                df['set_file'] = [f.split('.')[0][:-len('_plugins')]]
                df.set_index('set_file')
                df.insert(0, 'set_file', df.pop('set_file'))
                frames.append(df)

    if len(frames) > 0:
        all_status = pd.concat(frames, axis=0)
        all_status.fillna(value=0, inplace=True)
        all_status = all_status.sort_values('set_file')
        # print(all_status)
        with open(os.path.join(processed_dir, dsnumber, 'logs', 'ind_pipeline_plugins_status.csv'), 'w') as out:
            all_status.to_csv(out, index=False)
        
        aggregated = all_status.sum()
        final_status_df = frames[0].copy()
        # if 'check_import' not in final_status_df:
            # final_status_df.insert(1, 'check_import', 'ok' if aggregated['remove_chan'] > 0 else '0') # if start preprocessing, import must have been successful

        nsetfiles = len(all_status)
        for (col, val) in aggregated.items():
            if col != 'dsnumber' and col != 'set_file': # and col != 'check_import' 
                final_status_df[col] = f'{int(val)}/{nsetfiles}'
        final_status_df = final_status_df.drop(columns=['set_file'])
    else:
        final_status_df = pd.DataFrame()
        
    final_status_df.insert(0, 'dsnumber', [dsnumber])

    # create logs dir if not exists
    log_dir = os.path.join(processed_dir, dsnumber, 'logs')
    if not os.path.exists(log_dir):
        os.mkdir(log_dir)
        try:
            completed = subprocess.run(['chmod', '-R 776', log_dir], capture_output=True)
            # os.system(f'chmod -R 776 {log_dir}') # add write permission to group
        except:
            print(f'Cannot change permission for {log_dir}')

    with open(os.path.join(log_dir, 'pipeline_plugins_status.csv'), 'w') as out:
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
        all_status = pd.DataFrame()
        for ds in dsnumbers:
            # print(f'processing {ds}')
            # aggregate ind status files (new setup)
            aggregate_ind_status(ds)
            df_new = pd.read_csv(os.path.join(processed_dir, ds, 'logs', 'pipeline_plugins_status.csv'))
            if os.path.exists(final_file):
                all_status = pd.read_csv(final_file)
                df = all_status[all_status["dsnumber"] == ds].copy() 
                df.index = [0]
            else:
                df = df_new
            for col, _ in df.items():
                if len(df) == 0:
                    df.loc[len(df.index), col] = df_new[col][0]
                else:
                    if col in df_new:
                        df[col] = df_new[col][0]
            df = append_custom(df, processing)
            df = reformat_cell(df)
            if "dsnumber" in all_status and ds in list(all_status["dsnumber"]):
                all_status.loc[all_status["dsnumber"] == ds] = df.to_numpy()
            else:
                all_status = pd.concat([all_status, df])
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
                    status_file = os.path.join(path, "logs", "pipeline_plugins_status.csv")
                    if os.path.isfile(status_file):
                        df = pd.read_csv(status_file)
                        df = append_custom(df, processing)
                        df = reformat_cell(df)
                        frames.append(df)

        all_status = pd.concat(frames)

    # rearrange column
    first_column = all_status.pop('debug_note') 
    all_status.insert(len(all_status.columns), 'debug_note', first_column) 
    first_column = all_status.pop('manual_debug_note') 
    all_status.insert(len(all_status.columns), 'manual_debug_note', first_column) 
    return all_status

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

    with open(final_file, 'w') as out:
        final_df.to_csv(out, index=False)
        logfile.write('writing csv\n')

    with open(final_file_html, 'w') as out:
        final_df.to_html(out, index=False, na_rep="")
        logfile.write('writing html\n')

    logfile.close()

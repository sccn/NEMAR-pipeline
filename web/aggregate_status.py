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

logfile = open(os.path.join(sccn_dir,'log.txt'),'w')

def get_known_errors(matlab_log, batcherr_log):
    errors = ""
    with open(matlab_log, 'r') as file:
        data = file.read()
        if "out of memory" in data.lower():
            errors += "OOM\n"
        if "too short" in data.lower():
            errors += "Data too short\n"

    with open(batcherr_log, 'r') as file:
        data = file.read()
        if "DUE TO TIME LIMIT" in data:
            errors += "timeout\n"
        if "Error using parpool" in data:
            errors += "parpool\n"
    
    return errors

def append_modality(df):
    '''
    Get the modality of the dataset
    df is a row pertaining to the dataset of interest
    '''
    if "modality" in df:
        return df
    else:
        # search for modality by looking at the files
        modality = "unknown"
        path = os.path.join(raw_dir, df['dsnumber'][0])
        for root, d_names, f_names in os.walk(path):
            # val = next((x for x in f_names if x.endswith(("_eeg.json", "_ieeg.json", "_meg.json"))), None)
            val = next((x for x in d_names if x in ["eeg", "ieeg", "meg"]), None)
            if val:
                # modality = val.split("_")[-1].split(".")[0].upper()
                modality = val
                break
    
        df['modality'] = modality

        return df

def append_latest_date(df):
    log_dir = os.path.join(processed_dir, df['dsnumber'][0], 'logs')
    manual_debug_note = os.path.join(log_dir, "debug", "manual_debug_note")
    logfile = os.path.join(processed_dir, "logs", df['dsnumber'][0] + '.out')
    # latest_date = max((datetime.datetime.fromtimestamp(os.path.getmtime(os.path.join(root, file)))
                        # for root, _, files in os.walk(log_dir) for file in files if file != 'debug_note'))
    # df['latest_date'] = latest_date
    df['latest_batch_run'] = datetime.datetime.fromtimestamp(os.path.getmtime(logfile))

    df['latest_date_manual'] = datetime.datetime.fromtimestamp(os.path.getmtime(manual_debug_note))
    return df

def append_debug(df, processing):
    '''
    Append debug note to dataframe

    '''
    if len(df) > 1:
        raise ValueError('More than one dataset being processed')
    path = os.path.join(processed_dir, df['dsnumber'][0])
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
                    notes = get_known_errors(matlab_log, batcherr_log)
                file.write(notes)
            try:
                os.chmod(debug_note, 0o664) # add write permission to group
            except:
                print(f'Cannot change permission for {debug_note}')
        df['debug_note'] = notes

        # manual debug note
        manual_debug_note = os.path.join(path, "logs", "debug", "manual_debug_note")
        manual_notes = ""
        if not os.path.isfile(manual_debug_note) or os.stat(manual_debug_note).st_size == 0:
            # (re)create debug note if not exists or is empty
            with open(manual_debug_note, 'w') as file:
                file.write("") # create empty file
            try:
                os.chmod(manual_debug_note, 0o664) # add write permission to group
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
    return all(np.array(status) > 0.8)
                

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
    df = append_modality(df)
    df = append_debug(df, processing)
    df = append_latest_date(df)
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
    other_cols = ['midraw', 'spectra', 'icaact', 'icmap', 'dataqual']
    # print(log_dir)
    # print(os.path.exists(log_dir))
    if os.path.exists(log_dir):
        for f in os.listdir(log_dir):
            if f.endswith('preprocess.csv'): # get unique files
                df = pd.read_csv(os.path.join(log_dir, f))
                df.insert(0, 'set_file', f.split('.')[0])
                for col in other_cols:
                    df[col] = 0 # TODO might be string
                
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
        final_status_df.insert(1, 'imported', 1 if aggregated['remove_chan'] > 0 else 0) # TODO MATLAB should generate this

        nsetfiles = len(all_status)
        for (col, val) in aggregated.items():
            if col != 'dsnumber' and col != 'imported' and col != 'set_file':
                final_status_df[col] = f'{int(val)}/{nsetfiles}'
        with open(os.path.join(processed_dir, dsnumber, 'logs', 'pipeline_status.csv'), 'w') as out:
            final_status_df.to_csv(out, index=False)
        # print(final_status_df)
        return final_status_df


def get_pipeline_status(dsnumbers):
    processing = get_processing_ds()
    processing = [ds.decode('utf-8') for ds in processing]
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
            df = append_custom(df, processing)
            df = reformat_cell(df)
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
                        df = append_custom(df, processing)
                        df = reformat_cell(df)
                        frames.append(df)

        all_status = pd.concat(frames)
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
#!/data/qumulo/dtyoung/NEMAR-pipeline/.conda/envs/web-scrapping/bin/python
#!/expanse/projects/nemar/dtyoung/NEMAR-pipeline/.conda/envs/web-scrapping/bin/python
import numpy as np
import pandas as pd
import os
import datetime

raw_dir = "/data/qumulo/openneuro"
processed_dir = "/data/qumulo/openneuro/processed"
# processed_dir = "/expanse/projects/nemar/dtyoung/NEMAR-pipeline/temp/processed"
final_file = "pipeline_status_all.csv" #"/data/qumulo/openneuro/processed/logs/pipeline_status_all.csv" #"/expanse/projects/nemar/dtyoung/NEMAR-pipeline/temp/processed/pipeline_status_all.csv"
final_file_html = "pipeline_status_all.html" #"/data/qumulo/openneuro/processed/logs/pipeline_status_all.html" 

def get_known_errors(matlab_log):
    errors = ""
    with open(matlab_log, 'r') as file:
        data = file.read()
        if "out of memory" in data.lower():
            errors += "Out of memory\n"
        if "too short" in data.lower():
            errors += "Data too short\n"
    
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
            val = next((x for x in f_names if x.endswith(("_eeg.json", "_ieeg.json", "_meg.json"))), None)
            if val:
                modality = val.split("_")[-1].split(".")[0].upper()
                break
    
        df['modality'] = modality

        return df

def append_latest_date(df):
    log_dir = os.path.join(processed_dir, df['dsnumber'][0], 'logs')
    latest_date = max((datetime.datetime.fromtimestamp(os.path.getmtime(os.path.join(root, file)))
                        for root, _, files in os.walk(log_dir) for file in files))
    df['latest_date'] = latest_date
    return df

def append_debug(df):
    '''
    Append debug note to dataframe

    '''
    # notes = []
    # for ds in df['dsnumber']:
    #     # for each processed dataset
        # path = os.path.join(processed_dir, ds)
    if len(df) > 1:
        raise ValueError('More than one dataset being processed')
    path = os.path.join(processed_dir, df['dsnumber'][0])
    if os.path.isdir(path):
        # get debug note
        debug_note = os.path.join(path, "logs", "debug", "debug_note")
        if not os.path.isfile(debug_note):
            # create debug note if not exists
            with open(debug_note, 'w') as file:
                # put in default note for known issues
                matlab_log = os.path.join(path, "logs", "matlab_log")
                errors = get_known_errors(matlab_log)
                file.write(errors)

        if check_status(df):
            notes = "ok"
        else:
            with open(debug_note, 'r') as file:
                data = file.read()
                # put in default note for known issues
                notes = data

        df['debug_note'] = notes

    return df

def check_status(df):
    '''
    Check if at least 60% of dataset has been processed
    '''
    status = []
    for (columnName, series) in df.items():
        if isinstance(series[0], str):
            counts = series[0].split('/')
            if len(counts) == 2:
                status.append(int(counts[0]) / int(counts[1]))
    return all(np.array(status) > 0.6)
                

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

def append_custom(df):
    '''
    Append custom columns to dataframe
    '''
    if len(df) > 1:
        raise ValueError('More than one dataset being processed')
    df = append_modality(df)
    df = append_debug(df)
    df = append_latest_date(df)
    return df
    
def get_pipeline_status():
    frames = []
    for f in os.listdir(processed_dir):
        path = os.path.join(processed_dir, f)
        if os.path.isdir(path):
            status_file = os.path.join(path, "logs", "pipeline_status.csv")
            if os.path.isfile(status_file):
                df = pd.read_csv(status_file)
                df = append_custom(df)
                df = reformat_cell(df)
                frames.append(df)

    return pd.concat(frames)

final_df = get_pipeline_status()

with open(final_file, 'w') as out:
    final_df.to_csv(out, index=False)
with open(final_file_html, 'w') as out:
    final_df.to_html(out, index=False)

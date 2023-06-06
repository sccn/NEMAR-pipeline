#!/data/qumulo/dtyoung/NEMAR-pipeline/.conda/envs/web-scrapping/bin/python
#!/expanse/projects/nemar/dtyoung/NEMAR-pipeline/.conda/envs/web-scrapping/bin/python
import numpy as np
import pandas as pd
import os
import datetime

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
            errors += "Out of memory\n"
        if "too short" in data.lower():
            errors += "Data too short\n"

    with open(batcherr_log, 'r') as file:
        data = file.read()
        if "DUE TO TIME LIMIT" in data:
            errors += "Cancelled due to time limit\n"
    
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
    matlab_log = os.path.join(log_dir, 'matlab_log')
    # if not os.path.isfile(matlab_log):
        # print(f"matlab log not found for {df['dsnumber'][0]}")
    # else:
    latest_date = max((datetime.datetime.fromtimestamp(os.path.getmtime(os.path.join(root, file)))
                        for root, _, files in os.walk(log_dir) for file in files if file != 'debug_note'))
    df['latest_date'] = latest_date
        # df['latest_date'] = datetime.datetime.fromtimestamp(os.path.getmtime(matlab_log))
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
        if not os.path.isfile(debug_note) or os.stat(debug_note).st_size == 0:
            # (re)create debug note if not exists or is empty
            with open(debug_note, 'w') as file:
                # put in default note for known issues
                matlab_log = os.path.join(path, "logs", "matlab_log")
                batcherr_log = os.path.join(processed_dir, "logs", df['dsnumber'][0] + ".err")
                errors = get_known_errors(matlab_log, batcherr_log)
                file.write(errors)
            try:
                os.chmod(debug_note, 0o664) # add write permission to group
            except:
                print(f'Cannot change permission for {debug_note}')

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
    Check if at least 80% of dataset has been processed
    '''
    status = []
    for (columnName, series) in df.items():
        if isinstance(series[0], str):
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
        logfile.write(f'processing {f}\n')
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
    logfile.write('writing csv\n')

with open(final_file_html, 'w') as out:
    final_df.to_html(out, index=False)
    logfile.write('writing html\n')

logfile.close()

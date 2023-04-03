#!/data/qumulo/dtyoung/NEMAR-pipeline/.conda/envs/web-scrapping/bin/python

import pandas as pd
import os

processed_dir = "/data/qumulo/openneuro/processed" # "/expanse/projects/nemar/dtyoung/NEMAR-pipeline/temp/processed" # "/data/qumulo/dtyoung/NEMAR-pipeline/temp/processed"
final_file = "pipeline_status_all.csv" #"/data/qumulo/openneuro/processed/logs/pipeline_status_all.csv" #"/expanse/projects/nemar/dtyoung/NEMAR-pipeline/temp/processed/pipeline_status_all.csv"
final_file_html = "pipeline_status_all.html" #"/data/qumulo/openneuro/processed/logs/pipeline_status_all.html" 

def get_known_errors(matlab_log):
    errors = ""
    with open(matlab_log, 'r') as file:
        data = file.read()
        if "out of memory" in data.lower():
            errors += "Out of memory\n"
    
    return errors
def append_custom(df):
    notes = []
    for ds in df['dsnumber']:
        # for each processed dataset
        path = os.path.join(processed_dir, ds)
        if os.path.isdir(path):
            # get debug note
            debug_note = os.path.join(path, "logs", "debug", "debug_note")
            if not os.path.isfile(debug_note):
                # create debug note if not exists
                with open(debug_note, 'w') as file:
                    # put in default note for known issues
                    matlab_log = os.path.join(path, "logs", "matlab_log")
                    errors = get_known_errors(matlab_log)
                    if ds == "ds002338":
                        print(errors)
                    file.write(errors)

            with open(debug_note, 'r') as file:
                data = file.read()
                # # put in default note for known issues
                # matlab_log = os.path.join(path, "logs", "matlab_log")
                # errors = get_known_errors(matlab_log)
                # if errors:
                #     data = errors + data
                notes.append(data)

    df['debug_note'] = notes

    return df

def get_pipeline_status():
    frames = []
    for f in os.listdir(processed_dir):
        path = os.path.join(processed_dir, f)
        if os.path.isdir(path):
            status_file = os.path.join(path, "logs", "pipeline_status.csv")
            if os.path.isfile(status_file):
                df = pd.read_csv(status_file)
                frames.append(df)

    return pd.concat(frames)

final_df = get_pipeline_status()
final_df = append_custom(final_df)

with open(final_file, 'w') as out:
    final_df.to_csv(out, index=False)
with open(final_file_html, 'w') as out:
    final_df.to_html(out, index=False)

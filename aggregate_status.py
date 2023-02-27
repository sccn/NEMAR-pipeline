#!/data/qumulo/dtyoung/NEMAR-pipeline/.conda/envs/web-scrapping/bin/python

import pandas as pd
import os

processed_dir = "/data/qumulo/openneuro/processed" # "/expanse/projects/nemar/dtyoung/NEMAR-pipeline/temp/processed" # "/data/qumulo/dtyoung/NEMAR-pipeline/temp/processed"
final_file = "pipeline_status_all.csv" #"/data/qumulo/openneuro/processed/logs/pipeline_status_all.csv" #"/expanse/projects/nemar/dtyoung/NEMAR-pipeline/temp/processed/pipeline_status_all.csv"
final_file_html = "pipeline_status_all.html" #"/data/qumulo/openneuro/processed/logs/pipeline_status_all.html" 
frames = []
for f in os.listdir(processed_dir):
    path = os.path.join(processed_dir, f)
    if os.path.isdir(path):
        status_file = os.path.join(path, "logs", "pipeline_status.csv")
        if os.path.isfile(status_file):
            df = pd.read_csv(status_file)
            frames.append(df)

final_df = pd.concat(frames)
with open(final_file, 'w') as out:
    final_df.to_csv(out, index=False)
with open(final_file_html, 'w') as out:
    final_df.to_html(out, index=False)

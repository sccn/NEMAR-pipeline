import pandas as pd
import os

processed_dir = "/expanse/projects/nemar/openneuro/processed" # "/expanse/projects/nemar/dtyoung/NEMAR-pipeline/temp/processed" # "/data/qumulo/dtyoung/NEMAR-pipeline/temp/processed"
final_file = "/expanse/projects/nemar/openneuro/processed/logs/pipeline_status_all.csv" #"/expanse/projects/nemar/dtyoung/NEMAR-pipeline/temp/processed/pipeline_status_all.csv"
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

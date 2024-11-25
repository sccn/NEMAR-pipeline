from aggregate_status import aggregate_ind_status
import aggregate_status as agg
import os
from pathlib import Path
import pandas as pd
processed_dir = '/expanse/projects/nemar/hbn-bids-processed'
ds = 'cmi_bids_R1_processed'
aggregate_ind_status(ds, processed_dir)
df = pd.read_csv(os.path.join(processed_dir, ds, 'logs', 'pipeline_status.csv'))
print(df)
agg.write_nemar_json(df, True, '10-02-2024', processed_dir=processed_dir)

for root, dirs, files in os.walk(f'{processed_dir}/{ds}'):
    for f in files:
        if f.endswith('combined_eeg.set'):
            print(Path(root) / f)

import os
import json
import pandas as pd
from update_sheet import update_values

def aggregate_nemar_json():
    # Aggregate nemar.json files
    path = '/expanse/projects/nemar/openneuro/processed'
    nemar_jsons = []
    dsnumbers = []
    for folder in os.listdir(path):
        if folder.startswith('ds'):
            dsnumber = folder.split('/')[-1]
            dsnumbers.append(dsnumber)
            nemar_json = os.path.join(path, folder, 'code', 'nemar.json')
            # nemar_json = os.path.join(path, 'nemar_json_temp', f'{dsnumber}_nemar.json')
            if os.path.exists(nemar_json):
                with open(nemar_json, 'r') as f:
                    nemar_json = json.load(f)
                    # print(nemar_json)
                    nemar_json.pop('plots', None)
                    nemar_jsons.append(nemar_json)

    df = pd.DataFrame.from_dict(nemar_jsons)
    df.insert(0, 'dsnumber', dsnumbers)
    df = df.fillna('')
    return df


if __name__ == "__main__":
  # Pass: spreadsheet_id,  range_name, value_input_option and  _values
  spreadsheet_id = "1yNVCB_pfLvrIJqy-zU3yEzrfzhFctPmYpJeWL5_PMGs"
  data_df = aggregate_nemar_json()
  data = [list(data_df.keys())]
  data.extend(data_df.values.tolist())
  update_values(
      spreadsheet_id,
      "A1",
      "USER_ENTERED",
      data,
  )
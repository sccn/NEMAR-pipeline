import mne
import os
import shutil
from pop_loadset import pop_loadset
import pandas as pd
import json

def get_nemar_json(dsnumber):
    path = '/expanse/projects/nemar/openneuro/processed'

    nemar_json_path = 'code/nemar.json'
    nemar_json_fullpath = os.path.join(path, dsnumber, nemar_json_path)
    if os.path.exists(nemar_json_fullpath):
        return nemar_json_fullpath
    
    return ""

def has_1020(dsnumber):
    path = '/expanse/projects/nemar/openneuro/processed'
    ds_path = os.path.join(path, dsnumber) 
    chan_1020 = {"Fp1", "Fpz", "Fp2", "Nz", "AF9", "AF7", "AF3", "AFz", "AF4", "AF8", "AF10", "F9", "F7", "F5", "F3", "F1", "Fz", "F2", "F4", "F6", "F8", "F10", "FT9", "FT7", "FC5", "FC3", "FC1", "FCz", "FC2", "FC4", "FC6", "FT8", "FT10", "T9", "T7", "C5", "C3", "C1", "Cz", "C2", "C4", "C6", "T8", "T10", "TP9", "TP7", "CP5", "CP3", "CP1", "CPz", "CP2", "CP4", "CP6", "TP8", "TP10", "P9", "P7", "P5", "P3", "P1", "Pz", "P2", "P4", "P6", "P8", "P10", "PO9", "PO7", "PO3", "POz", "PO4", "PO8", "PO10", "O1", "Oz", "O2", "O9", "O10", "CB1", "CB2", "Iz"}

    for root, dirs, files in os.walk(ds_path):
        for f in files:
            if f.endswith('.set'):
                set_file = os.path.join(root,f)
                try:
                    EEG = pop_loadset(set_file)
                except:
                    print('error importing set file')
                    return False
                chanlocs = EEG['chanlocs']
                df = pd.DataFrame.from_records(chanlocs)
                labels = list(df['labels'])
                print(labels)

                for l in labels:
                    if l in chan_1020:
                        return True
                return False

def backup_nemar_json(dsnumber, nemar_json, addfield=False):
    backup_path = '/expanse/projects/nemar/openneuro/processed/nemar_json_temp'
    if os.path.exists(nemar_json):
        shutil.copyfile(nemar_json, os.path.join(backup_path, f'{dsnumber}_nemar.json'))
        if addfield:
            with open(nemar_json) as f:
                nemar_json_dict = json.load(f)
                nemar_json_dict['channelsystem'] = "other"
                with open(os.path.join(backup_path, f'{dsnumber}_nemar.json'), 'w') as out:
                    json.dump(nemar_json_dict, out)

def main():
    path = '/expanse/projects/nemar/openneuro/processed'

    for d in os.listdir(path):
        if d.startswith('ds'):
            dsnumber = d
            nemar_json = get_nemar_json(dsnumber)
            print(nemar_json)
            backup_nemar_json(dsnumber, nemar_json)

            nemar_json_tempdir = '/expanse/projects/nemar/openneuro/processed/nemar_json_temp'
            if has_1020(dsnumber):
                with open(nemar_json) as f:
                    nemar_json_dict = json.load(f)
                    nemar_json_dict['channelsystem'] = "10-20"
                    print(f'{dsnumber} has 10-20')
                    with open(os.path.join(nemar_json_tempdir, f'{dsnumber}_nemar.json'), 'w') as out:
                        json.dump(nemar_json_dict, out)

if __name__ == "__main__":
    main()
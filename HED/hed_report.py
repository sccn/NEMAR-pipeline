import json

def generate_json_report(value_summary, hed_summary, hed_type_summary, output):
    event_files = 0
    events = 0

    with open(value_summary,'r') as f:
        value_summary = json.load(f)
        events = value_summary['Overall summary']['Total events']
        event_files = value_summary['Overall summary']['Total files']
    summary = {'event files': event_files, 'events': events, 'events/file': events/event_files}
    summary['Main tags'] = {}
    summary['Other tags'] = []
    summary['Condition variables'] = {}
    with open(hed_summary,'r') as f:
        hed_summary = json.load(f)
        for key in hed_summary['Overall summary']['Main tags'].keys():
            main_tag = key
            summary['Main tags'][main_tag] = []

            for index, _ in enumerate(hed_summary['Overall summary']['Main tags'][main_tag]):
                tag = hed_summary['Overall summary']['Main tags'][main_tag][index]['tag']
                evt_count = hed_summary['Overall summary']['Main tags'][main_tag][index]['events']
                # summary['Main tags'][main_tag]['events'] = summary['Main tags'][main_tag]['events'] + evt_count
                summary['Main tags'][main_tag].append({'tag': tag, 'events': evt_count})

        for tag_dict in hed_summary['Overall summary']['Other tags']:
            summary['Other tags'].append({'tag': tag_dict['tag'], 'events': tag_dict['events']})

    if hed_type_summary:
        with open(hed_type_summary,'r') as f:
            hed_type_summary = json.load(f)
            for key in hed_type_summary['Overall summary']['details'].keys():
                main_tag = key
                summary['Condition variables'][main_tag] = []
                for level_key in hed_type_summary['Overall summary']['details'][main_tag]['level_counts'].keys():
                    desc = hed_type_summary['Overall summary']['details'][main_tag]['level_counts'][level_key]['description']
                    file_count = hed_type_summary['Overall summary']['details'][main_tag]['level_counts'][level_key]['files']
                    evt_count = hed_type_summary['Overall summary']['details'][main_tag]['level_counts'][level_key]['events']
                    summary['Condition variables'][main_tag].append({'level': level_key, 'description': desc, 'events': evt_count, 'files': file_count})

    with open(output, 'w') as out:
        json.dump(summary, out)
    
    return summary


import shutil
import glob
import os 
hed_datasets = "ds004362 ds004350 ds004123 ds004122 ds004121 ds004120 ds004119 ds004118 ds004117 ds004106 ds004105 ds003645 ds003061 ds002718"
hed_datasets = hed_datasets.split(" ")
print("Number of HED datasets:", len(hed_datasets))
data_path = "/expanse/projects/nemar/openneuro"
code_path = "/expanse/projects/nemar/dtyoung/NEMAR-pipeline/HED"
for ds in hed_datasets:
    ds_path = f"{data_path}/{ds}"
    print(ds_path)
    column_summary = glob.glob(f'{ds_path}/derivatives/remodel/summaries/column_values_summary/column_values_summary*.json')
    shutil.copyfile(column_summary[0], f'{ds_path}/derivatives/remodel/summaries/events_report.json')
    hed_tag_summary = glob.glob(f'{ds_path}/derivatives/remodel/summaries/hed_tag_summary/hed_tag_summary*.json')
    generate_json_report(column_summary[0], hed_tag_summary[0], '', f'{ds_path}/derivatives/remodel/summaries/hed_report.json')
    if not os.path.exists(f'{ds_path}/derivatives/remodel/summaries/events_report.json') or not os.path.exists(f'{ds_path}/derivatives/remodel/summaries/hed_report.json'):
        raise ('Missing report file')
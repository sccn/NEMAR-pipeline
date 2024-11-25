
import sys
sys.path.insert(0, "../hed_python")
from hed.tools.remodeling.cli.run_remodel import main
import os
import re
import json
import shutil

def generate_json_report(hed_summary_outputdir, hed_summary, outputpath):
    summary = {}
    summary['Main tags'] = {}
    summary['Other tags'] = []
    summary['Condition variables'] = {}
    with open(hed_summary,'r') as f:
        hed_summary = json.load(f)
        nfiles = hed_summary['Overall summary']['Total files']
        nevents = hed_summary['Overall summary']['Total events']
        summary['event files'] = nfiles
        summary['events'] = nevents
        summary['events/file'] = nevents/nfiles
        main_tags_summary_dict = hed_summary['Overall summary']['Specifics']['Main tags']
        other_tags_summary_dict = hed_summary['Overall summary']['Specifics']['Other tags']
        # iterate through main tags
        for key in main_tags_summary_dict.keys():
            main_tag = key
            summary['Main tags'][main_tag] = []

            for tag_dict in main_tags_summary_dict[main_tag]:
                summary['Main tags'][main_tag].append({'tag': tag_dict['tag'], 'events': tag_dict['events']})

        for tag_dict in other_tags_summary_dict:
            summary['Other tags'].append({'tag': tag_dict['tag'], 'events': tag_dict['events']})

    with open(outputpath +'/hed_report.json', 'w') as out:
        json.dump(summary, out)
    
    # move word cloud
    shutil.copyfile(hed_summary_outputdir + '/summarize_hed_tags_word_cloud.svg', outputpath+'/word_cloud.svg')
    return summary

raw_dir = '/expanse/projects/nemar/openneuro'
hed_summary_model_path = './hed_summary_cmd.json'
outputdir = '/expanse/projects/nemar/openneuro/processed/event_summaries'
start = False
error_logfile = './run_hed_summary.err'
logdir = './logs'
fid_err = open(error_logfile, 'w')
run_wordcloud = True

# TODO: use NEMAR database
dsnumbers = ['ds003645'] # ['ds004855', 'ds004854', 'ds004853', 'ds004852', 'ds004851', 'ds004850', 'ds004849', 'ds004844', 'ds004843', 'ds004842', 'ds004841', 'ds004661', 'ds004660', 'ds004657', 'ds004362', 'ds004350', 'ds004123', 'ds004122', 'ds004121', 'ds004120', 'ds004119', 'ds004118', 'ds004117', 'ds004106', 'ds004105', 'ds003645', 'ds003061', 'ds002893', 'ds002691', 'ds002680', 'ds002578']
for f in dsnumbers:
    print(f'processing {f}')
    try:
        data_root = os.path.join(raw_dir, f)
        work_dir = os.path.join(outputdir, f)
        if not os.path.exists(work_dir):
            os.mkdir(work_dir)
        if os.path.isdir(data_root):
            arg_list = [data_root, hed_summary_model_path, '-nb', '-nu',  '-x', 'stimuli',
                'derivatives', 'code', 'stimuli', 'sourcedata', '.datalad', '-nb', '-w', work_dir,
                '-ld', logdir, '-b', '-i', 'none', '-v', '-t', 'FacePerception']
            main(arg_list)
            hed_summary_outputdir = os.path.join(work_dir, 'remodel', 'summaries', 'summarize_hed_tags')
            hed_summaries = [file for file in os.listdir(hed_summary_outputdir) if re.match('summarize_hed_tags.json', file)]
            if len(hed_summaries) > 0:
                hed_summaries.sort()
                hed_summary_outputfile = os.path.join(hed_summary_outputdir, hed_summaries[-1])

                generate_json_report(hed_summary_outputdir, hed_summary_outputfile, work_dir)

    except Exception as e:
        print(e)
        fid_err.write(f'Error processing {f}: {e}\n')

fid_err.close()

def get_hed_datasets():
    # TODO
    return
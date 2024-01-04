
import sys
sys.path.insert(0, "../hed_python")
from hed.tools.remodeling.cli.run_remodel import main
from hed.tools.visualization import summary_to_dict, create_wordcloud, word_cloud_to_svg
import os
import re
import json

def generate_json_report(hed_summary, output):
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

    # if hed_type_summary:
    #     with open(hed_type_summary,'r') as f:
    #         hed_type_summary = json.load(f)
    #         for key in hed_type_summary['Overall summary']['Specifics']['details'].keys():
    #             main_tag = key
    #             summary['Condition variables'][main_tag] = []
    #             for level_key in hed_type_summary['Overall summary']['Specifics']['details'][main_tag]['level_counts'].keys():
    #                 desc = hed_type_summary['Overall summary']['Specifics']['details'][main_tag]['level_counts'][level_key]['description']
    #                 file_count = hed_type_summary['Overall summary']['Specifics']['details'][main_tag]['level_counts'][level_key]['files']
    #                 evt_count = hed_type_summary['Overall summary']['Specifics']['details'][main_tag]['level_counts'][level_key]['events']
    #                 summary['Condition variables'][main_tag].append({'level': level_key, 'description': desc, 'events': evt_count, 'files': file_count})

    with open(output, 'w') as out:
        json.dump(summary, out)
    
    return summary

def generate_wordcloud(summary_file, work_dir):
    with open(summary_file) as fin:
        hed_summary = json.load(fin)
        loaded_dict = summary_to_dict(hed_summary)

        word_cloud = create_wordcloud(loaded_dict, mask_path="./word_mask.png", height=400, width=None)
        svg_data = word_cloud_to_svg(word_cloud)
        with open(work_dir+"/word_cloud.svg", "w") as outfile:
            outfile.writelines(svg_data)


raw_dir = '/expanse/projects/nemar/openneuro'
hed_summary_model_path = './hed_summary_cmd_validation.json' #'./hed_summary_cmd.json'
outputdir = '/expanse/projects/nemar/openneuro/processed/event_summaries'
start = False
error_logfile = './run_hed_summary.err'
fid_err = open(error_logfile, 'w')
run_wordcloud = True

# TODO: use NEMAR database
dsnumbers = ['ds004362','ds004350','ds004123','ds004122','ds004121','ds004120','ds004119','ds004118','ds004117','ds004106','ds004105','ds003645','ds003061','ds002718']
dsnumbers = ['ds004123','ds004122','ds004121','ds004120','ds004119','ds004118','ds004106','ds004105'] # validation errors
for f in dsnumbers:
    print(f'processing {f}')
    try:
        data_root = os.path.join(raw_dir, f)
        work_dir = os.path.join(outputdir, f)
        if not os.path.exists(work_dir):
            os.mkdir(work_dir)
        if os.path.isdir(data_root):
            # arg_list1 = [data_root, hed_summary_model_path, '-x', 'derivatives', 'code', 'stimuli', 'sourcedata', '.datalad', 
                # '-nu', '-nb', '-w', work_dir, '-b', '-i', 'none', "-v"]
            arg_list1 = [data_root, hed_summary_model_path, '-x', 'derivatives', 'code', 'stimuli', 'sourcedata', 
                '-nb', '-nu', '-w', work_dir, '-b', '-i', 'none', '-v']
            main(arg_list1)
            hed_summary_outputdir = os.path.join(work_dir, 'remodel', 'summaries', 'summarize_hed_tags')
            hed_summaries = [file for file in os.listdir(hed_summary_outputdir) if re.match('summarize_hed_tags.json', file)]
            if len(hed_summaries) > 0:
                hed_summaries.sort()
                hed_summary_outputfile = os.path.join(hed_summary_outputdir, hed_summaries[-1])

                # hed_type_summary_outputdir = os.path.join(work_dir, 'remodel', 'summaries', 'hed_type_summary')
                # hed_type_summaries = [file for file in os.listdir(hed_type_summary_outputdir) if re.match('hed_type_summary.json', file)]
                # hed_type_summary_outputfile = None
                # if len(hed_type_summaries) > 0:
                #     hed_type_summaries.sort()
                #     hed_type_summary_outputfile = os.path.join(hed_type_summary_outputdir, hed_type_summaries[-1])
                # generate_json_report(hed_summary_outputfile, hed_type_summary_outputfile, work_dir+'/hed_report.json')
                generate_json_report(hed_summary_outputfile, work_dir+'/hed_report.json')

                if run_wordcloud:
                    # Generate word cloud
                    generate_wordcloud(hed_summary_outputfile, work_dir)
    except Exception as e:
        fid_err.write(f'Error processing {f}: {e}\n')

fid_err.close()

def get_hed_datasets():
    # TODO
    return
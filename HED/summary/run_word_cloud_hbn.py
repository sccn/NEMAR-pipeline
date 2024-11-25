
import sys
sys.path.insert(0, "../hed_python")
from hed.tools.visualization import summary_to_dict, create_wordcloud, word_cloud_to_svg
import os
import re
import shutil
import json

raw_dir = '/expanse/projects/nemar/yahya'
hed_summary_model_path = './hed_summary_cmd.json'
hed_type_summary_model_path = './hed_type_summary_cmd.json'
outputdir = '/expanse/projects/nemar/openneuro/processed/event_summaries'

dsnumbers = ['cmi_bids_R1', 'cmi_bids_R6']
for f in dsnumbers:
    print(f'processing {f}')
    data_root = os.path.join(raw_dir, f)
    work_dir = os.path.join(outputdir, f)
    hed_summary_outputfile = work_dir+'/remodel/summaries/summarize_hed_tags/summarize_hed_tags.json'
    if not os.path.exists(work_dir):
        os.mkdir(work_dir)
    if os.path.isdir(data_root):
        try:
            with open(hed_summary_outputfile,'r') as fin:
                hed_summary = json.load(fin)
                loaded_dict = summary_to_dict(hed_summary)

                word_cloud = create_wordcloud(loaded_dict, mask_path="./word_mask.png", height=400, width=None)
                svg_data = word_cloud_to_svg(word_cloud)
                with open(work_dir+"/word_cloud.svg", "w") as outfile:
                    outfile.writelines(svg_data)
        except Exception as e:
            print(f"Error for {f}")
            print(e)



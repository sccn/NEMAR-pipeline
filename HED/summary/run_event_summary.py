
import sys
sys.path.insert(0, "../hed_python")
from hed.tools.remodeling.cli.run_remodel import main
import os
import re
import shutil

raw_dir = '/expanse/projects/nemar/openneuro'
model_path = './column_values_summary_cmd.json'
outputdir = '/expanse/projects/nemar/openneuro/processed/event_summaries'
error_logfile = './run_event_summary.err'
fid_err = open(error_logfile, 'w')
start = False
dsnumbers = ['ds004855', 'ds004854', 'ds004853', 'ds004852', 'ds004851', 'ds004850', 'ds004849', 'ds004844', 'ds004843', 'ds004842', 'ds004841', 'ds004661', 'ds004660', 'ds004657', 'ds004362', 'ds004350', 'ds004123', 'ds004122', 'ds004121', 'ds004120', 'ds004119', 'ds004118', 'ds004117', 'ds004106', 'ds004105', 'ds003645', 'ds003061', 'ds002893', 'ds002691', 'ds002680', 'ds002578']
processed_dir = '/expanse/projects/nemar/openneuro/processed'
for idx, f in enumerate(os.listdir(processed_dir)):
# for f in dsnumbers:
    print(f'processing {f}')
    data_root = os.path.join(raw_dir, f)
    work_dir = os.path.join(outputdir, f)
    if not os.path.exists(work_dir):
        os.mkdir(work_dir)
    if os.path.isdir(data_root):
        arg_list1 = [data_root, model_path, '-x', 'derivatives', 'code', 'stimuli', '-nb', '-nu', '-w', work_dir, '-b', '-i', 'none', '-v']
        try:
            main(arg_list1)
            summary_outputdir = os.path.join(work_dir, 'remodel', 'summaries', 'column_values')
            summaries = [file for file in os.listdir(summary_outputdir) if re.match('column_values.*.json', file)]
            if len(summaries) > 0:
                summaries.sort()
                summary_outputfile = os.path.join(summary_outputdir, summaries[-1])
                shutil.copyfile(summary_outputfile, work_dir+'/events_report.json')
        except Exception as e:
            fid_err.write(f'Error processing {f}: {e}\n')


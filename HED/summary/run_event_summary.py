
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
# dsnumbers = ['ds004043', 'ds002691', 'ds004278', 'ds004033', 'ds004011', 'ds004603', 'ds000117', 'ds004368', 'ds003775', 'ds003987', 'ds004019', 'ds004551', 'ds004315', 'ds003602', 'ds003885', 'ds003844', 'ds002723', 'ds003947', 'ds002885', 'ds004252', 'ds004577', 'ds002001', 'ds004078', 'ds004166', 'ds004561', 'ds004256', 'ds002034', 'ds003702', 'ds004317', 'ds002725', 'ds004080', 'ds004200', 'ds003638', 'ds004357', 'ds003352', 'ds003710', 'ds004330', 'ds003848', 'ds002336', 'ds003766', 'ds002761', 'ds004346', 'ds004212', 'ds004447', 'ds003195', 'ds004477', 'ds004152', 'ds003810', 'ds004515', 'ds004264', 'ds004196', 'ds004395', 'ds002721', 'ds001787', 'ds001810', 'ds002893', 'ds004018', 'ds003816', 'ds004519', 'ds004554', 'ds004574', 'ds003555', 'ds004381', 'ds004107', 'ds004446', 'ds004572', 'ds003505', 'ds003801', 'ds004532', 'ds003570', 'ds004262', 'ds004398', 'ds004127', 'ds003800', 'ds004100', 'ds004147', 'ds004295', 'ds004306', 'ds004580', 'ds004444', 'ds004511', 'ds004197', 'ds004000', 'ds002720', 'ds004473', 'ds002158', 'ds003194', 'ds004215', 'ds003944', 'ds002833', 'ds004367', 'ds003670', 'ds004369', 'ds003078', 'ds004151', 'ds003969', 'ds004075', 'ds004408', 'ds004194', 'ds003039', 'ds004579', 'ds003626', 'ds002718', 'ds002778', 'ds004460', 'ds003374', 'ds000248', 'ds001784', 'ds000246', 'ds003753', 'ds003768', 'ds004229', 'ds002908', 'ds004575', 'ds004457', 'ds004347', 'ds002791', 'ds001971', 'ds004017', 'ds003751', 'ds002338', 'ds003876', 'ds003688', 'ds003754', 'ds003694', 'ds004502', 'ds003822', 'ds004356', 'ds003922', 'metadata', 'ds001849', 'ds004148', 'ds002799', 'ds002722', 'ds002094', 'ds004024', 'ds003838', 'ds003805', 'ds004022', 'ds004584', 'ds003739', 'ds004040', 'ds004521', 'ds004276', 'ds003190', 'ds000247', 'ds004015', 'ds004448', 'ds002680', 'ds004067', 'ds004010', 'ds004588', 'ds002578', 'ds004520', 'ds004284', 'ds004186', 'ds002218', 'ds004504', 'ds004348', 'ds003846', 'ds002724', 'ds003887', 'ds003380', 'ds004505', 'ds003774']
dsnumbers = ['ds003380', 'ds003768', 'ds002338', 'ds003944', 'ds004460', 'ds004398', 'ds004381', 'ds003775', 'ds003805', 'ds004022', 'ds000247', 'ds004551', 'ds004408', 'ds004127', 'ds003555', 'ds002885', 'ds002718', 'ds002001']
# for idx, f in enumerate(os.listdir(processed_dir)):
for f in dsnumbers:
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


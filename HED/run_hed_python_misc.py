import sys
sys.path.append(r'/expanse/projects/nemar/dtyoung/NEMAR-pipeline/HED/hed_python')
import hed.tools.remodeling.cli.run_remodel as run_remodel
import hed.tools.remodeling.cli.run_remodel_backup as run_remodel_backup
import os

hed_datasets = "ds004362" #ds004350 ds004123 ds004122 ds004121 ds004120 ds004119 ds004118 ds004117 ds004106 ds004105 ds003645 ds003061 ds002718"
# hed_datasets = "ds002718"
hed_datasets = hed_datasets.split(" ")
data_path = "/expanse/projects/nemar/openneuro"
code_path = "/expanse/projects/nemar/dtyoung/NEMAR-pipeline/HED"
for ds in hed_datasets:
    ds_path = f"{data_path}/{ds}"
    # print(ds_path)
    # if not os.path.exists(f"{ds_path}/derivatives/remodel/backups"):
    #     run_remodel_backup.main([ds_path, "-x", "derivatives", "stimuli", "-v"])
    run_remodel.main([ds_path, f"{code_path}/column_values_summary_cmd.json", "-b", "-s", ".json", "-x", "derivatives", "-v", "-n", "''"])
    # run_remodel.main([ds_path, f"{code_path}/hed_summary_cmd.json", "-b", "-s", ".json", "-x", "derivatives", "-v"])
    # run_remodel.main([ds_path, f"{code_path}/hed_type_summary_cmd.json", "-b", "-s", ".json", "-x", "derivatives", "-v"])
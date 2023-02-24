#! /bin/bash
hed_datasets="ds004350 ds004166 ds004123 ds004122 ds004121 ds004120 ds004119 ds004118 ds004117 ds004106 ds004105 ds003645 ds003061 ds002718"
data_dir="/expanse/projects/nemar/openneuro"
for ds in $hed_datasets; do
    echo $data_dir/$ds
    run_remodel_backup $data_dir/$ds -x derivatives stimuli
    run_remodel $data_dir/$ds ./HED/column_values_summary_cmd.json -b -s .json -x derivatives
    run_remodel $data_dir/$ds ./HED/hed_summary_cmd.json -b -s .json -x derivatives
    run_remodel $data_dir/$ds ./HED/hed_type_summary_cmd.json -b -s .json -x derivatives
done
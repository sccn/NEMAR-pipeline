# NEMAR-pipeline
Code for NEMAR pipeline to generate visualization and data quality report. Refactored https://github.com/sccn/app-test-NEMAR

# Files contains in this repo
- ds_create_and_submit_job.m, given a DS number, create a slurm job (create-submit-job.sh is the bash equivalent). This call run_pipeline.m. run_pipeline_custom.m is to call a specific function (plugin?) on each EEG file.
- run_commands.m 
- eeg_ uses EEG structures for preprocess (eeg_nemar_preprocess.m), plugins (eeg_nemar_plugin.m), data quality (eeg_nemar_dataqual.m). eeg_run_pipeline.m runs them all. eeg_create_and_submit_job.m runs at the dataset level.
- check_dataset_custom_code, allow to inject custom code for a dataset
- scan_processed_ds.py, add to the NEMAR.json file that this dataset has bad participant tsv file (manually provided)
- processing_sbatch - quickly run pipeline

# Folders
- nemar_plugin - vizualization plugins
- HED/summary - word cloud
- sbatch - all sbatch commands
- web/aggregate_status.py

# Using your own function

- Make sure you have an Expanse
- Clone the repository

There are 2 types of pipelines
- Pipelines that process single EEG datasets
- Pipelines that process an entire BIDS repo

process_all_custom_pipelines
  - Take a BIDS dataset
  - Take a function name to process the data
  
Allow to use the processed directory instead of the raw data folder
  
3 modes
  - Process single EEG dataset
  - Process all EEG datasets of a subject
  - Process a STUDY
  - Process the BIDS folder

The function should write a JSON or SVG file into the same folder as the EEG file or the same folder as the derivative BIDS repo 
- At the same time

options - options to the function

Parameters

# Inclusion to the NEMAR website

- Send the name of the file to Dung
- If a plot, send the title
    - associated titled
    - file name
- If a JSON file, for each entry send. No array allowed.
    - title 
    - field
    - description

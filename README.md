# NEMAR-pipeline
Code for NEMAR pipeline to generate visualization and data quality report. Refactored https://github.com/sccn/app-test-NEMAR

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

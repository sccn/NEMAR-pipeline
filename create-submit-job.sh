#!/bin/bash

# Function to print usage instructions
usage() {
    echo "Usage: $0 <dataset_number> [optional arguments]"
    echo "Creates and submits a SLURM job for NEMAR pipeline processing"
    exit 1
}

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
    usage
fi

# First argument is the dataset number
DSNUMBER="$1"
shift

# Create log directory
LOG_PATH="/expanse/projects/nemar/openneuro/processed/logs/${DSNUMBER}"
mkdir -p "$LOG_PATH"

# Create sbatch file
SBATCH_FILE="${LOG_PATH}/${DSNUMBER}_sbatch"

# Write SLURM job script
cat > "$SBATCH_FILE" << EOF
#!/bin/bash
#SBATCH -J $DSNUMBER
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --mem=240G
#SBATCH -o ${LOG_PATH}/${DSNUMBER}.out
#SBATCH -e ${LOG_PATH}/${DSNUMBER}.err
#SBATCH -t 10:00:00
#SBATCH --account=csd403
#SBATCH --no-requeue
#SBATCH --cpus-per-task=2
#SBATCH --ntasks-per-node=1

cd /home/dtyoung/NEMAR-pipeline
module load matlab/2022b
EOF

# Construct MATLAB command with arguments
MATLAB_ARGS="run_pipeline('${DSNUMBER}'"

# Process additional arguments
while [ $# -gt 0 ]; do
    # Check if argument is numeric or a string
    if [[ "$1" =~ ^[0-9]+$ ]] || [[ "$1" =~ ^[01]$ ]]; then
        MATLAB_ARGS+=", $1"
    else
        MATLAB_ARGS+=", '$1'"
    fi
    shift
done

# Complete the MATLAB command
echo "matlab -nodisplay -r \"${MATLAB_ARGS}); exit;\"" >> "$SBATCH_FILE"

# Make the sbatch file executable
chmod +x "$SBATCH_FILE"

# Submit the job
sbatch "$SBATCH_FILE"
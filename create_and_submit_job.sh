#!/bin/bash
dsnumber="$1"
path="/expanse/projects/nemar/openneuro/processed/logs"

sbatchfile="$path/$1sbatch"
echo "#!/bin/bash" > $sbatchfile
echo "#SBATCH -J $dsnumber" >> $sbatchfile
echo "#SBATCH --partition=compute" >> $sbatchfile
echo "#SBATCH --nodes=1" >> $sbatchfile
echo "#SBATCH --mem=240G" >> $sbatchfile
echo "#SBATCH -o $path/$dsnumber.out" >> $sbatchfile
echo "#SBATCH -e $path/$dsnumber.err" >> $sbatchfile
echo "#SBATCH -t 48:00:00" >> $sbatchfile
echo "#SBATCH --account=csd403" >> $sbatchfile
echo "#SBATCH --no-requeue" >> $sbatchfile
echo "#SBATCH --ntasks-per-node=1" >> $sbatchfile

echo "" >> $sbatchfile
echo "cd /home/dtyoung/NEMAR-pipeline" >> $sbatchfile
echo "module load matlab/2022b" >> $sbatchfile
echo "matlab -nodisplay -r \"run_pipeline('$dsnumber', 'maxparpool', 4, 'modeval', 'resume');\"" >> $sbatchfile

sbatch $sbatchfile

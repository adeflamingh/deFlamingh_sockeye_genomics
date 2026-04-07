#!/bin/bash
# ----------------SLURM Parameters----------------
#SBATCH -p normal
#SBATCH -n 1
#SBATCH --mem=16g
#SBATCH -N 1
#SBATCH --mail-user=<email>
#SBATCH --mail-type=ALL
#SBATCH -J <jobname>

module load R/3.3.3-IGB-gcc-4.9.4
module load Python/3.6.1-IGB-gcc-4.9.4

sample_names=$(cat namelist_test.txt) #same name list as in the GWH_perind.sh file

for sample in $sample_names
do
    echo ${sample} >> heteroz_R_results.txt
    Rscript heteroz_ml.R ${sample} >> heteroz_R_results.txt #make sure this code is copied to the same folder from which you are executing this slurm script

done

paste - - < heteroz_R_results.txt | sed 's/\[1\] //; s/\t/,/' > heteroz_R_results.csv #this file contains GWH for all individuals in the order in which they occur in the name list (names are also added to first column)



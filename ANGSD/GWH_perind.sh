#!/bin/bash
# ----------------SLURM Parameters----------------
#SBATCH -p normal
#SBATCH -n 1
#SBATCH --mem=490g
#SBATCH -N 1
#SBATCH --mail-user=<email>
#SBATCH --mail-type=ALL
#SBATCH -J <jobname>
# ----------------Load Modules--------------------
module load ANGSD/0.933-IGB-gcc-4.9.4
module load SAMtools/1.9-IGB-gcc-4.9.4
module load R/3.3.3-IGB-gcc-4.9.4
module load Python/3.6.1-IGB-gcc-4.9.4
# ----------------Commands------------------------
#!/bin/bash

cd <path to working directory>

# Input files
bam_filelist="<path to same textfile as the one used in ANGSD gl estimation for bams with > 50% coverage>"

names_filelist="<path to a seperate file that contains the names of each of the samples, one name per line. This could be the same as the bam list but without the .bam extension. this file is used to keep track of names under which output is saved>"

# Read BAM paths and sample names into arrays
mapfile -t bam_paths < "$bam_filelist"
mapfile -t sample_names < "$names_filelist"

# Check that the files have the same number of lines
if [ "${#bam_paths[@]}" -ne "${#sample_names[@]}" ]; then
    echo "Error: The number of BAM paths and sample names must match."
    echo "BAMs: ${#bam_paths[@]}, Names: ${#sample_names[@]}"
    exit 1
fi

# Loop through both arrays in parallel
for i in "${!sample_names[@]}"; do
    bam="${bam_paths[$i]}"
    sample="${sample_names[$i]}"
    
    echo "Processing sample: $sample"
    echo "Using BAM: $bam"

    angsd -i "$bam" -anc <path to genome fasta> -out "$sample"  -minQ 30 -dosaf 1 -noTrans 1 -gl 1 #use noTrans for ancient DNA damage correction
    realSFS "${sample}.saf.idx" > "${sample}.ml" # use heteroz & R code in this folder to make a table of GWH of all individuals
    
done

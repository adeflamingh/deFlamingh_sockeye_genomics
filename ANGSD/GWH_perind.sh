#!/bin/bash
# ----------------SLURM Parameters----------------
#SBATCH -p normal
#SBATCH -n 1
#SBATCH --mem=490g
#SBATCH -N 1
#SBATCH --mail-user=deflami2@illinoise.edu
#SBATCH --mail-type=ALL
#SBATCH -J het_noT_Sock_test
# ----------------Load Modules--------------------
module load ANGSD/0.933-IGB-gcc-4.9.4
module load SAMtools/1.9-IGB-gcc-4.9.4
module load R/3.3.3-IGB-gcc-4.9.4
module load Python/3.6.1-IGB-gcc-4.9.4
# ----------------Commands------------------------
#!/bin/bash

cd /home/labs/malhi_lab/paleogenomics/deflami2/sockeye/results/angsd/GWH_noTrans

# Input files
bam_filelist="/home/labs/malhi_lab/paleogenomics/deflami2/sockeye/bamlist_137indv_50percCov.txt"
#bam_filelist="bamlist_137indv_50percCov_test.txt"
names_filelist="namelist_137.txt"

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

    angsd -i "$bam" \
          -anc /home/labs/malhi_lab/paleogenomics/deflami2/PopGLen_testing/20250825-salmon-aln/results/ref/sock02_scaffolds_final_20250516/sock02_scaffolds_final_20250516.fa \
          -out "$sample" \
          -minQ 30 -dosaf 1 -noTrans 1 -gl 1

    realSFS "${sample}.saf.idx" > "${sample}.ml"
done

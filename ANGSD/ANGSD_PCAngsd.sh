#!/bin/bash
# ----------------SLURM Parameters----------------
#SBATCH -p normal
#SBATCH -n 64
#SBATCH --mem=128g
#SBATCH -N 1
#SBATCH --mail-user=deflami2@illinois.edu
#SBATCH --mail-type ALL
#SBATCH -J GL_48_sockeye_all
#SBATCH --time 200:00:00

# ----------------Load Modules--------------------
module load ANGSD/0.933-IGB-gcc-4.9.4
module load SAMtools/1.9-IGB-gcc-4.9.4
module load R/3.3.3-IGB-gcc-4.9.4
module load Python/3.6.1-IGB-gcc-4.9.4

# ----------------ANGSD------------------------
genome=/home/labs/malhi_lab/paleogenomics/deflami2/salmon/angsd/GCF_006149115.2_Oner_1.1_genomic.fna
bamlist=/home/labs/malhi_lab/paleogenomics/deflami2/salmon/angsd/2023/bam.list.2023.txt
cd /home/labs/malhi_lab/paleogenomics/deflami2/salmon/angsd/2023
angsd -GL 1 -out gl_48tot_24min_1e2 -nThreads 64 -doGlf 2 -doMajorMinor 1 -doMaf 2 -SNP_pval 1e-2 -minInd 24 -b ${bamlist} -ref ${genome}

# ----------------PCANGSD------------------------

module purge #needed so that biocluster can load PCAngsd because there are python version issues
module load pcangsd/20220330-IGB-gcc-8.2.0-Python-3.7.2

pcangsd --beagle gl_48tot_24min_1e2.beagle.gz --admix -o pca_48_all --threads 64 


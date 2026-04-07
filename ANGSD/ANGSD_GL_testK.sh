#!/bin/bash
# ----------------SLURM Parameters----------------
#SBATCH -p normal
#SBATCH -n 8
#SBATCH --mem=200g 
#SBATCH -N 1
#SBATCH --mail-user=deflami2@illinois.edu
#SBATCH --mail-type ALL
#SBATCH -J ANGSD_GL_137sockeye_newV_8threads_Ktest

#200g mem for angsd run
#limit threads to 8 - lots of samples and high amount of threads causes ANGSD to terminate with a non-informative error
# ----------------Load Modules--------------------
#module purge
#
#module load ANGSD/0.941-IGB-gcc-8.2.0
#module load SAMtools/1.9-IGB-gcc-4.9.4
#module load R/3.3.3-IGB-gcc-4.9.4
#module load Python/3.6.1-IGB-gcc-4.9.4

# ----------------ANGSD------------------------
genome=/home/labs/malhi_lab/paleogenomics/deflami2/PopGLen_testing/20250825-salmon-aln/results/ref/sock02_scaffolds_final_20250516/sock02_scaffolds_final_20250516.fa
bamlist=/home/labs/malhi_lab/paleogenomics/deflami2/sockeye/bamlist_137indv_50percCov.txt
cd /home/labs/malhi_lab/paleogenomics/deflami2/sockeye/results/angsd

#angsd -b ${bamlist} -doCounts 1 -minQ 30 -minInd 10 -dumpCounts 2 -doDepth 1 -out depth_102indv_minQ30_minInd10 -nThreads 64 

#angsd -GL 1 -out gl_137_Q30_minInd14_newV_8threads -nThreads 8 -doGlf 2 -doMajorMinor 1 -doMaf 2 -SNP_pval 1e-2 -minInd 14 -b ${bamlist} -ref ${genome}

# ----------------PCANGSD------------------------

module purge #needed so that biocluster can load PCAngsd because there are python version issues
module load pcangsd/20220330-IGB-gcc-8.2.0-Python-3.7.2
#
#pcangsd --beagle gl_137_Q30_minInd14_newV_8threads.beagle.gz --admix -o pca_137_50cov_minInd14_newV_8threads --threads 8 #initial run to determine optimal K

for K in {2..10}
do
  pcangsd --beagle gl_137_Q30_minInd14_newV_8threads.beagle.gz  --admix  --admix_K ${K} -o pca_137_50cov_minInd14_newV_8threads_K${K}  --threads 8
done



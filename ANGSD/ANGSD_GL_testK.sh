#!/bin/bash
# ----------------SLURM Parameters----------------
#SBATCH -p normal
#SBATCH -n 8
#SBATCH --mem=200g 
#SBATCH -N 1
#SBATCH --mail-user=<email>
#SBATCH --mail-type ALL
#SBATCH -J <jobname>

#200g mem for angsd run
#limit threads to 8 - lots of samples and high amount of threads causes ANGSD to terminate with a non-informative error
# ----------------Load Modules--------------------
module purge

module load ANGSD/0.941-IGB-gcc-8.2.0
module load SAMtools/1.9-IGB-gcc-4.9.4
module load R/3.3.3-IGB-gcc-4.9.4
module load Python/3.6.1-IGB-gcc-4.9.4

# ----------------ANGSD------------------------
genome=<path to genome fasta>
bamlist=<path to text file containing a list of individual bam names for samples with > 50% coverage across the genome. One bam per line>
cd <path to working directory>

#angsd -b ${bamlist} -doCounts 1 -minQ 30 -minInd 14 -dumpCounts 2 -doDepth 1 -out depth_137indv_minQ30_minInd14 -nThreads 8 # only do this step if you want to verify that your data coverage across SNPs is good enough, or if you want to identify low coverage individuals to remove

angsd -GL 1 -out gl_137_Q30_minInd14_newV_8threads -nThreads 8 -doGlf 2 -doMajorMinor 1 -doMaf 2 -SNP_pval 1e-2 -minInd 14 -b ${bamlist} -ref ${genome} # usually add variables to output name so that you can track analysis - e.g., 137 individuals, quality of 30, 14 minimum individuals, 8threads

# ----------------PCANGSD------------------------

module purge #needed so that biocluster can load PCAngsd because there are python version issues
module load pcangsd/20220330-IGB-gcc-8.2.0-Python-3.7.2

#pcangsd --beagle gl_137_Q30_minInd14_newV_8threads.beagle.gz --admix -o pca_137_50cov_minInd14_newV_8threads --threads 8 #initial run to determine optimal K
#once you have determined the optimal K using the code above, you can use the code below to estimate a range of Ks for admixture plots
for K in {2..10}
do
  pcangsd --beagle gl_137_Q30_minInd14_newV_8threads.beagle.gz  --admix  --admix_K ${K} -o pca_137_50cov_minInd14_newV_8threads_K${K}  --threads 8
done



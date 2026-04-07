# Genome Alignments

This folder contains the following scripts/code

The majority of fastqs were aligned using PopGLen but with the same parameters as the scripts below. The scripts below are for individuals that had multiple sequencing events that were different in Illumina approach (e.g., SE and PE), and for geographic reference samples that were selected after the initial alignment batch were processed. 

### prealign_ancientFASTQs.sh 
This slurm script contains code used to align and merge SE and PE data from ancient salmon fish bone fastqs

### georef_alignment.sh
This slurm contains code for aligning geographic reference fastqs downloaded from SRA. 

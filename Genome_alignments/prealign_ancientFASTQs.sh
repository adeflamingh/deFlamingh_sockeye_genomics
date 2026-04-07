#!/bin/bash
# ----------------SLURM Parameters----------------
#SBATCH -p normal
#SBATCH -n 1
#SBATCH --mem=16g
#SBATCH -N 1
#SBATCH --mail-user=deflami2@illinois.edu
#SBATCH --mail-type=ALL
#SBATCH -J prealned_bam_samplename

#set threads to 16
#check that trimming and alignment parameters are consistent with PopGLen filters/parameters that you choose.
#checked popglen, only -p and -g parameters specified, so just make sure to include the filtering options in the methods description to allow for reproduction


cd /home/labs/malhi_lab/paleogenomics/deflami2/sockeye/

#FILES/VARIABLES

#files to trim, align, merge, dedup in preparation for PopGLen - insert full path so that timmed files are saved in same place, but remove extension so only file/sample name retained
sample_name=''
FQ1='' #SE data
FQ1bam='filename' #hadcode bam file name without extension
FQ2='' #PE data
FQ2bam='filename' #hadcode bam file name without extension
#add files as needed

bamdirectory=givepathtofolder
genome=givepathtofasta.fasta #make sure that genome has been indexed with BWA and SAMtools prior to initiation of this script


#STEP1 TRIMMING
module load fastp/0.23.4 

#for SE trimming 
#results in reads longer than 25bp, and trim polyG if present on 3'
#make sure extension for FQ is correctly added in input -i, also change below if needed
fastp -i ${FQ1} -o ${FQ1}.trimmed.fq.gz  --trim_poly_g  -l 25 --thread 16 --html ${FQ1}.R_fastp.html --json ${FQ1}.R_fastp.json
#copy and repeat for however many sequencing rounds

#for PE trimming
#make sure extension for FQ is correctly added in --in1 and --in2, also change below if needed
fastp --in1 ${FQ2}_R1_001.fastq.gz --in2 ${FQ2}_R2_001.fastq.gz --out1 ${FQ2}.R1.pG.trimmed.fq.gz --out2 ${FQ2}.R2.pG.trimmed.fq.gz --detect_adapter_for_pe --trim_poly_g  -l 25 --thread 16 --html ${FQ2}_R_fastp.html --json ${FQ2}_R_fastp.json
#copy and repeat for however many sequencing rounds

#STEP2 ALIGNING AND DEDUP1
module purge
module load BWA
module load SAMtools
module load picard #check that this is okay

#for SE aln in bwa
bwa mem -M -t 16 ${genome} ${FQ1}.trimmed.fq.gz | samtools sort -@16 -o ${bamdirectory}/${FQ1bam}.aln.raw.bam - 
picard MarkDuplicates I=${bamdirectory}/${FQ1bam}.aln.raw.bam O=${bamdirectory}/${FQ1bam}_marked_dups.bam M=${bamdirectory}/${FQ1bam}_marked_dup_metrics.txt
samtools view -bh -q 25 -F 4 -F 1024 ${bamdirectory}/${FQ1bam}_marked_dups.bam >  ${bamdirectory}/${FQ1bam}.dedup.filt.bam

#for PE aln in bwa
bwa mem -M -t 16 ${genome1} ${bamdirectory}/${FQ2bam}.R1.pG.trimmed.fq.gz ${bamdirectory}/${FQ2bam}.R2.pG.trimmed.fq.gz | samtools sort -@16 -o ${bamdirectory}/${FQ2bam}.aln.raw.bam -
picard MarkDuplicates I=${bamdirectory}/${FQ2bam}.aln.raw.bam O=${bamdirectory}/${FQ2bam}_marked_dups.bam M=${bamdirectory}/${FQ2bam}_marked_dup_metrics.txt
samtools view -bh -q 25 -F 4 -F 1024 ${bamdirectory}/${FQ2bam}_marked_dups.bam >  ${bamdirectory}/${FQ2bam}.dedup.filt.bam

#STEP3 MERGE
samtools merge -o ${bamdirectory}/${sample_name}_premerged.bam -@ 16 ${bamdirectory}/${FQ1bam}.dedup.filt.bam ${bamdirectory}/${FQ2bam}.dedup.filt.bam #add all bams here
samtools sort -@ 16 -o ${bamdirectory}/${sample_name}_merged.bam ${bamdirectory}/${sample_name}_premerged.bam

#STEP4 DEDUP2 ON FINAL BAM (FINAL OUTPUT WHICH WILL BE INPUT IN POGLEN)
picard MarkDuplicates I=${bamdirectory}/${sample_name}_merged.bam O=${bamdirectory}/${sample_name}_merged_marked_dups.bam M=${bamdirectory}/${sample_name}_merged_marked_dup_metrics.txt
samtools view -bh -q 25 -F 4 -F 1024 -@ 16 ${bamdirectory}/${sample_name}_merged_marked_dups.bam >  ${bamdirectory}/${sample_name}_merged.dedup.filt.bam

##run alignment stats 
echo ${sample_name} >> ${bamdirectory}/${sample_name}.merged.alnstats.txt
echo "---"  >> ${bamdirectory}/${sample_name}.merged.alnstats.txt
echo "depth" >> ${bamdirectory}/${sample_name}.merged.alnstats.txt
samtools depth -a ${bamdirectory}/${sample_name}_merged.dedup.filt.bam |	awk '{c++;s+=$3}END{print s/c}' >> ${bamdirectory}/${sample_name}.merged.alnstats.txt
echo "breadth" >> ${bamdirectory}/${sample_name}.merged.alnstats.txt
samtools depth -a ${bamdirectory}/${sample_name}_merged.dedup.filt.bam  |	awk '{c++; if($3>0) total+=1}END{print (total/c)*100}' >> ${bamdirectory}/${sample_name}.merged.alnstats.txt

#verify that script works before running these (so that you don't loose intermediate files), also add additional FQs
#rm  ${bamdirectory}/${FQ1bam}.aln.raw.bam
#rm  ${bamdirectory}/${FQ1bam}_marked_dups.bam
#rm  ${bamdirectory}/${FQ1bam}.dedup.filt.bam
#rm  ${bamdirectory}/${FQ2bam}.aln.raw.bam
#rm  ${bamdirectory}/${FQ2bam}_marked_dups.bam
#rm  ${bamdirectory}/${FQ2bam}.dedup.filt.bam
#rm  ${bamdirectory}/${sample_name}_premerged.bam
#rm ${bamdirectory}/${sample_name}_merged.bam
#rm ${bamdirectory}/${sample_name}_merged_marked_dups.bam





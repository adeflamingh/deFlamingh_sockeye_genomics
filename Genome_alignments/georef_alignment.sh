#!/bin/bash
# ----------------SLURM Parameters----------------
#SBATCH -p normal
#SBATCH -n 16
#SBATCH --mem=60g
#SBATCH -N 1
#SBATCH --mail-user=deflami2@illinois.edu
#SBATCH --mail-type=ALL
#SBATCH -J sock_dup_issue_popglen

#set threads to 16
#check that trimming and alignment parameters are consistent with PopGLen filters/parameters that you choose.
#checked popglen, only -p and -g parameters specified, so just make sure to include the filtering options in the methods description to allow for reproduction


cd /home/labs/malhi_lab/paleogenomics/deflami2/sockeye/raw_data/modern/PE/georef_data/broader
sample_names=$(ls /home/labs/malhi_lab/paleogenomics/deflami2/sockeye/raw_data/modern/PE/georef_data/broader/*.fastq | sed 's#.*/##; s/_.*$//' | sort -u) 
genome=/home/labs/malhi_lab/paleogenomics/data/genomes/salmon/sock02_scaffolds_final_20250516.fa
bamdirectory=/home/labs/malhi_lab/paleogenomics/deflami2/sockeye/results/georef_bams

##STEP1 TRIMMING
#module load fastp/0.23.4 
for sample in $sample_names
do
    fastp --in1 ${sample}_1.fastq --in2 ${sample}_2.fastq --out1 ${bamdirectory}/${sample}.R1.pG.trimmed.fq.gz --out2 ${bamdirectory}/${sample}.R2.pG.trimmed.fq.gz --detect_adapter_for_pe --trim_poly_g  -l 25 --thread 16 --html ${bamdirectory}/${sample}_R_fastp.html --json ${bamdirectory}/${sample}_R_fastp.json
done

#STEP2 ALIGNING AND DEDUP1
module purge
#module load BWA
module load SAMtools
module load picard #check that this is okay

for sample in $sample_names
do
    bwa mem -M -t 16 ${genome} ${bamdirectory}/${sample}.R1.pG.trimmed.fq.gz ${bamdirectory}/${sample}.R2.pG.trimmed.fq.gz | samtools sort -@16 -o ${bamdirectory}/${sample}.aln.raw.bam -
    picard AddOrReplaceReadGroups  I=${bamdirectory}/${sample}.aln.raw.bam O=${bamdirectory}/${sample}.aln.rg.bam RGID=SRR11608368 RGLB=lib1  RGPL=ILLUMINA RGPU=unit1 RGSM=SRR11608368 #SRA downloads lack rg so we need to do this replacement so that picard can parse them
    picard MarkDuplicates -I ${bamdirectory}/${sample}.aln.rg.bam -O ${bamdirectory}/${sample}_marked_dups_pgl.bam -M ${bamdirectory}/${sample}_marked_dup_metrics_pgl.txt --REMOVE_DUPLICATES true --OPTICAL_DUPLICATE_PIXEL_DISTANCE 2500 #from popglen
    samtools view -bh -F 4 ${bamdirectory}/${sample}_marked_dups_pgl.bam >  ${bamdirectory}/${sample}_pgl.dedup.mapped.bam
done

#from popGLen --REMOVE_DUPLICATES true --OPTICAL_DUPLICATE_PIXEL_DISTANCE 2500

#STEP3 ALIGNMENT STATS  
for sample in $sample_names
do
    echo ${sample} >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    echo "---"  >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    echo "depth .aln.raw.bam" >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    samtools depth -a ${bamdirectory}/${sample}.aln.raw.bam |	awk '{c++;s+=$3}END{print s/c}' >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    echo "breadth .aln.raw.bam" >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    samtools depth -a ${bamdirectory}/${sample}.aln.raw.bam  |	awk '{c++; if($3>0) total+=1}END{print (total/c)*100}' >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    echo "---"  >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    echo "depth _pgl.dedup.mapped.bam" >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    samtools depth -a ${bamdirectory}/${sample}_pgl.dedup.mapped.bam |	awk '{c++;s+=$3}END{print s/c}' >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    echo "breadth _pgl.dedup.mapped.bam" >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    samtools depth -a ${bamdirectory}/${sample}_pgl.dedup.mapped.bam  |	awk '{c++; if($3>0) total+=1}END{print (total/c)*100}' >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    echo "---"  >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    echo "depth _marked_dups_pgl.bam" >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    samtools depth -a ${bamdirectory}/${sample}_marked_dups_pgl.bam|	awk '{c++;s+=$3}END{print s/c}' >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    echo "breadth _marked_dups_pgl.bam" >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    samtools depth -a ${bamdirectory}/${sample}_marked_dups_pgl.bam  |	awk '{c++; if($3>0) total+=1}END{print (total/c)*100}' >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    echo "---"  >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    echo "FLAGSTATS"  >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    echo "aln.raw.bam" >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    samtools flagstat ${bamdirectory}/${sample}.aln.raw.bam >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    echo "_pgl.dedup.mapped.bam" >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    samtools flagstat ${bamdirectory}/${sample}_pgl.dedup.mapped.bam >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    echo "_marked_dups_pgl.bam" >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt
    samtools flagstat ${bamdirectory}/${sample}_marked_dups_pgl.bam >> ${bamdirectory}/${sample}_pgl.new.alnstats.txt 
done


#!/bin/bash
# ----------------SLURM Parameters----------------
#SBATCH -p normal
#SBATCH -n 16
#SBATCH --mem=60g
#SBATCH -N 1
#SBATCH --mail-user=<email>
#SBATCH --mail-type=ALL
#SBATCH -J <job name>

cd <path to working directory>
sample_names=$(ls *.fastq | sed 's#.*/##; s/_.*$//' | sort -u) 
genome=<path to genome fasta>
bamdirectory=< path to directory containing bams>

##STEP1 TRIMMING
module load fastp/0.23.4 #fastp and bwa also work on .gz files, no need to decompress unless needed for other analysis. 
for sample in $sample_names
do
    fastp --in1 ${sample}_1.fastq --in2 ${sample}_2.fastq --out1 ${bamdirectory}/${sample}.R1.pG.trimmed.fq.gz --out2 ${bamdirectory}/${sample}.R2.pG.trimmed.fq.gz --detect_adapter_for_pe --trim_poly_g  -l 25 --thread 16 --html ${bamdirectory}/${sample}_R_fastp.html --json ${bamdirectory}/${sample}_R_fastp.json
done

#STEP2 ALIGNING AND DEDUP1
module purge
#module load BWA
module load SAMtools
module load picard 

for sample in $sample_names
do
    bwa mem -M -t 16 ${genome} ${bamdirectory}/${sample}.R1.pG.trimmed.fq.gz ${bamdirectory}/${sample}.R2.pG.trimmed.fq.gz | samtools sort -@16 -o ${bamdirectory}/${sample}.aln.raw.bam -
    picard AddOrReplaceReadGroups  I=${bamdirectory}/${sample}.aln.raw.bam O=${bamdirectory}/${sample}.aln.rg.bam RGID=${sample} RGLB=lib1  RGPL=ILLUMINA RGPU=unit1 RGSM=${sample} #SRA downloads lack rg so we need to do this replacement so that picard can parse them, usually not needed for regular fastqs
    picard MarkDuplicates -I ${bamdirectory}/${sample}.aln.rg.bam -O ${bamdirectory}/${sample}_marked_dups_pgl.bam -M ${bamdirectory}/${sample}_marked_dup_metrics_pgl.txt --REMOVE_DUPLICATES true --OPTICAL_DUPLICATE_PIXEL_DISTANCE 2500 #from popglen
    samtools view -bh -F 4 ${bamdirectory}/${sample}_marked_dups_pgl.bam >  ${bamdirectory}/${sample}_pgl.dedup.mapped.bam
done


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

#remember to delete intermediate files if needed.

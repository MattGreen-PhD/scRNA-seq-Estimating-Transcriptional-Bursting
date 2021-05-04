

#!/bin/bash
# Author: Matt Graan
# Date: 4/17/20
# This script will pre-process Smart-Seq single cell RNA Seq data to ultimately get allele-specific read counts
#SBATCH -J SmartSeq_1
#SBATCH -o %A_%a.out.txt
#SBATCH -e %A_%a.err.txt
#SBATCH --mem=30G
#SBATCH -n 12
#SBATCH --mail-type=END
#SBATCH --mail-user=mg443@duke.edu

#Load modules
module load fastqc
#module load TrimGalore
module load cutadapt
module load STAR
module load htslib
module load samtools
module load jdk/1.8.0_45-fasrc01
module load GATK

#Set variables/directories
genomeDir='/data/westlab/Gencodefiles/STAR_mm10_2.7.2b/'
GTF='/data/westlab/Gencodefiles/gencode.vM21.chr_patch_hapl_scaff.annotation.gtf'
QC='/data/westlab/Matt/MOp/QC/'
QC_2='/data/westlab/Matt/MOp/QC_2/'
Trim='/data/westlab/Matt/Modules/TrimGalore-0.6.5/trim_galore'
gvcf='/data/westlab/Matt/MOp/modules/gvcftools/gvcftools-0.16/bin/extract_variants'
BAM='/data/westlab/Matt/MOp/BAM/'
CRAM='/data/westlab/Matt/MOp/CRAM/'
BAM_Cigar='/data/westlab/Matt/MOp/BAM_Cigar/'
VCF='/data/westlab/Matt/MOp/VCF_files/'
picard=/data/westlab/Matt/MOp/Jar_files/picard/build/libs/picard.jar
fasta='/data/westlab/Gencodefiles/'
tempDB='/data/westlab/Matt/MOp/temp_GenomicsDB/'
DB='/data/westlab/Matt/MOp/fastqs/my_database/'
CRAM_split='/data/westlab/Matt/MOp/CRAM_split/'
testing='/data/westlab/Matt/MOp/testing/'

#unzip if zipped
echo unzipping...
for samp in $(cat samples_1.txt)
do
        if [ -e $samp'.fastq.gz' ]
        then
                gunzip $samp'.fastq.gz'
        fi
done

#run fastqc
for samp in $(cat seq.names.txt)
do
        fastqc $samp'.fastq' --outdir $QC
done

#trim reads
echo Trimming...
for samp in $(cat seq.names-R1orR2.txt)
do
        $Trim --paired $samp'_R1.fastq' $samp'_R2.fastq'\
        #--path_to_cutadapt /nfs/software/helmod/apps/Core/cutadapt/2.3-gcb01/bin/cutadapt\
        -o $QC_2\
        --fastqc_args $QC
done

#run fastqc
for samp in $(cat seq.names.txt)
do
        fastqc $samp'_val_2.fq' --outdir $QC_2
done

#Align genome
echo aligning...
for samp in $(cat samples-R1orR2_1.txt)
do
        STAR --outSAMtype BAM SortedByCoordinate --outSAMmapqUnique 60 --genomeDir $genomeDir --readFilesIn $samp'_R1.fastq' $samp'_R2.fastq' --twopassMode Basic --outFilterIntronMotifs RemoveNoncanonicalUnannotated --outFileNamePrefix $samp --runThreadN 8
done

#filter step
echo filtering reads..
for samp in $(cat samples-R1orR2_1.txt)
do
samtools view -F 4 -b -h -o $BAM$samp'AcceptedHits.bam' $samp'Aligned.sortedByCoord.out.bam'
done

#Add read groups and index
echo AddOrReplaceReadGroups...
for samp in $(cat samples-R1orR2_1.txt)
do
java -Xmx30G -jar $picard AddOrReplaceReadGroups INPUT=$BAM$samp'AcceptedHits.bam' OUTPUT=$BAM$samp'AcceptedHits.rg.bam' RGID=$Samp'RGID' RGLB=scRNA_seq_$samp'MOp' RGPL=ILLUMINA RGPU=machine RGSM=$samp; samtools index $samp'AcceptedHits.rg.bam'
done

#Compress bam to cram
echo Compressing bam...
for samp in $(cat samples-R1orR2_1.txt)
do
gatk PrintReads\
        -I $BAM$samp'AcceptedHits.rg.bam'\
        -O $CRAM$samp'_compressed.cram'\
        -R $fasta'GRCm38.p6.genome.fa'
done

#SplitNCigarReads
echo Splitting N Cigar Reads...
for samp in $(cat samples-R1orR2_1.txt)
do
gatk SplitNCigarReads\
        -R $fasta'GRCm38.p6.genome.fa'\
        -I $CRAM$samp'_compressed.cram'\
        -O $CRAM_split$samp'_split.cram'
done

#GATK HaplotypeCaller
echo HaplotypeCaller...
for samp in $(cat samples-R1orR2_1.txt)
do

gatk --java-options "-Xmx24g" HaplotypeCaller\
        -R $fasta'GRCm38.p6.genome.fa'\
        -I $BAM_Cigar'SM-D9D7W_S93_E1-50AcceptedHits_Cigar.bam_compressed.cram.bam'\
        -O $VCF'SM-D9D7W_S93_E1-50AcceptedHits_Cigar.vcf.gz'\
        -G StandardAnnotation\
        -G AS_StandardAnnotation\
        -G StandardHCAnnotation\
        --native-pair-hmm-threads 24\
        -L intervals.list


'''
for samp in $(cat $VCF'gvcfs.list')
do
gzip -dc $VCF$samp | $gvcf | bgzip -c > $testing$samp'.vcf.gz'
done
'''
####IF INITIATING DATABASE
#ImportGenomicsDB GATK
echo ImportGenomicsDB...
gatk --java-options "-Xmx4g -Xms4g" GenomicsDBImport\
        --genomicsdb-workspace-path my_database\
        -L intervals.list\
        --sample-name-map vcf_mapfile.txt\
        --tmp-dir=$tempDB\
        -G StandardAnnotation\
        -G AS_StandardAnnotation\
        --reader-threads 24

####IF APPENDING TO DATABASE
echo adding to GenomicsDB...
gatk GenomicsDBImport\
        --samples-name-map vcf_mapfile.txt\
        --genomicsdb-update-workspace-path $DB

#--genomicsdb-workspace-path my_database\
#--genomicsdb-update-workspace-path my_database\
#-V LS-15395_S48_E1-50.g.vcf.gz\

#Genotype GVCFs
echo Running GenotypeGVCFs...
gatk --java-options "-Xmx24g" GenotypeGVCFs\
        -R $fasta'GRCm38.p6.genome.fa'\
        -V gendb://my_database\
        -O output.vcf.gz\
        -G StandardAnnotation\
        -G AS_StandardAnnotation
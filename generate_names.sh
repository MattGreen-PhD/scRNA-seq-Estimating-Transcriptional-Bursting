#!/bin/bash
# Author: Matt Graan
# Date: 4/17/20
# This script will generate a text file containing the names of the files in order to loop over at each step in the pre-processing
#SBATCH -J SmartSeq1
#SBATCH -o %A_%a.out.txt
#SBATCH -e %A_%a.err.txt
#SBATCH --mem=10G
#SBATCH -n 4
#SBATCH --mail-type=END
#SBATCH --mail-user=mg443@duke.edu

#Generate seq.names.txt file, and seq.names-R1orR2.txt file and remove ending 'fastq.gz' from each file
#ls *.fastq.gz > seq.names.txt

VCF_2='/data/westlab/Matt/MOp/VCF_files_2/'

sed -i 's/$/    /g' $VCF_2'output.bed'


#sort seq.names.txt | uniq > sample.names.txt
#rm seq.names.txt

#ls *.fastq.gz > seq.names.txt
#sed -i 's/\_R1.fastq.gz//g' seq.names.txt
#sed -i 's/\_R2.fastq.gz//g' seq.names.txt
#sort seq.names.txt | uniq > seq.names-R1orR2.txt
#rm seq.names.txt
~                   
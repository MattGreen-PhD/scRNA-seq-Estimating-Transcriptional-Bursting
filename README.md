# scRNA-seq-Estimating-Transcriptional-Bursting
This pipeline is designed to generate allele-specific read counts and use the SCALE pipeline to estimate transcriptional bursting kinetics genome-wide from scRNA-seq data.

Multiple scripts are necessary for each respective step in the pipeline due to the processing load. Steps are broken up to allow for individual job submissions on the cluster.

Order of execution with explanation

Note: Use each script in it's respective folder, or change directory inside

1. Download files from website

run download.sh in 'tar_files' folder, change the .txt file to contain the respective files you wish to download, if doing it in small batches

2. Open tar files into fastq files and transfer to 'fastq' folder

run 'batch_open_tar.sh' in 'tar_files' folder
*Don't have to change anything inside each time

3. Generate the two name files that the Preprocess script will use for looping through

Run generate_namesfiles.sh
###This will generate two files, one that contains the file names -R1 or -R2, and one that contains the file with R1 and R2 still in the name

3.5 NOTE: here you can vim and edit the sample.names.txt file and the seq.names-R1orR2 files to run just the samples that you want, I run 25 over the course of 24 hrs

4. Run alignment and generate vcf files per sample

Can enter 'srun --pty /bin/bash' and submit job with sbatch Preprocess.slurm

5. Move to VCF_files folder and run CombineVCFs.slurm

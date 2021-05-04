library(data.table)
library(stringr)

#Read in all text from website
links=fread("http://data.nemoarchive.org/biccn/lab/zeng/transcriptome/scell/SMARTer/raw/MOp/")
#Select column with info you want
links=links[,1]
#Only take rows with info you want
links_sub=str_subset(links,"href")
#Separate after 'href=\\\'
links_split=str_split(links_sub,"href=\\\\\"")
#remove everything after 'tar'
files=sapply(links_split,function(x) gsub("(tar).*","\\1",as.character(x)))
#Generate sample names from file names
files=files[-1]

#Add in http... string to each name
full_files=lapply(files,function(x) paste0('http://data.nemoarchive.org/biccn/lab/zeng/transcriptome/scell/SMARTer/raw/MOp/',x))
string_files=toString(full_files)
string_files=noquote(unlist(strsplit(string_files,",")))
samples_files=toString(files)
samples_files=noquote(unlist(strsplit(samples_files,",")))
samples=sapply(samples_files,function(x) gsub(".fastq.tar","",x))
#setwd for output
setwd('C:/Users/mattg/Desktop')
#create txt file for files
write.table(noquote(string_files),file="file_names.txt",sep="\t",col.names=F,row.names=F,quote=F)
#Create txt file for samples
write.table(noquote(samples),file="sample_names.txt",sep="\t",col.names=F,row.names=F,quote=F)

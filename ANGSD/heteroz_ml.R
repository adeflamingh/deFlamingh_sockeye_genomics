
#created by Alida de Flamingh
#code for processing ml output files from ANGSD global hetero estimatio
args=(commandArgs(TRUE))
PREFIX=as.character(args[1])

a<-scan(paste(PREFIX, '.ml', sep=''))
#a
het<-a[2]/sum(a)
het

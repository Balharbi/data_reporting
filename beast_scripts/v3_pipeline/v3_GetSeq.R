##################################################
##  Script to get sequence (not SNV/SNP masked)
##  around SNV or indels to design primers for
##       Targeted resequencing on the MiSeq
##  Aparicio Lab WSOP 2013-001 developed by
##       Dr Damian Yap , Research Associate
##       dyap@bccrc.ca  Version 3.0 (Sep 2013)
##  Pipeline use gets parse args from html form
##################################################

# These commands must be specifed in order for this script to work
# source("http://www.bioconductor.org/biocLite.R"); 
# source("http://www.bioconductor.org/biocLite.R"); biocLite("BSgenome"); 
# biocLite("BSgenome.Hsapiens.UCSC.hg19"); library('BSgenome.Hsapiens.UCSC.hg19')

library('BSgenome.Hsapiens.UCSC.hg19')

# if run directly uncomment the sample name
# Command line `Rscript ~/Scripts/GetSeq.R --no-save --no-restore --args $dir/$sample/$file`

# This takes the 4th argument (see str above) which is sample name
args <- commandArgs(trailingOnly = TRUE)
input <- args[4]

# To test this programme in R using source
# commandArgs <- function() "TEST/123/20130926214630"
# source(file="~/Scripts/v3_pipeline/GetSeq.R")
# For testing only uncomment for production
# input <- "Tumour_Xenograft/SA494/SA494_p3_positions.txt"

Project <- strsplit(input, split="/")[[1]][1]
name <- strsplit(input, split="/")[[1]][2]
posfile <- strsplit(input, split="/")[[1]][3]

print("Directory")
print(Project)
print("Sample_ID")
print(name)
print("File")
print(posfile)


# all files from this point should be hg19
infile=paste(name, "p3_positions.txt", sep="_")

homebase="/home/dyap/Projects/PrimerDesign"
setwd(homebase)

basedir=paste(homebase,Project,sep="/")
setwd(basedir)

system('mkdir positions')
system('mkdir Annotate')
system('mkdir primer3')

#############################################
# Save input files under $homebase/positions#
#############################################

##############################################
######   User defined variables         ######
# Directory and file references
sourcedir=paste(basedir,"positions", sep="/")
p3dir=paste(basedir,"primer3", sep="/")
annpath=paste(basedir,"Annotate", sep="/")

############ name processing #################

######################
# These are the input files
input=paste(sourcedir,posfile,sep="/")

#######################################
# This is the name of the primer3 design file 
p3file=paste(name,"p3_design.txt",sep="_")
outfile=paste(p3dir,p3file,sep="/")

###############################################
file1 = paste(annpath, paste(name, "Annotate.csv", sep="_") ,sep="/")

###############################################
file2 = paste(sourcedir, paste(name, "positions.txt", sep="_") ,sep="/")


# offsets (sequences on either side of SNV,indel for matching only)
WToffset=5

snpdf <- read.csv(file=input,  stringsAsFactors = FALSE, header= FALSE)

# For positions

posdf <- data.frame(Chr = rep("", nrow(snpdf)),
                     Pos1 = rep(0, nrow(snpdf)),
                     ID = rep("", nrow(snpdf)),
                     stringsAsFactors = FALSE)

# For annotation files

andf <- data.frame(Chr = rep("", nrow(snpdf)),
                     Pos1 = rep(0, nrow(snpdf)),
                     Pos2 = rep(0, nrow(snpdf)),
                     WT = rep("", nrow(snpdf)),
                     SNV = rep("", nrow(snpdf)),
                     stringsAsFactors = FALSE)
                  
# For SNV matching

outdf <- data.frame(ID = rep("", nrow(snpdf)),
                     Chr = rep("", nrow(snpdf)),
                     Pos1 = rep(0, nrow(snpdf)),
                     Pos2 = rep(0, nrow(snpdf)),
                     SNV = rep("", nrow(snpdf)),
                     Cxt = rep("", nrow(snpdf)),
                     Seq = rep("", nrow(snpdf)),
                     stringsAsFactors = FALSE)
                     
offset <- 5
                     
for (ri in seq(nrow(snpdf))) {
  chr <- paste("chr",strsplit(snpdf[ri,2],split=":")[[1]][1],sep="")
  position1 <- as.numeric(strsplit(strsplit(snpdf[ri,2],split=":")[[1]][2], split="-")[[1]][1])

# for SNV the position is the same for both
  position2 <- as.numeric(strsplit(strsplit(snpdf[ri,2],split=":")[[1]][2], split="-")[[1]][2])
  sample <- strsplit(snpdf[ri,1],split="_")[[1]][1]
  sequence <- snpdf[ri,3]

  wt <- as.character(getSeq(Hsapiens,chr,position1,position1))
  cxt <- as.character(paste(getSeq(Hsapiens,chr,position1-offset,position1),
              getSeq(Hsapiens,chr,position2+1,position2+offset),
              sep=''))  

  outdf$ID[ri] <- paste(paste(sample, chr, sep="_"), position1, sep="_")
  outdf$Chr[ri] <- chr
  outdf$Pos1[ri] <- position1
  outdf$Pos2[ri] <- position2
  outdf$SNV[ri] <- wt
  outdf$Cxt[ri] <-cxt
  outdf$Seq[ri] <- sequence

print(outdf$ID[ri])

  posdf$ID[ri] <- outdf$ID[ri]
  posdf$Chr[ri] <- outdf$Chr[ri]
  posdf$Pos1[ri] <- outdf$Pos1[ri]

# Fake the SNV to be just the complement of WT position (as SNV allele is not known)

if (wt=="A") snv <- "T"
if (wt=="C") snv <- "G"
if (wt=="G") snv <- "C"
if (wt=="T") snv <- "A"
  
  andf$Chr[ri] <- gsub("chr","", outdf$Chr[ri])
  andf$Pos1[ri] <- outdf$Pos1[ri]
  andf$Pos2[ri] <- outdf$Pos2[ri]
  andf$WT[ri] <- outdf$SNV[ri]
  andf$SNV[ri] <-snv

  }

# Output file design.csv

print(outdf)
write.csv(outdf, file = outfile )

# Output file positions.txt

print(posdf)
write.csv(posdf, file = file2 )

# Format for ANNOVAR  <15 43762161 43762161 T C>

print(andf)
write.csv(andf, file = file1)

print("GetSeq.R complete...")

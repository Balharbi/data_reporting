# This script reads all the excel files and extracts ALL the Sample IDs from them
library(XLConnect)
library(plyr)
library(dplyr)
library(RCurl)

# This is where all the relevant excel spreadsheets may lie on MONCO
dir="/Volumes/Monco/Aparicio Lab - Projects/BreastCancerOutcomesUnitRelated/TNBC files/"
setwd(dir)

# This is the RNA-seq file
rnaseqfile="RNA-Seq libraries_Aparicio 2012May16 edited.xls"
rnaseq<-readWorksheetFromFile(file=rnaseqfile,sheet = c("Sheet1"), header=TRUE)

# Cut and paste from TN inventory Summary 2015June15.xls (first 4 cols and remove subheadings manually)
inventoryfile="TN inventory Summary 2015June15.xls"
collabID="Sample_matches"
codes<-read.table(collabID, sep="\t", header=TRUE, dec=".",stringsAsFactors = FALSE)
master_IHC<-readWorksheetFromFile(file=inventoryfile,sheet = c("Master_seq_IHC"), header=TRUE)
master_summary<-readWorksheetFromFile(file=inventoryfile,sheet = c("summary"), header=TRUE)

sampleIHC="TN_IHC.XLS"
IHC<-readWorksheetFromFile(file=sampleIHC,sheet = c("Sheet1"), header=TRUE)

# This is from TNBC-27 JIRA ticket cut and paste on 31 May 2017
#tnbc="TNBC-27_103.txt"
tnbc="TNBC_103_LIB.txt"
tnbc_seq<-read.table(tnbc, sep="\t", header=FALSE,stringsAsFactors = FALSE)
colnames(tnbc_seq)[1]<-"SA_ID"
colnames(tnbc_seq)[2]<-"WGSS_LIB_ID"

# This is where the locations are stored (Arusha showed me Jun 1, 2017)
locfile="Triple Negative_TTR_more sample location_2015June20.xls"
#Sheet1 contains "DNA_T_N & RNA"
location<-readWorksheetFromFile(file=locfile,sheet = c("DNA_T_N & RNA"), header=TRUE)
#Sheet2 contains "RNA"
location.RNA<-readWorksheetFromFile(file=locfile,sheet = c("RNA"), header=FALSE)
#Sheet1 contains "WGA-Triple Negative"
location.WGA<-readWorksheetFromFile(file=locfile,sheet = c("WGA-Triple Negative"), header=TRUE)

TN<-tnbc_seq$SA_ID
var1<-unique(master_summary$Sample.ID[1:211])
# removing all the heading with the word "cases"
sum1<-var1[lapply(var1,function(x) length(grep("cases",x,value=FALSE))) == 0]
LL1<-as.character(location$Sample.Name)
LL2<-c(LL1,as.character(location.RNA$Sample.Name))
LL3<-unique(c(LL2,as.character(location.WGA$Sample.Name)))
someID<-unique(do.call(c, list(LL1,LL2,LL3,sum1)))
univ<-as.data.frame(someID, stringsAsFactors = FALSE)

# This is how many records there might be
rec=nrow(univ)

# defining the data frame with placeholder data
outdf <-  data.frame(CollabID = rep("", rec),
		  addCollabID = rep("", rec),	
		         SAID = rep("", rec),	
		        addID = rep("", rec),	
		     add_SAID = rep("", rec),	
#		     loc_rack = rep("NA", rec),	
#		    loc_shelf = rep("NA", rec),	
#		      loc_box = rep("NA", rec),	
		      loc_pos = rep("NA", rec),	
#		     rem_elut = rep("NA", rec),	
#		     sam_type = rep("NA", rec),	
		Tumour.Normal = rep("NA", rec),	
		       ER_TMA = rep("NA", rec),	
		       PR_TMA = rep("NA", rec),	
		     HER2_TMA = rep("NA", rec),	
		     EGFR_TMA = rep("NA", rec),	
		    CK5.6_TMA = rep("NA", rec),	
		    RNASeq_Mb = rep("NA", rec),	
		    GSC_EXCAP = rep("NA", rec),	
		    SOLID_WGS = rep("NA", rec),	
		 Add_SOLIDLIB = rep("NA", rec),	
		 SNP_ARRAY_ID = rep("NA", rec),	
		  METABRIC_ID = rep("NA", rec),	
		         PROJ = rep("NA", rec),	
		       SOURCE = rep("NA", rec),	
		    RNASEQLIB = rep("NA", rec),	
	 	      WGSSLIB = rep("NA", rec),	
	 	 NORM_WGSSLIB = rep("NA", rec),	

                       Normal = rep("NA", rec),
                       Tumour = rep("NA", rec),
                RNASEQLIB.seq = rep("NA", rec),
                  WGSSLIB.seq = rep("NA", rec),
             NORM_WGSSLIB.seq = rep("NA", rec),

             stringsAsFactors = FALSE)

# This is the module where I sum up everything from the sheets
for (ri in seq(rec)) {

		# Using univ$someID to grep names from codes$Sample_ID (which is the Collaborator ID wanted) from codes
		collID<-gsub("[()]/", "_", as.character(codes[grep(univ$someID[ri], codes$Sample_ID) , c("Sample_ID")] ))

		if ( sum(nchar(collID)) > 0 )
				{	
					if ( is.na(unique(collID)) ) { next}
					if ( "collID" == univ$someID[ri] ) { outdf$CollabID[ri] <- collID } 
					else 	{ 
						outdf$addCollabID[ri] <- collID
						outdf$CollabID[ri] <- codes[codes$Sample_ID %in% collID, c("Sample_ID")] 
						}
				}


		# Used the standardized Collborator ID (Sample_ID) , c(1) <- col in codes to be output (Sample_ID)
		said<-codes[codes$Sample_ID %in% outdf$CollabID[ri], c("Sample_ID")]

		if ( sum(nchar(said)) > 0 )
				{	
					if ( said == outdf$CollabID[ri] ) { outdf$SAID[ri] <- codes[codes$Sample_ID %in% outdf$CollabID[ri], c("SA_ID")]  }
					if ( said == outdf$CollabID[ri] ) { outdf$addID[ri] <- codes[codes$Sample_ID %in% outdf$CollabID[ri], c("Additional_ID")]  }
					if ( said == outdf$CollabID[ri] ) { outdf$add_SAID[ri] <- codes[codes$Sample_ID %in% outdf$CollabID[ri], c("Additional_SA_IDs")]  }
				}

		# For UPDATE: use WGSS library from TNBC-27 JIRA (103 genomes) and confirm that they are TNBC
		dnaid<-tnbc_seq[tnbc_seq$SA_ID %in% outdf$SAID[ri], c("SA_ID")]

		if ( sum(nchar(dnaid)) > 0 )
				{	
					outdf$WGSSLIB[ri] <- tnbc_seq[tnbc_seq$SA_ID %in% outdf$SAID[ri], c("WGSS_LIB_ID")] 
					outdf$NORM_WGSSLIB[ri] <- tnbc_seq[tnbc_seq$SA_ID %in% paste(outdf$SAID[ri],"N",sep=""), c("WGSS_LIB_ID")] 
					outdf$PROJ[ri] <- "TNBC_103"			
				}

		# SA ID [,2] and rnaseq$Sample, c("Sample") <- col in tnbc_seq to be output (SA ID) 
		rnaid<-rnaseq[rnaseq$Sample %in% outdf$SAID[ri], c("Sample")]

		if ( sum(nchar(rnaid)) == 0 )	
				{ 
					rnaid<-rnaseq[rnaseq$Sample.1 %in% outdf$SAID[ri], c("Sample.1")] 
					if ( sum(nchar(rnaid)) > 0 )	
						{ 
							outdf$RNASEQLIB[ri] <- rnaseq[rnaseq$Sample.1 %in% outdf$SAID[ri], c("Library")] 
							outdf$PROJ[ri] <- rnaseq[rnaseq$Sample.1 %in% outdf$SAID[ri], c("Description")] 			
							rnaid<-NULL 			
						}
				}
		if ( sum(nchar(rnaid)) > 0 )	
				{ 
					outdf$RNASEQLIB[ri] <- rnaseq[rnaseq$Sample %in% outdf$SAID[ri], c("Library")] 
					outdf$PROJ[ri] <- rnaseq[rnaseq$Sample %in% outdf$SAID[ri], c("Description")] 			
				}
	
		# Collab ID [,1] and location$Sample.Name, c("Sample.Name") <- col in location to be output (Collab ID) 
		locid<-unique(location[location$Sample.Name %in% outdf$CollabID[ri], c("Sample.Name")])

		if ( sum(nchar(locid)) > 0 )
				{	
					source <- unique(location[location$Sample.Name %in% outdf$CollabID[ri], c("Source")])
					if ( sum(nchar(source)) > 1) 
						{
						outdf$SOURCE[ri] <- paste(unique(location[location$Sample.Name %in% outdf$CollabID[ri], c("Source")]), collapse=",")
						}
				}

		# Sample ID column match in location[,1], c(6-9) <- col in location to be output (Rack,Shelf,Box, Pos) 
		sam_loc<-unique(location[location$Sample.Name %in%  outdf$CollabID[ri], c(1)])

		if ( sum(nchar(sam_loc)) > 0 )
				{	
					loc_rack.temp <- paste(as.character(location[location$Sample.Name %in% outdf$CollabID[ri], c("Rack..")],sep=","), collapse=", ")
					loc_shelf.temp <- paste(as.character(location[location[,1] %in% outdf$CollabID[ri], c("Shelf..")], sep=","), collapse=", ")
					loc_box.temp <- paste(as.character(location[location[,1] %in% outdf$CollabID[ri], c("Box..")], sep=","), collapse=", ")
					loc_pos.temp <- paste(as.character(location[location[,1] %in% outdf$CollabID[ri], c("Position..")], sep=","), collapse=", ")

# This module stores the exect location of the samples 
#					if (length(loc_rack.temp) > 0 ) { outdf$loc_rack[ri] <- loc_rack.temp } 
#					if (length(loc_shelf.temp) > 0 ) { outdf$loc_shelf[ri] <- loc_shelf.temp } 
#					if (length(loc_box.temp) > 0 ) { outdf$loc_box[ri] <- loc_box.temp } 
#					if (length(loc_pos.temp) > 0 ) { outdf$loc_pos[ri] <- loc_pos.temp } 

# This modules says that we have samples only (location not given) We use position to indicate that we have physical sample
# AS long as it has a shelf, box or position reference, we assume that we have samples
					if (length(loc_shelf.temp) > 0 ) { outdf$loc_pos[ri] <- "Sample" } 
					if (length(loc_box.temp) > 0 ) { outdf$loc_pos[ri] <- "Sample" } 
					if (length(loc_pos.temp) > 0 ) { outdf$loc_pos[ri] <- "Sample" } 
				}
			}


# Remove incomplete cases which is no SA ID AND no Collaborator ID 
outdf<-unique(outdf[!(outdf$CollabID=="" & outdf$SAID==""),])

####################################

# File is in this path on MOMAC14
# /Volumes/Monco/Aparicio Lab - Projects/BreastCancerOutcomesUnitRelated/TNBC files
tempfile="TNBC_Summary_int.csv"
write.table(outdf, file=tempfile, sep=",")

########################################
# Missing SA IDs from outdf
tnbc_add<-as.data.frame(unique(sort(tnbc_seq[!tnbc_seq$SA_ID %in% outdf$SAID,c("SA_ID")])), stringsAsFactors = FALSE)
rna_add1<-as.data.frame(unique(sort(rnaseq[!rnaseq$Sample %in% outdf$SAID, c(2)])), stringsAsFactors = FALSE)
rna_add2<-as.data.frame(unique(sort(rnaseq[!rnaseq$Sample.1 %in% outdf$SAID, c(3) ])), stringsAsFactors = FALSE)
rna_add<-as.data.frame(c("SA024","SA029","SA030","SA051","SA052","SA053","SA054","SA055","SA056","SA072"), stringsAsFactors = FALSE)

colnames(tnbc_add)[1]<-"SAID"
colnames(rna_add1)[1]<-"SAID"
colnames(rna_add2)[1]<-"SAID"
colnames(rna_add)[1]<-"SAID"
missingIDs<-rbind(tnbc_add, rna_add, rna_add1,rna_add2)

# make them into a list so that I can remove those that we already have data for
MID<-unlist(missingIDs, use.name=FALSE)
# These are the normals
NOR<-grep('N', MID, value=TRUE)
# Those which are not present in the outdf dataset
MIE<-MID[which(!MID %in% NOR)]
missingIDs<-MIE[MIE != " "]

rec=length(missingIDs)

# defining the data frame with placeholder data
# This second data frame contains all the missing SA IDs which supposedly belong to TNBC 
# but were for some reasons missed from the analysis above 
# this list is partially script generated

outdf2 <- data.frame(CollabID = rep("", rec),
                  addCollabID = rep("", rec),
                         SAID = rep("", rec),
                        addID = rep("", rec),
                     add_SAID = rep("", rec),
#                    loc_rack = rep("NA", rec),
#                   loc_shelf = rep("NA", rec),
#                     loc_box = rep("NA", rec),
                      loc_pos = rep("NA", rec),
#                    rem_elut = rep("NA", rec),
#                    sam_type = rep("NA", rec),
                Tumour.Normal = rep("NA", rec),
                       ER_TMA = rep("NA", rec),
                       PR_TMA = rep("NA", rec),
                     HER2_TMA = rep("NA", rec),
                     EGFR_TMA = rep("NA", rec),
                    CK5.6_TMA = rep("NA", rec),
                    RNASeq_Mb = rep("NA", rec),
                    GSC_EXCAP = rep("NA", rec),
                    SOLID_WGS = rep("NA", rec),
                 Add_SOLIDLIB = rep("NA", rec),
                 SNP_ARRAY_ID = rep("NA", rec),
                  METABRIC_ID = rep("NA", rec),
                         PROJ = rep("NA", rec),
                       SOURCE = rep("NA", rec),
                    RNASEQLIB = rep("NA", rec),
                      WGSSLIB = rep("NA", rec),
                 NORM_WGSSLIB = rep("NA", rec),

                       Normal = rep("NA", rec),
                       Tumour = rep("NA", rec),
                RNASEQLIB.seq = rep("NA", rec),
                  WGSSLIB.seq = rep("NA", rec),
             NORM_WGSSLIB.seq = rep("NA", rec),

             stringsAsFactors = FALSE)

# This is the module where I get specific missing SA IDs from the respective sheets
for (ri in seq(rec)) 
			{
                # Using the Missing IDs as a guide for this data set
		outdf2$SAID[ri]<-as.character(missingIDs[ri])

                collID<-gsub(" ","", gsub("[()]/", "_", as.character(codes[grep(missingIDs[ri], codes$SA_ID) , c(1)] )))

                if ( length(collID) > 0 )
                                {
                                        outdf2$CollabID[ri] <- codes[codes[,2] %in% outdf2$SAID[ri], c(1)]  
                                        outdf2$addID[ri] <- codes[codes[,2] %in% outdf2$SAID[ri], c(3)]  
                                        #outdf2$add_SAID[ri] <- codes[codes[,1] %in% outdf$CollabID[ri], c(4)]  
				}


                # SA ID [,2] and tnbc_seq[,1], c(1) <- col in tnbc_seq to be output (SA ID)
                dnaid<-tnbc_seq[tnbc_seq[,1] %in% outdf2$SAID[ri], c(1)]

                if ( length(dnaid) > 0 )
                                {
                                        outdf2$WGSSLIB[ri] <- tnbc_seq[tnbc_seq[,1] %in% outdf2$SAID[ri], c(2)]
					outdf2$PROJ[ri] <- "TNBC_103"			
                                }
                # SA ID [,2] and rnaseq[,2], c(2) <- col in tnbc_seq to be output (SA ID)
                rnaid<-rnaseq[rnaseq[,2] %in% outdf2$SAID[ri], c(2)]

                if ( length(rnaid) > 0 )
                                {
                                        outdf2$RNASEQLIB[ri] <- rnaseq[rnaseq[,2] %in% outdf2$SAID[ri], c("Library")]
                                        outdf2$PROJ[ri] <- rnaseq[rnaseq[,2] %in% outdf2$SAID[ri], c(5)]
                                }


                # Sample ID column match in location[,1], c(6-9) <- col in location to be output (Rack,Shelf,Box, Pos)
                sam_loc<-unique(location[location[,1] %in%  outdf2$CollabID[ri], c(1)])

                if ( length(sam_loc) > 0 )
                                {
                                        loc_rack.temp <- paste(as.character(location[location[,1] %in% codes[ri,1],c(6)],sep=","), collapse=", ")
                                        loc_shelf.temp <- paste(as.character(location[location[,1] %in% codes[ri,1],c(7)],sep=","), collapse=", ")
                                        loc_box.temp <- paste(as.character(location[location[,1] %in% codes[ri,1],c(8)],sep=","), collapse=", ")
                                        loc_pos.temp <- paste(as.character(location[location[,1] %in% codes[ri,1],c(9)],sep=","), collapse=", ")

# This modules says that we have samples only (location not given) We use position to indicate that we have physical sample
# AS long as it has a shelf, box or position reference, we assume that we have samples
                                        if (length(loc_shelf.temp) > 0 ) { outdf2$loc_pos[ri] <- "Sample" }
                                        if (length(loc_box.temp) > 0 ) { outdf2$loc_pos[ri] <- "Sample" }
                                        if (length(loc_pos.temp) > 0 ) { outdf2$loc_pos[ri] <- "Sample" }
                                }
                        }


#Join data sets
outdf3_1<-join(outdf, outdf2, type = "full")
outdf3<-outdf3_1[!duplicated(outdf3_1),]

#outdf3<-mutate(output, WGSS=ifelse(output$WGSSLIB=="NA", "None", "Seq'd"))
#outdf3<-mutate(output, WTSS=ifelse(output$RNASEQLIB=="NA", "None", "Seq'd"))

############# Use the completed data to cross-reference Sequencing Master file 2017 ############
# This is the master sequencing file
seqfile="Aparicio_Library_master_list__January132017.xlsx"
seq<-readWorksheetFromFile(file=seqfile,sheet = c("master page"), header=TRUE)

#### NOTE CHNAGED OUTDF STRUCTURE ############
#### ADD AT END AS MERGING BY ROWS ##########

rec=nrow(outdf3)
outdf4 <- data.frame(CollabID = rep("", rec),
                  addCollabID = rep("", rec),
                         SAID = rep("", rec),
                        addID = rep("", rec),
                     add_SAID = rep("", rec),
                      loc_pos = rep("", rec),
                Tumour.Normal = rep("", rec),
                       ER_TMA = rep("", rec),
                       PR_TMA = rep("", rec),
                     HER2_TMA = rep("", rec),
                     EGFR_TMA = rep("", rec),
                    CK5.6_TMA = rep("", rec),
                    RNASeq_Mb = rep("", rec),
                    GSC_EXCAP = rep("", rec),
                    SOLID_WGS = rep("", rec),
                 Add_SOLIDLIB = rep("", rec),
                 SNP_ARRAY_ID = rep("", rec),
                  METABRIC_ID = rep("", rec),
                         PROJ = rep("", rec),
                       PROJ.1 = rep("", rec),
                       SOURCE = rep("", rec),
                    RNASEQLIB = rep("", rec),
                      WGSSLIB = rep("", rec),
                 NORM_WGSSLIB = rep("", rec),

                       Normal = rep("", rec),
                       Tumour = rep("", rec),
                RNASEQLIB.seq = rep("", rec),
                  WGSSLIB.seq = rep("", rec),
             NORM_WGSSLIB.seq = rep("", rec),

             stringsAsFactors = FALSE)

# I assmume that everything that gets SA ID for seq 
# Therefore it makes sense that I only use the SA ID to probe the spreadsheets

for (ri in seq(rec)) {

		# First get all the SA ID and if SA ID is not there label not suitable	 or missing
		test_said<-outdf3$SAID[ri]

                if ( sum(nchar(test_said)) > 1 )
				{
				if ( test_said == "not suitable for sequencing")  	{ test_said<-"not suitable" 
											outdf4$SAID[ri]<-test_said
											next
											} else { test_said<-"not assigned" 
												outdf4$SAID[ri]<-test_said
												}

				# Then transfer entire line from outdf3 to outdf4
        	        	outdf4[ri,]<-outdf3[ri,]

				collID<-gsub(" ","", master_summary[master_summary$SA.ID %in% outdf3$SAID[ri], c("Sample.ID")])

                if ( sum(nchar(collID)) > 0 & length(collID) == 1 )
                                {
				 # Fix Collaborator ID to remove spaces 
                                 outdf4$CollabID[ri] <- collID
				
                                }

		# Getting the IHC results from master_IHC speadsheet
                ihcid<-master_IHC[master_IHC$SA_id %in% outdf4$SAID[ri], c("SA_id")]

                if ( sum(nchar(length(ihcid)) > 0 & length(ihcid) == 1))
                                {
				# Get the normals and put them in the respective columns
				outdf4[ri,c("Normal")]<-unique(master_IHC[master_IHC$SA_id %in% paste(outdf4$SAID[ri],"N",sep=""), c("Tumour.Normal")])
				outdf4[ri,c("NORM_WGSSLIB.seq","SOLID_WGS","Add_SOLIDLIB")]<-unique(master_IHC[master_IHC$SA_id %in% paste(outdf4$SAID[ri],"N",sep=""), c("GSC_WGSS","SOLID_WGS","Addditional.SOLiD.libraries")])

				# get the tumours and put them in the respective columns
				outdf4[ri,c("Tumour","ER_TMA","PR_TMA","HER2_TMA","EGFR_TMA","CK5.6_TMA")]<-master_IHC[master_IHC$SA_id %in% outdf4$SAID[ri], 
					c("Tumour.Normal","ER_TMA","PR_TMA","HER2_TMA","EGFR_TMA","CK5.6_TMA")]
				outdf4[ri,c("RNASEQLIB.seq","RNASeq_Mb","WGSSLIB.seq","GSC_EXCAP","SOLID_WGS","Add_SOLIDLIB","PROJ.1","SOURCE")]<-master_IHC[master_IHC$SA_id %in% outdf4$SAID[ri], 
					c("GSC_RNASeq","RNASeq_Mb","GSC_WGSS","GSC_EXCAP","SOLID_WGS","Addditional.SOLiD.libraries","PROJECT","Source")]
                                }


				 }

			
			}

### END HERE FOR TEST
## CHECK
colSums(is.na(outdf4))
## Incorporate Paul Savage / Morag Park TNBC cases with SA IDs
parkmetafile="GCRC PDX metadata Overview 17-02-28 (Aparicio).xlsx"
parkmeta<-readWorksheetFromFile(file=parkmetafile,sheet = c("Sheet1"), header=TRUE)

parkseqfile="Paul Savage SA IDs.xlsx"
parkseq<-readWorksheetFromFile(file=parkseqfile,sheet = c("Sheet1"), header=TRUE)

rec=nrow(parkmeta)
outdf5 <- data.frame(CollabID = rep("", rec),
                  addCollabID = rep("", rec),
                         SAID = rep("", rec),
                        addID = rep("", rec),
                     add_SAID = rep("", rec),
                      loc_pos = rep("", rec),
                Tumour.Normal = rep("", rec),
                       ER_TMA = rep("", rec),
                       PR_TMA = rep("", rec),
                     HER2_TMA = rep("", rec),
                     EGFR_TMA = rep("", rec),
                    CK5.6_TMA = rep("", rec),
                    RNASeq_Mb = rep("", rec),
                    GSC_EXCAP = rep("", rec),
                    SOLID_WGS = rep("", rec),
                 Add_SOLIDLIB = rep("", rec),
                 SNP_ARRAY_ID = rep("", rec),
                  METABRIC_ID = rep("", rec),
                         PROJ = rep("", rec),
                       PROJ.1 = rep("", rec),
                       SOURCE = rep("", rec),
                    RNASEQLIB = rep("", rec),
                      WGSSLIB = rep("", rec),
                 NORM_WGSSLIB = rep("", rec),

                       Normal = rep("", rec),
                       Tumour = rep("", rec),
                RNASEQLIB.seq = rep("", rec),
                  WGSSLIB.seq = rep("", rec),
             NORM_WGSSLIB.seq = rep("", rec),

             stringsAsFactors = FALSE)

for (rj in seq(rec)) {

			outdf5$CollabID[rj]<-substr(parkmeta$PDX.ID[rj],1,8)

                        # get the tumours and put them in the respective columns
                        outdf5[ri,c("CollabID","SAID", "ER_TMA","PR_TMA","HER2_TMA","Tumour.Normal","loc_pos")]<-parkmeta[parkmeta$PDX.ID %in% outdf5$CollabID[rj],
                                        c("PDX.ID","SA.ID","ER.","PR.","HER2.","Histology","DNA.samples")]

	                parkid<-parkseq[parkseq$PDX.ID %in% substr(parkmeta$PDX.ID[rj],1,8), c("PDX.ID")]

        	        if ( length(parkid) > 0 )
                                {
        		                outdf5[ri,c("CollabID","SAID", "PROJ","RNASEQLIB.seq","HER2_TMA","Tumour.Normal","loc_pos")]<-parkseq[parkseq$PDX.ID %in% outdf5$CollabID[rj],
	                                       c("PDX.ID","SA.ID","Histology","RNAseq.Patient","HER2.","Histology","DNA.samples")]
        		                outdf5[ri,c("PROJ")]<-c("ParkPDX","
                                }


                # Sample ID column match in location[,1], c(6-9) <- col in location to be output (Rack,Shelf,Box, Pos)
                sam_loc<-unique(location[location[,1] %in%  outdf2$CollabID[ri], c(1)])

                if ( length(sam_loc) > 0 )
                                {
                                        loc_rack.temp <- paste(as.character(location[location[,1] %in% codes[ri,1],c(6)],sep=","), collapse=", ")
                                        loc_shelf.temp <- paste(as.character(location[location[,1] %in% codes[ri,1],c(7)],sep=","), collapse=", ")
                                        loc_box.temp <- paste(as.character(location[location[,1] %in% codes[ri,1],c(8)],sep=","), collapse=", ")
                                        loc_pos.temp <- paste(as.character(location[location[,1] %in% codes[ri,1],c(9)],sep=","), collapse=", ")

# This modules says that we have samples only (location not given) We use position to indicate that we have physical sample
# AS long as it has a shelf, box or position reference, we assume that we have samples
                                        if (length(loc_shelf.temp) > 0 ) { outdf2$loc_pos[ri] <- "Sample" }
                                        if (length(loc_box.temp) > 0 ) { outdf2$loc_pos[ri] <- "Sample" }
                                        if (length(loc_pos.temp) > 0 ) { outdf2$loc_pos[ri] <- "Sample" }
                                }


                        }



# Remove irrelevant cases
outdf5<-unique(outdf4[(outdf4$PROJ=="TNBC_103" | outdf4$PROJ=="TN Bca" | outdf4$PROJ=="NA" |  is.na(outdf4$PROJ) | outdf4$PROJ=="Her 2 (+) Bca" | outdf4$PROJ =="HCT116 BRCA-/- clone18"),])

# File is in this path on MOMAC14
# /Volumes/Monco/Aparicio Lab - Projects/BreastCancerOutcomesUnitRelated/TNBC files
tempfile="TNBC_Summary_outdf4.csv"
write.table(outdf4, file=tempfile, sep=",")
################################


############# SUMMARY ################

#outdf4$addID<-paste(outdf4$addID,outdf4$add_SAID,sep="")

print("Transcriptome")
count(output$WTSS)

print("Whole Genome")
count(output$WGSS)

print("TNBC cases")
count(output$PROJ)

print("Have samples")
count(output$loc_pos)

print (rnaseqfile)

print(inventoryfile)

print(sampleIHC)

print("TNBC-27_103.txt")

print(locfile)

# File is in this path on MOMAC14
# /Volumes/Monco/Aparicio Lab - Projects/BreastCancerOutcomesUnitRelated/TNBC files
outfile="TNBC_Summary_by_all_SA_onMAC_4.csv"
write.table(output, file=outfile, sep=",")

# Format
# cat (outputfile) | perl -p -e 's/\r\n|\n|\r/\|\n/g' | tr "," "|" | sed 's/^/\|/' | sed 's/\"\"/\ /g' | tr -d '"'


# Script to analyse MS data

# ON beast
library(plyr)
library(ggrepel)
library(ggplot2)

# On beast
wd="/home/dyap/Projects/Takeda_T3/MS data/Expt2_ectopicCLK2_Tag-unTag_IP"
pat="CLK_resMat_PSM_GeneLevel_vsn_Vars_v02.csv"
setwd(wd)
file_names = list.files(pattern = pat)

MS<-as.data.frame(read.csv(file_names[1],header=TRUE))
MS<-read.csv(file_names[1],header=TRUE)
results<-read.csv(file_names[1],header=TRUE)

# Highlight known Uniprot interactors of CLK2
Int<-read.table(file="Uniprot_CLK2_interactors.txt", header=FALSE, skip=1, sep="\t")

#############
allbinding=subset(MS, Benjamini.Hochberg.adjusted.Wald.p.value.for.average.treatment.effect < 0.05 & 
	log2.average.treatment.effect.difference.from.control.> 1, select=c(Accession,Gene.name,Descriptions))
#,pepNum))


# Nice labelling (non-overlapping)
MS<-mutate(MS, Legend=ifelse(MS$Benjamini.Hochberg.adjusted.Wald.p.value.for.average.treatment.effect<0.05 & 
	MS$log2.average.treatment.effect.difference.from.control.>1, "p<0.05 (n=118)", "Not Significant (n=1109)"))
#MS<-mutate(MS, Interactors=ifelse(MS$Benjamini.Hochberg.adjusted.Wald.p.value.for.average.treatment.effect<0.05 & 
#	MS$log2.average.treatment.effect.difference.from.control.>1 & MS$Gene.name %in% Int$V1, "Uniprot Interactors (9/26)", "Unknown"))
MS<-mutate(MS, Interactors=ifelse(MS$Gene.name %in% Int$V1, "Uniprot Interactors (9/26)", "Unknown"))


count(MS$Legend)
count(MS$Interactors)


write.csv(allbinding, file="CLK2_interactors_new.csv", quote=FALSE)
clk2<-as.list(as.character(allbinding$Gene))
lapply(clk2, write, "CLK2_int_genes.txt", append=TRUE, ncolumns=1000)
# Submit this file to http://www.pantherdb.org/geneListAnalysis.do
# remove the "'" from 3' as it causes import failure
GO<-read.table(file="CLK2-bind_MS-GO_new.txt", header=TRUE, skip=10, sep="\t")

colnames(GO)[1]<-"PantherGO"
colnames(GO)[6]<-"Fold_Enrichment"
colnames(GO)[7]<-"Adjusted.P.value"

# Set value >5 to 5
GO$Enrichment <- as.numeric(gsub(" > ","", GO$Fold_Enrichment))

q = ggplot(GO, aes(Enrichment, -log10(Adjusted.P.value)), pch=20) 

# Highlight known Uniprot interactors of CLK2
Int<-read.table(file="Uniprot_CLK2_interactors.txt", header=FALSE, skip=1, sep="\t")

# Nice labelling (non-overlapping)
#MS<-mutate(MS, Legend=ifelse(MS$Benjamini.Hochberg.adjusted.Wald.p.value.for.average.treatment.effect<0.05 & 
#	MS$log2.average.treatment.effect.difference.from.control.>1, "p<0.05 (n=118)", "Not Significant (n=1109)"))
MS<-mutate(MS, Legend=ifelse(MS$Benjamini.Hochberg.adjusted.Wald.p.value.for.average.treatment.effect<0.05,
	"p<0.05 (n=118)", "Not Significant (n=1109)"))
#MS<-mutate(MS, Interactors=ifelse(MS$Benjamini.Hochberg.adjusted.Wald.p.value.for.average.treatment.effect<0.05 & 
#	MS$log2.average.treatment.effect.difference.from.control.>1 & MS$Gene.name %in% Int$V1, "Uniprot Interactors (9/26)", "Unknown"))
MS<-mutate(MS, Interactors=ifelse(MS$Benjamini.Hochberg.adjusted.Wald.p.value.for.average.treatment.effect<0.05 & 
	MS$Gene.name %in% Int$V1, "Uniprot Interactors (9/26)", "Unknown"))

#hl<-c("CLK1","CLK2","CLK3","CLK4")
#MS = mutate(MS, CLKs=ifelse(MS$Gene.name %in% hl, "CLKs", "Unknown"))

table(MS$Interactors)
#table(MS$CLKs)
known<-MS[MS$Gene.name %in% Int$V1,]

# Label Uniprot binary interactions

p = ggplot(MS, aes(log2.average.treatment.effect.difference.from.control., 
           -log10(Benjamini.Hochberg.adjusted.Wald.p.value.for.average.treatment.effect)), pch=20) +
  geom_point(aes(col=Legend)) +
  scale_color_manual(values=c("light grey", "dark grey")) +
  theme_light()+geom_text_repel(data = MS[MS$Gene.name %in% Int$V1,], aes(label=Gene.name), fontface = "bold", 
  force = 7, nudge_x = -1.5, nudge_y=0.73) +
  geom_point(aes(col=Interactors)) + 
  scale_color_manual(values=c("grey90", "grey50", "red","transparent")) +
  theme(legend.position = c(0.18, 0.85)) + ggtitle("CLK2 interactors by IP-MS") +
  theme(panel.border = element_rect(fill = NA, colour = "black", size = 1))+
  labs(x = "log2(Ave Effect Difference from Control)", y="-log10((Benjamini-Hochberg adjusted Wald p-value)") 

pdf(file="SupplFig_CLK2_Interactors_new.pdf")
p
dev.off()


#####################################
# Reload fresh MS data
MS<-as.data.frame(read.csv(file_names[1],header=TRUE))
#MS<-read.csv(file_names[1],header=TRUE)
# label all those with GO splicing
# Download new-CLK2_interactors_GOList.txt from PantherGO
# grep "splic" new-CLK2_interactors_GOList.txt | awk -F"\t" '{print $2}' | awk -F";" '{print $2}' > new_CLK2_int_Splicing.txt
Splice<-read.table(file="new_CLK2_int_Splicing.txt", header=FALSE)

# Highlight known Uniprot interactors of CLK2
Int<-read.table(file="Uniprot_CLK2_interactors.txt", header=FALSE, skip=1, sep="\t")

# grep "RNA binding" new-CLK2_interactors_GOList.txt | awk -F"\t" '{print $2}' | awk -F";" '{print $2}' > new_CLK2_int_mRNAbinding.txt
RBin<-read.table(file="new_CLK2_int_mRNAbinding.txt", header=FALSE)
allbind<-as.character(allbinding$Gene)

MS<-mutate(MS, Legend=ifelse(MS$Benjamini.Hochberg.adjusted.Wald.p.value.for.average.treatment.effect<0.05 & 
	MS$log2.average.treatment.effect.difference.from.control.>1, "p<0.05 (n=118)", "Not Significant (n=1109)"))

MS<-mutate(MS, Interactors=ifelse(MS$Benjamini.Hochberg.adjusted.Wald.p.value.for.average.treatment.effect<0.05 & 
	MS$log2.average.treatment.effect.difference.from.control.>1 & MS$Gene.name %in% Int$V1, "Uniprot Interactors (9/26)", ""))

MS<-mutate(MS, Function=ifelse(MS$Benjamini.Hochberg.adjusted.Wald.p.value.for.average.treatment.effect<0.05 & 
	MS$log2.average.treatment.effect.difference.from.control.>1 & MS$Gene.name %in% Splice$V1, "RNA splicing (n=55)", ""))

print("Check n=, for the following values correspond to the legend")
table(MS$Interactors)
table(MS$Function)

##############################################################################
#For Supplemental Table
# List the selected proteins by cut of and p value - raw data to 2 sig figs (in excel)
# subset from MS

MS<-mutate(MS, Binders=ifelse(MS$Benjamini.Hochberg.adjusted.Wald.p.value.for.average.treatment.effect<0.05 & 
	MS$log2.average.treatment.effect.difference.from.control.>1 & MS$Gene.name %in% RBin$V1, "RNA binding (n=65)", ""))

table(MS$Binders)

sig<-MS[MS$Legend == "p<0.05 (n=118)",]
sigcom<-sig[complete.cases(sig),]
sigcom$Binders[sigcom$Binders == "RNA binding (n=65)"]  <- "YES"
sigcom$Function[sigcom$Function == "RNA splicing (n=55)"] <- "YES"
sigcom$Interactors[sigcom$Interactors == "Uniprot Interactors (9/26)"] <- "YES"

################
names(sigcom)
print("check")


colnames(sigcom)[28]
colnames(sigcom)[28]<-"Known_Interactors_Uniprot"
colnames(sigcom)[29]
colnames(sigcom)[29]<-"Involved_in_RNA_Splicing"
colnames(sigcom)[30]
colnames(sigcom)[30]<-"Involved_in_RNA_Binding"

# reorder and subset data using [ ]
#suptab <- sigcom[c(1,2,3:8,15,11,12,17:19)]
#suptab <- sigcom[c(1,2,21,24,22,23,25,18,15,12,10)]
suptab <- sigcom[c("Gene.name","Accession","Descriptions","Sequence","Annotated.Sequence","Modifications","Absolute.fold.change.direction","Fold.change.for.average.treatment.effect",
	"log2.average.treatment.effect.difference.from.control.","Average.treatment.effect.t.statistic.Wald.based.p.value","Benjamini.Hochberg.adjusted.Wald.p.value.for.average.treatment.effect",
	"Known_Interactors_Uniprot","Involved_in_RNA_Splicing")]

write.table(suptab, file="SupplTable_Sig_Rawdata_new.tsv", col.names = TRUE, quote=FALSE, sep="\t")



#####
left=c("SRSF11","EIF4A3","SRSF1","SRSF6","SNRNP70","SRSF7",
       "CPSF1","PABPN1","YTHDC1")
right=c("DDX46","SRRM2","CPSF7","SRSF3","CLK1","SMN1","TRA2B",
	"SRSF10","RNPS1", "DHX15")
top=c("U2AF2","CLK2","NUDT21","CPSF6","U2AF1","SRRM1","THRAP3",
	"CLK4","CLK3","LUC7L3","RBM39","LUC7L2")

p = ggplot(MS, aes(log2.average.treatment.effect.difference.from.control., 
           -log10(Benjamini.Hochberg.adjusted.Wald.p.value.for.average.treatment.effect)), pch=20) +
  geom_point(aes(col=Legend)) +
#  scale_color_manual(values=c("light grey", "dark grey")) +
  theme_light()+geom_text_repel(data = MS[MS$Gene.name %in% left,], aes(label=Gene.name),
  fontface = "bold", force = 7, nudge_x = -1.3, nudge_y=5.04) +
  theme_light()+geom_text_repel(data = MS[MS$Gene.name %in% right,], aes(label=Gene.name),
  fontface = "bold", force = 7, nudge_x = 0.56, nudge_y=0.53) +
  theme_light()+geom_text_repel(data = MS[MS$Gene.name %in% top,], aes(label=Gene.name),
  fontface = "bold", force = 7, nudge_y=0.23) +
  geom_point(aes(col=Function)) +
#  geom_point(aes(col=Binders)) +
  geom_point(aes(col=Interactors)) +
  scale_color_manual(values=c("transparent","grey90", "grey50","blue","red")) +
  annotate("text", x = 2.53, y = 147, label = "Involved in RNA splicing (selected)", fontface = "bold") +
  theme(legend.position = c(0.20, 0.85)) + ggtitle("CLK2 interactors by IP-MS") +
  theme(panel.border = element_rect(fill = NA, colour = "black", size = 1))+
  theme(axis.text=element_text(size=12),
        axis.title=element_text(size=14,face="bold")) +
  labs(x = "log2(Ave Effect Difference from Control)", y="-log10(Benjamini-Hochberg adjusted Wald p-value)") +
  geom_vline(xintercept=1, na.rm = FALSE, show.legend = TRUE, linetype = "dotted")
p


##########################################
# plots all interactors to identify binders
o = ggplot(MS, aes(log2.average.treatment.effect.difference.from.control., 
           -log10(Benjamini.Hochberg.adjusted.Wald.p.value.for.average.treatment.effect)), pch=20) +
  geom_point(aes(col=Legend)) +
  theme_light()+geom_label_repel(data = MS[MS$Benjamini.Hochberg.adjusted.Wald.p.value.for.average.treatment.effect<0.05 &
        MS$log2.average.treatment.effect.difference.from.control.>1,], aes(label=Gene.name), cex=2.5, force=7)+  
#  theme_light()+geom_text_repel(data = MS[MS$Gene.name %in% Splice$V1,], aes(label=Gene.name), force=10)+  
#  theme_light()+geom_text_repel(data = MS[MS$Gene.name %in% RBin$V1,], aes(label=Gene.name), force=10)+  
#  theme_light()+geom_text_repel(data = MS[MS$Gene.name %in% Int$V1,], aes(label=Gene.name), force=10)+  
  theme(legend.position = c(0.20, 0.85)) + ggtitle("All significant CLK2 interactors by IP-MS") +
  theme(panel.border = element_rect(fill = NA, colour = "black", size = 1))+
  theme(axis.text=element_text(size=12),
        axis.title=element_text(size=14,face="bold")) +
  labs(x = "log2(Ave Effect Difference from Control)", y="-log10(Benjamini-Hochberg adjusted Wald p-value)") +
  geom_vline(xintercept=1, na.rm = FALSE, show.legend = TRUE, linetype = "dotted")
o
pdf(file="ReferenceFig_CLK2_Interactors_V3all.pdf")
o
dev.off()

#########################################

pdf(file="SupplFig_CLK2_Interactors_Splicing_V3new.pdf")
p
dev.off()


##############################
# Submit this file to http://www.pantherdb.org/geneListAnalysis.do
# remove the "'" from 3' as it causes import failure
GOinq<-read.table(file="CLK2-bind_MS-GO_new.txt", header=TRUE, skip=10, sep="\t")
GOinr<-read.table(file="CLK2-bind_MS-GOMolFun_new.txt", header=TRUE, skip=10, sep="\t", quote='"')

colnames(GOinq)[1]<-"PantherGO"
colnames(GOinq)[6]<-"Fold_Enrichment"
colnames(GOinq)[7]<-"Adjusted.P.value"
GOq <- GOinq[order(-GOinq$Adjusted.P.value),]

colnames(GOinr)[1]<-"PantherGO"
colnames(GOinr)[6]<-"Fold_Enrichment"
colnames(GOinr)[7]<-"Adjusted.P.value"
GOr <- GOinr[order(-GOinr$Adjusted.P.value),]

# Set value >5 to 5
GOq$Enrichment <- as.numeric(gsub(" > ","", GOq$Fold_Enrichment))
GOq$PantherGO<-gsub("\\s*\\([^\\)]+\\)","",as.character(GOq$PantherGO))
GOr$Enrichment <- as.numeric(gsub(" > ","", GOr$Fold_Enrichment))
GOr$PantherGO<-gsub("\\s*\\([^\\)]+\\)","",as.character(GOr$PantherGO))

GOq$Label <- do.call(paste, c(GOq[c("new.CLK2_Interactors..118.", "Homo.sapiens...REFLIST..20814.")], sep = "/"))
GOr$Label <- do.call(paste, c(GOr[c("new.CLK2_Interactors..118.", "Homo.sapiens...REFLIST..20814.")], sep = "/"))

# annotation of no / total in category

# Core wrapping function

wrap.it <- function(x, len)
{
  sapply(x, function(y) paste(strwrap(y, len),
                              collapse = "\n"),
         USE.NAMES = FALSE)
}

# Call this function with a list or vector
wrap.labels <- function(x, len)
{
  if (is.list(x))
  {
    lapply(x, wrap.it, len)
  } else {
    wrap.it(x, len)
  }
}

GOq$value<-as.numeric(-log10(GOq$Adjusted.P.value))
GOr$value<-as.numeric(-log10(GOr$Adjusted.P.value))

gt3q <-subset(GOq, Enrichment > 10)
gt3r <-subset(GOr, Enrichment > 5)
gt3q$lab<-wrap.labels(gt3q$PantherGO,20)
gt3r$lab<-wrap.labels(gt3r$PantherGO,20)

q<-ggplot(data=gt3q, aes(x=reorder(lab,value), y=value)) +
  geom_bar(width=0.8, stat="identity")+
  geom_text(data=gt3q, aes(x=lab, y=value, hjust=-0.15, label=Label)) +
  scale_y_continuous(limits=c(0,20)) +
#  ggtitle("CLK2 interactors by Gene Ontology") +
  theme(panel.border = element_rect(fill = NA, colour = "black", size = 2))+
  theme(axis.text=element_text(size=10),
        axis.title=element_text(size=12,face="bold")) +
  labs(y = "-log10(Adjusted p-value)", x="Top GO Biological Processes") +
  coord_flip()

r<-ggplot(data=gt3r, aes(x=reorder(lab,value), y=value)) +
  geom_bar(width=0.8, stat="identity")+
  geom_text(data=gt3r, aes(x=lab, y=value, hjust=-0.15, label=Label)) +
  scale_y_continuous(limits=c(0,20)) +
#  ggtitle("CLK2 interactors by Gene Ontology") +
  theme(panel.border = element_rect(fill = NA, colour = "black", size = 2))+
  theme(axis.text=element_text(size=10),
        axis.title=element_text(size=12,face="bold")) +
  labs(y = "-log10(Adjusted p-value)", x="Top GO molecular functions") +
  coord_flip()


pdf(file="SupplFig_CLK2_Interactors_byGO2_V3new.pdf")
library(gridExtra)
grid.arrange(q, r, nrow=2)
dev.off()




#################
# List genes by GO - supplemental table

GOG<-read.delim(file="CLK2_interactors_byGO.txt", header=FALSE)

# Only get the GO codes within brackets
match1<-gsub("\\s*\\^*.+\\(","",as.character(GOin$PantherGO[1]))
match<-gsub("\\)","",match1)

GOG[GOG$V13 %in% match,]




##################
# working on it have to change the layout if required
### plotting both side by side
library(gridExtra)
grid.arrange(p, q, ncol=2)


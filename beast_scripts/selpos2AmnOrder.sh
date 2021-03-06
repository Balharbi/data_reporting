#!/bin/sh

# Script to take the order form which contains selected positions
# Add the Adaptors
# Generate the Order file
# Generate the AmpliconManifest for MiSeq run


# Forward adaptor for Fluidigm
# fa="ACACTGACGACATGGTTCTACA"
# Reverse adaptor for Fluidigm (5'->3')
# ra="TACGGTAGCAGAGACTTGGTCT"

# Illlumina Adaptors (5'->3')
fa="TCGTCGGCAGCGTCAGATGTGTATAAGAGACAG"
ra="GTCTCGTGGGCTCGGAGATGTGTATAAGAGACAG"

temp="/home/dyap/dyap_temp"

Project="TITAN-SS"
Sample="DG1136g"
set="set2"

basedir="/home/dyap/Projects/PrimerDesign/"$Project"/primer3"
inputfile=$basedir"/"$Sample"-"$set"-pos.txt"

manifestfile=$basedir"/"$Sample"-"$set".AmpliconManifest"
orderfile=$basedir"/"$Sample"-"$set"-primer-order.csv"

manfile=$temp"/"$Sample"-manifest.tmp"
ordfile=$temp"/"$Sample"-order.tmp"

# Amplicon Manifest Header
 		echo "[Header]" > $manfile
                echo $Sample"-"$set"  Manifest Version,1" >> $manfile
                echo "ReferenceGenome,C:\Illumina\MiSeq Reporter\Genomes\Homo_sapiens\UCSC\hg19\Sequence\WholeGenomeFASTA" >> $manfile
                echo "  " >> $manfile
                echo "[Regions]" >> $manfile
                echo "Name,Chromosome,Amplicon Start,Amplicon End,Upstream Probe Length,Downstream Probe Length,Comments" >> $manfile

# Primer Order file
		echo "WellPosition,Name,Sequence,Notes" > $ordfile
		count=0

# Get positions from selected file and generate manifest and orderfile

for i in `cat $inputfile | awk -F, '{print $1}'`

	do

	id=`grep $i $inputfile | awk -F, '{print $1}'`
	echo $id
	chr=`grep $i $inputfile | awk -F, '{print $2}'`
	sta=`grep $i $inputfile | awk -F, '{print $3}'`
	end=`grep $i $inputfile | awk -F, '{print $4}'`
	amplen=`grep $i $inputfile | awk -F, '{print $5}'`
	lseq=`grep $i $inputfile | awk -F, '{print $6}'`
	llen=`grep $i $inputfile | awk -F, '{print $7}'`
	rseq=`grep $i $inputfile | awk -F, '{print $8}'`
	rlen=`grep $i $inputfile | awk -F, '{print $9}'`
	type=`grep $i $inputfile | awk -F, '{print $10}'`

	 if [[ $type =~ "intergenic" ]]
                then
			ann=`grep $i $inputfile | awk -F, '{print $11"-"$12}'`
		else
			ann=`grep $i $inputfile | awk -F, '{print $11}'`
			
	 fi

	 # Generate the Amplicon Manifest file 
	 echo $id","$chr","$sta","$end","$llen","$rlen","$type"-"$ann >> $manfile

	# Generate order file for IDT
	count=`echo "$count + 1" | bc`
	echo ","$id"-"$count"F,"$fa$lseq","$Sample"-"$set"-FORWARD PRIMERS" >> $ordfile
	echo ","$id"-"$count"R,"$ra$rseq","$Sample"-"$set"-REVERSE PRIMERS" >> $ordfile

	done

cat $manfile | tr "," "\t" > $manifestfile

cat $ordfile | sort -t, -k4,4 -r > $orderfile

exit;


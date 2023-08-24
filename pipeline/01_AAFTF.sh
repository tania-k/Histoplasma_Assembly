#!/bin/bash -l
#SBATCH -N 1 -n 4 --mem 120gb --time=48:00:00 --out logs/AAFTF.%a.log

MEM=96
CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

module load anaconda/5.2.0
#conda activate mamba
#mamba activate aaftf
#source activate aaftf
conda activate aaftf

FASTQ=input
SAMPLEFILE=samples.csv
ASM=asm/AAFTF
WORKDIR=working_AAFTF
export AAFTF_DB=~/lib/AAFTF_DB
mkdir -p $ASM $WORKDIR
if [ -z $CPU ]; then
    CPU=1
fi
IFS=, # set the delimiter to be ,
sed -n ${N}p $SAMPLEFILE | while read STRAIN BASE PHYLUM FUNGI
do
    ASMFILE=$ASM/${STRAIN}.spades.fasta
    VECCLEAN=$ASM/${STRAIN}.vecscreen.fasta
    PURGE=$ASM/${STRAIN}.sourpurge.fasta
    CLEANDUP=$ASM/${STRAIN}.rmdup.fasta
    PILON=$ASM/${STRAIN}.pilon.fasta
    SORTED=$ASM/${STRAIN}.sorted.fasta
    STATS=$ASM/${STRAIN}.sorted.stats.txt
    LEFTIN=$FASTQ/${BASE}_R1_001.fastq.gz
    RIGHTIN=$FASTQ/${BASE}_R2_001.fastq.gz

    if [ ! -f $LEFTIN ]; then
     echo "no $LEFTIN file for $STRAIN/$BASE in $FASTQ dir"
     exit
    fi
    LEFTTRIM=$WORKDIR/${BASE}_1P.fastq.gz
    RIGHTTRIM=$WORKDIR/${BASE}_2P.fastq.gz
    LEFT=$WORKDIR/${BASE}_filtered_1.fastq.gz
    RIGHT=$WORKDIR/${BASE}_filtered_2.fastq.gz
    echo "$BASE $STRAIN"
    if [ ! -f $ASMFILE ]; then # can skip we already have made an assembly
	if [ ! -f $LEFT ]; then # can skip filtering if this exists means already processed
	    if [ ! -f $LEFTTRIM ]; then
		AAFTF trim --method bbduk --memory $MEM --left $LEFTIN --right $RIGHTIN -c $CPU -o $WORKDIR/${BASE}
	    fi
	    AAFTF filter -c $CPU --memory $MEM -o $WORKDIR/${BASE} --left $LEFTTRIM --right $RIGHTTRIM --aligner bbduk
	    if [ -f $LEFT ]; then
		#rm $LEFTTRIM $RIGHTTRIM # remove intermediate file
		echo "found $LEFT"
	    fi
	fi
	AAFTF assemble -c $CPU --left $LEFT --right $RIGHT  --memory $MEM \
	      -o $ASMFILE -w $WORKDIR/spades_${STRAIN}
	
	if [ -s $ASMFILE ]; then
	    rm -rf $WORKDIR/spades_${STRAIN}/K?? $WORKDIR/spades_${STRAIN}/tmp
	fi
	
	if [ ! -f $ASMFILE ]; then
	    echo "SPADES must have failed, exiting"
	    exit
	fi
    fi
done

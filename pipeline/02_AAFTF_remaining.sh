#!/bin/bash -l
#SBATCH -N 1 -n 16 --mem 96gb --time=24:00:00 --out logs/AAFTF_part2.%a.log

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
conda activate aaftf_sourmash
#conda activate aaftf_sourmash2

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
    LEFT=$WORKDIR/${BASE}_filtered_1.fastq.gz
    RIGHT=$WORKDIR/${BASE}_filtered_2.fastq.gz

	echo "$BASE $STRAIN"
	AAFTF vecscreen -i $ASMFILE -c $CPU -o $VECCLEAN
	AAFTF sourpurge -i $VECCLEAN -o $PURGE -c $CPU --phylum $PHYLUM --left $LEFT --right $RIGHT
done

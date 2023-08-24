#!/bin/bash -l
#SBATCH --nodes 1 --ntasks 8 --mem 16G --time 72:00:00 --out logs/busco.%a.log -J busco

# for augustus training
# set to a local dir to avoid permission issues and pollution in global
module load busco/4.0.5
module load augustus/3.3.3
export BUSCO_CONFIG_FILE="/nas/longleaf/home/taniak/Histoplasma_Assembly/busco_files/myconfig.ini"
export AUGUSTUS_CONFIG_PATH="/nas/longleaf/home/taniak/Histoplasma_Assembly/busco_files/config/"

#module load workspace/scratch

CPU=${SLURM_CPUS_ON_NODE}
N=${SLURM_ARRAY_TASK_ID}
if [ ! $CPU ]; then
     CPU=2
fi
export NUMEXPR_MAX_THREADS=$CPU
if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi
CONFIG=busco_files/myconfig.ini
GENOMEFOLDER=genomes
EXT=fasta
LINEAGE=eurotiomycetes_odb10
OUTFOLDER=BUSCO
SAMPLEFILE=samples.csv
SEED_SPECIES=histoplasma
GENOMEFILE=$(ls $GENOMEFOLDER/*.${EXT} | sed -n ${N}p)
#LINEAGE=$(realpath $LINEAGE)

echo "GENOMEFILE is $GENOMEFILE"
NAME=$(basename $GENOMEFILE .$EXT)
GENOMEFILE=$(realpath $GENOMEFILE)
if [ -d "$OUTFOLDER/${NAME}" ];  then
    echo "Already have run $NAME in folder busco - do you need to delete it to rerun?"
    exit
else
  busco -m genome -l $LINEAGE -c $CPU -o ${NAME} --out_path ${OUTFOLDER} --offline --augustus_species $SEED_SPECIES --in $GENOMEFILE
fi

#!/bin/bash

#SBATCH --job-name=atlas
#SBATCH --output=logs/%x-%u-%A-%a.log
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=58
#SBATCH --time=12000
#SBATCH --mem=480G
##SBATCH --nodelist=omics-cn004


#######################################################
# HELP                                                #
#######################################################

usage="

Run atlas metagenome assembly

sbatch scritps/$(basename "$0") [-h|-w|-c|-t|-p]

where:
    -h  show this help text
    -w  working directory (location to run atlas)
    -c  path to config file generated with 'atlas init'
    -t  path to tmp
    -p  additional parameters to pass on to atlas

example:
sbatch scripts/atlas-run.sh -w results/atlas/\$DATE -c results/atlas/\$DATE/config.yaml -t /scratch/\$USER/\$DATE -p --dryrun
"


while getopts ':h:w:c:t:p:' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    w) WORKDIR=${OPTARG}
       ;;
    c) CONFIG=${OPTARG}
       ;;
    t) TMP=${OPTARG}
       ;;
    p) PARAMS=${OPTARG}
       ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))



#######################################################
# MAIN                                                #
#######################################################

echo `date`" atlas-run.sh started on node $SLURM_NODEID using $SLURM_CPUS_ON_NODE cpus."
echo "Command: sbatch atlas-run.sh -w $WORKDIR -c $CONFIG -t $TMPDIR -p $PARAMS"
echo "-------------------------------------------------"




## ====================================================
## Environment
## ====================================================




## ====================================================
## Paths etc
## ====================================================

export TMPDIR=$TMP
srun mkdir -p $TMP



## ====================================================
## Collect input data
## ====================================================



## ====================================================
## Run atlas
## ====================================================

echo `date`"  Running atlas..."

cmd="srun atlas run all -w $WORKDIR --resources mem=$SLURM_MEM_PER_NODE --jobs $SLURM_CPUS_ON_NODE --profile cluster --latency-wait 180 $PARAMS"
echo "Command: $cmd"
eval $cmd

echo `date`"  Running atlas finished."
echo "-------------------------------------------------"



## ====================================================
## Cleanup
## ====================================================

echo `date`"  Cleaning up..."
srun rm -fr $TMP

echo `date`"  Cleaning up finished."
echo "-------------------------------------------------"


echo `date`" All done!"
echo "$SLURM_JOB_NAME finished on node $SLURM_NODEID using $SLURM_CPUS_ON_NODE cpus."


####################################################
# THE END                                          #
####################################################


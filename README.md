# README ThioPaq MGX

This repo contains the source code and documentation for the thiopaq metagenomics project.

## Usage

### Download atlas references

Download the atlas reference files and store in db directory.
This causes an error because gtdb need certificate.
Therefore run separately and disable certificate checking:

```bash
atlas download -d db -j 4 --conda-create-envs-only
atlas download -d db -j 4 /zfs/omics/projects/thiopac-mgx/db/adapters.fa
atlas download -d db -j 4 /zfs/omics/projects/thiopac-mgx/db/EggNOG_V5/eggnog.db
atlas download -d db -j 4 /zfs/omics/projects/thiopac-mgx/db/phiX174_virus.fa
atlas download -d db -j 4 checkm_data_v1.0.9.tar.gz
```

Now add ``--no-check-certificate`` to ``/zfs/omics/projects/thiopac-mgx/miniconda3/envs/atlas/pkgs/gtdbtk-1.5.1-pyhdfd78af_0/python-scripts/download-db.sh``
and download gtdb:

```bash
atlas download -d db -j 4 /zfs/omics/projects/thiopac-mgx/db/GTDB_V06/downloaded_success
```


### Initiate atlas

Create sample and config files to run atlas.

```bash
DATE=`date +"%Y%m%dT%H%M%S"`
RUNDIR=$PWD/results/atlas/${DATE}
mkdir -p $RUNDIR
atlas init -d ./db -w $RUNDIR --assembler spades --data-type metagenome --threads 32 --interleaved-fastq ./data/
```

Now change the tmp directory to the scratch directory on the cluster:

```bash
sed -i "s~tmpdir: /tmp~tmpdir: /scratch/\$USER/$DATE~" $RUNDIR/config.yaml
```


### Run atlas

Submit the atlas run script to the cluster. First try a dry run to make sure it works.
You can then check the log in ``logs/atlas-$USER-<jobid>*``, which lists the jobs atlas will execute if you remove the drurn parameter next

```bash
sbatch scripts/atlas-run.sh -w results/atlas/$DATE -c results/atlas/$DATE/config.yaml -t /scratch/$USER/$DATE -p --dryrun
```

Actual run:

```bash
sbatch scripts/atlas-run.sh -w results/atlas/$DATE -c results/atlas/$DATE/config.yaml -t /scratch/$USER/$DATE -p
```

## Authors

* Evelien Jongepier (e.jongepier@uva.nl)


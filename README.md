# README ThioPaq MGX

This repo contains the source code and documentation for the thiopaq metagenomics project.

## Usage

First activate the atlas conda environment at the start of each session:

```bash
conda activate $PWD/miniconda3/envs/atlas
```

### Download atlas references

Download the atlas reference files and store in db directory.

```bash
atlas download -d db -j 4
```

This causes an error because gtdb need certificate.

Add ``--no-check-certificate`` to ``/zfs/omics/projects/thiopac-mgx/miniconda3/envs/atlas/pkgs/gtdbtk-1.5.1-pyhdfd78af_0/python-scripts/download-db.sh``
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

```bash
sbatch scripts/atlas-run.sh -w results/atlas/$DATE -c results/atlas/$DATE/config.yaml -t /scratch/$USER/$DATE -p --dryrun
```

You can then check the log in ``logs/atlas-$USER-<jobid>*``, which lists the jobs atlas will execute if you remove the dryrun parameter next

Actual run:

```bash
sbatch scripts/atlas-run.sh -w results/atlas/$DATE -c results/atlas/$DATE/config.yaml -t /scratch/$USER/$DATE
```

Atlas init qc threw an error due to file corruptions. Adding the following line to the config.yaml makes atlas toss these broken reads:

```bash
importqc_params: "iupacToN=t touppercase=t qout=33 addslash=t trimreaddescription=t tossbrokenreads=t"
```

Still fails due to corruption, run step manually:

```bash
cd results/atlas/$DATE 
java -ea -Xmx8G -Xms8G -cp /zfs/omics/projects/thiopac-mgx/miniconda3/envs/atlas/opt/bbmap-38.90-1/current/ jgi.ReformatReads in1=TP-S13/sequence_quality_control/TP-S13_raw_R1.fastq.gz in2=TP-S13/sequence_quality_control/TP-S13_raw_R2.fastq.gz bhist=TP-S13/sequence_quality_control/read_stats/raw/pe/base_hist.txt qhist=TP-S13/sequence_quality_control/read_stats/raw/pe/quality_by_pos.txt lhist=TP-S13/sequence_quality_control/read_stats/raw/pe/readlength.txt gchist=TP-S13/sequence_quality_control/read_stats/raw/pe/gc_hist.txt gcbins=auto bqhist=TP-S13/sequence_quality_control/read_stats/raw/pe/boxplot_quality.txt threads=4 overwrite=true tossbrokenreads=true nullifybrokenquality=true -Xmx8G
```

Still fails due to file corruption. Try to repair first:

```bash
cd results/atlas/$DATE
srun --mem 300g /zfs/omics/projects/thiopac-mgx/miniconda3/envs/atlas/opt/bbmap-38.90-1/repair.sh in1=TP-S13/sequence_quality_control/TP-S13_raw_R1.fastq.gz in2=TP-S13/sequence_quality_control/TP-S13_raw_R2.fastq.gz out1=TP-S13/sequence_quality_control/TP-S13_raw_repaired_R1.fastq.gz out2=TP-S13/sequence_quality_control/TP-S13_raw_repaired_R2.fastq.gz overwrite=true tossbrokenreads=true nullifybrokenquality=true -Xmx300g
```

Still fails: no paired output.
The corruption is in read "2297:1:1308:8208:43212#ACAGTGA/2 /2". See output repair.sh:

```bash
Mismatch between length of bases and qualities for read 104764980 (id=2297:1:1308:8208:43212#ACAGTGA/2 /2).
# qualities=33, # bases=150

???DFFF>)6:9B1?</8AACC8>8@>@<0)79
GGCCGGGGGGGAGGCCATTTATCTGTCCGGCTGGCAGGTGGCGGCGGACAACAACAGCTCCAAGACCATGTACCCGGACCAGTCCCTGTACGCCTATGACTCCGTGCCCACGGTGGTGCGGCGCATCAACAACAGCTTCAAGCGCGCGCA
```

Plan Z, manually remove corrupted reads:

```bash
#gzip -d ../../../data/TP_S13.fastq.gz ## does not work
cp TP_S13.fastq.gz TP_S13-corrupted.fastq.gz
zgrep . TP_S13.fastq.gz > TP_S13.fastq
gzip TP_S13.fastq
```

Now run atlas again:

```bash
sbatch scripts/atlas-run.sh -w results/atlas/$DATE -c results/atlas/$DATE/config.yaml -t /scratch/$USER/$DATE
```


## Authors

* Evelien Jongepier (e.jongepier@uva.nl)


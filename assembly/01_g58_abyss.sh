#!/bin/bash
#SBATCH --job-name=abyss-test
#SBATCH -p standard-s
#SBATCH -A abchase_geol4379_1267_001c_0001
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=04:00:00
#SBATCH --output=/projects/abchase/geol4379_1267_001c/shared_data/jobs/abyss-test-%j.out

set -euo pipefail
source ~/.bashrc


############################################################
###################### DIRECTORIES ##########################
############################################################

BASE=/projects/abchase/geol4379_1267_001c/shared_data

RAWDIR=$BASE/rawdata/genomes
OUTBASE=$BASE/genome_workshop
SOFTWARE=$BASE/software

REF=Curtobacterium_grass058
METHOD=abyss

R1=$RAWDIR/ALEX-GRASS-58_S85_L001_R1_001.fastq.gz
R2=$RAWDIR/ALEX-GRASS-58_S85_L001_R2_001.fastq.gz

THREADS=${SLURM_CPUS_PER_TASK}


WORKDIR=$OUTBASE/$METHOD
QCDIR=$WORKDIR/qc
ASMDIR=$WORKDIR/assembly
FINALDIR=$WORKDIR/final

mkdir -p \
  "$BASE/jobs" \
  "$QCDIR" \
  "$ASMDIR" \
  "$FINALDIR"


############################################################
##################### READ QC ###############################
############################################################

# First remove sequencing adapters and trim low-quality bases.
#
# BBDuk keeps paired reads together when paired input/output
# files are supplied, so an additional repair step is not
# required here.

conda activate "$SOFTWARE/bbmap"

echo "Starting read QC..."


bbduk.sh \
  -Xmx20g \
  threads=$THREADS \
  in1=$R1 \
  in2=$R2 \
  out1=$QCDIR/${REF}.filter.clean.R1.fq.gz \
  out2=$QCDIR/${REF}.filter.clean.R2.fq.gz \
  ref=adapters \
  ktrim=r \
  k=25 \
  mink=11 \
  hdist=1 \
  qtrim=rl \
  trimq=10 \
  minlen=25 \
  tpe \
  tbo \
  stats=$QCDIR/${REF}.bbduk.stats.txt \
  ow=t


CLEAN_R1=$QCDIR/${REF}.filter.clean.R1.fq.gz
CLEAN_R2=$QCDIR/${REF}.filter.clean.R2.fq.gz


############################################################
############ FORMAT READ NAMES FOR ABYSS ####################
############################################################

# ABySS recognizes paired reads when their names are identical
# or carry /1 and /2 suffixes.
#
# We explicitly add /1 and /2 here.

reformat.sh \
  in1=$CLEAN_R1 \
  in2=$CLEAN_R2 \
  out1=$QCDIR/${REF}.abyss.R1.fq.gz \
  out2=$QCDIR/${REF}.abyss.R2.fq.gz \
  addslash \
  ow=t


ABYSS_R1=$QCDIR/${REF}.abyss.R1.fq.gz
ABYSS_R2=$QCDIR/${REF}.abyss.R2.fq.gz


conda deactivate


############################################################
###################### ABYSS ################################
############################################################

conda activate "$SOFTWARE/abyss"

echo "Starting ABySS assembly..."


# ABySS is driven through a Makefile workflow.
#
# Use a clean directory so that files from an earlier run
# cannot accidentally be reused.

ABYSS_OUT=$ASMDIR/$REF

rm -rf "$ABYSS_OUT"
mkdir -p "$ABYSS_OUT"


# k = k-mer size.
#
# k=111 was selected for these long paired-end Illumina reads.
# This is a dataset-specific parameter, not a universal
# ABySS setting.
#
# B controls the Bloom-filter size.
#
# j specifies the number of threads used by ABySS.

abyss-pe \
  -C "$ABYSS_OUT" \
  name=$REF \
  k=111 \
  j=$THREADS \
  B=2G \
  in="$ABYSS_R1 $ABYSS_R2"


RAW_ASSEMBLY=$ABYSS_OUT/${REF}-contigs.fa


# Make sure assembly succeeded before continuing.

if [[ ! -s "$RAW_ASSEMBLY" ]]; then
  echo "ERROR: ABySS did not produce the expected contig file."
  exit 1
fi


conda deactivate


############################################################
################ STANDARDIZE OUTPUT #########################
############################################################

conda activate "$SOFTWARE/bbmap"


# Give contigs consistent and informative names.

rename.sh \
  in=$RAW_ASSEMBLY \
  out=$FINALDIR/${REF}.abyss.fasta \
  prefix=${REF}_abyss_contig_ \
  ow=t


############################################################
################ ASSEMBLY STATISTICS ########################
############################################################

# Calculate statistics on the COMPLETE assembly.
#
# This is the assembly that should be compared with outputs
# from SPAdes, Velvet, and IDBA and used for subsequent genome
# annotation/comparative-genomics exercises.

stats.sh \
  in=$FINALDIR/${REF}.abyss.fasta \
  format=3 \
  > $FINALDIR/${REF}.abyss.stats.txt


############################################################
############ OPTIONAL >=2 KB CONTIG VERSION #################
############################################################

# For visualization such as GC/coverage/taxonomy blob plots,
# it can be useful to omit very short contigs.
#
# DO NOT treat this as the primary genome assembly.
# In particular, use the complete assembly above for genome
# annotation, ANI, and pangenome analyses.

reformat.sh \
  in=$FINALDIR/${REF}.abyss.fasta \
  out=$FINALDIR/${REF}.abyss.2kbp.fasta \
  minlength=2000 \
  ow=t


echo ""
echo "ABySS assembly complete."
echo ""
echo "Complete assembly:"
echo "  $FINALDIR/${REF}.abyss.fasta"
echo ""
echo "Assembly statistics:"
echo "  $FINALDIR/${REF}.abyss.stats.txt"
echo ""
echo ">=2 kb assembly for optional blob analysis:"
echo "  $FINALDIR/${REF}.abyss.2kbp.fasta"
echo ""


conda deactivate


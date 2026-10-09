#!/bin/bash
#SBATCH --job-name=velvet-test
#SBATCH -p standard-s
#SBATCH -A abchase_geol4379_1267_001c_0001
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=04:00:00
#SBATCH --output=/projects/abchase/geol4379_1267_001c/shared_data/jobs/velvet-test-%j.out

set -euo pipefail
source ~/.bashrc

BASE=/projects/abchase/geol4379_1267_001c/shared_data
RAWDIR=$BASE/rawdata/genomes
OUTBASE=$BASE/genome_workshop
SOFTWARE=$BASE/software

REF=Curtobacterium_grass058

R1=$RAWDIR/ALEX-GRASS-58_S85_L001_R1_001.fastq.gz
R2=$RAWDIR/ALEX-GRASS-58_S85_L001_R2_001.fastq.gz

THREADS=${SLURM_CPUS_PER_TASK}

METHOD=velvet
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

conda deactivate


############################################################
###################### VELVET ###############################
############################################################

conda activate "$SOFTWARE/velvet"

echo "Starting Velvet assembly..."

VELVET_OUT=$ASMDIR/$REF

rm -rf "$VELVET_OUT"
mkdir -p "$VELVET_OUT"


# velveth builds the de Bruijn graph.
#
# Here we use a single k-mer size of 111.
# -shortPaired tells Velvet these are paired short reads.
# -separate specifies that R1 and R2 are in separate files.

velveth \
  "$VELVET_OUT" \
  111 \
  -shortPaired \
  -fastq.gz \
  -separate \
  "$CLEAN_R1" \
  "$CLEAN_R2"


# velvetg resolves the graph and generates contigs.
#
# Expected coverage and the low-coverage cutoff are estimated
# automatically.
#
# The expected insert length for these paired-end reads is
# approximately 270 bp.

velvetg \
  "$VELVET_OUT" \
  -cov_cutoff auto \
  -exp_cov auto \
  -ins_length 270 \
  -min_contig_lgth 500


RAW_ASSEMBLY=$VELVET_OUT/contigs.fa


if [[ ! -s "$RAW_ASSEMBLY" ]]; then
  echo "ERROR: Velvet did not produce the expected contig file."
  exit 1
fi

conda deactivate


############################################################
################ STANDARDIZE OUTPUT #########################
############################################################

conda activate "$SOFTWARE/bbmap"

rename.sh \
  in=$RAW_ASSEMBLY \
  out=$FINALDIR/${REF}.velvet.fasta \
  prefix=${REF}_velvet_contig_ \
  ow=t


############################################################
################ ASSEMBLY STATISTICS ########################
############################################################

stats.sh \
  in=$FINALDIR/${REF}.velvet.fasta \
  format=3 \
  > $FINALDIR/${REF}.velvet.stats.txt


############################################################
############ OPTIONAL >=2 KB CONTIG VERSION #################
############################################################

# Make a >=2 kb version for GC/coverage/taxonomy visualization.
# Use the complete assembly above for annotation, ANI, etc.

reformat.sh \
  in=$FINALDIR/${REF}.velvet.fasta \
  out=$FINALDIR/${REF}.velvet.2kbp.fasta \
  minlength=2000 \
  ow=t


echo ""
echo "Velvet assembly complete."
echo ""
echo "Complete assembly:"
echo "  $FINALDIR/${REF}.velvet.fasta"
echo ""
echo "Assembly statistics:"
echo "  $FINALDIR/${REF}.velvet.stats.txt"
echo ""
echo ">=2 kb assembly:"
echo "  $FINALDIR/${REF}.velvet.2kbp.fasta"
echo ""

conda deactivate


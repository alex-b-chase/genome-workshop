#!/bin/bash
#SBATCH --job-name=spades-test
#SBATCH -p standard-s
#SBATCH -A abchase_geol4379_1267_001c_0001
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=04:00:00
#SBATCH --output=/projects/abchase/geol4379_1267_001c/shared_data/jobs/spades-test-%j.out

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

METHOD=spades
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
##################### SPADES ################################
############################################################

conda activate "$SOFTWARE/spades"

echo "Starting SPAdes assembly..."

SPADES_OUT=$ASMDIR/$REF

rm -rf "$SPADES_OUT"


# --isolate is appropriate for a cultured bacterial isolate.
#
# SPAdes will automatically select an appropriate series of
# k-mer sizes based on the read length.

spades.py \
  --isolate \
  -1 "$CLEAN_R1" \
  -2 "$CLEAN_R2" \
  -o "$SPADES_OUT" \
  -t "$THREADS" \
  -m 60


RAW_ASSEMBLY=$SPADES_OUT/contigs.fasta


if [[ ! -s "$RAW_ASSEMBLY" ]]; then
  echo "ERROR: SPAdes did not produce the expected contig file."
  exit 1
fi

conda deactivate


############################################################
################ STANDARDIZE OUTPUT #########################
############################################################

conda activate "$SOFTWARE/bbmap"


# Rename contigs so the genome and assembler are obvious.

rename.sh \
  in=$RAW_ASSEMBLY \
  out=$FINALDIR/${REF}.spades.fasta \
  prefix=${REF}_spades_contig_ \
  ow=t


############################################################
################ ASSEMBLY STATISTICS ########################
############################################################

# Calculate statistics using the complete assembly.

stats.sh \
  in=$FINALDIR/${REF}.spades.fasta \
  format=3 \
  > $FINALDIR/${REF}.spades.stats.txt


############################################################
############ OPTIONAL >=2 KB CONTIG VERSION #################
############################################################

# Make a >=2 kb version for GC/coverage/taxonomy visualization.
# Use the complete assembly above for annotation, ANI, etc.

reformat.sh \
  in=$FINALDIR/${REF}.spades.fasta \
  out=$FINALDIR/${REF}.spades.2kbp.fasta \
  minlength=2000 \
  ow=t


echo ""
echo "SPAdes assembly complete."
echo ""
echo "Complete assembly:"
echo "  $FINALDIR/${REF}.spades.fasta"
echo ""
echo "Assembly statistics:"
echo "  $FINALDIR/${REF}.spades.stats.txt"
echo ""
echo ">=2 kb assembly:"
echo "  $FINALDIR/${REF}.spades.2kbp.fasta"
echo ""

conda deactivate


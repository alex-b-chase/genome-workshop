#!/bin/bash
#SBATCH --job-name=idba-test
#SBATCH -p standard-s
#SBATCH -A abchase_geol4379_1267_001c_0001
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=04:00:00
#SBATCH --output=/projects/abchase/geol4379_1267_001c/shared_data/jobs/idba-test-%j.out

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

METHOD=idba
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

# Remove sequencing adapters and trim low-quality bases.

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
###################### IDBA-UD ##############################
############################################################

conda activate "$SOFTWARE/idba"

echo "Starting IDBA-UD assembly..."

IDBA_READS=$QCDIR/${REF}.idba.fasta
IDBA_OUT=$ASMDIR/$REF

# Remove results from an earlier run.

rm -rf "$IDBA_OUT"


# IDBA requires FASTA input.
# fq2fa converts the paired FASTQ files into the interleaved
# FASTA format expected by IDBA.

fq2fa \
  --merge \
  --filter \
  <(zcat "$CLEAN_R1") \
  <(zcat "$CLEAN_R2") \
  "$IDBA_READS"


# These Illumina reads are >128 bp, so IDBA uses -r  reads <=600 bp
#
# IDBA-UD assembles across a range of increasing k-mer sizes:
# 30, 40, 50 ... 110.

idba_ud \
  -r "$IDBA_READS" \
  --pre_correction \
  --mink 30 \
  --maxk 110 \
  --step 10 \
  --num_threads $THREADS \
  --out "$IDBA_OUT"

RAW_ASSEMBLY=$IDBA_OUT/contig.fa


# Stop if assembly failed.

if [[ ! -s "$RAW_ASSEMBLY" ]]; then
  echo "ERROR: IDBA-UD did not produce the expected contig file."
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
  out=$FINALDIR/${REF}.idba.fasta \
  prefix=${REF}_idba_contig_ \
  ow=t


############################################################
################ ASSEMBLY STATISTICS ########################
############################################################

# Calculate statistics using the complete assembly.

stats.sh \
  in=$FINALDIR/${REF}.idba.fasta \
  format=3 \
  > $FINALDIR/${REF}.idba.stats.txt


############################################################
############ OPTIONAL >=2 KB CONTIG VERSION #################
############################################################

# Make a >=2 kb version for GC/coverage/taxonomy visualization.
# Use the complete assembly above for annotation, ANI, etc.

reformat.sh \
  in=$FINALDIR/${REF}.idba.fasta \
  out=$FINALDIR/${REF}.idba.2kbp.fasta \
  minlength=2000 \
  ow=t


############################################################
###################### CLEAN UP ##############################
############################################################

# Remove the temporary interleaved FASTA used by IDBA.

rm -f "$IDBA_READS"


echo ""
echo "IDBA-UD assembly complete."
echo ""
echo "Complete assembly:"
echo "  $FINALDIR/${REF}.idba.fasta"
echo ""
echo "Assembly statistics:"
echo "  $FINALDIR/${REF}.idba.stats.txt"
echo ""
echo ">=2 kb assembly:"
echo "  $FINALDIR/${REF}.idba.2kbp.fasta"
echo ""

conda deactivate


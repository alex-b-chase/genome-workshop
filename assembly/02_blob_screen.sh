#!/bin/bash
#SBATCH --job-name=blob-screen
#SBATCH -p standard-s
#SBATCH -A abchase_geol4379_1267_001c_0001
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=/projects/abchase/geol4379_1267_001c/shared_data/jobs/blob-screen-%j.out

set -euo pipefail
source ~/.bashrc

BASE=/projects/abchase/geol4379_1267_001c/shared_data
SOFTWARE=$BASE/software
BIN=$BASE/bin

REF=Curtobacterium_grass058
THREADS=${SLURM_CPUS_PER_TASK}


############################################################
################ CHOOSE ASSEMBLER ###########################
############################################################

# Run as:
#
# sbatch blob_screen.sh spades
#
# Valid options:
#
# spades
# abyss
# idba
# velvet

METHOD=${1:?Usage: sbatch blob_screen.sh spades|abyss|idba|velvet}

case "$METHOD" in
  spades|abyss|idba|velvet)
    ;;
  *)
    echo "ERROR: METHOD must be spades, abyss, idba, or velvet."
    exit 1
    ;;
esac


WORKDIR=$BASE/genome_workshop/$METHOD

ASSEMBLY=$WORKDIR/final/${REF}.${METHOD}.2kbp.fasta

R1=$WORKDIR/qc/${REF}.filter.clean.R1.fq.gz
R2=$WORKDIR/qc/${REF}.filter.clean.R2.fq.gz

BLOBDIR=$WORKDIR/blob

mkdir -p "$BLOBDIR"


############################################################
################ CHECK INPUT FILES ##########################
############################################################

if [[ ! -s "$ASSEMBLY" ]]; then
  echo "ERROR: Assembly not found:"
  echo "$ASSEMBLY"
  exit 1
fi

if [[ ! -s "$R1" || ! -s "$R2" ]]; then
  echo "ERROR: Clean read files not found."
  exit 1
fi


############################################################
################ TAXONOMIC ASSIGNMENT #######################
############################################################

# In a full analysis, each assembled contig can be searched
# against the NCBI nucleotide database.
#
# The taxonomic identity of the best sequence match provides
# one line of evidence about the likely origin of each contig.
#
# The NCBI nt database used for this analysis is located at:
#
# /projects/abchase/refDB/refDB/blastDB2
#
# We will NOT run BLAST during class because the nt database
# is extremely large and the search is computationally
# expensive.
#
# The full command would be:

# conda activate "$SOFTWARE/blast"
#
# BLASTDB=/projects/abchase/refDB/refDB/blastDB2
#
# blastn \
#   -task megablast \
#   -query "$ASSEMBLY" \
#   -db "$BLASTDB/nt" \
#   -evalue 1e-5 \
#   -max_target_seqs 1 \
#   -num_threads "$THREADS" \
#   -outfmt '6 qseqid staxids' \
#   -out "$BLOBDIR/${REF}.${METHOD}.nt.1e-5.megablast"
#
# conda deactivate


############################################################
#################### READ COVERAGE ##########################
############################################################

# A second useful property of each contig is sequencing
# coverage.
#
# Map the original reads back to the assembled contigs.

conda activate "$SOFTWARE/bowtie2"

echo "Building Bowtie2 index..."

IDX=$BLOBDIR/${REF}.${METHOD}.idx

bowtie2-build \
  "$ASSEMBLY" \
  "$IDX"


echo "Mapping reads back to assembly..."

# Bowtie2 can use the paired R1 and R2 files directly.

bowtie2 \
  -x "$IDX" \
  -1 "$R1" \
  -2 "$R2" \
  --very-fast-local \
  -k 1 \
  -p "$THREADS" \
  -S "$BLOBDIR/${REF}.${METHOD}.bowtie2.sam"

conda deactivate


############################################################
###################### MAKE BAM #############################
############################################################

conda activate "$SOFTWARE/samtools"

echo "Converting and sorting alignments..."

samtools sort \
  -@ "$THREADS" \
  -o "$BLOBDIR/${REF}.${METHOD}.bowtie2.sorted.bam" \
  "$BLOBDIR/${REF}.${METHOD}.bowtie2.sam"


samtools index \
  "$BLOBDIR/${REF}.${METHOD}.bowtie2.sorted.bam"


# The SAM file is no longer needed after creating the
# sorted BAM file.

rm -f "$BLOBDIR/${REF}.${METHOD}.bowtie2.sam"

conda deactivate


############################################################
################ GC + COVERAGE + TAXONOMY ###################
############################################################

# The final blob analysis combines three independent
# properties of each contig:
#
#   1. GC content
#   2. sequencing coverage
#   3. taxonomic assignment
#
# The taxonomic assignment comes from the BLAST search above.

TAXDUMP=/projects/abchase/refDB/refDB/taxdump

BLAST_HITS=$BLOBDIR/${REF}.${METHOD}.nt.1e-5.megablast


############################################################
############ CHECK FOR PRECOMPUTED BLAST RESULTS ############
############################################################

# During class, BLAST will not be run.
#
# If a precomputed BLAST result is available in the expected
# location, continue and generate the combined blob table.
#
# Otherwise, stop here after successfully generating the
# coverage information.

if [[ ! -s "$BLAST_HITS" ]]; then

  echo ""
  echo "Read mapping complete."
  echo ""
  echo "No BLAST result found at:"
  echo "  $BLAST_HITS"
  echo ""
  echo "The BLAST search is skipped during class."
  echo "Coverage BAM created at:"
  echo "  $BLOBDIR/${REF}.${METHOD}.bowtie2.sorted.bam"
  echo ""

  exit 0
fi


############################################################
################ CREATE BLOB TABLE ##########################
############################################################

echo "Combining GC, coverage, and taxonomy..."

"$BIN/gc_cov_annotate.pl" \
  --blasttaxid "$BLAST_HITS" \
  --assembly "$ASSEMBLY" \
  --bam "$BLOBDIR/${REF}.${METHOD}.bowtie2.sorted.bam" \
  --out "$BLOBDIR/${REF}.${METHOD}.blobplot.txt" \
  --taxdump "$TAXDUMP" \
  --taxlist genus family phylum


echo ""
echo "Blob analysis complete."
echo ""
echo "Output:"
echo "  $BLOBDIR/${REF}.${METHOD}.blobplot.txt"
echo ""


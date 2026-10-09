#!/bin/bash
#SBATCH --job-name=genome-compare
#SBATCH -p standard-s
#SBATCH -A abchase_geol4379_1267_001c_0001
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=/projects/abchase/geol4379_1267_001c/shared_data/genome_workshop/pangenome/%u/genome-compare-%j.out

set -euo pipefail
source ~/.bashrc


############################################################
###################### DIRECTORIES ##########################
############################################################

BASE=/projects/abchase/geol4379_1267_001c/shared_data

PANGENOME=$BASE/genome_workshop/pangenome
GENOMEDIR=$PANGENOME/genomes
SOFTWARE=$BASE/software

# Each user writes results to their own workspace.
# BEFORE submitting this job, create it once with:
#   mkdir -p /projects/abchase/geol4379_1267_001c/shared_data/genome_workshop/pangenome/$USER
# Shared input genomes remain in $PANGENOME/genomes.
USERDIR=$PANGENOME/$USER

STATSDIR=$USERDIR/stats
RENAMEDDIR=$USERDIR/renamed_genomes
ANIDIR=$USERDIR/ani
PROKKADIR=$USERDIR/prokka

THREADS=${SLURM_CPUS_PER_TASK}

echo ""
echo "User workspace:"
echo "  $USERDIR"
echo ""

mkdir -p \
  "$STATSDIR" \
  "$RENAMEDDIR" \
  "$ANIDIR" \
  "$PROKKADIR"


############################################################
##################### FIND GENOMES ###########################
############################################################

# Accept .fasta, .fa, or .fna genome files.

shopt -s nullglob

GENOMES=(
  "$GENOMEDIR"/*.fasta
  "$GENOMEDIR"/*.fa
  "$GENOMEDIR"/*.fna
)

if [[ ${#GENOMES[@]} -eq 0 ]]; then
  echo "ERROR: No genome FASTA files found in:"
  echo "  $GENOMEDIR"
  exit 1
fi

echo ""
echo "Found ${#GENOMES[@]} genomes:"
printf '  %s\n' "${GENOMES[@]}"
echo ""


############################################################
############ GENOME STATS + RENAME CONTIGS ##################
############################################################

conda activate "$SOFTWARE/bbmap"

echo "Calculating genome statistics and renaming contigs..."

SUMMARY=$STATSDIR/genome_stats.tsv
FIRST=1

for GENOME in "${GENOMES[@]}"
do

  FILE=$(basename "$GENOME")
  NAME=${FILE%.*}

  echo ""
  echo "Processing: $NAME"


  ##########################################################
  # Genome statistics
  ##########################################################

  stats.sh \
    in="$GENOME" \
    format=3 \
    addname=t \
    > "$STATSDIR/${NAME}.stats.txt"


  # Build one combined table containing statistics for all
  # five genomes.

  if [[ $FIRST -eq 1 ]]; then

    cat "$STATSDIR/${NAME}.stats.txt" > "$SUMMARY"
    FIRST=0

  else

    tail -n +2 "$STATSDIR/${NAME}.stats.txt" >> "$SUMMARY"

  fi


  ##########################################################
  # Rename contigs
  ##########################################################

  # Example:
  #
  # GenomeA.fasta
  #
  # becomes:
  #
  # >GenomeA.c_1
  # >GenomeA.c_2
  # >GenomeA.c_3
  #
  # Unique contig names make it easier to identify their
  # genome of origin during downstream analyses.

  rename.sh \
    in="$GENOME" \
    out="$RENAMEDDIR/${NAME}.fasta" \
    prefix="${NAME}.c_" \
    ow=t

done

conda deactivate


echo ""
echo "Genome statistics:"
echo "  $SUMMARY"
echo ""

echo "Renamed genomes:"
ls -1 "$RENAMEDDIR"
echo ""


############################################################
###################### FASTANI ###############################
############################################################

conda activate "$SOFTWARE/fastani"

echo "Starting all-vs-all ANI analysis..."


# FastANI takes a text file containing one genome path
# per line.

ANI_LIST=$ANIDIR/genomes.txt

find "$RENAMEDDIR" \
  -maxdepth 1 \
  -type f \
  -name "*.fasta" \
  | sort \
  > "$ANI_LIST"


# Compare every genome against every other genome.
#
# The regular output includes:
#
# query genome
# reference genome
# ANI
# mapped fragments
# total query fragments
#
# --matrix also creates a convenient ANI matrix.

fastANI \
  --ql "$ANI_LIST" \
  --rl "$ANI_LIST" \
  --matrix \
  -t "$THREADS" \
  -o "$ANIDIR/all_vs_all.fastani.tsv"


echo ""
echo "FastANI complete."
echo ""
echo "Pairwise ANI:"
echo "  $ANIDIR/all_vs_all.fastani.tsv"
echo ""
echo "ANI matrix:"
echo "  $ANIDIR/all_vs_all.fastani.tsv.matrix"
echo ""

conda deactivate


############################################################
######################## PROKKA ##############################
############################################################

conda activate "$SOFTWARE/prokka"

echo "Starting genome annotation..."


for GENOME in "$RENAMEDDIR"/*.fasta
do

  FILE=$(basename "$GENOME")
  NAME=${FILE%.fasta}

  echo ""
  echo "Annotating: $NAME"


  # All genomes are annotated using exactly the same
  # software and parameters so gene content can later be
  # compared using a pangenome analysis.

  prokka \
    --outdir "$PROKKADIR/$NAME" \
    --prefix "$NAME" \
    --genus Curtobacterium \
    --kingdom Bacteria \
    --cpus "$THREADS" \
    --force \
    "$GENOME"

done

conda deactivate


############################################################
######################## FINISHED ############################
############################################################

echo ""
echo "============================================================"
echo "Comparative genome preparation complete for user: $USER"
echo "============================================================"
echo ""
echo "User workspace:"
echo "  $USERDIR"
echo ""
echo "Original genomes (shared input):"
echo "  $GENOMEDIR"
echo ""
echo "Genome statistics:"
echo "  $STATSDIR"
echo ""
echo "Renamed genomes:"
echo "  $RENAMEDDIR"
echo ""
echo "ANI results:"
echo "  $ANIDIR"
echo ""
echo "Prokka annotations:"
echo "  $PROKKADIR"
echo ""

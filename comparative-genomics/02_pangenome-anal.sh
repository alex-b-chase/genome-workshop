#!/bin/bash
#SBATCH --job-name=panaroo-thresholds
#SBATCH -p standard-s
#SBATCH -A abchase_geol4379_1267_001c_0001
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=/projects/abchase/geol4379_1267_001c/shared_data/genome_workshop/pangenome/%u/panaroo-%j.out

set -euo pipefail
source ~/.bashrc

BASE=/projects/abchase/geol4379_1267_001c/shared_data

PANGENOME=$BASE/genome_workshop/pangenome
SOFTWARE=$BASE/software

# Use the same per-user workspace created before genome-annotate.sh.
# If needed, create it first with:
#   mkdir -p /projects/abchase/geol4379_1267_001c/shared_data/genome_workshop/pangenome/$USER
USERDIR=$PANGENOME/$USER
PROKKADIR=$USERDIR/prokka
PANAROOBASE=$USERDIR/panaroo

THREADS=${SLURM_CPUS_PER_TASK}

echo ""
echo "User workspace:"
echo "  $USERDIR"
echo ""

############################################################
#################### FIND PROKKA GFFS #######################
############################################################

shopt -s nullglob

GFFS=("$PROKKADIR"/*/*.gff)

if [[ ${#GFFS[@]} -eq 0 ]]; then
    echo "ERROR: No Prokka GFF files found."
    exit 1
fi

echo "Found ${#GFFS[@]} genomes:"
printf '  %s\n' "${GFFS[@]}"
echo ""


############################################################
###################### RUN PANAROO ###########################
############################################################

conda activate "$SOFTWARE/panaroo"

mkdir -p "$PANAROOBASE"


# Protein-family identity thresholds to compare.
#
# Panaroo's default is 0.70.
#
# Lower values allow more divergent proteins to be grouped
# into the same gene family.
#
# Higher values require proteins to be more similar before
# they are grouped together.

THRESHOLDS=(
    "0.50:50"
    "0.60:60"
    "0.70:70"
    "0.80:80"
    "0.90:90"
    "0.95:95"
)

for X in "${THRESHOLDS[@]}"
do
    THRESHOLD=${X%%:*}
    LABEL=${X##*:}

    OUTDIR=$PANAROOBASE/family_${LABEL}

    echo ""
    echo "============================================================"
    echo "Family identity threshold: ${LABEL}%"
    echo "============================================================"
    echo ""

    rm -rf "$OUTDIR"

    panaroo \
        -i "${GFFS[@]}" \
        -o "$OUTDIR" \
        --clean-mode strict \
        --family_threshold "$THRESHOLD" \
        -t "$THREADS"

done


conda deactivate


echo ""
echo "============================================================"
echo "Panaroo threshold analysis complete for user: $USER"
echo "============================================================"
echo ""
echo "Results:"
echo "  $PANAROOBASE"
echo ""


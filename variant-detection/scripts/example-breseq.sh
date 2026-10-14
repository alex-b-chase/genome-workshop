#!/bin/bash

# Example breseq workflow for an evolved bacterial isolate.
#
# This script is provided to illustrate the analysis used to generate
# the example output in this repository. File paths and software setup
# will need to be changed for another computing environment.

set -euo pipefail

THREADS=8
SAMPLE="sample_name"

REFGENOME="reference/Curtobacterium_MMLR14002.gbk"
R1="reads/${SAMPLE}_R1.fastq.gz"
R2="reads/${SAMPLE}_R2.fastq.gz"

CLEAN_R1="${SAMPLE}.R1.clean.fq"
CLEAN_R2="${SAMPLE}.R2.clean.fq"
OUTDIR="breseq-output/${SAMPLE}"

############################################################
# 1. Read quality control
############################################################

bbduk.sh \
    in1="$R1" \
    in2="$R2" \
    out1="$CLEAN_R1" \
    out2="$CLEAN_R2" \
    minlen=25 \
    qtrim=rl \
    trimq=10 \
    ktrim=r \
    k=25 \
    ref=adapters.fa \
    hdist=1

############################################################
# 2. Compare evolved isolate reads to the ancestral genome
############################################################

breseq \
    -j "$THREADS" \
    -r "$REFGENOME" \
    -o "$OUTDIR" \
    "$CLEAN_R1" \
    "$CLEAN_R2"

############################################################
# 3. Save the GenomeDiff file for comparisons across isolates
############################################################

mkdir -p gd_files
cp "$OUTDIR/output/output.gd" "gd_files/${SAMPLE}.gd"

############################################################
# 4. Compare mutation calls across multiple evolved isolates
############################################################
#
# After breseq has been run independently on multiple isolates:
#
# gdtools COMPARE \
#     -r "$REFGENOME" \
#     -o compare.html \
#     gd_files/*.gd
#
# Open compare.html in a web browser to inspect mutations shared
# across isolates and mutations unique to individual lineages.

rm -f "$CLEAN_R1" "$CLEAN_R2"

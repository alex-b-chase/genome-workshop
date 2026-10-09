#!/bin/bash

# Test that all software required for the genome workshops
# can be accessed from the shared course directory.

source ~/.bashrc

module load conda

BASE=/projects/abchase/geol4379_1267_001c/shared_data
SOFTWARE=$BASE/software


echo ""
echo "========================================"
echo "        GENOME WORKSHOP SOFTWARE"
echo "========================================"
echo ""


############################################################
######################## BBMAP ###############################
############################################################

echo "===== BBMAP ====="

conda activate $SOFTWARE/bbmap

for x in bbduk.sh reformat.sh rename.sh stats.sh; do
    command -v $x || echo "$x NOT FOUND"
done

conda deactivate
echo ""


############################################################
######################## SPADES ##############################
############################################################

echo "===== SPADES ====="

conda activate $SOFTWARE/spades

command -v spades.py || echo "SPAdes NOT FOUND"
spades.py --version 2>&1 || echo "SPAdes FAILED"

conda deactivate
echo ""


############################################################
######################## ABYSS ###############################
############################################################

echo "===== ABYSS ====="

conda activate $SOFTWARE/abyss

command -v abyss-pe || echo "ABySS NOT FOUND"
abyss-pe --version 2>&1 || echo "ABySS FAILED"

conda deactivate
echo ""


############################################################
######################## VELVET ##############################
############################################################

echo "===== VELVET ====="

conda activate $SOFTWARE/velvet

command -v velveth || echo "velveth NOT FOUND"
command -v velvetg || echo "velvetg NOT FOUND"

conda deactivate
echo ""


############################################################
######################## IDBA ################################
############################################################

echo "===== IDBA-UD ====="

conda activate $SOFTWARE/idba

command -v fq2fa || echo "fq2fa NOT FOUND"
command -v idba_ud || echo "idba_ud NOT FOUND"

if idba_ud 2>&1 | grep -q "Iterative de Bruijn Graph Assembler"; then
    echo "IDBA-UD OK"
else
    echo "IDBA-UD FAILED"
fi

conda deactivate
echo ""


############################################################
####################### FASTANI ##############################
############################################################

echo "===== FASTANI ====="

conda activate $SOFTWARE/fastani

command -v fastANI || echo "FastANI NOT FOUND"
fastANI --version 2>&1 || echo "FastANI FAILED"

conda deactivate
echo ""


############################################################
######################## PROKKA ##############################
############################################################

echo "===== PROKKA ====="

conda activate $SOFTWARE/prokka

command -v prokka || echo "Prokka NOT FOUND"
prokka --version 2>&1 || echo "Prokka FAILED"

# Check the Perl dependency that previously caused problems.

perl -MXML::Simple -e 'print "XML::Simple OK\n"' 2>&1 || \
    echo "XML::Simple FAILED"

conda deactivate
echo ""


############################################################
######################## PANAROO #############################
############################################################

echo "===== PANAROO ====="

conda activate $SOFTWARE/panaroo

command -v panaroo || echo "Panaroo NOT FOUND"

panaroo --version 2>&1 || \
    panaroo --help >/dev/null 2>&1 && echo "Panaroo OK"

# Check several programs used by Panaroo.

for x in mafft mash cd-hit; do
    command -v $x || echo "$x NOT FOUND"
done

conda deactivate
echo ""


############################################################
######################## BOWTIE2 #############################
############################################################

echo "===== BOWTIE2 ====="

conda activate $SOFTWARE/bowtie2

command -v bowtie2 || echo "Bowtie2 NOT FOUND"
command -v bowtie2-build || echo "bowtie2-build NOT FOUND"

bowtie2 --version 2>&1 | head -n 5

conda deactivate
echo ""


############################################################
######################## SAMTOOLS ############################
############################################################

echo "===== SAMTOOLS ====="

conda activate $SOFTWARE/samtools

command -v samtools || echo "samtools NOT FOUND"
samtools --version 2>&1 | head -n 3

conda deactivate
echo ""


############################################################
######################## FINISHED ############################
############################################################

echo "========================================"
echo "Software test complete."
echo ""
echo "Look above for any:"
echo "  NOT FOUND"
echo "  FAILED"
echo "========================================"


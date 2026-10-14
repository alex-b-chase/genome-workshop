#!/bin/bash
#$ -N curto_D1-2-t2_B
#$ -q mic,bio
#$ -pe openmp 8
#$ -j y

echo "Job started on `hostname` at `date`"
module load samtools/1.3
module load bowtie2/2.2.7
module load R/3.4.1
module load breseq/0.26.1
module load BBMap/37.50

REF=curto_D1-2-t2
READBASE=/dfs5/bio/abchase/genomes/evolution_complete
BBMAPDIR=/data/users/abchase
FFILE=$READBASE/genome_raw/4R125-L3-P20-AGGCAGAA-CTCCTTAC-READ1-Sequences.txt.gz
RFILE=$READBASE/genome_raw/4R125-L3-P20-AGGCAGAA-CTCCTTAC-READ2-Sequences.txt.gz

OUTDIR=$READBASE/breseq/$REF
THREAD=8

REFGENOME=/dfs5/bio/abchase/genomes/ref_genome/Curtobacterium_MMLR14002.gbk

cd $READBASE/breseq

bbduk.sh in1=$FFILE in2=$RFILE \
out1=$REF.R1.clean.fq out2=$REF.R2.clean.fq \
minlen=25 qtrim=rl trimq=10 ktrim=r k=25 ref=$BBMAPDIR/nextera.fa.gz hdist=1

rm -rf $OUTDIR

breseq -j $THREAD -r $REFGENOME \
-o $OUTDIR \
$REF.R1.clean.fq $REF.R2.clean.fq 

rm -f $REF.R1.clean.fq
rm -f $REF.R2.clean.fq

cp $OUTDIR/output/output.gd $READBASE/breseq/$REF.gd
cp -R $OUTDIR/output/ $READBASE/breseq/${REF}_output/
rm -rf $OUTDIR

echo "Job Ended at `date`"

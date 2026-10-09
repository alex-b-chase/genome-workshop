# Genome Assembly and Comparative Genomics Workshop

Computational exercises developed for **BIOL/GEOL 6379: Microbial Diversity** at Southern Methodist University.

These workshops introduce microbial genome assembly and comparative genomics using command-line bioinformatics tools and R.

Although the exercises are taught using the **SMU M3 high-performance computing cluster**, the workshop is fully reproducible outside SMU. The raw sequencing data used for genome assembly are publicly available through the NCBI Sequence Read Archive (SRA), and all analysis scripts and processed teaching data are provided in this repository.

The goal is not simply to run bioinformatics software. We use the computational workflow to connect genome sequence data to concepts in microbial ecology and evolution, including:

- genome assembly
- sequence quality and assembly statistics
- nucleotide-level genome similarity
- homology, orthology, and paralogy
- genome annotation
- core and flexible genomes
- pangenomes
- gene gain and loss
- horizontal gene transfer
- phylogenetic conservation of microbial traits

# Before starting: M3 and Unix skills

These exercises are run using the **SMU M3 HPC system**.

You should be comfortable navigating a Unix/Linux command line before beginning the workshop.

## Required SMU resources

### 1. HPC accounts and access

SMU HPC accounts and class access are managed through ColdFront.

SMU documentation:

https://southernmethodistuniversity.github.io/hpc_docs/accounts.html

Students enrolled in an HPC-enabled course are added through a ColdFront Class Project. Students must accept the relevant policies and allocations before their HPC account is provisioned.

M3 can be accessed through the browser-based HPC OnDemand portal or through SSH.

### 2. Unix/Linux tutorial

Complete the SMU Unix/Linux tutorial before beginning the genome workshop:

https://southernmethodistuniversity.github.io/hpc_docs/tutorials/unix/unix.html

At minimum, you should understand:

```bash
pwd
ls
cd
mkdir
cp
mv
rm
```
# Using this workshop outside SMU

You do **not** need access to the SMU M3 cluster to complete this workshop.

The scripts were written for M3 and therefore contain SMU-specific Slurm settings and file paths, but the underlying analyses can be run on any Linux workstation or HPC system with the required software installed.

## Public sequencing data

The raw paired-end Illumina reads used for the genome assembly exercise are publicly available from the NCBI Sequence Read Archive:

**SRA accession: SRR24620908**

NCBI record:

https://trace.ncbi.nlm.nih.gov/Traces/?view=run_browser&acc=SRR24620908&display=metadata

The FASTQ files can be downloaded using the NCBI SRA Toolkit. For example:

```bash
prefetch SRR24620908

fasterq-dump \
    --split-files \
    SRR24620908
```

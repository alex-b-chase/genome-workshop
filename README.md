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
- recombination
- phylogenetic conservation of microbial traits

---

# Before starting: M3 and Unix skills

Basic Unix/Linux command-line skills are a prerequisite for this workshop.

**SMU students:** complete the SMU Unix/Linux and scripting tutorials below before the in-class HPC exercises.

**Users outside SMU:** any equivalent introductory Unix/Linux tutorial is sufficient.

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

You should also understand the difference between relative and absolute paths and be comfortable moving between directories.

### 3. Bash scripting tutorial

Review the SMU scripting tutorial before beginning the workshop:

https://southernmethodistuniversity.github.io/hpc_docs/tutorials/unix/scripting.html

At minimum, you should understand:

- what a shell script is
- variables
- comments beginning with `#`
- how to run a script with `bash`
- how to make a file executable with `chmod`
- how file paths are used inside scripts

For example:

```bash
bash script.sh
```

or:

```bash
chmod +x script.sh
./script.sh
```

### 4. Running jobs on M3

Computationally intensive analyses should be submitted through the Slurm scheduler rather than run directly on the login node.

Workshop scripts therefore begin with Slurm directives such as:

```bash
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00
```

Submit a job with:

```bash
sbatch script.sh
```

Check your jobs with:

```bash
squeue -u $USER
```

The Slurm output file is usually the first place to look if a job fails.

## Before coming to class

Before beginning the computational workshops, you should be able to:

1. log into M3
2. use `pwd`, `ls`, and `cd` to navigate directories
3. distinguish your home directory from the shared course directory
4. view and edit a shell script
5. submit a script using `sbatch`
6. locate the resulting Slurm output file

If any of these steps are unfamiliar, complete the Unix/Linux and scripting tutorials above before proceeding.

---

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

This generates paired FASTQ files similar to:

```text
SRR24620908_1.fastq
SRR24620908_2.fastq
```

These files can be substituted for the SMU course files used in the example scripts.

## Software

The workshop uses the following command-line tools.

### Genome assembly

- BBMap / BBDuk
- SPAdes
- ABySS
- Velvet
- IDBA-UD

### Contig screening

- Bowtie2
- samtools
- BLAST+

### Comparative genomics

- FastANI
- Prokka
- Panaroo

### Downstream analysis

- R
- RStudio
- ggplot2

The SMU course installation uses separate conda environments for each major program to minimize dependency conflicts.

If running the workshop elsewhere, install these tools using conda, mamba, micromamba, containers, or the software-management system available on your HPC cluster.

## Adapting the scripts

Most scripts begin with paths such as:

```bash
BASE=/projects/abchase/geol4379_1267_001c/shared_data
```

This is the SMU course directory.

If you are working elsewhere, change `BASE`, the raw-data paths, and the Slurm `#SBATCH` directives to match your own computing environment.

For example:

```bash
BASE=/path/to/your/genome-workshop
```

The biological workflow and program commands are otherwise portable.

---

# SMU course directories

For students completing the workshop on M3, course resources are located at:

```bash
/projects/abchase/geol4379_1267_001c/shared_data
```

Important directories include:

```text
shared_data/
├── rawdata/
│   └── genomes/
├── software/
├── genome_workshop/
└── bin/
```

The command-line programs used during the workshop are installed as shared conda environments under:

```bash
/projects/abchase/geol4379_1267_001c/shared_data/software
```

For example:

```bash
conda activate /projects/abchase/geol4379_1267_001c/shared_data/software/spades
```

When finished:

```bash
conda deactivate
```

---

# Workshop overview

The workshop is divided into two connected exercises.

## Workshop 1: Genome assembly

### Question

How can short sequencing reads be reconstructed into a microbial genome, and how does the choice of assembler influence the resulting assembly?

### Workflow

```text
raw paired-end reads
        |
        v
read quality control
        |
        v
genome assembly
        |
        v
contigs
        |
        v
assembly statistics
        |
        v
GC + coverage + taxonomy screening
```

We compare four de Bruijn graph assemblers:

- SPAdes
- ABySS
- Velvet
- IDBA-UD

All four use de Bruijn graph approaches, but they differ in how k-mers, graph construction, coverage, and graph resolution are handled. As a result, the same sequencing reads can produce different assemblies.

This allows us to ask:

> How much does the choice of assembler affect the genome we reconstruct?

### Read quality control

We use **BBMap / BBDuk** to remove sequencing adapters, trim low-quality sequence, and remove very short reads before assembly.

### Assembly statistics

For each assembly we compare metrics including:

- total assembly size
- number of contigs
- N50
- longest contig
- GC content

A more contiguous assembly is not automatically a more accurate assembly.

### Contig screening

Individual contigs can also be evaluated using three independent properties:

```text
GC content
coverage
taxonomy
```

Reads are mapped back to the assembly using Bowtie2 to estimate coverage.

Taxonomic assignment can be obtained using BLAST against the NCBI nucleotide database. Because the complete NCBI `nt` database is extremely large, this search is demonstrated rather than run during class.

---

## Workshop 2: Comparative genomics

### Question

How does our picture of genome similarity and gene content change as increasingly divergent microbial genomes are compared?

### Workflow

```text
assembled genomes
        |
        v
genome statistics
        |
        v
average nucleotide identity
        |
        v
gene prediction + annotation
        |
        v
gene-family clustering
        |
        v
core + flexible genome
```

Five related bacterial genomes are compared using:

- **FastANI** for nucleotide-level genome similarity
- **Prokka** for standardized genome annotation
- **Panaroo** for gene-family and pangenome analysis
- **R** for visualization and downstream analysis

---

# Comparative genomics concepts

## Average nucleotide identity

Average nucleotide identity (ANI) measures nucleotide similarity across homologous genomic regions between genomes.

ANI asks:

> How similar are homologous genomic regions between these organisms?

ANI is not the same as gene-content similarity. Two genomes may be highly similar across regions that align while still differing in the presence or absence of flexible genes.

## Genome annotation

All genomes are annotated using **Prokka** before gene-content comparisons.

Using the same annotation pipeline for every genome is important because inconsistent gene prediction or annotation can create apparent differences in gene content.

The Prokka GFF files are used as input for Panaroo.

## Homology, orthology, and paralogy

**Homologous genes** share evolutionary ancestry.

Homologs can include:

- **orthologs** — homologous genes separated by lineage divergence
- **paralogs** — homologous genes generated by gene duplication

Sequence similarity provides evidence for homology, but a particular percent identity does not by itself define orthology.

## Core and flexible genomes

For a given set of genomes:

**Core genome**  
Gene families present in every genome being compared.

**Flexible genome**  
Gene families present in some, but not all, genomes.

**Pangenome**  
The complete set of gene families observed across all genomes being compared.

Importantly:

> The core genome and pangenome are conditional on which genomes are included and how gene families are defined.

Adding increasingly divergent genomes generally causes:

```text
core genome       decreases
pangenome         increases
```

## What counts as the same gene family?

Panaroo is run using several protein-family identity thresholds:

```text
50%
60%
70%
80%
90%
95%
```

Increasing the required sequence similarity can split increasingly divergent homologs into separate gene families.

We therefore examine two factors that influence the inferred pangenome.

### Biological sampling

```text
adding increasingly divergent genomes
                |
                v
core genome decreases
pangenome increases
```

### Analytical definition

```text
increasing gene-family identity threshold
                |
                v
more gene families are distinguished
                |
                v
core genome decreases
pangenome increases
```

This illustrates an important point:

> A pangenome is not a single fixed property of an organism or species.

Its inferred size depends on both biological sampling and analytical definitions.

---

# R analysis

HPC outputs are analyzed locally in RStudio.

The R workflow includes:

1. comparing genome assembly statistics
2. generating an ANI heatmap
3. examining gene-family frequency
4. comparing core genome and pangenome size across protein-family identity thresholds
5. comparing core genome and pangenome size as increasingly divergent genomes are added

These analyses connect computational results back to microbial evolution:

```text
vertical inheritance
        |
        v
core genome / phylogeny

mutation + gene gain/loss + duplication + recombination + HGT
        |
        v
flexible genome variation

core + flexible genome
        |
        v
distribution of microbial traits across lineages
```

---

# Key biological questions

By the end of the workshop, you should be able to think about questions such as:

- What information does ANI provide that taxonomy alone does not?
- What makes two genes homologs?
- Why are orthology and sequence identity not equivalent?
- Why does the estimated core genome depend on which genomes are sampled?
- Why does changing a gene-family threshold alter the inferred pangenome?
- Which evolutionary processes generate flexible gene content?
- Why might flexible genes vary among closely related microbial lineages?
- How can comparative genomics help identify candidate traits associated with environmental adaptation?
- How do vertical inheritance and flexible gene evolution jointly shape trait distributions across microbial lineages?

---

# Repository structure

```text
genome-workshop/
├── assembly/
│   ├── test-install.sh
│   ├── spades.sh
│   ├── abyss.sh
│   ├── velvet.sh
│   ├── idba.sh
│   └── blob-screen.sh
│
├── comparative-genomics/
│   ├── genome-compare.sh
│   └── panaroo.sh
│
├── R/
│   └── comparative-genomics.R
│
└── data/
    └── processed files used for the R exercises
```

Large raw sequencing files, genome assemblies, assembly intermediates, and reference databases are not stored in this repository. Public sequencing data can be downloaded from NCBI using the accession listed above.

---

# Learning goals

By the end of the workshop, you should be able to explain:

- how short-read genome assembly works conceptually
- why different assemblers can produce different results
- what common assembly statistics measure
- what ANI tells us about genome similarity
- the distinction between homology, orthology, and paralogy
- how core and flexible genomes are defined
- why the size of a core genome depends on which genomes are sampled
- why changing gene-family definitions changes the inferred pangenome
- how mutation, gene gain, gene loss, duplication, recombination, and horizontal gene transfer contribute to microbial genome evolution
- how comparative genomics can identify candidate traits associated with environmental differentiation

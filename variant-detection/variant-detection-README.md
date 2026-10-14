# Variant Detection with breseq

This short exercise uses outputs from **Chase et al. (2021), "Adaptive differentiation and rapid evolution of a soil bacterium along a climate gradient"** (*PNAS*) to illustrate how mutations can be identified by comparing evolved bacterial isolates to a known ancestral genome.

Paper: https://www.pnas.org/doi/10.1073/pnas.2101254118

## Study context

The study transplanted an isogenic *Curtobacterium* strain, **MMLR14002**, across a Southern California climate gradient and reisolated descendants every 6 months over an 18-month field experiment to ask whether evolution could be detected on ecological timescales. Whole-genome sequencing of 112 evolved isolates identified 783 de novo mutations at 121 unique base-pair positions, including SNPs, deletions, and small insertions.

The published analysis compared variant calls from GATK and breseq and found no significant difference between the pipelines; the paper presents the GATK results. The breseq files included here are from the same evolved-isolate dataset and provide a convenient way to inspect mutation calls and their genomic context.

## Files in this exercise

```text
variant-detection/
├── README.md
├── reference/
│   └── Curtobacterium_MMLR14002.gbk
├── breseq-output/
│   └── curto_D1-2-t2_output/
│       ├── index.html
│       ├── summary.html
│       ├── marginal.html
│       └── evidence/
├── compare.html
├── count.csv
└── scripts/
    └── example-breseq.sh
```

The **reference genome** is the ancestral strain used for comparison.

The **single-sample breseq output** shows the mutations predicted in one evolved isolate and links each prediction to read-level evidence.

The **compare.html** file summarizes mutations across many evolved isolates, making it possible to look for repeated mutations across independently evolving lineages.

The **count.csv** file provides a machine-readable summary of mutation counts for each isolate, including base substitutions, small indels, larger events, and whether base substitutions occur in synonymous, nonsynonymous, nonsense, or intergenic positions.

## Viewing the breseq output

You do **not** need to run breseq for this exercise.

Clone or download the repository and open the HTML files locally in a web browser. For example:

```bash
open variant-detection/breseq-output/curto_D1-2-t2_output/index.html
```

On Windows, navigate to the file and open it with your browser.

Keep the complete breseq output directory together. The main `index.html` page links to additional files in the `evidence/` directory that show the sequencing evidence supporting individual mutation calls.

## What does breseq tell us?

For each predicted mutation, examine:

- genomic position
- mutation type
- reference and alternate sequence
- whether the mutation is coding or intergenic
- gene annotation
- amino-acid consequence for coding SNPs
- read evidence supporting the call

Coding SNPs can be further classified as:

- **synonymous** — the nucleotide changes but the encoded amino acid does not
- **nonsynonymous** — the nucleotide change alters the encoded amino acid
- **nonsense** — the nucleotide change introduces a stop codon

The comparison output also lets us ask whether the same genes or genomic positions mutate repeatedly across independently evolving isolates. Repeated mutation provides evidence of **evolutionary parallelism** and can identify candidate targets of selection.

## Example workflow

The included `scripts/example-breseq.sh` is a simplified version of the workflow used to generate these outputs. It is provided to show the computational logic rather than as an assignment to run.

Conceptually:

```text
ancestral reference genome
          +
paired-end reads from evolved isolate
          |
          v
     read quality control
          |
          v
        breseq
          |
          +----> GenomeDiff (.gd)
          |
          +----> interactive HTML output
          |
          v
 gdtools comparison across isolates
          |
          v
     compare.html
```

## From experimental evolution to natural populations

This example starts from a relatively simple case: an evolved isolate is compared against a known ancestral genome. A mutation is therefore a sequence difference that arose along that lineage relative to the ancestor.

The same basic logic can be extended to natural microbial populations using metagenomic read recruitment, but the interpretation becomes more complicated. Instead of asking only whether a mutation is present in an isolate, we can ask **what fraction of reads support different nucleotides at the same genomic position**.

This leads to several useful levels of variation:

- **SNV — single nucleotide variant:** variation at a nucleotide position
- **SCV — single codon variant:** variation resolved at the codon level
- **SAAV — single amino acid variant:** variation resolved by the encoded amino acid

For a detailed conceptual treatment of these approaches in metagenomic populations, see the anvi'o tutorial:

https://merenlab.org/blog/analyzing-variability/#generating-a-snv-scv-or-saav-profile

The important transition is:

```text
EXPERIMENTAL EVOLUTION
known ancestor + evolved isolate
        |
        v
which new mutations appeared?

              versus

NATURAL POPULATION / METAGENOME
reference genome + population of mapped reads
        |
        v
what variants exist, and at what frequencies?
```

## Questions to consider

1. What kinds of mutations can you identify in the breseq output besides SNPs?
2. For coding SNPs, what is the difference between synonymous and nonsynonymous mutations?
3. Why might the same gene accumulate mutations independently in multiple evolved isolates?
4. Why is a variant frequency important when moving from a clonal isolate to a metagenomic population?
5. What additional biological and technical processes could produce nucleotide variation in metagenomic read recruitment?

## References

Chase AB, Weihe C, Martiny JBH. 2021. Adaptive differentiation and rapid evolution of a soil bacterium along a climate gradient. *Proceedings of the National Academy of Sciences* 118:e2101254118. https://doi.org/10.1073/pnas.2101254118

breseq documentation: https://breseq.barricklab.org/

anvi'o microbial population genetics tutorial: https://merenlab.org/blog/analyzing-variability/

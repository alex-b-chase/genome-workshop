############################################################
############ COMPARATIVE GENOMICS WORKSHOP ##################
############################################################

# This script assumes you have cloned the workshop repository:
#
#   git clone https://github.com/alex-b-chase/genome-workshop.git
#   cd genome-workshop
#
# Run this script with the ROOT of the repository as your working directory.
# The processed comparative-genomics data are organized as:
#
# genome-workshop/
#   |-- R/
#   |   `-- pangenome-output.R
#   `-- data/
#       |-- stats/
#       |   `-- genome_stats.tsv
#       |-- ani/
#       |   |-- all_vs_all.fastani.tsv
#       |   `-- all_vs_all.fastani.tsv.matrix
#       `-- panaroo/
#           |-- family_50/
#           |-- family_60/
#           |-- family_70/
#           |-- family_80/
#           |-- family_90/
#           `-- family_95/
#
# Each Panaroo threshold directory contains the small output files
# used in this exercise, including gene_presence_absence.Rtab and
# summary_statistics.txt. family_70 also includes
# gene_presence_absence.csv for inspecting gene annotations.
#
# Check that R is running from the repository root.

DATA_DIR <- "data"

if (!dir.exists(DATA_DIR)) {
  stop(
    "Could not find the data/ directory. ",
    "Set your working directory to the root of the genome-workshop repository."
  )
}


library(ggplot2)

############################################################
################### GENOME STATISTICS ########################
############################################################

# These statistics were calculated on the HPC using BBMap
# stats.sh.

genome_stats <- read.delim(
  file.path(DATA_DIR, "stats", "genome_stats.tsv"),
  check.names = FALSE
)

genome_stats

# Look at the available columns.

names(genome_stats)

# Questions:
#
# How similar are the five genomes in total genome size?
#
# How fragmented are the assemblies?
#
# Do any genomes immediately look unusual?
#
# Remember:
# assembly statistics describe the reconstructed genome.
# They do NOT tell us how evolutionarily related the
# organisms are.


############################################################
######################## FASTANI #############################
############################################################

# FastANI asks a different question:
#
# How similar are homologous genomic regions between genomes?
#
# The raw output contains:
#
# query genome
# reference genome
# ANI
# mapped fragments
# total query fragments

ani <- read.delim(
  file.path(DATA_DIR, "ani", "all_vs_all.fastani.tsv"),
  header = FALSE,
  sep = "\t"
)

names(ani) <- c(
  "query",
  "reference",
  "ANI",
  "mapped_fragments",
  "total_fragments"
)


############################################################
################ CLEAN GENOME NAMES ##########################
############################################################

# Remove directory paths and FASTA extensions.

clean_name <- function(x) {
  
  x <- basename(x)
  
  sub(
    "\\.(fasta|fa|fna)$",
    "",
    x
  )
}


ani$query <- clean_name(ani$query)
ani$reference <- clean_name(ani$reference)

head(ani)


############################################################
############ HOW MUCH OF THE GENOME MATCHED? ################
############################################################

# FastANI also reports how many fragments contributed
# to each comparison.
#
# ANI and the fraction of the genome that aligns are
# related ideas, but they are not the same thing.

ani$mapped_fraction <-
  ani$mapped_fragments /
  ani$total_fragments


head(ani)


############################################################
################### BUILD ANI MATRIX #########################
############################################################

genomes <- sort(
  unique(
    c(
      ani$query,
      ani$reference
    )
  )
)


ANI <- matrix(
  NA_real_,
  nrow = length(genomes),
  ncol = length(genomes),
  dimnames = list(genomes, genomes)
)

diag(ANI) <- 100


# FastANI can report reciprocal comparisons.
#
# For the heatmap, average the two directions so we have
# one symmetric ANI value for every genome pair.

for (i in seq_along(genomes)) {
  
  for (j in seq_along(genomes)) {
    
    g1 <- genomes[i]
    g2 <- genomes[j]
    
    values <- ani$ANI[
      (ani$query == g1 & ani$reference == g2) |
        (ani$query == g2 & ani$reference == g1)
    ]
    
    if (length(values) > 0) {
      
      ANI[i, j] <- mean(
        values,
        na.rm = TRUE
      )
    }
  }
}


round(ANI, 2)


############################################################
################ ORDER GENOMES BY ANI ########################
############################################################

# Convert similarity into distance:
#
# 100 ANI = distance 0
# 95 ANI  = distance 5

if (!anyNA(ANI)) {
  
  ani_tree <- hclust(
    as.dist(100 - ANI)
  )
  
  genome_order <-
    ani_tree$labels[
      ani_tree$order
    ]
  
} else {
  
  # FastANI may not report very divergent genome pairs.
  #
  # If that occurs, retain the original genome order.
  
  genome_order <- genomes
  
  message(
    "Missing ANI values detected; ",
    "using genome input order."
  )
}


genome_order


############################################################
###################### ANI HEATMAP ###########################
############################################################

ani_plot <- as.data.frame(
  as.table(ANI)
)

names(ani_plot) <- c(
  "Genome1",
  "Genome2",
  "ANI"
)


ani_plot$Genome1 <- factor(
  ani_plot$Genome1,
  levels = rev(genome_order)
)

ani_plot$Genome2 <- factor(
  ani_plot$Genome2,
  levels = genome_order
)


ggplot(
  ani_plot,
  aes(
    x = Genome2,
    y = Genome1,
    fill = ANI
  )
) +
  geom_tile() +
  geom_text(
    aes(
      label = round(ANI, 1)
    ),
    size = 4
  ) +
  coord_equal() +
  labs(
    x = NULL,
    y = NULL,
    fill = "ANI (%)"
  ) +
  theme_classic() +
  theme(
    axis.text.x = element_text(
      angle = 45,
      hjust = 1
    )
  )



############################################################
###################### PANAROO ###############################
############################################################

pan70 <- read.delim(
  file.path(DATA_DIR, "panaroo", "family_70", "gene_presence_absence.Rtab"),
  check.names = FALSE
)

head(pan70)


############################################################
################ PRESENCE / ABSENCE MATRIX ###################
############################################################

# The first column contains the gene-family name.
#
# Remaining columns indicate whether each genome contains
# that gene family.

gene_family <- pan70[[1]]

PANGENOME <- as.matrix(
  pan70[, -1]
)

rownames(PANGENOME) <- gene_family

storage.mode(PANGENOME) <- "numeric"


dim(PANGENOME)

head(PANGENOME)

colnames(PANGENOME)

############################################################
################### CORE VS FLEXIBLE #########################
############################################################

# Count how many genomes contain each gene family.

frequency <- rowSums(
  PANGENOME > 0
)


table(frequency)


N <- ncol(PANGENOME)


# For this exercise:
#
# core:
# present in all 5 genomes
#
# shared flexible:
# present in 2-4 genomes
#
# unique:
# present in only one genome

gene_class <- ifelse(
  frequency == N,
  "Core",
  ifelse(
    frequency == 1,
    "Unique",
    "Shared flexible"
  )
)


table(gene_class)

## Is “core” an intrinsic property of this gene?

############################################################
############ EFFECT OF FAMILY IDENTITY THRESHOLD #############
############################################################

thresholds <- c(
  50,
  60,
  70,
  80,
  90,
  95
)


threshold_results <- data.frame()


for (threshold in thresholds) {
  
  file <- file.path(
    DATA_DIR,
    "panaroo",
    paste0("family_", threshold),
    "gene_presence_absence.Rtab"
  )
  
  
  dat <- read.delim(
    file,
    check.names = FALSE
  )
  
  
  PA <- as.matrix(
    dat[, -1]
  )
  
  storage.mode(PA) <- "numeric"
  
  
  N <- ncol(PA)
  
  frequency <- rowSums(
    PA > 0
  )
  
  
  # Pangenome:
  # every gene family detected in at least one genome.
  
  pan_size <- sum(
    frequency > 0
  )
  
  
  # Core:
  # gene families found in every genome.
  
  core_size <- sum(
    frequency == N
  )
  
  
  flexible_size <-
    pan_size -
    core_size
  
  
  threshold_results <- rbind(
    threshold_results,
    data.frame(
      Threshold = threshold,
      Core = core_size,
      Flexible = flexible_size,
      Pangenome = pan_size
    )
  )
}


threshold_results

threshold_long <- rbind(
  
  data.frame(
    Threshold = threshold_results$Threshold,
    Gene_families = threshold_results$Core,
    Genome_component = "Core genome"
  ),
  
  data.frame(
    Threshold = threshold_results$Threshold,
    Gene_families = threshold_results$Pangenome,
    Genome_component = "Pangenome"
  )
)

ggplot(
  threshold_long,
  aes(
    x = Threshold,
    y = Gene_families,
    linetype = Genome_component
  )
) +
  geom_line(
    linewidth = 1
  ) +
  geom_point(
    size = 3
  ) +
  scale_x_continuous(
    breaks = thresholds
  ) +
  labs(
    x = "Minimum protein family identity (%)",
    y = "Number of gene families",
    linetype = NULL
  ) +
  theme_classic()

## Why does requiring greater protein similarity change our estimate of the core genome and pangenome?

############################################################
############### ORDER BY RELATEDNESS #########################
############################################################

FOCAL <- "MCLR17_059"

other_genomes <- setdiff(
  genomes,
  FOCAL
)


other_genomes <- other_genomes[
  order(
    ANI[
      FOCAL,
      other_genomes
    ],
    decreasing = TRUE,
    na.last = TRUE
  )
]


comparison_order <- c(
  FOCAL,
  other_genomes
)


comparison_order

colnames(PANGENOME)

comparison_order

############################################################
############ PANGENOME ACROSS RELATEDNESS ####################
############################################################

growth <- data.frame()


for (k in seq_along(comparison_order)) {
  
  genomes_now <-
    comparison_order[1:k]
  
  
  subset_matrix <- PANGENOME[
    ,
    genomes_now,
    drop = FALSE
  ]
  
  
  frequency <- rowSums(
    subset_matrix > 0
  )
  
  
  # Present in at least one genome.
  
  pan_size <- sum(
    frequency > 0
  )
  
  
  # Present in every genome included so far.
  
  core_size <- sum(
    frequency == k
  )
  
  
  growth <- rbind(
    growth,
    data.frame(
      Number_genomes = k,
      Added_genome = genomes_now[k],
      Core = core_size,
      Pangenome = pan_size
    )
  )
}


growth

growth_long <- rbind(
  
  data.frame(
    Number_genomes = growth$Number_genomes,
    Gene_families = growth$Core,
    Genome_component = "Core genome"
  ),
  
  data.frame(
    Number_genomes = growth$Number_genomes,
    Gene_families = growth$Pangenome,
    Genome_component = "Pangenome"
  )
)

ggplot(
  growth_long,
  aes(
    x = Number_genomes,
    y = Gene_families,
    linetype = Genome_component
  )
) +
  geom_line(
    linewidth = 1
  ) +
  geom_point(
    size = 3
  ) +
  scale_x_continuous(
    breaks = 1:5
  ) +
  labs(
    x = "Number of genomes included",
    y = "Number of gene families",
    linetype = NULL
  ) +
  theme_classic()


frequency_table <- as.data.frame(
  table(
    rowSums(PANGENOME > 0)
  )
)

names(frequency_table) <- c(
  "Number_genomes",
  "Gene_families"
)

frequency_table$Number_genomes <-
  as.numeric(
    as.character(
      frequency_table$Number_genomes
    )
  )


ggplot(
  frequency_table,
  aes(
    x = Number_genomes,
    y = Gene_families
  )
) +
  geom_col() +
  scale_x_continuous(
    breaks = 1:5
  ) +
  labs(
    x = "Number of genomes containing gene family",
    y = "Number of gene families"
  ) +
  theme_classic()


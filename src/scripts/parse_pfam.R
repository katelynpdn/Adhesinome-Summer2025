#!/usr/bin/env Rscript

# ============================================================
# parse_pfam.R
#
# Parse and add PFAM results into proteinTable.csv
#
# Usage:
# Rscript parse_pfam.R <outputDirectory>
#
# Expected files:
#   <outputDirectory>/hmmscan_domtblout
#   <outputDirectory>/proteinTable.csv
# ============================================================

# === Load packages ===
suppressPackageStartupMessages({
  library(tidyverse)
})


# === Check command-line arguments ===
args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1) {
  stop(
    paste0(
      "\nUsage:\n",
      "  Rscript parse_pfam.R <outputDirectory>\n\n"
    )
  )
}
outputDirectory <- args[1]

# === Check required inputs ===
if (!dir.exists(outputDirectory)) {
  stop(
    "ERROR: Output directory does not exist:\n  ",
    outputDirectory
  )
}


# === Define input/output files ===

pfam_file <- file.path(
  outputDirectory,
  "hmmscan_domtblout"
)

protein_table_file <- file.path(
  outputDirectory,
  "proteinTable.csv"
)


# === Check required tool outputs ==
if (!file.exists(pfam_file)) {
  stop(
    "ERROR: PFAM does not exist:\n  ",
    pfam_file
  )
}
if (!file.exists(protein_table_file)) {
  stop(
    "ERROR: proteinTable.csv does not exist:\n  ",
    protein_table_file
  )
}

# Read existing protein table
message("Reading proteinTable.csv...")

protein_table <- read_csv(
  protein_table_file,
  show_col_types = FALSE
)

message(
  "  Found ",
  nrow(protein_table),
  " proteins in proteinTable.csv"
)

# === Helper function: extract protein ID ===

extract_protein_id <- function(identifier) {

  # Handle missing values
  if (is.na(identifier) || identifier == "") {
    return(NA_character_)
  }

  # Remove FASTA ">" if present
  identifier <- str_remove(identifier, "^>")

  # Remove anything after the first whitespace
  identifier <- str_split(identifier, "\\s+")[[1]][1]

  # Format: PREFIX|ACCESSION|ENTRY_NAME
  if (str_detect(identifier, "\\|")) {
    parts <- str_split(identifier, "\\|")[[1]]

    if (length(parts) >= 2 && parts[2] != "") {
      return(parts[2])
    }
  }

  # Format: PREFIX_ACCESSION_ENTRY_NAME
  if (str_detect(identifier, "_")) {
    parts <- str_split(identifier, "_")[[1]]

    if (length(parts) >= 2 && parts[2] != "") {
      return(parts[2])
    }
  }

  # If neither format matches, return the identifier itself
  return(identifier)
}


# === Read HMMSCAN output === 

message("Reading HMMSCAN output...")

hmm.names <- c(
  "target_name", "target_accession", "target_length",
  "query_name", "query_accession", "query_length",
  "seq_evalue", "seq_score", "seq_bias",
  "domain_num", "num_target_domains",
  "c_evalue", "i_evalue", "domain_score", "domain_bias",
  "hmm_from", "hmm_to", "ali_from", "ali_to",
  "env_from", "env_to", "accuracy"
)

hmm_lines <- readLines(
  pfam_file,
  warn = FALSE
)


# Remove HMMER comment/header lines & blank lines
hmm_lines <- hmm_lines[
  !str_starts(
    str_trim(hmm_lines),
    "#"
  )
]
hmm_lines <- hmm_lines[
  str_trim(hmm_lines) != ""
]

# Split each line into whitespace-separated fields
hmm_split <- str_split(
  hmm_lines,
  "\\s+"
)

# Extract the first 22 fields and save everything after as domain description.
hmm_standard_fields <- lapply(
  hmm_split,
  function(x) {
    # Standard HMMER domtblout has at least 22 fields
    if (length(x) < 22) {
      c(
        x,
        rep(
          NA_character_,
          22 - length(x)
        )
      )
    } else {
      x[1:22]
    }
  }
)


# Extract description
pfam_descriptions <- vapply(
  hmm_split,
  function(x) {

    if (length(x) > 22) {
      paste(
        x[23:length(x)],
        collapse = " "
      )
    } else {
      ""
    }

  },
  character(1)
)


# Reconstruct the first 22 columns into a table
hmm_standard_lines <- vapply(
  hmm_standard_fields,
  function(x) {
    paste(
      x,
      collapse = " "
    )
  },
  character(1)
)
hmmscan_df <- read_table(
  paste(
    hmm_standard_lines,
    collapse = "\n"
  ),
  col_names = hmm.names,
  col_types = "cciccidddiiddddiiiiiid",
  progress = FALSE
)

# Add description back
hmmscan_df <- hmmscan_df %>%
  mutate(
    pfam_domain_description = pfam_descriptions
  )

message(
  "  Parsed ",
  nrow(hmmscan_df),
  " PFAM/domain hits"
)

# Extract protein IDs
hmmscan_df <- hmmscan_df %>%
  mutate(
    ID = vapply(
      query_name,
      extract_protein_id,
      character(1)
    )
  )

# Get most significant hit for each protein
filtered_hmm_df <- hmmscan_df %>% 
  group_by(ID) %>%
  # Find the lowest sequence E-value for each protein
  group_by(ID) %>%
  slice_min(
    order_by = seq_evalue,
    n = 1,
    with_ties = FALSE
  ) %>%
  ungroup() %>%
  transmute(
    ID,
    `Top PFAM Domain` =
      target_name,

    `PFAM Sequence E-value` =
      seq_evalue,

    `PFAM Domain Description` =
      pfam_domain_description
  )

# Remove old PFAM columns if they already exist
pfam_columns <- c(
  "Top PFAM Domain",
  "PFAM Sequence E-value",
  "PFAM Domain Description"
)
protein_table <- protein_table %>%
  select(
    -any_of(pfam_columns)
  )

# Merge PFAM information into protein_table
protein_table <- protein_table %>%
  left_join(
    filtered_hmm_df,
    by = "ID"
  ) %>%
  relocate(
    all_of(pfam_columns),
    .after = last_col()
  )

# Replace missing PFAM values with empty strings
protein_table <- protein_table %>%
  mutate(
    `Top PFAM Domain` =
      replace_na(`Top PFAM Domain`, ""),

    `PFAM Domain Description` =
      replace_na(`PFAM Domain Description`, "")
  )

# === Write output ===
write_csv(
  protein_table,
  protein_table_file
)

message(
  "Protein annotation table created: ",
  protein_table_file
)

message(
  "  Total proteins: ",
  nrow(protein_table)
)

message(
  "  Proteins with PFAM domains: ",
  sum(
    protein_table$`Top PFAM Domain` != "",
    na.rm = TRUE
  )
)

quit(
  save = "no",
  status = 0
)
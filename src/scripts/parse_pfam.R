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

hmm.names <- c("target_name", "target_accession", "target_length", "query_name", "query_accession", "query_length", "seq_evalue", "seq_score", "seq_bias", "domain_num", "num_target_domains", "c_evalue", "i_evalue", "domain_score", "domain_bias", "hmm_from", "hmm_to", "ali_from", "ali_to", "env_from", "env_to", "accuracy")
hmmscan_df <- read_table(file = hmmscan_domtblout_file, col_names = hmm.names, col_types = "cciccidddiiddddiiiiiid", skip = 3)

hmmscan_df <- hmmscan_df %>%
  mutate(
    ID = vapply(
      query_name,
      extract_protein_id,
      character(1)
    )
  )

message(
  "  Parsed ",
  nrow(hmmscan_df),
  " PFAM/domain hits"
)

# Filter out anything that doesn't satisfy inclusion threshold
#   (seq_evalue \< 0.01 and c-evalue \< 0.01), 
# Create pfam_domains, unique_domains, and uncertain_domains

filtered_hmm_df <- hmmscan_df %>% 
  filter(seq_evalue < 0.01 & c_evalue < 0.01) %>% 
  group_by(ID) %>%
  # Collapse into list of pfam domains for each protein
  reframe(pfam_domains = paste0(target_name, " (", env_from, "-", env_to,  ")", collapse = ", "), 
          unique_domains = paste(unique(target_name), collapse = ", "))

# # Filter uncertain domains
# uncertain_domains_df <- hmmscan_df %>%
#   filter(seq_evalue >= 0.01 | c_evalue >= 0.01) %>%
#   distinct(ID, target_name, seq_evalue)

# uncertain_domains_df <- uncertain_domains_df %>% 
#   left_join(filtered_hmm_df %>% 
#               select(ID, unique_domains), by = "ID") %>%
#   rowwise() %>%
#   # Remove uncertain domains already in unique_domains
#   filter(!target_name %in% strsplit(unique_domains, ", ")[[1]]) %>%
#   ungroup() %>%
#   arrange(ID, seq_evalue) %>%   # Sort by ID then E-value (ascending)
#   group_by(ID) %>%
#   reframe(`uncertain_domains (E-value)` = paste0(target_name, " (", seq_evalue, ")", collapse = ", "))
# filtered_hmm_df <- filtered_hmm_df %>%
#   full_join(uncertain_domains_df, by = "ID") %>%
#   relocate(`uncertain_domains (E-value)`, .after = last_col())

# Remove old PFAM columns if they already exist
pfam_columns <- c(
  "pfam_domains",
  "unique_domains"
)

protein_table <- protein_table %>%
  select(
    -any_of(pfam_columns)
  )

# Merge PFAM information into protein_table
all_hmm_df <- protein_table %>%
  full_join(filtered_hmm_df, by = "ID") %>%
  relocate(pfam_domains, .after = last_col()) %>%
  relocate(unique_domains, .after = last_col())

# Replace missing PFAM values with empty strings
protein_table <- protein_table %>%
  mutate(
    across(
      any_of(pfam_columns),
      ~ replace_na(.x, "")
    )
  )

# === Write output ===
write_csv(
  protein_table,
  protein_table_file
)
message(
  "Protein annotation table created: ",
  output_file
)
message(
  "  Total proteins: ",
  nrow(protein_table)
)
message(
  "  Proteins with significant PFAM domains: ",
  sum(
    protein_table$pfam_domains != "",
    na.rm = TRUE
  )
)

quit(
  save = "no",
  status = 0
)
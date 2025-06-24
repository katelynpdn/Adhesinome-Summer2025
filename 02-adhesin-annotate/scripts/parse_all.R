#===========Parse hmmscan --domtblout output#===========
library(tidyverse)
library(readr)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2){
  print("Usage: Rscript parse_all.R <hmmscan_domtblout_file> <01_output_file>")
  stop()
}

hmm.names <- c("target_name", "target_accession", "target_length", "query_name", "query_accession", "query_length", "seq_evalue", "seq_score", "seq_bias", "domain_num", "num_target_domains", "c_evalue", "i_evalue", "domain_score", "domain_bias", "hmm_from", "hmm_to", "ali_from", "ali_to", "env_from", "env_to", "accuracy")
hmmscan_df <- read_table(file = args[1], col_names = hmm.names, col_types = "cciccidddiiddddiiiiiid", skip = 3)

# Filter out anything that doesn't satisfy inclusion threshold (seq_evalue < 0.01 and c-evalue < 0.01)
filtered_hmm_df <- hmmscan_df %>% 
  filter(seq_evalue < 0.01 & c_evalue < 0.01) %>% 
  group_by(query_name) %>%
  # Extract protein name
  mutate(query_name = unlist(strsplit(query_name, split="\\|"))[[2]]) %>%
  rename("Protein ID" = query_name) %>%
  # Collapse into list of pfam domains for each protein
  summarise(pfam_domains = paste0(target_name, " (", env_from, "-", env_to,  ")", collapse = ", "))


#===========Parse combined_output from 01===========
part_one_df <- read_csv(file = args[2])
part_one_df$"GPI-anchor" <- as.logical(part_one_df$"GPI-anchor")

# Sort
part_one_df <- part_one_df[order(-part_one_df$"FungalRV Score", 
                                 -part_one_df$"Signal Peptide", 
                                 -part_one_df$"GPI-anchor"), ]

# Table 1: All 3 criteria satisfied (FungalRV, PredGPI, SignalP)
df_all <- part_one_df[part_one_df$"FungalRV Score" > 0.511 
                      & part_one_df$"Signal Peptide" > 0.5 
                      & part_one_df$"GPI-anchor" == TRUE, ]

# Table 2: The rest
df_rest <- part_one_df[!(part_one_df$"FungalRV Score" > 0.511 
                & part_one_df$"Signal Peptide" > 0.5 
                & part_one_df$"GPI-anchor" == TRUE), ]

#===========Combine all===========
# Merge hmmscan table and 01_output table
all_hmm_df <- merge(filtered_hmm_df, df_all[, c("Protein ID", "FungalRV Score")], by = "Protein ID", all.y = TRUE)
# Sort by FungalRV score
all_hmm_df <- all_hmm_df[order(-all_hmm_df$"FungalRV Score"), ]

filtered_hmm_df <- na.omit(filtered_hmm_df)

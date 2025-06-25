#=========== Parse hmmscan --domtblout output ===========
library(tidyverse)
library(readr)
library(cowplot)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2){
  print("Usage: Rscript parse_all.R <hmmscan_domtblout_file> <01_output_file> <freak_output_directory>")
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
  # Collapse into list of pfam domains for each protein
  reframe(pfam_domains = paste0(target_name, " (", env_from, "-", env_to,  ")", collapse = ", "), 
          unique_domains = paste(unique(target_name), collapse = ", ")) %>%
  rename("Protein ID" = query_name)

#=========== Parse final output from 01-three-part-adhesin-test ===========
part_one_df <- read_csv(file = args[2])

# Sort
part_one_df <- part_one_df[order(-part_one_df$"FungalRV Score", 
                                 -part_one_df$"Signal Peptide", 
                                 -part_one_df$"GPI-anchor"), ]

# Table 1: All 3 criteria satisfied (FungalRV, PredGPI, SignalP)
df_all <- part_one_df[part_one_df$"FungalRV Score" > 0.511 
                      & part_one_df$"Signal Peptide" > 0.5 
                      & part_one_df$"GPI-anchor" == TRUE, ]

part_one_df <- part_one_df %>% 
  mutate(isAdhesin = part_one_df$`Protein ID` %in% df_all$"Protein ID")

# Table 2: The rest
df_rest <- part_one_df[!(part_one_df$"FungalRV Score" > 0.511 
                & part_one_df$"Signal Peptide" > 0.5 
                & part_one_df$"GPI-anchor" == TRUE), ]

#=========== Combine hmmscan, 01-three-part-test output ===========
# Merge hmmscan table and 01_output table
all_hmm_df <- merge(filtered_hmm_df, df_all[, c("Protein ID", "FungalRV Score")], by = "Protein ID", all.y = TRUE)
# Sort by FungalRV score
all_hmm_df <- all_hmm_df[order(-all_hmm_df$"FungalRV Score"), ]

#=========== Read Ser/Thr frequencies ===========
# Adapted from Rachel Smoak's R analysis
# (1) Panproteome-wide: Maximum frequency of Ser/Thr, Ser, Thr in 100aa window
ST.freq <- read_tsv(paste0(args[3],"/ST_freq_freak.out"), col_types = "cid")
S.freq <- read_tsv(paste0(args[3],"/S_freq_freak.out"), col_types = "cid")
T.freq <- read_tsv(paste0(args[3],"/T_freq_freak.out"), col_types = "cid")
ST.window <- bind_rows("ST" = ST.freq, "S" = S.freq, "T" = T.freq, .id = "residue") %>% 
  group_by(id, residue) %>% 
  summarize(max = max(freq))
rm(list = c("ST.freq", "S.freq", "T.freq"))

ST.window %>% 
  left_join(select(part_one_df, id = "Protein Name", isAdhesin), by = "id") %>% 
  mutate(residue = factor(residue, levels = c("ST", "S", "T"), labels = c("Ser/Thr", "Ser", "Thr")),
         `Adhesin` = ifelse(isAdhesin, "Yes", "No")) %>% 
  ggplot(aes(x = max)) + geom_histogram(binwidth = 0.02) + 
  xlab("Max frequency of Ser/Thr in 100 amino acid window") + scale_y_continuous(position = "right") +
  facet_grid(`Adhesin` ~ residue, scales = "free_y", labeller = "label_both", switch = "y") +
  theme_cowplot() + panel_border()

# (2) Panproteome-wide: Ser, Thr frequencies over whole protein
ST.protein <- read_tsv(paste0(args[3],"/ST_freq_perProtein"), col_types = cols())
# Extract protein ID, protein name
ST.protein <- ST.protein %>% 
  separate(ID, into = c("tmp", "ID", "Name"), sep = "\\|") %>%
  select(-tmp)

ST.protein %>% 
  left_join(select(part_one_df, `ID` = `Protein ID`, isAdhesin), by = "ID") %>% 
  mutate(`Ser/Thr` = (Ser+Thr)/length, Ser = Ser/length, Thr = Thr/length) %>% 
  pivot_longer(cols = c(`Ser/Thr`, Ser, Thr), names_to = "residue", values_to = "value") %>% 
  mutate(residue = factor(residue, levels = c("Ser/Thr", "Ser", "Thr")),
         `Adhesin` = ifelse(isAdhesin, "Yes", "No")) %>% 
  ggplot(aes(x = value)) + geom_histogram(binwidth = 0.02) + 
  xlab("Frequency of Ser/Thr in the whole protein") + scale_y_continuous(position = "right") +
  facet_grid(`Adhesin` ~ residue, scales = "free_y", labeller = "label_both", switch = "y") +
  theme_cowplot() + panel_border()

# (3) Merge with all_hmm_df
# Combine Maximum and Protein-wide Frequencies
tmp <- ST.protein %>% 
  mutate(ST.prot = round((Ser+Thr)/length, 3)) %>% 
  select(ID, Name, ST.prot) %>% 
  left_join(ST.window %>% filter(residue == "ST") %>% 
  select(Name = id, ST.window.max = max), by = "Name") %>% 
  # for proteins shorter than 100 a.a., the sliding window estimate would be NA. replace it with whole protein estimate in ST.protein
  mutate(ST.window.max = round(coalesce(ST.window.max, ST.prot),3))

# Add Maximum, Protein-wide Frequencies to all_hmm_df
all_hmm_df <- all_hmm_df %>% 
  rename(ID = "Protein ID") %>%
  left_join(tmp, by = "ID") %>%
  relocate(Name, .after = 1)
rm(tmp)
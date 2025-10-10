library(dplyr)
library(tidyr)
library(readr)

quickgo_file = "QuickGO-annotations.tsv"

quickgo_df <- read_table(file = quickgo_file)

quickgo_df_summary <- quickgo_df %>%
  group_by(PRODUCT) %>%
  summarise(PRODUCT_1 = paste(PRODUCT_1, collapse = ", "))
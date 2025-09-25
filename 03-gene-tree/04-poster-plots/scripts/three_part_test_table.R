# Create table of 3-part adhesin test for list of proteomes
# Author: Katelyn Nguyen
# Date: 7/18/2025

library(tidyverse)
library(gt)

uniprotIDs <- c("UP000000559", "UP000230249", "UP000002428", "UP000000598", "UP000002311")
uniprotNames <- c("Candida albicans", "Candida auris", "Candida glabrata", "Kluyveromyces lactis", "Saccharomyces cerevisiae")

numProteomes <- length(uniprotIDs)

# Input and output directory
params <- list(args = "/Volumes/rdss_bhe2/User/Katelyn-Nguyen/Adhesinome_Results/")
args <- strsplit(params$args, " ")[[1]]

# Read in each proteinTable.csv and create dataframe for values & percentages
columns <- c("Proteome", "Total", "FungalRV", "SignalP", "PredGPI", "Two_Tests", "All_Tests")
three_part_test_df = data.frame("Proteome_ID" = character(numProteomes), "Species" = character(numProteomes), 
                                "Total" = numeric(numProteomes), "FungalRV" = numeric(numProteomes), 
                                "SignalP" = numeric(numProteomes), "PredGPI" = numeric(numProteomes), 
                                "Two.Tests" = numeric(numProteomes),"All.Tests" = numeric(numProteomes))
percentages_df = data.frame("Proteome_ID" = character(numProteomes), "Species" = character(numProteomes), 
                                "Total" = numeric(numProteomes), "FungalRV" = numeric(numProteomes), 
                                "SignalP" = numeric(numProteomes), "PredGPI" = numeric(numProteomes), 
                                "Two.Tests" = numeric(numProteomes),"All.Tests" = numeric(numProteomes))

for (i in seq_along(uniprotIDs)) {
  uniprotID <- uniprotIDs[i]
  fullDir = paste0(args[1], uniprotID, "_output")
  three_part_test_file = paste0(fullDir, "/proteinTable.csv")
  
  part_one_df <- read_csv(file = three_part_test_file)
  
  # Apply cutoffs
  part_one_df <- part_one_df %>% rename(ID = `Protein ID`) %>% 
    mutate("FungalRV" = (`FungalRV Score` > 0.511), 
           "SignalP" = (`Signal Peptide` > 0.5),
           "PredGPI" = as.logical(`GPI-anchor`)) %>%
    select("FungalRV", "SignalP", "PredGPI")
  
  # Add failed_tests column to signify which of the 3 tests failed
  part_one_df <- part_one_df %>%
    mutate(
      failed_tests = paste(
        ifelse(`FungalRV` != TRUE, "FungalRV", ""),
        ifelse(`SignalP` != TRUE, "SignalP", ""),
        ifelse(`PredGPI` != TRUE, "PredGPI", ""),
        sep = ", ")
    ) %>%
    mutate(
      failed_tests = gsub(", ,", ",", failed_tests),
      failed_tests = gsub("^, |, , |, $", "", failed_tests)
    )
  
  # Calculate totals]
  numTotal <- nrow(part_one_df)
  numFungalRV <- nrow(subset(part_one_df, FungalRV == TRUE))
  numSignalP <- nrow(subset(part_one_df, SignalP == TRUE))
  numPredGPI <- nrow(subset(part_one_df, PredGPI == TRUE))
  num2Tests <- nrow(subset(part_one_df, sapply(strsplit(failed_tests, split=","), length) == 1))
  num3Tests <- nrow(subset(part_one_df, FungalRV == TRUE & SignalP == TRUE & PredGPI == TRUE))
  
  three_part_test_df[i, ] <- list(uniprotID, uniprotNames[i], numTotal, numFungalRV, numSignalP, 
                               numPredGPI, num2Tests, num3Tests)

  # Add to dataframe along with percentages
  percentages_df[i, ] <- list(uniprotID, uniprotNames[i], numTotal,round(numFungalRV/numTotal*100, 3), 
                           round(numSignalP/numTotal*100, 3), round(numPredGPI/numTotal*100, 3), 
                           round(num2Tests/numTotal*100, 3), round(num3Tests/numTotal*100, 3))

  }
  
three_part_test_df |> 
  gt() |>
  data_color(columns = 4:6,
             fn = scales::col_numeric(
               palette = c("#FFFFFF", "#FFEE8C"),
               domain = c(0, 400) )
  ) |>
  data_color(columns = 7,
             fn = scales::col_numeric(
               palette = c("#FFFFFF", "#FF7F50"),
               domain = c(0, 90) )
  ) |>
  data_color(columns = 8,
             fn = scales::col_numeric(
               palette = c("#FFFFFF", "#FF7F50"),
               domain = c(0, 50) )
  ) |>
  tab_options(column_labels.background.color = "#808080") |>
  opt_table_font(size = 20, weight = 600)

percentages_df |> 
  gt() |>
  data_color(columns = 4:6,
             fn = scales::col_numeric(
               palette = c("#FFFFFF", "#FFEE8C"),
               domain = c(0, 6.1) )
             ) |>
  data_color(columns = 7,
             fn = scales::col_numeric(
               palette = c("#FFFFFF", "#FF7F50"),
               domain = c(0, 1.5) )
             ) |>
  data_color(columns = 8,
             fn = scales::col_numeric(
               palette = c("#FFFFFF", "#FF7F50"),
               domain = c(0, 0.9) )
  ) |>
  tab_options(column_labels.background.color = "#808080") |>
  opt_table_font(size = 20, weight = 600)
             
             
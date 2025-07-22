# Create table of 3-part adhesin test for list of proteomes
# Author: Katelyn Nguyen
# Date: 7/18/2025

uniprotIDs <- c("UP000000559", "UP000230249", "UP000002428", "UP000000598", "UP000002311")
uniprotNames <- c("Calbicans", "Cauris", "Cglabrata", "Klactis", "Scerevisiae")
numProteomes <- length(uniprotIDs)

# Input and output directory
params <- list(args = "/Volumes/rdss_bhe2/User/Katelyn-Nguyen/Adhesinome_Results/")
args <- strsplit(params$args, " ")[[1]]

# Read in each proteinTable.csv and 
columns <- c("Proteome", "Total", "FungalRV", "SignalP", "PredGPI", "Two_Tests", "All_Tests")
three_part_test_df = data.frame("Proteome_ID" = character(numProteomes), "Proteome_Name" = character(numProteomes), 
                                "Total" = numeric(numProteomes), "FungalRV" = numeric(numProteomes), 
                                "SignalP" = numeric(numProteomes), "PredGPI" = numeric(numProteomes), 
                                "Two_Tests" = numeric(numProteomes),"All_Tests" = numeric(numProteomes))
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
  
  # Add to dataframe along with percentages
  three_part_test_df[i, ] <- c(uniprotID, uniprotNames[i], numTotal, 
                               paste0(numFungalRV, " (", round(numFungalRV/numTotal, 3), ")"), 
                               paste0(numSignalP, " (", round(numSignalP/numTotal, 3), ")"),
                               paste0(numPredGPI, " (", round(numPredGPI/numTotal, 3), ")"),
                               paste0(num2Tests, " (", round(num2Tests/numTotal, 3), ")"),
                               paste0(num3Tests, " (", round(num3Tests/numTotal, 3), ")"))
}
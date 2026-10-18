#!/usr/bin/env Rscript

# ============================================================
# curate_datasets.R
#
# Curate the positive set and three negative subsets.
#
# Positive set:
#   - From manualAnnotations.csv
#   - Proteins where is_adhesin_confidence is "Confident" or "Likely"
#
# Negative subset 1: Boundary cases
#   - From manualAnnotations.csv
#   - Proteins where is_adhesin_confidence is "Unlikely"
#
# Negative subset 2:
#   - From combinedProteinTable.csv
#   - Proteins that fail exactly two criteria
#   - Excludes proteins present in manualAnnotations.csv
#
# Negative subset 3:
#   - From combinedProteinTable.csv
#   - Proteins that fail all three criteria
#   - Excludes proteins present in manualAnnotations.csv
#
# Usage:
#   Rscript curate_datasets.R <resultsDirectory>
# ============================================================


# === Check command-line arguments ===

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1) {
  stop(
    paste0(
      "\nUsage:\n",
      "  Rscript 04_complete_curation.R <resultsDirectory>\n\n",
      "Example:\n",
      "  Rscript 04_complete_curation.R results/\n"
    )
  )
}

resultsDirectory <- args[1]


# === Check required inputs ===

if (!dir.exists(resultsDirectory)) {
  stop(
    "ERROR: Results directory does not exist:\n  ",
    resultsDirectory
  )
}

proteinFile <- file.path(
  resultsDirectory,
  "combinedProteinTable.csv"
)

manualFile <- file.path(
  resultsDirectory,
  "manualAnnotations.csv"
)

if (!file.exists(proteinFile)) {
  stop("ERROR: Protein table does not exist:\n  ", proteinFile)
}

if (!file.exists(manualFile)) {
  stop("ERROR: Manual annotations file does not exist:\n  ", manualFile)
}


# === Set up output directory ===

outputDirectory <- file.path(
  resultsDirectory,
  "curatedSets"
)

dir.create(
  outputDirectory,
  recursive = TRUE,
  showWarnings = FALSE
)

positiveFile <- file.path(
  outputDirectory,
  "positive_set.csv"
)

subset1File <- file.path(
  outputDirectory,
  "negative_subset1_boundary_cases.csv"
)

subset2File <- file.path(
  outputDirectory,
  "negative_subset2_fail_two.csv"
)

subset3File <- file.path(
  outputDirectory,
  "negative_subset3_fail_all_three.csv"
)


# === Read input files ===

manual <- read.csv(
  manualFile,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  na.strings = character(),
  strip.white = TRUE
)

proteins <- read.csv(
  proteinFile,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  na.strings = character(),
  strip.white = TRUE
)

# Trim whitespace from column names.
names(manual) <- trimws(names(manual))
names(proteins) <- trimws(names(proteins))


# === Validate required columns ===

requiredManualColumns <- c(
  "ID",
  "is_adhesin_confidence"
)

requiredProteinColumns <- c(
  "ID",
  "failed_tests"
)

missingManualColumns <- setdiff(
  requiredManualColumns,
  names(manual)
)

missingProteinColumns <- setdiff(
  requiredProteinColumns,
  names(proteins)
)

if (length(missingManualColumns) > 0) {
  stop(
    "ERROR: Missing column(s) in manualAnnotations.csv: ",
    paste(missingManualColumns, collapse = ", ")
  )
}

if (length(missingProteinColumns) > 0) {
  stop(
    "ERROR: Missing column(s) in combinedProteinTable.csv: ",
    paste(missingProteinColumns, collapse = ", ")
  )
}


# === Normalize IDs and annotation values ===

manual$ID <- trimws(as.character(manual$ID))
proteins$ID <- trimws(as.character(proteins$ID))

manual$is_adhesin_confidence <- tolower(
  trimws(as.character(manual$is_adhesin_confidence))
)

proteins$failed_tests <- toupper(
  trimws(as.character(proteins$failed_tests))
)

# Store every manually annotated protein ID.
manualIDs <- unique(
  manual$ID[
    !is.na(manual$ID) &
      manual$ID != ""
  ]
)


# === Curate positive set ===

positiveSet <- manual[
  !is.na(manual$is_adhesin_confidence) &
    manual$is_adhesin_confidence %in% c("confident", "likely"),
  ,
  drop = FALSE
]


# === Curate negative subset 1: Boundary cases ===

subset1 <- manual[
  !is.na(manual$is_adhesin_confidence) &
    manual$is_adhesin_confidence == "unlikely",
  ,
  drop = FALSE
]


# === Count failed criteria ===

# Assumes failed_tests contains whitespace-separated criterion names,
# such as "SIGNALP NETGPI PREDGPI".
# Empty values and "NA" indicate zero failed criteria.

countFailedTests <- function(x) {
  vapply(x, function(value) {

    if (
      is.na(value) ||
      value == "" ||
      value == "NA"
    ) {
      return(0L)
    }

    tests <- strsplit(
      trimws(value),
      "[[:space:]]+"
    )[[1]]

    sum(nzchar(tests))

  }, integer(1))
}

failedCount <- countFailedTests(
  proteins$failed_tests
)


# === Exclude manually annotated proteins ===

notManuallyAnnotated <- (
  !is.na(proteins$ID) &
    proteins$ID != "" &
    !(proteins$ID %in% manualIDs)
)


# === Curate negative subset 2: Fail exactly two criteria ===

subset2 <- proteins[
  failedCount == 2 &
    notManuallyAnnotated,
  ,
  drop = FALSE
]


# === Curate negative subset 3: Fail all three criteria ===

subset3 <- proteins[
  failedCount == 3 &
    notManuallyAnnotated,
  ,
  drop = FALSE
]


# === Write output files ===

write.csv(
  positiveSet,
  positiveFile,
  row.names = FALSE,
  na = ""
)

write.csv(
  subset1,
  subset1File,
  row.names = FALSE,
  na = ""
)

write.csv(
  subset2,
  subset2File,
  row.names = FALSE,
  na = ""
)

write.csv(
  subset3,
  subset3File,
  row.names = FALSE,
  na = ""
)


# === Report results ===

cat("\nCurated sets written to:\n")
cat("  Positive set: ", positiveFile, "\n", sep = "")
cat("  Subset 1:     ", subset1File, "\n", sep = "")
cat("  Subset 2:     ", subset2File, "\n", sep = "")
cat("  Subset 3:     ", subset3File, "\n", sep = "")

cat("\nNumber of proteins in each set:\n")
cat("  Positive set (Confident/Likely): ", nrow(positiveSet), "\n", sep = "")
cat("  Subset 1 (Unlikely):             ", nrow(subset1), "\n", sep = "")
cat("  Subset 2 (fail two criteria):    ", nrow(subset2), "\n", sep = "")
cat("  Subset 3 (fail three criteria):  ", nrow(subset3), "\n", sep = "")
#!/usr/bin/env Rscript

# ============================================================
# parse_output.R
#
# Combine:
#   - PredGPI
#   - SignalP
#   - NetGPI
#   - Ser/Thr frequencies
#   - EMBOSS freak
#   - TANGO
#   - XSTREAM
#
# into one proteinTable.csv file.
#
# Usage:
#
# Rscript parse_output.R <outputDirectory> <proteomeFile>
#
# Example:
#
# Rscript parse_output.R \
#     /path/to/results/PROTEOME \
#     /path/to/data/PROTEOME.fasta
#
# ============================================================

# === Load packages ===
suppressPackageStartupMessages({
  library(tidyverse)
})


# === Check command-line arguments ===
args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2) {
  stop(
    paste0(
      "\nUsage:\n",
      "  Rscript parse_output.R <outputDirectory> <proteomeFile>\n\n",
      "Example:\n",
      "  Rscript parse_output.R results/PROTEOME data/PROTEOME.fasta\n"
    )
  )
}

outputDirectory <- args[1]
proteomeFile <- args[2]


# === Check required inputs ===
if (!dir.exists(outputDirectory)) {
  stop(
    "ERROR: Output directory does not exist:\n  ",
    outputDirectory
  )
}

if (!file.exists(proteomeFile)) {
  stop(
    "ERROR: FASTA file does not exist:\n  ",
    proteomeFile
  )
}


# === Define input/output files ===

predgpi_file <- file.path(
  outputDirectory,
  "predgpi_output"
)

signalp_file <- file.path(
  outputDirectory,
  "signalP_output"
)

netgpi_file <- file.path(
  outputDirectory,
  "netgpi_output"
)

ser_thr_output <- file.path(
  outputDirectory,
  "ST_freq_perProtein"
)

freak_output_directory <- file.path(
  outputDirectory,
  "freak-output"
)

tango_output_directory <- file.path(
  outputDirectory,
  "tango-output"
)

xstream_output_directory <- file.path(
  outputDirectory,
  "tandem-repeats"
)

output_file <- file.path(
  outputDirectory,
  "proteinTable.csv"
)


# === Check required tool outputs ===

required_files <- c(
  predgpi_file,
  signalp_file,
  netgpi_file,
  ser_thr_output
)

required_file_names <- c(
  "PredGPI output",
  "SignalP output",
  "NetGPI output",
  "Ser/Thr output"
)

for (i in seq_along(required_files)) {

  if (!file.exists(required_files[i])) {

    stop(
      "ERROR: ",
      required_file_names[i],
      " does not exist:\n  ",
      required_files[i]
    )
  }
}


# === Check directories ===

required_directories <- c(
  freak_output_directory,
  tango_output_directory,
  xstream_output_directory
)

required_directory_names <- c(
  "freak output directory",
  "TANGO output directory",
  "XSTREAM output directory"
)

for (i in seq_along(required_directories)) {

  if (!dir.exists(required_directories[i])) {

    stop(
      "ERROR: ",
      required_directory_names[i],
      " does not exist:\n  ",
      required_directories[i]
    )
  }
}


# === Helper function: extract protein ID ===

extract_protein_id <- function(identifier) {

  identifier <- str_remove(
    identifier,
    "^>"
  )

  parts <- str_split_fixed(
    identifier,
    "\\|",
    3
  )

  if (ncol(parts) >= 3 && parts[1, 2] != "") {
    return(parts[1, 2])
  }

  return(
    str_split(
      identifier,
      "\\s+"
    )[[1]][1]
  )
}


# ===== Helper function: extract protein name =====

extract_protein_name <- function(identifier) {

  identifier <- str_remove(
    identifier,
    "^>"
  )

  parts <- str_split_fixed(
    identifier,
    "\\|",
    3
  )

  if (ncol(parts) >= 3) {

    return(
      str_split(
        parts[1, 3],
        "\\s+"
      )[[1]][1]
    )
  }

  return(
    str_split(
      identifier,
      "\\s+"
    )[[1]][1]
  )
}

# === Read FASTA ===
message("Reading FASTA...")

fasta_headers <- read_lines(proteomeFile) %>%
  str_subset("^>")

if (length(fasta_headers) == 0) {
  stop(
    "ERROR: No FASTA headers found in:\n  ",
    proteomeFile
  )
}

all_hmm_df <- tibble(
  identifier = str_remove(
    fasta_headers,
    "^>"
  )
) %>%
  mutate(
    ID = map_chr(
      identifier,
      extract_protein_id
    ),

    Name = map_chr(
      identifier,
      extract_protein_name
    )
  ) %>%
  select(
    ID,
    Name
  ) %>%
  distinct(ID, .keep_all = TRUE)

message(
  "  Found ",
  nrow(all_hmm_df),
  " proteins."
)

# === PredGPI === 

message("Reading PredGPI...")

predgpi_df <- read_tsv(
  predgpi_file,
  col_names = FALSE,
  show_col_types = FALSE
)

if (ncol(predgpi_df) < 3) {

  stop(
    "ERROR: PredGPI output has fewer than 3 columns:\n  ",
    predgpi_file
  )
}

GPIproteins <- predgpi_df %>%
  mutate(
    ID = map_chr(
      X1,
      extract_protein_id
    )
  ) %>%
  filter(
    X3 == "GPI-anchor"
  ) %>%
  distinct(ID) %>%
  mutate(
    `GPI-anchor` = TRUE
  )

all_hmm_df <- all_hmm_df %>%
  left_join(
    GPIproteins,
    by = "ID"
  ) %>%
  mutate(
    `GPI-anchor` =
      replace_na(
        `GPI-anchor`,
        FALSE
      )
  )


# === SignalP ===

message("Reading SignalP...")

signalP_df <- read_tsv(
  signalp_file,
  comment = "#",
  col_names = FALSE,
  show_col_types = FALSE
)

if (ncol(signalP_df) < 4) {

  stop(
    "ERROR: SignalP output has fewer than 4 columns:\n  ",
    signalp_file
  )
}

signalP_df <- signalP_df %>%
  mutate(
    ID = map_chr(
      X1,
      extract_protein_id
    )
  ) %>%
  select(
    ID,
    `Signal Peptide` = X4
  ) %>%
  distinct(
    ID,
    .keep_all = TRUE
  )

all_hmm_df <- all_hmm_df %>%
  left_join(
    signalP_df,
    by = "ID"
  )


#  === NetGPI ===

message("Reading NetGPI...")

netGPI_df <- read_tsv(
  netgpi_file,
  show_col_types = FALSE
)

if (!all(
  c("id", "likelihood") %in%
    names(netGPI_df)
)) {

  stop(
    "ERROR: NetGPI output must contain columns named ",
    "'id' and 'likelihood'.\nFile:\n  ",
    netgpi_file
  )
}

netGPI_df <- netGPI_df %>%
  select(
    ID = id,
    `NetGPI Likelihood` = likelihood
  ) %>%
  distinct(
    ID,
    .keep_all = TRUE
  )

all_hmm_df <- all_hmm_df %>%
  left_join(
    netGPI_df,
    by = "ID"
  )


# === Ser/Thr frequencies over whole protein ===

message("Reading Ser/Thr frequencies...")

ST.protein <- read_tsv(ser_thr_output, col_types = cols())

# Extract protein ID
# Extract protein ID
ST.protein <- ST.protein %>%
  mutate(
    ID = map_chr(
      ID,
      extract_protein_id
    )
  ) %>%
  mutate(
    `S/T Frequency` =
      (Ser + Thr) / length,

    `Ser Frequency` =
      Ser / length,

    `Thr Frequency` =
      Thr / length
  ) %>%
  select(
    ID,
    `S/T Frequency`,
    `Ser Frequency`,
    `Thr Frequency`
  ) %>%
  distinct(
    ID,
    .keep_all = TRUE
  )

all_hmm_df <- all_hmm_df %>%
  left_join(
    ST.protein,
    by = "ID"
  )


# === Maximum Ser/Thr frequency in 100-aa windows ===

message("Reading Ser/Thr sliding-window frequencies...")

ST_file <- file.path(
  freak_output_directory,
  "ST_freq_freak.out"
)

S_file <- file.path(
  freak_output_directory,
  "S_freq_freak.out"
)

T_file <- file.path(
  freak_output_directory,
  "T_freq_freak.out"
)

freak_files <- c(
  ST_file,
  S_file,
  T_file
)

for (file in freak_files) {

  if (!file.exists(file)) {

    stop(
      "ERROR: Required freak output does not exist:\n  ",
      file
    )
  }
}


ST.freq <- read_tsv(
  ST_file,
  col_types = "cid"
)

S.freq <- read_tsv(
  S_file,
  col_types = "cid"
)

T.freq <- read_tsv(
  T_file,
  col_types = "cid"
)


ST.window <- bind_rows(
  "ST" = ST.freq,
  "S" = S.freq,
  "T" = T.freq,
  .id = "residue"
) %>%
  group_by(
    id,
    residue
  ) %>%
  summarize(
    max = max(
      freq,
      na.rm = TRUE
    ),
    .groups = "drop"
  )


# Keep only maximum Ser/Thr frequency

ST.window.final <- ST.window %>%
  filter(
    residue == "ST"
  ) %>%
  transmute(
    ID = id,
    `Max window S/T frequency` = max
  )

all_hmm_df <- all_hmm_df %>%
  left_join(
    ST.window.final,
    by = "ID"
  )


## === Read TANGO output: average beta-aggregation per residue ===
Average B-Aggregation per residue
message("Reading TANGO average aggregation...")

tango_per_sequence <- file.path(
  tango_output_directory,
  "perSequence_aggregation.txt"
)

if (!file.exists(tango_per_sequence)) {

  stop(
    "ERROR: TANGO perSequence_aggregation.txt does not exist:\n  ",
    tango_per_sequence
  )
}

tango_df <- read_tsv(
  tango_per_sequence,
  col_types = cols()
)

if (!all(
  c("Sequence", "Aggregation") %in%
    names(tango_df)
)) {

  stop(
    "ERROR: TANGO perSequence_aggregation.txt must contain ",
    "'Sequence' and 'Aggregation' columns."
  )
}


tango_df <- tango_df %>%
  mutate(
    ID = map_chr(
      Sequence,
      extract_protein_id
    )
  ) %>%
  select(
    ID,
    `Average B-aggregation per residue` =
      Aggregation
  ) %>%
  distinct(
    ID,
    .keep_all = TRUE
  )

all_hmm_df <- all_hmm_df %>%
  left_join(
    tango_df,
    by = "ID"
  )

# Using Bin's tango extraction functions
extract_tango <- function(tango_output, agg_threshold = 5, required_in_serial = 5) {
    tmp <- read_tsv(file = tango_output, col_types = "icddddd") %>%
        # a boolean vector for residues above threshold
        mutate(pass = Aggregation > agg_threshold)
    pass.rle <- rle(tmp$pass) # this creates a run length encoding that will be useful for identifying the sub-sequences in a run longer than certain length
    # --- Explanation ---
    # this rle object is at the core of this function
    # an example of the rle looks like
    #   lengths: int[1:10] 5 19 20 8 1 5 19 6 181 18
    #   values: logi[1:10] F T  F  T F T F  T F   T
    #   note that by definition the values will always be T/F interdigited
    # our goal is to identify the sub-sequences that is defined as a stretch of
    # n consecutive positions with a score greater than the cutoff and record the
    # sub-sequence, its length, start and end position, 90% quantile of the score
    # --- End of explanation ---
    # 1. assigns a unique id for each run of events
    tmp$group <- rep(1:length(pass.rle$lengths), times = pass.rle$lengths)
    # # 2. extract the subsequences
    agg.seq <- tmp %>%
        dplyr::filter(pass) %>% # drop residues not predicted to have aggregation potential
        group_by(group) %>% # cluster by the runs
        summarise(seq = paste0(aa, collapse = ""),
                  start = min(res), end = max(res), length = n(),
                  median = median(Aggregation),
                  q90 = quantile(Aggregation, probs = 0.9),
                  ivt = sum(aa %in% c("I","V","T")) / length(aa),
                  .groups = "drop") %>%
        mutate(interval = start - dplyr::lag(end) - 1) %>%
        dplyr::filter(length >= required_in_serial) %>%
        select(-group)
    return(agg.seq)
}

# === Apply TANGO extraction to individual proteins ===

message("Extracting TANGO aggregation sequences...")

tango.output.files <- list.files(path = tango_output_directory, pattern = ".+\\|.*\\.txt(\\.gz)?$", full.names = TRUE)

if (length(tango.output.files) == 0) {

  warning(
    "No individual TANGO output files found in:\n  ",
    tango_output_directory
  )

  tango.res.df <- tibble()

} else {
    # the read_csv() function used in the custom function can automatically decompress gzipped files
    tango.res <- lapply(tango.output.files, extract_tango)
    names(tango.res) <- gsub(".txt|.txt.gz", "", basename(tango.output.files))
    # to add species information
    # seqInfo <- read_tsv("raw-output/XP_028889033_homologs.tsv", comment = "#", col_types = c("ccci"))
    tango.res.df <- bind_rows(tango.res, .id = "id")
    
    tango.res.df <- tango.res.df %>%
    mutate(
        ID = map_chr(
        id,
        extract_protein_id
        )
    )
}


tango.summary <- tango.res.df %>%
    select(
      ID,
      seq
    ) %>%
    group_by(ID) %>%
    summarize(
      `B-agg seq count` =
        n(),

      `B-agg sequences` =
        paste(
          sort(seq),
          collapse = ", "
        ),
      .groups = "drop"
    )

all_hmm_df <- all_hmm_df %>%
    left_join(
        tango.summary,
        by = "ID"
    )
    
all_hmm_df <- all_hmm_df %>%
  mutate(
    `B-agg seq count` =
      replace_na(
        `B-agg seq count`,
        0
      )
  )

# === Read XSTREAM output ===
message("Reading XSTREAM output...")

xstream_file <- file.path(
  xstream_output_directory,
  "XSTREAM_proteins_i0.7_g3_m5_L15_chart.xls"
)

if (!file.exists(xstream_file)) {

  stop(
    "ERROR: XSTREAM output does not exist:\n  ",
    xstream_file
  )
}

repeats_df <- read_tsv(
  xstream_file,
  col_types = cols()
)

repeats_df <- repeats_df %>%
  mutate(
    ID = map_chr(
      identifier,
      extract_protein_id
    )
  )

# Calculate per sequence repeat percentage and add to all_hmm_df
tmp <- repeats_df %>% 
  mutate(len = end - start + 1) %>% 
  group_by(ID) %>% 
  summarize(perc = round(sum(len/`seq length`),3)) %>% 
  rename("TR Percentage" = perc)

all_hmm_df <- all_hmm_df %>%
  left_join(
    tmp,
    by = "ID"
  ) %>%
  mutate(
    `TR Percentage` =
      replace_na(
        `TR Percentage`,
        0
      )
  )


# === Write output ===
write_csv(
  all_hmm_df,
  output_file
)
message(
  "Protein annotation table created: ",
  output_file
)

quit(
  save = "no",
  status = 0
)
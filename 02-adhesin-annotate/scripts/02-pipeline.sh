#!/bin/bash
# title: Given proteome and results from 01-three-part-adhesin-test, generate table of annotations
# author: Katelyn Nguyen
# date: 2025-06-27

set -e

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <inputFile.fasta> <directory_with_Pfam> <01_resultsFile> <outputName>"
    exit 1
fi

proteomeFile=$(readlink -f "$1")
if [[ -z "$proteomeFile" || ! -e "$proteomeFile" ]]; then
    echo "Error: Invalid or non-existent proteome file: $1"
    exit 1
fi
pfamDirectory=$(readlink -f "$2")
if [[ -z "$pfamDirectory" || ! -d "$pfamDirectory" ]]; then
    echo "Error: Invalid or non-existent Pfam directory: $2"
    exit 1
fi
part1File=$(readlink -f "$3")
if [[ -z "$part1File" || ! -e "$part1File" ]]; then
    echo "Error: Invalid or non-existent Part 1 file: $3"
    exit 1
fi

outputDirectory="../results/$4"
mkdir -p "$outputDirectory"

# HMMSCAN on Pfam
# If hmmscan_domtblout already exists in outputDirectory, ask user if they want to continue
hmmContinue="y"
if [ -f "$outputDirectory/hmmscan_domtblout" ]; then
    read -p "$outputDirectory/hmmscan_domtblout exists from a previous run. Run HMMSCAN anyways? (y/n) " hmmContinue
fi
if [[ $hmmContinue == "y" || $hmmContinue == "Y" || $hmmContinue == "yes" || $hmmContinue == "Yes" ]]; then
    echo "-------------Running HMMSCAN on Pfam-------------"
    hmmscan --domtblout  "$outputDirectory/hmmscan_domtblout" "$pfamDirectory/Pfam-A.hmm" "$proteomeFile"
else
    echo "Skipping HMMSCAN step, continuing..."
fi

# EMBOSS freak
# If freak-output already exists in outputDirectory, ask user if they want to continue
freakContinue="y"
if [ -d "$outputDirectory/freak-output" ]; then
    read -p "$outputDirectory/freak-output exists from a previous run. Run freak anyways? (y/n) " freakContinue
fi
if [[ $freakContinue == "y" || $freakContinue == "Y" || $freakContinue == "yes" || $freakContinue == "Yes" ]]; then
    echo "-------------Running EMBOSS freak-------------"
    ./run_freak.sh "$proteomeFile" "$outputDirectory/freak-output"
else
    echo "Skipping freak step, continuing..."
fi

# Ser/Thr frequencies
# If ST_freq_perProtein already exists in outputDirectory, ask user if they want to continue
stContinue="y"
if [ -f "$outputDirectory/ST_freq_perProtein" ]; then
    read -p "$outputDirectory/ST_freq_perProtein exists from a previous run. Calculate Ser/Thr frequencies anyways? (y/n) " stContinue
fi
if [[ $stContinue == "y" || $stContinue == "Y" || $stContinue == "yes" || $stContinue == "Yes" ]]; then
    echo "-------------Calculating Ser/Thr frequencies-------------"
    python calc_aafreq_gz.py "$proteomeFile" > "$outputDirectory/ST_freq_perProtein"
else
    echo "Skipping Ser/Thr per protein step, continuing..."
fi

# TANGO
# If tango-output already exists in outputDirectory, ask user if they want to continue
tangoContinue="y"
if [ -d "$outputDirectory/tango-output" ]; then
    read -p "$outputDirectory/tango-output exists from a previous run. Run TANGO anyways? (y/n) " tangoContinue
fi
if [[ $tangoContinue == "y" || $tangoContinue == "Y" || $tangoContinue == "yes" || $tangoContinue == "Yes" ]]; then
    echo "-------------Running TANGO-------------"
    ./runTango.sh "$proteomeFile" "$outputDirectory/tango-output"
else
    echo "Skipping TANGO step, continuing..."
fi

# XSTREAM
# If tandem-repeats already exists in outputDirectory, ask user if they want to continue
xstreamContinue="y"
if [ -d "$outputDirectory/tandem-repeats" ]; then
    read -p "$outputDirectory/tandem-repeats exists from a previous run. Run XSTREAM anyways? (y/n) " xstreamContinue
fi
if [[ $xstreamContinue == "y" || $xstreamContinue == "Y" || $xstreamContinue == "yes" || $xstreamContinue == "Yes" ]]; then
   echo "-------------Running XSTREAM-------------"
    ./xstream.sh "$proteomeFile" proteins "$outputDirectory/tandem-repeats"
else
    echo "Skipping XSTREAM step, continuing..."
fi


echo "All results saved to $outputDirectory"

echo "-------------Running R Analysis-------------"
Rscript -e "rmarkdown::render('parse_all.Rmd', params = list(args = '$outputDirectory $part1File'))"
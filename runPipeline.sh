#!/bin/bash
# title: Run Entire Pipeline: Part 1 (FungalRV, SignalP, PredGPI) and Part 2 (Annotation) on given list of reference proteomes
#       Each proteome is searched for and downloaded at reference_proteomes/Eukaryota
# author: Katelyn Nguyen
# date: 2025-07-08

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <inputFile.fasta> <directoryWithPfam>"
    exit 1
fi

inputFile=$1
pfamDir=$2

proteomeList=()
while read -r line; do
    proteomeList+=("$line")
done < "$inputFile"

# Save base directory
baseDir="$(cd "$(dirname "$0")" && pwd)"
dataDir="$baseDir/01-three-part-adhesin-test/data"

# Run pipeline on each proteome
for proteome in "${proteomeList[@]}"
do
    outDir="${proteome}_output"
    outDir_path="$baseDir/01-three-part-adhesin-test/results/$outDir"
    
    # Download proteome
    cd "$dataDir"
    UP_URL="https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/$proteome/"
    # Get the list of files in that directory
    files=$(curl -s "$UP_URL")
    # Extract the .fasta.gz file (not DNA or additional)
    proteomeFile=$(echo "$files" | grep -oP 'href="\K[^"]+\.fasta\.gz' | grep -v DNA | grep -v additional | head -n 1)
    # Check if we found a matching file
    if [ -z "$proteomeFile" ]; then
        echo "No .fasta.gz file found for $proteome at ${UP_URL}"
        exit 1
    fi
    # Download, Unzip the file if file doesn't already exist
    if [ ! -f "${proteomeFile%.gz}" ]; then
        wget "${UP_URL}${proteomeFile}"
        gunzip "${proteomeFile}"
        proteomeFile="${proteomeFile%.gz}"
    else
        proteomeFile="${proteomeFile%.gz}"
        echo "${proteomeFile} already exists"
    fi

    # Part 01
    # If proteinTable.csv already exists in outputDirectory, ask user if they want to still run Part 01
    part1Continue="y"
    if [ -f "$outDir_path/proteinTable.csv" ]; then
        read -p "proteinTable.csv exists from a previous run. Run PART 01 anyways? (y/n) " part1Continue
    fi
    if [[ $part1Continue == "y" || $part1Continue == "Y" || $part1Continue == "yes" || $part1Continue == "Yes" ]]; then
        cd ../
        ./adhesinPipeline.sh "data/${proteomeFile}" "$outDir"
        echo "Proteome $proteome Part 01 complete, check 01-three-part-adhesin-test/results."
    else
        echo "Skipping PART 01, continuing to PART 02..."
    fi

    # Part 02 - Run on seqList_other.fasta (sequences satisfying at least 1 condition)
    # Copy seqlist_other.fasta (from part 01 results) to part 02, check if it exists
    if [ ! -f "$outDir_path/seqList_other.fasta" ]; then
        echo "Error: seqList_other.fasta not found for $proteome"
        exit 1
    fi
    mkdir -p "$baseDir/02-adhesin-annotate/data"
    cp "$outDir_path/seqList_other.fasta" "$baseDir/02-adhesin-annotate/data/"
    
    cd "$baseDir/02-adhesin-annotate/scripts"
    ./02-pipeline.sh "../data/seqList_other.fasta" "$2" "$outDir_path/proteinTable.csv" "$outDir"
    echo "Proteome $proteome Part 02 complete, check 02-adhesin-annotate/results."
done
cd "$baseDir"
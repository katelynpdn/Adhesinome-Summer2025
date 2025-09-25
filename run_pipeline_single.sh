#!/bin/bash
# title: Run Entire Pipeline: Part 1 (FungalRV, SignalP, PredGPI) and Part 2 (Annotation) on *One FASTA File* of protein sequences
# author: Katelyn Nguyen
# date: 2025-09-25

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <inputFile.fasta> <directoryWithPfam>"
    exit 1
fi

proteomeFile=$(readlink -f "$1")
proteomeFile_no_extension="${proteomeFile%.*}"
proteome="$(basename ${proteomeFile_no_extension})"
pfamDir=$2

# Save base directory
baseDir="$(cd "$(dirname "$0")" && pwd)"

# Run pipeline on file
outDir="${proteome}_output"
outDir_01_path="$baseDir/01-three-part-adhesin-test/results/$outDir"
outDir_02_path="$baseDir/02-adhesin-annotate/results/$outDir"

# Part 01
# If proteinTable.csv already exists in outputDirectory, ask user if they want to still run Part 01
part1Continue="y"
if [ -f "$outDir_01_path/proteinTable.csv" ]; then
    read -p "proteinTable.csv exists from a previous run. Run PART 01 anyways? (y/n) " part1Continue
fi
if [[ $part1Continue == "y" || $part1Continue == "Y" || $part1Continue == "yes" || $part1Continue == "Yes" ]]; then
    cd ./01-three-part-adhesin-test
    ./adhesinPipeline.sh "${proteomeFile}" "$outDir"
    echo "File $proteome Part 01 complete, check 01-three-part-adhesin-test/results."
else
    echo "Skipping PART 01, continuing to PART 02..."
fi

# Part 02 - Run on all protein sequences
cd "$baseDir/02-adhesin-annotate/scripts"
# Copy proteinTable.csv into Part 02 results
cp "$outDir_01_path/proteinTable.csv" "$outDir_02_path/"
./02-pipeline.sh "${proteomeFile}" "$2" "$outDir_02_path/proteinTable.csv" "$outDir"
echo "File $proteome Part 02 complete, check 02-adhesin-annotate/results."

cd "$baseDir"
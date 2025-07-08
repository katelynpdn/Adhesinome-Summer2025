#!/bin/bash
# title: Run Entire Pipeline: Part 1 (FungalRV, SignalP, PredGPI) and Part 2 (Annotation) on given list of panproteomes
# author: Katelyn Nguyen
# date: 2025-07-08

set -e

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <inputFile.fasta> <directoryWithPfam> <outputDirectory>"
    exit 1
fi

inputFile=$1
pfamDir=$2
outDir=$3

proteomeList=()
while read -r line; do
    proteomeList+=("$line")
done < "$inputFile"

# Save directory of script
baseDir="$(cd "$(dirname "$0")" && pwd)"
for proteome in "${proteomeList[@]}"
do
    # Download proteome
    cd "$baseDir/data"
    wget "https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/pan_proteomes/$proteome"
    gunzip "$proteome"

    # Run part 01
    cd ../01-three-part-adhesin-test
    ./adhesinPipeline.sh "${baseDir}/data/${proteome}.fasta" "$outDir"
    echo "Proteome $proteome Part 01 complete, check 01-three-part-adhesin-test/results."

    # Run part 02 on seqList_other.fasta (sequences satisfying at least 1 condition)
    if [ ! -f results/seqList_other.fasta ]; then
        echo "Error: seqList_other.fasta not found for $proteome"
        exit 1
    fi
    cp results/seqList_other.fasta ../02-adhesin-annotate/data
    cd ../02-adhesin-annotate/scripts
    ./02-pipeline.sh "../data/seqList_other.fasta" "$2" "../01-three-part-adhesin-test/results/$outDir" "$outDir"
    echo "Proteome $proteome Part 02 complete, check 02-adhesin-annotate/results."
done
cd "$baseDir"
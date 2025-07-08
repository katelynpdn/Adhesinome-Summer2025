#!/bin/bash
# title: Run Entire Pipeline: Part 1 (FungalRV, SignalP, PredGPI) and Part 2 (Annotation) on given list of panproteomes
# author: Katelyn Nguyen
# date: 2025-06-23

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
done < $inputFile

for proteome in $proteomeList
do
    cd data
    wget "https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/pan_proteomes/$proteome"
    gunzip "$proteome"

    cd ../01-three-part-adhesin-test
    ./adhesinPipeline.sh "${proteome}.fasta" "$outDir"
    echo "Proteome $proteome Part 01 complete, check 01-three-part-adhesin-test/results."

    cd ../02-adhesin-annotate/scripts
    ./02-pipeline.sh "${proteome}.fasta" "$2" "../01-three-part-adhesin-test/results/$outDir" "$outDir"
    echo "Proteome $proteome Part 02 complete, check 02-three-part-adhesin-test/results."
done
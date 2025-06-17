#!/bin/bash
# title: Run SignalP predictor on a FASTA file
# author: Katelyn Nguyen
# date: 2025-06-12
set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <file.fasta>"
    exit 1
fi

inputFile=$1

# Split FASTA file into smaller files
python splitFasta.py "$inputFile"

if ! test -f "output/output.json"; then
    mkdir output
    touch output/output.json
fi

# Run SignalP on each FASTA file
for infile in *_group_*.fasta
do
	echo "Processing $infile"
	biolib run DTU/SignalP-6 --fastafile "$infile" --output_dir output/ --organism euk --format "none"
done

# Remove each FASTA file after it is processed
for infile in *_group_*.fasta
do
    rm -f "$infile"
done

# Merge results into one file
echo "Merging results"
cat biolib_results/prediction_results.txt* > biolib_results/merged_prediction_results.txt
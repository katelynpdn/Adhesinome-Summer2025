#!/bin/bash
# title: Run Tango on each sequence in given FASTA file
# author: Katelyn Nguyen
# date: 2025-06-25
set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <file.fasta>"
    exit 1
fi

inputFile=$1
if [ ! -f "$inputFile" ]; then
    echo "Error: File '$inputFile' not found."
    exit 1
fi

# Prepare input file
python prepareTango.py $inputFile > perSequence.txt

# Run Tango (y: Yes to prediction per residue)
echo -e "y\nperSequence.txt" | ./tango2_3_1 > command_line_output.txt
rm perSequence.txt

mkdir -p ../results/TANGO
mv tr\|*.txt perSequence_aggregation.txt command_line_output.txt ../results/TANGO/

echo "Done! Tango output files in results/TANGO"
#!/bin/bash
# title: Run Tango on each sequence in given FASTA file
# output files: perSequence_aggregation.txt: Average aggregation per residue for every sequence in file
#               tr|*.txt: Per residue aggregration, one file per sequence
#               command_line_output.txt: TANGO command line output
# author: Katelyn Nguyen
# date: 2025-06-25
set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <file.fasta> <outputDirectory>"
    exit 1
fi

inputFile=$1
outputDirectory=$2

if [ ! -f "$inputFile" ]; then
    echo "Error: File '$inputFile' not found."
    exit 1
fi

mkdir -p "$outputDirectory"

# Prepare input file
python prepareTango.py $inputFile > "$outputDirectory/perSequence.txt"

# Copy Tango over to output directory (because script creates files in current directory)
cp tango2_3_1 "$outputDirectory"
cd "$outputDirectory"
# Run Tango (y: Yes to prediction per residue)
echo -e "y\nperSequence.txt" | ./tango2_3_1
rm perSequence.txt
rm tango2_3_1
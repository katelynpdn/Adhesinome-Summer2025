#!/bin/bash
# title: Run EMBOSS freak on a FASTA file to get Ser/Thr, Ser, and Thr frequencies, with 50aa window and step of 10
# author: Katelyn Nguyen
# date: 2025-06-25
set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <file.fasta> <outputName>"
    exit 1
fi

inputFile=$1
outputDirectory=$2
windowSize=50

mkdir -p "../results/$outputDirectory"

# Ser/Thr
freak -filter -letters "ST" -window $windowSize -step 10 $inputFile > ../results/$outputDirectory/ST_freq.freak
python format_freak_output.py ../results/$outputDirectory/ST_freq.freak
# Ser
freak -filter -letters "S" -window $windowSize -step 10 $inputFile > ../results/$outputDirectory/S_freq.freak
python format_freak_output.py ../results/$outputDirectory/S_freq.freak
# Thr
freak -filter -letters "T" -window $windowSize -step 10 $inputFile > ../results/$outputDirectory/T_freq.freak
python format_freak_output.py ../results/$outputDirectory/T_freq.freak

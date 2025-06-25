#!/bin/bash
# title: Run Tango on each sequence in given FASTA file
# author: Katelyn Nguyen
# date: 2025-06-25
set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <file.fasta> <outputName>"
    exit 1
fi

inputFile=$1

python prepareTango.py inputFile < ./tango2_3_1 tf="0" stab="-10" conc="1"
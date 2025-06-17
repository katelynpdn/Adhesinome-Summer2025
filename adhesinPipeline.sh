#!/bin/bash
# title: Given proteome, get data from FungalRV, SignalP, PredGPI
# author: Katelyn Nguyen
# date: 2025-06-16

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <inputFile.fasta> <outputFile>"
    exit 1
fi

proteomeFile=$(readlink -f "$1")
proteomeFile_noX="${proteomeFile}_noX.fasta"
outputFile=$2

mkdir -p results
cd scripts

# FungalRV
python fastaRemoveX.py "$proteomeFile" "$proteomeFile_noX"
cd ../FungalRV_adhesin_predictor
echo "Running FungalRV"
perl run_fungalrv_adhesin_predictor.pl "$proteomeFile_noX" ../results/fungalrv_output y
rm "$proteomeFile_noX"

# PredGPI
cd ../predgpi
export PREDGPI_HOME=$(pwd)
echo "Running PredGPI"
python predgpi.py -f "$proteomeFile" -m gff3 -o ../results/predgpi_output

# SignalP
cd ../scripts
echo "Running SignalP"
./runSignalP.sh "$proteomeFile"
mv biolib_results/merged_prediction_results.txt ../results/signalP_output

# Combine results
echo "Combining results"
cd ../results
# Remove first 4 lines of fungalrv_output
tail -n +4 fungalrv_output > tmpfile && mv tmpfile fungalrv_output
# Remove all lines starting with "#" from signalP_output
grep -v '^#' signalP_output > tmpfile && mv tmpfile signalP_output
# Parse all output
python ../scripts/parse_all_output.py fungalrv_output predgpi_output signalP_output "$outputFile"
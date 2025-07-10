#!/bin/bash
# title: Given proteome, get data from FungalRV, SignalP, PredGPI
# author: Katelyn Nguyen
# date: 2025-06-16

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <inputFile.fasta> <outputName>"
    exit 1
fi

proteomeFile=$(readlink -f "$1")
proteomeFile_clean="${proteomeFile}_clean.fasta"
outputDirectory=$2

mkdir -p "results/$outputDirectory"
cd scripts
python fastaRemoveAmbiguity.py "$proteomeFile" "$proteomeFile_clean"  # Remove ambiguities from FASTA file for FUNGALRV

# Copy proteomeFile_clean to 01-three-part-adhesin-test/data if not already there
#   This is because run_fungalrv_adhesin_predictor.pl doesn't accept long pathnames, so we want to pass a relative path
mkdir -p "data"
copyProteomeFile="$(basename "$proteomeFile_clean")"
if [ ! -f "data/$copyProteomeFile" ]; then
    cp "$proteomeFile_clean" "data/$copyProteomeFile"
fi

# FungalRV
cd ../FungalRV_adhesin_predictor
# If fungalrv_output already exists in outputDirectory, ask user if they want to continue
if [ -f "../results/$outputDirectory/fungalrv_output" ]; then
    read -p "results/$outputDirectory/fungalrv_output exists from a previous run. Run FungalRV anyways? (y/n) " fungalContinue
else
    fungalContinue="y"
fi
if [[ $fungalContinue == "y" || $fungalContinue == "Y" || $fungalContinue == "yes" || $fungalContinue == "Yes" ]]; then
    echo "-------------Running FungalRV-------------"
    perl run_fungalrv_adhesin_predictor.pl "../data/$copyProteomeFile" "../results/$outputDirectory/fungalrv_output" y
else
    echo "Skipping FungalRV step, continuing..."
fi

# PredGPI
cd ../predgpi
# If predgpi_output already exists in outputDirectory, ask user if they want to continue
if [ -f "../results/$outputDirectory/predgpi_output" ]; then
    read -p "results/$outputDirectory/predgpi_output exists from a previous run. Run PredGPI anyways? (y/n) " GPIContinue
else
    GPIContinue="y"
fi
if [[ $GPIContinue == "y" || $GPIContinue == "Y" || $GPIContinue == "yes" || $GPIContinue == "Yes" ]]; then
    export PREDGPI_HOME=$(pwd)
    echo "-------------Running PredGPI-------------"
    python predgpi.py -f "$proteomeFile" -m gff3 -o "../results/$outputDirectory/predgpi_output"
else
    echo "Skipping PredGPI step, continuing..."
fi

# SignalP
cd ../scripts
# If signalP_output already exists in outputDirectory, ask user if they want to continue
if [ -f "../results/$outputDirectory/signalP_output" ]; then
    read -p "results/$outputDirectory/signalP_output exists from a previous run. Run SignalP anyways? (y/n) " spContinue
else
    spContinue="y"
fi
if [[ $spContinue == "y" || $spContinue == "Y" || $spContinue == "yes" || $spContinue == "Yes" ]]; then
    echo "-------------Running SignalP-------------"
    ./runSignalP.sh "$proteomeFile"
    mv biolib_results/merged_prediction_results.txt "../results/$outputDirectory/signalP_output"
else
    echo "Skipping SignalP step, continuing..."
fi

# Combine results
echo "-------------Combining results-------------"
cd "../results/$outputDirectory"
# Remove first 4 lines of fungalrv_output
tail -n +4 fungalrv_output > fungalrv_processed
# Remove all lines starting with "#" from signalP_output
grep -v '^#' signalP_output > signalP_processed
# Combine all output into table
python ../../scripts/parse_all_output.py fungalrv_processed predgpi_output signalP_processed proteinTable
# Extract sequences satisfying all 3 conditions and satisfying at least 1 condition into seqList_all and seqList_other
python ../../scripts/extractSeq.py proteinTable.csv "$proteomeFile" .

echo "Results saved to results/$outputDirectory"
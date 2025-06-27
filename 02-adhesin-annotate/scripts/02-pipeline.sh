#!/bin/bash
# title: Given proteome and results from 01-three-part-adhesin-test, generate table of annotations
# author: Katelyn Nguyen
# date: 2025-06-27

set -e

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <inputFile.fasta> <01_resultsFile> <outputName>"
    exit 1
fi

proteomeFile=$(readlink -f "$1")
part1File=$(readlink -f "$2")
outputDirectory="../results/$3"

mkdir -p "$outputDirectory"

echo "-------------Running HMMSCAN on Pfam-------------"
hmmscan --domtblout  "$outputDirectory/hmmscan_domtblout" Pfam-A.hmm "$proteomeFile"

echo "-------------Running EMBOSS freak-------------"
./run_freak.sh "$proteomeFile" "$outputDirectory/freak-output"

echo "-------------Calculating Ser/Thr frequencies-------------"
python calc_aafreq_gz.py "$proteomeFile" > "$outputDirectory/ST_freq_perProtein"

echo "-------------Running TANGO-------------"
./runTango.sh "$proteomeFile" "$outputDirectory/tango-output"

echo "-------------Running XSTREAM-------------"
./xstream.sh "$proteomeFile" proteins "$outputDirectory/tandem-repeats"

echo "All results saved to $outputDirectory"

echo "-------------Running R Analysis-------------"
Rscript -e "rmarkdown::render('parse_all.Rmd', params = list(args = '$outputDirectory $part1File'))"
#!/bin/bash
# title: run FungalRV predictor on protein sequences
# author: Bin He
# date: 2020-02-28

# this assumes that you have downloaded and appropriate svm_classify executable and compiled the C source files and linked them to the current folder. if not, you will encounter errors

for infile in *.faa
do
	echo "Processing $infile"
	outfile=$(basename $infile .faa)
	echo "Outfile $outfile"
	perl run_fungalrv_adhesin_predictor.pl $infile $outfile.txt y >$outfile.log 2>$outfile.err
	rm -f ./tmp.faa
	echo "done"
done

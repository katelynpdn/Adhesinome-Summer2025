#!/bin/bash
# title: Run 3-Part Test Pipeline (FungalRV, SignalP, PredGPI) on yeast panproteomes
# author: Katelyn Nguyen
# date: 2025-06-23

set -e

proteomeList=("UP000002428.fasta.gz")

for proteome in proteomeList
do
    wget "https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/pan_proteomes/$proteome"
    gunzip "$proteome"
    ./adhesinPipeline.sh "$proteome" "${proteome}Output"
done

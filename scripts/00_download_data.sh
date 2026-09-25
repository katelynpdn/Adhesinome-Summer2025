#!/bin/bash
# title: Proteomes in data/inputProteomes.txt are searched for and downloaded at reference_proteomes/Eukaryota
# author: Katelyn Nguyen
# date: 2026-09-25

source "$(dirname "${BASH_SOURCE[0]}")/common_path_setup.sh"

# Download each proteome
while read -r proteome; do
    # Skip empty lines
    [[ -z "$proteome" ]] && continue

    echo "Processing $proteome..."

    UP_URL="https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/$proteome/"

    # Get the list of files in that directory
    files=$(curl -s "$UP_URL")

    # Extract the .fasta.gz file (not DNA or additional)
    proteomeFile=$(echo "$files" \
        | grep -oP 'href="\K[^"]+\.fasta\.gz' \
        | grep -v DNA \
        | grep -v additional \
        | head -n 1)

    # Check if we found a matching file
    if [[ -z "$proteomeFile" ]]; then
        echo "WARNING: No .fasta.gz file found for $proteome at $UP_URL. Skipping."
        continue
    fi

    # Remove .gz to get the expected uncompressed filename
    fastaFile="${proteomeFile%.gz}"

    # Check whether the uncompressed file already exists
    if [[ -f "$DATA_DIR/$fastaFile" ]]; then
        echo "Proteome file $DATA_DIR/$fastaFile already exists. Skipping download."
        continue
    fi

    # Download the compressed file
    echo "Downloading $proteomeFile..."
    wget -P "$DATA_DIR" "${UP_URL}${proteomeFile}"

    # Unzip
    echo "Uncompressing $proteomeFile..."
    gunzip "$DATA_DIR/$proteomeFile"

    echo "Finished downloading $proteome"

done < "$INPUT_FILE"
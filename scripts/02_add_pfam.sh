#!/bin/bash
# title: Run HMMSCAN to get Pfam domains, 
#       and add results into proteinTable.csv for each proteome in data/inputProteomes.txt
# author: Katelyn Nguyen
# date: 2026-10-07

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directory_with_Pfam>"
    exit 1
fi

pfamDirectory=$(readlink -f "$1")
if [[ -z "$pfamDirectory" || ! -d "$pfamDirectory" ]]; then
    echo "Error: Invalid or non-existent Pfam directory: $1"
    exit 1
fi

source "$(dirname "${BASH_SOURCE[0]}")/common_path_setup.sh"

# Process each proteome
while read -r proteome; 
do
    # Skip empty lines and comments
    [[ -z "$proteome" ]] && continue
    [[ "$proteome" =~ ^# ]] && continue

    echo "Processing $proteome"

    # Find all FASTA files whose names start with the proteome accession
    mapfile -t fastaFiles < <(
        find "$DATA_DIR" \
            -maxdepth 1 \
            -type f \
            -name "${proteome}*.fasta" \
            -print
    )
    # Make sure exactly one FASTA file was found
    if [[ "${#fastaFiles[@]}" -eq 0 ]]; then
        echo "ERROR: No FASTA file found for $proteome."
        echo "Expected exactly one file matching:"
        echo "  $DATA_DIR/${proteome}*.fasta"
        echo "Skipping $proteome..."
        continue
    fi
    if [[ "${#fastaFiles[@]}" -gt 1 ]]; then
        echo "ERROR: Multiple FASTA files found for $proteome:"
        for fastaFile in "${fastaFiles[@]}"; do
            echo "  $fastaFile"
        done
        echo "Expected exactly one matching FASTA file."
        echo "Skipping $proteome..."
        continue
    fi

    proteomeFile="${fastaFiles[0]}"

    echo "Using FASTA:"
    echo "  $proteomeFile"

    # Set output directory
    outputDirectory="$RESULTS_DIR/$proteome"
    mkdir -p "$outputDirectory"
    outputFile="$outputDirectory/proteinTable.csv"

    # ==== HMMSCAN on Pfam ====
    # If hmmscan_domtblout already exists in outputDirectory, ask user if they want to continue
    hmmContinue="y"
    if [ -f "$outputDirectory/hmmscan_domtblout" ]; then
        read -p "$outputDirectory/hmmscan_domtblout exists from a previous run. Run HMMSCAN anyways? (y/n) " hmmContinue
    fi
    if [[ $hmmContinue == "y" || $hmmContinue == "Y" || $hmmContinue == "yes" || $hmmContinue == "Yes" ]]; then
        echo "-------------Running HMMSCAN on Pfam-------------"
        hmmscan --domtblout  "$outputDirectory/hmmscan_domtblout" "$pfamDirectory/Pfam-A.hmm" "$proteomeFile"
    else
        echo "Skipping HMMSCAN step, continuing..."
    fi

    # === Add Pfam results to proteinTable.csv ===
    echo "-------------Adding Pfam results to proteinTable.csv-------------"
    if ! Rscript "$SUBSCRIPTS_DIR/parse_pfam.R" \
        "$outputDirectory"; then

        echo "ERROR: Failed to add HMMSCAN PFAM results to proteinTable.csv for $proteome"
        continue
    fi

    echo ""
    echo "Finished $proteome"
    echo "Results saved to:"
    echo "  $outputDirectory"

done < "$INPUT_FILE"
#!/bin/bash
# title: Run SignalP, PredGPI, NetGPI, Ser/Thr frequency, Beta-aggregation, Tandem repeats, and combine results into a table
        # and process output for each proteome in data/inputProteomes.txt
# author: Katelyn Nguyen
# date: 2026-09-24

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


    # === PredGPI ===

    PREDGPI_OUTPUT="$outputDirectory/predgpi_output"

    if [[ -f "$PREDGPI_OUTPUT" ]]; then
        read -p \
            "$PREDGPI_OUTPUT exists from a previous run. Run PredGPI anyways? (y/n) " \
            GPIContinue
    else
        GPIContinue="y"
    fi

    if [[ "$GPIContinue" == "y" ||
          "$GPIContinue" == "Y" ||
          "$GPIContinue" == "yes" ||
          "$GPIContinue" == "Yes" ]]; then

        echo "-------------Running PredGPI-------------"

        export PREDGPI_HOME="$SRC_DIR/predgpi"

        python "$SRC_DIR/predgpi/predgpi.py" \
            -f "$proteomeFile" \
            -m gff3 \
            -o "$PREDGPI_OUTPUT"

    else
        echo "Skipping PredGPI step, continuing..."
    fi


    # === NetGPI ===

    NETGPI_OUTPUT="$outputDirectory/netgpi_output"

    if [[ -f "$NETGPI_OUTPUT" ]]; then
        read -p \
            "$NETGPI_OUTPUT exists from a previous run. Run NetGPI anyways? (y/n) " \
            netgpiContinue
    else
        netgpiContinue="y"
    fi

    if [[ "$netgpiContinue" == "y" ||
          "$netgpiContinue" == "Y" ||
          "$netgpiContinue" == "yes" ||
          "$netgpiContinue" == "Yes" ]]; then

        echo "-------------Running NetGPI-------------"

        python "$SUBSCRIPTS_DIR/runNetGPI.py" \
            "$proteomeFile" \
            "$NETGPI_OUTPUT"

    else
        echo "Skipping NetGPI step, continuing..."
    fi

    # Change directories
    cd "$SUBSCRIPTS_DIR"

    # === SignalP ===

    SIGNALP_OUTPUT="$outputDirectory/signalP_output"

    if [[ -f "$SIGNALP_OUTPUT" ]]; then
        read -p \
            "$SIGNALP_OUTPUT exists from a previous run. Run SignalP anyways? (y/n) " \
            spContinue
    else
        spContinue="y"
    fi

    if [[ "$spContinue" == "y" ||
          "$spContinue" == "Y" ||
          "$spContinue" == "yes" ||
          "$spContinue" == "Yes" ]]; then

        echo "-------------Running SignalP-------------"

        ./runSignalP.sh "$proteomeFile"

        mv biolib_results/merged_prediction_results.txt \
            "$SIGNALP_OUTPUT"

    else
        echo "Skipping SignalP step, continuing..."
    fi

    # === EMBOSS freak ===
    # If freak-output already exists in outputDirectory, ask user if they want to continue
    freakContinue="y"
    if [ -d "$outputDirectory/freak-output" ]; then
        read -p "$outputDirectory/freak-output exists from a previous run. Run freak anyways? (y/n) " freakContinue
    fi
    if [[ $freakContinue == "y" || $freakContinue == "Y" || $freakContinue == "yes" || $freakContinue == "Yes" ]]; then
        echo "-------------Running EMBOSS freak-------------"
        ./run_freak.sh "$proteomeFile" "$outputDirectory/freak-output"
    else
        echo "Skipping freak step, continuing..."
    fi

    # === Ser/Thr frequencies ===
    # If ST_freq_perProtein already exists in outputDirectory, ask user if they want to continue
    stContinue="y"
    if [ -f "$outputDirectory/ST_freq_perProtein" ]; then
        read -p "$outputDirectory/ST_freq_perProtein exists from a previous run. Calculate Ser/Thr frequencies anyways? (y/n) " stContinue
    fi
    if [[ $stContinue == "y" || $stContinue == "Y" || $stContinue == "yes" || $stContinue == "Yes" ]]; then
        echo "-------------Calculating Ser/Thr frequencies-------------"
        python calc_aafreq_gz.py "$proteomeFile" > "$outputDirectory/ST_freq_perProtein"
    else
        echo "Skipping Ser/Thr per protein step, continuing..."
    fi

    # === TANGO ===
    # If tango-output already exists in outputDirectory, ask user if they want to continue
    tangoContinue="y"
    if [ -d "$outputDirectory/tango-output" ]; then
        read -p "$outputDirectory/tango-output exists from a previous run. Run TANGO anyways? (y/n) " tangoContinue
    fi
    if [[ $tangoContinue == "y" || $tangoContinue == "Y" || $tangoContinue == "yes" || $tangoContinue == "Yes" ]]; then
        echo "-------------Running TANGO-------------"
        ./runTango.sh "$proteomeFile" "$outputDirectory/tango-output"
    else
        echo "Skipping TANGO step, continuing..."
    fi

    # === XSTREAM ===
    # If tandem-repeats already exists in outputDirectory, ask user if they want to continue
    xstreamContinue="y"
    if [ -d "$outputDirectory/tandem-repeats" ]; then
        read -p "$outputDirectory/tandem-repeats exists from a previous run. Run XSTREAM anyways? (y/n) " xstreamContinue
    fi
    if [[ $xstreamContinue == "y" || $xstreamContinue == "Y" || $xstreamContinue == "yes" || $xstreamContinue == "Yes" ]]; then
    echo "-------------Running XSTREAM-------------"
        ./xstream.sh "$proteomeFile" proteins "$outputDirectory/tandem-repeats"
    else
        echo "Skipping XSTREAM step, continuing..."
    fi

    echo "-------------Combining annotation results-------------"
    if ! Rscript "$SUBSCRIPTS_DIR/parse_output.R" \
        "$outputDirectory" \
        "$proteomeFile"; then

        echo "ERROR: Failed to create proteinTable.csv for $proteome"
        continue
    fi

    echo ""
    echo "Finished $proteome"
    echo "Results saved to:"
    echo "  $outputDirectory"

done < "$INPUT_FILE"
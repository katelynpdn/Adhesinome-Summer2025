#!/bin/bash
# title: Extract adhesin candidates: proteins that have a SignalP probability above 0.5, a NetGPI likelihood above 0.5, and a PredGPI prediction of True
# author: Katelyn Nguyen
# date: 2026-09-26

source "$(dirname "${BASH_SOURCE[0]}")/common_path_setup.sh"

# Process each proteome
while read -r proteome;
do
    # Skip empty lines
    [[ -z "$proteome" ]] && continue

    echo "Extracting adhesin candidates for $proteome"

    # Find results directory for the proteome
    proteomeResultsDir="$RESULTS_DIR/$proteome"

    if [[ ! -d "$proteomeResultsDir" ]]; then
        echo "ERROR: Results directory for $proteome does not exist: $proteomeResultsDir"
        echo "Skipping $proteome..."
        continue
    fi

    # Output file
    OUTPUT_FILE="$RESULTS_DIR/$proteome/adhesinCandidateTable.csv"

    # proteinTable.csv should contain all required prediction columns
    proteinTable="$proteomeResultsDir/proteinTable.csv"

    if [[ ! -f "$proteinTable" ]]; then
        echo "ERROR: proteinTable.csv does not exist for $proteome:"
        echo "  $proteinTable"
        echo "Skipping $proteome..."
        continue
    fi

    # Extract rows satisfying all three criteria.
    #
    # Criteria:
    #   Signal Peptide > 0.5
    #   NetGPI Likelihood > 0.5
    #   PredGPI Prediction == TRUE
    #
    # The first file processed provides the header.
    if [[ ! -s "$OUTPUT_FILE" ]]; then
        head -n 1 "$proteinTable" > "$OUTPUT_FILE"
    fi

    # Find column numbers from the header, then filter rows.
    awk -F',' '
        NR == 1 {
            for (i = 1; i <= NF; i++) {
                if ($i == "ID") id_col = i
                if ($i == "PredGPI Prediction") predgpi_col = i
                if ($i == "Signal Peptide") signalp_col = i
                if ($i == "NetGPI Likelihood") netgpi_col = i
            }

            if (!id_col || !predgpi_col || !signalp_col || !netgpi_col) {
                print "ERROR: Required column missing from proteinTable.csv" > "/dev/stderr"
                exit 1
            }

            next
        }

        $signalp_col > 0.5 &&
        $netgpi_col > 0.5 &&
        $predgpi_col == "TRUE" {
            print
        }
    ' "$proteinTable" >> "$OUTPUT_FILE"

    echo "Finished $proteome"
    echo "Results saved to:"
    echo "  $proteomeResultsDir"

done < "$INPUT_FILE"
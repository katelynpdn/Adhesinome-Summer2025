#!/bin/bash
# title: Combine protein tables and add failed test information
#
# Output:
#   - results/combinedProteinTable.csv
#     All proteins from all proteomes, with Proteome and failed_tests
#     columns, sorted by number of failed tests.
#
# Criteria:
#   - SignalP: score > 0.5
#   - NetGPI: TRUE
#   - PredGPI: TRUE
#
# failed_tests:
#   - NA if all three criteria pass
#   - Otherwise, space-separated names of failed tests
#
# author: Katelyn Nguyen
# date: 2026-10-17

source "$(dirname "${BASH_SOURCE[0]}")/common_path_setup.sh"

# Output file
combinedTable="$RESULTS_DIR/combinedProteinTable.csv"

# Temporary files
tmpCombined=$(mktemp)
tmpRows=$(mktemp)

trap 'rm -f "$tmpCombined" "$tmpRows"' EXIT

# Start fresh
: > "$tmpCombined"
: > "$tmpRows"

combined_header_written=false

# ------------------------------------------------------------
# Process each proteome
# ------------------------------------------------------------

while IFS= read -r proteome || [[ -n "$proteome" ]]; do

    # Skip empty lines
    [[ -z "$proteome" ]] && continue

    echo "Processing $proteome"

    proteomeResultsDir="$RESULTS_DIR/$proteome"
    proteinTable="$proteomeResultsDir/proteinTable.csv"

    if [[ ! -d "$proteomeResultsDir" ]]; then
        echo "ERROR: Results directory does not exist: $proteomeResultsDir"
        echo "Skipping $proteome..."
        continue
    fi

    if [[ ! -f "$proteinTable" ]]; then
        echo "ERROR: proteinTable.csv does not exist: $proteinTable"
        echo "Skipping $proteome..."
        continue
    fi

    # --------------------------------------------------------
    # Process proteinTable.csv
    # --------------------------------------------------------

    
    awk -F',' -v OFS=',' \
        -v proteome="$proteome" \
        -v combined="$tmpCombined" \
        -v rows="$tmpRows" \
        -v combined_header_written="$combined_header_written" '
        NR == 1 {
            predgpi_col = 0
            signalp_col = 0
            netgpi_col = 0

            for (i = 1; i <= NF; i++) {
                if ($i == "PredGPI Prediction")
                    predgpi_col = i

                if ($i == "Signal Peptide")
                    signalp_col = i

                if ($i == "NetGPI Prediction")
                    netgpi_col = i
            }

            if (!predgpi_col || !signalp_col || !netgpi_col) {
                print "ERROR: Required column missing from " FILENAME > "/dev/stderr"
                exit 1
            }

            if (combined_header_written == "false") {
                print "Proteome", $0, "failed_tests" > combined
            }

            next
        }

        {
            signalp_pass = ($signalp_col + 0 > 0.5)
            netgpi_pass = ($netgpi_col == "TRUE")
            predgpi_pass = ($predgpi_col == "TRUE")

            pass_count = signalp_pass + netgpi_pass + predgpi_pass
            fail_count = 3 - pass_count

            failed_tests = ""

            if (!signalp_pass)
                failed_tests = failed_tests "SignalP "

            if (!netgpi_pass)
                failed_tests = failed_tests "NetGPI "

            if (!predgpi_pass)
                failed_tests = failed_tests "PredGPI "

            sub(/ $/, "", failed_tests)

            if (failed_tests == "")
                failed_tests = "NA"

            print fail_count, proteome, $0, failed_tests >> rows
        }
    ' "$proteinTable"


    if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to process $proteinTable"
        exit 1
    fi

    combined_header_written=true

    echo "Finished $proteome"

done < "$INPUT_FILE"

# ------------------------------------------------------------
# Sort combined results by number of failed tests
# ------------------------------------------------------------

if [[ "$combined_header_written" == "true" ]]; then

    {
        # Header from the first valid protein table
        head -n 1 "$tmpCombined"

        # Sort by failure count (0, 1, 2, 3), then remove sort key
        sort -t',' -k1,1n "$tmpRows" |
            cut -d',' -f2-
    } > "$combinedTable"

else
    echo "ERROR: No valid protein tables were processed." >&2
    exit 1
fi

echo ""
echo "All proteomes processed."

echo ""
echo "Combined protein table saved to:"
echo "  $combinedTable"
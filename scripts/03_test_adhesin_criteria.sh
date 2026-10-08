#!/bin/bash
# title: Extract adhesin candidates and negative subsets based on
#       SignalP, NetGPI, and PredGPI criteria
#
#       Positive candidates:
#         - Pass at least 2 of 3 criteria
#
#       Negative subset 1:
#         - Fail all 3 criteria
#
#       Negative subset 2:
#         - Fail exactly 2 of 3 criteria
#
# author: Katelyn Nguyen
# date: 2026-09-26

source "$(dirname "${BASH_SOURCE[0]}")/common_path_setup.sh"

# ------------------------------------------------------------
# Output files for negative subsets
# ------------------------------------------------------------

outputDir="$RESULTS_DIR/curatedSets"
mkdir -p "$outputDir"

subset1="$outputDir/negative_subset1_fail_all.csv"
subset2="$outputDir/negative_subset2_fail_two.csv"

# Start fresh negative subset files
> "$subset1"
> "$subset2"

# Track whether headers have been written
subset1_header_written=false
subset2_header_written=false


# ------------------------------------------------------------
# Process each proteome
# ------------------------------------------------------------

while read -r proteome;
do
    # Skip empty lines
    [[ -z "$proteome" ]] && continue

    echo "Processing $proteome"

    # Find results directory for the proteome
    proteomeResultsDir="$RESULTS_DIR/$proteome"

    if [[ ! -d "$proteomeResultsDir" ]]; then
        echo "ERROR: Results directory for $proteome does not exist: $proteomeResultsDir"
        echo "Skipping $proteome..."
        continue
    fi

    # Input protein table
    proteinTable="$proteomeResultsDir/proteinTable.csv"

    if [[ ! -f "$proteinTable" ]]; then
        echo "ERROR: proteinTable.csv does not exist for $proteome:"
        echo "  $proteinTable"
        echo "Skipping $proteome..."
        continue
    fi

    # Positive candidate output
    OUTPUT_FILE="$proteomeResultsDir/adhesinCandidateTable.csv"

    # Start fresh for this proteome
    > "$OUTPUT_FILE"


    # Process proteinTable.csv

    awk -F',' -v OFS=',' \
        -v proteome="$proteome" \
        -v subset1="$subset1" \
        -v subset2="$subset2" \
        -v output="$OUTPUT_FILE" \
        -v subset1_header_written="$subset1_header_written" \
        -v subset2_header_written="$subset2_header_written" '

        # ----------------------------------------------------
        # Header
        # ----------------------------------------------------
        NR == 1 {

            for (i = 1; i <= NF; i++) {
                if ($i == "ID")
                    id_col = i

                if ($i == "PredGPI Prediction")
                    predgpi_col = i

                if ($i == "Signal Peptide")
                    signalp_col = i

                if ($i == "NetGPI Likelihood")
                    netgpi_col = i
            }

            # Check that all required columns exist
            if (!id_col || !predgpi_col || !signalp_col || !netgpi_col) {
                print "ERROR: Required column missing from proteinTable.csv" > "/dev/stderr"
                exit 1
            }

            # ------------------------------------------------
            # Positive candidate header
            # ------------------------------------------------
            print $0, "Failed Test" > output

            # ------------------------------------------------
            # Negative subset headers
            # ------------------------------------------------
            if (subset1_header_written == "false") {
                print $0, "proteome" > subset1
                subset1_header_written = "true"
            }

            if (subset2_header_written == "false") {
                print $0, "proteome" > subset2
                subset2_header_written = "true"
            }

            next
        }


        # ----------------------------------------------------
        # Process each protein
        # ----------------------------------------------------
        {

            # Determine whether each criterion passes

            signalp_pass = ($signalp_col > 0.5)

            netgpi_pass = ($netgpi_col > 0.5)

            predgpi_pass = ($predgpi_col == "TRUE")


            # Count criteria passed and failed

            pass_count = signalp_pass + netgpi_pass + predgpi_pass

            fail_count = 3 - pass_count


            # =================================================
            # POSITIVE CANDIDATES
            #
            # Keep proteins passing at least 2/3 criteria.
            # =================================================

            if (pass_count >= 2) {

                # Determine failed test
                #
                # If all three pass:
                #     NA
                #
                # Otherwise identify the single failed test.

                if (!signalp_pass)
                    failed_test = "SignalP"

                else if (!netgpi_pass)
                    failed_test = "NetGPI"

                else if (!predgpi_pass)
                    failed_test = "PredGPI"

                else
                    failed_test = "NA"


                # Write original row + Failed Test
                print $0, failed_test > output
            }


            # =================================================
            # NEGATIVE SUBSET 1
            #
            # Fail all three criteria.
            # =================================================

            if (fail_count == 3) {

                # Write original row + proteome
                print $0, proteome >> subset1
            }


            # =================================================
            # NEGATIVE SUBSET 2
            #
            # Fail exactly two criteria.
            # =================================================

            else if (fail_count == 2) {

                # Write original row + proteome
                print $0, proteome >> subset2
            }
        }

    ' "$proteinTable"

    echo "Finished $proteome"

    echo "Positive candidates saved to:"
    echo "  $OUTPUT_FILE"

done < "$INPUT_FILE"

echo ""
echo "All proteomes processed."

echo ""
echo "Negative subset 1 (fail all three criteria):"
echo "  $subset1"

echo ""
echo "Negative subset 2 (fail exactly two criteria):"
echo "  $subset2"
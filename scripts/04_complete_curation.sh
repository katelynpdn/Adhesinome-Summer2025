#!/bin/bash
# title: Based on annotatedAdhesinCandidateTable.csv, curate the positive set
#       AND remaining negative subsets:
#
#       Positive set:
#         - Manually classified TRUE
#
#       Negative subset 3:
#         - Failed exactly 1 criterion (SignalP, NetGPI, or PredGPI)
#
#       Negative subset 4:
#         - Passed all 3 criteria, but manually classified FALSE
#
# author: Katelyn Nguyen
# date: 2026-10-08

source "$(dirname "${BASH_SOURCE[0]}")/common_path_setup.sh"

proteinFile="$RESULTS_DIR/curatedSets/annotatedAdhesinCandidateTable.csv"

outputDir="$RESULTS_DIR/curatedSets"
mkdir -p "$outputDir"

positiveSet="$outputDir/positive_set.csv"
subset3="$outputDir/negative_subset3_fail_one.csv"
subset4="$outputDir/negative_subset4_fail_none.csv"

# Start fresh output files
> "$positiveSet"
> "$subset3"
> "$subset4"

awk -F',' '
BEGIN {
    OFS=","
}

NR == 1 {
    # Find columns by header name
    for (i = 1; i <= NF; i++) {
        header = $i
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", header)

        if (header == "ID")
            id_col = i

        else if (header == "Manual Adhesin Classification")
            manual_col = i

        else if (header == "Failed Test")
            failed_col = i
    }

    # Make sure required columns exist
    if (!manual_col) {
        print "ERROR: 'Manual Adhesin Classification' column not found." > "/dev/stderr"
        exit 1
    }

    if (!failed_col) {
        print "ERROR: 'Failed Test' column not found." > "/dev/stderr"
        exit 1
    }

    # Write the original header to all output files
    print $0 > "'"$positiveSet"'"
    print $0 > "'"$subset3"'"
    print $0 > "'"$subset4"'"

    next
}

{
    # Normalize values
    manual = $manual_col
    failed_test = $failed_col

    gsub(/^[[:space:]]+|[[:space:]]+$/, "", manual)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", failed_test)

    manual = toupper(manual)
    failed_test = toupper(failed_test)


    # ------------------------------------------------------------
    # Positive set
    #
    # Anything manually classified TRUE goes into the positive set,
    # regardless of the Failed Test value.
    # ------------------------------------------------------------
    if (manual == "TRUE") {
        print $0 >> "'"$positiveSet"'"
    }


    # ------------------------------------------------------------
    # Negative subset 3
    #
    # Failed exactly ONE criterion.
    #
    # Failed Test identifies which criterion failed.
    # ------------------------------------------------------------
    else if (
        failed_test == "SIGNALP" ||
        failed_test == "NETGPI" ||
        failed_test == "PREDGPI"
    ) {
        print $0 >> "'"$subset3"'"
    }


    # ------------------------------------------------------------
    # Negative subset 4
    #
    # Passed all three criteria (Failed Test = NA)
    # but manually classified FALSE.
    # ------------------------------------------------------------
    else if (
        failed_test == "NA" &&
        manual == "FALSE"
    ) {
        print $0 >> "'"$subset4"'"
    }
}

END {
    close("'"$positiveSet"'")
    close("'"$subset3"'")
    close("'"$subset4"'")
}
' "$proteinFile"

echo "Curated sets written to:"
echo "  Positive set: $positiveSet"
echo "  Subset 3:     $subset3"
echo "  Subset 4:     $subset4"
#!/bin/bash
# title: Curate the positive set AND negative subsets:
#
#       Positive set: Manually annotated as an adhesin
#         - From manualAnnotations.csv, proteins where is_adhesin_confidence
#           is "Confident" or "Likely"
#
#       Negative subset 1: Manually annotated as not an adhesin: 'boundary cases'
#         - From manualAnnotations.csv, proteins where is_adhesin_confidence
#           is "Unlikely"
#
#       Negative subset 2:
#         - From combinedProteinTable.csv, proteins that fail two criteria
#           and are not in manualAnnotations.csv
#
#       Negative subset 3:
#         - From combinedProteinTable.csv, proteins that fail all 3 criteria
#
# author: Katelyn Nguyen
# date: 2026-10-17

source "$(dirname "${BASH_SOURCE[0]}")/common_path_setup.sh"

if ! Rscript "$SUBSCRIPTS_DIR/curate_datasets.R" "$RESULTS_DIR"; then
    echo "ERROR: Failed to curate datasets"
    exit 1
fi
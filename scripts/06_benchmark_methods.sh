#!/bin/bash
# title: Based on annotatedAdhesinCandidateTable.csv, benchmark the performance of different adhesin prediction methods
# author: Katelyn Nguyen
# date: 2026-10-07

source "$(dirname "${BASH_SOURCE[0]}")/common_path_setup.sh"

proteinFile="$RESULTS_DIR/annotatedAdhesinCandidateTable.csv"

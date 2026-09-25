# Run FungalRV

# Remove FASTA ambiguities
proteomeFile_clean="${proteomeFile}_clean.fasta"
echo "-------------Removing FASTA ambiguities-------------"
python "$SUBSCRIPTS_DIR/fastaRemoveAmbiguity.py" \
    "$proteomeFile" \
    "$proteomeFile_clean"


# Prepare FASTA for FungalRV
# FungalRV does not accept long pathnames, so copy the cleaned FASTA into SRC_DIR/data.
copyProteomeFile="$(basename "$proteomeFile_clean")"
mkdir -p "$SRC_DIR/tmp"

if [[ ! -f "$SRC_DIR/tmp/$copyProteomeFile" ]]; then
    cp "$proteomeFile_clean" \
        "$SRC_DIR/tmp/$copyProteomeFile"
fi


# === FungalRV ===
FUNGALRV_OUTPUT="$outputDirectory/fungalrv_output"

if [[ -f "$FUNGALRV_OUTPUT" ]]; then
    read -p \
        "$FUNGALRV_OUTPUT exists from a previous run. Run FungalRV anyways? (y/n) " \
        fungalContinue
else
    fungalContinue="y"
fi

if [[ "$fungalContinue" == "y" ||
        "$fungalContinue" == "Y" ||
        "$fungalContinue" == "yes" ||
        "$fungalContinue" == "Yes" ]]; then

    echo "-------------Running FungalRV-------------"

    cd "$SRC_DIR/FungalRV_adhesin_predictor"

    perl run_fungalrv_adhesin_predictor.pl \
        "../tmp/$copyProteomeFile" \
        "$FUNGALRV_OUTPUT" \
        y

else
    echo "Skipping FungalRV step, continuing..."
fi

# Clean up temporary files
rm -f "$proteomeFile_clean"
rm -f "$SRC_DIR/tmp/$copyProteomeFile"
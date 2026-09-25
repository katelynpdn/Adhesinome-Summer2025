# title: Prepare sequence file for Tango in the format (Name Cter Nter pH Temp Ionic Stability Concentration Sequence)
# author: Katelyn Nguyen
# date: 2025-06-25

import sys
from Bio import SeqIO

if len(sys.argv) != 2:
    print("Usage: python prepareTango.py <input.fasta>")
    sys.exit(1)

inputFile = sys.argv[1]
ambiguity_letters = "BJOUXZ"
translationTable = str.maketrans('', '', ambiguity_letters)

# Compile sequence file for Tango in the format (Name Cter Nter pH Temp Ionic Stability Concentration Sequence)
for record in SeqIO.parse(inputFile, "fasta"): 
    # Remove any ambiguities
    seq_clean = str(record.seq).translate(translationTable)
    print(record.id, "N", "N", 7.5, 298, 0.1, -10, 1, seq_clean, sep=" ")
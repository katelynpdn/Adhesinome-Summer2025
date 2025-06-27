# title: Prepare sequence file for Tango in the format (Name Cter Nter pH Temp Ionic Stability Concentration Sequence)
# author: Katelyn Nguyen
# date: 2025-06-25

import sys
from Bio import SeqIO

if len(sys.argv) != 2:
    print("Usage: python prepareTango.py <input.fasta>")
    sys.exit(1)

inputFile = sys.argv[1]

# Compile sequence file for Tango in the format (Name Cter Nter pH Temp Ionic Stability Concentration Sequence)
for record in SeqIO.parse(inputFile, "fasta"): 
    # Remove any X's from sequence  
    seq_noX =  record.seq.replace("X", "")
    print(record.id, "N", "N", 7.5, 298, 0.1, -10, 1, seq_noX, sep=" ")
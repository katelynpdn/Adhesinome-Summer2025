# Remove any X's in a FASTA file
import sys
import os

if len(sys.argv) != 2:
    print("Usage: python fastaRemoveX.py <filename>")

inputFile = sys.argv[1]
outputFile = os.path.splitext(inputFile)[0] + "_noX.fasta"

with open(inputFile, "r") as inputf, open(outputFile, "w") as outf:
    for line in inputf:
        if line.startswith(">"):    # ID
            outf.write(line) 
        else:   # Sequence
            outf.write(line.replace("X", ""))   # Remove any X'sf
# Remove any X's in a FASTA file
import sys

if len(sys.argv) != 3:
    print("Usage: python fastaRemoveX.py <inputFile> <outputFile>")
    sys.exit(1)

inputFile = sys.argv[1]
outputFile = sys.argv[2]

with open(inputFile, "r") as inputf, open(outputFile, "w") as outf:
    for line in inputf:
        if line.startswith(">"):    # ID
            outf.write(line) 
        else:   # Sequence
            outf.write(line.replace("X", ""))   # Remove any X's
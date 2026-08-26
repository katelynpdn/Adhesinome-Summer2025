# Remove any residue ambiguities: B/J/O/U/X/Z in a FASTA file
import sys

if len(sys.argv) != 3:
    print("Usage: python fastaRemoveX.py <inputFile> <outputFile>")
    sys.exit(1)

inputFile = sys.argv[1]
outputFile = sys.argv[2]
ambiguity_letters = "BJOUXZ"

with open(inputFile, "r") as inputf, open(outputFile, "w") as outf:
    for line in inputf:
        if line.startswith(">"):    # ID
            outf.write(line) 
        else:   # Sequence
            # Remove any ambiguities
            translationTable = str.maketrans('', '', ambiguity_letters)
            outf.write(line.translate(translationTable))
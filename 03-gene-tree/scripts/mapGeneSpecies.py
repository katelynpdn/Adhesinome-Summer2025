# Map sequence to species name -> text file for GeneRax
# Assuming sequence is in the form >NP_012537.1_Saccharomyces_cerevisiae

import sys
from Bio import SeqIO

if len(sys.argv) != 3:
    print("Usage: python mapGeneSpecies.py <file.fasta> <outputFile")
    sys.exit(1)

inputFile = sys.argv[1]
outputFile = sys.argv[2]

with open(outputFile, 'w') as outf:
    for record in SeqIO.parse(inputFile, "fasta"):
        # Extract species name in header
        speciesName = record.id.split('.')[1][2:]
        # Remove -newassembly if exists
        if (speciesName.endswith("-newassembly")):
            speciesName = speciesName[:-12]
        # Write header and species name to file
        outf.write(record.id + "\t" + speciesName + "\n")
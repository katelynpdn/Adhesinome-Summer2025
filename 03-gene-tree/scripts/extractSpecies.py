# Output species names embedded in FASTA headers
    # Also print number of sequences belonging to each species
# Assuming it's in the form >NP_012537.1_Saccharomyces_cerevisiae

import sys
from Bio import SeqIO

if len(sys.argv) != 3:
    print("Usage: python extractSpecies.py <file.fasta> <outputFile>")
    sys.exit(1)

inputFile = sys.argv[1]
outputFile = sys.argv[2]

speciesDict = {}
for record in SeqIO.parse(inputFile, "fasta"):
    # Extract species name in header
    speciesName = record.id.split('.')[1][2:]
    # Remove -newassembly if exists
    if (speciesName.endswith("-newassembly")):
        speciesName = speciesName[:-12]
    # speciesName = speciesName.replace("_", " ")       # Replace underscore with space
    
    # Add species name to speciesDict
    if speciesName not in speciesDict:
        speciesDict[speciesName] = 1
    else:
        speciesDict[speciesName] += 1

# Write to file each species in dictionary
with open(outputFile, 'w') as outf:
    for species, count in speciesDict.items():
        outf.write(species + "\n")
        # Print to output: Number of sequences belonging to each species in outputFile
        print(str(count), end = ' ')
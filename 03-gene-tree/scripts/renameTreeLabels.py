# Rename gene labels to speciesgene
# For Notung

import sys
from ete3 import Tree

if len(sys.argv) != 3:
    print("Usage: python renameTreeLabels.py <file.fasta> <outputFile>")
    sys.exit(1)

inputFile = sys.argv[1]
outputFile = sys.argv[2]

# Read Tree from file
t = Tree(inputFile)

for node in t.traverse():
    # Extract species name in header
    if (node.name != ""):
        parts = node.name.split('.')
        speciesName = parts[1][2:]
        # Remove -newassembly if exists
        if (speciesName.endswith("-newassembly")):
            speciesName = speciesName[:-12]
        # Fix label
        node.name = speciesName + parts[0]

t.write(outfile=outputFile)
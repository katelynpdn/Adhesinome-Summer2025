# Remove proteins that are not in Li et al tree:
#   (Candida_haemuloni, 'Candida_pseudohaemulonii', or 'Candida_duobushaemulonis' )

import sys
from Bio import SeqIO

if len(sys.argv) != 3:
    print("Usage: python pruneFasta.py <file.fasta> <outputFile")
    sys.exit(1)

inputFile = sys.argv[1]
outputFile = sys.argv[2]

with open(outputFile, 'w') as outf:
    for record in SeqIO.parse(inputFile, "fasta"):
        # Write sequence to new file if it is not any of the following species
        if not ((record.id.endswith("Candida_pseudohaemulonii") or \
            record.id.endswith("Candida_haemuloni") or record.id.endswith("Candida_duobushaemulonis"))):
            SeqIO.write(record, outf, "fasta")

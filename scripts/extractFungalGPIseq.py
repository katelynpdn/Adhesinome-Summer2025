# Output sequences with a GPI anchor & FungalRV score greater than cutoff

import sys
import csv
from Bio import SeqIO

if len(sys.argv) != 3:
    print("Usage: python extractFungalGPIseq.py <combinedFungalPredGPI.csv> <proteome.fasta>")

inputFile = sys.argv[1]
proteomeFile = sys.argv[2]

fungalCutoff = 0.511

# Extract protein IDs with a good FungalRV cutoff and a GPI-anchor
proteins = set()
with open(inputFile, "r") as f:
    csvReader = csv.reader(f)
    for row in csvReader:
        if (row[2] == "TRUE" and float(row[1]) > fungalCutoff):
            proteinID = row[0]
            proteins.add(proteinID)

# Extract sequences of those protein IDs
count = 0
for record in SeqIO.parse(proteomeFile, "fasta"):
    header = record.id
    # If one of the protein IDs is in the sequence header
    if (any(protein in header for protein in proteins)):
        count += 1
        print(">" + header)
        print(record.seq)
        

# print(count)
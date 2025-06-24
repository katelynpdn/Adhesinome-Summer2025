# Output sequences with a GPI anchor, FungalRV score greater than cutoff, and SignalP score greater than cutoff
# seqList_all: Sequences satisfying all 3 conditions
# seqList_other: Other sequences

import sys
import csv
from Bio import SeqIO

if len(sys.argv) != 3:
    print("Usage: python extractSeq.py <combinedOutput.csv> <proteome.fasta>")

inputFile = sys.argv[1]
proteomeFile = sys.argv[2]
outputFile = "seqList_all.fasta"
outputFile2 = "seqList_other.fasta"

fungalCutoff = 0.511
signalPCutoff = 0.5

# Extract protein IDs with a good FungalRV cutoff and a GPI-anchor
proteins = set()
with open(inputFile, "r") as f:
    csvReader = csv.reader(f)
    for row in csvReader:
        if (row[2].lower() == "true" and float(row[1]) > fungalCutoff and float(row[3]) > signalPCutoff):
            proteinID = row[0]
            proteins.add(proteinID)

# Extract sequences of those protein IDs
with open(outputFile, "w") as outfile_all, open(outputFile2, "w") as outfile_other:
    for record in SeqIO.parse(proteomeFile, "fasta"):
        header = record.id
        # If one of the protein IDs is in the sequence header, Add to seqList_all
        if (any(protein in header for protein in proteins)):
            SeqIO.write(record, outfile_all, "fasta")
        else:
            SeqIO.write(record, outfile_other, "fasta")
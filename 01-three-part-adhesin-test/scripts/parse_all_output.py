# Combine FungalRV, PredGPI, and SignalP output
# Output: CSV file with <Protein ID> <FungalRV Score> <GPI-anchor> <Signal Peptide>

# REQUIREMENT: 
# 1. Ensure all comments are removed from all files

import sys
import csv

if len(sys.argv) != 5:
    print("Usage: python parse_all_output.py <fungalRV_file> <predGPI_file> <signalP_file> <output_file>")

fungalFile = sys.argv[1]
predGPIFile = sys.argv[2]
signalPFile = sys.argv[3]
outputFile = sys.argv[4] + ".csv"

# Add protein IDs with a GPI-anchor into set
GPIproteins = set()
with open(predGPIFile, "r") as f:
    tsvReader = csv.reader(f, delimiter="\t")
    for row in tsvReader:
        if (row[2] == "GPI-anchor"):
            proteinID = row[0].split("|")[1]
            GPIproteins.add(proteinID)

# Add SignalP scores (and protein IDs) into dictionary
signalPdict = {}
with open(signalPFile, "r") as f:
    tsvReader = csv.reader(f, delimiter="\t")
    for row in tsvReader:
        proteinID = row[0].split("|")[1]
        signalPdict[proteinID] = row[3]
        
header = ["Protein ID","FungalRV Score","GPI-anchor", "Signal Peptide"]
with open(fungalFile, "r") as inputf, open(outputFile, "w") as outf:
    tsvReader = csv.reader(inputf, delimiter="\t")
    csvWriter = csv.writer(outf)
    csvWriter.writerow(header)
    for row in tsvReader:
        proteinID = row[0].split("|")[1]
        isGPI = proteinID in GPIproteins
        signalP = signalPdict.get(proteinID)
        csvWriter.writerow([f"{proteinID}",f"{row[1]}",f"{isGPI}",f"{signalP}"])


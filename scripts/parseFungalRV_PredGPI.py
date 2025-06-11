# Combine FungalRV and PredGPI output
# Output: CSV file with <Protein ID> <FungalRV Score> <GPI-anchor>

import sys
import csv

if len(sys.argv) != 4:
    print("Usage: python parseFungalRV_PredGPI.py <fungalRV_file> <predGPI_file> <output_file>")

fungalFile = sys.argv[1]
predGPIFile = sys.argv[2]
outputFile = sys.argv[3]

proteins = []
with open(predGPIFile, "r") as f:
    tsvReader = csv.reader(f, delimiter="\t")
    for row in tsvReader:
        if (row[2] == "GPI-anchor"):
            proteinID = row[0].split("|")[1]
            proteins.append(proteinID)

header = ["Protein ID","FungalRV Score","GPI-anchor"]
with open(fungalFile, "r") as inputf, open(outputFile, "w") as outf:
    tsvReader = csv.reader(inputf, delimiter="\t")
    csvWriter = csv.writer(outf)
    csvWriter.writerow(header)
    for row in tsvReader:
        proteinID = row[0].split("|")[1]
        isGPI = proteinID in proteins
        csvWriter.writerow([f"{proteinID}",f"{row[1]}",f"{isGPI}"])


# Combine FungalRV, PredGPI, SignalP, and NetGPI output
# Output: CSV file with <Protein ID> <FungalRV Score> <GPI-anchor> <Signal Peptide> <NetGPI Likelihood>

import sys
import csv

if len(sys.argv) != 6:
    print(
        "Usage: python parse_three_part_test_output.py "
        "<fungalRV_file> <predGPI_file> <signalP_file> "
        "<netGPI_file> <output_file>"
    )
    sys.exit(1)

fungalFile = sys.argv[1]
predGPIFile = sys.argv[2]
signalPFile = sys.argv[3]
netGPIFile = sys.argv[4]
outputFile = sys.argv[5] + ".csv"

# === PredGPI ===
# Add protein IDs with a GPI-anchor into set
GPIproteins = set()

with open(predGPIFile, "r") as f:
    tsvReader = csv.reader(f, delimiter="\t")

    for row in tsvReader:
        if row[2] == "GPI-anchor":
            proteinID = row[0].split("|")[1]
            GPIproteins.add(proteinID)


# === SignalP ===
# Add SignalP scores (and protein IDs) into dictionary
signalPdict = {}

with open(signalPFile, "r") as f:
    for line in f:
        # Skip comments
        if line.startswith("#"):
            continue

        row = line.rstrip("\n").split("\t")

        proteinID = row[0].split("|")[1]
        signalPdict[proteinID] = row[3]


# === NetGPI ===
# Add NetGPI likelihoods into dictionary
netGPIdict = {}
with open(netGPIFile, "r") as f:
    tsvReader = csv.DictReader(f, delimiter="\t")

    for row in tsvReader:
        proteinID = row["id"]
        likelihood = row["likelihood"]

        netGPIdict[proteinID] = likelihood


# === FungalRV + Combined Results ===
# Create combined output
header = [
    "Protein ID",
    "Protein Name",
    "FungalRV Score",
    "GPI-anchor",
    "Signal Peptide",
    "NetGPI Likelihood"
]

with open(fungalFile, "r") as inputf, open(outputFile, "w") as outf:
    # Skip the first 3 lines of FungalRV output.
    for _ in range(3):
            next(inputf)

    tsvReader = csv.reader(inputf, delimiter="\t")
    csvWriter = csv.writer(outf)

    csvWriter.writerow(header)

    for row in tsvReader:
        proteinID = row[0].split("|")[1]
        proteinName = row[0].split("|")[2].split()[0]

        isGPI = proteinID in GPIproteins

        signalP = signalPdict.get(proteinID)

        netGPI = netGPIdict.get(proteinID)

        csvWriter.writerow([
            proteinID,
            proteinName,
            row[1],
            isGPI,
            signalP,
            netGPI
        ])
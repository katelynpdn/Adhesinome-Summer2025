# title: Run Tango on each sequence in given FASTA file
# author: Katelyn Nguyen
# date: 2025-06-23

import subprocess
import sys
from Bio import SeqIO

if len(sys.argv) != 2:
    print("Usage: python runTango.py <input.fasta>")
    sys.exit(1)

inputFile = sys.argv[1]

# Run Tango on each sequence
for record in SeqIO.parse(inputFile, "fasta"):
    subprocess.run(["./tango2_3_1", record.id, "nt='N'", "ct='A'", "ph='7.4'", "te='298'", "io='0.05'", 
                    "tf='0'", "stab='-10'", "conc='1'", "seq='{}'".format(record.seq)])
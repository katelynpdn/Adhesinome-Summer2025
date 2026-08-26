# Split FASTA file into chunks of 300 (or less) sequences

import sys
import os
from Bio import SeqIO

if len(sys.argv) != 2:
    print("Usage: python splitFasta.py <file.fasta>")
    sys.exit(1)

inputFile = sys.argv[1]
startInputFile = os.path.splitext(os.path.basename(inputFile))[0]
SPLIT_COUNT = 300

# From BioPython Documentation: https://biopython.org/wiki/Split_large_file
def batch_iterator(iterator, batch_size):
    """Returns lists of length batch_size.

    This can be used on any iterator, for example to batch up
    SeqRecord objects from Bio.SeqIO.parse(...), or to batch
    Alignment objects from Bio.Align.parse(...), or simply
    lines from a file handle.

    This is a generator function, and it returns lists of the
    entries from the supplied iterator.  Each list will have
    batch_size entries, although the final list may be shorter.
    """
    batch = []
    for entry in iterator:
        batch.append(entry)
        if len(batch) == batch_size:
            yield batch
            batch = []
    if batch:
        yield batch

record_iter = SeqIO.parse(open(inputFile), "fasta")
for i, batch in enumerate(batch_iterator(record_iter, SPLIT_COUNT)):
    outputFile = startInputFile + "_group_%i.fasta" % (i + 1)
    with open(outputFile, "w") as handle:
        count = SeqIO.write(batch, handle, "fasta")
    print("Wrote %i records to %s" % (count, outputFile))
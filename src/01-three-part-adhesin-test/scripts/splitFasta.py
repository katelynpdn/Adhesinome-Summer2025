# Split FASTA file into chunks of 300 (or less) sequences

import sys
import os

def split_fasta(input_file, split_count):
    from Bio import SeqIO
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

    start_input_file = os.path.splitext(os.path.basename(input_file))[0]
    record_iter = SeqIO.parse(open(input_file), "fasta")
    for i, batch in enumerate(batch_iterator(record_iter, split_count)):
        output_file = start_input_file + "_group_%i.fasta" % (i + 1)
        with open(output_file, "w") as handle:
            count = SeqIO.write(batch, handle, "fasta")
        print("Wrote %i records to %s" % (count, output_file))

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python splitFasta.py <file.fasta> <SPLIT_COUNT>")
        sys.exit(1)
    input_file = sys.argv[1]
    split_count = int(sys.argv[2])
    split_fasta(input_file, split_count)

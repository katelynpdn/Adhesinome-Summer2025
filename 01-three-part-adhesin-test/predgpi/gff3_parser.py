# from BCBio import GFF
import pprint
from BCBio.GFF import GFFExaminer
import sys

if (len(sys.argv) != 2):
    print("Usage: python gff3_parser <inputFile>")
in_file = sys.argv[1]
print(in_file)
in_handle = open(in_file)
examiner = GFFExaminer()
in_handle = open(in_file)
pprint.pprint(examiner.parent_child_map(in_handle))
in_handle.close()
# for rec in GFF.parse(in_handle):
#     print(rec)
# in_handle.close()
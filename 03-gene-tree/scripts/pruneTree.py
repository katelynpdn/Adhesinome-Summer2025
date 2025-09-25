# Prune species tree to only contain relevant species
import sys
from ete3 import Tree

if len(sys.argv) != 4:
    print("Usage: python pruneTree.py <species_tree_file> <species_list> <output_file")
    sys.exit(1)

speciesTree = sys.argv[1]
speciesList = sys.argv[2]
outputFile = sys.argv[3]

# Read Tree from file
t = Tree(speciesTree)
# Read list of species to keep
with open(speciesList, "r") as f:
    lines = f.readlines()
    lines = [line.strip() for line in lines]    # Remove newlines

# Prune the tree in order to keep only some leaf nodes
t.prune(lines)
t.write(outfile=outputFile)
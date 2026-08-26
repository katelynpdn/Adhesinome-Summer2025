"""
MODIFIED FROM interpro7-api/docs/examples/fetch-alphafold-for-entry.py
Title: Download AlphaFold predictions (PDB format) of proteins given UniProt IDs.
Example inputFile: A0A0000000 A0A0000001 A0A0000002

Requires python >= 3.6

Example of running command:
$ mkdir -p <outdir>
$ python fetch_alphafold_for_uniprot.py <inputFile> <outdir>
"""

import json
import os
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib.request import urlopen
    
def download_af_pdb(accession, outdir):
    url = f"https://alphafold.ebi.ac.uk/api/prediction/{accession}"
    with urlopen(url) as res:
        payload = res.read().decode("utf-8")
        obj = json.loads(payload)
        pdb_url = obj[0]["pdbUrl"]
        
    filename = os.path.basename(pdb_url)
    filepath = os.path.join(outdir, filename)

    with open(filepath, "wb") as fh, urlopen(pdb_url) as res:
        for chunk in res:
            fh.write(chunk)

# def download_cath(accession, outdir):
#     url = f"https://funvar.cathdb.info/api/uniprot/id/{accession}"
#     with urlopen(url) as res:
#         payload = res.read().decode("utf-8")
#         obj = json.loads(payload)
#         pdb_url = obj[0]["pdbUrl"]
        
#     filename = os.path.basename(pdb_url)
#     filepath = os.path.join(outdir, filename)

#     with open(filepath, "wb") as fh, urlopen(pdb_url) as res:
#         for chunk in res:
#             # fh.write(chunk)
#             print(chunk)

def main():
    inputFile = sys.argv[1]
    outdir = sys.argv[2]

    with open(inputFile) as f:
        input = f.read()
    proteins = input.split()

    # download_cath(proteins[0], outdir)

    with ThreadPoolExecutor(max_workers=8) as executor:
        fs = {}
        done = 0
        milestone = step = 10
        total = len(proteins)

        
        for accession in proteins:
            f = executor.submit(download_af_pdb, accession, outdir)
            fs[f] = accession

        failed = []
        for f in as_completed(fs):
            accession = fs[f]
            print(accession)

            try:
                f.result()
            except Exception as exc:
                failed.append(accession)
                sys.stderr.write(f"error: {exc}\n")
            else:
                done += 1
                progress = done / total * 100
                if progress >= milestone:
                    sys.stderr.write(f"progress: {progress:.0f}%\n")
                    milestone += step


if __name__ == "__main__":
    main()

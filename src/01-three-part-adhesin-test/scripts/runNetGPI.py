import time
import requests
import pandas as pd
import sys
import glob
import os
from splitFasta import split_fasta

SERVER = "https://services.healthtech.dtu.dk/cgi-bin/webface2.fcgi"
CONFIG = "/var/www/html/services/NetGPI-1.1/webface.cf"
RESULT_BASE = "https://services.healthtech.dtu.dk/services/NetGPI-1.1/tmp"

def submit_netgpi(fasta_file):
    with open(fasta_file, "rb") as f:
        files = {
            "uploadfile": (
                fasta_file,
                f,
                "text/plain"
            )
        }

        data = {
            "configfile": CONFIG,
            "format": "short"
        }

        response = requests.post(
            SERVER,
            data=data,
            files=files,
            allow_redirects=False
        )

    response.raise_for_status()

    # The R code expects the job ID in the redirect URL.
    location = response.headers.get("Location")

    if not location or "jobid=" not in location:
        raise RuntimeError(
            f"Could not obtain job ID.\n"
            f"Status: {response.status_code}\n"
            f"Location: {location}\n"
            f"Response: {response.text[:500]}"
        )

    jobid = location.split("jobid=", 1)[1].split("&", 1)[0]

    return jobid


def wait_for_job(jobid, timeout=2500):
    start = time.time()

    while time.time() - start < timeout:

        response = requests.get(
            SERVER,
            params={
                "jobid": jobid,
                "wait": "20"
            }
        )

        response.raise_for_status()

        html = response.text

        if "Prediction summary" in html:
            return True

        time.sleep(1)

    return False


def download_results(jobid):
    url = (
        f"{RESULT_BASE}/{jobid}/"
        "output_protein_type.txt"
    )

    response = requests.get(url)
    response.raise_for_status()

    return response.text


def parse_results(text):
    from io import StringIO

    df = pd.read_csv(
        StringIO(text),
        sep="\t",
        header=None,
        usecols=range(5),
        names=[
            "id",
            "length",
            "is.gpi",
            "omega_site",
            "likelihood"
        ]
    )

    gpi_status = df["is.gpi"].astype("string")

    df["is.gpi"] = ~gpi_status.str.contains(
        "Not",
        regex=False,
        na=False
    )

    df["length"] = pd.to_numeric(df["length"])

    df["omega_site"] = (
        df["omega_site"]
        .replace("-", pd.NA)
    )

    df["omega_site"] = pd.to_numeric(
        df["omega_site"],
        errors="coerce"
    )

    df["likelihood"] = pd.to_numeric(
        df["likelihood"],
        errors="coerce"
    )

    return df

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python runNetGPI.py <fasta_file>")
        sys.exit(1)

    fastaFile = sys.argv[1]
    split_fasta(fastaFile, 5000)
    
    # Query NetGPI for each FASTA file
    jobids = []
    for infile in glob.glob("*_group_*.fasta"):
        print(f"Processing {infile}")
        jobid = submit_netgpi(infile)
        jobids.append(jobid)
        if not wait_for_job(jobid):
            raise RuntimeError("NetGPI job timed out")

    # Download results for each job
    for jobid in jobids:
        result_text = download_results(jobid)
        results = parse_results(result_text)
        print(results)

    # Remove each FASTA file after it is processed
    for infile in glob.glob("*_group_*.fasta"):
        os.remove(infile)
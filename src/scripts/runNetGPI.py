import time
import requests
import pandas as pd
import argparse
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
        header=1,
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


def main():
    parser = argparse.ArgumentParser(
        description="Run NetGPI on a FASTA file and save the results."
    )

    parser.add_argument(
        "fasta_file",
        help="Path to the input FASTA file"
    )

    parser.add_argument(
        "output_path",
        help="Path where the results should be saved"
    )

    args = parser.parse_args()

    # Convert paths to absolute paths
    fasta_file = os.path.abspath(args.fasta_file)
    output_path = os.path.abspath(args.output_path)

    input_dir = os.path.dirname(fasta_file)

    # Split the input FASTA
    split_fasta(fasta_file, 5000)

    # Find only the split files belonging to this input, from the same directory as the input.
    fasta_basename = os.path.splitext(
        os.path.basename(fasta_file)
    )[0]

    split_pattern = os.path.join(
        input_dir,
        f"{fasta_basename}_group_*.fasta"
    )

    split_files = glob.glob(split_pattern)

    if not split_files:
        raise RuntimeError(
            f"No split FASTA files found matching: {split_pattern}"
        )

    print(f"Found {len(split_files)} split FASTA files.")

    # Query NetGPI for each FASTA file
    jobids = []

    try:
        for infile in sorted(split_files):
            print(f"Processing {infile}")

            jobid = submit_netgpi(infile)
            jobids.append(jobid)

            if not wait_for_job(jobid):
                raise RuntimeError(
                    f"NetGPI job timed out: {jobid}"
                )

        # Download and combine results
        all_results = []

        for jobid in jobids:
            print(f"Downloading results for job {jobid}")

            result_text = download_results(jobid)
            results = parse_results(result_text)

            all_results.append(results)

        if not all_results:
            raise RuntimeError("No NetGPI results were produced.")

        final_results = pd.concat(
            all_results,
            ignore_index=True
        )

        # Create the output directory if it doesn't exist.
        output_dir = os.path.dirname(output_path)

        if output_dir:
            os.makedirs(output_dir, exist_ok=True)

        # Save results
        final_results.to_csv(
            output_path,
            sep="\t",
            index=False
        )

        print(
            f"Saved {len(final_results)} results to "
            f"{output_path}"
        )

    finally:
        # Always remove temporary split files, even if an error occurs.
        for infile in split_files:
            if os.path.exists(infile):
                os.remove(infile)
                print(f"Removed temporary file: {infile}")


if __name__ == "__main__":
    main()
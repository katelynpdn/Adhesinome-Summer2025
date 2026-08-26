from pathlib import Path

DATA_DIR = Path("data")

# Find all input proteomes in data/
SAMPLES = [
    p.stem
    for p in DATA_DIR.glob("*.fasta")
]

rule all:
    input:
        expand(
            "results/{sample}/seqList_all",
            sample=SAMPLES
        ),
        expand(
            "results/{sample}/seqList_other",
            sample=SAMPLES
        )

rule clean_fasta:
    input:
        fasta="data/{sample}.fasta"

    output:
        fasta="processed_data/{sample}_clean.fasta"

    script:
        "src/01-three-part-adhesin-test/scripts/fastaRemoveAmbiguity.py"


rule fungalrv:
    input:
        fasta="processed_data/{sample}_clean.fasta"

    output:
        output="results/{sample}/fungalrv_output"

    shell:
        r"""
        mkdir -p results/{wildcards.sample}

        cd src/01-three-part-adhesin-test/FungalRV_adhesin_predictor

        perl run_fungalrv_adhesin_predictor.pl \
            ../../../.. /processed_data/{wildcards.sample}_clean.fasta \
            ../../../../results/{wildcards.sample}/fungalrv_output \
            y
        """

rule predgpi:
    input:
        fasta="data/{sample}.fasta"

    output:
        output="results/{sample}/predgpi_output"

    shell:
        r"""
        mkdir -p results/{wildcards.sample}

        python src/01-three-part-adhesin-test/predgpi/predgpi.py \
            -f {input.fasta} \
            -m gff3 \
            -o {output.output}
        """

rule signalp:
    input:
        fasta="data/{sample}.fasta"

    output:
        output="results/{sample}/signalP_output"

    shell:
        r"""
        mkdir -p results/{wildcards.sample}

        src/01-three-part-adhesin-test/scripts/runSignalP.sh \
            {input.fasta}

        mv biolib_results/merged_prediction_results.txt \
            {output.output}
        """

rule process_fungalrv:
    input:
        "results/{sample}/fungalrv_output"

    output:
        "processed_data/{sample}_fungalrv_processed"

    shell:
        r"""
        tail -n +4 {input} > {output}
        """

rule process_signalp:
    input:
        "results/{sample}/signalP_output"

    output:
        "processed_data/{sample}_signalP_processed"

    shell:
        r"""
        grep -v '^#' {input} > {output}
        """

rule combine_results:
    input:
        fungalrv="processed_data/{sample}_fungalrv_processed",
        predgpi="results/{sample}/predgpi_output",
        signalp="processed_data/{sample}_signalP_processed"

    output:
        table="results/{sample}/proteinTable.csv"

    shell:
        r"""
        python src/01-three-part-adhesin-test/scripts/parse_all_output.py \
            {input.fungalrv} \
            {input.predgpi} \
            {input.signalp} \
            results/{wildcards.sample}/proteinTable
        """

rule extract_sequences:
    input:
        table="results/{sample}/proteinTable.csv",
        fasta="data/{sample}.fasta"

    output:
        all="results/{sample}/seqList_all",
        other="results/{sample}/seqList_other"

    shell:
        r"""
        python src/01-three-part-adhesin-test/scripts/extractSeq.py \
            {input.table} \
            {input.fasta} \
            results/{wildcards.sample}
        """
SAMPLES = [f"sample_{i:02d}" for i in range(1, 11)]

rule all:
    input:
        "results/summary.tsv",
        "results/qc_summary.tsv"

rule debug_bash:
    """Test shell conda tools on compute node"""
    output:
        "results/debug_bash.txt"
    shell:
        """
        set +euo pipefail
        echo "host=$(hostname)" > {output}
        echo "CONDA_DEFAULT_ENV=$CONDA_DEFAULT_ENV" >> {output}
        echo "CONDA_PREFIX=$CONDA_PREFIX" >> {output}
        echo "PATH=$PATH" >> {output}
        echo "seqkit=$(which seqkit 2>&1)" >> {output}
        seqkit version >> {output} 2>&1 || echo "seqkit FAILED" >> {output}
        exit 0
        """

rule debug_python:
    """Test python conda packages on compute node"""
    output:
        "results/debug_python.txt"
    run:
        import sys
        import socket

        lines = []
        lines.append(f"host={socket.gethostname()}")
        lines.append(f"python={sys.executable}")
        lines.append(f"version={sys.version}")
        lines.append(f"prefix={sys.prefix}")

        try:
            from Bio import SeqIO
            lines.append("biopython=OK")
        except ImportError as e:
            lines.append(f"biopython=FAIL: {e}")

        with open(output[0], 'w') as f:
            f.write("\n".join(lines) + "\n")

rule debug_all:
    """Combine debug results"""
    input:
        bash="results/debug_bash.txt",
        python="results/debug_python.txt"
    output:
        "results/debug.txt"
    shell:
        """
        echo "=== Bash ===" > {output}
        cat {input.bash} >> {output}
        echo "=== Python ===" >> {output}
        cat {input.python} >> {output}
        """

rule generate_reads:
    """Generate random FASTQ reads using BioPython"""
    output:
        "data/{sample}.fastq"
    resources:
        mem_mb=1000,
        runtime=5
    run:
        import random
        import socket
        from Bio.Seq import Seq
        from Bio.SeqRecord import SeqRecord
        from Bio import SeqIO

        print(f"Generating reads for {wildcards.sample} on {socket.gethostname()}")

        bases = "ACGT"
        records = []
        for i in range(1, 1001):
            seq = Seq("".join(random.choices(bases, k=100)))
            qual = [random.randint(20, 40) for _ in range(100)]
            record = SeqRecord(seq, id=f"read_{i}", description="")
            record.letter_annotations["phred_quality"] = qual
            records.append(record)

        SeqIO.write(records, output[0], "fastq")

rule count_bases:
    """Count base composition using BioPython"""
    input:
        "data/{sample}.fastq"
    output:
        "results/{sample}.counts.tsv"
    resources:
        mem_mb=1000,
        runtime=5
    run:
        from collections import Counter
        import socket
        from Bio import SeqIO

        counts = Counter()
        for record in SeqIO.parse(input[0], "fastq"):
            counts.update(str(record.seq))

        with open(output[0], 'w') as f:
            f.write(f"sample\thost\tA\tC\tG\tT\n")
            f.write(f"{wildcards.sample}\t{socket.gethostname()}\t")
            f.write(f"{counts['A']}\t{counts['C']}\t{counts['G']}\t{counts['T']}\n")

rule qc_reads:
    """QC stats using seqkit (tests shell conda tool)"""
    input:
        "data/{sample}.fastq"
    output:
        "results/{sample}.qc.tsv"
    resources:
        mem_mb=1000,
        runtime=5
    shell:
        "seqkit stats -T {input} > {output}"

rule aggregate:
    """Combine base counts and QC stats"""
    input:
        counts=expand("results/{sample}.counts.tsv", sample=SAMPLES),
        qc=expand("results/{sample}.qc.tsv", sample=SAMPLES)
    output:
        counts="results/summary.tsv",
        qc="results/qc_summary.tsv"
    resources:
        mem_mb=500,
        runtime=5
    shell:
        """
        echo "sample\thost\tA\tC\tG\tT" > {output.counts}
        for f in {input.counts}; do
            tail -n1 $f >> {output.counts}
        done

        head -n1 {input.qc[0]} > {output.qc}
        for f in {input.qc}; do
            tail -n1 $f >> {output.qc}
        done

        echo "=== Base Counts ===" && cat {output.counts}
        echo "=== QC Stats ===" && cat {output.qc}
        """

#!/bin/bash
# Submit to LSF and return just the job ID
# Conda env activation handled by ~/.bashrc on compute nodes
# bsub outputs: "Job <12345> is submitted to queue <normal>."
# snakemake needs just: "12345"

output=$(bsub "$@" 2>&1)
echo "$output" | sed 's/Job <\([0-9]*\)>.*/\1/'

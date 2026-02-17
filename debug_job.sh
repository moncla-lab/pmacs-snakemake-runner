#!/bin/bash
# Usage: ~/debug_job.sh JOBID
# Collects all diagnostic info for a failed snakemake job

JOBID=$1

if [ -z "$JOBID" ]; then
    echo "Usage: $0 JOBID"
    exit 1
fi

OUT=~/debug_report_${JOBID}.txt

{
    echo "===== DEBUG REPORT FOR JOB $JOBID ====="
    echo "Generated: $(date)"
    echo "Host: $(hostname)"
    echo "Conda env: $CONDA_DEFAULT_ENV"
    echo ""

    echo "===== JOB DETAILS ====="
    bjobs -l "$JOBID" 2>&1
    echo ""

    echo "===== JOB HISTORY ====="
    bhist -l "$JOBID" 2>&1
    echo ""

    echo "===== RESULTS DIR ====="
    ls -la ~/results/ 2>&1
    echo ""

    echo "===== LOGS DIR ====="
    ls -la ~/logs/ 2>&1
    echo ""

    echo "===== LSF LOG FILES (relative) ====="
    for f in ~/logs/*"$JOBID"* ~/logs/debug_*; do
        if [ -f "$f" ]; then
            echo "--- $f ---"
            cat "$f"
        fi
    done
    echo ""

    echo "===== LSF LOG FILES (absolute) ====="
    for f in ~/logs/debug_*; do
        if [ -f "$f" ]; then
            echo "--- $f ---"
            cat "$f"
        fi
    done
    echo ""

    echo "===== JOBSCRIPT FILES ====="
    ls -la ~/.snakemake/tmp.*/snakejob.*.sh 2>&1
    echo ""

    echo "===== JOBSCRIPT CONTENTS ====="
    for f in ~/.snakemake/tmp.*/snakejob.*.sh; do
        if [ -f "$f" ]; then
            echo "--- $f ---"
            cat "$f"
            echo ""
        fi
    done

    echo "===== SNAKEMAKE LOG (last 50 lines) ====="
    LATEST_LOG=$(ls -t ~/.snakemake/log/*.snakemake.log 2>/dev/null | head -1)
    if [ -n "$LATEST_LOG" ]; then
        echo "--- $LATEST_LOG ---"
        tail -50 "$LATEST_LOG"
    else
        echo "No snakemake logs found"
    fi

} > "$OUT" 2>&1

echo "Report written to $OUT"
echo "Run: cat $OUT"

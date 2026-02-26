# Snakemake + Conda on PMACS LSF

A general-purpose [Snakemake global profile](https://snakemake.readthedocs.io/en/stable/executing/cli.html#profiles) for running conda-dependent workflows on the PMACS HPC cluster (IBM Spectrum LSF 10.1) via the [cluster-generic executor](https://snakemake.github.io/snakemake-plugin-catalog/plugins/executor/cluster-generic.html). It provides default submission, status, and cancellation commands so you can run **any** Snakemake pipeline on PMACS without editing the pipeline itself. Supports both Python (`run:`) and shell (`shell:`) Snakemake directives with full access to conda-installed tools.

To maximize resource utilization, combine this profile with a pipeline-specific [workflow profile](https://snakemake.readthedocs.io/en/stable/executing/cli.html#profiles), or at minimum pass `--jobs N` to control how many LSF jobs Snakemake submits concurrently.

### Configuration Priorities

When a setting is defined in multiple places, higher-priority sources override lower ones:

1. **Command-line arguments** — explicit flags like `--jobs 20` always win.
2. **Workflow profile** — a `profiles/default/config.yaml` inside the pipeline directory ([docs](https://snakemake.readthedocs.io/en/stable/executing/cli.html#profiles)).
3. **Global profile** — the profile passed via `--profile` or the `SNAKEMAKE_PROFILE` environment variable (i.e., this repo).
4. **Snakemake defaults** — built-in fallback values.

### Usage Options

**Option A — Specify the profile each run (recommended)**

```bash
snakemake --profile ~/pmacs-snakemake-runner/profile
```

Best when you work across different clusters or need different profiles for different projects.

**Option B — Set as your default profile**

Add this to your `~/.bashrc`:

```bash
export SNAKEMAKE_PROFILE="~/pmacs-snakemake-runner/profile"
```

After sourcing, plain `snakemake` will use this profile automatically. Command-line flags and workflow profiles still take precedence.

## Quick Start

### 1. Setup

SSH to the cluster:

```bash
ssh consign.pmacs.upenn.edu
```

Clone the repository:

```bash
git clone https://github.com/moncla-lab/pmacs-snakemake-runner
```

Note that it is required for this to be cloned in your home directory. At present, paths in the submit and status scripts are absolute.

### Transferring Data

To copy files to or from the cluster with `scp` or `rsync`, use `mercury.pmacs.upenn.edu` — **not** `consign`. `consign` is the login node for interactive SSH sessions, but file transfers go through `mercury`:

```bash
# from your local machine
scp mydata.fastq youruser@mercury.pmacs.upenn.edu:~/data/
rsync -avz local_folder/ youruser@mercury.pmacs.upenn.edu:~/data/
```

Both hosts share the same home directory, so files you transfer to `mercury` will be visible when you SSH into `consign`.

### Configure Conda

You need to edit a file called `~/.bashrc`. Here's what you need to know:

- `~` is shorthand for your home directory (e.g. `/home/youruser`)
- `.bashrc` is a hidden file (the `.` prefix means it won't show up in a normal `ls` — use `ls -a` to see it)
- `.bashrc` is a shell startup script — it runs automatically every time a new shell session starts, including when you log in and when an LSF job starts on a compute node
- This is how we make sure conda tools are available everywhere, not just on the login node

Open the file with nano (see the [nano tutorial](#editing-files-with-nano) below if you haven't used it before):

```bash
nano ~/.bashrc
```

Scroll to the bottom of the file. You should see a block that looks like this (it was added when conda/miniforge was installed):

```bash
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
...
# <<< conda initialize <<<
```

**After** that block (as the very last line of the file), add:

```bash
conda activate $ENVIRONMENT
```

where `$ENVIRONMENT` is the name of the conda environment that runs your Snakemake pipeline. For example, if your environment is called `snakemake`:

```bash
conda activate snakemake
```

Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`). The next time you log in or an LSF job starts, this environment will activate automatically... check this before running!

### 2. Run a Workflow

You can either get an interactive shell on a compute node like so:

```
bsub -Is -q interactive bash
cd /path/to/your/snakemake/pipeline
snakemake --profile ~/pmacs-snakemake-runner/profile ...
```

Or write a submission script so snakemake runs as a batch job (useful for long workflows you don't want to babysit):

```bash
#!/bin/bash
#BSUB -J snakemake_runner
#BSUB -q normal
#BSUB -o ~/logs/snakemake_runner.out
#BSUB -e ~/logs/snakemake_runner.err
#BSUB -M 4096
#BSUB -R "rusage[mem=4096]"

snakemake --profile ~/pmacs-snakemake-runner/profile ...
```

Submit it with:

```bash
bsub < run_snakemake.sh
```

This launches Snakemake itself as an LSF job. Snakemake then submits each rule as its own sub-job. The runner job stays alive to poll status and coordinate — it uses minimal resources but needs to run for the duration of the workflow.

## Built-in Debug Rules

The `Snakefile` in this repository includes three debug rules that are used for testing the types of rules we support. Use them to verify the conda environment works on compute nodes:

```bash
# Test bash tools (like seqkit)
snakemake --profile ~/profile results/debug_bash.txt

# Test Python packages (like biopython)
snakemake --profile ~/profile results/debug_python.txt

# Both, combined into one file... add more as necessary
snakemake --profile ~/profile results/debug.txt
```

## Editing Files with nano

nano is a simple command line interface text editor. To open a file:

```bash
nano ~/.bashrc
```

- **Navigate**: Arrow keys
- **Edit**: Just type — there are no modes
- **Save**: `Ctrl+O`, then `Enter` to confirm the filename
- **Exit**: `Ctrl+X` (if you have unsaved changes, it will ask to save first), confirm changes with Y or N, hit enter to exit and return to the command line
- **Cancel a prompt**: `Ctrl+C`

The bottom of the screen always shows available commands. `^` means `Ctrl`.
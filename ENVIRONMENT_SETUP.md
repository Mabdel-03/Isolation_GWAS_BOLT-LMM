# Environment Setup Guide

## Quick Setup on HPC (Copy-Paste Command)

Create the conda environment in one command:

```bash
conda create -p /home/mabdel03/data/conda_envs/bolt_lmm \
  -c conda-forge -c bioconda \
  python=3.10 \
  plink2 \
  bcftools \
  samtools \
  htslib \
  pandas \
  numpy \
  scipy \
  matplotlib \
  seaborn \
  jupyter \
  notebook \
  scikit-learn \
  statsmodels \
  r-base=4.2 \
  r-essentials \
  r-tidyverse \
  r-data.table \
  r-ggplot2 \
  r-devtools \
  zlib \
  gzip \
  bzip2 \
  xz \
  parallel \
  pigz \
  -y
```

**Activate the environment:**
```bash
conda activate /home/mabdel03/data/conda_envs/bolt_lmm
```

**Test installation:**
```bash
plink2 --version
python --version
R --version
```

---

## Alternative: Using environment.yml File

If you prefer using the specification file:

```bash
# Clone the repository (if not already done)
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/
git clone https://github.com/Mabdel-03/Isolation_GWAS_BOLT-LMM.git

# Create environment from file
cd Isolation_GWAS_BOLT-LMM
conda env create -f environment.yml -p /home/mabdel03/data/conda_envs/bolt_lmm

# Activate
conda activate /home/mabdel03/data/conda_envs/bolt_lmm
```

---

## Included Packages

### Genetics/Bioinformatics Tools
- **PLINK2**: Genotype file conversion, QC, LD pruning
- **BCFtools**: VCF/BCF file manipulation
- **SAMtools**: Sequence alignment manipulation
- **HTSlib**: High-throughput sequencing data library

### Python Stack
- **Python 3.10**: Programming language
- **pandas**: Data manipulation and analysis
- **NumPy**: Numerical computing
- **SciPy**: Scientific computing
- **matplotlib**: Plotting and visualization
- **seaborn**: Statistical data visualization
- **Jupyter**: Interactive notebooks
- **scikit-learn**: Machine learning utilities
- **statsmodels**: Statistical modeling

### R Stack
- **R 4.2**: R programming language
- **tidyverse**: Data manipulation (dplyr, tidyr, ggplot2, etc.)
- **data.table**: Fast data manipulation
- **ggplot2**: Advanced plotting
- **devtools**: Package development tools

### Utilities
- **parallel**: GNU parallel for job parallelization
- **pigz**: Parallel gzip for faster compression
- **gzip, bzip2, xz**: Compression tools

---

## Installing BOLT-LMM (Not in Conda)

BOLT-LMM must be installed separately:

### Download and Install

```bash
# Navigate to software directory
cd /home/mabdel03/software/
# or wherever you keep software

# Download BOLT-LMM
wget https://storage.googleapis.com/broad-alkesgroup-public/BOLT-LMM/downloads/BOLT-LMM_v2.4.1.tar.gz

# Extract
tar -xzf BOLT-LMM_v2.4.1.tar.gz

# Test installation
cd BOLT-LMM_v2.4.1
./bolt --help

# Add to PATH (add to your ~/.bashrc)
export PATH="/home/mabdel03/software/BOLT-LMM_v2.4.1:$PATH"
```

### Update Scripts

After installing BOLT-LMM, update `bolt_lmm.sh`:

```bash
# Edit bolt_lmm.sh around lines 100-110
nano bolt_lmm.sh

# Update these paths:
ld_scores_file="/home/mabdel03/software/BOLT-LMM_v2.4.1/tables/LDSCORE.1000G_EUR.tab.gz"
genetic_map_file="/home/mabdel03/software/BOLT-LMM_v2.4.1/tables/genetic_map_hg19_withX.txt.gz"
```

---

## Updating Your Scripts to Use This Environment

Update the conda activation in your scripts:

### Option 1: Update Individual Scripts

Edit `bolt_lmm.sh`, `1a_bolt_lmm.sbatch.sh`, etc.:

```bash
# Replace these lines (around lines 14-16):
# module load miniconda3/v4
# source /home/software/conda/miniconda3/bin/condainit
# conda activate /home/mabdel03/data/conda_envs/GWAS_env

# With:
conda activate /home/mabdel03/data/conda_envs/bolt_lmm
```

### Option 2: Create Module Loading Script

Create a helper script:

```bash
# Create load_env.sh
cat > load_env.sh << 'EOF'
#!/bin/bash
# Load conda environment for BOLT-LMM analysis
module load miniconda3/v4
source /home/software/conda/miniconda3/bin/condainit
conda activate /home/mabdel03/data/conda_envs/bolt_lmm
EOF

chmod +x load_env.sh

# Then in your scripts, just use:
source ./load_env.sh
```

---

## Verifying Installation

```bash
# Activate environment
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

# Test key tools
plink2 --version
# Expected: PLINK v2.00a...

python -c "import pandas; print(pandas.__version__)"
# Expected: 1.5.x or higher

R --version
# Expected: R version 4.2.x

bcftools --version
# Expected: bcftools 1.x

# Test compression tools
pigz --version
parallel --version

# Check environment info
conda list
conda info --envs
```

---

## Troubleshooting

### Environment Creation Fails

If you get package conflicts:

```bash
# Try with more relaxed solving
conda create -p /home/mabdel03/data/conda_envs/bolt_lmm \
  -c conda-forge -c bioconda \
  --override-channels \
  python=3.10 plink2 pandas numpy scipy -y

# Then install remaining packages
conda install -p /home/mabdel03/data/conda_envs/bolt_lmm \
  -c conda-forge -c bioconda \
  r-base=4.2 r-tidyverse -y
```

### PLINK2 Not Found

```bash
# Install separately
conda install -p /home/mabdel03/data/conda_envs/bolt_lmm \
  -c bioconda plink2 -y
```

### R Packages Missing

```bash
# Activate environment
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

# Install additional R packages
R -e "install.packages('package_name', repos='http://cran.rstudio.com/')"
```

### Environment Activation Issues

If `conda activate` doesn't work:

```bash
# Use full path
source activate /home/mabdel03/data/conda_envs/bolt_lmm

# Or initialize conda for your shell
conda init bash
# Then restart shell and try again
```

---

## Environment Management

### List Installed Packages
```bash
conda activate /home/mabdel03/data/conda_envs/bolt_lmm
conda list
```

### Update Environment
```bash
conda update -p /home/mabdel03/data/conda_envs/bolt_lmm --all -y
```

### Export Environment (for reproducibility)
```bash
conda activate /home/mabdel03/data/conda_envs/bolt_lmm
conda env export > environment_snapshot.yml
```

### Remove Environment (if needed)
```bash
conda deactivate
conda env remove -p /home/mabdel03/data/conda_envs/bolt_lmm
```

---

## Adding to Your .bashrc (Optional)

For easier activation, add to `~/.bashrc`:

```bash
# Add these lines
export BOLT_ENV="/home/mabdel03/data/conda_envs/bolt_lmm"

# Alias for quick activation
alias bolt_env="conda activate /home/mabdel03/data/conda_envs/bolt_lmm"

# Auto-load for BOLT-LMM directory
if [[ "$PWD" == *"Isolation_GWAS_BOLT-LMM"* ]]; then
    conda activate /home/mabdel03/data/conda_envs/bolt_lmm
fi
```

Then reload:
```bash
source ~/.bashrc
```

---

## Summary

**Quick Start:**
1. Run the one-line conda create command above
2. Activate: `conda activate /home/mabdel03/data/conda_envs/bolt_lmm`
3. Install BOLT-LMM separately (not in conda)
4. Update scripts to use new environment
5. Test: `plink2 --version && python --version`

**You're ready to run the GWAS!** 🚀


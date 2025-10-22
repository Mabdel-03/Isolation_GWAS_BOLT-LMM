#!/bin/bash
#SBATCH --job-name=convert_to_bed
#SBATCH --partition=kellis
#SBATCH --mem=32G
#SBATCH -n 8
#SBATCH --time=2:00:00
#SBATCH --output=%x.%j.out
#SBATCH --error=%x.%j.err

set -beEo pipefail

# SLURM batch script to convert PLINK2 pgen files to PLINK1 bed/bim/fam format for BOLT-LMM
# Note: Removed -u flag due to Qt conda package activation issues

echo "========================================"
echo "Job: Convert genotypes to BED format"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Start time: $(date)"
echo "========================================"

REPODIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942"
ukb21942_d='/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'

source "${REPODIR}/helpers/functions.sh"

# Activate conda environment
module load miniconda3/v4
source /home/software/conda/miniconda3/bin/condainit
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

# Input and output paths
genotype_dir="${ukb21942_d}/geno/ukb_genoHM3"
input_pfile="${genotype_dir}/ukb_genoHM3"
output_bfile="${genotype_dir}/ukb_genoHM3_bed"

echo "Converting genotype files for BOLT-LMM v2.5..."
echo "Input:  ${input_pfile}.pgen/pvar/psam"
echo "Output: ${output_bfile}.bed/bim/fam"

# Check if output already exists
if [ -s "${output_bfile}.bed" ] && [ -s "${output_bfile}.bim" ] && [ -s "${output_bfile}.fam" ] ; then
    echo "BED format files already exist: ${output_bfile}.bed/bim/fam"
    echo "To regenerate, delete these files and run this script again."
    exit 0
fi

# Check if input files exist
if [ ! -s "${input_pfile}.pgen" ] ; then
    echo "ERROR: Input pgen file not found: ${input_pfile}.pgen" >&2
    echo "This script should be run on the HPC where the data files are located." >&2
    exit 1
fi

# Convert pgen to bed
# IMPORTANT: Only include autosomes (chr 1-22) to avoid BOLT-LMM chromosome code errors
# BOLT-LMM doesn't recognize MT, X, Y, XY chromosome codes
echo "Running conversion (this may take a while for large datasets)..."
echo "Converting AUTOSOMES ONLY (chr 1-22) for BOLT-LMM compatibility"

plink2 \
    --pfile ${input_pfile} vzs \
    --chr 1-22 \
    --make-bed \
    --out ${output_bfile} \
    --threads ${SLURM_CPUS_PER_TASK} \
    --memory ${SLURM_MEM_PER_NODE}

# Verify output
if [ -s "${output_bfile}.bed" ] && [ -s "${output_bfile}.bim" ] && [ -s "${output_bfile}.fam" ] ; then
    echo "Conversion completed successfully!"
    echo "Output files:"
    ls -lh ${output_bfile}.bed
    ls -lh ${output_bfile}.bim
    ls -lh ${output_bfile}.fam
    
    # Count variants and samples
    n_variants=$(wc -l < ${output_bfile}.bim)
    n_samples=$(wc -l < ${output_bfile}.fam)
    echo "Number of variants: ${n_variants}"
    echo "Number of samples: ${n_samples}"
    
else
    echo "ERROR: Conversion failed" >&2
    exit 1
fi

echo ""
echo "========================================"
echo "Conversion complete!"
echo "End time: $(date)"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Run: sbatch 0b_prepare_model_snps.sbatch.sh"
echo "2. Then test with: sbatch 0c_test_run.sbatch.sh"


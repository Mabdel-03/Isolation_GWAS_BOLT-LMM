#!/bin/bash
#SBATCH --job-name=model_snps
#SBATCH --partition=kellis
#SBATCH --mem=80G
#SBATCH -n 8
#SBATCH --time=2:00:00
#SBATCH --output=%x.%j.out
#SBATCH --error=%x.%j.err

set -beEo pipefail

# SLURM batch script to prepare model SNPs for BOLT-LMM
# Note: Removed -u flag due to Qt conda package activation issues
# Model SNPs are a subset of common, well-imputed variants used to compute the genetic relationship matrix

echo "========================================"
echo "Job: Prepare Model SNPs for GRM"
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

# Input genotype files
genotype_dir="${ukb21942_d}/geno/ukb_genoHM3"
genotype_pfile="${genotype_dir}/ukb_genoHM3"

# Output model SNPs file
output_snplist="${genotype_dir}/ukb_genoHM3_modelSNPs.txt"
output_prefix="${genotype_dir}/ukb_genoHM3_modelSNPs"

echo "Preparing model SNPs for BOLT-LMM..."
echo "Input: ${genotype_pfile}"
echo "Output: ${output_snplist}"

# Check if output already exists
if [ -s "${output_snplist}" ] ; then
    echo "Model SNPs file already exists: ${output_snplist}"
    echo "To regenerate, delete the file and run this script again."
    exit 0
fi

# Create LD-pruned SNP list
# Criteria for model SNPs (optimized for HM3 variant set):
# - MAF >= 0.5% (--maf 0.005)
# - Missingness < 10% (--geno 0.10)
# - HWE with sample-size adjustment (--hwe 1e-5 0.001 keep-fewhet)
# - LD pruning: window=1000kb, step=50, r2<0.5 (--indep-pairwise 1000 50 0.5)
#   Relaxed to r2<0.5 to retain sufficient SNPs from HM3 set
# - Autosomes only (--chr 1-22)
#
# Note: For GRM computation in large biobank datasets, r2<0.5 is acceptable
# Model SNPs don't need strict LD independence - moderate LD is fine
# Previous attempt with r2<0.2 yielded only 243K SNPs (too few)
# BOLT-LMM recommends 400K-600K SNPs for optimal GRM estimation

echo "Running LD pruning to select model SNPs..."
echo "This may take a while..."
echo "Memory allocated: ${SLURM_MEM_PER_NODE}MB"
echo "Target: 400K-600K model SNPs for GRM computation"
echo "Starting with ~1.3M HM3 variants after QC filters"

plink2 \
    --pfile ${genotype_pfile} vzs \
    --chr 1-22 \
    --maf 0.005 \
    --geno 0.10 \
    --hwe 1e-5 0.001 keep-fewhet \
    --indep-pairwise 1000 50 0.5 \
    --out ${output_prefix} \
    --threads ${SLURM_NTASKS} \
    --memory 80000

# The above command creates two files:
# - ${output_prefix}.prune.in  (SNPs to keep)
# - ${output_prefix}.prune.out (SNPs to exclude)

# Rename the .prune.in file to our target name
if [ -s "${output_prefix}.prune.in" ] ; then
    mv "${output_prefix}.prune.in" "${output_snplist}"
    echo "Model SNPs file created: ${output_snplist}"
    
    # Count SNPs
    n_snps=$(wc -l < "${output_snplist}")
    echo "Number of model SNPs: ${n_snps}"
    
    # BOLT-LMM typically uses 400K-600K SNPs for the GRM
    if [ ${n_snps} -lt 300000 ] ; then
        echo "WARNING: Fewer than 300K model SNPs. Consider relaxing filters." >&2
    elif [ ${n_snps} -gt 700000 ] ; then
        echo "WARNING: More than 700K model SNPs. Consider stricter LD pruning." >&2
    else
        echo "Model SNP count is in the recommended range (300K-700K)."
    fi
    
    # Clean up temporary files
    if [ -s "${output_prefix}.prune.out" ] ; then
        rm "${output_prefix}.prune.out"
    fi
    if [ -s "${output_prefix}.log" ] ; then
        echo "LD pruning log saved to: ${output_prefix}.log"
    fi
    
else
    echo "ERROR: Failed to create model SNPs file" >&2
    exit 1
fi

echo ""
echo "========================================"
echo "Model SNPs preparation complete!"
echo "End time: $(date)"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Run test: sbatch 0c_test_run.sbatch.sh"
echo "2. If test succeeds, run full analysis: bash 1a_bolt_lmm.sbatch.sh"


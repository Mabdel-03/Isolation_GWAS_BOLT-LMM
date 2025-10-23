#!/bin/bash
#SBATCH --job-name=bolt_lmm
#SBATCH --partition=kellis
#SBATCH --mem=150G
#SBATCH -n 100
#SBATCH --time=47:00:00
#SBATCH --output=1_%a.out
#SBATCH --error=1_%a.err
#SBATCH --array=1-6
#SBATCH --mail-user=mabdel03@mit.edu
#SBATCH --mail-type=BEGIN,END,FAIL,ARRAY_TASKS

set -beEo pipefail

# Simplified BOLT-LMM GWAS: 6 jobs total (3 phenotypes × 2 covariate sets)
# No variant splitting - each job processes the full genome

echo "========================================"
echo "BOLT-LMM GWAS Analysis"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Array Task ID: ${SLURM_ARRAY_TASK_ID}"
echo "Node: ${SLURM_NODELIST}"
echo "Start time: $(date)"
echo "========================================"

# Activate conda environment
module load miniconda3/v4
source /home/software/conda/miniconda3/bin/condainit
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

# Navigate to analysis directory
SRCDIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM"
cd ${SRCDIR}

# Define phenotypes and covariate sets
phenotypes=(Loneliness FreqSoc AbilityToConfide)
covar_sets=(Day_NoPCs Day_10PCs)

# Map array task ID to phenotype and covariate combination
# Task 1-3: Day_NoPCs with each phenotype
# Task 4-6: Day_10PCs with each phenotype

if [ ${SLURM_ARRAY_TASK_ID} -le 3 ]; then
    covar_str="Day_NoPCs"
    pheno_idx=$((SLURM_ARRAY_TASK_ID - 1))
else
    covar_str="Day_10PCs"
    pheno_idx=$((SLURM_ARRAY_TASK_ID - 4))
fi

phenotype=${phenotypes[$pheno_idx]}

echo "Processing:"
echo "  Phenotype: ${phenotype}"
echo "  Covariate set: ${covar_str}"
echo ""

# Run BOLT-LMM using the simplified workflow script
bash ${SRCDIR}/run_single_phenotype.sh ${phenotype} ${covar_str}

# Check if successful
exit_code=$?

echo ""
echo "========================================"
if [ ${exit_code} -eq 0 ]; then
    echo "✅ SUCCESS: ${phenotype} with ${covar_str}"
else
    echo "❌ FAILED: ${phenotype} with ${covar_str}"
    echo "Exit code: ${exit_code}"
fi
echo "End time: $(date)"
echo "========================================"

exit ${exit_code}


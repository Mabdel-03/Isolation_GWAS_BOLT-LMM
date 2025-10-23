#!/bin/bash
#SBATCH --job-name=bolt_test_simple
#SBATCH --partition=kellis
#SBATCH --mem=150G
#SBATCH -n 100
#SBATCH --time=6:00:00
#SBATCH --output=%x.%j.out
#SBATCH --error=%x.%j.err
#SBATCH --mail-user=mabdel03@mit.edu
#SBATCH --mail-type=BEGIN,END,FAIL

set -beEo pipefail

# Simplified test run: One phenotype, full genome

echo "========================================"
echo "BOLT-LMM Simplified Test Run"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Resources: 150GB RAM, 100 tasks"
echo "Start time: $(date)"
echo "========================================"

# Activate conda environment
module load miniconda3/v4
source /home/software/conda/miniconda3/bin/condainit
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

# Navigate to analysis directory
SRCDIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM"
cd ${SRCDIR}

echo ""
echo "Testing with Loneliness phenotype, Day_NoPCs covariate set"
echo "This tests the full pipeline on the complete genome (~1.3M variants)"
echo ""

# Clean up any previous test outputs
echo "Removing any previous test outputs..."
rm -f ${SRCDIR}/results/Day_NoPCs/EUR/bolt_Loneliness.Day_NoPCs.stats*
rm -f ${SRCDIR}/results/Day_NoPCs/EUR/bolt_Loneliness.Day_NoPCs.log*
echo "✓ Ready for clean test run"
echo ""

# Run test
bash run_single_phenotype.sh Loneliness Day_NoPCs

test_exit=$?

echo ""
echo "========================================"
if [ ${test_exit} -eq 0 ]; then
    echo "🎉 TEST PASSED!"
    echo ""
    echo "Verification:"
    ls -lh results/Day_NoPCs/EUR/bolt_Loneliness.Day_NoPCs.stats.gz
    ls -lh results/Day_NoPCs/EUR/bolt_Loneliness.Day_NoPCs.log.gz
    echo ""
    echo "Next steps:"
    echo "1. Review the output files and log"
    echo "2. Check for any warnings or issues"
    echo "3. If everything looks good, submit full analysis:"
    echo "   sbatch 1_run_bolt_lmm.sbatch.sh"
    echo ""
else
    echo "❌ TEST FAILED"
    echo "Check error messages above"
    echo "Do NOT proceed to full analysis"
    exit 1
fi

echo "End time: $(date)"
echo "========================================"


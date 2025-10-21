#!/bin/bash
#SBATCH --job-name=bolt_test
#SBATCH --partition=kellis
#SBATCH --mem=45000
#SBATCH --cpus-per-task=8
#SBATCH --time=6:00:00
#SBATCH --output=%x.%j.out
#SBATCH --error=%x.%j.err

set -beEo pipefail

# SLURM batch script for BOLT-LMM test run
# Tests the complete pipeline with a single variant split
# Note: Removed -u flag due to Qt conda package activation issues

echo "========================================"
echo "Job: BOLT-LMM Test Run"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Start time: $(date)"
echo "========================================"

# Activate conda environment
module load miniconda3/v4
source /home/software/conda/miniconda3/bin/condainit
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

# Navigate to analysis directory
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM

echo ""
echo "Running test with variant split 1, Day_NoPCs, EUR population..."
echo "This will process all 3 phenotypes: Loneliness, FreqSoc, AbilityToConfide"
echo ""

# Run the test
bash bolt_lmm.sh isolation_run_control BOLT 5,6,9 8 45000 Day_NoPCs EUR 1

# Check if test succeeded
SRCDIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM"
test_output_dir="${SRCDIR}/results/Day_NoPCs/EUR/var_split"

echo ""
echo "========================================"
echo "Test run complete!"
echo "End time: $(date)"
echo "========================================"
echo ""
echo "Checking output files..."

success=true
for pheno in Loneliness FreqSoc AbilityToConfide; do
    stats_file=$(find ${test_output_dir} -name "*${pheno}.BOLT.stats.gz" 2>/dev/null | head -1)
    log_file=$(find ${test_output_dir} -name "*${pheno}.BOLT.log.gz" 2>/dev/null | head -1)
    
    if [ -s "${stats_file}" ] && [ -s "${log_file}" ]; then
        echo "✅ ${pheno}: SUCCESS"
        n_variants=$(zcat "${stats_file}" 2>/dev/null | tail -n +2 | wc -l)
        echo "   Variants: ${n_variants}"
    else
        echo "❌ ${pheno}: FAILED - output files missing"
        success=false
    fi
done

echo ""
if [ "$success" = true ]; then
    echo "🎉 TEST PASSED! All phenotypes completed successfully."
    echo ""
    echo "Next steps:"
    echo "1. Review the output files in: ${test_output_dir}"
    echo "2. Check log files for any warnings"
    echo "3. If everything looks good, run full analysis:"
    echo "   bash 1a_bolt_lmm.sbatch.sh"
else
    echo "⚠️  TEST FAILED! Check error logs:"
    echo "   ${SLURM_JOB_NAME}.${SLURM_JOB_ID}.err"
    echo ""
    echo "Common issues:"
    echo "- Check that genotype files are converted to BED format"
    echo "- Check that model SNPs file exists"
    echo "- Check that BOLT-LMM paths are correct in bolt_lmm.sh"
    echo "- Check phenotype and covariate files"
    exit 1
fi


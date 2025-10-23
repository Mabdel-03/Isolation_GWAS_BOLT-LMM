#!/bin/bash
set -beEo pipefail

# Test BOLT-LMM WITHOUT --remove filter
# This helps diagnose if EUR.remove is causing the "0 individuals" issue

REPODIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942"
ukb21942_d='/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'

echo "========================================"
echo "Test BOLT-LMM WITHOUT ancestry filtering"
echo "========================================"
echo ""
echo "This will help diagnose if EUR.remove is causing the issue"
echo ""

genotype_bfile="${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_bed"
model_snps_file="${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_modelSNPs.txt"
ld_scores_file="/home/mabdel03/data/software/BOLT-LMM_v2.5/tables/LDSCORE.1000G_EUR.GRCh38.tab.gz"
genetic_map_file="/home/mabdel03/data/software/BOLT-LMM_v2.5/tables/genetic_map_hg19_withX.txt.gz"

echo "Running BOLT-LMM WITHOUT --remove filter..."
echo "This will use ALL samples in phenotype/covariate files"
echo ""

bolt \
    --bfile=${genotype_bfile} \
    --phenoFile=${ukb21942_d}/pheno/isolation_run_control.tsv.gz \
    --phenoCol=Loneliness \
    --covarFile=${ukb21942_d}/sqc/sqc.20220316.tsv.gz \
    --qCovarCol=age \
    --covarCol=sex,array \
    --covarMaxLevels=30 \
    --modelSnps=${model_snps_file} \
    --LDscoresFile=${ld_scores_file} \
    --geneticMapFile=${genetic_map_file} \
    --lmm \
    --LDscoresMatchBp \
    --numThreads=4 \
    --statsFile=/tmp/test_no_filter.stats \
    --verboseStats \
    2>&1 | tee /tmp/test_no_filter.log

exit_code=$?

echo ""
echo "========================================"
if [ $exit_code -eq 0 ]; then
    echo "✅ SUCCESS without --remove filter"
    echo ""
    echo "This means:"
    echo "1. The phenotype/covariate files may already be EUR-filtered, OR"
    echo "2. The EUR.remove file has an ID matching issue"
    echo ""
    echo "Check the log for sample counts:"
    grep -A 5 "Total indivs" /tmp/test_no_filter.log
    echo ""
    echo "If you see many individuals (>400K), the files are NOT EUR-filtered"
    echo "and we need to fix the EUR.remove file."
    echo ""
    echo "If you see ~450K individuals, the files ARE already EUR-filtered"
    echo "and we can skip the --remove step entirely."
else
    echo "❌ FAILED even without --remove filter"
    echo ""
    echo "This suggests a more fundamental issue:"
    echo "- Sample ID mismatch between files"
    echo "- Missing columns in phenotype/covariate files"
    echo "- Genotype file corruption"
    echo ""
    echo "Check the log:"
    cat /tmp/test_no_filter.log | tail -50
fi
echo "========================================"


#!/bin/bash
set -beEo pipefail

# Minimal BOLT-LMM test to isolate command line argument issues

REPODIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942"
ukb21942_d='/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'

echo "========================================"
echo "Minimal BOLT-LMM Test"
echo "========================================"

# Test 1: BOLT help (should always work)
echo "Test 1: Can we run BOLT at all?"
bolt --help > /dev/null 2>&1 && echo "✓ BOLT executable works" || echo "✗ BOLT not found/working"

# Test 2: Verify file paths
echo ""
echo "Test 2: Checking file paths..."

genotype_bfile="${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_bed"
model_snps_file="${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_modelSNPs.txt"
ld_scores_file="/home/mabdel03/data/software/BOLT-LMM_v2.5/tables/LDSCORE.1000G_EUR.GRCh38.tab.gz"
genetic_map_file="/home/mabdel03/data/software/BOLT-LMM_v2.5/tables/genetic_map_hg19_withX.txt.gz"

for file in "${genotype_bfile}.bed" "${genotype_bfile}.bim" "${genotype_bfile}.fam" \
            "${ukb21942_d}/pheno/isolation_run_control.tsv.gz" \
            "${ukb21942_d}/sqc/sqc.20220316.tsv.gz" \
            "${ukb21942_d}/sqc/population.20220316/EUR.keep" \
            "${model_snps_file}" \
            "${ld_scores_file}" \
            "${genetic_map_file}" ; do
    if [ -f "$file" ]; then
        size=$(du -h "$file" | cut -f1)
        echo "  ✓ $file ($size)"
    else
        echo "  ✗ MISSING: $file"
    fi
done

# Test 3: Minimal BOLT command (just bfile and phenotype)
echo ""
echo "Test 3: Minimal BOLT command..."
bolt \
    --bfile=${genotype_bfile} \
    --phenoFile=${ukb21942_d}/pheno/isolation_run_control.tsv.gz \
    --phenoCol=Loneliness \
    --lmm \
    --numThreads=4 \
    --statsFile=/tmp/test_minimal.stats \
    2>&1 | head -50

echo ""
echo "Test 3 exit code: $?"

# Test 4: Add covariate file
echo ""
echo "Test 4: With covariates..."
bolt \
    --bfile=${genotype_bfile} \
    --phenoFile=${ukb21942_d}/pheno/isolation_run_control.tsv.gz \
    --phenoCol=Loneliness \
    --covarFile=${ukb21942_d}/sqc/sqc.20220316.tsv.gz \
    --qCovarCol=age \
    --lmm \
    --numThreads=4 \
    --statsFile=/tmp/test_covar.stats \
    2>&1 | head -50

echo ""
echo "Test 4 exit code: $?"

echo ""
echo "========================================"
echo "If all tests pass, the issue is with a specific argument combination"
echo "Check which test fails to isolate the problem"
echo "========================================"


#!/bin/bash
set -beEo pipefail

# Debug script to print and test BOLT-LMM command

REPODIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942"
ukb21942_d='/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'

genotype_bfile="${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_bed"
model_snps_file="${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_modelSNPs.txt"
ld_scores_file="/home/mabdel03/data/software/BOLT-LMM_v2.5/tables/LDSCORE.1000G_EUR.GRCh38.tab.gz"
genetic_map_file="/home/mabdel03/data/software/BOLT-LMM_v2.5/tables/genetic_map_hg19_withX.txt.gz"

echo "========================================"
echo "BOLT-LMM Command Debugging"
echo "========================================"
echo ""

# Print the exact command that will be run
echo "EXACT COMMAND:"
echo "==============="
cat << EOF
bolt \\
    --bfile=${genotype_bfile} \\
    --phenoFile=${ukb21942_d}/pheno/isolation_run_control.tsv.gz \\
    --phenoCol=Loneliness \\
    --covarFile=${ukb21942_d}/sqc/sqc.20220316.tsv.gz \\
    --qCovarCol=age \\
    --covarCol=sex,array \\
    --covarMaxLevels=30 \\
    --keep=${ukb21942_d}/sqc/population.20220316/EUR.keep \\
    --modelSnps=${model_snps_file} \\
    --LDscoresFile=${ld_scores_file} \\
    --geneticMapFile=${genetic_map_file} \\
    --lmm \\
    --LDscoresMatchBp \\
    --numThreads=4 \\
    --statsFile=/tmp/test_debug.stats \\
    --verboseStats
EOF

echo ""
echo "========================================"
echo "Test 1: Minimal BOLT (just bfile + pheno)"
echo "========================================"

bolt \
    --bfile=${genotype_bfile} \
    --phenoFile=${ukb21942_d}/pheno/isolation_run_control.tsv.gz \
    --phenoCol=Loneliness \
    --lmm \
    --numThreads=4 \
    --statsFile=/tmp/test1.stats

test1_result=$?
echo "Test 1 exit code: $test1_result"

if [ $test1_result -ne 0 ]; then
    echo "FAILED at Test 1 - issue with basic files or BOLT installation"
    exit 1
fi

echo ""
echo "========================================"
echo "Test 2: Add model SNPs"
echo "========================================"

bolt \
    --bfile=${genotype_bfile} \
    --phenoFile=${ukb21942_d}/pheno/isolation_run_control.tsv.gz \
    --phenoCol=Loneliness \
    --modelSnps=${model_snps_file} \
    --lmm \
    --numThreads=4 \
    --statsFile=/tmp/test2.stats

test2_result=$?
echo "Test 2 exit code: $test2_result"

if [ $test2_result -ne 0 ]; then
    echo "FAILED at Test 2 - issue with model SNPs file"
    exit 1
fi

echo ""
echo "========================================"
echo "Test 3: Add LD scores"
echo "========================================"

bolt \
    --bfile=${genotype_bfile} \
    --phenoFile=${ukb21942_d}/pheno/isolation_run_control.tsv.gz \
    --phenoCol=Loneliness \
    --modelSnps=${model_snps_file} \
    --LDscoresFile=${ld_scores_file} \
    --lmm \
    --numThreads=4 \
    --statsFile=/tmp/test3.stats

test3_result=$?
echo "Test 3 exit code: $test3_result"

if [ $test3_result -ne 0 ]; then
    echo "FAILED at Test 3 - issue with LD scores file"
    exit 1
fi

echo ""
echo "========================================"
echo "Test 4: Add genetic map"
echo "========================================"

bolt \
    --bfile=${genotype_bfile} \
    --phenoFile=${ukb21942_d}/pheno/isolation_run_control.tsv.gz \
    --phenoCol=Loneliness \
    --modelSnps=${model_snps_file} \
    --LDscoresFile=${ld_scores_file} \
    --geneticMapFile=${genetic_map_file} \
    --lmm \
    --numThreads=4 \
    --statsFile=/tmp/test4.stats

test4_result=$?
echo "Test 4 exit code: $test4_result"

if [ $test4_result -ne 0 ]; then
    echo "FAILED at Test 4 - issue with genetic map file"
    exit 1
fi

echo ""
echo "========================================"
echo "Test 5: Add covariates"
echo "========================================"

bolt \
    --bfile=${genotype_bfile} \
    --phenoFile=${ukb21942_d}/pheno/isolation_run_control.tsv.gz \
    --phenoCol=Loneliness \
    --covarFile=${ukb21942_d}/sqc/sqc.20220316.tsv.gz \
    --qCovarCol=age \
    --covarCol=sex,array \
    --modelSnps=${model_snps_file} \
    --LDscoresFile=${ld_scores_file} \
    --geneticMapFile=${genetic_map_file} \
    --lmm \
    --numThreads=4 \
    --statsFile=/tmp/test5.stats

test5_result=$?
echo "Test 5 exit code: $test5_result"

if [ $test5_result -ne 0 ]; then
    echo "FAILED at Test 5 - issue with covariate arguments or file"
    exit 1
fi

echo ""
echo "========================================"
echo "ALL TESTS PASSED!"
echo "========================================"
echo "The full command should work. Issue was likely with tmp genotype paths."


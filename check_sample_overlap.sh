#!/bin/bash
set -beEo pipefail

# Script to check sample ID overlap between files

ukb21942_d='/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'

echo "========================================"
echo "Checking Sample ID Overlap"
echo "========================================"
echo ""

# File paths
fam_file="${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_bed.fam"
keep_file="${ukb21942_d}/sqc/population.20220316/EUR.keep"
remove_file="${ukb21942_d}/sqc/population.20220316/EUR.remove"
pheno_file="${ukb21942_d}/pheno/isolation_run_control.tsv.gz"
covar_file="${ukb21942_d}/sqc/sqc.20220316.tsv.gz"

# Check fam file
if [ -f "${fam_file}" ]; then
    n_fam=$(wc -l < "${fam_file}")
    echo "✓ Fam file: ${n_fam} samples"
    echo "  First 3 samples:"
    head -3 "${fam_file}" | awk '{print "    "$1"\t"$2}'
else
    echo "✗ Fam file not found: ${fam_file}"
fi

echo ""

# Check keep file
if [ -f "${keep_file}" ]; then
    n_keep=$(wc -l < "${keep_file}")
    echo "✓ Keep file (EUR): ${n_keep} samples"
    echo "  First 3 samples:"
    head -3 "${keep_file}" | awk '{print "    "$1"\t"$2}'
else
    echo "✗ Keep file not found: ${keep_file}"
fi

echo ""

# Check remove file
if [ -f "${remove_file}" ]; then
    n_remove=$(wc -l < "${remove_file}")
    echo "✓ Remove file (non-EUR): ${n_remove} samples"
    echo "  First 3 samples:"
    head -3 "${remove_file}" | awk '{print "    "$1"\t"$2}'
else
    echo "✗ Remove file not found (run create_remove_file.sh)"
fi

echo ""

# Check phenotype file
if [ -f "${pheno_file}" ]; then
    n_pheno=$(zcat "${pheno_file}" | tail -n +2 | wc -l)
    echo "✓ Phenotype file: ${n_pheno} samples"
    echo "  Header:"
    zcat "${pheno_file}" | head -1
    echo "  First 3 data lines:"
    zcat "${pheno_file}" | tail -n +2 | head -3 | awk '{print "    "$1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6}'
else
    echo "✗ Phenotype file not found"
fi

echo ""

# Check covariate file
if [ -f "${covar_file}" ]; then
    n_covar=$(zcat "${covar_file}" | tail -n +2 | wc -l)
    echo "✓ Covariate file: ${n_covar} samples"
    echo "  First few columns of header:"
    zcat "${covar_file}" | head -1 | cut -f1-10
else
    echo "✗ Covariate file not found"
fi

echo ""
echo "========================================"
echo "Sample Counts Summary"
echo "========================================"
echo "Genotypes (fam):     ${n_fam:-N/A}"
echo "EUR keep:            ${n_keep:-N/A}"
echo "Non-EUR remove:      ${n_remove:-N/A}"
echo "Phenotype file:      ${n_pheno:-N/A}"
echo "Covariate file:      ${n_covar:-N/A}"
echo ""

# Sanity check
if [ -n "$n_fam" ] && [ -n "$n_keep" ] && [ -n "$n_remove" ]; then
    sum=$((n_keep + n_remove))
    if [ $sum -eq $n_fam ]; then
        echo "✓ Sanity check PASSED: keep ($n_keep) + remove ($n_remove) = fam ($n_fam)"
    else
        echo "⚠️  WARNING: keep ($n_keep) + remove ($n_remove) = $sum ≠ fam ($n_fam)"
        echo "   This suggests an ID matching issue!"
    fi
fi

echo ""
echo "========================================"
echo "Potential Issues"
echo "========================================"

# Check if remove file removes everyone
if [ -n "$n_remove" ] && [ -n "$n_fam" ]; then
    if [ $n_remove -eq $n_fam ]; then
        echo "❌ CRITICAL: Remove file excludes ALL samples!"
        echo "   This will result in 0 individuals after filtering"
        echo "   Check ID format match between fam and keep files"
    elif [ $n_remove -eq 0 ]; then
        echo "❌ CRITICAL: Remove file is empty!"
        echo "   All samples will be included (not EUR-filtered)"
    else
        echo "✓ Remove file looks reasonable"
    fi
fi

echo ""
echo "To fix ID mismatches, check:"
echo "1. Are IDs in same format (FID IID)?"
echo "2. Are they tab or space separated?"
echo "3. Do IDs actually match between files?"


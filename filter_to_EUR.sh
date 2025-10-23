#!/bin/bash
set -beEo pipefail

# Filter phenotype and covariate files to EUR ancestry samples
# This is simpler than using --remove in BOLT-LMM

ukb21942_d='/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'
SRCDIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM"

echo "========================================"
echo "Filter Phenotype & Covariate Files to EUR"
echo "========================================"
echo ""

# Input files
keep_file="${ukb21942_d}/sqc/population.20220316/EUR.keep"
pheno_file="${ukb21942_d}/pheno/isolation_run_control.tsv.gz"
covar_file="${ukb21942_d}/sqc/sqc.20220316.tsv.gz"

# Output files (in Git repo for easy access)
pheno_eur="${SRCDIR}/isolation_run_control.EUR.tsv.gz"
covar_eur="${SRCDIR}/sqc.EUR.tsv.gz"

echo "Input files:"
echo "  EUR samples: ${keep_file}"
echo "  Phenotypes: ${pheno_file}"
echo "  Covariates: ${covar_file}"
echo ""
echo "Output files:"
echo "  EUR phenotypes: ${pheno_eur}"
echo "  EUR covariates: ${covar_eur}"
echo ""

# Check if EUR.keep exists
if [ ! -f "${keep_file}" ]; then
    echo "ERROR: EUR.keep file not found: ${keep_file}" >&2
    exit 1
fi

# Count EUR samples
n_eur=$(wc -l < "${keep_file}")
echo "EUR samples to keep: ${n_eur}"
echo ""

# Filter phenotype file
echo "Filtering phenotype file..."

# Create temporary ID file (just IDs, no header)
awk '{print $2}' "${keep_file}" | sort > /tmp/eur_iids.txt

# Filter phenotype file:
# 1. Extract header
# 2. Filter data rows to EUR IDs only
# 3. Compress output

{
    # Header
    zcat "${pheno_file}" | head -1
    
    # Data rows - keep only EUR IDs
    # Join on IID (column 2)
    zcat "${pheno_file}" | tail -n +2 | awk 'NR==FNR{ids[$1]; next} $2 in ids' /tmp/eur_iids.txt -
    
} | gzip > "${pheno_eur}"

n_pheno_out=$(zcat "${pheno_eur}" | tail -n +2 | wc -l)
echo "✓ EUR phenotype file created: ${n_pheno_out} samples"

# Filter covariate file
echo "Filtering covariate file..."

{
    # Header
    zcat "${covar_file}" | head -1
    
    # Data rows - keep only EUR IDs
    zcat "${covar_file}" | tail -n +2 | awk 'NR==FNR{ids[$1]; next} $2 in ids' /tmp/eur_iids.txt -
    
} | gzip > "${covar_eur}"

n_covar_out=$(zcat "${covar_eur}" | tail -n +2 | wc -l)
echo "✓ EUR covariate file created: ${n_covar_out} samples"

# Clean up
rm -f /tmp/eur_iids.txt

echo ""
echo "========================================"
echo "Filtering Complete!"
echo "========================================"
echo ""
echo "Summary:"
echo "  EUR samples requested: ${n_eur}"
echo "  Phenotype file output: ${n_pheno_out}"
echo "  Covariate file output: ${n_covar_out}"
echo ""

if [ ${n_pheno_out} -ne ${n_eur} ]; then
    echo "⚠️  WARNING: Phenotype sample count doesn't match EUR count"
    echo "   This is normal if some EUR samples have missing phenotype data"
fi

if [ ${n_covar_out} -ne ${n_eur} ]; then
    echo "⚠️  WARNING: Covariate sample count doesn't match EUR count"
    echo "   This is normal if some EUR samples have missing covariate data"
fi

echo ""
echo "Next steps:"
echo "1. Update run_single_phenotype.sh to use filtered files:"
echo "   phenoFile: ${pheno_eur}"
echo "   covarFile: ${covar_eur}"
echo "2. Remove --remove argument from BOLT-LMM command"
echo "3. Run test: sbatch 0c_test_simplified.sbatch.sh"


#!/bin/bash
set -beEo pipefail

# Simplified BOLT-LMM script: runs one phenotype with one covariate set
# Processes the FULL GENOME (no variant splitting)

if [ $# -ne 2 ]; then
    echo "Usage: $0 <phenotype> <covar_str>" >&2
    echo "Example: $0 Loneliness Day_NoPCs" >&2
    exit 1
fi

phenotype=$1
covar_str=$2

# Directories
REPODIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942"
SRCDIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM"
ukb21942_d='/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'

keep_set="EUR"

echo "========================================"
echo "Running BOLT-LMM for ${phenotype}"
echo "Covariate model: ${covar_str}"
echo "Population: ${keep_set}"
echo "========================================"

# Output directory
out_dir="${SRCDIR}/results/${covar_str}/${keep_set}"
mkdir -p ${out_dir}

out_file="${out_dir}/bolt_${phenotype}.${covar_str}"

# Remove existing output files to ensure clean run
echo "Checking for existing output files..."
for ext in stats stats.gz log log.gz; do
    if [ -f "${out_file}.${ext}" ]; then
        echo "  Removing old file: ${out_file}.${ext}"
        rm -f "${out_file}.${ext}"
    fi
done
echo "✓ Ready for clean run"
echo ""

# Input files
genotype_bfile="${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_bed"
model_snps_file="${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_modelSNPs.txt"
ld_scores_file="/home/mabdel03/data/software/BOLT-LMM_v2.5/tables/LDSCORE.1000G_EUR.GRCh38.tab.gz"
genetic_map_file="/home/mabdel03/data/software/BOLT-LMM_v2.5/tables/genetic_map_hg19_withX.txt.gz"

# Use EUR-filtered files (created by filter_to_EUR.sh)
# This avoids ID matching issues with --remove
pheno_file_eur="${SRCDIR}/isolation_run_control.EUR.tsv.gz"
covar_file_eur="${SRCDIR}/sqc.EUR.tsv.gz"

# Set up covariates based on covar_str
if [ "${covar_str}" == "Day_NoPCs" ]; then
    qcovar_cols="age"
    covar_cols="sex,array"
elif [ "${covar_str}" == "Day_10PCs" ]; then
    qcovar_cols="age,UKB_PC1,UKB_PC2,UKB_PC3,UKB_PC4,UKB_PC5,UKB_PC6,UKB_PC7,UKB_PC8,UKB_PC9,UKB_PC10"
    covar_cols="sex,array"
else
    echo "ERROR: Unknown covar_str: ${covar_str}" >&2
    exit 1
fi

echo "Configuration:"
echo "  Genotype: ${genotype_bfile}"
echo "  Phenotype: ${phenotype}"
echo "  qCovariates: ${qcovar_cols}"
echo "  Covariates: ${covar_cols}"
echo "  Model SNPs: ${model_snps_file} (~444K SNPs)"
echo "  Output: ${out_file}.stats"
echo ""

# Verify all required files exist
echo "Verifying input files..."
for file in "${genotype_bfile}.bed" "${genotype_bfile}.bim" "${genotype_bfile}.fam" \
            "${pheno_file_eur}" \
            "${covar_file_eur}" \
            "${model_snps_file}" \
            "${ld_scores_file}" \
            "${genetic_map_file}"; do
    if [ ! -f "$file" ]; then
        echo "ERROR: Required file not found: $file" >&2
        if [[ "$file" == *".EUR.tsv.gz" ]]; then
            echo "Create EUR-filtered files by running: bash filter_to_EUR.sh" >&2
        fi
        exit 1
    fi
done
echo "✓ All input files verified"
echo ""

# Run BOLT-LMM
echo "Starting BOLT-LMM analysis..."
echo "This will analyze ~1.3M autosomal variants (full genome)"
echo ""

    # BOLT-LMM command
    # Using EUR-filtered phenotype and covariate files (simpler than --remove)
    # No need for --remove since files only contain EUR samples
    
    bolt \
        --bfile=${genotype_bfile} \
        --phenoFile=${pheno_file_eur} \
        --phenoCol=${phenotype} \
        --covarFile=${covar_file_eur} \
        --qCovarCol=${qcovar_cols} \
        --covarCol=${covar_cols} \
        --covarMaxLevels=30 \
        --modelSnps=${model_snps_file} \
        --LDscoresFile=${ld_scores_file} \
        --geneticMapFile=${genetic_map_file} \
        --lmm \
        --LDscoresMatchBp \
        --numThreads=100 \
        --statsFile=${out_file}.stats \
        --verboseStats \
        2>&1 | tee ${out_file}.log

bolt_exit_code=$?

echo ""
echo "BOLT-LMM exit code: ${bolt_exit_code}"

if [ ${bolt_exit_code} -ne 0 ]; then
    echo "ERROR: BOLT-LMM failed" >&2
    exit 1
fi

# Compress output files
echo "Compressing output files..."
if [ -s "${out_file}.stats" ]; then
    gzip -f ${out_file}.stats
    echo "✓ Created: ${out_file}.stats.gz"
fi

if [ -s "${out_file}.log" ]; then
    gzip -f ${out_file}.log
    echo "✓ Created: ${out_file}.log.gz"
fi

# Report success
echo ""
echo "========================================"
echo "✅ COMPLETED: ${phenotype} with ${covar_str}"
echo "Output files:"
ls -lh ${out_file}.stats.gz
ls -lh ${out_file}.log.gz
echo "========================================"


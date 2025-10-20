#!/bin/bash
set -beEo pipefail

# Note: Removed -u flag due to Qt conda package activation issues

# Hardcode the top-level repo directory:
REPODIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942"

# If you need SRCDIR, define it explicitly:
SRCDIR="${REPODIR}/isolation_run_control_BOLT"

source "${REPODIR}/helpers/functions.sh"
# If source_paths is needed, call it with the directory that actually holds the relevant files
source_paths "${SRCDIR}"

module load miniconda3/v4
source /home/software/conda/miniconda3/bin/condainit
conda activate /home/mabdel03/data/conda_envs/GWAS_env

ukb21942_d='/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'

if [ $# -lt 8 ] ; then
    echo "missing args!" >&2
    exit 1
fi

analysis_name=$1      # isolation_run_control
out_suffix=$2         # BOLT
pheno_col_nums=$3     # 5,6,9 (not used directly by BOLT, but for consistency)
bolt_threads=$4       # 8 (BOLT can use more threads)
bolt_memory=$5        # 30000 (BOLT needs more memory than PLINK)
covar_str=$6          # Day_10PCs or Day_NoPCs
keep_set=$7           # EUR
idx=$8                # 1-69
use_tmp_geno="TRUE"
overwrite="FALSE"

# Phenotype columns for isolation_run_control
# All phenotypes are BINARY (case-control)
# Following methodology from Day et al. "Elucidating the genetic basis of social interaction and isolation"
# Column 5: Loneliness (binary: 0=no, 1=yes)
# Column 6: FreqSoc (binary: 0=low frequency, 1=high frequency)
# Column 9: AbilityToConfide (binary: 0=no, 1=yes)
phenotypes=("Loneliness" "FreqSoc" "AbilityToConfide")

# var_split="array_both_9"
var_split=$(zcat ${ukb21942_d}/gwas_geno/ukb_geno.var_split.info.tsv.gz | grep -v '#' | awk -v idx=${idx} '(NR == idx){print $1}')

echo "Processing variant split: ${var_split}"

####################################################################
# output files
####################################################################

out_base=${ukb21942_d}/isolation_run_control_BOLT/${covar_str}/${keep_set}/var_split/bolt_${analysis_name}.${var_split}

if [ ! -d $(dirname "${out_base}") ] ; then mkdir -p $(dirname "${out_base}") ; fi

####################################################################
# input files
####################################################################

# BOLT-LMM requires bed/bim/fam format
# Assuming genotype files are available in bed format or need conversion
if [ "${use_tmp_geno}" == "TRUE" ] ; then
    # copy genotype files into cache directory if using tmp
    bash ${REPODIR}/helpers/cache.pgen.sh ukb_genoHM3
    
    # For BOLT-LMM, we need bed/bim/fam format (converted from pgen)
    # Use the _bed suffix for converted files
    genotype_bfile=${tmp_ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_bed
else
    # Use bed format files (converted from pgen via 0_convert_to_bed.sh)
    genotype_bfile=${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_bed
fi

# Model SNPs file (for computing genetic relationship matrix)
# This should be a subset of well-imputed common variants (usually ~500K SNPs)
# You may need to create this file using LD pruning
model_snps_file=${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_modelSNPs.txt

# LD scores table (for calibration)
# BOLT-LMM v2.5 installation path
ld_scores_file="/home/mabdel03/data/software/BOLT-LMM_v2.5/tables/LDSCORE.1000G_EUR.GRCh38.tab.gz"

# Genetic map for interpolation (hg19/GRCh37 - matches UK Biobank coordinates)
genetic_map_file="/home/mabdel03/data/software/BOLT-LMM_v2.5/tables/genetic_map_hg19_withX.txt.gz"

####################################################################
# main
####################################################################

if [ "${overwrite}" == "FALSE" ] ; then
    # check if the output files exist for all phenotypes
    all_exist=true
    for pheno in "${phenotypes[@]}" ; do
        if [ ! -s "${out_base}.${pheno}.${out_suffix}.stats.gz" ] ; then
            all_exist=false
            break
        fi
    done
    
    if [ "${all_exist}" == "true" ] ; then
        echo "All output files already exist"
        exit 0
    fi
fi

# Extract variant IDs for this split
extract_file="${out_base}.extract.txt"
if [ ! -s "${extract_file}" ] ; then
    zcat ${ukb21942_d}/gwas_geno/ukb_geno.var_split.tsv.gz \
    | awk -v var_split="${var_split}" '(var_split == $NF){ print $3 }' \
    > ${extract_file}
fi

# Set up covariates based on covar_str
if [ "${covar_str}" == "Day_NoPCs" ] ; then
    # Quantitative covariates: age
    qcovar_cols="age"
    # Categorical covariates: sex, array
    covar_cols="sex,array"
    
elif [ "${covar_str}" == "Day_10PCs" ] ; then
    # Quantitative covariates: age, PC1-PC10
    qcovar_cols="age,UKB_PC1,UKB_PC2,UKB_PC3,UKB_PC4,UKB_PC5,UKB_PC6,UKB_PC7,UKB_PC8,UKB_PC9,UKB_PC10"
    # Categorical covariates: sex, array
    covar_cols="sex,array"
    
elif [ "${covar_str}" == "pop_10PCs" ] ; then
    # Quantitative covariates: age, Townsend, PC1-PC10
    qcovar_cols="age,Townsend,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10"
    # Categorical covariates: sex
    covar_cols="sex"
    
else
    echo "Unknown covar_str: ${covar_str}" >&2
    exit 1
fi

# Run BOLT-LMM for each phenotype
for pheno in "${phenotypes[@]}" ; do
    out_file="${out_base}.${pheno}.${out_suffix}"
    
    if [ -s "${out_file}.stats.gz" ] && [ "${overwrite}" == "FALSE" ] ; then
        echo "Output already exists for ${pheno}, skipping..."
        continue
    fi
    
    echo "Running BOLT-LMM for phenotype: ${pheno}"
    
    # BOLT-LMM command for BINARY phenotypes
    # Following Day et al. methodology for case-control analysis
    # BOLT-LMM automatically detects binary (0/1 or 1/2) phenotypes and uses liability threshold model
    bolt \
        --bfile=${genotype_bfile} \
        --exclude=${extract_file} \
        --phenoFile=${ukb21942_d}/pheno/${analysis_name}.tsv.gz \
        --phenoCol=${pheno} \
        --covarFile=${ukb21942_d}/sqc/sqc.20220316.tsv.gz \
        --qCovarCol=${qcovar_cols} \
        --covarCol=${covar_cols} \
        --covarMaxLevels=30 \
        --keep=${ukb21942_d}/sqc/population.20220316/${keep_set}.keep \
        --modelSnps=${model_snps_file} \
        --LDscoresFile=${ld_scores_file} \
        --geneticMapFile=${genetic_map_file} \
        --lmm \
        --LDscoresMatchBp \
        --numThreads=${bolt_threads} \
        --statsFile=${out_file}.stats \
        --verboseStats \
        2>&1 | tee ${out_file}.log
    
    # Note: For binary traits, BOLT-LMM uses a liability threshold model
    # Effect sizes (BETA) are on the liability scale, not the observed scale
    
    # Compress output files
    if [ -s "${out_file}.stats" ] ; then
        gzip -f ${out_file}.stats
    fi
    
    if [ -s "${out_file}.log" ] ; then
        gzip -f ${out_file}.log
    fi
done

echo "BOLT-LMM analysis completed for variant split: ${var_split}"


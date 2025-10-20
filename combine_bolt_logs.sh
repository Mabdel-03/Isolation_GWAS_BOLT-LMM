#!/bin/bash
set -beEuo pipefail

# Script to combine BOLT-LMM log files from variant splits

REPODIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942"
ukb21942_d='/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'

if [ $# -ne 3 ] ; then
    echo "Usage: $0 <analysis_name> <covar_str> <keep_set>" >&2
    exit 1
fi

analysis_name=$1
covar_str=$2
keep_set=$3

input_dir="${ukb21942_d}/isolation_run_control_BOLT/${covar_str}/${keep_set}/var_split"
output_dir="${ukb21942_d}/isolation_run_control_BOLT/${covar_str}/${keep_set}"

if [ ! -d "${output_dir}" ] ; then
    mkdir -p "${output_dir}"
fi

# Combine log files for each phenotype
for pheno in Loneliness FreqSoc AbilityToConfide ; do
    output_log="${output_dir}/bolt_${analysis_name}.${pheno}.BOLT.log.gz"
    
    if [ -s "${output_log}" ] ; then
        echo "Combined log already exists: ${output_log}"
        continue
    fi
    
    echo "Combining log files for ${pheno}..."
    
    # Find all log files for this phenotype across variant splits
    log_files=$(find "${input_dir}" -name "bolt_${analysis_name}.*.${pheno}.BOLT.log.gz" | sort)
    
    if [ -z "${log_files}" ] ; then
        echo "Warning: No log files found for ${pheno}" >&2
        continue
    fi
    
    # Concatenate all log files
    {
        for log_file in ${log_files} ; do
            echo "# ============================================"
            echo "# Log from: $(basename ${log_file})"
            echo "# ============================================"
            zcat "${log_file}"
        done
    } | gzip > "${output_log}"
    
    echo "Created combined log: ${output_log}"
done

echo "Log combination completed for ${covar_str}/${keep_set}"


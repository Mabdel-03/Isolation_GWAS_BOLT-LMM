#!/bin/bash
set -beEuo pipefail

# Script to combine BOLT-LMM summary statistics from variant splits

REPODIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942"
SRCDIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM"

if [ $# -ne 4 ] ; then
    echo "Usage: $0 <analysis_name> <covar_str> <keep_set> <trait>" >&2
    exit 1
fi

analysis_name=$1
covar_str=$2
keep_set=$3
trait=$4

# Use results directory within Git repository
input_dir="${SRCDIR}/results/${covar_str}/${keep_set}/var_split"
output_dir="${SRCDIR}/results/${covar_str}/${keep_set}"

if [ ! -d "${output_dir}" ] ; then
    mkdir -p "${output_dir}"
fi

output_file="${output_dir}/${trait}.bolt.stats.gz"

if [ -s "${output_file}" ] ; then
    echo "Combined statistics already exist: ${output_file}"
    exit 0
fi

echo "Combining statistics for ${trait}..."

# Find all stats files for this trait across variant splits
stats_files=$(find "${input_dir}" -name "bolt_${analysis_name}.*.${trait}.BOLT.stats.gz" | sort)

if [ -z "${stats_files}" ] ; then
    echo "Warning: No stats files found for ${trait}" >&2
    exit 1
fi

# Combine stats files
# The first file will include the header
first_file=true

{
    for stats_file in ${stats_files} ; do
        if [ "${first_file}" = true ] ; then
            # Include header from first file
            zcat "${stats_file}"
            first_file=false
        else
            # Skip header from subsequent files
            zcat "${stats_file}" | tail -n +2
        fi
    done
} | gzip > "${output_file}"

echo "Created combined statistics: ${output_file}"

# Count variants
n_variants=$(zcat "${output_file}" | tail -n +2 | wc -l)
echo "Total variants in combined file: ${n_variants}"


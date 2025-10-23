#!/bin/bash
set -beEo pipefail

# Fix .fam file IDs by copying from .psam file

ukb21942_d='/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'

psam_file="${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3.psam"
fam_file="${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_bed.fam"
fam_backup="${fam_file}.backup"

echo "========================================"
echo "Fixing .fam File Sample IDs"
echo "========================================"
echo ""

# Check if psam exists
if [ ! -f "${psam_file}" ]; then
    echo "ERROR: PSAM file not found: ${psam_file}" >&2
    exit 1
fi

# Check if fam exists
if [ ! -f "${fam_file}" ]; then
    echo "ERROR: FAM file not found: ${fam_file}" >&2
    exit 1
fi

# Check current fam file IDs
echo "Current fam file (first 3 lines):"
head -3 "${fam_file}"
echo ""

# Check psam file IDs
echo "Original psam file (first 3 lines):"
head -3 "${psam_file}"
echo ""

# Backup original fam
echo "Creating backup: ${fam_backup}"
cp "${fam_file}" "${fam_backup}"

# Create new fam file with correct IDs from psam
echo "Creating corrected fam file..."

# The psam file has header, skip it
# Columns: #FID IID PAT MAT SEX PHENO
# We need: FID IID PAT MAT SEX PHENO (same order)

tail -n +2 "${psam_file}" | awk '{print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6}' > "${fam_file}.tmp"

# Count lines
n_psam=$(tail -n +2 "${psam_file}" | wc -l)
n_fam_old=$(wc -l < "${fam_file}")
n_fam_new=$(wc -l < "${fam_file}.tmp")

echo "Sample counts:"
echo "  Original psam: ${n_psam}"
echo "  Old fam: ${n_fam_old}"
echo "  New fam: ${n_fam_new}"

# Verify counts match
if [ ${n_psam} -ne ${n_fam_new} ]; then
    echo "ERROR: Sample count mismatch!" >&2
    echo "  PSAM: ${n_psam}, New FAM: ${n_fam_new}" >&2
    exit 1
fi

# Replace old fam with new
mv "${fam_file}.tmp" "${fam_file}"

echo ""
echo "✓ Fam file updated!"
echo ""
echo "New fam file (first 3 lines):"
head -3 "${fam_file}"
echo ""

# Verify IDs now match keep file
echo "Checking if IDs now match EUR.keep file..."
keep_file="${ukb21942_d}/sqc/population.20220316/EUR.keep"

if [ -f "${keep_file}" ]; then
    # Check if first few keep IDs are in fam
    first_keep_id=$(head -1 "${keep_file}" | awk '{print $1}')
    if grep -q "^${first_keep_id}\s" "${fam_file}"; then
        echo "✓ IDs appear to match! Found ${first_keep_id} in fam file"
    else
        echo "⚠️  First keep ID (${first_keep_id}) not found in fam file"
        echo "   This may still be an issue..."
    fi
fi

echo ""
echo "========================================"
echo "Fam file fixed!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Recreate EUR.remove file:"
echo "   bash create_remove_file.sh"
echo ""
echo "2. Test BOLT-LMM:"
echo "   bash test_no_filter.sh  (or)"
echo "   sbatch 0c_test_simplified.sbatch.sh"


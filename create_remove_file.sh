#!/bin/bash
set -beEo pipefail

# Create .remove file from .keep file for BOLT-LMM
# BOLT-LMM uses --remove (samples to exclude), not --keep (samples to include)

ukb21942_d='/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'

keep_file="${ukb21942_d}/sqc/population.20220316/EUR.keep"
remove_file="${ukb21942_d}/sqc/population.20220316/EUR.remove"
fam_file="${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_bed.fam"

echo "========================================"
echo "Creating .remove file for BOLT-LMM"
echo "========================================"
echo ""

# Check if files exist
if [ ! -f "${keep_file}" ]; then
    echo "ERROR: Keep file not found: ${keep_file}" >&2
    exit 1
fi

if [ ! -f "${fam_file}" ]; then
    echo "ERROR: Fam file not found: ${fam_file}" >&2
    echo "Run 0a_convert_to_bed.sbatch.sh first to create bed/bim/fam files" >&2
    exit 1
fi

# Check if remove file already exists
if [ -s "${remove_file}" ]; then
    echo "Remove file already exists: ${remove_file}"
    n_remove=$(wc -l < "${remove_file}")
    echo "Number of samples to remove: ${n_remove}"
    exit 0
fi

echo "Input files:"
echo "  Keep file: ${keep_file}"
echo "  Fam file: ${fam_file}"
echo "Output file:"
echo "  Remove file: ${remove_file}"
echo ""

# Count samples
n_total=$(wc -l < "${fam_file}")
n_keep=$(wc -l < "${keep_file}")

echo "Sample counts:"
echo "  Total samples in fam: ${n_total}"
echo "  EUR samples in keep: ${n_keep}"
echo "  Non-EUR to remove: $((n_total - n_keep))"
echo ""

# Create remove file: all samples NOT in keep file
echo "Creating remove file..."

# Extract FID IID from fam file (first two columns)
awk '{print $1, $2}' "${fam_file}" > /tmp/all_samples.txt

# Sort files for comm
sort "${keep_file}" > /tmp/keep_sorted.txt
sort /tmp/all_samples.txt > /tmp/all_sorted.txt

# Find samples in all_samples but NOT in keep file
comm -23 /tmp/all_sorted.txt /tmp/keep_sorted.txt > "${remove_file}"

# Clean up temp files
rm /tmp/all_samples.txt /tmp/keep_sorted.txt /tmp/all_sorted.txt

# Verify output
if [ -s "${remove_file}" ]; then
    n_remove=$(wc -l < "${remove_file}")
    echo "✓ Remove file created: ${remove_file}"
    echo "  Samples to remove: ${n_remove}"
    echo "  Samples to keep: ${n_keep}"
    echo "  Total: ${n_total}"
    echo ""
    
    # Sanity check
    expected_remove=$((n_total - n_keep))
    if [ ${n_remove} -eq ${expected_remove} ]; then
        echo "✓ Sanity check PASSED: ${n_keep} + ${n_remove} = ${n_total}"
    else
        echo "WARNING: Counts don't add up!" >&2
        echo "  Keep: ${n_keep}, Remove: ${n_remove}, Total: ${n_total}" >&2
    fi
else
    echo "ERROR: Failed to create remove file" >&2
    exit 1
fi

echo ""
echo "========================================"
echo "Remove file ready for BOLT-LMM"
echo "========================================"
echo ""
echo "Next: Run BOLT-LMM with:"
echo "  --remove=${remove_file}"


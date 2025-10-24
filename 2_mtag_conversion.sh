#!/bin/bash
set -beEo pipefail

# Convert BOLT-LMM outputs to MTAG format
# Run this after BOLT-LMM jobs complete

echo "========================================"
echo "BOLT-LMM to MTAG Format Conversion"
echo "Step 2: Post-GWAS Processing"
echo "Start time: $(date)"
echo "========================================"
echo ""

# Navigate to analysis directory
SRCDIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM"
cd ${SRCDIR}

# Activate conda environment (for pandas)
module load miniconda3/v4
source /home/software/conda/miniconda3/bin/condainit
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

echo "Configuration:"
echo "  Working directory: ${SRCDIR}"
echo "  Python environment: bolt_lmm"
echo "  Input: results/Day_NoPCs/EUR/*.stats.gz"
echo "  Input: results/Day_10PCs/EUR/*.stats.gz (if available)"
echo "  Output: MTAG_Inputs/*.mtag.sumstats.txt"
echo ""

# Check if BOLT-LMM results exist
echo "Checking for BOLT-LMM results..."
n_day_nopcs=$(ls results/Day_NoPCs/EUR/bolt_*.stats.gz 2>/dev/null | wc -l)
n_day_10pcs=$(ls results/Day_10PCs/EUR/bolt_*.stats.gz 2>/dev/null | wc -l)

echo "  Day_NoPCs results found: ${n_day_nopcs}/3"
echo "  Day_10PCs results found: ${n_day_10pcs}/3"
echo ""

if [ ${n_day_nopcs} -eq 0 ] && [ ${n_day_10pcs} -eq 0 ]; then
    echo "ERROR: No BOLT-LMM results found!" >&2
    echo "Run BOLT-LMM analysis first (sbatch 1_run_bolt_lmm.sbatch.sh)" >&2
    exit 1
fi

if [ ${n_day_nopcs} -lt 3 ] && [ ${n_day_10pcs} -lt 3 ]; then
    echo "WARNING: Some BOLT-LMM jobs may still be running or failed"
    echo "Will process available results only"
    echo ""
fi

# Run Python conversion script
echo "Running MTAG conversion (Python)..."
echo ""
python3 ${SRCDIR}/convert_to_MTAG.py

conversion_exit=$?

echo ""
echo "========================================"
if [ ${conversion_exit} -eq 0 ]; then
    echo "✅ MTAG Conversion Complete!"
    echo ""
    echo "Output files:"
    ls -lh MTAG_Inputs/*.mtag.sumstats.txt 2>/dev/null || echo "  No files created"
    echo ""
    echo "Variant counts:"
    for file in MTAG_Inputs/*.mtag.sumstats.txt; do
        if [ -f "$file" ]; then
            n_vars=$(wc -l < "$file")
            n_vars_data=$((n_vars - 1))  # Subtract header
            echo "  $(basename $file): ${n_vars_data} variants"
        fi
    done
    echo ""
    echo "Next steps:"
    echo "1. Verify MTAG input files: ls -lh MTAG_Inputs/"
    echo "2. Run MTAG multi-trait analysis"
    echo "3. See: https://github.com/JonJala/mtag"
else
    echo "❌ MTAG Conversion Failed"
    echo "Check error messages above"
    exit 1
fi

echo "End time: $(date)"
echo "========================================"


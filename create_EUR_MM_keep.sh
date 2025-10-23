#!/bin/bash
set -beEo pipefail

# Create EUR_MM.keep by combining WB_MM and NBW_MM
# This includes RELATED individuals (appropriate for BOLT-LMM mixed models)

ukb21942_d='/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'

pop_dir="${ukb21942_d}/sqc/population.20220316"
wb_mm="${pop_dir}/WB_MM.keep"
nbw_mm="${pop_dir}/NBW_MM.keep"
eur_mm="${pop_dir}/EUR_MM.keep"

echo "========================================"
echo "Create EUR_MM.keep (European + Related)"
echo "========================================"
echo ""
echo "This includes BOTH related and unrelated EUR individuals"
echo "Appropriate for BOLT-LMM mixed model analysis"
echo ""

# Check files exist
if [ ! -f "${wb_mm}" ]; then
    echo "ERROR: WB_MM.keep not found: ${wb_mm}" >&2
    exit 1
fi

if [ ! -f "${nbw_mm}" ]; then
    echo "ERROR: NBW_MM.keep not found: ${nbw_mm}" >&2
    exit 1
fi

# Count samples
n_wb=$(wc -l < "${wb_mm}")
n_nbw=$(wc -l < "${nbw_mm}")

echo "Input files:"
echo "  WB_MM (White British):    ${n_wb} samples"
echo "  NBW_MM (Non-British White): ${n_nbw} samples"
echo "  Expected EUR_MM total:    $((n_wb + n_nbw)) samples"
echo ""

# Combine files
echo "Combining WB_MM and NBW_MM..."
cat "${wb_mm}" "${nbw_mm}" | sort -u > "${eur_mm}"

n_eur=$(wc -l < "${eur_mm}")

echo "✓ EUR_MM.keep created: ${eur_mm}"
echo "  Total EUR samples: ${n_eur}"
echo ""

# Sanity check
expected=$((n_wb + n_nbw))
if [ ${n_eur} -lt ${expected} ]; then
    overlap=$((expected - n_eur))
    echo "  Note: ${overlap} samples appear in both WB_MM and NBW_MM (removed duplicates)"
fi

echo ""
echo "========================================"
echo "Comparison"
echo "========================================"

# Compare with unrelated-only EUR.keep
eur_unrelated="${pop_dir}/EUR.keep"
if [ -f "${eur_unrelated}" ]; then
    n_eur_unrel=$(wc -l < "${eur_unrelated}")
    echo "EUR.keep (unrelated only): ${n_eur_unrel}"
    echo "EUR_MM.keep (with related): ${n_eur}"
    echo "Additional samples gained:  $((n_eur - n_eur_unrel))"
    echo ""
    echo "Using EUR_MM.keep gives you ~$((n_eur - n_eur_unrel)) more samples!"
    echo "This is appropriate for BOLT-LMM (handles relatedness via GRM)"
fi

echo ""
echo "========================================"
echo "Next Steps"
echo "========================================"
echo ""
echo "To use EUR_MM.keep instead of EUR.keep:"
echo "1. Update filter_to_EUR_python.py to use EUR_MM.keep"
echo "2. Rerun: python3 filter_to_EUR_python.py"
echo "3. This will give you ~${n_eur} EUR samples (closer to Day et al.)"


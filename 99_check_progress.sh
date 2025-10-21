#!/bin/bash
set -beEo pipefail

# Script to check the progress of BOLT-LMM analysis

SRCDIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM"

echo "========================================"
echo "BOLT-LMM Analysis Progress Check"
echo "========================================"
echo ""

# Check for each covariate set and phenotype
for covar_str in Day_NoPCs Day_10PCs ; do
    for keep_set in EUR ; do
        echo "Covariate Set: ${covar_str}, Population: ${keep_set}"
        echo "----------------------------------------"
        
        base_dir="${SRCDIR}/results/${covar_str}/${keep_set}"
        var_split_dir="${base_dir}/var_split"
        
        if [ ! -d "${var_split_dir}" ] ; then
            echo "  Directory not found: ${var_split_dir}"
            echo ""
            continue
        fi
        
        # Check each phenotype
        for pheno in Loneliness FreqSoc AbilityToConfide ; do
            echo "  Phenotype: ${pheno}"
            
            # Count completed variant splits
            n_expected=69
            n_completed=$(find "${var_split_dir}" -name "bolt_isolation_run_control.*.${pheno}.BOLT.stats.gz" 2>/dev/null | wc -l)
            n_logs=$(find "${var_split_dir}" -name "bolt_isolation_run_control.*.${pheno}.BOLT.log.gz" 2>/dev/null | wc -l)
            
            echo "    Variant splits completed: ${n_completed} / ${n_expected}"
            echo "    Log files: ${n_logs} / ${n_expected}"
            
            # Check combined output
            combined_stats="${base_dir}/${pheno}.bolt.stats.gz"
            combined_log="${base_dir}/bolt_isolation_run_control.${pheno}.BOLT.log.gz"
            
            if [ -s "${combined_stats}" ] ; then
                n_variants=$(zcat "${combined_stats}" 2>/dev/null | tail -n +2 | wc -l)
                echo "    Combined statistics: EXISTS (${n_variants} variants)"
            else
                echo "    Combined statistics: NOT FOUND"
            fi
            
            if [ -s "${combined_log}" ] ; then
                echo "    Combined log: EXISTS"
            else
                echo "    Combined log: NOT FOUND"
            fi
            
            echo ""
        done
        
        echo ""
    done
done

echo "========================================"
echo "Summary"
echo "========================================"

# Check SLURM logs
slurm_log_dir="$HOME/slurm_logs/isolation_run_control_BOLT"
if [ -d "${slurm_log_dir}" ] ; then
    n_out=$(find "${slurm_log_dir}" -name "*.out" 2>/dev/null | wc -l)
    n_err=$(find "${slurm_log_dir}" -name "*.err" 2>/dev/null | wc -l)
    echo "SLURM output files: ${n_out}"
    echo "SLURM error files: ${n_err}"
    
    # Check for errors in SLURM logs
    if [ ${n_err} -gt 0 ] ; then
        echo ""
        echo "Checking for errors in SLURM logs..."
        grep -i "error\|fail\|abort" "${slurm_log_dir}"/*.err 2>/dev/null | head -20 || echo "  No obvious errors found"
    fi
else
    echo "SLURM log directory not found: ${slurm_log_dir}"
fi

echo ""
echo "Check complete!"


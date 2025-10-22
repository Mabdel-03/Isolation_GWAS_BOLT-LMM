# Simplified BOLT-LMM Workflow (6 Jobs, No Variant Splitting)

## Overview

This is the **streamlined workflow** - much simpler and more efficient than the original 138-job variant-split approach.

**Key Simplification**: Each job processes the **full genome** (~1.3M autosomal variants) for one phenotype-covariate combination.

---

## Why Simplified?

### Original Approach (Complex):
- 138 jobs (69 variant splits × 2 covariate sets)
- Required combining results from 69 chunks
- More complex, more failure points
- Variant splitting was a PLINK optimization, not needed for BOLT-LMM

### Simplified Approach (Recommended):
- **Only 6 jobs** (3 phenotypes × 2 covariate sets)
- Each job processes full genome
- No combining needed (except log concatenation)
- Simpler, more reliable
- With 100 CPUs and 150GB RAM, BOLT-LMM handles full genome efficiently

---

## Complete Workflow

### Step 1: Preprocessing (One-time setup)

```bash
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

# 1a. Convert genotypes to bed format (autosomes only: chr 1-22)
sbatch 0a_convert_to_bed.sbatch.sh
# Wait ~5-10 min, creates ukb_genoHM3_bed.bed/bim/fam (~145GB, autosomes only)

# 1b. Create EUR.remove file from EUR.keep (BOLT-LMM uses --remove, not --keep)
bash create_remove_file.sh
# Takes <1 second, creates EUR.remove (samples to exclude)

# 1c. Create model SNPs (after 1a completes)
sbatch 0b_prepare_model_snps.sbatch.sh
# Wait ~15-30 min, creates ~444K SNPs for GRM (r²<0.5, MAF≥0.5%)
```

### Step 2: Test Run (Required!)

```bash
# Test with one phenotype on full genome
sbatch 0c_test_simplified.sbatch.sh

# Monitor
tail -f bolt_test_simple.*.out

# Check for success
grep "TEST PASSED" bolt_test_simple.*.out
```

**Expected runtime**: 1-3 hours  
**Resources**: 150GB RAM, 100 tasks  
**Output**: `results/Day_NoPCs/EUR/bolt_Loneliness.Day_NoPCs.stats.gz`

⚠️ **Do NOT proceed unless test passes!**

### Step 3: Full Analysis (6 Jobs)

```bash
# Submit all 6 jobs as array
sbatch 1_run_bolt_lmm.sbatch.sh

# This submits:
# Job 1: Loneliness + Day_NoPCs
# Job 2: FreqSoc + Day_NoPCs
# Job 3: AbilityToConfide + Day_NoPCs
# Job 4: Loneliness + Day_10PCs
# Job 5: FreqSoc + Day_10PCs
# Job 6: AbilityToConfide + Day_10PCs
```

**Per job**:
- Resources: 150GB RAM, 100 tasks, 47h time limit
- Runtime: 1-3 hours typically
- Processes: Full genome (~1.3M variants)

### Step 4: Monitor Progress

```bash
# Check SLURM queue
squeue -u $USER

# View specific job output
tail -f bolt_lmm.*.out

# Check progress
ls -lh results/Day_NoPCs/EUR/
ls -lh results/Day_10PCs/EUR/
```

### Step 5: Results

**No combining needed!** Each job creates final output directly.

**Output files**:
```
results/
├── Day_NoPCs/EUR/
│   ├── bolt_Loneliness.Day_NoPCs.stats.gz    ⭐ FINAL GWAS
│   ├── bolt_Loneliness.Day_NoPCs.log.gz
│   ├── bolt_FreqSoc.Day_NoPCs.stats.gz       ⭐ FINAL GWAS
│   ├── bolt_FreqSoc.Day_NoPCs.log.gz
│   ├── bolt_AbilityToConfide.Day_NoPCs.stats.gz  ⭐ FINAL GWAS
│   └── bolt_AbilityToConfide.Day_NoPCs.log.gz
└── Day_10PCs/EUR/
    ├── bolt_Loneliness.Day_10PCs.stats.gz    ⭐ FINAL GWAS
    ├── bolt_Loneliness.Day_10PCs.log.gz
    ├── bolt_FreqSoc.Day_10PCs.stats.gz       ⭐ FINAL GWAS
    ├── bolt_FreqSoc.Day_10PCs.log.gz
    ├── bolt_AbilityToConfide.Day_10PCs.stats.gz  ⭐ FINAL GWAS
    └── bolt_AbilityToConfide.Day_10PCs.log.gz
```

---

## Resource Summary

| Step | Script | RAM | Tasks | Time | Jobs |
|------|--------|-----|-------|------|------|
| Convert | `0a_convert_to_bed.sbatch.sh` | 32GB | 8 | ~10m | 1 |
| Create .remove | `create_remove_file.sh` | - | - | <1s | - |
| Model SNPs | `0b_prepare_model_snps.sbatch.sh` | 80GB | 8 | ~30m | 1 |
| Test | `0c_test_simplified.sbatch.sh` | 150GB | 100 | ~2h | 1 |
| **Full** | `1_run_bolt_lmm.sbatch.sh` | **150GB** | **100** | ~2h each | **6** |

**Total**: 9 steps (3 preprocessing + 1 test + 1 array of 6)  
**Wall time**: ~1 day (all 6 can run concurrently)  
**Vs. old approach**: 138 jobs over 3-4 days!

**Key**: The `.remove` file filters phenotype data to EUR ancestry only (BOLT-LMM requirement)

---

## Comparison to Old Workflow

| Aspect | Old (Variant Split) | New (Simplified) |
|--------|---------------------|------------------|
| **Jobs** | 138 | **6** |
| **Complexity** | High | **Low** |
| **Combining step** | Required (complex) | **Not needed** |
| **Wall time** | 3-4 days | **~1 day** |
| **Failure points** | Many | **Few** |
| **Output files** | 414 intermediates + 6 combined | **6 final files directly** |
| **Disk usage** | Higher | **Lower** |
| **Maintenance** | Complex | **Simple** |

---

## Job Mapping

```
Array Task ID → Phenotype + Covariate Set
=====================================
1 → Loneliness      + Day_NoPCs
2 → FreqSoc         + Day_NoPCs
3 → AbilityToConfide + Day_NoPCs
4 → Loneliness      + Day_10PCs
5 → FreqSoc         + Day_10PCs
6 → AbilityToConfide + Day_10PCs
```

---

## Quick Commands (New Workflow)

```bash
# Navigate to repo
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM

# Activate environment
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

# Preprocessing (one-time setup)
sbatch 0a_convert_to_bed.sbatch.sh      # Convert genotypes (chr 1-22), ~10 min
bash create_remove_file.sh               # Create EUR.remove from EUR.keep, <1 sec
sbatch 0b_prepare_model_snps.sbatch.sh  # Create ~444K model SNPs, ~30 min

# Test (REQUIRED - validates EUR filtering and full pipeline)
sbatch 0c_test_simplified.sbatch.sh     # Full genome test with EUR samples, ~2 hours
# Check: grep "TEST PASSED" bolt_test_simple.*.out

# Full analysis (if test passes)
sbatch 1_run_bolt_lmm.sbatch.sh         # Submits 6 jobs (EUR-filtered)

# Monitor
squeue -u $USER
watch -n 30 squeue -u $USER

# Check results
ls -lh results/Day_NoPCs/EUR/
ls -lh results/Day_10PCs/EUR/
```

---

## Expected Timeline

```
Day 1 Morning:   Submit preprocessing (Steps 1a, 1b)
Day 1 Afternoon: Submit test run (Step 2)
Day 1 Evening:   Test completes, submit full analysis (6 jobs)
Day 2 Morning:   All 6 jobs complete
Day 2 Afternoon: QC and downstream analysis
```

**Total**: ~1-1.5 days from start to GWAS results!

---

## Benefits of This Approach

1. ✅ **Simpler**: 6 jobs vs 138 jobs
2. ✅ **Faster wall time**: 1 day vs 3-4 days
3. ✅ **More reliable**: Fewer moving parts
4. ✅ **No combining step**: Results are immediately usable
5. ✅ **Easier debugging**: One file per phenotype-covariate combo
6. ✅ **Standard BOLT-LMM**: Designed to run on full genome
7. ✅ **Better resource use**: 150GB, 100 CPUs per job

---

## Troubleshooting

**If a job fails**:
```bash
# Check which job failed
sacct -u $USER --format=JobID,JobName,State,ExitCode

# View error log for failed job
cat bolt_lmm.<jobid>_<taskid>.err

# View output log
cat bolt_lmm.<jobid>_<taskid>.out

# Rerun just that phenotype-covariate combination
bash run_single_phenotype.sh <Phenotype> <CovarSet>
```

**Check specific phenotype**:
```bash
# Manual run for debugging
bash run_single_phenotype.sh Loneliness Day_NoPCs
```

---

## Migrating from Old Workflow

If you have the old variant-split setup:

```bash
# The old scripts still exist but are deprecated:
# - bolt_lmm.sh (used variant idx parameter)
# - 1a_bolt_lmm.sbatch.sh (138 jobs)
# - 1b_combine_bolt_output.sh (combining script)

# Use new simplified scripts instead:
# - run_single_phenotype.sh (one phenotype, full genome)
# - 0c_test_simplified.sbatch.sh (simplified test)
# - 1_run_bolt_lmm.sbatch.sh (6 jobs total)
```

No data migration needed - just use new scripts!

---

## Why This Works

BOLT-LMM is specifically designed for biobank-scale data:
- Efficient algorithms that scale well
- Can handle 500K samples × 1M variants easily
- With 100 CPUs, processes full genome in 1-3 hours
- Variant splitting was unnecessary complexity

**The simplified workflow aligns with BOLT-LMM's intended use!**

---

*Use this workflow for production runs. The old variant-split workflow is deprecated but kept for reference.*


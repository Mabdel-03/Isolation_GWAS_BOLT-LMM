# BOLT-LMM Analysis: Complete SLURM Batch Workflow

All scripts have been converted to SLURM batch scripts using the **kellis partition**.

## 📋 Complete Workflow

### Step 0: Prerequisites

Make sure you have:
- ✅ BOLT-LMM v2.5 installed at `/home/mabdel03/data/software/BOLT-LMM_v2.5/`
- ✅ Conda environment created: `/home/mabdel03/data/conda_envs/bolt_lmm`
- ✅ Repository cloned and up-to-date

---

### Step 1: Convert Genotypes to BED Format

**Script:** `0a_convert_to_bed.sbatch.sh`  
**Resources:** 32GB RAM, 8 CPUs, 2 hours  
**Partition:** kellis

```bash
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM

# Submit job
sbatch 0a_convert_to_bed.sbatch.sh

# Monitor
squeue -u $USER
tail -f convert_to_bed.*.out
```

**Expected time:** 5-10 minutes  
**Output:** `ukb_genoHM3_bed.bed/bim/fam` (150GB total)

---

### Step 3: Create Model SNPs

**Script:** `0b_prepare_model_snps.sbatch.sh`  
**Resources:** 80GB RAM, 8 tasks, 2 hours  
**Partition:** kellis

```bash
# Submit job (after Step 1 completes)
sbatch 0b_prepare_model_snps.sbatch.sh

# Monitor
tail -f model_snps.*.out
```

**Expected time:** 15-30 minutes  
**Output:** `ukb_genoHM3_modelSNPs.txt` (~444K SNPs)  
**Parameters:** MAF≥0.5%, r²<0.5, HWE sample-size adjusted  
**Why 80GB:** LD calculations with ~500K samples require substantial memory

---

### Step 4: Test Run (CRITICAL!)

**Script:** `0c_test_simplified.sbatch.sh`  
**Resources:** 150GB RAM, 100 tasks, 6 hours  
**Partition:** kellis

```bash
# Submit test job (after Steps 1-3 complete)
sbatch 0c_test_simplified.sbatch.sh

# Monitor
tail -f bolt_test_simple.*.out

# Check for success message
grep "TEST PASSED" bolt_test_simple.*.out
```

**Expected time:** 1-2 hours  
**What it does:** Runs BOLT-LMM for Loneliness + Day_NoPCs on **full genome** with **EUR samples**  
**Output:** `results/Day_NoPCs/EUR/bolt_Loneliness.Day_NoPCs.stats.gz` (complete GWAS result)  
**⚠️ CRITICAL:** This is 1 of 6 final jobs. Must pass before running other 5!

---

### Step 5: Full Analysis (6 Jobs - Simplified)

**Script:** `1_run_bolt_lmm.sbatch.sh`  
**Resources per job:** 150GB RAM, 100 tasks, 47 hours  
**Partition:** kellis  
**Total jobs:** 6 (3 phenotypes × 2 covariate sets)

```bash
# Submit all jobs (only after test passes!)
bash 1a_bolt_lmm.sbatch.sh

# Monitor progress
squeue -u $USER
bash 99_check_progress.sh

# Watch queue continuously
watch -n 30 squeue -u $USER
```

**Expected time:** 1-2 days (depending on queue)

---

### Step 5: Combine Results

**Script:** `1b_combine_bolt_output.sh` (not a batch script, runs quickly)

```bash
# After all 6 jobs complete
ls -lh results/Day_NoPCs/EUR/bolt_*.stats.gz
ls -lh results/Day_10PCs/EUR/bolt_*.stats.gz

# Results are ready! No combining step needed
```

**Expected time:** 1-2 hours

---

## 🎯 Quick Start Commands

```bash
# Full workflow
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM

# Step 1: Convert genotypes
sbatch 0a_convert_to_bed.sbatch.sh

# Step 2: Create model SNPs (after Step 1 finishes)
sbatch 0b_prepare_model_snps.sbatch.sh

# Step 3: Test run (after Step 2 finishes)
sbatch 0c_test_run.sbatch.sh

# Step 4: Full analysis (only if test passes!)
bash 1a_bolt_lmm.sbatch.sh

# Step 5: Combine (after all jobs finish)
bash 1b_combine_bolt_output.sh
```

---

## 📊 Resource Summary

| Step | Script | RAM | CPUs | Time | Partition |
|------|--------|-----|------|------|-----------|
| 1. Convert | `0a_convert_to_bed.sbatch.sh` | 32GB | 8 | 2h | kellis | Chr 1-22 only |
| 2. EUR filter | `create_remove_file.sh` | - | - | <1s | - | EUR.remove |
| 3. Model SNPs | `0b_prepare_model_snps.sbatch.sh` | 80GB | 8 | 2h | kellis | r²<0.5 |
| 4. Test | `0c_test_simplified.sbatch.sh` | 150GB | 100 | 47h | kellis | Full genome |
| 5. Full (×6) | `1_run_bolt_lmm.sbatch.sh` | 150GB | 100 | 47h | kellis | Concurrent |

---

## 🔍 Monitoring Commands

```bash
# Check running jobs
squeue -u $USER

# Check specific job
squeue -j <JOB_ID>

# View job output (live)
tail -f <job_name>.<job_id>.out

# View errors
tail -f <job_name>.<job_id>.err

# Check completed jobs
sacct -u $USER --format=JobID,JobName,Partition,State,ExitCode,Elapsed

# Analysis progress
bash 99_check_progress.sh
```

---

## ✅ Success Criteria

### Step 1 (Convert):
```bash
# Should see these files:
ls -lh /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/geno/ukb_genoHM3/ukb_genoHM3_bed.*
# bed: ~150GB, bim: ~42MB, fam: ~12MB
```

### Step 2 (Model SNPs):
```bash
# Should have ~500K SNPs:
wc -l /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/geno/ukb_genoHM3/ukb_genoHM3_modelSNPs.txt
# Output: 300000-700000 lines
```

### Step 3 (Test):
```bash
# Check for success message:
grep "TEST PASSED" bolt_test.*.out
# Should see: "🎉 TEST PASSED! All phenotypes completed successfully."
```

### Step 4 (Full):
```bash
# All 6 jobs complete:
squeue -u $USER  # Should show no jobs running
ls -lh results/Day_NoPCs/EUR/  # Should show 3 .stats.gz files
ls -lh results/Day_10PCs/EUR/  # Should show 3 .stats.gz files
```

---

## 🚨 Troubleshooting

### Job fails immediately:
```bash
# Check error log
cat <job_name>.<job_id>.err

# Common issues:
# - Conda environment not found: check path
# - Files not found: verify data paths
# - BOLT-LMM not found: check installation
```

### Out of memory:
```bash
# Edit sbatch script, increase --mem
nano 0c_test_run.sbatch.sh
# Change: #SBATCH --mem=45000
# To:     #SBATCH --mem=60000
```

### Job stuck in queue:
```bash
# Check partition status
sinfo -p kellis

# Check your job priority
sprio -u $USER
```

---

## 📈 Expected Timeline

| Day | Activity |
|-----|----------|
| Day 1 Morning | Submit preprocessing (Steps 1-3), ~1 hour total |
| Day 1 Afternoon | Submit test (Step 4), ~1-2 hours |
| Day 1 Evening | If test passes, submit full analysis (Step 5) - 6 jobs |
| Day 1 Night / Day 2 Morning | All 6 jobs complete (~1-2 hours) |
| Day 2 | Results ready for QC and downstream analysis |

**Total:** 3-4 days from start to finish

---

## 🎉 Final Outputs

After Step 5 completes, you'll have:

```
isolation_run_control_BOLT/
├── Day_NoPCs/EUR/
│   ├── Loneliness.bolt.stats.gz          ⭐ FINAL
│   ├── FreqSoc.bolt.stats.gz             ⭐ FINAL
│   └── AbilityToConfide.bolt.stats.gz    ⭐ FINAL
└── Day_10PCs/EUR/
    ├── Loneliness.bolt.stats.gz          ⭐ FINAL
    ├── FreqSoc.bolt.stats.gz             ⭐ FINAL
    └── AbilityToConfide.bolt.stats.gz    ⭐ FINAL
```

Each file contains millions of variants with BOLT-LMM association statistics!


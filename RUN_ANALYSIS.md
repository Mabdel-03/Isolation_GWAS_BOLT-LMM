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

### Step 4: Full Analysis (138 Jobs)

**Script:** `1a_bolt_lmm.sbatch.sh`  
**Resources per job:** 45GB RAM, 8 CPUs, 12 hours  
**Partition:** kellis  
**Total jobs:** 138 (69 variant splits × 2 covariate sets)

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
# After ALL 138 jobs complete
bash 99_check_progress.sh  # Verify all complete

# Combine results
bash 1b_combine_bolt_output.sh
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
| 1. Convert | `0a_convert_to_bed.sbatch.sh` | 32GB | 8 | 2h | kellis |
| 2. Model SNPs | `0b_prepare_model_snps.sbatch.sh` | 32GB | 8 | 1.5h | kellis |
| 3. Test | `0c_test_run.sbatch.sh` | 45GB | 8 | 6h | kellis |
| 4. Full (×138) | `1a_bolt_lmm.sbatch.sh` | 45GB | 8 | 12h | kellis |

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
# All jobs complete:
bash 99_check_progress.sh
# Should show 69/69 for each phenotype
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
| Day 1 AM | Submit Steps 1-2, monitor |
| Day 1 PM | Submit Step 3 (test), monitor |
| Day 1 Evening | If test passes, submit Step 4 (full analysis) |
| Day 2-3 | Jobs running (138 jobs) |
| Day 3-4 | Combine results, QC |

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


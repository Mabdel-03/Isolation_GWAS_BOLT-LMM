# BOLT-LMM Workflow Summary (Final Version)

## 🎯 Quick Reference Card

**BOLT-LMM version**: v2.5 (June 2025 release)  
**Total Jobs**: 6 (not 138!)  
**Resources per job**: 150GB RAM, 100 CPUs (multithreading enabled), 47h limit  
**Actual runtime**: **8-12 hours per job** (full genome, 426K samples)  
**Sample size**: **426,602 EUR samples** (EUR_MM.keep: includes 73K related individuals)  
**Output location**: `Isolation_GWAS_BOLT-LMM/results/`  
**Ancestry**: European (WB_MM + NBW_MM, including relatives - appropriate for mixed models)  
**Chromosomes**: Autosomes 1-22 only (BOLT v2.5 limitation)  
**Test**: Optional - can skip and run all 6 jobs directly

---

## 📋 Complete Workflow Checklist

```bash
# Navigate to Git repository
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM
conda activate /home/mabdel03/data/conda_envs/bolt_lmm
```

### ✅ One-Time Preprocessing

- [ ] **Step 1**: Convert genotypes (autosomes only)
  ```bash
  sbatch 0a_convert_to_bed.sbatch.sh
  # Wait ~5-10 min
  # Creates: ukb_genoHM3_bed.bed/bim/fam (~145GB, chr 1-22 only)
  ```

- [ ] **Step 2**: Filter phenotype/covariate files to EUR (including relatives)
  ```bash
  python3 filter_to_EUR_python.py
  # Takes 2-3 minutes
  # Uses: EUR_MM.keep (426,602 EUR samples including related)
  # Creates: isolation_run_control.EUR.tsv.gz (~420K EUR samples)
  # Creates: sqc.EUR.tsv.gz (~426K EUR samples)
  # Includes related individuals (BOLT-LMM handles via GRM)
  ```

- [ ] **Step 3**: Create model SNPs (after Step 1 completes)
  ```bash
  sbatch 0b_prepare_model_snps.sbatch.sh
  # Wait ~15-30 min
  # Creates: ~444K SNPs (r²<0.5, MAF≥0.5%, 80GB RAM)
  # Autosomes only (chr 1-22)
  ```

### ✅ Analysis (Skip Test, Run All 6 Jobs Directly - RECOMMENDED)

- [ ] **Step 4**: Submit all 6 jobs (no test needed - we've debugged thoroughly)
  ```bash
  sbatch 1_run_bolt_lmm.sbatch.sh
  # Submits array job with 6 tasks
  # Each: Full genome, 426K EUR_MM samples
  # Runtime: 8-12 hours per task
  # All 6 run concurrently (if resources available)
  ```

### Alternative: Run Test First (Optional)

- [ ] **Step 4a** (Optional): Test with 1 phenotype
  ```bash
  sbatch 0c_test_simplified.sbatch.sh
  # Runs: Loneliness + Day_NoPCs
  # Runtime: 8-12 hours (same as any final job!)
  # Check: grep "TEST PASSED" 0c.out
  # Then: sbatch 1_run_bolt_lmm.sbatch.sh (submit other 5)
  ```

**Recommendation**: Skip test, run all 6 directly (faster to results)

### ✅ Results

- [ ] **Step 6**: Check outputs
  ```bash
  ls -lh results/Day_NoPCs/EUR/bolt_*.stats.gz
  ls -lh results/Day_10PCs/EUR/bolt_*.stats.gz
  # Should see 6 files (3 phenotypes × 2 covariate sets)
  ```

---

## 📊 The 6 Jobs Explained

| Task | Phenotype | Covariate Set | Output File |
|------|-----------|---------------|-------------|
| 1 | Loneliness | Day_NoPCs | `results/Day_NoPCs/EUR/bolt_Loneliness.Day_NoPCs.stats.gz` |
| 2 | FreqSoc | Day_NoPCs | `results/Day_NoPCs/EUR/bolt_FreqSoc.Day_NoPCs.stats.gz` |
| 3 | AbilityToConfide | Day_NoPCs | `results/Day_NoPCs/EUR/bolt_AbilityToConfide.Day_NoPCs.stats.gz` |
| 4 | Loneliness | Day_10PCs | `results/Day_10PCs/EUR/bolt_Loneliness.Day_10PCs.stats.gz` |
| 5 | FreqSoc | Day_10PCs | `results/Day_10PCs/EUR/bolt_FreqSoc.Day_10PCs.stats.gz` |
| 6 | AbilityToConfide | Day_10PCs | `results/Day_10PCs/EUR/bolt_AbilityToConfide.Day_10PCs.stats.gz` |

Each file contains **~1.3M variants** with BOLT-LMM association statistics.

---

## 🔑 Key Points

1. **Autosomes Only**: Converted genotypes include chr 1-22 only (BOLT-LMM doesn't recognize MT/X/Y)

2. **EUR Filtering**: Via pre-filtered phenotype/covariate files (simpler than --remove)
   - **Uses EUR_MM.keep**: 426,602 EUR samples (WB_MM + NBW_MM, **includes related**)
   - BOLT-LMM v2.5 handles relatedness via GRM (appropriate for mixed models)
   - Python script: `filter_to_EUR_python.py`
   - Avoids ID matching issues between .fam and .keep files

3. **No Variant Splitting**: Each job processes full genome (~1.3M variants)

4. **No Combining**: Results are final outputs directly from BOLT-LMM

5. **Model SNPs**: r²<0.5 threshold for HM3 data (~444K SNPs, 80GB RAM)

6. **High Resources**: 150GB RAM, 100 CPUs per BOLT job ensures fast, stable computation

---

## ⏱️ Expected Timeline

### Option A: Skip Test (RECOMMENDED - Faster)

```
Day 1 Morning (9 AM):
  Submit preprocessing: 0a, 0b
  Run: python3 filter_to_EUR_python.py
  
Day 1 Morning (10 AM):
  Preprocessing complete
  Submit all 6 jobs: sbatch 1_run_bolt_lmm.sbatch.sh
  
Day 1 Evening (6-10 PM):
  All 6 jobs complete ✅ (8-12 hours runtime)
  Results ready!

Total: ~9-13 hours from start to results
```

### Option B: With Test (Conservative)

```
Day 1 Morning: Preprocessing (~1h)
Day 1 10 AM: Submit test (0c)
Day 1 Evening (6-10 PM): Test completes (8-12h)
Day 2 Morning: Submit remaining 5 jobs
Day 2 Evening: All complete

Total: ~1.5-2 days
```

**Recommendation**: Option A (skip test) - faster and we've thoroughly debugged!

---

## 🚀 Minimal Command Sequence (Skip Test - RECOMMENDED)

```bash
# Complete workflow in one day:
cd Isolation_GWAS_BOLT-LMM
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

# Preprocessing (~1 hour)
sbatch 0a_convert_to_bed.sbatch.sh
# Wait ~10 min, then:
bash create_EUR_MM_keep.sh  # Create EUR_MM.keep
python3 filter_to_EUR_python.py  # Filter to 426K EUR samples (~3 min)
sbatch 0b_prepare_model_snps.sbatch.sh
# Wait ~30 min for model SNPs

# Full analysis (all 6 jobs at once)
sbatch 1_run_bolt_lmm.sbatch.sh

# Wait ~8-12 hours
# Results ready! All 6 files in results/ directory
ls -lh results/Day_NoPCs/EUR/
ls -lh results/Day_10PCs/EUR/
```

---

## 📁 Final Directory Structure

```
Isolation_GWAS_BOLT-LMM/
├── Scripts (*.sh, *.sbatch.sh)
├── Documentation (*.md)
└── results/ (gitignored)
    ├── Day_NoPCs/EUR/
    │   ├── bolt_Loneliness.Day_NoPCs.stats.gz      ⭐
    │   ├── bolt_FreqSoc.Day_NoPCs.stats.gz         ⭐
    │   └── bolt_AbilityToConfide.Day_NoPCs.stats.gz ⭐
    └── Day_10PCs/EUR/
        ├── bolt_Loneliness.Day_10PCs.stats.gz      ⭐
        ├── bolt_FreqSoc.Day_10PCs.stats.gz         ⭐
        └── bolt_AbilityToConfide.Day_10PCs.stats.gz ⭐
```

---

## 🆚 Old vs New Workflow

| Feature | Old (Variant Split) | New (Simplified) |
|---------|---------------------|------------------|
| Total jobs | 138 | **6** ✅ |
| Variant splits | 69 chunks | **None** (full genome) |
| Per-job variants | ~19K | **~1.3M** (complete) |
| Wall time | 3-4 days | **~1 day** ✅ |
| Combining step | Required | **Not needed** ✅ |
| Output files | 414 intermediate + 6 final | **6 final** ✅ |
| Complexity | High | **Low** ✅ |
| Failure recovery | Complex | **Simple** ✅ |

---

## ✅ Pre-Flight Checklist

Before starting, verify:

- [ ] In correct directory: `Isolation_GWAS_BOLT-LMM/` (not parent `ukb21942/`)
- [ ] BOLT-LMM installed: `bolt --help` works
- [ ] Conda environment exists: `conda activate /home/mabdel03/data/conda_envs/bolt_lmm`
- [ ] Input files exist:
  - [ ] `geno/ukb_genoHM3/ukb_genoHM3.pgen` (will be converted)
  - [ ] `pheno/isolation_run_control.tsv.gz` (all samples)
  - [ ] `sqc/sqc.20220316.tsv.gz` (all samples)
  - [ ] `sqc/population.20220316/EUR_MM.keep` (426K EUR samples, includes relatives)
  - [ ] `sqc/population.20220316/WB_MM.keep` and `NBW_MM.keep` (used to create EUR_MM)

---

## 📞 Getting Help

**Issue with setup?** → See `SETUP_CHECKLIST.md` or `IMPORTANT_FIXES.md`  
**Understanding binary traits?** → See `BINARY_TRAITS_INFO.md`  
**Quick reference?** → See `QUICK_START.md`  
**Full workflow details?** → See `SIMPLIFIED_WORKFLOW.md`  
**Scientific background?** → See `README.md`

---

**This is the complete, working workflow. Follow these steps and you'll have GWAS results in ~1 day!** 🎯


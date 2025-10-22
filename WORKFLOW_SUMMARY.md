# BOLT-LMM Workflow Summary (Final Version)

## 🎯 Quick Reference Card

**Total Jobs**: 6 (not 138!)  
**Resources per job**: 150GB RAM, 100 CPUs, 47h limit  
**Actual runtime**: 1-2 hours per job  
**Output location**: `Isolation_GWAS_BOLT-LMM/results/`  
**Ancestry filter**: EUR only (via EUR.remove file)  
**Chromosomes**: Autosomes 1-22 only (BOLT-LMM limitation)

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

- [ ] **Step 2**: Create EUR.remove file
  ```bash
  bash create_remove_file.sh
  # Takes <1 second
  # Converts: EUR.keep → EUR.remove (BOLT uses --remove)
  ```

- [ ] **Step 3**: Create model SNPs
  ```bash
  sbatch 0b_prepare_model_snps.sbatch.sh
  # Wait ~15-30 min
  # Creates: ~444K SNPs (r²<0.5, MAF≥0.5%, 80GB RAM)
  ```

### ✅ Validation

- [ ] **Step 4**: Test run (1 of 6 jobs)
  ```bash
  sbatch 0c_test_simplified.sbatch.sh
  # Wait ~1-2 hours
  # Tests: Loneliness + Day_NoPCs + EUR
  # Check: grep "TEST PASSED" bolt_test_simple.*.out
  ```

### ✅ Full Analysis

- [ ] **Step 5**: Submit all 6 jobs
  ```bash
  sbatch 1_run_bolt_lmm.sbatch.sh
  # Submits array job with 6 tasks
  # All run concurrently
  ```

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

1. **Autosomes Only**: Converted genotypes include chr 1-22 only (BOLT-LMM limitation)

2. **EUR Filtering**: Via EUR.remove file (BOLT uses `--remove`, not `--keep`)

3. **No Variant Splitting**: Each job processes full genome (BOLT-LMM is efficient enough)

4. **No Combining**: Results are final outputs directly from BOLT-LMM

5. **Model SNPs**: r²<0.5 threshold chosen for HM3 data (~444K SNPs)

6. **High Resources**: 150GB RAM, 100 CPUs ensures fast, stable computation

---

## ⏱️ Expected Timeline

```
Day 1 Morning (9 AM):
  Submit preprocessing (Steps 1-3)
  
Day 1 Afternoon (12 PM):
  Preprocessing completes
  Submit test run (Step 4)
  
Day 1 Late Afternoon (2-4 PM):
  Test completes and passes ✅
  Submit full analysis (Step 5) - 6 jobs
  
Day 1 Evening (6-8 PM):
  All 6 jobs complete ✅
  Results ready for QC and downstream analysis!

Total: ~9-11 hours from start to GWAS results
```

---

## 🚀 Minimal Command Sequence

```bash
# Assuming you're starting fresh:
cd Isolation_GWAS_BOLT-LMM
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

sbatch 0a_convert_to_bed.sbatch.sh && \
sleep 600 && \
bash create_remove_file.sh && \
sbatch 0b_prepare_model_snps.sbatch.sh

# Wait ~45 min total, then:
sbatch 0c_test_simplified.sbatch.sh

# Wait ~2h, verify test passed, then:
sbatch 1_run_bolt_lmm.sbatch.sh

# Done! Results appear in ~2h
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
  - [ ] `sqc/population.20220316/EUR.keep` (EUR samples to analyze)

---

## 📞 Getting Help

**Issue with setup?** → See `SETUP_CHECKLIST.md` or `IMPORTANT_FIXES.md`  
**Understanding binary traits?** → See `BINARY_TRAITS_INFO.md`  
**Quick reference?** → See `QUICK_START.md`  
**Full workflow details?** → See `SIMPLIFIED_WORKFLOW.md`  
**Scientific background?** → See `README.md`

---

**This is the complete, working workflow. Follow these steps and you'll have GWAS results in ~1 day!** 🎯


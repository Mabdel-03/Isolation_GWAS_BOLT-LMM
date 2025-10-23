# Current Status and Next Steps

**Last Updated**: October 22, 2025  
**Status**: Ready to run with EUR pre-filtering approach

---

## ✅ What's Working

### Completed Setup:
1. ✅ **BOLT-LMM v2.5** (June 2025 release) installed at `/home/mabdel03/data/software/BOLT-LMM_v2.5/`
2. ✅ Conda environment created: `/home/mabdel03/data/conda_envs/bolt_lmm`
3. ✅ Genotypes converted to bed format (chr 1-22, autosomes only, ~1.3M variants)
4. ✅ Model SNPs created: 444,241 SNPs (r²<0.5, MAF≥0.5%, 80GB RAM)
5. ✅ Simplified 6-job workflow implemented (no variant splitting)
6. ✅ EUR_MM.keep created: **426,602 EUR samples (includes related individuals)**
7. ✅ EUR filtering via Python (robust, handles relatedness)
8. ✅ **Multithreading enabled: 100 threads per job** (12.5× typical BOLT usage)

### Current Workflow:
- **6 jobs total** (3 phenotypes × 2 covariate sets)
- **150GB RAM, 100 CPUs** per job
- **No variant splitting** - full genome per job
- **EUR filtering** via pre-filtered data files
- **~1 day** total timeline

---

## 🚧 Current Issue: EUR Filtering

**Problem**: bash filter script (`filter_to_EUR.sh`) produced incomplete output

**Solution**: Use Python version instead:
```bash
python3 filter_to_EUR_python.py
```

**This creates**:
- `isolation_run_control.EUR.tsv.gz` (~420K EUR_MM samples, includes related)
- `sqc.EUR.tsv.gz` (~426K EUR_MM samples, includes related)

**Using EUR_MM.keep (not EUR.keep)**:
- EUR_MM: 426,602 samples (includes related individuals)
- EUR: 353,122 samples (unrelated only)
- **Gain: +73,480 samples** for better statistical power!
- Appropriate for BOLT-LMM mixed models

---

## 🎯 Immediate Next Steps on HPC

```bash
# 1. Navigate to repository
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM

# 2. Pull latest updates
git pull origin main

# 3. Activate conda
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

# 4. Delete incomplete EUR files (if any)
rm -f isolation_run_control.EUR.tsv.gz sqc.EUR.tsv.gz

# 5. Run Python EUR filter
python3 filter_to_EUR_python.py
# Wait for completion (~2-3 minutes)
# Should see progress indicators

# 6. Verify EUR files created successfully
ls -lh *.EUR.tsv.gz
# Should see two files, each 50-200MB (NOT 99 bytes!)

# 7. Check sample counts
zcat isolation_run_control.EUR.tsv.gz | wc -l
# Should show ~426,603 (426,602 EUR_MM samples + 1 header)

# 8. Submit test run
sbatch 0c_test_simplified.sbatch.sh

# 9. Monitor
tail -f bolt_test_simple.*.out
# Should see: "Total indivs after QC: 350000+" (NOT 0!)

# 10. If test passes, submit full analysis
sbatch 1_run_bolt_lmm.sbatch.sh
```

---

## 📋 Complete Preprocessing Checklist

- [x] BOLT-LMM installed
- [x] Conda environment created
- [x] Genotypes converted (chr 1-22 only)
- [x] Model SNPs created (444K SNPs)
- [ ] EUR-filtered files created ← **DO THIS NOW**
- [ ] Test run passes
- [ ] Full analysis submitted

---

## 🔧 Key Configuration Details

### Genotype Conversion (Step 1):
- **Input**: ukb_genoHM3.pgen (all chromosomes)
- **Filter**: `--chr 1-22` (autosomes only)
- **Output**: ukb_genoHM3_bed.bed/bim/fam (~145GB)
- **Why autosomes**: BOLT-LMM doesn't recognize MT/X/Y chromosome codes

### EUR Filtering (Step 2):
- **Method**: Pre-filter phenotype/covariate files
- **Script**: `filter_to_EUR_python.py` (robust Python implementation)
- **Input**: All samples (502K pheno, 488K covar)
- **Output**: EUR only (~353K samples)
- **Why**: Simpler than --remove, avoids .fam ID issues

### Model SNPs (Step 3):
- **Parameters**: MAF≥0.5%, r²<0.5, HWE adjusted
- **Output**: 444,241 SNPs
- **Memory**: 80GB (required for ~500K samples)
- **Chromosomes**: 1-22 only

### Test Run (Step 4):
- **Phenotype**: Loneliness
- **Covariate set**: Day_NoPCs
- **Samples**: EUR (~353K)
- **Variants**: ~1.3M (full genome)
- **Resources**: 150GB RAM, 100 CPUs
- **Runtime**: 1-2 hours

### Full Analysis (Step 5):
- **Jobs**: 6 (array)
- **Per job**: 150GB, 100 CPUs, 47h limit
- **Runtime**: 1-2 hours each
- **Concurrent**: All 6 can run simultaneously

---

## 📁 Directory Structure

```
Isolation_GWAS_BOLT-LMM/
├── Scripts (*.sh, *.py, *.sbatch.sh)
├── Documentation (*.md)
├── isolation_run_control.EUR.tsv.gz  ← EUR-filtered phenotypes
├── sqc.EUR.tsv.gz                    ← EUR-filtered covariates
└── results/                          ← Output directory
    ├── Day_NoPCs/EUR/
    │   ├── bolt_Loneliness.Day_NoPCs.stats.gz      (after analysis)
    │   ├── bolt_FreqSoc.Day_NoPCs.stats.gz
    │   └── bolt_AbilityToConfide.Day_NoPCs.stats.gz
    └── Day_10PCs/EUR/
        ├── bolt_Loneliness.Day_10PCs.stats.gz
        ├── bolt_FreqSoc.Day_10PCs.stats.gz
        └── bolt_AbilityToConfide.Day_10PCs.stats.gz
```

---

## 🐛 Issues Resolved

1. ✅ MT chromosome error → autosomes only conversion
2. ✅ Too few model SNPs → r²<0.5 threshold
3. ✅ Out of memory → 80GB for model SNPs, 150GB for BOLT
4. ✅ SLURM variable mismatch → use SLURM_NTASKS
5. ✅ Qt conda activation → removed -u flag
6. ✅ Variant splitting complexity → simplified to 6 jobs
7. ✅ ID matching issues → pre-filter files instead of --remove
8. ⏳ EUR filter incomplete → use Python version

---

## 📚 Documentation Files (Updated)

All 12 .md files reflect current workflow:
- ✅ WORKFLOW_SUMMARY.md
- ✅ SIMPLIFIED_WORKFLOW.md  
- ✅ START_HERE.md
- ✅ QUICK_START.md
- ✅ RUN_ANALYSIS.md
- ✅ SETUP_CHECKLIST.md
- ✅ FILE_MANIFEST.md
- ✅ IMPORTANT_FIXES.md
- ✅ README.md
- ✅ BINARY_TRAITS_INFO.md
- ✅ GITHUB_SETUP.md
- ✅ ENVIRONMENT_SETUP.md

---

## 🚀 What To Do RIGHT NOW

**Action Required**: Create EUR-filtered files

```bash
cd Isolation_GWAS_BOLT-LMM
python3 filter_to_EUR_python.py

# Wait for:
# "Filtering Complete!"

# Then:
sbatch 0c_test_simplified.sbatch.sh
```

**Once EUR filtering completes, the pipeline is ready to run!**

---

## 💡 Why This Approach is Better

**Old approach (--remove)**:
- Create EUR.remove file
- BOLT uses --remove=EUR.remove
- ❌ Requires ID matching between .fam and .keep
- ❌ .fam had placeholder IDs (-1, -2, -3)
- ❌ Result: 0 individuals after filtering

**New approach (pre-filter)**:
- Filter phenotype/covariate files to EUR using Python
- BOLT uses EUR-filtered files directly
- ✅ No ID matching needed with .fam
- ✅ More transparent (clear which samples analyzed)
- ✅ More reliable (Python handles data properly)

---

## 📊 Expected Results

After full analysis (Step 5) completes, you'll have:

**6 final GWAS summary statistic files**:
1. `bolt_Loneliness.Day_NoPCs.stats.gz` (~1-5GB, ~1.3M variants, ~353K EUR samples)
2. `bolt_FreqSoc.Day_NoPCs.stats.gz`
3. `bolt_AbilityToConfide.Day_NoPCs.stats.gz`
4. `bolt_Loneliness.Day_10PCs.stats.gz`
5. `bolt_FreqSoc.Day_10PCs.stats.gz`
6. `bolt_AbilityToConfide.Day_10PCs.stats.gz`

Each with BOLT-LMM association statistics ready for downstream analysis!

---

*Run `python3 filter_to_EUR_python.py` now and you're ready to go!* 🚀


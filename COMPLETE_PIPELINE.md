# Complete Pipeline Overview

**End-to-End Workflow**: UK Biobank GWAS → MTAG-Ready Results

---

## 📊 Pipeline Steps

```
Step 0: Preprocessing (one-time setup, ~1 hour)
  ├─ 0a: Convert genotypes (chr 1-22)
  ├─ EUR_MM: Create 426K EUR sample list
  ├─ Filter: EUR-only pheno/covar files
  └─ 0b: Create 444K model SNPs

Step 1: BOLT-LMM GWAS (6 jobs, 8-12 hours)
  ├─ Loneliness + Day_NoPCs
  ├─ FreqSoc + Day_NoPCs
  ├─ AbilityToConfide + Day_NoPCs
  ├─ Loneliness + Day_10PCs
  ├─ FreqSoc + Day_10PCs
  └─ AbilityToConfide + Day_10PCs

Step 2: MTAG Conversion (~3 minutes)
  └─ Convert BOLT → MTAG format (rsID mapping)

Step 3: Multi-Trait Analysis (MTAG)
  └─ Your next step!
```

---

## 🚀 Complete Command Sequence

```bash
# Navigate to repository
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

# ===== STEP 0: PREPROCESSING (~1 hour) =====

sbatch 0a_convert_to_bed.sbatch.sh       # Wait ~10 min
bash create_EUR_MM_keep.sh                # <1 second
python3 filter_to_EUR_python.py           # ~3 min
sbatch 0b_prepare_model_snps.sbatch.sh   # Wait ~30 min

# ===== STEP 1: BOLT-LMM GWAS (8-12 hours) =====

sbatch 1_run_bolt_lmm.sbatch.sh           # Submit all 6 jobs
# Wait 8-12 hours for completion

# ===== STEP 2: MTAG CONVERSION (~3 min) =====

bash 2_mtag_conversion.sh                 # Convert to MTAG format

# ===== STEP 3: MULTI-TRAIT ANALYSIS =====

# Run MTAG (see MTAG documentation)
# Input files: MTAG_Inputs/*.mtag.sumstats.txt
```

---

## 📁 Complete File Tree (After All Steps)

```
Isolation_GWAS_BOLT-LMM/
│
├── 📜 Scripts
│   ├── 0a_convert_to_bed.sbatch.sh
│   ├── 0b_prepare_model_snps.sbatch.sh
│   ├── 1_run_bolt_lmm.sbatch.sh        ⭐ Main GWAS
│   ├── 2_mtag_conversion.sh             ⭐ MTAG prep
│   ├── run_single_phenotype.sh
│   ├── create_EUR_MM_keep.sh
│   └── filter_to_EUR_python.py
│
├── 📊 Data Files (gitignored)
│   ├── isolation_run_control.EUR.tsv.gz (~420K EUR samples)
│   ├── sqc.EUR.tsv.gz (~426K EUR samples)
│   │
│   ├── results/
│   │   ├── Day_NoPCs/EUR/
│   │   │   ├── bolt_Loneliness.Day_NoPCs.stats.gz      (1-5GB)
│   │   │   ├── bolt_FreqSoc.Day_NoPCs.stats.gz
│   │   │   └── bolt_AbilityToConfide.Day_NoPCs.stats.gz
│   │   └── Day_10PCs/EUR/
│   │       ├── bolt_Loneliness.Day_10PCs.stats.gz
│   │       ├── bolt_FreqSoc.Day_10PCs.stats.gz
│   │       └── bolt_AbilityToConfide.Day_10PCs.stats.gz
│   │
│   └── MTAG_Inputs/
│       ├── Loneliness.Day_NoPCs.mtag.sumstats.txt      (~80MB)
│       ├── FreqSoc.Day_NoPCs.mtag.sumstats.txt
│       ├── AbilityToConfide.Day_NoPCs.mtag.sumstats.txt
│       ├── Loneliness.Day_10PCs.mtag.sumstats.txt
│       ├── FreqSoc.Day_10PCs.mtag.sumstats.txt
│       └── AbilityToConfide.Day_10PCs.mtag.sumstats.txt
│
└── 📚 Documentation (19 .md files)
```

---

## 📊 Data Processing Summary

| Step | Input | Output | Format |
|------|-------|--------|--------|
| **BOLT-LMM** | 426K EUR samples, 1.3M variants | 6 .stats.gz files | BOLT format |
| **MTAG Conversion** | 6 BOLT .stats.gz files | 6 .mtag.sumstats.txt files | MTAG format |
| **MTAG Analysis** | 6 MTAG sumstats files | Multi-trait results | MTAG output |

---

## 🔑 Key Specifications

**Software**:
- BOLT-LMM v2.5 (June 2025)
- Python 3.10 (pandas for MTAG conversion)
- MTAG (for multi-trait analysis)

**Sample Population**:
- EUR_MM: 426,602 individuals (includes 73K related)
- WB_MM: 409,853 (White British)
- NBW_MM: 16,749 (Non-British White)

**Variants**:
- Total: ~1.26M autosomal variants (chr 1-22)
- With rsIDs: 98% (from annotation file)
- Model SNPs: 444K (for GRM)

**Resources per BOLT Job**:
- Memory: 150GB
- CPUs: 100 (multithreading)
- Time: 8-12 hours actual, 47h limit

---

## ⏱️ Complete Timeline

```
Hour 0:       Start preprocessing
Hour 1:       Preprocessing complete, submit BOLT jobs
Hour 9-13:    BOLT jobs complete (6 GWAS results)
Hour 13:      Run MTAG conversion (~3 min)
Hour 13+:     Ready for multi-trait analysis!

Total: ~9-13 hours from start to MTAG-ready files
```

---

## ✅ Current Status

Based on your output:

**Completed** ✅:
- Preprocessing (all steps)
- Day_NoPCs BOLT-LMM (3 phenotypes)
- MTAG conversion for Day_NoPCs (3 files)

**In Progress** ⏳:
- Day_10PCs BOLT-LMM (3 phenotypes)
  - Tasks 4-6 still running or failed with covariate error
  - Need to pull fix and rerun if failed

**Next** 📋:
- Complete Day_10PCs jobs
- Rerun MTAG conversion to add Day_10PCs files
- Run MTAG multi-trait analysis

---

## 🎯 Immediate Actions

### If Day_10PCs Jobs Are Still Running:
```bash
# Just wait for completion
# Then: bash 2_mtag_conversion.sh (to add Day_10PCs MTAG files)
```

### If Day_10PCs Jobs Failed:
```bash
# Pull covariate fix
git pull origin main

# Cancel failed jobs
scancel -u mabdel03

# Resubmit
sbatch 1_run_bolt_lmm.sbatch.sh

# Wait 8-12 hours
# Then: bash 2_mtag_conversion.sh
```

---

## 📚 Complete Documentation

All 19 .md files updated to document:
- ✅ BOLT-LMM v2.5
- ✅ EUR_MM (426K samples, includes related)
- ✅ 100 threads multithreading
- ✅ 6-job simplified workflow
- ✅ **Step 2: MTAG conversion** (NEW!)
- ✅ Complete pipeline (GWAS → MTAG-ready)

---

**You now have 3 MTAG-ready files! Once Day_10PCs completes, you'll have all 6!** 🎉


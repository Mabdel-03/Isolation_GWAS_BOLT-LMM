# ⚠️ IMPORTANT: Use the NEW Simplified Scripts!

## 🚨 You Ran the OLD Script (Don't Use This!)

The error you got was from running the **OLD, DEPRECATED 138-job workflow**:

```bash
❌ bash 1a_bolt_lmm.sbatch.sh  # OLD - 138 jobs, don't use!
```

---

## ✅ Use the NEW Simplified Script Instead

```bash
✅ sbatch 1_run_bolt_lmm.sbatch.sh  # NEW - 6 jobs, use this!
```

---

## 📁 Script Comparison

| Old (Deprecated) | New (Recommended) | Why |
|------------------|-------------------|-----|
| `1a_bolt_lmm.sbatch.sh` | `1_run_bolt_lmm.sbatch.sh` | Simplified |
| 138 jobs | **6 jobs** | 96% fewer jobs |
| Variant splitting | **Full genome** | Simpler |
| `bash 1a...` | **`sbatch 1_...`** | Direct sbatch |
| Complex | **Simple** | Easier |

---

## 🔧 What Caused Your Error

The old script had:
```bash
sbatch --nodes=1 ...
```

The kellis partition doesn't need/allow `--nodes=1` specification with `-n` flag.

**Fixed in both scripts** (removed --nodes=1)

---

## 🚀 THE CORRECT COMMAND

```bash
cd Isolation_GWAS_BOLT-LMM
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

# Use THIS command (not 1a):
sbatch 1_run_bolt_lmm.sbatch.sh
```

---

## 📊 What This Runs

**6 array jobs** (NOT 138!):
1. Loneliness + Day_NoPCs
2. FreqSoc + Day_NoPCs
3. AbilityToConfide + Day_NoPCs
4. Loneliness + Day_10PCs
5. FreqSoc + Day_10PCs
6. AbilityToConfide + Day_10PCs

Each:
- 150GB RAM
- 100 CPUs
- 8-12 hours
- 426K EUR_MM samples
- Full genome (1.3M variants)

---

## 🗑️ Deprecated Scripts (Don't Use)

These are kept for reference but **DO NOT USE**:
- ❌ `1a_bolt_lmm.sbatch.sh` (old 138-job workflow)
- ❌ `bolt_lmm.sh` (old variant-split worker)
- ❌ `1b_combine_bolt_output.sh` (old combining script)
- ❌ `0c_test_run.sbatch.sh` (old test with variant split)

---

## ✅ Current Scripts (Use These!)

**Preprocessing**:
- ✅ `0a_convert_to_bed.sbatch.sh`
- ✅ `0b_prepare_model_snps.sbatch.sh`
- ✅ `create_EUR_MM_keep.sh`
- ✅ `filter_to_EUR_python.py`

**Analysis**:
- ✅ **`1_run_bolt_lmm.sbatch.sh`** ← MAIN SCRIPT
- ✅ `run_single_phenotype.sh` (worker called by 1_run)

**Optional**:
- ✅ `0c_test_simplified.sbatch.sh` (can skip)

---

## 🎯 Right Now on HPC

```bash
# Pull the --nodes=1 fix
git pull origin main

# Run the CORRECT script
sbatch 1_run_bolt_lmm.sbatch.sh

# NOT: bash 1a_bolt_lmm.sbatch.sh
```

**This will work!** 🚀


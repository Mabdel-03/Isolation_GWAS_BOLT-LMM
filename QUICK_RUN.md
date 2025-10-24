# Quick Run Guide - Skip Test, Go Directly to Results

**Timeline**: ~9-13 hours from start to GWAS results  
**Approach**: Skip test (0c), run all 6 jobs directly

---

## ⚡ Fast Track Commands

```bash
# Navigate
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM

# Activate
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

# === PREPROCESSING (~1 hour) ===

# If not done: Convert genotypes (chr 1-22 only)
sbatch 0a_convert_to_bed.sbatch.sh
# Wait ~10 min, monitor: tail -f 0a.out

# Create EUR_MM.keep and filter files
bash create_EUR_MM_keep.sh
python3 filter_to_EUR_python.py
# Takes ~3 min total

# If not done: Create model SNPs
sbatch 0b_prepare_model_snps.sbatch.sh  
# Wait ~30 min, monitor: tail -f 0b.out

# === ANALYSIS (8-12 hours) ===

# Submit ALL 6 jobs at once
sbatch 1_run_bolt_lmm.sbatch.sh

# Monitor
squeue -u $USER

# Watch results appear
watch -n 120 'ls -lh results/*/EUR/*.stats.gz 2>/dev/null'

# Wait ~8-12 hours
# All 6 jobs complete concurrently
```

---

## 📊 The 6 Jobs

```
Task 1 → Loneliness      + Day_NoPCs   → 1_1.out
Task 2 → FreqSoc         + Day_NoPCs   → 1_2.out
Task 3 → AbilityToConfide + Day_NoPCs  → 1_3.out
Task 4 → Loneliness      + Day_10PCs   → 1_4.out
Task 5 → FreqSoc         + Day_10PCs   → 1_5.out
Task 6 → AbilityToConfide + Day_10PCs  → 1_6.out

Each: 150GB, 100 CPUs, 426K EUR_MM samples, 1.3M variants
Runtime: 8-12 hours each
```

---

## ✅ Success Check & MTAG Conversion

After ~8-12 hours:

```bash
# All jobs done?
squeue -u $USER
# Should show: no jobs running

# All 6 BOLT results created?
ls results/Day_NoPCs/EUR/
ls results/Day_10PCs/EUR/

# Should see 6 .stats.gz files total:
# Day_NoPCs:  Loneliness, FreqSoc, AbilityToConfide
# Day_10PCs:  Loneliness, FreqSoc, AbilityToConfide

# Check file sizes (should be 1-5GB each)
ls -lh results/*/EUR/*.stats.gz

# === STEP 2: Convert to MTAG Format ===

bash 2_mtag_conversion.sh

# Creates MTAG_Inputs/ with .mtag.sumstats.txt files
# - Maps variants to rsIDs (98% coverage)
# - Formats for multi-trait analysis
# - 6 output files (~80MB each)

# Verify MTAG files
ls -lh MTAG_Inputs/
# Should see up to 6 .mtag.sumstats.txt files
```

---

## 📧 Email Notifications

You'll receive emails at: **mabdel03@mit.edu**

**Timeline**:
1. ~10 AM: "Array job bolt_lmm Began"
2. ~10 AM: 6 emails "Array task X Began" (one per job)
3. ~6-10 PM: 6 emails "Array task X Ended" (as jobs finish)
4. ~10 PM: "Array job bolt_lmm Ended" (all complete)

---

## 🔍 Monitor Individual Jobs

```bash
# Check specific job output
tail -f 1_1.out  # Loneliness + Day_NoPCs
tail -f 1_2.out  # FreqSoc + Day_NoPCs
# etc.

# Check for errors
cat 1_1.err
cat 1_2.err

# See which jobs are done
ls -lh results/Day_NoPCs/EUR/
ls -lh results/Day_10PCs/EUR/
```

---

## ⏱️ What to Expect

### Hour 0-2: GRM Computation
```
Reading genotypes...
Computing GRM from 444K model SNPs...
[Progress for each job]
```

### Hour 2-4: Setup Complete
```
Total indivs after QC: ~420,000-426,000
Starting association testing...
```

### Hour 4-10: Association Testing
```
Testing chromosome 1... 2... 3... [progress]
[Each job progresses independently]
```

### Hour 8-12: Completion
```
Jobs start finishing
Results appear in results/ directory
```

---

## 🎯 After Jobs Complete

**Verify all 6 results**:
```bash
for covar in Day_NoPCs Day_10PCs; do
  for pheno in Loneliness FreqSoc AbilityToConfide; do
    file="results/${covar}/EUR/bolt_${pheno}.${covar}.stats.gz"
    if [ -f "$file" ]; then
      size=$(ls -lh "$file" | awk '{print $5}')
      vars=$(zcat "$file" | wc -l)
      echo "✅ $pheno + $covar: $size, $vars variants"
    else
      echo "❌ MISSING: $pheno + $covar"
    fi
  done
done
```

---

## 💡 Why This Works

1. ✅ **Thorough debugging**: All ID matching, covariate issues resolved
2. ✅ **EUR_MM files created**: 426K samples, proper headers
3. ✅ **Scripts validated**: Command structure tested
4. ✅ **Resources adequate**: 150GB, 100 CPUs, 47h per job
5. ✅ **Independent jobs**: Each can succeed/fail independently

**Risk is minimal, reward is faster results!**

---

## 🚀 RUN THIS NOW

```bash
cd Isolation_GWAS_BOLT-LMM
conda activate /home/mabdel03/data/conda_envs/bolt_lmm
sbatch 1_run_bolt_lmm.sbatch.sh
```

**Results in ~8-12 hours!** 🎯


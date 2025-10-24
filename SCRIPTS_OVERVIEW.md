# Scripts Overview - Current Working Pipeline

**All deprecated scripts removed!** Only current, production-ready scripts remain.

---

## 🚀 Production Scripts (Use These!)

### Preprocessing (SLURM Batch Jobs)

**0a_convert_to_bed.sbatch.sh**
- Convert genotypes from pgen to bed format
- Autosomes only (chr 1-22)
- Resources: 32GB, 8 tasks, 2h
- Output: `0a.out`, `0a.err`
- Creates: `ukb_genoHM3_bed.bed/bim/fam`

**0b_prepare_model_snps.sbatch.sh**
- Create LD-pruned SNPs for GRM
- r²<0.5, MAF≥0.5%, autosomes only
- Resources: 80GB, 8 tasks, 2h
- Output: `0b.out`, `0b.err`
- Creates: `ukb_genoHM3_modelSNPs.txt` (444K SNPs)

---

### EUR Filtering (Interactive)

**create_EUR_MM_keep.sh**
- Combines WB_MM.keep + NBW_MM.keep
- Creates EUR_MM.keep (426,602 EUR samples, includes related)
- Runtime: <1 second

**filter_to_EUR_python.py** ⭐ PRIMARY
- Filters phenotype/covariate files to EUR_MM
- Ensures FID/IID headers for BOLT compatibility
- Runtime: 2-3 minutes
- Creates: `isolation_run_control.EUR.tsv.gz`, `sqc.EUR.tsv.gz`

**filter_to_EUR.sh** (alternative bash version)
- Same functionality, bash implementation
- Use Python version (more robust)

---

### Analysis (SLURM Batch Jobs)

**1_run_bolt_lmm.sbatch.sh** ⭐ MAIN ANALYSIS SCRIPT
- Array job with 6 tasks
- Each task: One phenotype-covariate combination
- Resources: 150GB, 100 tasks, 47h per job
- Output: `1_1.out` through `1_6.out` (and .err files)
- Email notifications enabled
- **THIS IS THE SCRIPT TO RUN!**

**run_single_phenotype.sh** (worker script)
- Called by 1_run_bolt_lmm.sbatch.sh
- Runs BOLT-LMM for one phenotype
- Full genome analysis (1.3M variants)
- Uses EUR_MM-filtered files
- 100 threads multithreading

**0c_test_simplified.sbatch.sh** (optional)
- Tests one phenotype (Loneliness + Day_NoPCs)
- Full analysis (8-12 hours)
- Can skip and run all 6 jobs directly
- Resources: 150GB, 100 tasks, 47h
- Output: `0c.out`, `0c.err`

---

### Post-Processing (MTAG Preparation)

**2_mtag_conversion.sh**
- Wrapper for MTAG format conversion
- Checks for BOLT-LMM results
- Calls convert_to_MTAG.py
- Reports conversion status
- Runtime: 2-5 minutes
- Run after: BOLT-LMM jobs complete

**convert_to_MTAG.py**
- Converts BOLT → MTAG format
- Maps chr:pos:ref:alt → rsIDs (98% coverage)
- Calculates z-scores (BETA/SE)
- Detects sample sizes automatically
- Creates: MTAG_Inputs/*.mtag.sumstats.txt

---

### Diagnostic & Utility Scripts

**check_sample_overlap.sh**
- Verifies sample counts and ID formats
- Checks overlap between files
- Useful for troubleshooting

**debug_bolt_command.sh**
- Tests BOLT-LMM arguments incrementally
- Helps identify command-line errors

**test_bolt_minimal.sh**
- Minimal BOLT-LMM tests
- Quick validation

**test_no_filter.sh**
- Tests BOLT without EUR filtering
- Helps diagnose filtering issues

**fix_fam_ids.sh**
- Fixes .fam file IDs from .psam
- (Not needed with current pre-filtering approach)

---

### Configuration

**paths.sh**
- Central path configuration
- BOLT-LMM v2.5 paths
- LD scores and genetic map locations

---

## 🗑️ Deleted Scripts (Removed to Avoid Confusion)

**Old 138-job variant-split workflow**:
- ~~1a_bolt_lmm.sbatch.sh~~ (138 jobs, variant splits)
- ~~bolt_lmm.sh~~ (worker for variant splits)
- ~~1b_combine_bolt_output.sh~~ (combining results)
- ~~combine_bolt_logs.sh~~ (combining helper)
- ~~combine_bolt_sumstats.sh~~ (combining helper)
- ~~99_check_progress.sh~~ (progress for variant splits)

**Deprecated approaches**:
- ~~0c_test_run.sbatch.sh~~ (old test with variant splits)
- ~~0_convert_to_bed.sh~~ (non-batch version)
- ~~0_prepare_model_snps.sh~~ (non-batch version)
- ~~create_remove_file.sh~~ (EUR.remove approach, replaced by pre-filtering)

---

## 📋 Current Workflow Commands

```bash
# Preprocessing
sbatch 0a_convert_to_bed.sbatch.sh
bash create_EUR_MM_keep.sh
python3 filter_to_EUR_python.py
sbatch 0b_prepare_model_snps.sbatch.sh

# Analysis (all 6 BOLT-LMM jobs)
sbatch 1_run_bolt_lmm.sbatch.sh

# Post-processing (after BOLT completes)
bash 2_mtag_conversion.sh

# Optional: Test first
sbatch 0c_test_simplified.sbatch.sh  # Then: sbatch 1_run...
```

---

## ✅ Key Points

1. **Only ONE main analysis script**: `1_run_bolt_lmm.sbatch.sh`
2. **No variant splitting**: Full genome per job
3. **6 jobs total**: Simple and fast
4. **No combining needed**: Results are final
5. **All scripts use batch submission**: No interactive versions

---

## 🎯 To Run Analysis

**Single command**:
```bash
sbatch 1_run_bolt_lmm.sbatch.sh
```

**That's it!** No confusion about which script to use.

---

*All deprecated scripts removed for clarity. See documentation for detailed usage of current scripts.*


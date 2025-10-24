# Repository Contents - Clean, Production-Ready Pipeline

**Last Updated**: October 23, 2025  
**Status**: All deprecated scripts removed, only current scripts remain

---

## 📊 Repository Statistics

- **Total files**: 42
- **Scripts (.sh/.py)**: 14
- **Documentation (.md)**: 17
- **Configuration**: 3 (paths.sh, .gitignore, LICENSE)
- **Deprecated scripts removed**: 10
- **Total commits**: 70+

---

## 📁 Complete File Listing

### 🚀 Main Analysis Scripts (2)
```
1_run_bolt_lmm.sbatch.sh     ⭐ MAIN - Submit this for full analysis!
run_single_phenotype.sh        Worker called by 1_run
```

### ⚙️ Preprocessing Scripts (4)
```
0a_convert_to_bed.sbatch.sh    Convert genotypes (chr 1-22)
0b_prepare_model_snps.sbatch.sh Create 444K model SNPs (r²<0.5)
create_EUR_MM_keep.sh           Create EUR_MM.keep (426K samples)
filter_to_EUR_python.py         Filter pheno/covar to EUR
```

### 🧪 Optional Test (1)
```
0c_test_simplified.sbatch.sh   Test 1 job (optional, 8-12h)
```

### 🔧 Diagnostic & Utility (5)
```
check_sample_overlap.sh         Check sample ID matching
debug_bolt_command.sh           Incremental BOLT testing
test_bolt_minimal.sh            Minimal BOLT tests
test_no_filter.sh               Test without EUR filtering
fix_fam_ids.sh                  Fix .fam IDs (if needed)
```

### 🔄 Alternative Implementations (1)
```
filter_to_EUR.sh                Bash version of EUR filtering
```

### ⚙️ Configuration (2)
```
paths.sh                        Path configuration
.gitignore                      Git ignore rules
```

### 📚 Documentation (17 files)
```
READY_TO_RUN.md          ⭐ START HERE - Ready to submit!
QUICK_RUN.md             ⭐ Fast track guide
SCRIPTS_OVERVIEW.md      ⭐ All scripts explained
CURRENT_STATUS.md           Real-time status
WORKFLOW_SUMMARY.md         Quick reference
SIMPLIFIED_WORKFLOW.md      Complete 6-job guide
FINAL_CONFIGURATION.md      Definitive specs
README.md                   Scientific documentation (35KB, 11 citations)
START_HERE.md               Entry point
RUN_ANALYSIS.md             Detailed SLURM guide
SETUP_CHECKLIST.md          Step-by-step setup
FILE_MANIFEST.md            This file
IMPORTANT_FIXES.md          All issues & solutions
IMPORTANT_NOTE.md           Usage warnings
BINARY_TRAITS_INFO.md       Liability scale interpretation
GITHUB_SETUP.md             Git instructions
ENVIRONMENT_SETUP.md        Conda setup
```

### 📜 Legal & Setup (2)
```
LICENSE                         MIT License
environment.yml                 Conda environment spec
```

---

## 🎯 Essential Scripts to Know

### For Running Analysis:
1. **`1_run_bolt_lmm.sbatch.sh`** - The ONLY script you need to run analysis!
2. **`run_single_phenotype.sh`** - Worker (don't run directly)

### For Setup (run once):
3. **`0a_convert_to_bed.sbatch.sh`** - Convert genotypes
4. **`create_EUR_MM_keep.sh`** - Create EUR_MM.keep file
5. **`filter_to_EUR_python.py`** - Filter data to EUR
6. **`0b_prepare_model_snps.sbatch.sh`** - Create model SNPs

### Everything Else:
- Optional test or diagnostic tools

---

## 🗑️ What Was Deleted (No Longer Needed)

**Old 138-job workflow** (deprecated):
- ~~1a_bolt_lmm.sbatch.sh~~ → Replaced by `1_run_bolt_lmm.sbatch.sh`
- ~~bolt_lmm.sh~~ → Replaced by `run_single_phenotype.sh`
- ~~1b_combine_bolt_output.sh~~ → Not needed (no combining)
- ~~combine_bolt_logs.sh~~ → Not needed
- ~~combine_bolt_sumstats.sh~~ → Not needed
- ~~99_check_progress.sh~~ → Not needed

**Superseded approaches**:
- ~~0c_test_run.sbatch.sh~~ → Replaced by `0c_test_simplified.sbatch.sh`
- ~~0_convert_to_bed.sh~~ → Replaced by `0a` batch version
- ~~0_prepare_model_snps.sh~~ → Replaced by `0b` batch version
- ~~create_remove_file.sh~~ → Replaced by pre-filtering approach

**Total removed**: 10 scripts (1,042 lines of deprecated code)

---

## 📊 Current Pipeline Summary

**Workflow**: Preprocessing (4 steps) → Analysis (1 command)

**Commands**:
```bash
# Setup (once)
sbatch 0a_convert_to_bed.sbatch.sh
bash create_EUR_MM_keep.sh
python3 filter_to_EUR_python.py
sbatch 0b_prepare_model_snps.sbatch.sh

# Analysis (all 6 jobs)
sbatch 1_run_bolt_lmm.sbatch.sh
```

**Results**: 6 GWAS files in `results/` directory after 8-12 hours

---

## 🔍 Documentation Roadmap

**Quickstart** (read these first):
1. **READY_TO_RUN.md** - Final verification, go command
2. **QUICK_RUN.md** - Fast track to results
3. **SCRIPTS_OVERVIEW.md** - All scripts explained

**Complete guides**:
4. **WORKFLOW_SUMMARY.md** - Quick reference card
5. **SIMPLIFIED_WORKFLOW.md** - Detailed 6-job guide
6. **RUN_ANALYSIS.md** - SLURM batch guide

**Reference**:
7. **README.md** - Scientific methods (11 citations)
8. **FINAL_CONFIGURATION.md** - Complete specs
9. **FILE_MANIFEST.md** - This file

**Setup & troubleshooting**:
10. **SETUP_CHECKLIST.md** - Step-by-step
11. **IMPORTANT_FIXES.md** - Issues & solutions
12. **IMPORTANT_NOTE.md** - Usage warnings

---

## ✅ Repository is Now Clean!

- ✅ Only current, working scripts
- ✅ No deprecated code
- ✅ No confusion about which script to use
- ✅ Clear documentation
- ✅ Production-ready

**ONE command to run analysis**: `sbatch 1_run_bolt_lmm.sbatch.sh`

---

*See READY_TO_RUN.md for immediate next steps*


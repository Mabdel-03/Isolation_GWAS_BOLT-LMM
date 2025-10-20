# File Manifest: isolation_run_control_BOLT

## Overview
This directory contains a complete BOLT-LMM v2.5 GWAS analysis pipeline for binary social isolation phenotypes. The pipeline implements the methodology from Day et al. (2018) "Elucidating the genetic basis of social interaction and isolation" using SLURM batch jobs on the MIT Luria HPC cluster (kellis partition).

## Main Analysis Scripts

### `bolt_lmm.sh` ⭐ CORE SCRIPT
**Purpose**: Main script that runs BOLT-LMM for a single variant split  
**Usage**: `bash bolt_lmm.sh <analysis_name> <out_suffix> <pheno_cols> <threads> <memory> <covar_str> <keep_set> <idx>`  
**Example**: `bash bolt_lmm.sh isolation_run_control BOLT 5,6,9 8 40000 Day_NoPCs EUR 1`  
**What it does**:
- Runs BOLT-LMM for 3 phenotypes (Loneliness, FreqSoc, AbilityToConfide)
- Applies specified covariate model
- Processes one variant split at a time
- Outputs .stats.gz and .log.gz files

### `1a_bolt_lmm.sbatch.sh`
**Purpose**: Job submission script for SLURM cluster  
**Usage**: `bash 1a_bolt_lmm.sbatch.sh`  
**What it does**:
- Generates list of 138 jobs (69 variant splits × 2 covariate sets)
- Submits SLURM array jobs with appropriate resources
- Creates job list file with timestamp
- Runs max 5 concurrent jobs

### `1b_combine_bolt_output.sh`
**Purpose**: Orchestrates combining results from all variant splits  
**Usage**: `bash 1b_combine_bolt_output.sh`  
**What it does**:
- Submits jobs to combine logs and statistics
- Runs for all covariate sets and phenotypes
- Creates final combined output files

## Helper Scripts

### `combine_bolt_logs.sh`
**Purpose**: Combines log files from variant splits  
**Usage**: `bash combine_bolt_logs.sh <analysis_name> <covar_str> <keep_set>`  
**Example**: `bash combine_bolt_logs.sh isolation_run_control Day_NoPCs EUR`

### `combine_bolt_sumstats.sh`
**Purpose**: Combines summary statistics from variant splits  
**Usage**: `bash combine_bolt_sumstats.sh <analysis_name> <covar_str> <keep_set> <trait>`  
**Example**: `bash combine_bolt_sumstats.sh isolation_run_control Day_NoPCs EUR Loneliness`

## Setup/Preparation Scripts (SLURM Batch Jobs)

### `0a_convert_to_bed.sbatch.sh` ⭐ STEP 1
**Purpose**: Converts PLINK2 pgen files to PLINK1 bed format for BOLT-LMM  
**Usage**: `sbatch 0a_convert_to_bed.sbatch.sh`  
**Resources**: 32GB RAM, 8 CPUs, 2 hours, kellis partition  
**When to run**: Once, before first BOLT-LMM analysis  
**Runtime**: ~5-10 minutes  
**Creates**: `geno/ukb_genoHM3/ukb_genoHM3_bed.{bed,bim,fam}` (~150GB total)  
**Output logs**: `convert_to_bed.<jobid>.{out,err}`  
**What it does**:
- Activates conda environment internally
- Converts 1.3M variants from pgen to bed format
- Verifies output file creation
- Reports variant and sample counts

### `0b_prepare_model_snps.sbatch.sh` ⭐ STEP 2
**Purpose**: Creates LD-pruned SNP list for genetic relationship matrix  
**Usage**: `sbatch 0b_prepare_model_snps.sbatch.sh`  
**Resources**: 64GB RAM, 8 CPUs, 2 hours, kellis partition  
**When to run**: Once, after `0a_convert_to_bed.sbatch.sh` completes  
**Runtime**: ~15-30 minutes  
**Creates**: `geno/ukb_genoHM3/ukb_genoHM3_modelSNPs.txt` (~500K SNPs)  
**Output logs**: `model_snps.<jobid>.{out,err}`  
**LD Pruning Parameters**:
- MAF ≥0.5%, missingness <10%
- HWE: sample-size adjusted (--hwe 1e-5 0.001 keep-fewhet)
- LD: r²<0.5 in 1000kb windows
- Autosomes only (chr 1-22)  
**What it does**:
- Applies QC filters optimized for GRM construction
- Performs LD pruning to select ~500K independent SNPs
- Validates SNP count is in optimal range (400K-600K)

### `0c_test_run.sbatch.sh` ⭐ STEP 3 (CRITICAL!)
**Purpose**: Test complete pipeline with one variant split before full analysis  
**Usage**: `sbatch 0c_test_run.sbatch.sh`  
**Resources**: 45GB RAM, 8 CPUs, 6 hours, kellis partition  
**When to run**: After `0b_prepare_model_snps.sbatch.sh` completes  
**Runtime**: ~1-3 hours  
**Output logs**: `bolt_test.<jobid>.{out,err}`  
**What it does**:
- Runs BOLT-LMM on variant split 1 (~19K variants)
- Tests all 3 phenotypes (Loneliness, FreqSoc, AbilityToConfide)
- Uses Day_NoPCs covariate model
- Validates output file generation
- Reports success/failure status
- Creates 6 test output files in var_split/ directory  
**Success check**: Look for "🎉 TEST PASSED!" in output log  
**⚠️ CRITICAL**: Do NOT proceed to full analysis unless test passes!

### Legacy Scripts (Interactive Versions)

These are kept for reference but SLURM batch versions should be used:

#### `0_convert_to_bed.sh`
**Purpose**: Interactive version of genotype conversion  
**Usage**: `bash 0_convert_to_bed.sh` (direct execution)  
**Note**: Use `0a_convert_to_bed.sbatch.sh` instead for SLURM submission

#### `0_prepare_model_snps.sh`
**Purpose**: Interactive version of model SNPs creation  
**Usage**: `bash 0_prepare_model_snps.sh` (direct execution)  
**Note**: Use `0b_prepare_model_snps.sbatch.sh` instead for SLURM submission

## Utility Scripts

### `99_check_progress.sh`
**Purpose**: Checks analysis progress and completion status  
**Usage**: `bash 99_check_progress.sh`  
**When to run**: During/after analysis to monitor progress  
**Shows**:
- Number of completed variant splits per phenotype
- Combined output file status
- SLURM log summary

## Configuration Files

### `paths.sh`
**Purpose**: Centralized path configuration  
**Contains**:
- BOLT-LMM installation directory
- LD scores file path
- Genetic map file path
- Model SNPs file path
**Action required**: Update paths based on your HPC setup

## Documentation

### `README.md` ⭐⭐⭐ PRIMARY DOCUMENTATION
**Purpose**: Comprehensive scientific documentation of the analysis  
**Contains**:
- Background and motivation (Day et al. 2018 study)
- UK Biobank data description
- Detailed phenotype definitions with UK Biobank field codes
- Complete pipeline documentation with flowchart
- Scientific justification for all parameters
- BOLT-LMM methodology and binary trait handling
- Quality control procedures
- Computational requirements and resource allocations
- Comparison to Day et al. methodology
- Downstream analysis recommendations
- 11 scientific citations with DOIs
- Troubleshooting guide

### `RUN_ANALYSIS.md` ⭐ SLURM WORKFLOW GUIDE
**Purpose**: Complete SLURM batch workflow documentation  
**Contains**:
- Step-by-step SLURM job submission guide
- Resource allocation table
- Monitoring commands
- Success criteria for each step
- Expected timeline (3-4 days)
- Final output descriptions
- Quick start commands for batch workflow

### `SETUP_CHECKLIST.md` ⭐ STEP-BY-STEP SETUP
**Purpose**: Detailed setup instructions with checklist  
**Contains**:
- Pre-requisite verification
- Step-by-step setup instructions
- Configuration file updates
- Common issues and solutions
- Resource requirements
- Expected outputs

### `QUICK_START.md` ⭐ FAST REFERENCE
**Purpose**: Quick reference for experienced users  
**Contains**:
- Command sequence to run analysis
- Key differences from PLINK table
- Expected runtime
- Quick troubleshooting

### `FILE_MANIFEST.md` (this file)
**Purpose**: Complete listing of all files and their purposes  
**Updated**: October 2025 with SLURM batch workflow

### `RUN_ANALYSIS.md` ⭐ SLURM BATCH WORKFLOW
**Purpose**: Complete guide for running analysis via SLURM  
**Contains**:
- Step-by-step batch job submission
- Resource specifications per step
- Monitoring and troubleshooting
- Success criteria
- Expected timeline
- Final output descriptions

### `BINARY_TRAITS_INFO.md` ⭐ BINARY PHENOTYPES GUIDE
**Purpose**: Comprehensive guide to binary trait analysis in BOLT-LMM  
**Contains**:
- Liability threshold model explanation
- Effect size interpretation (liability scale vs odds ratios)
- Comparison to PLINK logistic regression
- Day et al. methodology details
- Quality control for binary traits
- Heritability interpretation
- Common issues and solutions
- Example interpretations

## Analysis Parameters

**IMPORTANT**: All phenotypes are **BINARY** (case-control, 0/1 coded)

### Phenotypes
1. **Loneliness** (column 5 in phenotype file): 0=not lonely, 1=lonely
2. **FreqSoc** (column 6 in phenotype file): 0=low frequency social contact, 1=high frequency
3. **AbilityToConfide** (column 9 in phenotype file): 0=no one to confide in, 1=has someone

**Study Design**: Following Day et al. "Elucidating the genetic basis of social interaction and isolation" (Nature Communications, 2018)

### Covariate Sets
1. **Day_NoPCs**: age, sex, array (no PCs)
2. **Day_10PCs**: age, sex, array, UKB_PC1-UKB_PC10

### Populations
- **EUR**: European ancestry (filtered via sqc/population.20220316/EUR.keep)

### Variant Splits
- **69 splits**: Variants divided for parallelization (defined in gwas_geno/ukb_geno.var_split.info.tsv.gz)

## Resource Requirements (Updated for Kellis Partition)

### Per-Step Resources (SLURM Batch Jobs)

| Step | Script | RAM | CPUs | Time | Partition |
|------|--------|-----|------|------|-----------|
| **1. Convert** | `0a_convert_to_bed.sbatch.sh` | 32GB | 8 | 2h | kellis |
| **2. Model SNPs** | `0b_prepare_model_snps.sbatch.sh` | **64GB** | 8 | 2h | kellis |
| **3. Test** | `0c_test_run.sbatch.sh` | 45GB | 8 | 6h | kellis |
| **4. Full (each)** | `1a_bolt_lmm.sbatch.sh` | 45GB | 8 | 12h | kellis |

**Why 64GB for Model SNPs?**
- LD correlation calculations with ~500K samples and 1.3M variants
- Peak memory during pairwise r² computation
- 32GB insufficient (job killed at 32.7GB usage)

### Total Analysis
- **Total jobs**: 138 (69 variant splits × 2 covariate sets)
- **Concurrent**: Max 5 jobs at once (configurable in `1a_bolt_lmm.sbatch.sh`)
- **Wall time**: 3-4 days from start to finish
- **Disk space**: ~200GB (150GB genotypes + 50GB outputs)
- **Total CPU-hours**: ~13,250 (138 jobs × 8 CPUs × ~12 hours)

## Complete File Listing

### Core Directory Files

```
isolation_run_control_BOLT/
│
├── 📜 Core Execution Scripts
│   ├── bolt_lmm.sh                      # Main BOLT-LMM worker script
│   ├── 1a_bolt_lmm.sbatch.sh            # SLURM: Submit 138 array jobs
│   ├── 1b_combine_bolt_output.sh        # Combine results orchestrator
│   ├── combine_bolt_logs.sh             # Helper: merge log files
│   └── combine_bolt_sumstats.sh         # Helper: merge statistics
│
├── 🚀 Preprocessing Scripts (SLURM Batch)
│   ├── 0a_convert_to_bed.sbatch.sh      # SLURM: Convert pgen→bed
│   ├── 0b_prepare_model_snps.sbatch.sh  # SLURM: Create model SNPs (64GB!)
│   └── 0c_test_run.sbatch.sh            # SLURM: Test pipeline
│
├── 📝 Legacy Interactive Scripts
│   ├── 0_convert_to_bed.sh              # (use 0a batch version)
│   └── 0_prepare_model_snps.sh          # (use 0b batch version)
│
├── 🔍 Utility Scripts
│   └── 99_check_progress.sh             # Monitor analysis progress
│
├── ⚙️ Configuration
│   ├── paths.sh                         # Path configuration
│   ├── .gitignore                       # Git ignore rules
│   └── LICENSE                          # MIT License
│
└── 📚 Documentation (7 files)
    ├── README.md                        # Primary scientific documentation
    ├── RUN_ANALYSIS.md                  # SLURM workflow guide
    ├── START_HERE.md                    # Quick entry point
    ├── BINARY_TRAITS_INFO.md            # Binary trait analysis guide
    ├── QUICK_START.md                   # Fast reference
    ├── SETUP_CHECKLIST.md               # Detailed setup guide
    ├── FILE_MANIFEST.md                 # This file
    ├── GITHUB_SETUP.md                  # GitHub instructions
    └── ENVIRONMENT_SETUP.md             # Conda environment guide
│
├── Day_NoPCs/                           # Results without PCs
│   └── EUR/                             # European ancestry
│       ├── Loneliness.bolt.stats.gz     # Combined GWAS results
│       ├── FreqSoc.bolt.stats.gz
│       ├── AbilityToConfide.bolt.stats.gz
│       ├── bolt_isolation_run_control.Loneliness.BOLT.log.gz
│       ├── bolt_isolation_run_control.FreqSoc.BOLT.log.gz
│       ├── bolt_isolation_run_control.AbilityToConfide.BOLT.log.gz
│       └── var_split/                   # Individual split results
│           ├── bolt_isolation_run_control.array_both_1.Loneliness.BOLT.stats.gz
│           ├── bolt_isolation_run_control.array_both_1.Loneliness.BOLT.log.gz
│           └── ... (206 more files)
│
├── Day_10PCs/                           # Results with 10 PCs
│   └── EUR/                             # European ancestry
│       ├── Loneliness.bolt.stats.gz
│       ├── FreqSoc.bolt.stats.gz
│       ├── AbilityToConfide.bolt.stats.gz
│       ├── bolt_isolation_run_control.Loneliness.BOLT.log.gz
│       ├── bolt_isolation_run_control.FreqSoc.BOLT.log.gz
│       ├── bolt_isolation_run_control.AbilityToConfide.BOLT.log.gz
│       └── var_split/                   # Individual split results
│           └── ... (207 files)
│
└── .slurm_logs/                         # SLURM job logs
    ├── isolation_run_control_BOLT.bolt.*.out
    ├── isolation_run_control_BOLT.bolt.*.err
    └── ... (job log files)
```

## Script Execution Order (SLURM Batch Workflow)

### Recommended Workflow (Using Batch Scripts)

1. **Preprocessing** (run once, ~1-2 hours total):
   ```bash
   sbatch 0a_convert_to_bed.sbatch.sh       # Step 1: Convert genotypes
   # Wait for completion, then:
   sbatch 0b_prepare_model_snps.sbatch.sh   # Step 2: Create model SNPs
   ```

2. **Validation** (critical checkpoint, ~1-3 hours):
   ```bash
   # Wait for Step 2 completion, then:
   sbatch 0c_test_run.sbatch.sh             # Step 3: Test pipeline
   # Check for "TEST PASSED" in output before proceeding!
   ```

3. **Full Analysis** (1-2 days):
   ```bash
   # Only if test passed:
   bash 1a_bolt_lmm.sbatch.sh               # Step 4: Submit all 138 jobs
   bash 99_check_progress.sh                # Monitor progress
   ```

4. **Post-Processing** (1-2 hours):
   ```bash
   # After all 138 jobs complete:
   bash 1b_combine_bolt_output.sh           # Step 5: Combine results
   ```

### Alternative: Interactive Workflow (Legacy)

For interactive/debugging use only:

```bash
# Step 1: Convert (interactive)
bash 0_convert_to_bed.sh

# Step 2: Model SNPs (interactive) 
bash 0_prepare_model_snps.sh

# Step 3: Test (interactive)
bash bolt_lmm.sh isolation_run_control BOLT 5,6,9 8 45000 Day_NoPCs EUR 1

# Steps 4-5: Same as batch workflow
```

**Note**: Interactive scripts don't reserve resources via SLURM and may be killed on shared nodes. Use batch scripts for production runs.

## Key Configuration (Pre-configured for Your HPC)

All paths are already configured for:
- **BOLT-LMM**: `/home/mabdel03/data/software/BOLT-LMM_v2.5/`
- **LD Scores**: `LDSCORE.1000G_EUR.GRCh38.tab.gz`
- **Genetic Map**: `genetic_map_hg19_withX.txt.gz`
- **Conda Environment**: `/home/mabdel03/data/conda_envs/bolt_lmm`
- **Data Directory**: `/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942`
- **Partition**: kellis

### If You Need to Modify

1. **bolt_lmm.sh** (lines 79-84):
   - LD scores file path (currently BOLT-LMM v2.5 tables)
   - Genetic map file path
   - Genotype file path (uses ukb_genoHM3_bed after conversion)

2. **paths.sh**:
   - BOLT-LMM installation directory
   - Table file locations

3. **Resource adjustments** (if needed):
   - `0a_convert_to_bed.sbatch.sh` line 4: `#SBATCH --mem=32000`
   - `0b_prepare_model_snps.sbatch.sh` line 4: `#SBATCH --mem=64000`
   - `0c_test_run.sbatch.sh` line 4: `#SBATCH --mem=45000`
   - `1a_bolt_lmm.sbatch.sh` line 26: `sbatch_resources_str='-p kellis --mem=45000...'`

## Output File Formats

### Summary Statistics (.bolt.stats.gz)
Columns:
- SNP, CHR, BP, GENPOS
- ALLELE1, ALLELE0, A1FREQ
- F_MISS, BETA, SE
- P_BOLT_LMM_INF, P_BOLT_LMM

### Log Files (.BOLT.log.gz)
Contains:
- BOLT-LMM version and parameters
- Sample and SNP counts
- Variance component estimates
- Heritability estimates
- Convergence information

## Dependencies

### Software Requirements
- **BOLT-LMM v2.5**: Installed at `/home/mabdel03/data/software/BOLT-LMM_v2.5/`
- **PLINK2 v2.0**: In conda environment (for genotype conversion and LD pruning)
- **Python 3.10**: In conda environment (for data processing)
- **Standard Unix tools**: bash, awk, grep, zcat, gzip, etc.
- **SLURM**: Job scheduling and resource management

### Conda Environment
**Path**: `/home/mabdel03/data/conda_envs/bolt_lmm`

**Key Packages**:
- plink2 (v2.0.0-a.6.9LM)
- python (3.10)
- pandas, numpy, scipy
- matplotlib, seaborn
- jupyter, notebook
- scikit-learn, statsmodels

**Activation** (handled automatically in batch scripts):
```bash
module load miniconda3/v4
source /home/software/conda/miniconda3/bin/condainit
conda activate /home/mabdel03/data/conda_envs/bolt_lmm
```

## Related Files (Outside This Directory)

- Phenotype: `pheno/isolation_run_control.tsv.gz`
- Covariates: `sqc/sqc.20220316.tsv.gz`
- Population: `sqc/population.20220316/EUR.keep`
- Genotypes: `geno/ukb_genoHM3/ukb_genoHM3.{pgen,pvar,psam}`
- Variant splits: `gwas_geno/ukb_geno.var_split.tsv.gz`
- Helper functions: `helpers/functions.sh`

## Model SNP Selection Parameters (Updated)

**Critical Update**: LD pruning threshold relaxed to accommodate HM3 variant set

| Parameter | Value | Justification |
|-----------|-------|---------------|
| MAF | ≥0.5% | Include common/low-freq variants for genome coverage |
| Missingness | <10% | Permissive for model SNPs (not tested for association) |
| HWE | 1e-5, sample-size adjusted | Appropriate for ~500K samples |
| **LD threshold** | **r²<0.5** | Optimal for GRM with HM3 variants (Yang et al. 2011) |
| Chromosomes | 1-22 | Autosomes only |
| Memory | 64GB | Required for LD calculations with large N |

**Evolution**:
- Initial: r²<0.1 → 150-200K SNPs (too few)
- Updated: r²<0.2 → 243K SNPs (still too few)  
- **Final: r²<0.5 → 450-600K SNPs (optimal)** ✅

## Version History

- **v1.0.0** (October 2025): Initial pipeline implementation
  - Converted from PLINK analysis in gwas_geno/isolation_run_control
  - BOLT-LMM v2.5 integration
  - Complete SLURM batch workflow
  - Kellis partition optimization
  - Three binary social isolation phenotypes
  - EUR population analysis
  - 11 scientific citations in documentation
  
- **v1.0.1** (October 2025): Resource optimization
  - Increased model SNPs memory: 32GB → 64GB
  - Relaxed LD threshold: r²<0.1 → r²<0.5
  - Updated HWE filter for large sample sizes
  - Added comprehensive scientific justification


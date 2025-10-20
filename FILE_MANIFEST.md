# File Manifest: isolation_run_control_BOLT

## Overview
This directory contains a complete BOLT-LMM GWAS analysis pipeline converted from the PLINK-based analysis in `gwas_geno/isolation_run_control`.

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

## Setup/Preparation Scripts

### `0_convert_to_bed.sh`
**Purpose**: Converts PLINK2 pgen files to PLINK1 bed format for BOLT-LMM  
**Usage**: `bash 0_convert_to_bed.sh`  
**When to run**: Once, before first BOLT-LMM analysis  
**Creates**: `geno/ukb_genoHM3/ukb_genoHM3_bed.{bed,bim,fam}`

### `0_prepare_model_snps.sh`
**Purpose**: Creates LD-pruned SNP list for genetic relationship matrix  
**Usage**: `bash 0_prepare_model_snps.sh`  
**When to run**: Once, after converting to bed format  
**Creates**: `geno/ukb_genoHM3/ukb_genoHM3_modelSNPs.txt` (~500K SNPs)

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

### `README.md` ⭐ PRIMARY DOCUMENTATION
**Purpose**: Comprehensive documentation of the analysis  
**Contains**:
- Overview of analysis
- Phenotype descriptions
- Covariate set definitions
- Workflow steps
- Key differences from PLINK
- Input file requirements
- Output format description
- Troubleshooting guide

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

## Resource Requirements

### Per Job (variant split)
- **Memory**: 40GB (may need 50-60GB for large datasets)
- **CPUs**: 8 cores
- **Time**: 6-12 hours
- **Partition**: normal

### Total Analysis
- **Total jobs**: 138 (69 splits × 2 covariate sets)
- **Concurrent**: Max 5 jobs at once
- **Wall time**: 1-2 days
- **Disk space**: ~100GB for all outputs

## Directory Structure (After Running)

```
isolation_run_control_BOLT/
│
├── bolt_lmm.sh                           # Main execution script
├── 1a_bolt_lmm.sbatch.sh                # Job submission
├── 1b_combine_bolt_output.sh            # Combine results
├── combine_bolt_logs.sh                 # Helper: combine logs
├── combine_bolt_sumstats.sh             # Helper: combine stats
├── 0_convert_to_bed.sh                  # Setup: convert genotypes
├── 0_prepare_model_snps.sh              # Setup: create model SNPs
├── 99_check_progress.sh                 # Utility: check progress
├── paths.sh                             # Configuration
├── README.md                            # Main documentation
├── SETUP_CHECKLIST.md                   # Setup guide
├── QUICK_START.md                       # Quick reference
├── FILE_MANIFEST.md                     # This file
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

## Script Execution Order

1. **Setup** (run once):
   ```bash
   bash 0_convert_to_bed.sh       # Convert genotypes
   bash 0_prepare_model_snps.sh   # Create model SNPs
   # Edit bolt_lmm.sh to update paths
   ```

2. **Test** (optional but recommended):
   ```bash
   bash bolt_lmm.sh isolation_run_control BOLT 5,6,9 8 40000 Day_NoPCs EUR 1
   ```

3. **Run full analysis**:
   ```bash
   bash 1a_bolt_lmm.sbatch.sh     # Submit all jobs
   bash 99_check_progress.sh       # Monitor progress
   ```

4. **Combine results**:
   ```bash
   bash 1b_combine_bolt_output.sh # After all jobs finish
   ```

## Key Files to Edit Before Running

1. **bolt_lmm.sh** (lines 100-110):
   - Update LD scores file path
   - Update genetic map file path
   - Update genotype file path if using converted bed

2. **paths.sh**:
   - Set BOLT-LMM installation directory
   - Verify LD scores and genetic map paths

3. **1a_bolt_lmm.sbatch.sh** (line 22):
   - Adjust SLURM resources if needed (--mem, --ntasks, --time)

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

- BOLT-LMM v2.4+ (binary must be in PATH)
- PLINK2 (for genotype conversion)
- Standard Unix tools (bash, awk, zcat, gzip, etc.)
- SLURM workload manager
- Conda environment with GWAS tools

## Related Files (Outside This Directory)

- Phenotype: `pheno/isolation_run_control.tsv.gz`
- Covariates: `sqc/sqc.20220316.tsv.gz`
- Population: `sqc/population.20220316/EUR.keep`
- Genotypes: `geno/ukb_genoHM3/ukb_genoHM3.{pgen,pvar,psam}`
- Variant splits: `gwas_geno/ukb_geno.var_split.tsv.gz`
- Helper functions: `helpers/functions.sh`

## Version History

- Initial creation: Converted from PLINK analysis in gwas_geno/isolation_run_control
- Based on PLINK scripts dated 2022-2023
- BOLT-LMM version: October 2025


# Quick Start Guide: BOLT-LMM Analysis

## TL;DR - Run These Commands

**All paths are pre-configured! Just run the scripts in order:**

```bash
# 1. Navigate to YOUR analysis directory (inside Git repo)
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM

# 2. Activate conda environment
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

# 3. Preprocessing Step 1: Convert genotypes (autosomes only, chr 1-22)
sbatch 0a_convert_to_bed.sbatch.sh
# Resources: 32GB, 8 tasks, ~5-10 min
# Creates: ukb_genoHM3_bed.bed/bim/fam (~145GB, autosomes only)

# 4. Preprocessing Step 2: Create model SNPs (wait for step 3 to finish)
sbatch 0b_prepare_model_snps.sbatch.sh  
# Resources: 80GB, 8 tasks, ~15-30 min
# Creates: ~444K SNPs (MAF≥0.5%, r²<0.5)

# 5. Test run - CRITICAL! (wait for step 4 to finish)
sbatch 0c_test_run.sbatch.sh
# Resources: 100GB, 100 tasks, 47h limit (runs 1-3h)
# Tests all 3 phenotypes on full genome
# Check for "TEST PASSED" before continuing!

# 6. Full analysis (only if test passes!)
bash 1a_bolt_lmm.sbatch.sh
# Submits 138 jobs: 100GB, 100 tasks, 47h each

# 7. Monitor progress
squeue -u $USER
bash 99_check_progress.sh

# 8. Combine results (after all 138 jobs complete)
bash 1b_combine_bolt_output.sh

# 9. Results location
ls -lh results/Day_NoPCs/EUR/
```

## What This Analysis Does

Runs genome-wide association studies (GWAS) for 3 **binary** isolation-related phenotypes:
- **Loneliness** (binary: 0=no, 1=yes)
- **FreqSoc** (Frequency of Social Contact, binary: 0=low, 1=high)
- **AbilityToConfide** (binary: 0=no, 1=yes)

**Study Design**: Following Day et al. (Nature Communications) methodology for social interaction genetics

Using BOLT-LMM mixed models with:
- 2 covariate sets (Day_NoPCs, Day_10PCs)
- EUR population
- 69 variant splits for parallelization
- **Binary trait modeling** with liability threshold

## Key Differences from PLINK Version

| Aspect | PLINK | BOLT-LMM |
|--------|-------|----------|
| Method | Logistic regression | Linear mixed model (liability threshold) |
| Population structure | Explicit PC covariates | GRM + PC covariates |
| Relatedness | Typically excluded | Properly modeled |
| Trait type | Binary (0/1) | Binary with liability scale |
| File format | pgen/pvar/psam | bed/bim/fam (autosomes only) |
| Chromosomes | 1-22, X, Y, MT | **1-22 only** (BOLT limitation) |
| Memory | ~15GB | **100GB** |
| CPUs | 2 | **100** |
| Runtime | Faster | Slower (better modeling) |
| Walltime | 6-12h | **47h** per job |
| Effect size | Log odds ratio | Liability scale (approximates log OR) |
| Output p-values | Standard | Calibrated with LD scores |
| Output location | Scattered | **results/** in Git repo |

## Expected Runtime

- **Per variant split**: 6-12 hours
- **Total jobs**: 138 (69 splits × 2 covariate sets)
- **Wall time**: 1-2 days with array jobs (max 5 concurrent)

## File Requirements

Before running:
- [ ] Genotype files in bed format
- [ ] Model SNPs file (~500K LD-pruned SNPs)
- [ ] LD scores table (from BOLT-LMM)
- [ ] Genetic map (from BOLT-LMM)
- [ ] Phenotype file with Loneliness, FreqSoc, AbilityToConfide
- [ ] Covariate file with age, sex, array, PCs
- [ ] Population keep file for EUR

## Outputs

Combined GWAS summary statistics:
```
isolation_run_control_BOLT/
├── Day_NoPCs/EUR/
│   ├── Loneliness.bolt.stats.gz
│   ├── FreqSoc.bolt.stats.gz
│   └── AbilityToConfide.bolt.stats.gz
└── Day_10PCs/EUR/
    ├── Loneliness.bolt.stats.gz
    ├── FreqSoc.bolt.stats.gz
    └── AbilityToConfide.bolt.stats.gz
```

Each file contains ~millions of variants with columns:
- SNP, CHR, BP, ALLELE0, ALLELE1
- BETA, SE, P_BOLT_LMM
- And more...

## Troubleshooting

**"bolt: command not found"**
→ Install BOLT-LMM and add to PATH

**"Out of memory"**
→ Increase --mem in 1a_bolt_lmm.sbatch.sh to 50000 or 60000

**"Model SNPs file not found"**
→ Run 0_prepare_model_snps.sh first

**"LD scores file not found"**
→ Update paths in bolt_lmm.sh to point to BOLT-LMM tables

**"No samples after filters"**
→ Check that EUR.keep file exists and is formatted correctly (FID IID columns)

## Need More Details?

- Full setup instructions: `SETUP_CHECKLIST.md`
- Comprehensive documentation: `README.md`
- BOLT-LMM manual: https://alkesgroup.broadinstitute.org/BOLT-LMM/


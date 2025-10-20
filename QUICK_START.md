# Quick Start Guide: BOLT-LMM Analysis

## TL;DR - Run These Commands

```bash
# 1. Navigate to the analysis directory
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/isolation_run_control_BOLT

# 2. Update paths in bolt_lmm.sh (lines 100-110)
# - Set LD_SCORES_FILE to your BOLT-LMM tables directory
# - Set GENETIC_MAP_FILE to your BOLT-LMM tables directory
# - Set genotype_bfile path if using converted bed files

# 3. Convert genotypes to bed format (if needed)
bash 0_convert_to_bed.sh

# 4. Create model SNPs for GRM
bash 0_prepare_model_snps.sh

# 5. Test with one variant split
bash bolt_lmm.sh isolation_run_control BOLT 5,6,9 8 40000 Day_NoPCs EUR 1

# 6. If test succeeds, submit all jobs
bash 1a_bolt_lmm.sbatch.sh

# 7. Monitor progress
bash 99_check_progress.sh

# 8. After completion, combine results
bash 1b_combine_bolt_output.sh
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
| File format | pgen/pvar/psam | bed/bim/fam |
| Memory | ~15GB | ~40GB |
| Runtime | Faster | Slower (better modeling) |
| Effect size | Log odds ratio | Liability scale (approximates log OR) |
| Output p-values | Standard | Calibrated with LD scores |

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


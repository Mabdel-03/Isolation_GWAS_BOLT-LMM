# BOLT-LMM GWAS Analysis for Isolation Run Control

This directory contains scripts for running GWAS using BOLT-LMM (Bayesian mixed model association testing) for the isolation run control phenotypes.

## Overview

This is a BOLT-LMM version of the PLINK-based GWAS analysis in `gwas_geno/isolation_run_control`. BOLT-LMM provides better control for population structure and relatedness through linear mixed models.

**Study Design**: This analysis follows the methodology from Day et al. (Nature Communications) "Elucidating the genetic basis of social interaction and isolation"

## Phenotypes

Three **binary** isolation-related phenotypes (case-control):
- **Loneliness** (column 5): Binary indicator of self-reported loneliness (0=no, 1=yes)
- **FreqSoc** (Frequency of Social Contact, column 6): Binary indicator of social contact frequency (0=low, 1=high)
- **AbilityToConfide** (column 9): Binary indicator of having someone to confide in (0=no, 1=yes)

**Note**: All phenotypes are binary (0/1 coded). BOLT-LMM automatically detects this and uses a liability threshold model for case-control analysis.

## Covariate Sets

- **Day_NoPCs**: age, sex, array (no principal components)
- **Day_10PCs**: age, sex, array, UKB_PC1-UKB_PC10

## Analysis Workflow

### Step 1: Run BOLT-LMM GWAS

Submit array jobs to run BOLT-LMM across 69 variant splits:

```bash
bash 1a_bolt_lmm.sbatch.sh
```

This will:
- Run BOLT-LMM for each variant split (1-69)
- Process both covariate sets (Day_NoPCs and Day_10PCs)
- Run for EUR population
- Generate statistics and log files for each phenotype

### Step 2: Combine Results

After all jobs complete, combine results from variant splits:

```bash
bash 1b_combine_bolt_output.sh
```

This will:
- Combine log files for each phenotype
- Merge summary statistics across variant splits
- Create final output files in `isolation_run_control_BOLT/[covar_str]/EUR/`

## Key Differences from PLINK Analysis

### Resources
- **Memory**: 40GB (vs 15GB for PLINK) - BOLT-LMM needs more memory for mixed model calculations
- **Threads**: 8 cores (vs 2 for PLINK) - BOLT-LMM can benefit from more parallelization
- **Runtime**: Longer than PLINK due to mixed model computations

### Input Files Required

1. **Genotype files**: bed/bim/fam format (BOLT-LMM doesn't use pgen format)
2. **Model SNPs file**: Subset of SNPs for computing genetic relationship matrix
   - Path: `${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_modelSNPs.txt`
   - Should contain ~500K common, well-imputed SNPs
   - Can be created using LD pruning
3. **LD scores**: For BOLT-LMM calibration
   - Typically included with BOLT-LMM distribution
   - Update path in `bolt_lmm.sh` based on your installation
4. **Genetic map**: For interpolation
   - Also included with BOLT-LMM distribution

### Output Format

BOLT-LMM produces different output columns than PLINK:
- `SNP`: Variant ID
- `CHR`: Chromosome
- `BP`: Base pair position
- `GENPOS`: Genetic position
- `ALLELE1`: Effect allele
- `ALLELE0`: Reference allele
- `A1FREQ`: Effect allele frequency
- `F_MISS`: Fraction missing
- `BETA`: Effect size estimate (on liability scale for binary traits)
- `SE`: Standard error (on liability scale for binary traits)
- `P_BOLT_LMM_INF`: P-value from infinitesimal mixed model
- `P_BOLT_LMM`: P-value from non-infinitesimal model (use this for GWAS)

**Important for Binary Traits**: 
- Effect sizes (BETA) are on the liability scale, not the observed 0/1 scale
- To convert to odds ratios: OR = exp(BETA × h²_liability / h²_observed)
- For prevalence K and case-control ratio, liability scale approximates log(OR) when effect is small

## Important Setup Notes

### Before Running on HPC

1. **Install BOLT-LMM**: Make sure BOLT-LMM is installed and in your PATH
2. **Create model SNPs file**: Generate the LD-pruned SNP list for GRM computation
3. **Update paths**: In `bolt_lmm.sh`, update:
   - `ld_scores_file`: Path to LD scores table
   - `genetic_map_file`: Path to genetic map
   - `model_snps_file`: Path to model SNPs list
4. **Convert genotypes**: Ensure genotype files are available in bed/bim/fam format
5. **Check population file**: BOLT uses `--remove` instead of `--keep`, so you may need to create a `.remove` file

### Creating Model SNPs File

Example command to create model SNPs:
```bash
plink2 \
  --bfile ${genotype_bfile} \
  --maf 0.01 \
  --geno 0.05 \
  --hwe 1e-6 \
  --indep-pairwise 1000 50 0.1 \
  --write-snplist \
  --out ${genotype_bfile}_modelSNPs
```

## Directory Structure

```
isolation_run_control_BOLT/
├── bolt_lmm.sh                    # Main BOLT-LMM execution script
├── 1a_bolt_lmm.sbatch.sh          # Job submission script
├── 1b_combine_bolt_output.sh      # Combine results from splits
├── combine_bolt_logs.sh           # Helper: combine log files
├── combine_bolt_sumstats.sh       # Helper: combine summary stats
├── README.md                      # This file
├── Day_NoPCs/
│   └── EUR/
│       ├── Loneliness.bolt.stats.gz
│       ├── FreqSoc.bolt.stats.gz
│       ├── AbilityToConfide.bolt.stats.gz
│       └── var_split/           # Individual variant split results
└── Day_10PCs/
    └── EUR/
        ├── Loneliness.bolt.stats.gz
        ├── FreqSoc.bolt.stats.gz
        ├── AbilityToConfide.bolt.stats.gz
        └── var_split/           # Individual variant split results
```

## References

- **Study design based on**: Day, F.R., et al. "Elucidating the genetic basis of social interaction and isolation." Nature Communications (2018).
- BOLT-LMM software: [https://alkesgroup.broadinstitute.org/BOLT-LMM/](https://alkesgroup.broadinstitute.org/BOLT-LMM/)
- Loh et al. (2015). "Efficient Bayesian mixed-model analysis increases association power in large cohorts." Nature Genetics.
- Loh et al. (2018). "Mixed-model association for biobank-scale datasets." Nature Genetics.
- **Binary trait analysis**: BOLT-LMM uses liability threshold model for case-control phenotypes

## Troubleshooting

### Memory Issues
If jobs fail with out-of-memory errors, increase `--mem` in `1a_bolt_lmm.sbatch.sh`

### Missing LD Scores
Download LD scores from BOLT-LMM website or use included tables in BOLT distribution

### Convergence Issues
BOLT-LMM may have convergence issues with:
- Very rare variants (use MAF filter)
- High missingness (use genotype QC)
- Small sample sizes (consider standard linear/logistic regression)


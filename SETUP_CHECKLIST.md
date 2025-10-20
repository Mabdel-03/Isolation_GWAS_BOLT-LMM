# BOLT-LMM Setup Checklist

## Study Information

**Analysis Type**: Case-control GWAS for binary phenotypes  
**Study Design**: Following Day et al. "Elucidating the genetic basis of social interaction and isolation"  
**Phenotypes**: Loneliness, FreqSoc, AbilityToConfide (all binary: 0/1)  
**Method**: BOLT-LMM with liability threshold model for binary traits

Before running the BOLT-LMM analysis on your HPC, complete the following steps:

## ✓ Pre-requisites

- [ ] BOLT-LMM software installed on HPC
- [ ] PLINK2 available in your conda environment
- [ ] UK Biobank genotype data accessible
- [ ] Phenotype file available: `pheno/isolation_run_control.tsv.gz`
- [ ] Covariate file available: `sqc/sqc.20220316.tsv.gz`
- [ ] Population keep/remove files: `sqc/population.20220316/EUR.keep` (or .remove)

## ✓ Step 1: Install BOLT-LMM

```bash
# Download BOLT-LMM from:
# https://alkesgroup.broadinstitute.org/BOLT-LMM/downloads/

# Extract and add to PATH
wget https://alkesgroup.broadinstitute.org/BOLT-LMM/downloads/BOLT-LMM_v2.4.1.tar.gz
tar -xzf BOLT-LMM_v2.4.1.tar.gz
export PATH=/path/to/BOLT-LMM_v2.4.1/:$PATH
```

## ✓ Step 2: Update Configuration Files

### Update `paths.sh`

Edit `isolation_run_control_BOLT/paths.sh`:

```bash
# Set BOLT-LMM installation directory
BOLT_LMM_DIR="/path/to/BOLT-LMM_v2.4.1"
BOLT_TABLES_DIR="${BOLT_LMM_DIR}/tables"

# Check that these files exist:
LD_SCORES_FILE="${BOLT_TABLES_DIR}/LDSCORE.1000G_EUR.tab.gz"
GENETIC_MAP_FILE="${BOLT_TABLES_DIR}/genetic_map_hg19_withX.txt.gz"
```

### Update `bolt_lmm.sh`

Around lines 100-110, update paths:

```bash
# LD scores table (check path exists)
ld_scores_file="${BOLT_TABLES_DIR}/LDSCORE.1000G_EUR.tab.gz"

# Genetic map (check path exists)
genetic_map_file="${BOLT_TABLES_DIR}/genetic_map_hg19_withX.txt.gz"
```

## ✓ Step 3: Convert Genotype Files to BED Format

BOLT-LMM requires PLINK1 bed/bim/fam format (not pgen):

```bash
cd isolation_run_control_BOLT
bash 0_convert_to_bed.sh
```

This creates: `geno/ukb_genoHM3/ukb_genoHM3_bed.{bed,bim,fam}`

**Important**: After conversion, update `bolt_lmm.sh` line ~80:

```bash
# Change from:
genotype_bfile=${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3

# To:
genotype_bfile=${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_bed
```

## ✓ Step 4: Create Model SNPs File

Generate LD-pruned SNPs for computing the genetic relationship matrix:

```bash
cd isolation_run_control_BOLT
bash 0_prepare_model_snps.sh
```

This creates: `geno/ukb_genoHM3/ukb_genoHM3_modelSNPs.txt`

Expected: 300K-700K SNPs

## ✓ Step 5: Check Population Files

BOLT-LMM uses `--remove` instead of PLINK2's `--keep`. You may need to convert:

```bash
# If you only have .keep files, create .remove files:
cd sqc/population.20220316/

# Get all sample IDs
plink2 --pfile ${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3 \
       --write-samples --out all_samples

# Create .remove file (samples NOT in .keep file)
comm -23 <(sort all_samples.id) <(sort EUR.keep) > EUR.remove
```

**OR** modify `bolt_lmm.sh` line ~105 to use `--keep` instead of `--remove`

## ✓ Step 6: Verify Phenotype and Covariate Columns

Check that column names match and phenotypes are properly coded:

```bash
# Check phenotype columns
zcat pheno/isolation_run_control.tsv.gz | head -1

# Should contain: Loneliness, FreqSoc, AbilityToConfide

# VERIFY BINARY CODING: Phenotypes must be coded as 0/1 or 1/2
zcat pheno/isolation_run_control.tsv.gz | awk '{print $5}' | sort | uniq
zcat pheno/isolation_run_control.tsv.gz | awk '{print $6}' | sort | uniq
zcat pheno/isolation_run_control.tsv.gz | awk '{print $9}' | sort | uniq

# Should show: 0, 1 (and possibly NA/-9/missing)
# BOLT-LMM automatically detects binary phenotypes

# Check covariate columns  
zcat sqc/sqc.20220316.tsv.gz | head -1

# For Day_NoPCs: should contain age, sex, array
# For Day_10PCs: should contain age, sex, array, UKB_PC1-UKB_PC10
```

If column names differ, update `bolt_lmm.sh` lines ~125-145

**CRITICAL**: Ensure phenotypes are binary (0/1 or 1/2 coding). BOLT-LMM will automatically use liability threshold model.

## ✓ Step 7: Test Run (Optional but Recommended)

Test with a single variant split before submitting all jobs:

```bash
cd isolation_run_control_BOLT

# Test run for variant split 1, Day_NoPCs, EUR
bash bolt_lmm.sh isolation_run_control BOLT 5,6,9 8 40000 Day_NoPCs EUR 1
```

Check output:
- `isolation_run_control_BOLT/Day_NoPCs/EUR/var_split/bolt_isolation_run_control.*.*.BOLT.stats.gz`
- Look for errors in log files

## ✓ Step 8: Submit Full Analysis

Once test run succeeds:

```bash
cd isolation_run_control_BOLT
bash 1a_bolt_lmm.sbatch.sh
```

This submits 138 jobs (69 variant splits × 2 covariate sets)

## ✓ Step 9: Monitor Progress

```bash
# Check SLURM queue
squeue -u $USER

# Check progress
bash 99_check_progress.sh
```

## ✓ Step 10: Combine Results

After all jobs complete:

```bash
cd isolation_run_control_BOLT
bash 1b_combine_bolt_output.sh
```

## Common Issues and Solutions

### Issue: "bolt: command not found"
**Solution**: Add BOLT-LMM to PATH or use full path in bolt_lmm.sh

### Issue: "LD scores file not found"
**Solution**: Update paths in bolt_lmm.sh to point to BOLT-LMM tables directory

### Issue: Out of memory
**Solution**: Increase --mem in 1a_bolt_lmm.sbatch.sh (try 50000 or 60000)

### Issue: "No samples remain after filters"
**Solution**: Check population .keep/.remove files. May need to use --keep instead of --remove

### Issue: BOLT convergence failure
**Solution**: Check phenotype distribution. BOLT may struggle with very skewed or sparse phenotypes.

### Issue: "modelSnps file not found"
**Solution**: Run 0_prepare_model_snps.sh first

## Resource Requirements

Per job:
- **Memory**: 40GB (may need 50-60GB for large datasets)
- **Cores**: 8
- **Runtime**: 6-12 hours per variant split (depends on sample size)
- **Disk**: ~50GB for temporary files

Total analysis:
- **138 jobs** (69 splits × 2 covariate sets)
- **~20-30 hours** wall time with array parallelization

## Output Files

After completion, you should have:

```
isolation_run_control_BOLT/
├── Day_NoPCs/
│   └── EUR/
│       ├── Loneliness.bolt.stats.gz      (~1-5GB per file)
│       ├── FreqSoc.bolt.stats.gz
│       ├── AbilityToConfide.bolt.stats.gz
│       └── var_split/                    (individual results)
└── Day_10PCs/
    └── EUR/
        ├── Loneliness.bolt.stats.gz
        ├── FreqSoc.bolt.stats.gz
        ├── AbilityToConfide.bolt.stats.gz
        └── var_split/                    (individual results)
```

## Next Steps After GWAS

1. QC summary statistics (MAF, INFO score, P-value distribution)
2. Manhattan and QQ plots
3. LD Score Regression (heritability, genetic correlation)
4. Fine-mapping (FINEMAP, SuSiE)
5. Functional annotation (FUMA, MAGMA)
6. Gene-set enrichment analysis


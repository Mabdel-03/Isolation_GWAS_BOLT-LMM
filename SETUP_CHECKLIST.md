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

## ✓ Step 3: Convert Genotype Files to BED Format (Autosomes Only)

BOLT-LMM requires PLINK1 bed/bim/fam format with standard chromosome codes:

```bash
cd Isolation_GWAS_BOLT-LMM

# Submit as batch job (32GB RAM, 8 tasks, ~5-10 min)
sbatch 0a_convert_to_bed.sbatch.sh

# Monitor
tail -f convert_to_bed.*.out
```

**CRITICAL**: This converts **autosomes only (chr 1-22)**
- BOLT-LMM doesn't recognize MT, X, Y, XY chromosome codes
- Including these will cause: "ERROR: Unknown chromosome code"
- Output: `geno/ukb_genoHM3/ukb_genoHM3_bed.{bed,bim,fam}` (~145GB, autosomes only)

**No manual editing needed** - paths are pre-configured!

## ✓ Step 4: Create Model SNPs File

Generate LD-pruned SNPs for computing the genetic relationship matrix:

```bash
# Submit as batch job (80GB RAM, 8 tasks, ~15-30 min)
sbatch 0b_prepare_model_snps.sbatch.sh

# Monitor
tail -f model_snps.*.out
```

**Parameters** (optimized for HM3 data):
- MAF ≥0.5%, missingness <10%
- HWE: sample-size adjusted (--hwe 1e-5 0.001 keep-fewhet)
- LD pruning: **r²<0.5** (relaxed for HM3 variant set)
- Memory: **80GB** (required for ~500K samples)

**Output**: `geno/ukb_genoHM3/ukb_genoHM3_modelSNPs.txt`  
**Expected**: **~444,000 SNPs** (verified working)  
**Range**: 400K-600K SNPs (optimal for BOLT-LMM)

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

## ✓ Step 7: Test Run (CRITICAL - Required!)

Test the complete pipeline before submitting all jobs:

```bash
cd Isolation_GWAS_BOLT-LMM

# Submit test as SLURM batch job (100GB RAM, 100 CPUs, 47h limit)
sbatch 0c_test_run.sbatch.sh

# Monitor
tail -f bolt_test.*.out

# Check for success
grep "TEST PASSED" bolt_test.*.out
```

Check output (in Git repository):
- `results/Day_NoPCs/EUR/var_split/bolt_isolation_run_control.*.Loneliness.BOLT.stats.gz`
- `results/Day_NoPCs/EUR/var_split/bolt_isolation_run_control.*.FreqSoc.BOLT.stats.gz`
- `results/Day_NoPCs/EUR/var_split/bolt_isolation_run_control.*.AbilityToConfide.BOLT.stats.gz`
- Each should have corresponding .log.gz files
- Total: 6 files (3 phenotypes × 2 file types)

⚠️ **DO NOT proceed to full analysis unless you see "🎉 TEST PASSED!"**

## ✓ Step 8: Submit Full Analysis

Once test run succeeds:

```bash
cd Isolation_GWAS_BOLT-LMM
sbatch 1_run_bolt_lmm.sbatch.sh
```

This submits 6 jobs (3 phenotypes × 2 covariate sets) as a SLURM array  
All jobs run concurrently and process the full genome

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
- **6 jobs** (3 phenotypes × 2 covariate sets)
- **~1-2 hours** wall time (all run concurrently)

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


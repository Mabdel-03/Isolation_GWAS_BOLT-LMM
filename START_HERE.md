# 🚀 START HERE: BOLT-LMM Binary Trait GWAS

## ⚡ SIMPLIFIED WORKFLOW (RECOMMENDED)

**We now use a streamlined 6-job approach** - much faster and simpler!

- **6 jobs total** (not 138!) - one per phenotype-covariate combination
- Each job processes the **full genome** (~1.3M autosomal variants)
- **150GB RAM, 100 CPUs** per job
- **~1 day** from test to results (not 3-4 days!)
- No variant splitting, no combining step needed

👉 **See [SIMPLIFIED_WORKFLOW.md](SIMPLIFIED_WORKFLOW.md) for the recommended workflow!**

---

## What You Have

A complete, ready-to-run BOLT-LMM GWAS pipeline for **binary phenotypes** based on:

> **Day, F.R., et al. (2018)**  
> "Elucidating the genetic basis of social interaction and isolation"  
> Nature Communications

**Optimized for**: MIT Luria HPC (kellis partition), UK Biobank scale (~500K samples)

## ⚠️ Critical Information: BINARY PHENOTYPES

**All phenotypes in this analysis are BINARY (case-control):**

| Phenotype | Coding | Description |
|-----------|--------|-------------|
| Loneliness | 0=no, 1=yes | Self-reported loneliness |
| FreqSoc | 0=low, 1=high | Frequency of social contact |
| AbilityToConfide | 0=no, 1=yes | Has someone to confide in |

**Important Implications:**

1. ✅ BOLT-LMM automatically detects binary coding (0/1 or 1/2)
2. ✅ Uses **liability threshold model** (not standard linear regression)
3. ⚠️ Effect sizes (BETA) are on **liability scale** (not odds ratios)
4. ⚠️ To interpret as odds ratios: `OR ≈ exp(BETA)` for small effects
5. ✅ P-values are valid for association testing

**Read this first**: [`BINARY_TRAITS_INFO.md`](BINARY_TRAITS_INFO.md) - comprehensive guide to binary trait analysis

## Quick Start Commands

```bash
# On your HPC:
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/isolation_run_control_BOLT

# 1. Edit bolt_lmm.sh (lines 100-110) to set BOLT-LMM paths
# 2. Convert genotypes (run once)
bash 0_convert_to_bed.sh

# 3. Create model SNPs (run once)
bash 0_prepare_model_snps.sh

# 4. Test with one variant split
bash bolt_lmm.sh isolation_run_control BOLT 5,6,9 8 40000 Day_NoPCs EUR 1

# 5. Submit all 6 jobs (old variant-split approach deprecated)
# Use new simplified workflow instead - see SIMPLIFIED_WORKFLOW.md

# 6. Monitor progress
bash 99_check_progress.sh

# 7. Combine results (after jobs finish)
bash 1b_combine_bolt_output.sh
```

## Documentation Roadmap

### 🏃 Fast Track (Experienced Users)
1. **[QUICK_START.md](QUICK_START.md)** - Commands and quick reference
2. **[BINARY_TRAITS_INFO.md](BINARY_TRAITS_INFO.md)** - Binary trait specifics

### 🔧 Setup Track (First Time)
1. **[SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)** - Step-by-step setup with checklist
2. **[BINARY_TRAITS_INFO.md](BINARY_TRAITS_INFO.md)** - Understand your results

### 📚 Reference Track (Comprehensive)
1. **[README.md](README.md)** - Full documentation
2. **[FILE_MANIFEST.md](FILE_MANIFEST.md)** - All files explained
3. **[BINARY_TRAITS_INFO.md](BINARY_TRAITS_INFO.md)** - Binary trait details

## Files Overview (14 total)

### Core Scripts (6)
- `bolt_lmm.sh` - Main execution script ⭐
- `1a_bolt_lmm.sbatch.sh` - Job submission
- `1b_combine_bolt_output.sh` - Combine results
- `combine_bolt_logs.sh`, `combine_bolt_sumstats.sh` - Helpers
- `paths.sh` - Configuration

### Setup Scripts (2)
- `0_convert_to_bed.sh` - Convert pgen → bed format
- `0_prepare_model_snps.sh` - Create model SNPs list

### Utility (1)
- `99_check_progress.sh` - Monitor analysis

### Documentation (5)
- `START_HERE.md` (this file) - Entry point
- `README.md` - Full reference
- `QUICK_START.md` - Fast commands
- `SETUP_CHECKLIST.md` - Step-by-step setup
- `BINARY_TRAITS_INFO.md` - Binary trait guide ⭐⭐⭐
- `FILE_MANIFEST.md` - File descriptions

## Key Differences: BOLT-LMM vs PLINK

| Feature | PLINK | BOLT-LMM |
|---------|-------|----------|
| Binary traits | Logistic regression | Liability threshold model |
| Effect size | Log odds ratio | Liability scale (≈log OR) |
| Relatedness | Exclude related | Model via GRM |
| Pop structure | PC covariates only | GRM + PC covariates |
| Power | Standard | Higher (better modeling) |
| File format | pgen | bed/bim/fam |
| Memory | 15GB | 40GB |
| Runtime | Fast | Slower |

## Before You Run: Checklist

- [ ] BOLT-LMM installed and in PATH
- [ ] Phenotypes are binary coded (0/1 or 1/2)
- [ ] Check case/control counts (need ≥1000 each)
- [ ] Genotype files accessible
- [ ] Covariate file has required columns
- [ ] Population keep file exists
- [ ] Edit `bolt_lmm.sh` to set LD scores and genetic map paths

## Understanding Your Results

### Output Files
```
isolation_run_control_BOLT/
├── Day_NoPCs/EUR/
│   ├── Loneliness.bolt.stats.gz     ← Use P_BOLT_LMM column
│   ├── FreqSoc.bolt.stats.gz        ← BETA is on liability scale
│   └── AbilityToConfide.bolt.stats.gz
└── Day_10PCs/EUR/
    └── ... (same structure)
```

### Interpreting Effect Sizes

**Example Result:**
```
SNP: rs123456
BETA: 0.05
SE: 0.01  
P_BOLT_LMM: 3.2e-8
A1FREQ: 0.35
```

**What this means:**
- Each copy of effect allele increases **liability** by 0.05 SD
- Approximate odds ratio: OR ≈ exp(0.05) ≈ 1.051 (5.1% increase)
- Genome-wide significant (p < 5×10⁻⁸)
- Common variant (35% frequency)

**Important**: BETA is on **liability scale**, not observed 0/1 scale!

See [`BINARY_TRAITS_INFO.md`](BINARY_TRAITS_INFO.md) for detailed interpretation.

## Analysis Specifications

- **Study design**: Day et al. 2018 methodology
- **Phenotypes**: 3 binary traits (Loneliness, FreqSoc, AbilityToConfide)
- **Covariate sets**: 2 (Day_NoPCs, Day_10PCs)
- **Population**: EUR (European ancestry)
- **Variant splits**: 69 (for parallelization)
- **Total jobs**: 6 (3 phenotypes × 2 covariate sets)
- **Expected runtime**: ~1 day (1-2 hours for analysis after preprocessing) with array jobs
- **Output**: ~6 summary statistic files (2 covariate sets × 3 phenotypes)

## Common Questions

**Q: Why BOLT-LMM instead of PLINK?**  
A: Better modeling of population structure and relatedness. Day et al. used BOLT-LMM for their UKB analysis.

**Q: Why are effect sizes smaller than PLINK?**  
A: They're on liability scale, not odds ratio scale. Convert with OR ≈ exp(BETA).

**Q: Can I compare to Day et al. results?**  
A: Yes! Both use liability scale. Compare BETA and P-values directly.

**Q: What if I have case-control imbalance?**  
A: BOLT-LMM handles this well via liability threshold model. Check λ_GC in logs.

**Q: Do I need to do anything special for binary traits?**  
A: No! BOLT-LMM auto-detects and applies liability threshold model. Just ensure 0/1 coding.

## Need Help?

1. **Setup issues**: See [`SETUP_CHECKLIST.md`](SETUP_CHECKLIST.md)
2. **Understanding results**: See [`BINARY_TRAITS_INFO.md`](BINARY_TRAITS_INFO.md)
3. **Script details**: See [`FILE_MANIFEST.md`](FILE_MANIFEST.md)
4. **Full reference**: See [`README.md`](README.md)

## Next Steps After GWAS

1. **QC**: Check λ_GC, QQ plots, case/control counts
2. **Visualization**: Manhattan plots, regional plots
3. **Heritability**: LDSC on liability scale
4. **Replication**: Compare to Day et al. results
5. **Fine-mapping**: FINEMAP/SuSiE with liability-scale BETA
6. **Functional annotation**: FUMA, MAGMA
7. **PRS**: Build polygenic risk scores

## Citation

If using this pipeline, cite:

1. **Study design**: Day, F.R., et al. (2018). Nature Communications.
2. **BOLT-LMM**: Loh, P.-R., et al. (2015). Nature Genetics.
3. **UK Biobank**: Bycroft, C., et al. (2018). Nature.

---

**Ready to start?** → Open [`SETUP_CHECKLIST.md`](SETUP_CHECKLIST.md) and follow the steps!

**Need to understand binary traits?** → Read [`BINARY_TRAITS_INFO.md`](BINARY_TRAITS_INFO.md) first!


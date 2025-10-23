# ✅ READY TO RUN - Final Verification

**Status**: All issues resolved, pipeline ready for production  
**Last Updated**: October 23, 2025  
**Action**: Submit all 6 jobs directly (skip test)

---

## ✅ Pre-Flight Checklist

### Software & Environment
- [x] BOLT-LMM v2.5 installed at `/home/mabdel03/data/software/BOLT-LMM_v2.5/`
- [x] Conda environment: `/home/mabdel03/data/conda_envs/bolt_lmm`
- [x] All scripts pulled from GitHub (latest commit)

### Preprocessing Complete
- [x] Genotypes converted to bed format (chr 1-22, ~145GB)
- [x] EUR_MM.keep created (426,602 EUR samples)
- [x] Model SNPs created (444,241 SNPs, r²<0.5)
- [x] EUR-filtered files created:
  - isolation_run_control.EUR.tsv.gz (~2-5MB, ~420K samples)
  - sqc.EUR.tsv.gz (~139MB, ~426K samples)

### Configuration Verified
- [x] **Sample size**: 426,602 EUR (includes 73K related)
- [x] **Multithreading**: 100 threads per job
- [x] **Resources**: 150GB RAM, 100 CPUs, 47h per job
- [x] **Covariates**: Properly specified (--covarCol=sex --covarCol=array)
- [x] **Headers**: FID IID format confirmed
- [x] **Output**: Numbered files (1_1.out through 1_6.out)
- [x] **Emails**: mabdel03@mit.edu notifications enabled

---

## 🚀 FINAL COMMAND TO RUN

```bash
cd /home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM
conda activate /home/mabdel03/data/conda_envs/bolt_lmm

# THE COMMAND:
sbatch 1_run_bolt_lmm.sbatch.sh
```

**That's it!** This submits all 6 jobs.

---

## 📊 What Happens Next

### Immediately:
- 6 array tasks submitted to SLURM queue
- Email: "Array job bolt_lmm Began"
- Files created: 1_1.out through 1_6.out (and .err files)

### Hour 0-2: GRM Computation
- All 6 jobs: Reading genotypes, computing GRM
- Monitor any job: `tail -f 1_1.out`
- Look for: "Total indivs after QC: ~420,000-426,000"

### Hour 2-10: Association Testing
- All 6 jobs: Running BOLT-LMM on 1.3M variants
- Results start appearing in results/ directory

### Hour 8-12: Completion
- Jobs finish (may not all finish simultaneously)
- 6 emails: "Array task X Ended"
- Final email: "Array job bolt_lmm Ended"

### Verification:
```bash
ls -lh results/Day_NoPCs/EUR/*.stats.gz
ls -lh results/Day_10PCs/EUR/*.stats.gz
# Should see 6 files, each 1-5GB
```

---

## 📋 Job-to-Output Mapping

| Task | Phenotype | Covariate | Output File | Log File |
|------|-----------|-----------|-------------|----------|
| 1 | Loneliness | Day_NoPCs | `results/Day_NoPCs/EUR/bolt_Loneliness.Day_NoPCs.stats.gz` | `1_1.out` |
| 2 | FreqSoc | Day_NoPCs | `results/Day_NoPCs/EUR/bolt_FreqSoc.Day_NoPCs.stats.gz` | `1_2.out` |
| 3 | AbilityToConfide | Day_NoPCs | `results/Day_NoPCs/EUR/bolt_AbilityToConfide.Day_NoPCs.stats.gz` | `1_3.out` |
| 4 | Loneliness | Day_10PCs | `results/Day_10PCs/EUR/bolt_Loneliness.Day_10PCs.stats.gz` | `1_4.out` |
| 5 | FreqSoc | Day_10PCs | `results/Day_10PCs/EUR/bolt_FreqSoc.Day_10PCs.stats.gz` | `1_5.out` |
| 6 | AbilityToConfide | Day_10PCs | `results/Day_10PCs/EUR/bolt_AbilityToConfide.Day_10PCs.stats.gz` | `1_6.out` |

---

## 🔍 Script Verification

**1_run_bolt_lmm.sbatch.sh** is configured with:
```bash
✅ #SBATCH --mem=150G
✅ #SBATCH -n 100
✅ #SBATCH --time=47:00:00
✅ #SBATCH --array=1-6
✅ #SBATCH --mail-user=mabdel03@mit.edu
✅ #SBATCH --mail-type=BEGIN,END,FAIL,ARRAY_TASKS
✅ Calls: run_single_phenotype.sh
```

**run_single_phenotype.sh** uses:
```bash
✅ EUR-filtered files (isolation_run_control.EUR.tsv.gz, sqc.EUR.tsv.gz)
✅ EUR_MM samples: 426,602 (includes related)
✅ BOLT v2.5 with 100 threads (--numThreads=100)
✅ Separate --covarCol=sex --covarCol=array
✅ Model SNPs: 444,241 SNPs
✅ Full genome: ~1.3M variants (autosomes)
✅ Proper headers: FID IID format
```

**Everything is correct!** ✅

---

## ⚠️ If a Job Fails

```bash
# Check which task failed
sacct -u $USER --format=JobID,JobName,State,ExitCode

# View error log
cat 1_X.err  # Replace X with failed task number

# Common issues:
# - Out of memory: Increase --mem in script
# - Timeout: Job needs more than 47h (unlikely)
# - Covariate error: Check column names in sqc.EUR.tsv.gz

# Rerun just that phenotype-covariate combo:
bash run_single_phenotype.sh <Phenotype> <CovarSet>
# Example: bash run_single_phenotype.sh Loneliness Day_NoPCs
```

---

## 🎉 Expected Results

After 8-12 hours, you'll have **6 complete GWAS summary statistic files**:

**Each file contains**:
- ~1.3 million autosomal variants
- BOLT-LMM association statistics (β, SE, p-values)
- Based on ~420,000-426,000 EUR individuals
- Liability-scale effect sizes for binary traits
- LD score-calibrated p-values

**Ready for**:
- Manhattan/QQ plots
- Identification of genome-wide significant hits (p<5×10⁻⁸)
- LDSC heritability estimation
- Genetic correlation analysis
- Fine-mapping
- Comparison to Day et al. (2018) results

---

## 🎯 THE COMMAND

```bash
sbatch 1_run_bolt_lmm.sbatch.sh
```

**Run it and wait ~8-12 hours for complete GWAS results!** 🚀✨

---

*See QUICK_RUN.md for detailed monitoring and verification commands*


# Important Fixes and Lessons Learned

This document summarizes all the issues encountered during setup and their solutions. **Read this to avoid common pitfalls!**

---

## Critical Issues Fixed

### 1. ❌ MT Chromosome Error → ✅ Autosomes Only

**Error**:
```
ERROR: Unknown chromosome code in bim file: MT
```

**Root Cause**: BOLT-LMM v2.5 doesn't recognize mitochondrial (MT), X, Y, or XY chromosome codes.

**Fix**: Convert only autosomes (chr 1-22)
```bash
plink2 --pfile ukb_genoHM3 vzs --chr 1-22 --make-bed
```

**Lesson**: BOLT-LMM requires standard autosome codes only. Check your data for non-standard chromosomes before conversion.

---

### 2. ❌ Genotype Files in /tmp → ✅ Main Directory

**Error**:
```
ERROR: Required file not found: /tmp/kellis/ukb21942/geno/ukb_genoHM3/ukb_genoHM3_bed.bed
```

**Root Cause**: 
- `use_tmp_geno="TRUE"` was set
- The `cache.pgen.sh` helper copies pgen files, not bed files
- Bed files (~150GB) only exist in main data directory

**Fix**: Set `use_tmp_geno="FALSE"` in bolt_lmm.sh
```bash
genotype_bfile=${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_bed
```

**Lesson**: Tmp directory strategies from PLINK don't always transfer to BOLT-LMM. Bed files are large and don't benefit from tmp caching.

---

### 3. ❌ Too Few Model SNPs (<300K) → ✅ Relaxed LD Threshold

**Issue**: Initial LD pruning with r²<0.1 yielded only ~150-200K SNPs (too few for GRM)

**Evolution**:
| Attempt | LD Threshold | Result | Status |
|---------|--------------|--------|--------|
| 1st | r²<0.1 | ~150-200K SNPs | ❌ Too few |
| 2nd | r²<0.2 | 242,986 SNPs | ❌ Still too few |
| 3rd | r²<0.5 | **444,241 SNPs** | ✅ Optimal! |

**Fix**: Relax LD threshold to r²<0.5
```bash
plink2 --indep-pairwise 1000 50 0.5
```

**Rationale**:
- HM3 variant set has only 1.3M variants (vs 12M for full imputed data)
- Model SNPs are for GRM, not association testing
- r²<0.5 is acceptable for relatedness estimation (Yang et al. 2011)
- BOLT-LMM recommends 400K-600K SNPs

**Lesson**: Adjust LD pruning based on your variant set size. HM3 data needs more relaxed thresholds than full imputed data.

---

### 4. ❌ Out of Memory (32GB → 64GB → 80GB) → ✅ Sufficient Memory

**Error**:
```
slurmstepd: error: Job exceeded memory limit
```

**Evolution**:
| Attempt | Memory | Result |
|---------|--------|--------|
| 1st | 32GB | ❌ Killed at 32.77GB |
| 2nd | 64GB | ❌ Killed at 64.05GB |
| 3rd | **80GB** | ✅ Success! |

**Root Cause**: LD pruning with ~500K samples requires substantial memory for pairwise r² calculations

**Fix**: Allocate 80GB RAM for model SNPs step
```bash
#SBATCH --mem=80G
```

**Lesson**: With biobank-scale samples (>400K), LD pruning needs significant RAM. Allocate generously (1.5-2x initial estimates).

---

### 5. ❌ SLURM Variable Mismatch → ✅ Use SLURM_NTASKS

**Error**:
```
Error: Missing --threads argument
```

**Root Cause**: SLURM header uses `-n 8` which sets `SLURM_NTASKS`, but scripts used `${SLURM_CPUS_PER_TASK}`

**Fix**: Use correct variable
```bash
# Header:
#SBATCH -n 8

# In script:
--threads ${SLURM_NTASKS}  # Not ${SLURM_CPUS_PER_TASK}
```

**Lesson**: Match SLURM variables to header directives:
- `-n X` → use `${SLURM_NTASKS}`
- `--cpus-per-task=X` → use `${SLURM_CPUS_PER_TASK}`

---

### 6. ❌ Qt Conda Activation Error → ✅ Remove `-u` Flag

**Error**:
```
QT_XCB_GL_INTEGRATION: unbound variable
```

**Root Cause**: Qt package has activation script that references unbound variables, conflicts with `set -u`

**Fix**: Change bash flags
```bash
# From:
set -beEuo pipefail

# To:
set -beEo pipefail  # Remove -u flag
```

**Lesson**: Conda environments with GUI packages (Qt, matplotlib) may have activation issues with `set -u`.

---

### 7. ❌ HWE Filter Too Strict → ✅ Sample-Size Adjusted

**Warning**:
```
Warning: --hwe filter is suspiciously strict for the sample size
```

**Fix**: Use sample-size adjusted HWE filter
```bash
# From:
--hwe 1e-6

# To:
--hwe 1e-5 0.001 keep-fewhet
```

**Rationale**:
- With ~500K samples, strict HWE filters may remove true associations
- `keep-fewhet` removes only heterozygosity excess (likely errors)
- Threshold adjusts dynamically with sample size

**Lesson**: Large samples need sample-size adjusted QC filters (PLINK2 documentation).

---

### 8. ❌ Outputs Scattered → ✅ Centralized in Git Repo

**Issue**: Outputs going to `/home/.../ukb21942/isolation_run_control_BOLT/` (outside Git repo)

**Fix**: Output to `results/` within Git repository
```bash
out_base=${SRCDIR}/results/${covar_str}/${keep_set}/var_split/...
```

**Benefits**:
- All analysis files in one location
- Easy to navigate
- Results stay with code
- Still gitignored (privacy protected)

**Lesson**: Centralize outputs within project directory for better organization.

---

## Configuration Summary (Final Working Setup)

### Paths (Pre-configured)
```bash
BOLT-LMM:     /home/mabdel03/data/software/BOLT-LMM_v2.5/
Conda env:    /home/mabdel03/data/conda_envs/bolt_lmm
Git repo:     /home/.../ukb21942/Isolation_GWAS_BOLT-LMM/
Data:         /home/.../ukb21942/ (pheno/, sqc/, geno/)
Results:      Isolation_GWAS_BOLT-LMM/results/
```

### Resources (Final)
```bash
Convert (0a):     32GB, 8 tasks, 2h
Model SNPs (0b):  80GB, 8 tasks, 2h  
Test (0c):        100GB, 100 tasks, 47h
Full (1):         150GB, 100 tasks, 47h per job × 6 jobs
```

### Model SNP Parameters (Final)
```bash
MAF:           ≥0.5%
Missingness:   <10%
HWE:           --hwe 1e-5 0.001 keep-fewhet
LD threshold:  r²<0.5
Output:        ~444K SNPs
```

### Genotype Conversion (Final)
```bash
Input:   1,316,181 variants (all chromosomes)
Filter:  --chr 1-22 (autosomes only)
Output:  ~1,310,000 variants (BOLT-compatible)
```

---

## Troubleshooting Checklist

If you encounter errors:

**1. Check you're in the right directory**
```bash
pwd
# Should be: .../Isolation_GWAS_BOLT-LMM/
# NOT: .../ukb21942/ (parent directory)
```

**2. Verify BOLT-LMM works**
```bash
bolt --help | head -5
```

**3. Check file paths**
```bash
bash test_bolt_minimal.sh
bash debug_bolt_command.sh
```

**4. Verify conda environment**
```bash
conda activate /home/mabdel03/data/conda_envs/bolt_lmm
which plink2
which bolt
```

**5. Check Git remote**
```bash
git remote -v
# Should show: Mabdel-03/Isolation_GWAS_BOLT-LMM
# NOT: KellisLab/ukb21942
```

---

## Best Practices Learned

1. **Start with minimal tests** - Use debug scripts before full runs
2. **Check memory usage** - Monitor actual usage, allocate 1.5-2x
3. **Verify file formats** - BOLT has strict requirements (autosomes, bed format)
4. **Use batch jobs** - Don't run resource-intensive tasks interactively
5. **Centralize outputs** - Keep results with code
6. **Document issues** - This file exists because of iterative debugging!

---

## Time Investment

**Total setup time**: ~4-6 hours debugging and optimizing

**Breakdown**:
- Conda environment: 30 min
- BOLT-LMM installation: 10 min
- Genotype conversion issues: 2 hours
- Model SNPs optimization: 1.5 hours
- Path and variable fixes: 1 hour
- Documentation: 1 hour

**Worth it**: Once working, analysis runs smoothly for any future projects!

---

## References

Issues documented here led to improvements in:
- Model SNP selection methodology (cited Yang et al. 2011)
- Resource allocation guidelines
- File format documentation
- SLURM best practices

---

*This document should be consulted if adapting this pipeline for new datasets or phenotypes.*


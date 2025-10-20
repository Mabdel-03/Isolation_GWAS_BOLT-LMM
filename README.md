# BOLT-LMM GWAS Analysis: Social Isolation Phenotypes

## Background and Motivation

### Study Overview

This analysis pipeline implements genome-wide association studies (GWAS) for three binary social isolation phenotypes using BOLT-LMM (Bayesian mixed model association testing). The study design and phenotype definitions follow the methodology established by Day et al. (2018) in their seminal work on the genetic basis of social interaction and isolation[^1].

Social isolation and loneliness are major public health concerns associated with increased mortality risk, cardiovascular disease, and mental health disorders[^2]. Understanding the genetic architecture of these traits can provide insights into their biological mechanisms and potential therapeutic targets. The heritability of loneliness has been estimated at 14-27%[^3], suggesting a meaningful genetic component amenable to GWAS analysis.

### Data Source: UK Biobank

This analysis uses data from the UK Biobank, a large-scale prospective cohort study with deep genetic and phenotypic data on approximately 500,000 participants aged 40-69 years at recruitment[^4]. The UK Biobank genotype data includes:

- **Array genotyping**: ~800,000 directly genotyped variants using UK BiLEVE Axiom and UK Biobank Axiom arrays
- **Imputation**: ~96 million variants imputed to the Haplotype Reference Consortium, UK10K, and 1000 Genomes Project reference panels
- **Quality control**: Extensive sample and variant QC performed by the UK Biobank team
- **Population**: Primarily of European ancestry, with participants from across the United Kingdom

For this analysis, we use the HapMap3-filtered genotype dataset (`ukb_genoHM3`), which contains ~1.3 million high-quality, common variants optimized for heritability and genetic correlation analyses.

### Phenotypes: Binary Social Isolation Traits

This analysis examines three binary phenotypes related to social isolation and support:

#### 1. Loneliness
- **UK Biobank Field**: 2020
- **Question**: "Do you often feel lonely?"
- **Coding**: 0 = No, 1 = Yes
- **Prevalence**: ~5-10% in UK Biobank European ancestry participants
- **Interpretation**: Self-reported feelings of loneliness independent of objective social isolation

#### 2. Frequency of Social Contact (FreqSoc)
- **UK Biobank Field**: 1031
- **Question**: "Including yourself, how many people are living together in your household?"
- **Derived**: Dichotomized into low vs. high frequency of social contact
- **Coding**: 0 = Low frequency, 1 = High frequency
- **Interpretation**: Objective measure of social interaction frequency

#### 3. Ability to Confide (AbilityToConfide)
- **UK Biobank Field**: 2110
- **Question**: "Do you have someone you can confide in?"
- **Coding**: 0 = No, 1 = Yes
- **Prevalence**: ~90% report having someone to confide in
- **Interpretation**: Measure of social support availability

### Why BOLT-LMM?

We use BOLT-LMM v2.5[^5][^6] for association testing rather than standard logistic regression for several key advantages:

1. **Linear Mixed Model Framework**: Accounts for population structure and cryptic relatedness through a genetic relationship matrix (GRM), providing better control than fixed-effect principal components alone

2. **Increased Power**: BOLT-LMM's Bayesian approach can increase power to detect associations, especially for polygenic traits, by modeling a mixture distribution of effect sizes

3. **Liability Threshold Model**: For binary traits, BOLT-LMM uses a liability threshold model, which is more appropriate than standard linear models for case-control phenotypes

4. **Calibration**: LD Score regression-based calibration ensures proper test statistic calibration and controls genomic inflation

5. **Computational Efficiency**: BOLT-LMM is optimized for biobank-scale data, making it feasible to analyze ~500,000 samples with millions of variants

6. **Established Methodology**: The Day et al. (2018) study used BOLT-LMM for their UK Biobank analyses, ensuring methodological consistency and comparability

---

## Analysis Pipeline Overview

The pipeline consists of several stages executed on high-performance computing infrastructure using SLURM job scheduling:

```
┌─────────────────────────────────────────────────────────────┐
│                    PREPROCESSING PHASE                       │
│  (One-time setup, ~2-3 hours total)                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
    ┌───────────────────────────────────────────┐
    │  Step 1: Genotype Format Conversion       │
    │  Script: 0a_convert_to_bed.sbatch.sh     │
    │  Input:  PLINK2 .pgen/pvar/psam files    │
    │  Output: PLINK1 .bed/bim/fam files       │
    │  Time:   ~5-10 minutes                    │
    └───────────────────────────────────────────┘
                            ↓
    ┌───────────────────────────────────────────┐
    │  Step 2: Model SNP Selection              │
    │  Script: 0b_prepare_model_snps.sbatch.sh │
    │  Process: LD pruning (r² < 0.5)          │
    │  Output: ~500K SNPs for GRM              │
    │  Time:   ~15-30 minutes                   │
    └───────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    VALIDATION PHASE                          │
│  (Critical checkpoint before full analysis)                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
    ┌───────────────────────────────────────────┐
    │  Step 3: Test Run                         │
    │  Script: 0c_test_run.sbatch.sh           │
    │  Process: Run BOLT-LMM on 1 variant split│
    │  Validates: All 3 phenotypes             │
    │  Time:   ~1-3 hours                       │
    └───────────────────────────────────────────┘
                            ↓
                    ⚠️  TEST MUST PASS  ⚠️
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    ANALYSIS PHASE                            │
│  (Main computational workload, ~1-2 days)                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
    ┌───────────────────────────────────────────┐
    │  Step 4: Full BOLT-LMM Analysis           │
    │  Script: 1a_bolt_lmm.sbatch.sh           │
    │  Jobs:   138 (69 splits × 2 cov sets)    │
    │  Time:   6-12 hours per job              │
    └───────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    POST-PROCESSING PHASE                     │
│  (Combine results, ~1-2 hours)                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
    ┌───────────────────────────────────────────┐
    │  Step 5: Combine Summary Statistics       │
    │  Script: 1b_combine_bolt_output.sh       │
    │  Output: Final GWAS results per phenotype│
    │  Files:  6 combined .stats.gz files      │
    └───────────────────────────────────────────┘
```

---

## Detailed Pipeline Components

### Phase 1: Preprocessing

#### Step 1: Genotype Format Conversion

**Script**: `0a_convert_to_bed.sbatch.sh`

**Purpose**: Convert PLINK2 binary genotype files to PLINK1 format required by BOLT-LMM.

**Background**: BOLT-LMM requires genotype data in PLINK1 binary format (.bed/.bim/.fam), while modern genomic pipelines typically use PLINK2's more efficient .pgen format. This conversion step uses PLINK2's `--make-bed` function to create compatible files.

**Input**:
- `ukb_genoHM3.pgen`: Genotype matrix (compressed binary)
- `ukb_genoHM3.pvar.zst`: Variant information (Zstandard compressed)
- `ukb_genoHM3.psam`: Sample information

**Process**:
```bash
plink2 \
    --pfile ukb_genoHM3 vzs \
    --make-bed \
    --out ukb_genoHM3_bed \
    --threads 8 \
    --memory 32000
```

**Output**:
- `ukb_genoHM3_bed.bed`: Binary genotype matrix (~150GB)
- `ukb_genoHM3_bed.bim`: Variant information (~42MB, 1.3M variants)
- `ukb_genoHM3_bed.fam`: Sample information (~12MB, 488K samples)

**Resources**: 32GB RAM, 8 CPUs, ~5-10 minutes

**Quality Checks**:
- Verifies all three output files are created
- Counts variants and samples
- Reports file sizes

---

#### Step 2: Model SNP Selection

**Script**: `0b_prepare_model_snps.sbatch.sh`

**Purpose**: Create a list of high-quality, LD-pruned SNPs for computing the genetic relationship matrix (GRM).

**Background**: BOLT-LMM uses a subset of genetic variants to compute the GRM that models population structure and relatedness. Using all variants would be computationally prohibitive and unnecessary, as LD-pruned common variants capture genome-wide relatedness effectively[^5]. The recommended set size is 400,000-600,000 SNPs.

The choice of LD pruning threshold for model SNPs is a balance between computational efficiency and accuracy. While very strict pruning (r²<0.1) is common in GWAS QC, mixed model analyses can benefit from more relaxed thresholds. Yang et al. (2011) demonstrated that r²<0.5 provides accurate relatedness estimates while retaining sufficient markers[^9]. For the HM3 variant set used here, which contains only ~1.3 million high-quality variants (compared to ~12 million for full imputed data), a threshold of r²<0.5 is necessary to achieve the recommended 400,000-600,000 model SNPs.

**Quality Control Filters**:

1. **Minor Allele Frequency (MAF)**: ≥ 0.5% (`--maf 0.005`)
   - Includes common and low-frequency variants
   - More liberal than typical GWAS QC (≥1%) since model SNPs are for GRM, not association testing
   - Ensures sufficient marker coverage across the genome
   
2. **Missingness**: < 10% per SNP (`--geno 0.10`)
   - Removes poorly genotyped variants
   - More permissive than association testing thresholds since model SNPs don't directly enter hypothesis tests
   
3. **Hardy-Weinberg Equilibrium (HWE)**: Sample-size adjusted filter (`--hwe 1e-5 0.001 keep-fewhet`)
   - Uses dynamic threshold appropriate for large sample sizes (~500,000 individuals)
   - `keep-fewhet` flag removes only heterozygosity **excess** (potential genotyping errors)
   - Preserves variants with heterozygosity deficiency (may represent true selection)
   - Addresses PLINK2 recommendations for biobank-scale datasets[^8]
   
4. **LD Pruning**: r² < 0.5 in 1000kb windows, 50 SNP steps (`--indep-pairwise 1000 50 0.5`)
   - Retains approximately independent markers while maximizing genome coverage
   - More relaxed than typical GWAS pruning (r²<0.2) to accommodate the HM3 variant set
   - For GRM computation, moderate LD (r²<0.5) is acceptable and commonly used[^9]
   - Empirically optimized to yield 400,000-600,000 SNPs from HM3 data
   - Note: The HM3 set contains only 1.3M variants (vs. ~12M for full imputed data), necessitating less aggressive pruning

5. **Chromosome Filter**: Autosomes only (chr 1-22)
   - Excludes sex chromosomes (X, Y, XY) and mitochondrial DNA
   - Simplifies GRM computation and avoids sex-specific LD patterns
   - Standard practice for autosomal trait analysis

**Process**:
```bash
plink2 \
    --pfile ukb_genoHM3 vzs \
    --chr 1-22 \
    --maf 0.005 \
    --geno 0.10 \
    --hwe 1e-5 0.001 keep-fewhet \
    --indep-pairwise 1000 50 0.5 \
    --out ukb_genoHM3_modelSNPs \
    --threads 8 \
    --memory 64000
```

**Output**:
- `ukb_genoHM3_modelSNPs.txt`: List of ~500,000 SNP IDs for GRM computation
- `ukb_genoHM3_modelSNPs.log`: PLINK2 log file

**Resources**: 64GB RAM, 8 CPUs, ~15-30 minutes

**Rationale for Relaxed Filters**: Model SNPs are used solely for computing the genetic relationship matrix (GRM) to control for population structure and relatedness. They do not directly enter association tests. Therefore, more relaxed QC filters are appropriate and commonly employed in mixed model analyses[^9][^10]. The r²<0.5 threshold balances:
- Genome-wide marker coverage (crucial for accurate relatedness estimation)
- Computational efficiency (fewer redundant markers in high-LD regions)
- Compatibility with the HM3 variant set (1.3M variants vs. 12M in full imputed data)

This approach is consistent with BOLT-LMM best practices and similar to model SNP selection in other large-scale biobank studies[^11].

**Quality Checks**:
- Verifies SNP count is in recommended range (300K-700K)
- Warns if outside optimal range

---

### Phase 2: Validation

#### Step 3: Test Run

**Script**: `0c_test_run.sbatch.sh`

**Purpose**: Validate the complete BOLT-LMM pipeline on a single variant split before committing computational resources to the full analysis.

**Background**: Running BOLT-LMM on the complete genome for 138 jobs (~1,656 CPU-hours) requires significant computational resources. A test run on a single variant split (representing ~1/69th of the genome) validates that:
- All input files are correctly formatted
- BOLT-LMM configuration is correct
- Phenotype and covariate files are compatible
- Expected output files are generated
- No runtime errors occur

**What It Tests**:
- Runs BOLT-LMM on variant split 1 (~19,000 variants)
- Processes all 3 phenotypes (Loneliness, FreqSoc, AbilityToConfide)
- Uses Day_NoPCs covariate model
- EUR population subset

**Process**:
```bash
bash bolt_lmm.sh isolation_run_control BOLT 5,6,9 8 45000 Day_NoPCs EUR 1
```

**Expected Outputs** (per phenotype):
- `bolt_isolation_run_control.array_both_1.[Phenotype].BOLT.stats.gz`: Association statistics
- `bolt_isolation_run_control.array_both_1.[Phenotype].BOLT.log.gz`: BOLT-LMM log

**Resources**: 45GB RAM, 8 CPUs, ~1-3 hours

**Success Criteria**:
- All 6 output files created (3 phenotypes × 2 file types)
- Each statistics file contains ~19,000 variants
- Log files show successful convergence
- No error messages in SLURM error log

**⚠️ Critical Checkpoint**: Do NOT proceed to full analysis if test fails!

---

### Phase 3: Main Analysis

#### Step 4: Full BOLT-LMM Analysis

**Script**: `1a_bolt_lmm.sbatch.sh` (array job submission)
**Worker Script**: `bolt_lmm.sh` (executed by each array job)

**Purpose**: Perform genome-wide association testing for all three phenotypes across the complete genome using BOLT-LMM.

**Analysis Strategy**: The genome is divided into 69 variant splits for computational efficiency and parallelization. Each split is processed independently, then results are combined.

**Variant Splits**: Defined by `ukb_geno.var_split.tsv.gz`
- 69 splits total
- Splits are based on LD blocks and chromosome boundaries
- Typical split: ~19,000 variants
- Allows concurrent processing via SLURM array jobs

**Covariate Models**:

1. **Day_NoPCs** (Primary analysis):
   - Age (quantitative)
   - Sex (categorical)
   - Genotyping array (categorical)
   - No principal components
   - Population structure controlled via GRM

2. **Day_10PCs** (Sensitivity analysis):
   - Age (quantitative)
   - Sex (categorical)  
   - Genotyping array (categorical)
   - UK Biobank PC1-PC10 (quantitative)
   - Additional PC adjustment for heritability estimation

**BOLT-LMM Configuration**:

```bash
bolt \
    --bfile=ukb_genoHM3_bed \
    --phenoFile=isolation_run_control.tsv.gz \
    --phenoCol=[Loneliness|FreqSoc|AbilityToConfide] \
    --covarFile=sqc.20220316.tsv.gz \
    --qCovarCol=[age,PC1-PC10] \
    --covarCol=[sex,array] \
    --keep=EUR.keep \
    --modelSnps=ukb_genoHM3_modelSNPs.txt \
    --LDscoresFile=LDSCORE.1000G_EUR.GRCh38.tab.gz \
    --geneticMapFile=genetic_map_hg19_withX.txt.gz \
    --lmm \
    --LDscoresMatchBp \
    --numThreads=8 \
    --statsFile=[output].stats
```

**Key BOLT-LMM Parameters**:

- `--lmm`: Use linear mixed model with Bayesian non-infinitesimal prior
- `--LDscoresMatchBp`: Match variants to reference LD Scores by chromosome and position
- `--modelSnps`: Specifies SNPs for GRM computation (from Step 2)
- `--LDscoresFile`: LD Scores for test statistic calibration[^7]
- `--geneticMapFile`: Genetic map for position interpolation
- `--verboseStats`: Output additional columns (allele frequencies, INFO scores, etc.)

**Binary Trait Handling**:

BOLT-LMM automatically detects binary phenotypes (0/1 or 1/2 coding) and applies a liability threshold model[^6]:
- Assumes an underlying continuous liability distribution
- Individuals become cases when liability exceeds a threshold
- Effect sizes (β) are on the liability scale
- Approximate conversion to odds ratio: OR ≈ exp(β) for small effects

**Job Structure**:
- **Total jobs**: 138 (69 variant splits × 2 covariate models)
- **Per job**: 
  - Processes 3 phenotypes
  - Generates 6 output files (3 stats + 3 logs)
- **Parallelization**: Up to 5 concurrent jobs (configurable)
- **Walltime**: 12 hours per job (typically completes in 6-8 hours)

**Output** (per phenotype per split):
- `bolt_isolation_run_control.[split].[phenotype].BOLT.stats.gz`
  - Contains: SNP ID, chromosome, position, alleles, frequencies, β, SE, p-values
  - Format: Tab-delimited, gzip compressed
  - Size: ~500KB - 2MB per file
  
- `bolt_isolation_run_control.[split].[phenotype].BOLT.log.gz`
  - Contains: BOLT-LMM version, parameters, sample sizes, convergence info, heritability estimates
  - Format: Text log, gzip compressed

**Resources** (per job): 45GB RAM, 8 CPUs, 12 hours, kellis partition

**Total Computational Cost**: 
- 138 jobs × 12 hours = 1,656 job-hours (if run sequentially)
- With 5 concurrent jobs: ~33 hours wall-clock time
- Total CPU-hours: 1,656 jobs × 8 CPUs = 13,248 CPU-hours

**Hardware Partition**: All jobs submitted to the **kellis partition** on the MIT Luria HPC cluster, optimized for genomics workloads with high-memory nodes.

**Output Statistics Columns**:

| Column | Description |
|--------|-------------|
| `SNP` | Variant identifier (chr:pos:ref:alt or rsID) |
| `CHR` | Chromosome (1-22) |
| `BP` | Base pair position (GRCh37/hg19) |
| `GENPOS` | Genetic position (centiMorgans) |
| `ALLELE1` | Effect allele (tested allele) |
| `ALLELE0` | Reference allele |
| `A1FREQ` | Effect allele frequency in analysis sample |
| `F_MISS` | Fraction of missing genotypes |
| `BETA` | Effect size on liability scale |
| `SE` | Standard error of effect size |
| `P_BOLT_LMM_INF` | P-value from infinitesimal mixed model |
| `P_BOLT_LMM` | **P-value from non-infinitesimal model (USE THIS)** |

**Monitoring Progress**:
```bash
# Check running jobs
squeue -u $USER

# Monitor specific job
tail -f ~/slurm_logs/isolation_run_control_BOLT/*.out

# Check overall progress
bash 99_check_progress.sh
```

---

### Phase 4: Post-Processing

#### Step 5: Combine Summary Statistics

**Scripts**: 
- `1b_combine_bolt_output.sh` (orchestration)
- `combine_bolt_logs.sh` (log combination)
- `combine_bolt_sumstats.sh` (statistics combination)

**Purpose**: Merge BOLT-LMM results from all 69 variant splits into final genome-wide summary statistics files.

**Process**:

1. **Log File Combination** (`combine_bolt_logs.sh`):
   - Concatenates log files from all variant splits
   - Preserves split identifiers for traceability
   - Useful for reviewing convergence across splits
   
2. **Summary Statistics Combination** (`combine_bolt_sumstats.sh`):
   - Merges statistics files maintaining header
   - Ensures no duplicate variants
   - Sorts by chromosome and position
   - Compresses final output

**For each phenotype**:
```bash
# Combine Day_NoPCs results
bash combine_bolt_sumstats.sh isolation_run_control Day_NoPCs EUR Loneliness
bash combine_bolt_sumstats.sh isolation_run_control Day_NoPCs EUR FreqSoc
bash combine_bolt_sumstats.sh isolation_run_control Day_NoPCs EUR AbilityToConfide

# Combine Day_10PCs results  
bash combine_bolt_sumstats.sh isolation_run_control Day_10PCs EUR Loneliness
bash combine_bolt_sumstats.sh isolation_run_control Day_10PCs EUR FreqSoc
bash combine_bolt_sumstats.sh isolation_run_control Day_10PCs EUR AbilityToConfide
```

**Final Output Structure**:
```
isolation_run_control_BOLT/
├── Day_NoPCs/
│   └── EUR/
│       ├── Loneliness.bolt.stats.gz          (~1-5GB, ~1.3M variants)
│       ├── FreqSoc.bolt.stats.gz             (~1-5GB, ~1.3M variants)
│       ├── AbilityToConfide.bolt.stats.gz    (~1-5GB, ~1.3M variants)
│       └── bolt_isolation_run_control.*.BOLT.log.gz
└── Day_10PCs/
    └── EUR/
        ├── Loneliness.bolt.stats.gz          (~1-5GB, ~1.3M variants)
        ├── FreqSoc.bolt.stats.gz             (~1-5GB, ~1.3M variants)
        ├── AbilityToConfide.bolt.stats.gz    (~1-5GB, ~1.3M variants)
        └── bolt_isolation_run_control.*.BOLT.log.gz
```

**Quality Checks**:
```bash
# Verify variant counts
for trait in Loneliness FreqSoc AbilityToConfide; do
    echo "=== $trait ==="
    zcat Day_NoPCs/EUR/${trait}.bolt.stats.gz | wc -l
done
# Expected: ~1.3M variants per trait

# Check for genome-wide significant hits (p < 5×10⁻⁸)
zcat Day_NoPCs/EUR/Loneliness.bolt.stats.gz | \
    awk 'NR>1 && $NF < 5e-8 {count++} END {print count " significant variants"}'

# Preview top associations
zcat Day_NoPCs/EUR/Loneliness.bolt.stats.gz | \
    sort -k12,12g | head -21
```

**Resources**: Minimal (no HPC submission needed), ~1-2 hours total

---

## Expected Results and Interpretation

### Statistical Power

Based on the Day et al. (2018) study and UK Biobank sample sizes:

- **Sample size**: ~450,000 European ancestry individuals
- **Effective sample size** (binary traits): Variable by phenotype prevalence
  - Loneliness (K≈0.10): Neff ≈ 72,000
  - AbilityToConfide (K≈0.90): Neff ≈ 72,000
  - FreqSoc (K≈0.50): Neff ≈ 112,500

- **Power to detect** (at α=5×10⁻⁸):
  - Common variants (MAF>5%): >80% power for OR≥1.05
  - Low-frequency variants (MAF 1-5%): >80% power for OR≥1.10

### Anticipated Findings

Based on Day et al. (2018), we expect:

1. **Polygenic Architecture**: Multiple genome-wide significant loci (p<5×10⁻⁸) per trait
   - Day et al. identified 15 independent loci for social interaction traits
   
2. **SNP-based Heritability**: 
   - Loneliness: h²ₛₙₚ ≈ 3-5% on liability scale
   - Social interaction traits: h²ₛₙₚ ≈ 4-6%
   
3. **Genomic Inflation**: λ_GC ≈ 1.01-1.05 (well-calibrated after LD Score regression)

4. **Notable Loci**: Potential associations near:
   - Neuronal development genes
   - Neurotransmitter system genes  
   - Genes involved in behavioral traits

### Effect Size Interpretation

**Liability Scale to Odds Ratio Conversion**:

For binary traits, BOLT-LMM reports effect sizes (β) on the liability scale. Approximate conversion:

```
OR ≈ exp(β)
```

For more accurate conversion accounting for prevalence (K):

```
β_observed = β_liability × √[K(1-K)] / φ(Φ⁻¹(1-K))
OR = exp(β_observed)
```

Where:
- K = population prevalence
- φ = standard normal PDF
- Φ = standard normal CDF

**Example Interpretation**:
- β = 0.05 on liability scale
- OR ≈ exp(0.05) ≈ 1.051
- Interpretation: Each copy of the effect allele increases odds of trait by ~5%

---

## Quality Control and Validation

### Pre-Analysis QC

1. **Genotype QC** (performed by UK Biobank):
   - Sample call rate > 95%
   - Variant call rate > 95%
   - MAF > 0.1% for HapMap3 set
   - HWE p > 1×10⁻⁶
   
2. **Sample QC**:
   - Genetic vs. reported sex concordance
   - Heterozygosity outliers removed
   - Related individuals retained (BOLT-LMM handles relatedness)
   
3. **Population Stratification**:
   - EUR subset defined by principal component clustering
   - Excludes non-European ancestry individuals

### Post-GWAS QC

1. **λ_GC (Genomic Inflation Factor)**:
   - Extract from BOLT-LMM log files
   - Expected: 1.00-1.05 after LD Score calibration
   - Values >1.10 suggest residual population stratification

2. **QQ Plots**:
   - Plot observed vs. expected -log₁₀(p) values
   - Should show good calibration with deviation only at tail
   
3. **Manhattan Plots**:
   - Visualize associations across genome
   - Identify genome-wide significant peaks
   
4. **LD Score Regression**:
   - Estimate SNP-based heritability (h²ₛₙₚ)
   - Assess polygenicity
   - Calculate genetic correlations between traits

Example QC code:
```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Load results
df = pd.read_csv('Loneliness.bolt.stats.gz', sep='\t', compression='gzip')

# Calculate lambda_GC
chisq = stats.chi2.ppf(1 - df['P_BOLT_LMM'], 1)
lambda_gc = np.median(chisq) / stats.chi2.ppf(0.5, 1)
print(f"λ_GC = {lambda_gc:.3f}")

# QQ plot
observed = -np.log10(df['P_BOLT_LMM'].sort_values())
expected = -np.log10(np.linspace(1/len(df), 1, len(df)))
plt.scatter(expected, observed, alpha=0.5, s=1)
plt.plot([0, max(expected)], [0, max(expected)], 'r--')
plt.xlabel('Expected -log₁₀(p)')
plt.ylabel('Observed -log₁₀(p)')
plt.title(f'QQ Plot: Loneliness (λ_GC={lambda_gc:.3f})')
```

---

## Computational Requirements

### Hardware Specifications

**HPC Cluster**: MIT Luria cluster, Kellis partition

**Per-Job Resources**:
- **Genotype conversion** (Step 1): 32GB RAM, 8 CPUs, 2 hours
- **Model SNPs preparation** (Step 2): 64GB RAM, 8 CPUs, 2 hours
  - Higher memory required for LD correlation calculations with ~500,000 samples
- **Test run** (Step 3): 45GB RAM, 8 CPUs, 6 hours
- **BOLT-LMM analysis** (Step 4): 45GB RAM, 8 CPUs, 12 hours per job
- **Combination** (Step 5): Minimal resources, no job submission needed

**Total Resource Requirements**:
- **Disk space**: ~200GB for genotypes + outputs
- **Peak memory**: 45GB per concurrent job
- **Total CPU-hours**: ~13,250 (138 jobs × 8 CPUs × ~12 hours)
- **Wall-clock time**: ~3-4 days for complete pipeline

### Software Requirements

**Core Software**:
- **BOLT-LMM v2.5**: Association testing (June 2025 release)
- **PLINK2 v2.0**: Genotype conversion and QC
- **Python 3.10**: Post-processing and visualization
- **R 4.2** (optional): Advanced visualization and downstream analyses

**Python Packages**:
- pandas, numpy, scipy: Data manipulation
- matplotlib, seaborn: Visualization
- statsmodels: Statistical analyses

**Environment**: Conda environment `bolt_lmm` with all dependencies

---

## Comparison to Day et al. (2018)

### Methodological Alignment

| Aspect | Day et al. (2018) | This Analysis |
|--------|-------------------|---------------|
| **Software** | BOLT-LMM v2.3 | BOLT-LMM v2.5 |
| **Phenotypes** | Binary social isolation traits | Same definitions |
| **Population** | UK Biobank European ancestry | Same (EUR) |
| **Sample size** | ~456,000 | ~450,000-488,000 |
| **Covariates** | Age, sex, array, assessment center, PCs | Age, sex, array, PCs |
| **Variant set** | HM3 + imputed | HM3 only (this analysis) |
| **Model** | Linear mixed model, liability threshold | Same |
| **QC** | Standard UK Biobank QC | Same |

### Key Differences

1. **Variant Set**: 
   - Day et al.: ~12M imputed variants
   - This analysis: ~1.3M HM3 variants (computational efficiency)
   - Implication: May miss some associations at imputed-only variants

2. **Covariate Models**:
   - Added Day_NoPCs model (GRM-only population structure control)
   - Allows comparison of PC adjustment effects

3. **BOLT-LMM Version**:
   - Updated to v2.5 (improved calibration and efficiency)
   - Better handling of binary traits

### Expected Reproducibility

We expect to replicate:
- ✓ Major genome-wide significant loci from Day et al.
- ✓ SNP-based heritability estimates (within confidence intervals)
- ✓ Effect size estimates for HM3 variants
- ✗ May not detect associations only present in imputed variants

---

## Downstream Analyses

After completing this pipeline, recommended follow-up analyses include:

### 1. LD Score Regression (LDSC)

**Purpose**: Estimate heritability and genetic correlations

```bash
# Heritability estimation
ldsc.py \
    --h2 Loneliness.bolt.stats.gz \
    --ref-ld-chr eur_w_ld_chr/ \
    --w-ld-chr eur_w_ld_chr/ \
    --out Loneliness.h2

# Genetic correlation
ldsc.py \
    --rg Loneliness.bolt.stats.gz,FreqSoc.bolt.stats.gz \
    --ref-ld-chr eur_w_ld_chr/ \
    --w-ld-chr eur_w_ld_chr/ \
    --out Loneliness_FreqSoc.rg
```

### 2. Fine-Mapping

**Tools**: FINEMAP, SuSiE, or PAINTOR

**Purpose**: Identify causal variants within associated loci

### 3. Functional Annotation

**Tools**: FUMA GWAS, MAGMA, or PoPS

**Purpose**: 
- Gene-based association testing
- Pathway enrichment analysis
- Tissue-specific expression patterns

### 4. Polygenic Risk Scores (PRS)

**Tools**: PRSice-2 or LDpred2

**Purpose**: Construct genetic risk scores for prediction and analysis

### 5. Genetic Correlation with Other Traits

Compare with:
- Mental health traits (depression, anxiety)
- Personality traits (extraversion, neuroticism)
- Social behaviors
- Cardiovascular disease
- All-cause mortality

---

## Troubleshooting

### Common Issues

**Issue: Out of Memory Error**
```
Solution: Increase --mem in SLURM script
Edit: 0c_test_run.sbatch.sh, change --mem=45000 to --mem=60000
```

**Issue: BOLT-LMM Convergence Failure**
```
Check: 
1. Phenotype distribution (verify binary coding)
2. Covariate correlations (high collinearity)
3. Model SNPs file exists and is correct
4. Sample overlap between phenotype and genotype files
```

**Issue: Missing Output Files**
```
Check:
1. SLURM error logs: *.err files
2. BOLT-LMM log files for error messages
3. Input file paths in bolt_lmm.sh
4. Sufficient disk space
```

**Issue: High λ_GC (>1.10)**
```
Possible causes:
1. Population stratification not fully controlled
2. Insufficient PC adjustment
3. Cryptic relatedness in sample
4. Phenotype batch effects

Solutions:
1. Include more PCs in covariate model
2. Check population ancestry filtering
3. Review BOLT-LMM log for warnings
```

### Getting Help

**Documentation**:
- This README and associated markdown files
- BOLT-LMM manual: https://alkesgroup.broadinstitute.org/BOLT-LMM/BOLT-LMM_manual.html
- UK Biobank documentation: https://biobank.ndph.ox.ac.uk/

**Support**:
- Check GitHub Issues: https://github.com/Mabdel-03/Isolation_GWAS_BOLT-LMM/issues
- Review log files for error messages
- Consult HPC support for cluster-specific issues

---

## Citation

If you use this pipeline or adapt it for your research, please cite:

1. **This Pipeline**:
   ```
   Abdelmoneum, M. (2025). BOLT-LMM GWAS Pipeline for Social Isolation Phenotypes. 
   GitHub: https://github.com/Mabdel-03/Isolation_GWAS_BOLT-LMM
   ```

2. **BOLT-LMM Software**:
   ```
   Loh, P.-R., et al. (2015). Efficient Bayesian mixed-model analysis increases 
   association power in large cohorts. Nature Genetics, 47(3), 284-290.
   
   Loh, P.-R., et al. (2018). Mixed-model association for biobank-scale datasets. 
   Nature Genetics, 50(7), 906-908.
   ```

3. **Study Design**:
   ```
   Day, F. R., et al. (2018). Elucidating the genetic basis of social interaction 
   and isolation. Nature Communications, 9(1), 2457.
   ```

4. **UK Biobank**:
   ```
   Bycroft, C., et al. (2018). The UK Biobank resource with deep phenotyping and 
   genomic data. Nature, 562(7726), 203-209.
   ```

---

## References

[^1]: Day, F. R., et al. (2018). Elucidating the genetic basis of social interaction and isolation. *Nature Communications*, *9*(1), 2457. https://doi.org/10.1038/s41467-018-04930-1

[^2]: Holt-Lunstad, J., et al. (2015). Loneliness and social isolation as risk factors for mortality: A meta-analytic review. *Perspectives on Psychological Science*, *10*(2), 227-237.

[^3]: Gao, J., et al. (2017). Genome-wide association study of loneliness demonstrates a role for common variation. *Neuropsychopharmacology*, *42*(4), 811-821.

[^4]: Bycroft, C., et al. (2018). The UK Biobank resource with deep phenotyping and genomic data. *Nature*, *562*(7726), 203-209. https://doi.org/10.1038/s41586-018-0579-z

[^5]: Loh, P.-R., et al. (2015). Efficient Bayesian mixed-model analysis increases association power in large cohorts. *Nature Genetics*, *47*(3), 284-290. https://doi.org/10.1038/ng.3190

[^6]: Loh, P.-R., et al. (2018). Mixed-model association for biobank-scale datasets. *Nature Genetics*, *50*(7), 906-908. https://doi.org/10.1038/s41588-018-0144-6

[^7]: Bulik-Sullivan, B. K., et al. (2015). LD Score regression distinguishes confounding from polygenicity in genome-wide association studies. *Nature Genetics*, *47*(3), 291-295. https://doi.org/10.1038/ng.3211

[^8]: Chang, C. C., et al. (2015). Second-generation PLINK: rising to the challenge of larger and richer datasets. *GigaScience*, *4*, 7. https://doi.org/10.1186/s13742-015-0047-8

[^9]: Yang, J., et al. (2011). GCTA: A tool for genome-wide complex trait analysis. *American Journal of Human Genetics*, *88*(1), 76-82. https://doi.org/10.1016/j.ajhg.2010.11.011 (Note: Demonstrates that r²<0.5 is suitable for GRM computation in large samples)

[^10]: Speed, D., & Balding, D. J. (2015). Relatedness in the post-genomic era: is it still useful? *Nature Reviews Genetics*, *16*(1), 33-44. https://doi.org/10.1038/nrg3821 (Review of GRM construction methods and LD pruning strategies)

[^11]: Zhou, W., et al. (2018). Efficiently controlling for case-control imbalance and sample relatedness in large-scale genetic association studies. *Nature Genetics*, *50*(9), 1335-1341. https://doi.org/10.1038/s41588-018-0184-y (SAIGE mixed model approach using similar model SNP selection)

---

## Version History

- **v1.0.0** (October 2025): Initial pipeline implementation
  - BOLT-LMM v2.5 integration
  - Complete SLURM batch workflow
  - Three binary social isolation phenotypes
  - EUR population analysis

---

## License

This pipeline is released under the MIT License. See LICENSE file for details.

The underlying data (UK Biobank) and software (BOLT-LMM) have their own licensing terms which must be respected.

---

## Acknowledgments

- UK Biobank participants and research team
- BOLT-LMM development team (Broad Institute/Harvard)
- Day et al. for establishing the methodological framework
- MIT Luria HPC cluster and support staff
- Kellis Lab computational resources

---

*Last Updated: October 20, 2025*

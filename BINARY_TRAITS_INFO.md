# Binary Traits in BOLT-LMM: Important Information

## Overview

This analysis uses **binary (case-control) phenotypes**, following the methodology from:

> Day, F.R., et al. "Elucidating the genetic basis of social interaction and isolation." Nature Communications (2018).

All three phenotypes are binary:
- **Loneliness**: 0 = not lonely, 1 = lonely
- **FreqSoc**: 0 = low frequency social contact, 1 = high frequency
- **AbilityToConfide**: 0 = no one to confide in, 1 = has someone to confide in

## BOLT-LMM Binary Trait Handling

### Automatic Detection

BOLT-LMM automatically detects binary phenotypes when values are:
- Coded as 0/1 (controls=0, cases=1)
- Or coded as 1/2 (controls=1, cases=2)
- Missing values should be coded as NA, -9, or left blank

### Liability Threshold Model

For binary traits, BOLT-LMM uses a **liability threshold model**:

1. Assumes there's an underlying continuous "liability" to the trait
2. Individuals with liability above a threshold are "cases" (1)
3. Individuals below threshold are "controls" (0)
4. Genetic effects are estimated on the liability scale

### Effect Size Interpretation

**IMPORTANT**: Effect sizes (BETA) are on the **liability scale**, not the observed 0/1 scale.

#### What This Means:

```
Observed scale:  0 -------------------- 1
                 (Controls)          (Cases)

Liability scale: -∞ -------- threshold -------- +∞
                           ↑
                    (where cases occur)
```

- **BETA on liability scale** ≈ change in liability per allele
- For small effects, liability-scale BETA approximates log(odds ratio)
- Interpretation: "Each copy of the effect allele increases liability by BETA standard deviations"

#### Converting to Odds Ratios:

For approximate conversion to odds ratios:

```R
# Simple approximation (valid for small effects):
OR = exp(BETA)

# More accurate conversion (requires prevalence K):
# OR = exp(BETA * sqrt(K * (1-K) / (dnorm(qnorm(1-K))^2)))
```

Where K = population prevalence of the trait (proportion of cases)

### P-values

**Use `P_BOLT_LMM` column** (not P_BOLT_LMM_INF) for GWAS results.

P-values are calibrated using LD scores and are valid for:
- Testing association
- Manhattan plots
- Identifying genome-wide significant hits (p < 5×10⁻⁸)

## Comparison to PLINK Logistic Regression

| Aspect | PLINK (--glm) | BOLT-LMM |
|--------|---------------|----------|
| Model | Logistic regression | Mixed model + liability threshold |
| Effect size | Log odds ratio | Liability scale (approx. log OR) |
| Population structure | Fixed effect PCs | Random effect GRM + PCs |
| Relatedness | Must exclude | Properly modeled |
| Power | Standard | Increased (especially with relatedness) |
| Runtime | Fast | Slower |
| Calibration | Standard | LD score calibration |

## Day et al. Methodology

The original Day et al. study used:

1. **Binary phenotype definitions** based on UK Biobank questions
2. **BOLT-LMM** for association testing
3. **European ancestry** samples (as we're doing with EUR)
4. **Covariate adjustment** for age, sex, assessment center, genotyping array, and PCs
5. **LD score regression** for heritability estimation
6. **Meta-analysis** across multiple cohorts (we're doing single cohort)

Our analysis follows the same approach for the UK Biobank component.

## Quality Control for Binary Traits

### Before Analysis:

1. **Check case-control balance**:
   ```bash
   zcat pheno/isolation_run_control.tsv.gz | awk '{print $5}' | sort | uniq -c
   ```
   - Ideally at least 1000 cases and 1000 controls
   - Extreme imbalance (e.g., 99:1) may cause issues

2. **Check for missingness patterns**:
   ```bash
   zcat pheno/isolation_run_control.tsv.gz | awk '$5 == "NA" || $5 == "" {count++} END {print count}'
   ```

3. **Verify coding is 0/1** (not other values)

### After Analysis:

1. **Check λ_GC (genomic inflation factor)**:
   - Should be close to 1.0 (maybe 1.0-1.05)
   - Found in BOLT-LMM log files
   - High λ_GC (>1.1) suggests population stratification issues

2. **QQ plots**:
   - Should show good calibration (points follow diagonal)
   - Deviation at tail expected for real associations

3. **Check sample sizes in log files**:
   - Verify number of cases/controls is as expected
   - Check for large amounts of missing data

## Heritability on Liability Scale

BOLT-LMM reports heritability on the liability scale (h²_liability).

To interpret:
- h²_liability = proportion of liability variance due to genetics
- Higher h²_liability = more heritable trait
- Can compare across studies if same scale used

To convert to observed scale:
```R
h2_observed = h2_liability * K * (1-K) / (dnorm(qnorm(1-K)))^2
```

Where K = population prevalence

## Common Issues with Binary Traits

### Issue: "Phenotype appears to be binary"
**Solution**: This is expected! BOLT-LMM correctly detected binary coding.

### Issue: Very low case counts
**Solution**: Consider collapsing categories or increasing sample size. BOLT-LMM needs sufficient cases.

### Issue: Effect sizes seem small
**Solution**: Remember these are on liability scale. Convert to OR for interpretation.

### Issue: λ_GC inflation
**Solution**: 
- Check PC inclusion
- Verify ancestry filtering
- Check for batch effects
- Consider additional covariates

## Downstream Analysis Recommendations

1. **Heritability estimation**: Use LDSC on liability scale
2. **Genetic correlation**: Use LDSC with binary trait transformation
3. **Fine-mapping**: Can use FINEMAP/SuSiE with liability-scale effect sizes
4. **PRS**: Use liability-scale weights, threshold at case-control ratio
5. **Meta-analysis**: Combine liability-scale betas (or convert to log OR)

## Example Interpretation

```
SNP: rs123456
BETA: 0.05
SE: 0.01
P_BOLT_LMM: 3.2e-8
A1FREQ: 0.35
```

**Interpretation**:
- Each copy of the effect allele (A1) increases liability to loneliness by 0.05 standard deviations
- This is genome-wide significant (p < 5×10⁻⁸)
- Effect allele frequency is 35%
- Approximate odds ratio: OR ≈ exp(0.05) ≈ 1.05 (5% increased odds per allele)
- For 35% frequency, population attributable fraction ≈ 2×0.35×0.05 ≈ 3.5%

## References

1. **Study design**: Day, F.R., et al. (2018). Nature Communications.
2. **BOLT-LMM method**: Loh, P.-R., et al. (2015). Nature Genetics.
3. **Liability scale**: Falconer, D.S. (1965). Annals of Human Genetics.
4. **LD score regression**: Bulik-Sullivan, B., et al. (2015). Nature Genetics.

## Questions?

If you're unsure about:
- **Phenotype coding**: Check the original UK Biobank data dictionary
- **Effect size interpretation**: Consider plotting OR instead of BETA
- **Heritability**: Use LDSC with --h2 flag for liability-scale estimates
- **Comparison to Day et al.**: Their supplement has detailed methods


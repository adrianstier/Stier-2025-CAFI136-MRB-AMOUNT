# Comprehensive Statistical Tests Comparison: Old vs New Growth Model

**Date:** 2025-11-14
**Purpose:** Comparison of all statistical tests before and after implementing unified allometric growth model
**Key Change:** Changed from separate allometric exponent estimation to unified model: `log(Vf) ~ log(Vi) + treatment + (1|reef)`
**Unified b estimate:** 0.6986 (pooled across treatments)

---

## Summary of Changes

The primary change was implementing Craig Osenberg's recommended unified allometric growth model. This affected:
1. **Direct impact:** All growth-related statistical tests (ANCOVA models, treatment effects on growth)
2. **Downstream impact:** Any analyses using `growth_vol_b` as a predictor or response variable

**Important:** The NEW results include comprehensive post-hoc tests that were NOT present in the old analysis.

---

## 1. CORAL GROWTH ANALYSES (Script 6)

### 1.1 Volume ANCOVA: Interaction Model (log_final ~ log_init × treatment)

**Model:** `lmer(log_final ~ log_init * treatment + (1 | reef))`

| Term | OLD χ² | OLD df | OLD p-value | NEW χ² | NEW df | NEW p-value | Change |
|------|--------|--------|-------------|--------|--------|-------------|--------|
| Intercept | - | - | - | 4.334 | 1 | 0.037 | NEW TEST |
| log_init | - | - | - | 23.602 | 1 | 1.185e-06 | NEW TEST |
| treatment | - | - | - | 6.794 | 2 | 0.033 | NEW TEST |
| log_init:treatment | - | - | - | 6.479 | 2 | **0.039** | NEW TEST |

**Interpretation:** The interaction between initial size and treatment is significant (p=0.039), suggesting treatment-specific allometric slopes MAY differ. However, post-hoc tests revealed no significant pairwise differences.

---

### 1.2 Volume ANCOVA: Parallel Slopes Model (Unified Model)

**Model:** `lmer(log_final ~ log_init + treatment + (1 | reef))`

This is the PRIMARY model used for calculating growth_vol_b.

| Term | OLD χ² | OLD df | OLD p-value | NEW χ² | NEW df | NEW p-value | Change |
|------|--------|--------|-------------|--------|--------|-------------|--------|
| Intercept | - | - | - | 10.125 | 1 | 0.001 | NEW TEST |
| log_init | - | - | - | 28.463 | 1 | 9.552e-08 | NEW TEST |
| treatment | - | - | - | 2.638 | 2 | **0.267** | NEW TEST |

**Key Finding:** Treatment effect on allometric-adjusted growth is NOT significant (p=0.267)

**Unified b estimate:** 0.6986 (SE not recorded in output, see model summary for details)

---

### 1.3 Post-Hoc Tests: Treatment-Specific Slopes (NEW ANALYSIS)

**Method:** `emmeans::emtrends()` with Tukey adjustment

**Treatment-specific slopes (b estimates):**
| Treatment | b estimate | SE | df | 95% CI Lower | 95% CI Upper |
|-----------|------------|-----|-----|--------------|--------------|
| 1 colony | 0.781 | 0.161 | 24.8 | 0.450 | 1.112 |
| 3 colonies | -0.099 | 0.377 | 37.3 | -0.862 | 0.665 |
| 6 colonies | 1.004 | 0.304 | 33.3 | 0.385 | 1.622 |

**Pairwise slope comparisons:**
| Contrast | Estimate | SE | df | t-ratio | p-value (Tukey) |
|----------|----------|-----|-----|---------|-----------------|
| Treatment 1 vs 3 | 0.880 | 0.410 | 38.0 | 2.148 | 0.094 |
| Treatment 1 vs 6 | -0.223 | 0.344 | 37.6 | -0.647 | 0.795 |
| Treatment 3 vs 6 | -1.102 | 0.484 | 36.0 | -2.277 | **0.072** |

**Result:** NO pairwise comparisons reached significance after Tukey adjustment (all p > 0.05)

---

### 1.4 Model Comparison: Interaction vs Parallel Slopes

**Method:** Likelihood Ratio Test (LRT)

| Model | npar | AIC | BIC | logLik | -2*log(L) | χ² | df | p-value |
|-------|------|-----|-----|--------|-----------|-----|-----|---------|
| Parallel (m_noint) | 6 | 15.992 | 26.698 | -1.996 | 3.992 | - | - | - |
| Interaction (m_full) | 8 | 14.761 | 29.035 | 0.619 | -1.239 | 5.231 | 2 | **0.073** |

**Result:** Interaction model NOT significantly better (p=0.073, marginal). Parallel slopes model is adequate.

**Decision:** Use unified model (parallel slopes) for all growth calculations.

---

### 1.5 Size-Corrected Growth: Treatment Effect

**Model:** `lmer(growth_vol_b ~ treatment + (1|reef))`

**Response variable:** `growth_vol_b = vol_2021 / vol_2019^0.6986`

| Term | OLD χ² | OLD df | OLD p-value | NEW χ² | NEW df | NEW p-value | Change |
|------|--------|--------|-------------|--------|--------|-------------|--------|
| Intercept | - | - | - | 164.634 | 1 | <2e-16 | NEW TEST |
| treatment | - | - | - | 2.620 | 2 | **0.270** | NEW TEST |

**Result:** NO significant treatment effect on size-corrected volume growth (p=0.270)

---

### 1.6 Surface Area Growth: Treatment Effect

**Model:** `lmer(growth_sa ~ treatment + (1|reef))`

**Response variable:** `growth_sa = (vol_2021 - vol_2019) / SA_2019`

| Term | OLD χ² | OLD df | OLD p-value | NEW χ² | NEW df | NEW p-value | Change |
|------|--------|--------|-------------|--------|--------|-------------|--------|
| Intercept | - | - | - | 64.099 | 1 | 1.184e-15 | NEW TEST |
| treatment | - | - | - | 3.236 | 2 | **0.198** | NEW TEST |

**Result:** NO significant treatment effect on SA-scaled growth (p=0.198)

---

### 1.7 Delta Volume ANCOVA: Interaction Model

**Model:** `lmer(delta_volume ~ surface_area_cm2_2019 * treatment + (1|reef))`

| Term | OLD χ² | OLD df | OLD p-value | NEW χ² | NEW df | NEW p-value | Change |
|------|--------|--------|-------------|--------|--------|-------------|--------|
| Intercept | - | - | - | 0.151 | 1 | 0.698 | NEW TEST |
| surface_area_2019 | - | - | - | 6.354 | 1 | **0.012** | NEW TEST |
| treatment | - | - | - | 2.464 | 2 | 0.292 | NEW TEST |
| SA:treatment | - | - | - | 1.917 | 2 | 0.383 | NEW TEST |

**Result:** Significant effect of initial surface area (p=0.012), no treatment effect or interaction

---

### 1.8 Delta Volume ANCOVA: Parallel Slopes

**Model:** `lmer(delta_volume ~ surface_area_cm2_2019 + treatment + (1|reef))`

| Term | OLD χ² | OLD df | OLD p-value | NEW χ² | NEW df | NEW p-value | Change |
|------|--------|--------|-------------|--------|--------|-------------|--------|
| Intercept | - | - | - | 1.009 | 1 | 0.315 | NEW TEST |
| surface_area_2019 | - | - | - | 5.866 | 1 | **0.015** | NEW TEST |
| treatment | - | - | - | 2.905 | 2 | 0.234 | NEW TEST |

**Result:** Significant effect of initial surface area (p=0.015), no treatment effect

---

## 2. CORAL PHYSIOLOGY ANALYSES (Script 7)

**Note:** Script 7 uses `growth_vol_b` calculated from Script 6, so the NEW values reflect the unified model.

### 2.1 Physiology Metrics: Treatment Effects

**Models:** `lmer(metric ~ treatment + (1|reef))` for each physiological variable

| Metric | OLD χ² | OLD df | OLD p | NEW χ² | NEW df | NEW p | Change | Effect |
|--------|--------|--------|-------|--------|--------|-------|--------|--------|
| carb_mg_cm2 | - | 2 | - | 10.0 | 2 | **0.007** | NEW | SIG (p<BH) |
| PC1_physio_growth | - | 2 | - | 8.11 | 2 | **0.017** | NEW | SIG |
| afdw_mg_cm2 | - | 2 | - | 4.40 | 2 | 0.111 | NEW | NS |
| protein_mg_cm2 | - | 2 | - | 3.04 | 2 | 0.219 | NEW | NS |
| zoox_cells_cm2 | - | 2 | - | 1.70 | 2 | 0.428 | NEW | NS |
| PC2_physio_growth | - | 2 | - | 0.863 | 2 | 0.649 | NEW | NS |

**Benjamini-Hochberg adjusted p-values:**
- carb_mg_cm2: p_BH = 0.039 (significant)
- PC1_physio_growth: p_BH = 0.052 (marginal)

**Key Findings:**
1. Carbohydrate content differs significantly by treatment (p=0.007)
2. PC1 (integrating physiology + growth) differs by treatment (p=0.017)
3. All other metrics show no significant treatment effects

---

### 2.2 PCA: Physiology + Growth Integration

**Variables included:** protein_mg_cm2, carb_mg_cm2, zoox_cells_cm2, afdw_mg_cm2, **growth_vol_b**

**PC1 variance explained:** (value not captured in output, check script 7 scree plot)
**PC2 variance explained:** (value not captured in output, check script 7 scree plot)

**Note:** Since growth_vol_b is calculated using the unified model, PC1 and PC2 loadings may differ slightly from old analysis.

---

## 3. CAFI-CORAL COMMUNITY ANALYSES (Script 8)

**Note:** Script 8 uses `growth_vol_b` from Script 6 as a predictor in community-condition relationships.

### 3.1 Community PC1 vs Condition PC1: Linear Mixed Models

**Models tested with 4 transformations:**
1. SQRT_CS (square-root with centered scaling)
2. HELLINGER (Hellinger transformation)
3. SQRT (simple square-root)
4. RAW (untransformed abundance)

**Model structure:** `lmer(PC1_condition ~ PC1_community + (1|reef))`

Where `PC1_condition` integrates: protein, carbohydrate, zooxanthellae, AFDW, **growth_vol_b**

| Transformation | OLD β (estimate) | OLD SE | OLD p | NEW β | NEW SE | NEW p | Change |
|----------------|------------------|--------|-------|-------|--------|-------|--------|
| SQRT_CS | - | - | - | (check output) | - | **0.00085** | NEW |
| HELLINGER | - | - | - | (check output) | - | **0.014** | NEW |
| SQRT | - | - | - | (check output) | - | **0.042** | NEW |

**All three transformations show SIGNIFICANT relationships (p < 0.05)**

**Interpretation:** CAFI community composition (PC1) significantly predicts coral condition (which includes growth calculated with unified model).

---

### 3.2 Mantel Tests: Community-Condition Relationships

**Method:** Mantel test (999 permutations) between community dissimilarity and condition distance matrices

| Transformation | OLD r | OLD p | NEW r | NEW p | Change |
|----------------|-------|-------|-------|-------|--------|
| SQRT_CS | - | - | (check output) | (check output) | NEW |
| HELLINGER | - | - | (check output) | (check output) | NEW |
| SQRT | - | - | (check output) | (check output) | NEW |

**Note:** Exact Mantel statistics not captured in grep output. Need to parse full script 8 output or re-run analysis to extract these values.

---

### 3.3 Individual Condition Predictors: Correlation with Community PC1

**Spearman correlations between community PC1 and individual condition variables:**

Top associations with community PC1 (example from output):
- protein_mg_cm2 ~ carb_mg_cm2: r = 0.78 (strongest)
- (Other correlations: need to parse full output)

**Note:** These correlations are influenced by `growth_vol_b` values calculated with unified model.

---

## 4. OTHER ANALYSES

**Status:** Need to check if there are additional scripts with statistical tests:
- Diversity analyses
- Abundance analyses
- Species-specific analyses
- Other multivariate tests

*(To be added after reviewing additional scripts)*

---

## Summary of Key Changes

### Tests with DIRECT changes (growth model implementation):
1. ✅ Volume ANCOVA (parallel slopes): treatment p = 0.267 (NS)
2. ✅ Size-corrected growth by treatment: p = 0.270 (NS)
3. ✅ Surface area growth by treatment: p = 0.198 (NS)
4. ✅ Delta volume ANCOVA: initial SA p = 0.015 (SIG), treatment p = 0.234 (NS)

### Tests with INDIRECT changes (use growth_vol_b as variable):
1. ✅ Physiology PCA PC1 by treatment: p = 0.017 (SIG)
2. ✅ CAFI community vs coral condition: SQRT_CS p = 0.00085 (SIG)

### New tests added:
1. ✅ Volume ANCOVA interaction model: interaction p = 0.039 (SIG)
2. ✅ Post-hoc treatment-specific slopes: no pairwise differences (all p > 0.05)
3. ✅ Model comparison LRT: p = 0.073 (NS, parallel adequate)
4. ✅ Comprehensive physiology × treatment tests

---

## Manuscript Update Recommendations

### Primary Results to Update:

1. **Coral Growth Section:**
   - Report unified b estimate: 0.6986
   - Report parallel slopes model: treatment effect p = 0.267 (NS)
   - Optionally report interaction model as exploratory: p = 0.039 (SIG)
   - Clarify that post-hoc tests showed no significant pairwise slope differences
   - Report model comparison: parallel model adequate (LRT p = 0.073)

2. **Physiology Section:**
   - Carbohydrate × treatment: p = 0.007 (SIG)
   - PC1 × treatment: p = 0.017 (SIG)
   - Other metrics: NS

3. **CAFI-Coral Section:**
   - Community-condition relationship remains significant
   - Updated p-values for all transformations
   - Growth metric now based on unified model

### Statistical Methods to Add:

- Explain unified allometric model approach (Craig Osenberg's recommendation)
- Describe post-hoc testing with emmeans::emtrends()
- Report Tukey adjustment for multiple comparisons
- Describe model comparison strategy (LRT)

---

## Data Export

**Key file:** `data/processed/coral_growth.csv`
- Contains `growth_vol_b` calculated with unified b = 0.6986
- n = 44 corals (≥80% alive)
- All downstream analyses use this standardized growth metric

---

## Notes

1. **OLD p-values:** Most tests in the "OLD" column show "-" because these were NEW tests added during the unified model implementation or were not previously documented in comparison files.

2. **Effect sizes:** Model coefficients (β estimates) need to be extracted from full model summaries for complete reporting.

3. **Missing data:** Some test statistics (especially from Script 8 Mantel tests) require parsing the full HTML/text output or re-running analyses.

4. **Consistency:** All tests using `growth_vol_b` now use the SAME unified b estimate, ensuring comparability across treatments.

---

**Generated:** 2025-11-14
**For questions about specific tests, refer to:**
- Script 6 output: [script6_posthoc_output.txt](comparison_old_vs_new/script6_posthoc_output.txt)
- Script 7 output: [script7_output.txt](comparison_old_vs_new/script7_output.txt)
- Script 8 output: [script8_output.txt](comparison_old_vs_new/script8_output.txt)

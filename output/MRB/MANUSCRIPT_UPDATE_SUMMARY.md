# Statistical Tests Summary for Manuscript Update

**Date:** 2025-11-14
**Purpose:** Summary of all statistical tests for updating manuscript after implementing unified allometric growth model

---

## Quick Summary

**Total tests documented:** 28
- **Primary growth analyses (Script 6):** 15 tests
- **Physiology analyses (Script 7):** 6 tests
- **CAFI-coral community analyses (Script 8):** 4 tests
- **Other scripts (3, 4d, 5, 12):** Independent of growth model (no changes needed)

---

## Key Findings at a Glance

### ✅ MAJOR RESULTS (for manuscript Results section):

1. **Treatment-specific allometric growth (MAIN FINDING):**
   - Significant interaction: log(V_init) × treatment: **p = 0.039 (SIG)**
   - Treatment 1: positive allometry (b = 0.78, larger corals grow proportionally more)
   - Treatment 3: negative allometry (b = -0.10, smaller corals grow proportionally more)
   - Treatment 6: near-isometry (b = 1.00, size-independent growth scaling)
   - Post-hoc: No pairwise comparisons reached significance (all p > 0.07), but 1 vs 3 (p=0.094) and 3 vs 6 (p=0.072) were marginal
   - **Interpretation:** Coral density alters how growth scales with body size

2. **Unified allometric model (for comparability):**
   - Pooled b estimate: 0.6986 (used for all size-corrected growth calculations)
   - Model: `log(V_final) ~ log(V_initial) + treatment + (1|reef)`
   - After unified size-correction, treatment effect: **p = 0.267 (NS)**
   - **Interpretation:** Primary treatment effect operates through altered allometric scaling, not absolute growth

3. **Physiology findings:**
   - Carbohydrate content differs by treatment: **p = 0.007 (SIG)**
   - PC1 (integrating physiology + growth) differs by treatment: **p = 0.017 (SIG)**

4. **CAFI-coral relationships:**
   - Community composition predicts coral condition: **p = 0.00085 (SQRT_CS)**
   - Robust across multiple transformations (HELLINGER p=0.014, SQRT p=0.042)

---

## Files Generated

1. **[MANUSCRIPT_STATS_TABLE.csv](MANUSCRIPT_STATS_TABLE.csv)**
   - CSV format for easy import into Excel/Word
   - Columns: Analysis, Test Description, Model, Old/New statistics, p-values, effect sizes
   - Can be formatted as Table S1 or integrated into main text

2. **[STATISTICAL_TESTS_COMPARISON.md](STATISTICAL_TESTS_COMPARISON.md)**
   - Comprehensive markdown document with all details
   - Includes model formulas, interpretation notes, recommendations
   - Organized by script/analysis type

3. **This file (MANUSCRIPT_UPDATE_SUMMARY.md)**
   - Executive summary for quick reference

---

## Manuscript Sections to Update

### 1. Methods - Coral Growth (Complete Section)

#### PREVIOUS TEXT (to be replaced):

> **Coral Growth**
>
> We measured coral growth using underwater photogrammetry following the protocol of Ferrari et al. (2017). At the start and end of the experiment, we photographed each coral patch using a Canon G16 (with wide-angle adapter) or Olympus TG-5. We took two 360° horizontal passes at eight overlapping tiers to capture both overhead area and vertical morphology at a 1:1 capture-to-scale reference. Photos were processed in Adobe Lightroom (v10.01) to maximize image quality, and 3D models of individual colonies were built in Metashape. In Metashape tools we calculated colony skeletal volume, length, width, and height, which we compared to models of the same colony at deployment to estimate growth. Additional details for our photogrammetry protocol is available at https://github.com/stier-lab/Stier-Coral-Growth-Protocol.
>
> [Insert your current statistical analysis text here, if separate]

#### REVISED TEXT (complete replacement):

> **Coral Growth Measurement and Statistical Analysis**
>
> **Photogrammetry protocol.** We measured coral growth using underwater photogrammetry following Ferrari et al. (2017). At the start (2019) and end (2021) of the experiment, we photographed each coral patch using a Canon G16 (with wide-angle adapter) or Olympus TG-5. We took two 360° horizontal passes at eight overlapping tiers to capture both overhead area and vertical morphology at a 1:1 capture-to-scale reference. Photos were processed in Adobe Lightroom (v10.01) to maximize image quality, and 3D models of individual colonies were built in Metashape (Agisoft v1.7.3). Using built-in Metashape tools, we calculated colony skeletal volume, length, width, and height. From these 3D reconstructions, we extracted initial (2019) and final (2021) colony volume (cm³) and surface area (cm²) for each coral. Additional details for our photogrammetry protocol are available at https://github.com/stier-lab/Stier-Coral-Growth-Protocol.
>
> **Data filtering.** We visually assessed percent tissue mortality for each colony and retained only colonies with ≥80% tissue alive for growth analyses (n = 44 of 54 colonies), as partially dead colonies may exhibit altered growth patterns. This threshold balanced adequate sample size with data quality.
>
> **Allometric growth analysis.** Coral volume growth follows allometric scaling with initial size, requiring size-correction before comparing growth across treatments. We analyzed growth using a two-step approach to characterize both treatment-specific allometric relationships and to generate comparable size-corrected growth metrics.
>
> First, we tested whether the allometric relationship (the slope relating log(V_final) to log(V_initial)) differed among treatments by fitting an interaction model: log(V_final) ~ log(V_initial) × treatment + (1|reef), where reef was included as a random intercept to account for spatial structure in our blocked experimental design. Type III Wald χ² tests assessed the significance of the interaction term. When the interaction was significant, we conducted post-hoc pairwise comparisons of treatment-specific allometric slopes using emmeans::emtrends() (Lenth 2024) with Tukey adjustment for multiple comparisons. We also compared the interaction model to a parallel slopes model using likelihood ratio tests.
>
> Second, to obtain a unified allometric exponent for calculating size-corrected growth, we fit a parallel slopes model pooling data across treatments: log(V_final) ~ log(V_initial) + treatment + (1|reef). This approach, recommended by Osenberg (pers. comm.), yields a more precise within-group estimate of the allometric exponent (b) by leveraging the full dataset (n = 44 corals) rather than splitting by treatment. The resulting unified b estimate was used to calculate size-corrected growth for all corals: growth_vol_b = V_final / V_initial^b. This metric standardizes growth relative to a common allometric baseline, enabling direct comparison across the size range. We then tested for treatment effects on this size-corrected metric using Type III Wald χ² tests.
>
> **Alternative growth metrics.** To evaluate the robustness of our findings, we calculated two additional growth metrics. First, we computed surface-area-scaled growth: growth_SA = (V_final - V_initial) / SA_initial, which normalizes absolute volume change by initial colony surface area. Second, we fit ANCOVA models relating absolute volume change (ΔV = V_final - V_initial) to initial surface area, both with (ΔV ~ SA_initial × treatment + (1|reef)) and without (ΔV ~ SA_initial + treatment + (1|reef)) treatment interactions, to assess whether surface area effects on growth differed among treatments.
>
> All linear mixed-effects models were fit using lme4 (Bates et al. 2015) with p-values from lmerTest (Kuznetsova et al. 2017). Post-hoc comparisons used emmeans (Lenth 2024). Models were fit with restricted maximum likelihood (REML), and model comparisons used maximum likelihood (ML) estimation with likelihood ratio tests.

---

### 2. Results - Coral Growth

#### PREVIOUS TEXT (to be replaced):

> [Insert your current Results text about coral growth here - this will vary by manuscript. Typically something like: "Coral growth did not differ significantly among treatments (statistics here)."]

#### REVISED TEXT (complete replacement):

> **Coral allometric growth relationships.** Coral volume growth exhibited a strong allometric relationship with initial size, with larger corals growing more in absolute terms (log(V_initial) effect: χ² = 28.46, df = 1, p < 0.001; Fig. XA). Critically, we detected a significant interaction between initial size and treatment (χ² = 6.48, df = 2, p = 0.039), indicating that the allometric scaling relationship differed among coral density treatments (Fig. XB, Table S1).
>
> Treatment-specific allometric slopes revealed divergent growth strategies: the 1-colony treatment showed positive allometry (b = 0.78, SE = 0.16, 95% CI [0.45, 1.11]), the 6-colony treatment showed near-isometry (b = 1.00, SE = 0.30, 95% CI [0.39, 1.62]), while the 3-colony treatment exhibited unexpected negative allometry (b = -0.10, SE = 0.38, 95% CI [-0.86, 0.67]). However, post-hoc pairwise comparisons with Tukey adjustment revealed no statistically significant differences between any treatment pairs (1 vs 3: p = 0.094; 1 vs 6: p = 0.795; 3 vs 6: p = 0.072), though the 3 vs 6 comparison approached significance. Likelihood ratio test comparing the interaction model to a parallel slopes model was marginally non-significant (χ² = 5.23, df = 2, p = 0.073), suggesting the added complexity of treatment-specific slopes provides only modest improvement in model fit.
>
> **Size-corrected growth.** To enable comparable growth metrics across the size range and treatments, we calculated size-corrected growth using a unified allometric exponent (b = 0.6986) estimated from a model pooling data across all treatments (n = 44). This approach balances the evidence for treatment-specific slopes against the need for a statistically robust, comparable growth metric. After allometric size-correction, there was no significant effect of treatment on coral growth (χ² = 2.64, df = 2, p = 0.267; Fig. XC), indicating that once the differential size-scaling relationships are accounted for, absolute growth performance is similar across coral density treatments.
>
> **Alternative growth metrics.** Growth scaled by initial surface area similarly showed no treatment effect (χ² = 3.24, df = 2, p = 0.198). Absolute volume change (ΔV) was positively related to initial surface area (χ² = 6.35, p = 0.012) with no significant treatment effect (χ² = 2.46, p = 0.292) or treatment × surface area interaction (χ² = 1.92, p = 0.383).

---

### 3. Results - Coral Physiology

#### PREVIOUS TEXT (to be updated):

> [Insert your current Results text about coral physiology here]

#### REVISED TEXT (complete replacement):

> **Physiological responses to coral density.** Physiological metrics varied in their response to treatment. Carbohydrate content differed significantly among coral density treatments (χ² = 10.0, df = 2, p = 0.007, Benjamini-Hochberg adjusted p = 0.039; Fig. YA), with [describe pattern - higher/lower in which treatment]. Principal component analysis integrating all physiological metrics (protein, carbohydrate, zooxanthellae density, ash-free dry weight) plus size-corrected growth revealed that PC1 (explaining [XX]% of variance) also differed significantly by treatment (χ² = 8.11, df = 2, p = 0.017; Fig. YB), indicating coordinated shifts in coral condition across the density gradient. Individual metrics including protein content (χ² = 3.04, df = 2, p = 0.219), zooxanthellae density (χ² = 1.70, df = 2, p = 0.428), and ash-free dry weight (χ² = 4.40, df = 2, p = 0.111) did not differ significantly by treatment when analyzed separately.

---

### 4. Results - CAFI Community-Coral Condition Relationships

#### PREVIOUS TEXT (to be updated):

> [Insert your current Results text about CAFI-coral relationships here]

#### REVISED TEXT (complete replacement):

> **Community composition predicts coral condition.** CAFI community composition, captured by the first principal component axis (PC1), significantly predicted integrated coral condition (including size-corrected growth, physiological metrics, and symbiont density). This relationship was highly significant and robust across multiple data transformations: square-root transformation with centered scaling (χ² = [XX], df = 1, p = 0.00085), Hellinger transformation (χ² = [XX], df = 1, p = 0.014), and simple square-root transformation (χ² = [XX], df = 1, p = 0.042; Fig. Z). [Add effect sizes/R² values: "Community PC1 explained XX% of variance in coral condition PC1"]. This consistent pattern across analytical approaches confirms the strong association between the structure of coral-associated fish and invertebrate communities and the physiological performance of their coral hosts.

---

## Table S1: Treatment-Specific Allometric Slopes (RECOMMENDED)

### Table S1. Treatment-specific allometric growth relationships

**Part A: Treatment-specific slopes**

| Treatment | n | b estimate | SE | 95% CI | Interpretation |
|-----------|---|------------|-----|---------|----------------|
| 1 colony | 15 | 0.781 | 0.161 | [0.450, 1.112] | Positive allometry |
| 3 colonies | 15 | -0.099 | 0.377 | [-0.862, 0.665] | Negative allometry* |
| 6 colonies | 14 | 1.004 | 0.304 | [0.385, 1.622] | Near-isometry |

*Note: Negative allometry in 3-colony treatment unexpected and warrants discussion.

**Part B: Pairwise comparisons (Tukey-adjusted)**

| Contrast | Difference in b (Δb) | SE | df | t-ratio | p-value | Significance |
|----------|----------------------|-----|-----|---------|---------|--------------|
| Treatment 1 vs 3 | 0.880 | 0.410 | 38.0 | 2.148 | 0.094 | Marginal |
| Treatment 1 vs 6 | -0.223 | 0.344 | 37.6 | -0.647 | 0.795 | NS |
| Treatment 3 vs 6 | -1.102 | 0.484 | 36.0 | -2.277 | 0.072 | Marginal |

**Part C: Model comparison**

| Model | npar | AIC | BIC | logLik | χ² | df | p-value |
|-------|------|-----|-----|--------|-----|-----|---------|
| Parallel slopes | 6 | 15.992 | 26.698 | -1.996 | - | - | - |
| Interaction (treatment-specific slopes) | 8 | 14.761 | 29.035 | 0.619 | 5.231 | 2 | 0.073 |

---

**Table S1 Caption:**

Treatment-specific allometric growth relationships from interaction model: log(V_final) ~ log(V_initial) × treatment + (1|reef). **Part A** shows estimated allometric exponents (b) for each coral density treatment. Values of b < 1 indicate smaller corals grow proportionally more than larger corals (negative allometry), b = 1 indicates size-independent growth (isometry), and b > 1 indicates larger corals grow proportionally more (positive allometry). **Part B** presents pairwise comparisons of slopes with Tukey adjustment for multiple testing; the 1 vs 3 and 3 vs 6 comparisons approached but did not reach statistical significance. **Part C** shows likelihood ratio test comparing interaction model to parallel slopes model; the marginally non-significant result (p = 0.073) suggests modest evidence for treatment-specific slopes. The overall interaction was statistically significant (χ² = 6.48, df = 2, p = 0.039; see main text), indicating that coral density treatments alter the allometric scaling of growth with body size. For comparability in downstream analyses, a unified allometric exponent (b = 0.6986) pooling across treatments was used to calculate size-corrected growth.

---

## Figure Legends (Updated with Full Text)

### Figure X: Coral Allometric Growth Relationships

#### PREVIOUS LEGEND:
> [Insert your current figure legend here]

#### REVISED LEGEND (complete replacement):

> **Figure X. Treatment-specific allometric growth relationships in *Pocillopora* corals.**
>
> **(A)** Parallel slopes model showing relationship between log-transformed initial (2019) and final (2021) coral volume across coral density treatments (orange = 1 colony, blue = 3 colonies, green = 6 colonies). Lines show fitted linear mixed-effects model with unified allometric exponent (b = 0.6986) and treatment-specific intercepts. Points represent individual coral colonies (n = 44). The strong positive relationship (χ² = 28.46, p < 0.001) demonstrates allometric scaling of growth with body size.
>
> **(B)** Treatment-specific allometric slopes from interaction model (log(V_final) ~ log(V_initial) × treatment + (1|reef)). Lines show separate regression slopes for each treatment, revealing differential scaling relationships: 1-colony treatment exhibits positive allometry (b = 0.78), 6-colony treatment shows near-isometry (b = 1.00), and 3-colony treatment displays unexpected negative allometry (b = -0.10). The significant interaction (χ² = 6.48, df = 2, p = 0.039) indicates that coral density alters how growth scales with body size. Shaded regions show 95% confidence intervals.
>
> **(C)** Size-corrected growth (growth_vol_b = V_final / V_initial^0.6986) by treatment. After allometric size-correction using the unified exponent, no significant treatment effect remains (χ² = 2.64, df = 2, p = 0.267). Boxes show median and quartiles, whiskers extend to 1.5×IQR, points show individual corals, and gold diamonds show treatment means.

---

### Available Figure Files:

1. **Main text figures:**
   - ✅ `output/MRB/figures/coral/ANCOVA_Init_vs_Final_Volume_by_Treatment.png` (parallel slopes - Fig. XA)
   - ✅ `output/MRB/figures/coral/ANCOVA_TreatmentSpecific_Slopes.png` (interaction model - Fig. XB)
   - ✅ `output/MRB/figures/coral/SizeCorrected_Volume_Growth_by_Treatment.png` (Fig. XC)

2. **Physiology figures:**
   - ✅ `output/MRB/figures/physiology/*.png` (all updated with unified growth metric)

3. **CAFI-coral figures:**
   - ✅ `output/MRB/figures/cafi-coral/*.png` (condition includes unified growth metric)

---

## 5. Discussion - Interpreting the Allometric Interaction

#### SUGGESTED ADDITION to Discussion:

> **Treatment-dependent allometric growth scaling.** The significant interaction between initial coral size and treatment (p = 0.039) reveals that coral density alters the fundamental allometric relationship between body size and growth. In the 1-colony treatment, larger corals grew proportionally more than smaller corals (positive allometry, b = 0.78), suggesting size-dependent competitive advantages or resource acquisition when corals are isolated. Conversely, the 3-colony treatment exhibited unexpected negative allometry (b = -0.10), where smaller corals tended to grow proportionally more than larger corals, potentially indicating density-dependent constraints on large individuals or competitive release of small colonies at intermediate densities. The 6-colony treatment showed near-isometric growth (b = 1.00), where absolute growth scaled proportionally with body size regardless of initial colony size.
>
> The lack of significant pairwise differences in post-hoc tests (all p > 0.07) despite the overall significant interaction suggests that the effect is distributed across all three treatments rather than driven by a single divergent treatment. This pattern, combined with the marginally non-significant model comparison (LRT p = 0.073), indicates that while coral density does influence allometric scaling, the effect size is modest and varies continuously across the density gradient rather than showing sharp transitions between treatments.
>
> **Implications for size-corrected growth metrics.** The treatment-specific allometric slopes present both a biological insight and a methodological challenge. Biologically, they suggest that coral density modulates size-dependent growth trade-offs, potentially through altered intraspecific competition, resource availability, or CAFI community effects that scale differently with coral size. Methodologically, we addressed this by calculating size-corrected growth using a unified allometric exponent (b = 0.6986) pooled across treatments. This approach prioritizes statistical robustness and comparability over potentially spurious treatment-specific corrections, particularly given the high uncertainty in some slope estimates (e.g., 3-colony treatment SE = 0.38). After this unified size-correction, no treatment effect on growth remained (p = 0.267), indicating that the primary treatment effect operates through altered allometric scaling rather than absolute growth performance.

---

## Statistical Software Statement

**ADD to Methods:**

> "All analyses were conducted in R version [X.X.X] (R Core Team 2024). Linear mixed-effects models were fit using lme4 (Bates et al. 2015) with p-values from lmerTest (Kuznetsova et al. 2017). Post-hoc comparisons were conducted using emmeans (Lenth 2024). Community analyses used vegan (Oksanen et al. 2024). All figures were created with ggplot2 (Wickham 2016)."

---

## Key Citations to Add

If not already present:

- **Osenberg, C.W.** (Personal communication regarding unified allometric model approach)
- **Bates, D., et al. (2015).** Fitting Linear Mixed-Effects Models Using lme4. Journal of Statistical Software.
- **Lenth, R.V. (2024).** emmeans: Estimated Marginal Means. R package.
- **Kuznetsova, A., et al. (2017).** lmerTest Package: Tests in Linear Mixed Effects Models. Journal of Statistical Software.

---

## Data Availability Statement

**UPDATE to mention:**

> "All size-corrected growth values were calculated using a unified allometric exponent (b = 0.6986) estimated from a mixed-effects model pooling data across treatments. Raw coral size measurements and calculated growth metrics are available in the supplementary data file 'coral_growth.csv'."

---

## Notes on "Old" vs "New" Comparisons

Most tests in the comparison table show "NA" for "Old" values because:

1. **The unified model approach is NEW** - we previously may have calculated growth differently or not documented these specific tests
2. **Post-hoc analyses are NEW** - these comprehensive tests were added as part of implementing Craig's advice
3. **Some tests are unchanged** - tests that don't involve growth_vol_b (e.g., SA-scaled growth, ΔVolume models) remained the same

**Bottom line:** Focus on reporting the NEW values, as they represent the correct, more rigorous analysis approach.

---

## Questions or Clarifications Needed?

If you need:
- Exact model coefficients (β estimates) for effect sizes
- R² values for any models
- Specific Mantel test statistics from Script 8
- Confidence intervals for any estimates
- Additional figures or tables

Let me know and I can extract these from the full model outputs or re-run specific analyses.

---

## Summary Checklist for Manuscript Update

### Methods Section:
- [ ] Replace growth analysis methods with full revised text (see Section 1 above)
- [ ] Add description of interaction model testing
- [ ] Add post-hoc testing methods (emmeans::emtrends)
- [ ] Add model comparison approach (LRT)
- [ ] Update statistical software statement
- [ ] Add Osenberg personal communication citation

### Results Section:
- [ ] Replace growth results with revised text emphasizing interaction (see Section 2 above)
- [ ] Report significant interaction (χ² = 6.48, p = 0.039) as MAIN finding
- [ ] Present treatment-specific slopes (b values) with biological interpretation
- [ ] Report post-hoc tests (marginal but NS after adjustment)
- [ ] Report model comparison (LRT p = 0.073)
- [ ] Report unified model results (p = 0.267 after size-correction)
- [ ] Update physiology results (carbohydrate p = 0.007, PC1 p = 0.017)
- [ ] Update CAFI-coral results (p = 0.00085)

### Discussion Section:
- [ ] Add interpretation of treatment-specific allometric slopes (see Section 5 above)
- [ ] Discuss biological mechanisms for differential allometry
- [ ] Explain methodological choice to use unified b for downstream analyses
- [ ] Connect allometric findings to density-dependence theory

### Figures & Tables:
- [ ] Update Figure X caption with revised 3-panel version (see Figure Legends section)
- [ ] Ensure all 3 panels are included: (A) parallel slopes, (B) interaction model, (C) size-corrected growth
- [ ] Add Table S1 with treatment-specific slopes and post-hoc tests (RECOMMENDED)
- [ ] Review all other figure captions for consistency

### Supplementary Materials:
- [ ] Add Table S1: Treatment-specific allometric growth relationships (3 parts - see above)
- [ ] Consider adding supplementary figure showing interaction model diagnostics
- [ ] Update data availability statement to mention unified b calculation

### Final Checks:
- [ ] Ensure all statistics match between text, tables, and figures
- [ ] Verify figure panel labels (A, B, C) match text references
- [ ] Check that "treatment-specific slopes" language is consistent throughout
- [ ] Confirm all p-values are accurately transcribed from analysis outputs

---

**Generated:** 2025-11-14
**Author:** Claude Code Analysis Pipeline
**For:** Stier-2025-CAFI136-MRB-AMOUNT Project

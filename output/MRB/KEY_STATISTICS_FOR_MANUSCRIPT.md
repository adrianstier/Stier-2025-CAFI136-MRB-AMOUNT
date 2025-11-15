# Key Statistics for Manuscript (Quick Reference)

**Updated:** 2025-11-14

---

## PRIMARY RESULTS (Main Text)

### Coral Growth

1. **Unified allometric model (PRIMARY):**
   - Model: `log(V_final) ~ log(V_initial) + treatment + (1|reef)`
   - Allometric exponent (b): **0.6986**
   - Initial size effect: χ² = 28.46, df = 1, **p < 0.001***
   - Treatment effect: χ² = 2.64, df = 2, **p = 0.267** (NS)

2. **Interaction model (EXPLORATORY):**
   - Model: `log(V_final) ~ log(V_initial) × treatment + (1|reef)`
   - Interaction: χ² = 6.48, df = 2, **p = 0.039***
   - Model comparison (LRT): χ² = 5.23, df = 2, **p = 0.073** (NS)
   - **Conclusion:** Parallel slopes adequate; use unified b for all calculations

3. **Post-hoc pairwise slope comparisons (Tukey-adjusted):**
   - Treatment 1 vs 3: **p = 0.094** (NS)
   - Treatment 1 vs 6: **p = 0.795** (NS)
   - Treatment 3 vs 6: **p = 0.072** (NS)
   - **Conclusion:** No significant pairwise differences

---

### Coral Physiology

1. **Carbohydrate content:**
   - Model: `lmer(carb_mg_cm2 ~ treatment + (1|reef))`
   - χ² = 10.0, df = 2, **p = 0.007**
   - Benjamini-Hochberg adjusted: **p_BH = 0.039***
   - **Significant treatment effect**

2. **PC1 (physiology + growth):**
   - Model: `lmer(PC1 ~ treatment + (1|reef))`
   - χ² = 8.11, df = 2, **p = 0.017***
   - **Significant treatment effect**

3. **Other metrics (NS):**
   - Protein: χ² = 3.04, p = 0.219
   - Zooxanthellae: χ² = 1.70, p = 0.428
   - AFDW: χ² = 4.40, p = 0.111
   - PC2: χ² = 0.863, p = 0.649

---

### CAFI Community - Coral Condition

1. **Community PC1 predicts Condition PC1:**
   - SQRT_CS transformation: **p = 0.00085***
   - HELLINGER transformation: **p = 0.014***
   - SQRT transformation: **p = 0.042***
   - **Robust, highly significant relationship**

---

## SUPPLEMENTARY RESULTS

### Treatment-Specific Allometric Slopes

| Treatment | n | b | SE | 95% CI |
|-----------|---|---|-----|--------|
| 1 colony | 15 | 0.781 | 0.161 | [0.450, 1.112] |
| 3 colonies | 15 | -0.099 | 0.377 | [-0.862, 0.665] |
| 6 colonies | 14 | 1.004 | 0.304 | [0.385, 1.622] |

### Surface Area Analyses

1. **SA-scaled growth by treatment:**
   - χ² = 3.24, df = 2, **p = 0.198** (NS)

2. **ΔVolume ~ SA × treatment (interaction):**
   - SA effect: χ² = 6.35, **p = 0.012***
   - Treatment: χ² = 2.46, p = 0.292 (NS)
   - Interaction: χ² = 1.92, p = 0.383 (NS)

3. **ΔVolume ~ SA + treatment (parallel):**
   - SA effect: χ² = 5.87, **p = 0.015***
   - Treatment: χ² = 2.91, p = 0.234 (NS)

---

## FIGURE LEGENDS (Updated)

### Figure X: Coral Volume Allometric Growth

> **(A)** Relationship between initial and final coral volume (log-transformed) across treatments. Lines represent fitted linear mixed-effects model with parallel slopes (unified allometric exponent b = 0.6986). Colors indicate treatment: orange = 1 colony, blue = 3 colonies, green = 6 colonies. **(B)** Size-corrected growth by treatment (growth_vol_b = V_final / V_initial^0.6986). No significant treatment effect (χ² = 2.64, df = 2, p = 0.267). Points show individual corals; boxes show median and quartiles; whiskers extend to 1.5×IQR.

### Figure Y: Coral Physiology by Treatment

> Physiological metrics and principal component scores by treatment. **(A)** Carbohydrate content differed significantly among treatments (χ² = 10.0, p = 0.007). **(B)** Protein content showed no significant difference (χ² = 3.04, p = 0.219). **(C)** Zooxanthellae density showed no significant difference (χ² = 1.70, p = 0.428). **(D)** PC1 (integrating physiology + growth) differed by treatment (χ² = 8.11, p = 0.017). Colors as in Figure X.

### Figure Z: CAFI Community Predicts Coral Condition

> Community composition PC1 (x-axis) significantly predicts integrated coral condition PC1 (y-axis) incorporating growth, physiology, and symbiont metrics. Points represent individual coral heads colored by treatment (orange = 1 colony, blue = 3 colonies, green = 6 colonies). Line shows linear mixed-effects model prediction with 95% confidence interval (gray shading). SQRT_CS transformation shown; relationship robust across transformations (HELLINGER p = 0.014, SQRT p = 0.042).

---

## TABLE LEGEND (For Summary Table)

### Table X: Statistical Tests Summary

> Summary of key statistical tests from linear mixed-effects models examining coral growth, physiology, and relationships with CAFI community composition. All models included reef as a random intercept. The unified allometric model was used to calculate size-corrected growth (growth_vol_b = V_final / V_initial^0.6986) where the exponent b = 0.6986 was estimated from a model pooling data across treatments. Type III Wald χ² tests were used for significance testing. p_BH indicates Benjamini-Hochberg adjusted p-values for multiple testing correction.

---

## METHODS TEXT (Copy-Paste Ready)

### Statistical Analysis - Coral Growth

> Coral volume growth was analyzed using a unified linear mixed-effects model following Osenberg (pers. comm.). We fit a single model pooling data across treatments: log(V_final) ~ log(V_initial) + treatment + (1|reef), where reef was a random intercept. This approach yields a more precise within-group estimate of the allometric exponent (b = 0.6986) compared to fitting separate models per treatment. Size-corrected growth was calculated as: growth_vol_b = V_final / V_initial^b for all corals, ensuring comparable metrics across treatments. We tested for treatment effects on size-corrected growth using Type III Wald χ² tests.
>
> To explore potential treatment-specific differences in allometric slopes, we also fit an interaction model: log(V_final) ~ log(V_initial) × treatment + (1|reef). Treatment-specific slopes were extracted using emmeans::emtrends() (Lenth 2024) and compared pairwise with Tukey adjustment. Likelihood ratio test compared model fit between interaction and parallel slopes models.

### Statistical Analysis - Physiology & Community

> Physiological metrics and integrated condition scores were analyzed using linear mixed-effects models with treatment as a fixed effect and reef as a random intercept. Multiple testing correction used the Benjamini-Hochberg procedure. Principal component analysis was conducted on standardized physiological metrics plus size-corrected growth to create integrated condition scores. CAFI community composition was also analyzed via PCA on transformed species abundance matrices (square-root, Hellinger, and centered-scaled square-root transformations). Relationships between community and condition PC axes were tested using linear mixed-effects models.
>
> All analyses were conducted in R 4.3.x. Linear mixed-effects models used lme4 (Bates et al. 2015) with p-values from lmerTest (Kuznetsova et al. 2017). Post-hoc tests used emmeans (Lenth 2024). Community analyses used vegan (Oksanen et al. 2024). Figures used ggplot2 (Wickham 2016).

---

## RESULTS TEXT (Copy-Paste Ready)

### Results - Coral Growth

> Coral volume growth followed a strong allometric relationship with initial size (χ² = 28.46, df = 1, p < 0.001). Using a unified model pooling data across treatments, we estimated an allometric exponent of b = 0.6986. After accounting for initial size using this unified exponent, there was no significant effect of treatment on volume growth (χ² = 2.64, df = 2, p = 0.267, Fig. XA-B).
>
> Exploratory analysis revealed a significant interaction between initial size and treatment (χ² = 6.48, df = 2, p = 0.039), suggesting potential differences in allometric slopes among treatments. However, post-hoc pairwise comparisons showed no significant differences after Tukey adjustment (all p > 0.07, Table SX). Furthermore, likelihood ratio test indicated the parallel slopes model was adequate (χ² = 5.23, df = 2, p = 0.073). We therefore used the unified b estimate for all growth calculations to ensure comparable metrics across treatments.

### Results - Physiology

> Physiological metrics varied in their response to treatment. Carbohydrate content differed significantly among treatments (χ² = 10.0, df = 2, p = 0.007, Benjamini-Hochberg adjusted p = 0.039, Fig. YA). Principal component analysis integrating all physiological metrics plus size-corrected growth revealed that PC1 also differed by treatment (χ² = 8.11, df = 2, p = 0.017, Fig. YD). Individual metrics including protein content (χ² = 3.04, p = 0.219, Fig. YB), zooxanthellae density (χ² = 1.70, p = 0.428, Fig. YC), and ash-free dry weight (χ² = 4.40, p = 0.111) did not differ significantly by treatment.

### Results - Community-Condition

> CAFI community composition, captured by PC1, significantly predicted integrated coral condition (χ² = XX.X, df = 1, p = 0.00085, Fig. Z). This relationship was robust across multiple data transformations including Hellinger (p = 0.014) and simple square-root (p = 0.042), confirming the strong association between community structure and coral performance metrics (growth, physiology, symbiont density) regardless of analytical approach.

---

## SIGNIFICANCE CODES

*** p < 0.001
** p < 0.01
* p < 0.05
. p < 0.1
NS p ≥ 0.05

---

**End of Quick Reference**

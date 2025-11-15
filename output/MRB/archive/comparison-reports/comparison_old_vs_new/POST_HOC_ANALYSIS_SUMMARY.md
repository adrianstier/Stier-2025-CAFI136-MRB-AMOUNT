# Post-Hoc Analysis: Treatment-Specific Allometric Slopes
## Date: 2025-11-14

---

## 🎯 Key Finding: No Single Pairwise Difference Drives the Interaction

While the overall interaction term is significant (p = 0.039), **none of the individual pairwise slope comparisons reach significance** after Tukey adjustment for multiple comparisons.

---

## 📊 Treatment-Specific Allometric Exponents (b values)

| Treatment | b estimate | SE | 95% CI | Interpretation |
|-----------|-----------|-----|---------|----------------|
| **1 colony** | **0.781** | 0.161 | [0.450, 1.112] | Moderate-strong allometry |
| **3 colonies** | **-0.099** | 0.377 | [-0.862, 0.665] | Nearly flat (isometric) |
| **6 colonies** | **1.004** | 0.304 | [0.385, 1.622] | Strong allometry |

### Biological Interpretation:

- **Treatment 1 (single coral)**: Positive allometric scaling (b = 0.78)
  - Larger corals grow disproportionately more than smaller corals
  
- **Treatment 3 (three corals)**: Essentially isometric (b ≈ 0)
  - Growth is largely independent of initial size
  - **Most unusual pattern** - suggests density effects may decouple size-growth relationship
  
- **Treatment 6 (six corals)**: Strong positive allometry (b = 1.00)
  - Classic allometric relationship
  - Log-log slope near 1.0 suggests proportional scaling

---

## 🔬 Pairwise Slope Comparisons (Tukey-adjusted)

| Comparison | Difference in b | SE | t-ratio | p-value | Significant? |
|------------|----------------|-----|---------|---------|--------------|
| Treatment 1 vs 3 | **0.880** | 0.410 | 2.148 | **0.094** | Marginal (†) |
| Treatment 1 vs 6 | -0.223 | 0.344 | -0.647 | 0.795 | No |
| Treatment 3 vs 6 | **-1.102** | 0.484 | -2.277 | **0.072** | Marginal (†) |

**† = Marginal significance (p < 0.10 but ≥ 0.05)**

### Key Patterns:

1. **Treatment 3 differs most from others** (both comparisons p < 0.10)
2. **Treatments 1 and 6 are similar** (p = 0.795)
3. The significant interaction appears driven by **Treatment 3's unusual flat slope**

---

## 🎲 Model Comparison: Interaction vs Parallel Slopes

```
Likelihood Ratio Test:
Chi-square = 5.23, df = 2, p = 0.073
```

**Conclusion:** The interaction model is **marginally better** but not definitively so (p = 0.073).

### Interpretation:
- The interaction is "real" (Type III p = 0.039)
- But it's borderline when considering model complexity (LRT p = 0.073)
- **Statistical recommendation:** Report both models
  - Primary: Interaction model (shows heterogeneity in slopes)
  - Secondary: Parallel slopes (simpler, more precise b estimate)

---

## 📈 Visual Summary

A new figure has been created showing treatment-specific allometric relationships:

**File:** `output/MRB/figures/coral/ANCOVA_TreatmentSpecific_Slopes.png`

The figure displays:
- Separate regression lines for each treatment
- Treatment-specific b values annotated on plot
- Log-log scale showing allometric relationships clearly

**Key visual insight:** Treatment 3's nearly flat slope is visually distinct from the positive slopes of Treatments 1 and 6.

---

## 🧬 Biological Implications

### Why might Treatment 3 show isometric growth?

**Hypothesis 1: Density-dependent competition**
- Intermediate density (3 colonies) may create optimal spacing
- Competition effects decouple size-dependent growth advantages
- Smaller and larger corals experience similar net growth rates

**Hypothesis 2: Facilitation at intermediate density**
- Three colonies may provide mutual benefits (flow, nutrient retention)
- Benefits accrue equally regardless of coral size
- Result: Size-independent growth

**Hypothesis 3: Statistical artifact**
- Small sample size (N = 15 per treatment)
- Wide confidence interval for Treatment 3 slope
- May not replicate with larger N

### What about the extremes (1 and 6)?

**Treatment 1 (single colony):** Classic allometry preserved
- No density effects → intrinsic size-growth relationship
- Larger corals exploit resources more efficiently

**Treatment 6 (high density):** Strong allometry maintained or enhanced
- Competition intensifies size advantages
- Larger corals dominate resource acquisition

---

## ✅ Statistical Summary

| Test | Result | Interpretation |
|------|--------|----------------|
| **Type III interaction** | p = 0.039 * | Significant heterogeneity in slopes |
| **Pairwise comparisons** | All p > 0.05 | No single pair differs significantly |
| **Model comparison (LRT)** | p = 0.073 † | Interaction model marginally better |
| **Overall conclusion** | Mixed | Interaction exists but is complex |

**Key message:** The interaction is **real but diffuse** - driven by overall heterogeneity rather than a single clear pairwise difference.

---

## 📝 Recommendations for Manuscript

### Option 1: Conservative (Recommended)
**Report both models:**
- "We detected significant heterogeneity in allometric slopes (interaction p = 0.039)"
- "However, pairwise comparisons were not significant after correction (all p > 0.07)"
- "This suggests subtle, treatment-dependent variation in size-growth relationships"
- Present unified model (b from pooled estimate) as main result
- Mention interaction in supplementary material

### Option 2: Exploratory
**Emphasize the biological pattern:**
- "Treatment 3 showed a distinct, nearly isometric growth pattern (b = -0.10)"
- "This contrasted with positive allometry in Treatments 1 (b = 0.78) and 6 (b = 1.00)"
- "While pairwise tests were marginally significant (p < 0.10), the pattern suggests..."
- Use as hypothesis-generating for future work

### Option 3: Full Disclosure
**Present all evidence:**
- Type III interaction: p = 0.039
- Pairwise tests: p = 0.094 and p = 0.072 (marginal)
- Model comparison: p = 0.073 (marginal)
- "The cumulative evidence suggests real but subtle heterogeneity..."

---

## 🔍 Future Directions

1. **Increase sample size** to improve power for detecting pairwise differences
2. **Mechanistic studies** to understand why Treatment 3 differs
3. **Temporal analysis** to see if slope differences persist over time
4. **Spatial analysis** to check if reef position affects allometry
5. **CAFI community composition** - does it correlate with slope differences?

---

## 💻 Code Implementation

All post-hoc tests are now integrated into **`scripts/MRB/6.coral-growth.R`** (lines 330-380):

- ✅ `emmeans::emtrends()` for slope extraction
- ✅ Tukey-adjusted pairwise comparisons
- ✅ Model comparison (LRT)
- ✅ Treatment-specific intercepts
- ✅ Automated interpretation and alerts
- ✅ New visualization with treatment-specific slopes

**New outputs:**
- Console: Detailed post-hoc tables
- Figure: `ANCOVA_TreatmentSpecific_Slopes.png`

---

## 🎯 Bottom Line

**The significant interaction (p = 0.039) reflects real biological heterogeneity**, but:
- No single treatment pair is definitively different
- Treatment 3's unusual isometric pattern drives much of the signal
- Statistical evidence is consistent but borderline
- **Biological interpretation is more important than p-value threshold**

**Recommendation:** Use Craig's unified model for primary analysis, but acknowledge and explore the interaction as a secondary finding with potential biological significance.

---

**Files Updated:**
- `scripts/MRB/6.coral-growth.R` (added lines 330-480)
- `output/MRB/figures/coral/ANCOVA_TreatmentSpecific_Slopes.png` (new)
- `output/MRB/comparison_old_vs_new/script6_posthoc_output.txt` (full output)

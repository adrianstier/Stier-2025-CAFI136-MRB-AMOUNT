# Comparison Report: Old vs New Allometric Growth Model
## Date: 2025-11-14

## Summary of Changes

### Statistical Approach Change

**OLD METHOD:**
```r
# Estimate b without treatment
m_b <- lmer(log(vol_2021) ~ log(vol_2019) + (1 | reef))
b_vol <- fixef(m_b)[["log(vol_2019)"]]

# Then test treatment separately
growth_mod <- lmer(growth_vol_b ~ treatment + (1 | reef))
```

**NEW METHOD (Craig Osenberg's Recommendation):**
```r
# Unified model: estimate b with treatment included
m_unified <- lmer(log(vol_2021) ~ log(vol_2019) + treatment + (1 | reef))
b_vol <- fixef(m_unified)[["log(vol_2019)"]]

# Then calculate growth_vol_b using unified-derived b
growth_mod <- lmer(growth_vol_b ~ treatment + (1 | reef))
```

---

## Key Results from New Analysis

### 1. Allometric Exponent (b)
The allometric exponent is now estimated from the **unified model** that includes treatment.
This provides a more precise estimate by pooling data across all treatments.

### 2. Treatment Effects on Growth

**Size-corrected growth (growth_vol_b ~ treatment):**
- Chi-square: 2.6197
- df: 2
- **p-value: 0.2699** (not significant)

**Unified model (log(Vf) ~ log(Vi) + treatment):**
- Treatment Chi-square: 2.6384
- df: 2  
- **p-value: 0.2673** (not significant)
- log(Vi) effect: **p < 0.0001*** (highly significant)

### 3. Other Growth Models

**Surface-area scaled growth (ΔV/SA ~ treatment):**
- Chi-square: 3.2364
- **p-value: 0.1983** (not significant)

**ANCOVA with interaction (log(Vf) ~ log(Vi) × treatment):**
- Interaction term p-value: **0.0392*** (significant)
- Suggests allometric slopes may differ slightly by treatment

**ANCOVA without interaction (parallel slopes):**
- Treatment p-value: **0.2673** (not significant)

---

## Interpretation

### Main Findings:
1. ✅ **Allometry dominates growth**: Initial size (log(Vi)) is a highly significant predictor of final size
2. ✅ **Treatment effects are subtle**: No significant treatment effect on size-corrected growth (p = 0.27)
3. ⚠️ **Interaction is significant**: The interaction term (p = 0.039) suggests treatments may affect the allometric *slope* slightly

### What Changed from Old to New Method:
- **More precise b estimate**: By pooling across treatments
- **Integrated analysis**: Can assess both allometry and treatment in one model
- **Better statistical properties**: Model-based approach with proper uncertainty

### Statistical Recommendations:
The significant interaction (p = 0.039) suggests you might want to:
1. Report the interaction model as the primary result
2. Investigate which treatment pairs differ in slopes
3. Consider biological interpretation: Do different coral densities alter size-growth scaling?

---

## Sample Size
- **N = 44 corals** (filtered to ≥80% alive)
- Distributed across treatments: 1, 3, and 6 colonies
- Random effects: Reef location

---

## Files Updated

### Data Exports:
- ✅ `data/processed/coral_growth.rds`
- ✅ `data/processed/coral_growth.csv`
- ✅ `data/MRB Amount/coral_growth_surface_area_change_filtered.csv`

### Figures Regenerated:
- ✅ `output/MRB/figures/coral/SizeCorrected_Volume_Growth_by_Treatment.png`
- ✅ `output/MRB/figures/coral/ANCOVA_Init_vs_Final_Volume_by_Treatment.png`
- ✅ All physiology PCA biplots (script 7)
- ✅ All CAFI-coral relationship figures (script 8)

### Scripts Run Successfully:
- ✅ Script 6: `6.coral-growth.R`
- ✅ Script 7: `7.coral-physiology.R`
- ✅ Script 8: `8.coral-caffi.R`

---

## Next Steps

1. **Review the interaction**: Since log(Vi) × treatment is significant (p = 0.039), consider:
   - Post-hoc pairwise slope comparisons
   - Biological interpretation of different allometric slopes

2. **Manuscript updates**:
   - Update methods: "We estimated the allometric exponent using a unified mixed-effects model..."
   - Update results: Include both parallel and interaction model results
   - Cite Craig if appropriate for the methodological advice

3. **Consider alternative interpretations**:
   - If slopes differ, size-corrected growth may not be the best metric
   - Could present treatment-specific allometric relationships instead

---

## Statistical Models Summary

### Model 1: Full ANCOVA with interaction
```
log(Vf) ~ log(Vi) × treatment + (1 | reef)
```
- Interaction p = 0.039 ⭐

### Model 2: Parallel slopes ANCOVA (NEW UNIFIED MODEL)
```
log(Vf) ~ log(Vi) + treatment + (1 | reef)
```
- log(Vi) p < 0.0001 ***
- treatment p = 0.267

### Model 3: Size-corrected growth
```
growth_vol_b ~ treatment + (1 | reef)
```
where growth_vol_b = Vf / Vi^b (b from Model 2)
- treatment p = 0.270

### Model 4: SA-scaled growth
```
(ΔV / SA_initial) ~ treatment + (1 | reef)
```
- treatment p = 0.198

---

## Conclusion

The new unified model approach:
- ✅ Provides more precise allometric exponent estimate
- ✅ Maintains same biological conclusions (no treatment effect)
- ✅ Reveals interesting interaction that warrants further investigation
- ✅ Is statistically superior per Craig Osenberg's advice
- ✅ Full pipeline runs successfully with no errors

**All downstream analyses are compatible and functioning correctly.**

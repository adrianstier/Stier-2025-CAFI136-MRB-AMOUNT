# Exploratory Trapezia analysis

Generated: 2026-07-31 10:18:38 PDT

## Scope

- Raw CAFI treatment/community summaries use 54 colonies on 27 reefs.
- Coral-condition associations use 44 colonies on 23 reefs, matching the filtered growth/physiology condition data.
- Trapezia species detected: Trapezia areolata, Trapezia bella, Trapezia bidentata, Trapezia guttata, Trapezia punctimanus, Trapezia serenei, Trapezia speciosa, Trapezia tigrina.
- Condition PC1 explains 52.5% of standardized growth/physiology variance and is oriented so higher PC1 means higher overall condition.

## Main read

- `Trapezia serenei` is the dominant and ubiquitous congener: 314 individuals across 54 of 54 colonies. Any-Trapezia incidence is therefore not informative.
- Mean `T. serenei` abundance per colony by treatment was 1-coral: 4.67; 3-coral: 6.17; 6-coral: 6.61. This is the clearest treatment-direction signal.
- The existing 38-species proportional-scaling table classifies the Trapezia rows as not significant; use that rather than treating raw above-expected deviations as significant.
- In treatment-adjusted condition models, the smallest metric-level p-value was 0.240 for arcsin sqrt non-serenei Trapezia share of full CAFI. In species-level treatment-adjusted abundance models, the smallest p-value was 0.024 for Trapezia bidentata. These should be read as exploratory screens, not confirmatory tests.

## Species abundance and incidence by treatment

| species | treatment | total_count | mean_per_coral | n_present | prevalence |
| --- | --- | --- | --- | --- | --- |
| Trapezia guttata | 1 | 2 | 0.111 | 1 | 0.0556 |
| Trapezia guttata | 3 | 6 | 0.333 | 3 | 0.167 |
| Trapezia guttata | 6 | 4 | 0.222 | 2 | 0.111 |
| Trapezia serenei | 1 | 84 | 4.67 | 18 | 1.00 |
| Trapezia serenei | 3 | 111 | 6.17 | 18 | 1.00 |
| Trapezia serenei | 6 | 119 | 6.61 | 18 | 1.00 |
| Trapezia tigrina | 1 | 4 | 0.222 | 3 | 0.167 |
| Trapezia tigrina | 3 | 4 | 0.222 | 2 | 0.111 |
| Trapezia tigrina | 6 | 6 | 0.333 | 5 | 0.278 |

## Colony-level Trapezia metrics by treatment

| metric | treatment | n | mean | median | n_nonzero | nonzero_rate |
| --- | --- | --- | --- | --- | --- | --- |
| trap_non_serenei | 1 | 18 | 0.722 | 0 | 7 | 0.389 |
| trap_non_serenei | 3 | 18 | 0.722 | 0 | 7 | 0.389 |
| trap_non_serenei | 6 | 18 | 1.00 | 0.500 | 9 | 0.500 |
| trap_prop_full | 1 | 18 | 0.0543 | 0.0522 | 18 | 1.00 |
| trap_prop_full | 3 | 18 | 0.0717 | 0.0647 | 18 | 1.00 |
| trap_prop_full | 6 | 18 | 0.0770 | 0.0615 | 18 | 1.00 |
| trap_rare_richness | 1 | 18 | 0.556 | 0 | 7 | 0.389 |
| trap_rare_richness | 3 | 18 | 0.444 | 0 | 7 | 0.389 |
| trap_rare_richness | 6 | 18 | 0.722 | 0.500 | 9 | 0.500 |
| trap_serenei | 1 | 18 | 4.67 | 5.00 | 18 | 1.00 |
| trap_serenei | 3 | 18 | 6.17 | 5.00 | 18 | 1.00 |
| trap_serenei | 6 | 18 | 6.61 | 5.00 | 18 | 1.00 |
| trap_total | 1 | 18 | 5.39 | 5.00 | 18 | 1.00 |
| trap_total | 3 | 18 | 6.89 | 6.00 | 18 | 1.00 |
| trap_total | 6 | 18 | 7.61 | 7.00 | 18 | 1.00 |

## Reef-level treatment tests

Treatment was imposed at the reef scale, so this table is the main screen for treatment effects. P-values are exploratory and uncorrected plus BH-corrected within this family of reef-level tests.

| metric | n | lm_F | lm_r2 | lm_p | lm_p_BH | spearman_rho | spearman_p |
| --- | --- | --- | --- | --- | --- | --- | --- |
| trap_total_reef | 27 | 63.5 | 0.841 | <0.001 | <0.001 | 0.838 | <0.001 |
| trap_richness_reef | 27 | 13.3 | 0.527 | <0.001 | <0.001 | 0.607 | <0.001 |
| trap_rare_richness_reef | 27 | 13.3 | 0.527 | <0.001 | <0.001 | 0.607 | <0.001 |
| trap_serenei_density_per_colony | 27 | 3.31 | 0.216 | 0.054 | 0.134 | 0.470 | 0.013 |
| trap_density_per_colony | 27 | 2.18 | 0.154 | 0.135 | 0.252 | 0.389 | 0.045 |
| trap_prop_full_reef | 27 | 2.05 | 0.146 | 0.151 | 0.252 | 0.481 | 0.011 |
| trap_serenei_prop_full_reef | 27 | 1.78 | 0.129 | 0.190 | 0.272 | 0.486 | 0.010 |
| trap_non_serenei_prop_full_reef | 27 | 0.501 | 0.0401 | 0.612 | 0.765 | 0.224 | 0.262 |
| trap_non_serenei_density_per_colony | 27 | 0.107 | 0.00887 | 0.899 | 0.921 | 0.228 | 0.252 |
| trap_non_serenei_incidence_rate | 27 | 0.0830 | 0.00687 | 0.921 | 0.921 | 0.145 | 0.471 |

## Existing 38-species scaling rows

| Species | Taxon | Obs_t3 | Exp_t3 | Obs_t6 | Exp_t6 | Deviation_pct_t6 | Direction | Significant |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Trapezia serenei | Crustacean | 18.5 | 14.0 | 39.7 | 28.0 | 41.7 | Above | FALSE |
| Trapezia tigrina | Crustacean | 0.667 | 0.667 | 2.00 | 1.33 | 50.0 | Above | FALSE |

## Condition PC1 models

Estimates are change in condition PC1 per 1 SD increase in the transformed Trapezia predictor, with treatment included as a covariate and reef as a random intercept.

| label | n | n_reefs | estimate | conf_low | conf_high | p_value | p_value_BH | singular |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| arcsin sqrt non-serenei Trapezia share of full CAFI | 44 | 23 | -0.274 | -0.724 | 0.176 | 0.240 | 0.542 | FALSE |
| sqrt T. serenei abundance | 44 | 23 | 0.275 | -0.197 | 0.747 | 0.260 | 0.542 | TRUE |
| sqrt non-serenei Trapezia abundance | 44 | 23 | -0.248 | -0.702 | 0.207 | 0.292 | 0.542 | FALSE |
| sqrt Trapezia richness | 44 | 23 | -0.231 | -0.691 | 0.228 | 0.330 | 0.542 | FALSE |
| sqrt rare Trapezia richness | 44 | 23 | -0.227 | -0.686 | 0.232 | 0.339 | 0.542 | FALSE |
| sqrt total Trapezia abundance | 44 | 23 | 0.140 | -0.339 | 0.620 | 0.576 | 0.720 | FALSE |
| arcsin sqrt Trapezia share of full CAFI | 44 | 23 | -0.118 | -0.595 | 0.359 | 0.630 | 0.720 | FALSE |
| arcsin sqrt T. serenei share of full CAFI | 44 | 23 | 0.00529 | -0.475 | 0.485 | 0.983 | 0.983 | FALSE |

## Species-level condition models

| species | n | estimate | conf_low | conf_high | p_value | p_value_BH | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Trapezia bidentata | 44 | -0.523 | -0.960 | -0.0865 | 0.024 | 0.191 | NA |
| Trapezia areolata | 44 | 0.299 | -0.154 | 0.751 | 0.206 | 0.520 | NA |
| Trapezia guttata | 44 | -0.295 | -0.752 | 0.162 | 0.214 | 0.520 | NA |
| Trapezia serenei | 44 | 0.275 | -0.197 | 0.747 | 0.260 | 0.520 | NA |
| Trapezia speciosa | 44 | -0.230 | -0.685 | 0.225 | 0.328 | 0.524 | NA |
| Trapezia bella | 44 | -0.180 | -0.627 | 0.267 | 0.437 | 0.583 | NA |
| Trapezia punctimanus | 44 | 0.0468 | -0.410 | 0.504 | 0.842 | 0.857 | NA |
| Trapezia tigrina | 44 | -0.0425 | -0.503 | 0.418 | 0.857 | 0.857 | NA |

## Nominal individual-trait correlations

This table lists unadjusted p < 0.10 screens across transformed Trapezia metrics and individual condition traits. BH-adjusted p-values are included to show how fragile the nominal signals are.

| label | trait | method | n | estimate | p_value | p_value_BH |
| --- | --- | --- | --- | --- | --- | --- |
| sqrt T. serenei abundance | zoox_cells_cm2 | spearman | 44 | 0.382 | 0.011 | 0.509 |
| Trapezia serenei sqrt abundance | zoox_cells_cm2 | spearman | 44 | 0.382 | 0.011 | 0.509 |
| sqrt T. serenei abundance | zoox_cells_cm2 | pearson | 44 | 0.337 | 0.025 | 0.799 |
| Trapezia serenei sqrt abundance | zoox_cells_cm2 | pearson | 44 | 0.337 | 0.025 | 0.799 |
| arcsin sqrt Trapezia share of full CAFI | carb_mg_cm2 | spearman | 44 | -0.332 | 0.027 | 0.652 |
| arcsin sqrt Trapezia share of full CAFI | protein_mg_cm2 | spearman | 44 | -0.296 | 0.051 | 0.652 |
| arcsin sqrt Trapezia share of full CAFI | growth_vol_b | pearson | 44 | -0.277 | 0.068 | 0.799 |
| Trapezia tigrina sqrt abundance | zoox_cells_cm2 | pearson | 44 | -0.277 | 0.069 | 0.799 |
| Trapezia punctimanus sqrt abundance | growth_vol_b | spearman | 44 | -0.273 | 0.073 | 0.652 |
| arcsin sqrt Trapezia share of full CAFI | cond_PC1 | spearman | 44 | -0.273 | 0.073 | 0.652 |
| Trapezia tigrina sqrt abundance | zoox_cells_cm2 | spearman | 44 | -0.269 | 0.078 | 0.652 |
| arcsin sqrt T. serenei share of full CAFI | carb_mg_cm2 | spearman | 44 | -0.264 | 0.083 | 0.652 |

## Trapezia species composition tests

| scale | matrix | test | term | df | statistic | r2 | p_value |
| --- | --- | --- | --- | --- | --- | --- | --- |
| reef | sqrt Trapezia abundance | adonis2 Bray by terms | treatment | 2 | 16.5 | 0.578 | 0.001 |
| reef | sqrt Trapezia per-colony density | adonis2 Bray by terms | treatment | 2 | 2.96 | 0.198 | 0.016 |
| reef | Trapezia relative composition | adonis2 Bray by terms | treatment | 2 | 0.665 | 0.0525 | 0.651 |
| colony condition subset | sqrt Trapezia abundance | adonis2 Bray by terms | cond_PC1 | 1 | 0.391 | 0.00880 | 0.773 |
| colony condition subset | sqrt Trapezia abundance | adonis2 Bray by terms | treatment | 2 | 2.00 | 0.0902 | 0.074 |
| colony condition subset | Trapezia relative composition | adonis2 Bray by terms | cond_PC1 | 1 | 1.05 | 0.0246 | 0.364 |
| colony condition subset | Trapezia relative composition | adonis2 Bray by terms | treatment | 2 | 0.769 | 0.0361 | 0.585 |

## Interpretation

- The strongest Trapezia pattern is ecological rather than physiological: `T. serenei` is everywhere and has higher per-colony abundance in the multi-coral treatments, but the existing proportional-scaling table does not support calling it significantly above expected.
- Rare congeners are too sparse for strong species-specific inference. Their incidence and richness are useful descriptors, but the sample sizes are small enough that isolated nominal results should not drive the manuscript.
- I do not see a robust signal that Trapezia abundance, diversity, incidence, or relative contribution explains overall coral condition PC1 after accounting for treatment and reef structure.
- The only places worth watching are physiology-specific screens, especially Symbiodiniaceae-density correlations for dominant or moderately common congeners. Those are candidate story details only if they remain consistent with the broader manuscript and multiple-testing caveats.

## Output files

- Tables: `output/MRB/exploratory/trapezia/tables`
- Figures: `output/MRB/exploratory/trapezia/figures`

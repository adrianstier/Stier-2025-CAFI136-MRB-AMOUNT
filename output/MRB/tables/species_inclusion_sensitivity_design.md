# Species-inclusion sensitivity analysis

Generated: 2026-07-30 07:05:20 PDT

## Design

- Ranked top-N species sets: 5, 10, 15, 20, 25, 30, 38, 50, 75, 100.
- Reference set: corrected manuscript 10x10 set (n = 38).
- Full community set: all observed species in the CAFI census (n = 118).
- Functional subset: obligate/strong coral-associated taxa plus damselfishes (n = 27).
- Abundance and scaling results use the full CAFI reef-level data.
- Beta-diversity and CAFI-condition results use the growth/physiology subset, because coral condition is only available there.
- PC1 signs are aligned so higher community PC1 is positively correlated with higher coral condition PC1 where possible.

## Key Result Summary

| Result | Main 38 estimate | Main 38 p | Whole-community p | Obligate+damselfish p | Sensitivity class |
|---|---:|---:|---:|---:|---|
| Treatment effect on rarefied richness | 1.671 | 0.033 | 0.032 | 0.311 | direction-sensitive across top-N |
| Treatment effect on richness | 2.786 | 0.249 | 0.081 | 0.165 | direction-sensitive across top-N |
| CAFI community PC1 predicts coral condition PC1 (HELLINGER) | 0.311 | 0.008 | 0.054 | 0.015 | functional-subset sensitive |
| Percent of included species with observed 6-coral density above proportional expectation | 68.421 |  |  |  | identity/count depends on included species |
| Number of species significantly above proportional scaling | 2.000 |  |  |  | identity/count depends on included species |
| Number of species significantly below proportional scaling | 1.000 |  |  |  | identity/count depends on included species |
| Alpheus diadema abundance predicts coral condition | -0.995 | 0.042 | 0.042 | 0.042 | inclusion-sensitive; coefficient stable when species is included |
| Caracanthus maculatus abundance predicts coral condition | 1.422 | 0.001 | 0.001 | 0.001 | inclusion-sensitive; coefficient stable when species is included |
| Dascyllus aruanus abundance predicts coral condition | 0.194 | 0.362 | 0.362 | 0.362 | inclusion-sensitive; coefficient stable when species is included |
| Luniella pugil abundance predicts coral condition | -0.917 | 0.013 | 0.013 |  | inclusion-sensitive; coefficient stable when species is included |
| Treatment effect on community composition: jaccard | 0.197 | 0.001 | 0.001 | 0.003 | significance-sensitive across top-N |
| Treatment effect on CAFI community PC1 (SQRT_CS) | -3.337 | 0.002 | 0.007 | 0.007 | significance-sensitive across top-N |
| CAFI community PC1 predicts coral condition PC1 (SQRT_CS) | 0.301 | 0.014 | 0.094 | 0.034 | significance-sensitive and functional-subset sensitive |
| Treatment effect on community composition: gower_sqrt_z | 0.497 | 0.001 | 0.001 | 0.001 | not sensitive in tested scenarios |
| Total CAFI abundance in 6-coral reefs vs proportional expectation | -10.891 |  |  |  | not sensitive in tested scenarios |

## Output files

- `species_inclusion_sensitivity_result_summary.csv`: compact sensitivity classification for each result.
- `species_inclusion_sensitivity_result_summary.md`: Markdown version of the compact sensitivity table.
- `species_inclusion_sensitivity_long.csv`: one row per result x inclusion scenario.
- `species_inclusion_sensitivity_functional_subset.csv`: direct whole-community versus obligate/damselfish comparison.
- `species_inclusion_sensitivity_scaling_species.csv`: species-level observed-versus-expected classifications for each scenario.
- `species_inclusion_sensitivity_species_condition.csv`: per-species condition LMMs for each scenario.

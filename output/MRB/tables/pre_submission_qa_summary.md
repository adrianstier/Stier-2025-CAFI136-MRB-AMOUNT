# MRB pre-submission QA summary

Generated: 2026-08-01 11:08:40.226985

## Status counts

- WARN: 3
- PASS: 10

## Checks

- **PASS** `COMPOSITION_INDEX` (composition): Composition robustness index assembled with 4 metric flavors; 5 PERMANOVA rows significant; 3 rows have matching PERMDISP. [output/MRB/tables/composition_robustness_index.csv]
- **PASS** `PERMDISP_DENSITY_PRESENT` (composition): Exact matching PERMDISP for reef per-colony-density distance: F=2.275, p=0.122. [output/MRB/tables/16_permdisp_summary.csv]
- **PASS** `PERM_DENSITY_PRESENT` (composition): Exact reef per-colony-density PERMANOVA present: F=2.013, R2=0.168, p=0.015. [output/MRB/tables/16_permanova_summary.csv]
- **PASS** `SAMPLE_SIZE_SENSITIVITY` (composition): Section 17 rarefaction/bootstrap/N-sensitivity concordance table is present. [output/MRB/tables/section17_concordance_vs_main.csv]
- **PASS** `MANUSCRIPT_STATS_TABLE` (concordance): Compiled manuscript statistical test table is present. [output/MRB/tables/MANUSCRIPT_STATISTICAL_TESTS.csv]
- **PASS** `MRB_README_CURRENT` (documentation): scripts/MRB/README.md points to the current runner/script names. [scripts/MRB/README.md]
- **PASS** `PUBLIC_ANALYSIS_DOCS` (documentation): Public reproducibility, data availability, and figure guide documents are present. [docs/REPRODUCIBILITY_GUIDE.md; docs/DATA_AVAILABILITY.md; docs/FIGURE_GUIDE_FOR_PUBLICATION.md]
- **PASS** `TRAPEZIA_EXPLORATION` (exploratory): Exploratory Trapezia treatment/condition report is present and kept outside the gated manuscript outputs. [output/MRB/exploratory/trapezia/trapezia_exploration_report.md]
- **PASS** `QA_WIRED_IN_RUNNER` (pipeline): run_all.sh invokes scripts/MRB/15.pre_submission_checks.R. [run_all.sh]
- **PASS** `SPECIES_DRIVER_TABLE` (species drivers): Top-15 per-colony-density driver table present; strongest delta is Apataxia cerithiiformis (delta z=1.911). [output/MRB/tables/16_species_density_drivers_top15.csv]
- **WARN** `CLAIM_LEDGER` (future gate): No claims.tsv exists yet. This remains the highest-value next gate for qualitative manuscript claims. [claims.tsv]
- **WARN** `DISPLAY_INDEX` (future gate): No display_items.tsv exists yet. This remains a next-stage gate for figure/table citation hygiene. [display_items.tsv]
- **WARN** `RENV_LOCK` (reproducibility): No renv.lock found; package versions rely on sessionInfo outputs rather than a restorable lockfile. [renv.lock]

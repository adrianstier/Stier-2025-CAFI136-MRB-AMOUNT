# MRB pipeline integration TODO

Created: 2026-07-31

Purpose: convert the Pocillopora pipeline audit into concrete MRB resubmission checks.

## Immediate implementation

- [x] Add an exact PERMDISP diagnostic for the Fig. 3 reef per-colony-density PERMANOVA.
  - Producing script: `scripts/MRB/4d.diversity.R`
  - Outputs: `output/MRB/tables/16_permdisp_summary.csv`, `.html`
- [x] Export the species-driver table behind the Fig. 3 density dumbbell panel.
  - Producing script: `scripts/MRB/4d.diversity.R`
  - Output: `output/MRB/tables/16_species_density_drivers_top15.csv`
- [x] Assemble a consolidated composition-robustness index from the current output tables.
  - Producing script: `scripts/MRB/15.pre_submission_checks.R`
  - Output: `output/MRB/tables/composition_robustness_index.csv`
- [x] Add a pre-submission QA ledger that checks for the density PERMANOVA/PERMDISP pair, composition robustness index, species-driver table, sample-size sensitivity, Trapezia exploration, concordance audit, package-lock status, and future gate gaps.
  - Producing script: `scripts/MRB/15.pre_submission_checks.R`
  - Outputs: `output/MRB/tables/pre_submission_qa_checks.csv`, `pre_submission_qa_summary.md`
- [x] Wire the QA script into `run_all.sh`.
- [x] Add compact `Makefile` entry points for `analysis`, `quick`, `qa`, and `validate`.

## Near-term structural gates

- [ ] Create a true `results_master.csv` by logging load-bearing model results at fit time rather than compiling selected existing CSVs after the fact.
- [ ] Add `claims.tsv` for qualitative assertions that number concordance cannot check.
- [ ] Add `display_items.tsv` for figure/table filenames, driver scripts, manuscript citations, panel letters, and submission tiers.
- [ ] Add vocabulary/causal-verb linting over manuscript prose and code, especially around "feedback", "drive", "enhance", and contemporaneous CAFI-condition associations.
- [ ] Decide whether to add `renv.lock`; currently the repo records package state with `sessionInfo()` outputs but cannot restore exact package versions from a lockfile.

## Optional science additions

- [ ] Add a coverage-standardized Hill-diversity sensitivity if diversity remains a central reviewer concern.
- [ ] Add an all-taxa indicator/SIMPER-style species-driver table if reviewers ask which taxa drive the main composition shift beyond the current top-density-change and PC-loading displays.

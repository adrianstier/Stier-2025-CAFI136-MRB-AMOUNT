# CAFI136 MRB Amount Analysis

Publication-ready analysis: "Habitat Quantity Drives Community Assembly and Feedbacks to Coral Performance." Stier, Primo, Curtis, Osenberg. Archived on Zenodo (DOI: 10.5281/zenodo.18239647).

## Status
Publication-ready. This is an archival repo — edits should preserve reproducibility.

## Manuscript
The manuscript this analysis supports lives on Google Drive (submitted to *Ecology Letters*, 15 Jan 2026):

`~/Library/CloudStorage/GoogleDrive-astier@ucsb.edu/My Drive/Stier Lab/People/Adrian Stier/Projects/In Review/CAFI-1-3-6`

A local symlink `manuscript/` in the repo root points there (git-ignored — the path is machine-specific; recreate with `ln -sfn "<drive path>" manuscript`). Key files:
- `Initial_Submission_1_15_2026/Stier_Osenberg_et_al_CAFI136_main_text_1_15_2026.docx` — main text
- `Initial_Submission_1_15_2026/Stier_Osenberg_et_al_CAFI136_supplement_1_15_2026.docx` — supplement
- `Initial_Submission_1_15_2026/Stier_Osenberg_et_al_CAFI136_CoverLetter_1_15_2026.docx` — cover letter
- `Figure-revisions/` — figure working files

## Structure
- `data/` — Raw and processed data (`MRB Amount/`, `processed/`)
- `scripts/MRB/` — R analysis scripts
- `output/MRB/` — Figures, tables, model outputs
- `docs/` — Publication checklist, figure guide, reproducibility guide
- `archive/python_agents/` — Legacy Python agent code (not active)
- `run_all.sh` — Master script to reproduce all analyses

## Stack
- R (≥4.0) with `.Rproj`
- Shell scripts for automation

## Conventions
- R scripts in `scripts/MRB/` follow numbered naming (sequential pipeline)
- Raw data in `data/` is read-only — never modify
- All outputs go to `output/MRB/`
- `run_all.sh` runs the full pipeline end-to-end

## Reproducibility
- Run `bash run_all.sh` from project root
- Checksums in `data/checksums.txt` verify data integrity
- See `docs/REPRODUCIBILITY_GUIDE.md` for full instructions

## File Ownership (parallel work)
- `scripts/MRB/` — individual R scripts can be edited independently if they don't share intermediate files
- `docs/` — documentation files are independent
- `data/` — READ ONLY, never edit
- `output/` — generated files, safe to regenerate

## Gotchas
- Zenodo archived — any changes should be versioned carefully
- Zero-inflation and PCA assessment docs in `docs/` contain analytical decisions

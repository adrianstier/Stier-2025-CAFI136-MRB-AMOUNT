# CAFI-136 MRB-Amount — Stats ↔ Manuscript Concordance & Reproducibility Audit

*Last updated: 2026-07-31*
*Created: 2026-07-29*
Status: reviewer-readiness Gate 2 (concordance) + Gate 3 (clone-to-figure reproducibility)

Repo: `Stier-2025-CAFI136-MRB-AMOUNT`
Manuscript: *Habitat Quantity Drives Community Assembly and Feedbacks to Coral Performance* (Stier, Primo, Curtis, Osenberg; submitted *Ecology Letters* 2026-01-15).

Scope of this audit: trace headline manuscript numbers to the producing script/CSV and actual computed value; record bootstrap determinism and clone-to-figure checks where run. The 2026-07-31 addendum below is the current reviewer-readiness status. No `.docx` was edited. No commits/pushes were made.

---

## 2026-07-31 reviewer-readiness addendum

This addendum supersedes the older P0 concordance notes below where they conflict with the final 2026-07-30 manuscript package.

### Gate status after the reviewer-readiness run

| Gate | Status | Current evidence |
|---|---|---|
| Gate 1 code hygiene | PARTIAL | The visible worktree is clean after the reviewer-readiness commit, and local manuscript/helper scripts with machine-specific paths are ignored. The main remaining hygiene issue is broader script-surface complexity rather than untracked-path clutter. |
| Gate 2 stats/prose concordance | PARTIAL | The old percentage and species-scaling problems are resolved in `manuscript/Second_Submission/final_resubmission_fixes_render_qa_2026-07-30/main.txt`; the remaining manuscript wording risks are listed below. |
| Gate 3 local reproduction | PASS for working tree | `./run_all.sh` completed in 4m31s and found all expected current outputs; `make qa` passed with 10 PASS / 3 WARN; `Rscript scripts/MRB/validate_pipeline.R` passed after the filtered-growth checksum was updated to the regenerated `sa_scaled_growth` header. |
| Gate 3 clean clone | PASS for the reviewer-readiness commit | A fresh local clone from the committed snapshot ran `./run_all.sh` in 4m07s, found all expected outputs, and passed `Rscript scripts/MRB/validate_pipeline.R`. Regenerated PDFs/HTML are not byte-identical because of render metadata/timestamps, but paths and results regenerate. |
| Gate 4 archive package | PARTIAL | The current revision is now captured in a local Git commit; still needs push/tag/Zenodo refresh, plus no `renv.lock`, no `claims.tsv`, and no `display_items.tsv`. |

### Resolved by the final 2026-07-30 manuscript package

- The main text now reports abundance +447%, species richness +182%, and rarefied richness +35%.
- The significant above-expected 38-species taxa are now `Xanthias lamarckii` and `Mitrella moleculina`; `Morula zebrina` is described as above expected but non-significant.
- Supplement Table S4/final supplement text identify the three significant scaling rows as `Xanthias lamarckii`, `Mitrella moleculina`, and `Dascyllus aruanus`; `Morula zebrina`, `Trapezia serenei`, and `Trapezia tigrina` are non-significant.
- The Fig. 3 density result now has the paired diagnostic: PERMANOVA F=2.013, R2=0.168, p=0.015; matching PERMDISP F=2.275, p=0.122.

### Remaining manuscript/prose issues before resubmission

- Fig. 3 Results line still says "greatest change in relative abundance" for the 15 taxa, but the figure/source table are standardized per-colony density (`output/MRB/tables/16_species_density_drivers_top15.csv`). Change "relative abundance" to "standardized per-colony density".
- Species-condition language should distinguish raw-p nominal associations from corrected significance. `Caracanthus maculatus` remains significant after Hochberg correction (raw p=0.000848, adjusted p=0.01696), while `Luniella pugil` and `Alpheus diadema` are nominally negative but not Hochberg-significant (adjusted p=0.256 and 0.761 in `output/MRB/tables/LMM_species_top20_RAWsqrt_vs_condPC1.csv` / final Table S2). The Results wording is already softer ("associated"), but the Discussion still says they were "significantly negatively associated".
- The Data Accessibility statement says the current code/data are archived on Zenodo/GitHub. The current state is committed locally, but it still needs to be pushed/tagged and re-archived before that statement is fully true.

### Pipeline/documentation changes made on 2026-07-31

- Fixed `scripts/MRB/14.compile-manuscript-statistics.R` by qualifying masked dplyr calls and refreshing Script 8 rows from `LMM_COMM_vs_COND_summary.csv`.
- Updated `run_all.sh` final output checks to current figure paths.
- Updated `README.md`, `docs/REPRODUCIBILITY_GUIDE.md`, and `scripts/MRB/README.md` to remove stale Script 8 p-values/script names and old growth-column wording.
- Updated `data/checksums.txt` for the regenerated `coral_growth_surface_area_change_filtered.csv` header (`sa_scaled_growth`).

### Remaining repo/archive blockers

- Push/tag/archive the reviewer-readiness commit so the current analysis state is available outside this local machine.
- Add a dependency lock (`renv.lock`) or explicitly state that reproducibility relies on `sessionInfo` only.
- Decide whether reviewer-facing archive should include/exclude helper scripts with absolute local paths (`scripts/MRB/build_updated_response_to_reviewers.py`, selected `scripts/MRB/agent_generated/*`) and stale checklist examples.
- Add `claims.tsv` and `display_items.tsv` only if we want a stronger automated manuscript-claim/figure-citation gate; current QA marks them as WARN, not FAIL.

---

## 1. Concordance table (Gate 2)

Legend: ✅ match · 🟡 close / provenance-corrected / needs wording fix · 🔴 mismatch or no provenance.

| # | Claim | Manuscript value | Producing script → object/CSV | Code value | Verdict |
|---|-------|------------------|-------------------------------|------------|---------|
| **Abstract** ||||||
| 1 | CAFI abundance increased fivefold | ~5× | `3.abundance.R` → `community_abundance` (emmeans) 107.6 → 588.3 | 5.47× | ✅ |
| 2 | Species richness doubled | ~2× | `3.abundance.R`/`4d.diversity.R` → `richness_summary` 20.4 → 57.7 | **2.82× (+182%)** | 🔴 nearly *tripled*, not doubled |
| **Results — community scale** ||||||
| 3 | Total community abundance +428% (LR χ²=105.5, df=2, p<0.0001) | 428%; χ²=105.5 | `community_total_abundance_omnibus.csv` (χ²=105.55, df=2, p=1.2e-23); emmeans 107.6→588.3 | χ²=105.5 ✅; increase = **+447%** | test ✅ / **% 🟡 (447 vs 428)** |
| 4 | Species richness +117% (LR χ²=95.2, df=2, p<0.0001) | 117%; χ²=95.2 | `richness_omnibus.csv` (95.15, df=2, p=2.2e-21); emmeans 20.4→57.7 | χ²=95.2 ✅; increase = **+182%** | test ✅ / **% 🔴 (182 vs 117)** |
| 5 | Rarefied richness +19% (F₂,₂₄=4.70, p=0.019) | 19%; F=4.70 | `rarefied_richness_omnibus.csv` (F=4.698, df 2,24, p=0.0190); emmeans 10.32→13.93 | F=4.70 ✅, df ✅, p=0.019 ✅; increase = **+34.9%** | test ✅ / **% 🔴 (35 vs 19)** |
| **Results — species-scaling paragraph** ||||||
| 6 | 38 taxa in inclusion set | 38 | `3.abundance.R` → `scaling_table_38species_1row.csv` | 38 rows | ✅ |
| 7 | 26 (68.4%) above Field-of-Dreams expectation (6-coral) | 26 / 68.4% | `scaling_table_38species_1row.csv` `Direction=="Above"` | 26/38 = 68.4% | ✅ |
| 8 | 2 (5.3%) significant above: **Morula zebrina, Mitrella moleculina** | Morula + Mitrella | `scaling_table_38species_1row.csv` `Significant==TRUE & Above` | 2 species, but = **Xanthias lamarckii, Mitrella moleculina** | 🔴 **wrong species named** — *Morula zebrina* is NOT significant (obs CI overlaps expected); *Xanthias lamarckii* (+400%, p<.05) is |
| 9 | median increase +80%, max +2000% | +80%, +2000% | `scaling_table_38species_1row.csv` `Deviation_pct_t6` (Above) | median 80.0, max 2000 (Pascula muricata) | ✅ |
| 10 | 12 of 38 (31.6%) below expected | 12 / 31.6% | `Direction=="Below"` | 12/38 = 31.6% | ✅ |
| 11 | 1 (2.6%) significant decline: Dascyllus aruanus | Dascyllus aruanus | `Significant==TRUE & Below` | Dascyllus aruanus (only) | ✅ |
| 12 | negatives −14% to −89%, median −45% | −14…−89; −45 | `Deviation_pct_t6` (Below) | min −88.9, max −13.7, median −45.0 | ✅ |
| 13 | 3 of 38 significant vs ~1.9 expected by chance | 3; 1.9 | `Significant==TRUE` count; 0.05×38 | 3 (Xanthias, Mitrella, Dascyllus); 1.9 | ✅ |
| **Results — community composition** ||||||
| 14 | PERMANOVA F₂,₂₀=2.01, R²=0.17, p=0.015 | F=2.01, R²=0.17, p=0.015 | `12.nmds_permanova_cafi.R` → **`16_permanova_summary.csv`, scale "Reef" / "Per-colony density"** | F=2.013, R²=0.168, p=0.015 | ✅ (**provenance corrected**: the per-colony-density PERMANOVA, *not* `06_permanova_gower.csv`, which is F=9.61/R²=0.49/p=0.001 — a different, abundance-scaled variant) |
| **Results — coral condition** ||||||
| 15 | PC1_Coral explains 52.5% variance | 52.5% | `7.coral-physiology.R` `var_exp[1]` (recomputed here) | 0.5252 → 52.5% | ✅ |
| 16 | Condition PC1 treatment effect χ²=8.11, df=2, p=0.017 | 8.11/2/0.017 | `MANUSCRIPT_STATS_TABLE.csv` row "PC1 (physio+growth) by treatment" | χ²=8.11, df=2, p=0.017 | ✅ |
| **Results — CAFI → condition feedback** ||||||
| 17 | β=0.29, 95% CI [0.004, 0.58], χ²₁=4.20, p=0.040 | 0.29 / [0.004,0.58] / 4.20 / 0.040 | `LMM_condPC1_on_commPC1_fixed_effects.csv` (est=0.2904, CI 0.0038–0.5771) + `LMM_condPC1_on_commPC1_AnovaTypeIII.csv` (χ²=4.2006, p=0.0404) | all match | ✅ (β/CI from summary; χ²/p from Type-III Anova) |
| 18 | Hellinger β=0.31, p=0.008 | 0.31 / 0.008 | `LMM_HELLINGER_fixed.csv` (est=0.3112, p=0.00784) | 0.31 / 0.008 | ✅ |
| **Methods** ||||||
| 19 | Allometric interaction LRT χ²=5.23, df=2, p=0.073 | 5.23/2/0.073 | `MANUSCRIPT_STATS_TABLE.csv` "Model comparison: Interaction vs Parallel" (`6.coral-growth.R`) | χ²=5.231, df=2, p=0.073 | ✅ |
| 20 | Allometric exponent b=0.6986 | 0.6986 | `6.coral-growth.R` unified model → `MANUSCRIPT_STATS_TABLE.csv` | b=0.6986 | ✅ |
| 21 | 54 colonies | 54 | `data/MRB Amount/coral_id_position_treatment.csv` = 54 rows (stocked total) | 54 stocked; **growth analysis N = 44** after ≥80%-alive filter (`coral_growth.csv`, `keep_ids`) | 🟡 54 = total stocked ✅; but every model runs on **44** — make sure the text distinguishes "54 stocked" from "44 analyzed" |
| 22 | 38 species = observed on ≥10 colonies AND total abundance >10 | ≥10 colonies & >10 indiv | `3.abundance.R` `PREV_MIN_SCALING=10`, `ABUND_MIN_SCALING=10` (both `>=`) | prevalence ≥10 AND total_abundance ≥10 | ✅ (code uses **≥10** for abundance, text says **>10**; immaterial — prevalence ≥10 ⇒ abundance ≥10) |
| **Fig 6 / Discussion taxa signs** (slope of species abundance vs condition PC1) ||||||
| 23a | Caracanthus maculatus + | + | `LMM_species_top20_RAWsqrt_vs_condPC1.csv` | +1.422, p=8.5e-4 (sig +) | ✅ |
| 23b | Alpheus diadema − | − | `LMM_species_top20_RAWsqrt_vs_condPC1.csv` | −0.995, p=0.042 (sig −) | ✅ |
| 23c | Luniella pugil − | − | `species_LMMs_rawAbund_vs_condPC1.csv` | −0.541, p=0.022 (sig −) | ✅ |
| 23d | Calcinus latens + (ns) | + ns | `species_LMMs_rawAbund_vs_condPC1.csv` | +0.126, p=0.109 | ✅ |
| 23e | Harpiliopsis spinigera + (ns) | + ns | `species_LMMs_rawAbund_vs_condPC1.csv` | +0.084, p=0.198 | ✅ |
| 23f | Dascyllus flavicaudus + (ns) | + ns | `species_LMMs_rawAbund_vs_condPC1.csv` | +0.117, p=0.145 | ✅ |

### The observed treatment means behind rows 2–5 (from `output/MRB/objects/mrb_comm_summaries.rds`)

| Metric | 1-coral | 3-coral | 6-coral | 1→6 change (code) | Manuscript |
|--------|--------:|--------:|--------:|------------------:|-----------|
| Total community abundance | 107.56 | 307.50 | 588.33 | **+447% (5.47×)** | +428% / "fivefold" |
| Species richness | 20.44 | 38.33 | 57.67 | **+182% (2.82×)** | +117% / "doubled" |
| Rarefied richness | 10.32 | 12.59 | 13.93 | **+34.9%** | +19% |

Every **test statistic** (χ², F, df, p) matches the code exactly. The three **percent-increase magnitudes** in the abstract/results do not reproduce from the current data (they are neither the observed nor the model-predicted 1→6 change; they appear nowhere in the scripts or output). They read like values carried over from an earlier data cut. **Adrian must reconcile these three percentages** (and the "doubled" wording) against the current means above, or clarify what quantity they represent.

---

## 2. Reproducibility (Gate 3)

### 2a. Bootstrap determinism — PASS
`3.abundance.R` was run **twice from fresh `Rscript` sessions** (each a clean R process). All bootstrap-derived outputs were byte-identical across runs:

- `scaling38_observed_vs_expected_all.csv` — `diff` returned identical.
- `scaling_table_38species_1row.csv` — `diff` returned identical.
- NP-expected **richness** band: k=3 median 35 [22, 50]; k=6 median 47 [32, 59] — identical both runs.
- NP-expected **rarefied** band: k=3 median 10.8 [8.5, 15]; k=6 median 11.2 [9.2, 14] — identical both runs.

Seeds are correctly placed: `set.seed(1234)` at the top, `set.seed(params$seed)` before each bootstrap block, and every helper (`np_sum_ci`, `np_richness_ci`, `np_rarefied_ci`) receives `seed = params$seed` (B = 10000). **No seed fix was needed.**

### 2b. Clone-to-figure — FIXED (was broken in 4 places)
`git clone --depth 1 file://$HOME/... /tmp/cafi_repro_clone` then `bash run_all.sh`. A fresh clone contains all raw data (`data/MRB Amount/*`, `data/processed/coral_growth.csv`); the `manuscript/` symlink and `*.rds` caches are git-ignored but not required (`utils.R` rebuilds `cafi_data.rds` from raw when absent). Four blockers were hit and fixed; each was reached only after the previous fix let the pipeline advance:

1. **`4d.diversity.R` §17D — dplyr data-masking crash (halted the whole pipeline).**
   `dplyr::summarise(technique = label, …)` where `label` is *also a column* in `res_rare`/`res_boot` (added by `.run_perms_one`). Under dplyr ≥1.1 (here 1.2.1) the bare `label` resolves to the length-199 column, not the scalar argument → `` `technique` must be size 1, not 199 ``. **Fix:** `technique = .env$label` (forces the scalar argument; label-only, no statistical change).

2. **`run_all.sh` run-order bug — 12 depends on 7 but ran before it.**
   `12.nmds_permanova_cafi.R` reads `output/MRB/figures/coral/physio/physio_metrics_plus_growth_filtered.csv`, which is *written by* `7.coral-physiology.R`. That file is git-ignored (under `output/MRB/figures/**/`), so on a fresh clone it does not exist when `run_all.sh` ran 12 (step 2) before 7 (step 4) → `Error: Missing physio file`. **Fix:** moved the `12.nmds` call to run *after* `7.coral-physiology.R` (reorder only; no statistical change).

3. **`12.nmds_permanova_cafi.R` — unqualified `glue()`.**
   Lines 191–192 called bare `glue(...)` in `labs()`, but `glue` is never attached (`1.libraries.R` does not `library(glue)`); line 201 already used `glue::glue`. Under a clean `Rscript` → `could not find function "glue"`. **Fix:** qualified both to `glue::glue(...)` (identical text; no figure-content change).

4. **`8.coral-caffi.R` §7.7 — same dplyr summarise-size crash (halted Fig5/Fig6 script).**
   Line ~2663 `dplyr::summarise(line = paste0(trait, ": ", …))` inside `group_by(trait)`: the bare grouping column `trait` is length = group size (2), so `line` is size 2 → `` `line` must be size 1 `` under dplyr ≥1.1. The parallel block 40 lines above already used `unique(trait)`. **Fix:** `paste0(unique(trait), …)` (copy/paste report text only; no statistical result or figure change).

After all four fixes the pipeline runs end-to-end from the fresh clone (verified stage-by-stage: 3→4d→5→6→7→12→8→14 all exit 0). All six manuscript figures regenerate:
Fig1 `three_panel_nonparametric`, Fig2 `focal_order_species_np`, Fig3 `16_horizontal_2panel_nmds_prop_plus_top15_density` + `06_nmds`, Fig4 `pc1_loadings_and_scores_paired`, Fig5 `PCA_LOADINGS_RAW_2panel_clean`, Fig6 `species_faceted_LMM_lines_rawX_sqrtAxis`, plus `MANUSCRIPT_STATISTICAL_TESTS.csv` and the community/PERMANOVA/LMM CSVs.

### 2b-CRITICAL. A fresh clone TODAY reproduces the OLD figures, not the current manuscript figures

`git clone` copies only **committed** state (HEAD). Six files in the working tree are **uncommitted**, and they include not just the 4 reproducibility fixes below but Adrian's entire in-progress R1 figure/analysis revision:

- `scripts/MRB/3.abundance.R` — 38-species scaling reconciliation (replaces the old "top-30" selection), rarefied-richness Field-of-Dreams band, PhyloPic silhouettes, axis relabels ("… per reef") — comments tag it `R1 revision (Osenberg #C59 / Curtis #J58)`.
- `scripts/MRB/mrb_figure_standards.R` — new treatment palette (`#440154/#31688E/#5DC863`) — `Curtis #J61`.
- `scripts/MRB/8.coral-caffi.R` — Fig 5 taxon-silhouette key + Fig 6 per-panel silhouettes + layout — `Joe #J64/#1223/#1224`.
- `scripts/MRB/4d.diversity.R` — Fig 3B Panel-B monotonic reorder — `Curtis #J63`.
- (plus `12.nmds_permanova_cafi.R`, `run_all.sh` — the fixes below.)

**Consequence:** until these are committed, a stranger who clones the repo runs the *previous* code cut — old palette, top-30 (not 38-species) scaling, no rarefied band — so the regenerated figures will NOT match the current submission. The determinism/concordance results in this audit were produced by running the **working tree** (current code), which is correct; but the clone-to-figure guarantee only holds once the working tree is committed. **This is the single most important reproducibility action: `git add -A scripts/ run_all.sh && git commit` (Adrian's call on message/scope), then re-run the clone test.**

### 2c. Path portability — PASS
No absolute local-home paths and no working-directory mutation calls in any script (pre-verified). Scripts use `here::here()` / relative paths and `cd "$(dirname "$0")"` in `run_all.sh`. The only machine-specific path is the git-ignored `manuscript/` symlink, which is not on the analysis path.

### 2d. Raw data for every figure — PASS
All inputs each figure needs are git-tracked under `data/` (`git ls-files data/` = raw CAFI/fish/physio/photogram CSVs + `data/processed/coral_growth.csv`). Intermediate `*.rds` caches and `output/MRB/figures/**` products are git-ignored but are all regenerated by `run_all.sh`. No figure depends on an untracked raw input.

---

## 3. Fix list

### Fixed in this pass (safe; no statistical result or figure content changed)
1. `scripts/MRB/4d.diversity.R` — `technique = label` → `technique = .env$label` (§17D `.summarise_iter_tbl`). Verified: `4d.diversity.R` now exits 0.
2. `run_all.sh` — moved `12.nmds_permanova_cafi.R` to run after `7.coral-physiology.R` (with a `QUICK_MODE` guard preserved). Verified in clone.
3. `scripts/MRB/12.nmds_permanova_cafi.R` — bare `glue()` → `glue::glue()` (lines 191–192). Verified in clone.

These fixes (4d.diversity `.env$label`; 8.coral-caffi `unique(trait)`; 12.nmds `glue::glue()`; run_all.sh reorder) are edited but **not committed** (per instruction). Each is a namespace/scalar/run-order fix only — no statistical result or figure content changed. They must be committed (together with Adrian's uncommitted R1 revision work — see §2b-CRITICAL) for a genuine fresh clone to reproduce the current figures; until then `bash run_all.sh` from a clean `git clone` fails at the diversity step.

### Needs Adrian (manuscript text — cannot fix in `.docx`)
- **P0 — Species-scaling significant species (row 8).** Text names *Morula zebrina* as a significant above-expected species; the code's significant above-expected species are **Xanthias lamarckii** and *Mitrella moleculina*. *Morula zebrina* tests Proportional (obs CI overlaps expected). Replace *Morula zebrina* → *Xanthias lamarckii*.
- **P0 — Percent-increase magnitudes (rows 2, 4, 5).** Richness "doubled"/"+117%" vs observed **+182% (2.82×)**; rarefied "+19%" vs **+35%**; abundance "+428%" vs **+447%**. Test statistics are all correct; only the % magnitudes are off and have no code provenance. Update to the observed values above (or state the intended quantity).
- **P1 — PERMANOVA provenance (row 14).** The reported F=2.01/R²=0.17/p=0.015 is the **per-colony-density** PERMANOVA (`16_permanova_summary.csv`), not the Gower abundance PERMANOVA (`06_permanova_gower.csv` = F=9.61/R²=0.49/p=0.001). Confirm the Methods describe the per-colony-density distance so a reader lands on the right table.
- **P2 — "54 colonies" (row 21).** 54 = colonies stocked; every model runs on **44** (≥80%-alive filter). Make the text distinguish stocked vs analyzed N.
- **P3 — filter wording (row 22).** Text says "total abundance >10"; code uses **≥10**. Immaterial to the 38-species set, but align the symbol if precise.

---

## 4. What was NOT done
- No `.docx` edited, no git commit/push (per instruction).
- Manuscript claims were traced against the provided claim text + the committed/regenerated CSVs; the live `Ecology Letters` `.docx` on Google Drive was not re-opened. Where the code contradicts the provided claim (rows 2, 4, 5, 8), Adrian should confirm against the current submission text.

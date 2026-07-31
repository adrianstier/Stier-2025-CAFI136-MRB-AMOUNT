#!/usr/bin/env Rscript
# ==============================================================================
# MRB Analysis Script 15: Pre-submission pipeline checks
# ==============================================================================
# Purpose:
#   Consolidate the submission-facing checks that keep the analysis, figures,
#   supplement, and manuscript claims from drifting apart during revision.
#
# This is intentionally lightweight: it checks for the outputs that already exist
# in this repository, writes a machine-readable QA ledger, and warns about larger
# Pocillopora-style gates that are not yet implemented here.
#
# Inputs: output/MRB/tables/*.csv, docs/*.md, run_all.sh
# Outputs:
#   output/MRB/tables/composition_robustness_index.csv
#   output/MRB/tables/pre_submission_qa_checks.csv
#   output/MRB/tables/pre_submission_qa_summary.md
# ==============================================================================

source("scripts/MRB/1.libraries.R")
source("scripts/MRB/utils.R")

options(stringsAsFactors = FALSE, scipen = 999, readr.show_col_types = FALSE)

TAB_DIR <- here::here("output", "MRB", "tables")
DOC_DIR <- here::here("docs")
dir.create(TAB_DIR, recursive = TRUE, showWarnings = FALSE)

status_rank <- c(PASS = 0L, WARN = 1L, FAIL = 2L)
qa_rows <- list()

fmt_p <- function(p) {
  if (length(p) == 0 || is.na(p)) return("NA")
  if (p < 0.001) return("<0.001")
  sprintf("%.3f", p)
}

exists_nonempty <- function(path) {
  file.exists(path) && isTRUE(file.info(path)$size > 0)
}

relative_evidence_path <- function(path) {
  if (length(path) == 0 || is.na(path) || !nzchar(path)) return(NA_character_)
  root <- normalizePath(here::here(), winslash = "/", mustWork = TRUE)
  norm <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(root, "/")
  if (startsWith(norm, prefix)) {
    return(substring(norm, nchar(prefix) + 1L))
  }
  path
}

read_csv_if_exists <- function(path) {
  if (!exists_nonempty(path)) return(tibble::tibble())
  suppressMessages(readr::read_csv(path, show_col_types = FALSE))
}

add_check <- function(check_id, area, status, message, evidence_file = NA_character_) {
  stopifnot(status %in% names(status_rank))
  qa_rows[[length(qa_rows) + 1L]] <<- tibble::tibble(
    check_id = check_id,
    area = area,
    status = status,
    message = message,
    evidence_file = relative_evidence_path(evidence_file)
  )
}

canon_metric <- function(x) {
  lx <- tolower(trimws(as.character(x)))
  dplyr::case_when(
    grepl("jaccard|incidence", lx) ~ "Jaccard incidence",
    grepl("per-colony|density", lx) ~ "Gower sqrt per-colony density",
    grepl("proportion|prop", lx) ~ "Gower proportional composition",
    grepl("gower|sqrt|abundance", lx) ~ "Gower sqrt abundance",
    TRUE ~ as.character(x)
  )
}

# ------------------------------------------------------------------------------
# 1) Build a consolidated composition-robustness index from existing outputs
# ------------------------------------------------------------------------------
perm14_path <- file.path(TAB_DIR, "14_permanova_summary.csv")
perm16_path <- file.path(TAB_DIR, "16_permanova_summary.csv")
disp16_path <- file.path(TAB_DIR, "16_permdisp_summary.csv")
conc17_path <- file.path(TAB_DIR, "section17_concordance_vs_main.csv")

perm14 <- read_csv_if_exists(perm14_path)
perm16 <- read_csv_if_exists(perm16_path)
disp16 <- read_csv_if_exists(disp16_path)
conc17 <- read_csv_if_exists(conc17_path)

comp_rows <- list()

if (nrow(perm14)) {
  comp_rows[[length(comp_rows) + 1L]] <- perm14 |>
    dplyr::filter(grepl("^Reef", .data$Level)) |>
    dplyr::transmute(
      source = "§14 unit-correct reef PERMANOVA",
      scale = .data$Level,
      metric = canon_metric(.data$Metric),
      test = "PERMANOVA",
      F = suppressWarnings(as.numeric(.data$F)),
      R2 = suppressWarnings(as.numeric(.data$R2)),
      p = suppressWarnings(as.numeric(.data$p)),
      permdisp_p = NA_real_,
      sensitivity_prop_sig = NA_real_,
      evidence_file = perm14_path
    )
}

if (nrow(perm16)) {
  comp16 <- perm16 |>
    dplyr::filter(.data$scale == "Reef") |>
    dplyr::transmute(
      source = "§16 reef Gower/density PERMANOVA",
      scale = .data$scale,
      metric = canon_metric(.data$flavor),
      flavor = .data$flavor,
      test = "PERMANOVA",
      F = suppressWarnings(as.numeric(.data$F)),
      R2 = suppressWarnings(as.numeric(.data$R2)),
      p = suppressWarnings(as.numeric(.data$p)),
      evidence_file = perm16_path
    )
  if (nrow(disp16)) {
    disp16_reduced <- disp16 |>
      dplyr::filter(.data$scale == "Reef") |>
      dplyr::transmute(
        flavor = .data$flavor,
        permdisp_F = suppressWarnings(as.numeric(.data$F)),
        permdisp_p = suppressWarnings(as.numeric(.data$p))
      )
    comp16 <- comp16 |>
      dplyr::left_join(disp16_reduced, by = "flavor")
  } else {
    comp16$permdisp_F <- NA_real_
    comp16$permdisp_p <- NA_real_
  }
  comp_rows[[length(comp_rows) + 1L]] <- comp16 |>
    dplyr::select(-flavor) |>
    dplyr::mutate(sensitivity_prop_sig = NA_real_)
}

composition_index <- dplyr::bind_rows(comp_rows)

if (nrow(conc17) && nrow(composition_index)) {
  conc17_reduced <- conc17 |>
    dplyr::transmute(
      metric = canon_metric(.data$metric),
      technique = .data$technique,
      sensitivity_prop_sig = suppressWarnings(as.numeric(.data$prop_p_lt_0.05))
    )
  sensitivity_rollup <- conc17_reduced |>
    dplyr::group_by(.data$metric) |>
    dplyr::summarise(
      sensitivity_prop_sig = max(.data$sensitivity_prop_sig, na.rm = TRUE),
      sensitivity_methods = paste(unique(.data$technique), collapse = "; "),
      .groups = "drop"
    )
  composition_index <- composition_index |>
    dplyr::left_join(sensitivity_rollup, by = "metric", suffix = c("", "_rollup")) |>
    dplyr::mutate(
      sensitivity_prop_sig = dplyr::coalesce(.data$sensitivity_prop_sig_rollup, .data$sensitivity_prop_sig),
      sensitivity_methods = dplyr::coalesce(.data$sensitivity_methods, NA_character_)
    ) |>
    dplyr::select(-dplyr::any_of("sensitivity_prop_sig_rollup"))
}

if (nrow(composition_index)) {
  composition_index <- composition_index |>
    dplyr::mutate(
      evidence_file = vapply(.data$evidence_file, relative_evidence_path, character(1)),
      permanova_significant = !is.na(.data$p) & .data$p < 0.05,
      dispersion_caution = !is.na(.data$permdisp_p) & .data$permdisp_p < 0.05
    )
  readr::write_csv(composition_index, file.path(TAB_DIR, "composition_robustness_index.csv"))
}

# ------------------------------------------------------------------------------
# 2) QA checks
# ------------------------------------------------------------------------------
density_perm <- if (nrow(perm16)) {
  perm16 |> dplyr::filter(.data$scale == "Reef", .data$flavor == "Per-colony density")
} else tibble::tibble()
density_disp <- if (nrow(disp16)) {
  disp16 |> dplyr::filter(.data$scale == "Reef", .data$flavor == "Per-colony density")
} else tibble::tibble()

if (nrow(density_perm) == 1L) {
  add_check(
    "PERM_DENSITY_PRESENT", "composition",
    "PASS",
    sprintf("Exact reef per-colony-density PERMANOVA present: F=%.3f, R2=%.3f, p=%s.",
            density_perm$F[1], density_perm$R2[1], fmt_p(density_perm$p[1])),
    perm16_path
  )
} else {
  add_check("PERM_DENSITY_PRESENT", "composition", "FAIL",
            "Missing exact reef per-colony-density PERMANOVA row.", perm16_path)
}

if (nrow(density_disp) == 1L) {
  status <- if (is.na(density_disp$p[1]) || density_disp$p[1] >= 0.05) "PASS" else "WARN"
  add_check(
    "PERMDISP_DENSITY_PRESENT", "composition",
    status,
    sprintf("Exact matching PERMDISP for reef per-colony-density distance: F=%.3f, p=%s.",
            density_disp$F[1], fmt_p(density_disp$p[1])),
    disp16_path
  )
} else {
  add_check("PERMDISP_DENSITY_PRESENT", "composition", "FAIL",
            "Missing exact PERMDISP row for the reef per-colony-density distance.", disp16_path)
}

if (nrow(composition_index)) {
  n_metrics <- dplyr::n_distinct(composition_index$metric)
  n_sig <- sum(composition_index$permanova_significant, na.rm = TRUE)
  n_disp <- sum(!is.na(composition_index$permdisp_p))
  add_check(
    "COMPOSITION_INDEX", "composition",
    if (n_metrics >= 4 && n_disp >= 3) "PASS" else "WARN",
    sprintf("Composition robustness index assembled with %d metric flavors; %d PERMANOVA rows significant; %d rows have matching PERMDISP.",
            n_metrics, n_sig, n_disp),
    file.path(TAB_DIR, "composition_robustness_index.csv")
  )
} else {
  add_check("COMPOSITION_INDEX", "composition", "FAIL",
            "Could not assemble composition robustness index from existing outputs.",
            file.path(TAB_DIR, "composition_robustness_index.csv"))
}

driver_path <- file.path(TAB_DIR, "16_species_density_drivers_top15.csv")
drivers <- read_csv_if_exists(driver_path)
if (nrow(drivers) >= 15L) {
  top_driver <- drivers |> dplyr::arrange(.data$rank_by_abs_change) |> dplyr::slice(1)
  add_check(
    "SPECIES_DRIVER_TABLE", "species drivers", "PASS",
    sprintf("Top-15 per-colony-density driver table present; strongest delta is %s (delta z=%.3f).",
            top_driver$species[1], top_driver$delta_z_6_minus_1[1]),
    driver_path
  )
} else {
  add_check("SPECIES_DRIVER_TABLE", "species drivers", "WARN",
            "Top-15 per-colony-density driver table missing or has fewer than 15 rows.", driver_path)
}

if (exists_nonempty(conc17_path)) {
  add_check("SAMPLE_SIZE_SENSITIVITY", "composition", "PASS",
            "Section 17 rarefaction/bootstrap/N-sensitivity concordance table is present.",
            conc17_path)
} else {
  add_check("SAMPLE_SIZE_SENSITIVITY", "composition", "WARN",
            "Section 17 sensitivity concordance table is missing.", conc17_path)
}

trapezia_report <- here::here("output", "MRB", "exploratory", "trapezia", "trapezia_exploration_report.md")
if (exists_nonempty(trapezia_report)) {
  add_check("TRAPEZIA_EXPLORATION", "exploratory", "PASS",
            "Exploratory Trapezia treatment/condition report is present and kept outside the gated manuscript outputs.",
            trapezia_report)
} else {
  add_check("TRAPEZIA_EXPLORATION", "exploratory", "WARN",
            "Exploratory Trapezia report not found; run scripts/MRB/exploratory_trapezia_analysis.R if this remains part of the response package.",
            trapezia_report)
}

stats_table <- file.path(TAB_DIR, "MANUSCRIPT_STATISTICAL_TESTS.csv")
if (exists_nonempty(stats_table)) {
  add_check("MANUSCRIPT_STATS_TABLE", "concordance", "PASS",
            "Compiled manuscript statistical test table is present.", stats_table)
} else {
  add_check("MANUSCRIPT_STATS_TABLE", "concordance", "FAIL",
            "Compiled manuscript statistical test table is missing.", stats_table)
}

concordance_doc <- file.path(DOC_DIR, "CONCORDANCE_AUDIT.md")
if (exists_nonempty(concordance_doc)) {
  add_check("CONCORDANCE_AUDIT_DOC", "concordance", "PASS",
            "Manual concordance audit document is present.", concordance_doc)
} else {
  add_check("CONCORDANCE_AUDIT_DOC", "concordance", "WARN",
            "Manual concordance audit document is missing.", concordance_doc)
}

if (exists_nonempty(here::here("renv.lock"))) {
  add_check("RENV_LOCK", "reproducibility", "PASS",
            "renv.lock present for package-version capture.", here::here("renv.lock"))
} else {
  add_check("RENV_LOCK", "reproducibility", "WARN",
            "No renv.lock found; package versions rely on sessionInfo outputs rather than a restorable lockfile.",
            here::here("renv.lock"))
}

runner_text <- if (exists_nonempty(here::here("run_all.sh"))) {
  paste(readLines(here::here("run_all.sh"), warn = FALSE), collapse = "\n")
} else ""
if (grepl("15.pre_submission_checks.R", runner_text, fixed = TRUE)) {
  add_check("QA_WIRED_IN_RUNNER", "pipeline", "PASS",
            "run_all.sh invokes scripts/MRB/15.pre_submission_checks.R.",
            here::here("run_all.sh"))
} else {
  add_check("QA_WIRED_IN_RUNNER", "pipeline", "FAIL",
            "run_all.sh does not invoke scripts/MRB/15.pre_submission_checks.R.",
            here::here("run_all.sh"))
}

readme_path <- here::here("scripts", "MRB", "README.md")
readme_text <- if (exists_nonempty(readme_path)) paste(readLines(readme_path, warn = FALSE), collapse = "\n") else ""
if (grepl("scripts/run_all_analyses.R|4\\.diversity\\.R|6\\.coral\\.R", readme_text)) {
  add_check("MRB_README_CURRENT", "documentation", "WARN",
            "scripts/MRB/README.md still contains legacy runner/script names.",
            readme_path)
} else {
  add_check("MRB_README_CURRENT", "documentation", "PASS",
            "scripts/MRB/README.md points to the current runner/script names.",
            readme_path)
}

if (exists_nonempty(here::here("claims.tsv"))) {
  add_check("CLAIM_LEDGER", "future gate", "PASS",
            "Claim ledger present.", here::here("claims.tsv"))
} else {
  add_check("CLAIM_LEDGER", "future gate", "WARN",
            "No claims.tsv exists yet. This remains the highest-value next gate for qualitative manuscript claims.",
            here::here("claims.tsv"))
}

if (exists_nonempty(here::here("display_items.tsv"))) {
  add_check("DISPLAY_INDEX", "future gate", "PASS",
            "Display-item index present.", here::here("display_items.tsv"))
} else {
  add_check("DISPLAY_INDEX", "future gate", "WARN",
            "No display_items.tsv exists yet. This remains a next-stage gate for figure/table citation hygiene.",
            here::here("display_items.tsv"))
}

qa <- dplyr::bind_rows(qa_rows) |>
  dplyr::mutate(status_rank = unname(status_rank[.data$status])) |>
  dplyr::arrange(.data$status_rank, .data$area, .data$check_id) |>
  dplyr::select(-status_rank)

readr::write_csv(qa, file.path(TAB_DIR, "pre_submission_qa_checks.csv"))

summary_counts <- qa |>
  dplyr::count(.data$status, name = "n") |>
  dplyr::mutate(status = factor(.data$status, levels = c("FAIL", "WARN", "PASS"))) |>
  dplyr::arrange(.data$status)

summary_lines <- c(
  "# MRB pre-submission QA summary",
  "",
  paste0("Generated: ", Sys.time()),
  "",
  "## Status counts",
  "",
  paste0("- ", summary_counts$status, ": ", summary_counts$n),
  "",
  "## Checks",
  ""
)

detail_lines <- paste0(
  "- **", qa$status, "** `", qa$check_id, "` (", qa$area, "): ",
  qa$message,
  ifelse(is.na(qa$evidence_file), "", paste0(" [", qa$evidence_file, "]"))
)

writeLines(c(summary_lines, detail_lines), file.path(TAB_DIR, "pre_submission_qa_summary.md"))

cli::cli_h1("Pre-submission QA checks")
print(summary_counts)
cat("\n")
print(qa, n = Inf)

if (any(qa$status == "FAIL")) {
  stop("Pre-submission QA failed: see output/MRB/tables/pre_submission_qa_checks.csv")
}

cli::cli_alert_success("Pre-submission QA completed with no FAIL checks.")

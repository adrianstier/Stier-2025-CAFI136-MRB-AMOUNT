# ==============================================================================
# File:    13.SLOSS.R
# Purpose: SLOSS (Single Large vs Several Small) comparison via resampling.
#          Compares expected pooled richness (and Shannon) for k corals sampled
#          within one reef (SL) vs across reefs (SS), using the 10×10 species set.
#
# Depends on objects & helpers defined in 4d.diversity.R:
#   species_only_df, mat_coral_abund, meta_coral, .kept_species
#   FIG_DIR, TAB_DIR, cols_trt, theme_pub(), show_and_save(), save_both()
# ==============================================================================

# Source libraries, utilities, and figure standards
source("scripts/MRB/1.libraries.R")
source("scripts/MRB/utils.R")
source("scripts/MRB/mrb_figure_standards.R")  # For colors, themes, save functions


cli::cli_h1("§12 — SLOSS: Single Large vs Several Small")

# ---- 12.0 Guards -------------------------------------------------------------
.required <- c("species_only_df","mat_coral_abund","meta_coral",
               ".kept_species","FIG_DIR","TAB_DIR","theme_pub","show_and_save")
if (!all(vapply(.required, exists, logical(1)))) {
  stop("§12 requires: ", paste(.required, collapse = ", "),
       "\nRun §1–§3 and the 10×10 filter first.")
}

set.seed(123)
meta_coral <- meta_coral %>%
  dplyr::mutate(
    treatment = factor(treatment, levels = c(1,3,6)),
    reef      = factor(reef)
  )

# Presence/absence long table (10×10 species only)
pa_long <- species_only_df %>%
  dplyr::filter(species %in% .kept_species) %>%
  dplyr::mutate(pa = as.integer(count > 0)) %>%
  dplyr::select(coral_id, reef, treatment, species, pa) %>%
  dplyr::distinct()

# Convenience indices
corals_by_reef <- split(meta_coral$coral_id, meta_coral$reef)
n_per_reef     <- vapply(corals_by_reef, length, integer(1))
reefs          <- names(corals_by_reef)

# Max k we can sample *within a single reef* without replacement (SL design)
K_MAX <- max(n_per_reef, na.rm = TRUE)
cli::cli_alert_info("Max k for SL within-reef sampling (no replacement): {K_MAX}")

# =============================================================================
# §12.1 Helpers: pooled diversity for a set of corals
# =============================================================================

# Return pooled presence/absence vector for a vector of coral_ids
pooled_pa_vec <- function(coral_ids) {
  # join and collapse to species × presence
  pa_long %>%
    dplyr::filter(coral_id %in% coral_ids) %>%
    dplyr::group_by(species) %>%
    dplyr::summarise(pa = as.integer(any(pa > 0)), .groups = "drop") %>%
    dplyr::pull(pa)
}

# Pooled abundance vector (sum across corals) — for Shannon
pooled_abund_vec <- function(coral_ids) {
  species_only_df %>%
    dplyr::filter(species %in% .kept_species, coral_id %in% coral_ids) %>%
    dplyr::group_by(species) %>%
    dplyr::summarise(abund = sum(count, na.rm = TRUE), .groups = "drop") %>%
    dplyr::pull(abund)
}

# Compute richness & Shannon for a set of corals
pool_div <- function(coral_ids) {
  pa <- pooled_pa_vec(coral_ids)
  ab <- pooled_abund_vec(coral_ids)
  tibble::tibble(
    richness = sum(pa, na.rm = TRUE),
    shannon  = vegan::diversity(ab, index = "shannon")
  )
}

# =============================================================================
# §12.2 Resampling designs
#   SL (Single Large): pick 1 reef with ≥ k corals; sample k corals within it.
#   SS (Several Small): sample k distinct reefs, 1 coral per reef (if a reef has
#                       0 corals, it won't be in meta; we guard for availability).
# Notes:
#   - No replacement within a reef; reefs sampled without replacement for SS.
#   - Repeat B iterations to estimate expectation and uncertainty.
# =============================================================================

B <- 499L                           # iterations per k per design
K <- seq.int(1, K_MAX)              # k values
set.seed(42)

draw_SL <- function(k) {
  # eligible reefs with at least k corals
  elig <- names(n_per_reef)[n_per_reef >= k]
  if (!length(elig)) return(NULL)
  r  <- sample(elig, size = 1)
  cs <- sample(corals_by_reef[[r]], size = k, replace = FALSE)
  list(reef = r, corals = cs)
}

draw_SS <- function(k) {
  # need k distinct reefs that each have at least 1 coral
  if (length(reefs) < k) return(NULL)
  r_pick <- sample(reefs, size = k, replace = TRUE)   # allow repeats if many reefs have 1 coral
  # ensure distinct reefs if possible
  if (length(unique(reefs)) >= k) r_pick <- sample(reefs, size = k, replace = FALSE)
  cs <- unlist(Map(function(r) sample(corals_by_reef[[r]], size = 1), r_pick), use.names = FALSE)
  list(reefs = r_pick, corals = cs)
}

# =============================================================================
# §12.3 Main loop
# =============================================================================

res_list <- vector("list", length(K) * 2L)
ix <- 0L

progress <- requireNamespace("cli", quietly = TRUE)

for (k in K) {
  if (progress) cli::cli_alert_info("k = {k} / {max(K)}")
  # ---- SL draws ----
  sl_tbl <- vector("list", B); b_ok <- 0L
  for (b in seq_len(B)) {
    dr <- draw_SL(k)
    if (is.null(dr)) next
    dv <- pool_div(dr$corals) %>% dplyr::mutate(k = k, design = "SL")
    b_ok <- b_ok + 1L; sl_tbl[[b_ok]] <- dv
  }
  sl_tbl <- if (b_ok) dplyr::bind_rows(sl_tbl[seq_len(b_ok)]) else tibble::tibble()
  
  # ---- SS draws ----
  ss_tbl <- vector("list", B); b_ok <- 0L
  for (b in seq_len(B)) {
    dr <- draw_SS(k)
    if (is.null(dr)) next
    dv <- pool_div(dr$corals) %>% dplyr::mutate(k = k, design = "SS")
    b_ok <- b_ok + 1L; ss_tbl[[b_ok]] <- dv
  }
  ss_tbl <- if (b_ok) dplyr::bind_rows(ss_tbl[seq_len(b_ok)]) else tibble::tibble()
  
  # collect
  ix <- ix + 1L; res_list[[ix]] <- sl_tbl
  ix <- ix + 1L; res_list[[ix]] <- ss_tbl
}

res <- dplyr::bind_rows(res_list) %>%
  dplyr::filter(is.finite(richness), is.finite(shannon))

if (!nrow(res)) stop("§12: No valid resamples produced. Check inputs.")

readr::write_csv(res, file.path(TAB_DIR, "12_sloss_resamples.csv"))
cli::cli_alert_success("Resamples saved: {nrow(res)} rows.")

# =============================================================================
# §12.4 Summaries & effect sizes
# =============================================================================

sum_k <- res %>%
  tidyr::pivot_longer(c(richness, shannon), names_to = "index", values_to = "value") %>%
  dplyr::group_by(design, k, index) %>%
  dplyr::summarise(
    mean  = mean(value, na.rm = TRUE),
    q25   = stats::quantile(value, 0.25, na.rm = TRUE),
    q75   = stats::quantile(value, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

# SS – SL difference at each k
diff_k <- sum_k %>%
  dplyr::select(design, k, index, mean) %>%
  tidyr::pivot_wider(names_from = design, values_from = mean) %>%
  dplyr::mutate(diff = SS - SL)

readr::write_csv(sum_k,  file.path(TAB_DIR, "12_sloss_summary_by_k.csv"))
readr::write_csv(diff_k, file.path(TAB_DIR, "12_sloss_diff_by_k.csv"))

# =============================================================================
# §12.5 Plots
# =============================================================================

# A) Richness & Shannon vs k with ribbons
plot_vs_k <- function(df, index_label, ylab) {
  ggplot(df %>% dplyr::filter(index == index_label),
         aes(x = k, y = mean, color = design, fill = design)) +
    geom_ribbon(aes(ymin = q25, ymax = q75), alpha = 0.15, color = NA) +
    geom_line(linewidth = 1) +
    geom_point(size = 1.8) +
    scale_color_manual(values = c(SL = "#444444", SS = "#1b9e77"), name = NULL) +
    scale_fill_manual(values  = c(SL = "#444444", SS = "#1b9e77"), guide = "none") +
    labs(title = paste("SLOSS —", index_label), x = "k corals pooled",
         y = ylab, subtitle = "Mean ± IQR over resamples (B = 499)") +
    theme_pub() + theme(legend.position = "top")
}

p_rich <- plot_vs_k(sum_k, "richness", "Pooled species richness")
p_shan <- plot_vs_k(sum_k, "shannon",  "Pooled Shannon diversity")

p_grid <- p_rich / p_shan + patchwork::plot_annotation(
  title = "§12 SLOSS: Single Large vs Several Small",
  subtitle = "SL: k corals within one reef | SS: k corals across distinct reefs"
)

show_and_save(p_grid, file.path(FIG_DIR, "12_sloss_richness_shannon.png"),
              width = 10, height = 8, dpi = 600)

# B) Difference curve (SS − SL) for richness (primary focus)
p_diff <- ggplot(diff_k %>% dplyr::filter(index == "richness"),
                 aes(k, diff)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_line(linewidth = 1) +
  geom_point(size = 1.8) +
  labs(title = "SLOSS (Richness): SS − SL vs k",
       x = "k corals pooled", y = "ΔRichness (SS − SL)") +
  theme_pub()

show_and_save(p_diff, file.path(FIG_DIR, "12_sloss_diff_richness.png"),
              width = 7.5, height = 4.5, dpi = 600)

cli::cli_alert_success("§12 complete: figures written to {FIG_DIR}")

# =============================================================================
# §12.6 (Optional) Treatment-stratified SS
#   If you want to restrict SS draws to reefs within the same treatment level
#   (e.g., k reefs all from treatment 6), flip STRAT_SS = TRUE.
# =============================================================================

STRAT_SS <- FALSE
if (isTRUE(STRAT_SS)) {
  cli::cli_alert_info("Running treatment‑stratified SS draws …")
  ids_by_trt <- split(meta_coral$reef, meta_coral$treatment)
  run_strat <- function(k, trt) {
    R <- ids_by_trt[[as.character(trt)]]
    if (length(R) < k) return(NULL)
    r_pick <- sample(R, size = k, replace = FALSE)
    cs <- unlist(Map(function(r) sample(corals_by_reef[[r]], size = 1), r_pick), use.names = FALSE)
    pool_div(cs) %>% dplyr::mutate(k = k, design = "SS_strat", treatment = trt)
  }
  strat_list <- list(); row_ix <- 0L
  for (k in K) for (b in seq_len(B)) for (trt in levels(meta_coral$treatment)) {
    out <- run_strat(k, trt)
    if (!is.null(out)) { row_ix <- row_ix + 1L; strat_list[[row_ix]] <- out }
  }
  ss_strat <- dplyr::bind_rows(strat_list)
  if (nrow(ss_strat)) {
    readr::write_csv(ss_strat, file.path(TAB_DIR, "12_sloss_resamples_SS_stratified.csv"))
    cli::cli_alert_success("Saved treatment‑stratified SS resamples: {nrow(ss_strat)} rows.")
  } else {
    cli::cli_alert_warning("No valid SS_strat draws (insufficient reefs per treatment and k).")
  }
}

# ==============================================================================
# End §12
# ==============================================================================

# =============================================================================
# §12B) SLOSS — Beta diversity partitioning (PA & Abundance) for SL vs SS
#   SL = k corals within one reef; SS = one coral from each of k distinct reefs
#   Repeats B iterations per k and plots mean ± IQR vs k.
#   Requires: species_only_df, .kept_species, meta_coral, mat_coral_abund,
#             FIG_DIR, TAB_DIR, theme_pub(), show_and_save()
# =============================================================================

cli::cli_h2("§12B SLOSS — Beta diversity partitioning (SL vs SS)")

# ---- Packages ----------------------------------------------------------------
if (!requireNamespace("betapart", quietly = TRUE)) {
  stop("Missing package: betapart. Install with install.packages('betapart').")
}

# ---- Controls ----------------------------------------------------------------
set.seed(42)
B_iter <- 499                         # resamples per k
K_vals <- 1:6                         # k corals pooled
PA_only_species <- .kept_species      # 10×10 set carried from §2

# ---- Helpers -----------------------------------------------------------------
# extract a long table of beta components from a (sub)matrix (rows=corals)
# Replace the earlier .compute_beta_parts() with this robust version
.compute_beta_parts <- function(X_counts) {
  # X_counts: rows = corals (sites), cols = species (counts)
  X_counts <- as.matrix(X_counts)
  
  # Drop species that are zero across all selected corals
  if (nrow(X_counts) < 2) {
    return(tibble::tibble(
      sor=NA_real_, sim=NA_real_, sne=NA_real_,
      bray=NA_real_, bal=NA_real_, gra=NA_real_,
      sor_ms=NA_real_, sim_ms=NA_real_, sne_ms=NA_real_,
      bray_ms=NA_real_, bal_ms=NA_real_, gra_ms=NA_real_
    ))
  }
  keep_cols <- colSums(X_counts, na.rm = TRUE) > 0
  X_counts  <- X_counts[, keep_cols, drop = FALSE]
  if (ncol(X_counts) == 0) {
    return(tibble::tibble(
      sor=NA_real_, sim=NA_real_, sne=NA_real_,
      bray=NA_real_, bal=NA_real_, gra=NA_real_,
      sor_ms=NA_real_, sim_ms=NA_real_, sne_ms=NA_real_,
      bray_ms=NA_real_, bal_ms=NA_real_, gra_ms=NA_real_
    ))
  }
  
  # Presence/absence core
  X_pa <- (X_counts > 0) * 1
  X_pa <- X_pa[, colSums(X_pa) > 0, drop = FALSE]  # drop empty PA species
  
  # Pairwise presence/absence (Baselga: sorensen -> sim + sne)
  bp <- tryCatch(
    {
      core_pa <- betapart::betapart.core(X_pa)
      betapart::beta.pair(core_pa, index.family = "sorensen")
    },
    error = function(e) NULL
  )
  
  # Pairwise abundance (Baselga 2017: bray -> bal + gra)
  bpa <- tryCatch(betapart::beta.pair.abund(X_counts, index.family = "bray"),
                  error = function(e) NULL)
  
  # Multi-site summaries (single values)
  ms_pa <- tryCatch(
    {
      core_pa <- betapart::betapart.core(X_pa)
      betapart::beta.multi(core_pa, index.family = "sorensen")
    },
    error = function(e) NULL
  )
  ms_ab <- tryCatch(betapart::beta.multi.abund(X_counts, index.family = "bray"),
                    error = function(e) NULL)
  
  # Helper to safely mean() a dist or numeric; returns NA if NULL
  mean_or_na <- function(x) if (is.null(x)) NA_real_ else mean(as.numeric(x), na.rm = TRUE)
  get_or_na  <- function(x, nm) if (is.null(x)) NA_real_ else as.numeric(x[[nm]])
  
  tibble::tibble(
    sor   = mean_or_na(bp$beta.sor),
    sim   = mean_or_na(bp$beta.sim),
    sne   = mean_or_na(bp$beta.sne),
    bray  = mean_or_na(bpa$beta.bray),
    bal   = mean_or_na(bpa$beta.bray.bal),
    gra   = mean_or_na(bpa$beta.bray.gra),
    sor_ms  = get_or_na(ms_pa, "beta.SOR"),
    sim_ms  = get_or_na(ms_pa, "beta.SIM"),
    sne_ms  = get_or_na(ms_pa, "beta.SNE"),
    bray_ms = get_or_na(ms_ab, "beta.BRAY"),
    bal_ms  = get_or_na(ms_ab, "beta.BRAY.BAL"),
    gra_ms  = get_or_na(ms_ab, "beta.BRAY.GRA")
  )
}

# sample k coral IDs for SL (within one reef) and SS (across reefs)
.pick_ids <- function(k, meta_tbl) {
  # SL: choose a reef that has at least k corals, then sample k within it
  reefs_with_k <- names(which(table(meta_tbl$reef) >= k))
  if (!length(reefs_with_k)) return(NULL)
  reef_sl <- sample(reefs_with_k, 1)
  ids_sl  <- meta_tbl$coral_id[meta_tbl$reef == reef_sl] |> sample(k, replace = FALSE)
  
  # SS: choose k distinct reefs, one coral each (sample a coral uniformly within reef)
  if (length(unique(meta_tbl$reef)) < k) return(NULL)
  reefs_ss <- sample(unique(meta_tbl$reef), k, replace = FALSE)
  ids_ss   <- unlist(lapply(reefs_ss, function(rf) {
    sample(meta_tbl$coral_id[meta_tbl$reef == rf], 1)
  }), use.names = FALSE)
  
  list(SL = ids_sl, SS = ids_ss, reef_SL = reef_sl)
}

# Build a species × corals matrix for a given set of coral IDs
.matrix_for_ids <- function(ids, long_df, spp_keep = PA_only_species) {
  long_df |>
    dplyr::filter(coral_id %in% ids, species %in% spp_keep) |>
    dplyr::group_by(coral_id, species) |>
    dplyr::summarise(val = sum(count, na.rm = TRUE), .groups = "drop") |>
    tidyr::pivot_wider(names_from = coral_id, values_from = val, values_fill = 0) |>
    tibble::column_to_rownames("species") |>
    as.matrix()
}

# ---- Prep metadata (one row per coral) ---------------------------------------
stopifnot(all(rownames(mat_coral_abund) %in% meta_coral$coral_id))
meta1 <- meta_coral |>
  dplyr::select(coral_id, reef, treatment) |>
  dplyr::distinct()

# ---- Main resampling loop ----------------------------------------------------
cli::cli_alert_info("Running {B_iter} iterations for each k ∈ [{min(K_vals)}, {max(K_vals)}]")

res_list <- vector("list", length(K_vals))
names(res_list) <- paste0("k", K_vals)

for (kk in seq_along(K_vals)) {
  k <- K_vals[kk]
  out_k <- vector("list", B_iter)
  n_ok  <- 0L
  
  for (b in seq_len(B_iter)) {
    picks <- .pick_ids(k, meta1)
    if (is.null(picks)) next
    
    # Build matrices & compute partitions
    M_SL <- .matrix_for_ids(picks$SL, species_only_df)
    M_SS <- .matrix_for_ids(picks$SS, species_only_df)
    
    # Guard: need ≥2 columns (corals) and some variation
    if (ncol(M_SL) < 2 || sum(M_SL) == 0 || ncol(M_SS) < 2 || sum(M_SS) == 0) next
    
    tb_sl <- .compute_beta_parts(t(M_SL)) |> dplyr::mutate(kind = "SL")
    tb_ss <- .compute_beta_parts(t(M_SS)) |> dplyr::mutate(kind = "SS")
    
    n_ok  <- n_ok + 1L
    out_k[[n_ok]] <- dplyr::bind_rows(tb_sl, tb_ss) |>
      dplyr::mutate(k = k, iter = b)
  }
  
  # bind if anything succeeded
  res_list[[kk]] <- dplyr::bind_rows(out_k[seq_len(n_ok)])
  cli::cli_alert_success("k = {k}: {nrow(res_list[[kk]])} rows ({n_ok} successful iterations × 2 kinds).")
}

res_beta <- dplyr::bind_rows(res_list)
stopifnot(nrow(res_beta) > 0)

# Save raw iteration results
readr::write_csv(res_beta, file.path(TAB_DIR, "12B_sloss_beta_partition_iterations.csv"))

# ---- Summaries (mean ± IQR over iterations per k × kind) --------------------
qIQR <- function(x) diff(stats::quantile(x, c(0.25, 0.75), na.rm = TRUE))
sum_beta <- res_beta |>
  tidyr::pivot_longer(c(sor, sim, sne, bray, bal, gra),
                      names_to = "metric", values_to = "value") |>
  dplyr::group_by(kind, k, metric) |>
  dplyr::summarise(
    mean = mean(value, na.rm = TRUE),
    q25  = stats::quantile(value, 0.25, na.rm = TRUE),
    q75  = stats::quantile(value, 0.75, na.rm = TRUE),
    IQR  = qIQR(value),
    .groups = "drop"
  )

readr::write_csv(sum_beta, file.path(TAB_DIR, "12B_sloss_beta_partition_summary.csv"))

# ---- Plots -------------------------------------------------------------------
lab_metric <- c(
  sor  = "Sørensen (total PA)",
  sim  = "Turnover (β_SIM)",
  sne  = "Nestedness (β_SNE)",
  bray = "Bray–Curtis (total)",
  bal  = "Balanced variation (β_BAL)",
  gra  = "Abundance gradients (β_GRA)"
)

plot_panel <- function(df, which_metrics, title_) {
  df |>
    dplyr::filter(metric %in% which_metrics) |>
    dplyr::mutate(metric = factor(metric, levels = which_metrics, labels = lab_metric[which_metrics])) |>
    ggplot2::ggplot(ggplot2::aes(x = k, y = mean, color = kind, fill = kind)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = q25, ymax = q75), alpha = 0.18, color = NA) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 2) +
    ggplot2::scale_color_manual(values = c(SL = "black", SS = "#1b9e77"), name = NULL) +
    ggplot2::scale_fill_manual(values  = c(SL = "black", SS = "#1b9e77"), guide = "none") +
    ggplot2::labs(title = title_, x = "k corals pooled", y = "Mean dissimilarity (± IQR)") +
    ggplot2::facet_wrap(~ metric, ncol = 3, scales = "free_y") +
    theme_pub()
}

p_pa   <- plot_panel(sum_beta, c("sor","sim","sne"),
                     "SLOSS β-diversity (Presence/absence: Sørensen = turnover + nestedness)")
p_abun <- plot_panel(sum_beta, c("bray","bal","gra"),
                     "SLOSS β-diversity (Abundance: Bray–Curtis = balanced + gradients)")

show_and_save(p_pa,   file.path(FIG_DIR, "12B_sloss_beta_presence_absence.png"), width = 12, height = 6)
show_and_save(p_abun, file.path(FIG_DIR, "12B_sloss_beta_abundance.png"),        width = 12, height = 6)

cli::cli_alert_success("§12B complete: beta partition tables and figures written.")

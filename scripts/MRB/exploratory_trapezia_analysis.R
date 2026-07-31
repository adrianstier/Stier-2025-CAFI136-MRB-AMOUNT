# ==============================================================================
# File: exploratory_trapezia_analysis.R
# Purpose: Explore Trapezia patterns by treatment and coral condition.
#
# This script is intentionally exploratory. It keeps treatment/community summaries
# on the full 54-colony CAFI data set, then restricts condition associations to
# the 44 colonies retained in the growth/physiology condition analysis.
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(vegan)
  library(lme4)
  library(lmerTest)
  library(broom)
  library(broom.mixed)
  library(patchwork)
  library(scales)
})

set.seed(1234)
options(stringsAsFactors = FALSE, scipen = 999, readr.show_col_types = FALSE)

if (requireNamespace("here", quietly = TRUE)) {
  root_dir <- here::here()
} else {
  root_dir <- getwd()
}

fig_standard_path <- file.path(root_dir, "scripts", "MRB", "mrb_figure_standards.R")
if (file.exists(fig_standard_path)) {
  source(fig_standard_path)
} else {
  TREATMENT_COLORS <- c("1" = "#440154", "3" = "#31688E", "6" = "#5DC863")
  theme_publication <- function(base_size = 12, ...) ggplot2::theme_bw(base_size = base_size)
}

OUT_DIR <- file.path(root_dir, "output", "MRB", "exploratory", "trapezia")
FIG_DIR <- file.path(OUT_DIR, "figures")
TAB_DIR <- file.path(OUT_DIR, "tables")
dir.create(FIG_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(TAB_DIR, recursive = TRUE, showWarnings = FALSE)

strip_fe <- function(x) stringr::str_remove(as.character(x), "^FE-")

clean_name <- function(x) {
  x %>%
    stringr::str_to_lower() %>%
    stringr::str_replace_all("[^a-z0-9]+", "_") %>%
    stringr::str_replace_all("^_|_$", "")
}

safe_sd <- function(x) stats::sd(x, na.rm = TRUE)

z_score <- function(x) {
  sx <- safe_sd(x)
  if (!is.finite(sx) || sx == 0) return(rep(NA_real_, length(x)))
  as.numeric((x - mean(x, na.rm = TRUE)) / sx)
}

save_plot <- function(plot, stub, width, height) {
  ggplot2::ggsave(paste0(stub, ".png"), plot, width = width, height = height,
                  dpi = 600, bg = "white")
  ggplot2::ggsave(paste0(stub, ".pdf"), plot, width = width, height = height,
                  bg = "white")
}

fmt_num <- function(x, digits = 3) {
  ifelse(is.na(x), "NA", formatC(x, digits = digits, format = "fg", flag = "#"))
}

fmt_p <- function(p) {
  dplyr::case_when(
    is.na(p) ~ "NA",
    p < 0.001 ~ "<0.001",
    TRUE ~ sprintf("%.3f", p)
  )
}

md_table <- function(df) {
  if (is.null(df) || nrow(df) == 0) return("_No rows._")
  df_chr <- df %>% dplyr::mutate(dplyr::across(dplyr::everything(), as.character))
  header <- paste0("| ", paste(names(df_chr), collapse = " | "), " |")
  rule <- paste0("| ", paste(rep("---", ncol(df_chr)), collapse = " | "), " |")
  body <- apply(df_chr, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  paste(c(header, rule, body), collapse = "\n")
}

read_required_csv <- function(path) {
  if (!file.exists(path)) stop("Missing required file: ", path)
  readr::read_csv(path, show_col_types = FALSE)
}

message("Loading CAFI, treatment, and condition data...")

cafi_path <- file.path(root_dir, "data", "MRB Amount",
                       "1. mrb_fe_cafi_summer_2021_v4_AP_updated_2024.csv")
treatment_path <- file.path(root_dir, "data", "MRB Amount",
                            "coral_id_position_treatment.csv")
physio_path <- file.path(root_dir, "output", "MRB", "figures", "coral",
                         "physio", "physio_metrics_plus_growth_filtered.csv")
scaling_path <- file.path(root_dir, "output", "MRB", "data",
                          "scaling_table_38species_1row.csv")

treatment <- read_required_csv(treatment_path) %>%
  dplyr::mutate(
    coral_id = strip_fe(coral_id),
    treatment = factor(as.character(treatment), levels = c("1", "3", "6")),
    treatment_num = as.numeric(as.character(treatment)),
    row_num = stringr::str_extract(position, "^\\d+"),
    col_num = stringr::str_extract(position, "(?<=-)\\d+"),
    replicate = stringr::str_extract(position, "[A-Za-z]+$"),
    reef = paste0("Reef_", row_num, "-", col_num)
  ) %>%
  dplyr::select(coral_id, reef, treatment, treatment_num, position, replicate)

cafi <- read_required_csv(cafi_path) %>%
  dplyr::mutate(
    coral_id = strip_fe(coral_id),
    species = trimws(as.character(species)),
    genus = trimws(as.character(genus)),
    count = as.numeric(count)
  ) %>%
  dplyr::filter(!is.na(coral_id), !is.na(species), species != "") %>%
  dplyr::mutate(count = tidyr::replace_na(count, 0)) %>%
  dplyr::left_join(treatment, by = "coral_id")

if (any(is.na(cafi$treatment))) {
  warning("Some CAFI rows do not have treatment metadata: ",
          paste(unique(cafi$coral_id[is.na(cafi$treatment)]), collapse = ", "))
}

trapezia_species <- cafi %>%
  dplyr::filter(genus == "Trapezia" | stringr::str_detect(species, regex("^Trapezia\\s", ignore_case = TRUE))) %>%
  dplyr::distinct(species) %>%
  dplyr::arrange(species) %>%
  dplyr::pull(species)

if (length(trapezia_species) == 0) stop("No Trapezia species were found.")

species_full_meta <- cafi %>%
  dplyr::group_by(species) %>%
  dplyr::summarise(
    full_total_count = sum(count, na.rm = TRUE),
    full_n_corals = dplyr::n_distinct(coral_id[count > 0]),
    .groups = "drop"
  )

full_totals <- cafi %>%
  dplyr::group_by(coral_id) %>%
  dplyr::summarise(
    full_total_abundance = sum(count, na.rm = TRUE),
    full_richness = dplyr::n_distinct(species[count > 0]),
    .groups = "drop"
  )

base_corals <- treatment %>%
  dplyr::left_join(full_totals, by = "coral_id") %>%
  dplyr::mutate(
    full_total_abundance = tidyr::replace_na(full_total_abundance, 0),
    full_richness = tidyr::replace_na(full_richness, 0)
  )

trap_counts_original <- cafi %>%
  dplyr::filter(species %in% trapezia_species) %>%
  dplyr::group_by(coral_id, species) %>%
  dplyr::summarise(count = sum(count, na.rm = TRUE), .groups = "drop") %>%
  tidyr::pivot_wider(names_from = species, values_from = count, values_fill = 0)

trap_counts_original <- base_corals %>%
  dplyr::select(coral_id) %>%
  dplyr::left_join(trap_counts_original, by = "coral_id")

missing_species_cols <- setdiff(trapezia_species, names(trap_counts_original))
if (length(missing_species_cols) > 0) {
  for (sp in missing_species_cols) trap_counts_original[[sp]] <- 0
}

trap_counts_original <- trap_counts_original %>%
  dplyr::mutate(dplyr::across(dplyr::all_of(trapezia_species), ~ tidyr::replace_na(.x, 0)))

count_cols_by_species <- setNames(
  paste0("trap_count_", clean_name(trapezia_species)),
  trapezia_species
)
inc_cols_by_species <- setNames(
  paste0("trap_incidence_", clean_name(trapezia_species)),
  trapezia_species
)

trap_counts <- trap_counts_original %>%
  dplyr::rename(!!!setNames(names(count_cols_by_species), count_cols_by_species))

trap_incidence <- trap_counts %>% dplyr::select(coral_id)
for (sp in trapezia_species) {
  trap_incidence[[inc_cols_by_species[[sp]]]] <- as.integer(trap_counts[[count_cols_by_species[[sp]]]] > 0)
}

coral_metrics <- base_corals %>%
  dplyr::left_join(trap_counts, by = "coral_id") %>%
  dplyr::left_join(trap_incidence, by = "coral_id")

trap_count_cols <- unname(count_cols_by_species)
trap_incidence_cols <- unname(inc_cols_by_species)
trap_mat_all <- as.matrix(coral_metrics[, trap_count_cols, drop = FALSE])
colnames(trap_mat_all) <- trapezia_species

serenei_col <- if ("Trapezia serenei" %in% names(count_cols_by_species)) {
  count_cols_by_species[["Trapezia serenei"]]
} else {
  NA_character_
}

non_serenei_species <- setdiff(trapezia_species, "Trapezia serenei")
non_serenei_cols <- unname(count_cols_by_species[non_serenei_species])

coral_metrics <- coral_metrics %>%
  dplyr::mutate(
    trap_total = rowSums(dplyr::pick(dplyr::all_of(trap_count_cols)), na.rm = TRUE),
    trap_serenei = if (!is.na(serenei_col)) .data[[serenei_col]] else 0,
    trap_non_serenei = trap_total - trap_serenei,
    trap_richness = rowSums(dplyr::pick(dplyr::all_of(trap_count_cols)) > 0, na.rm = TRUE),
    trap_rare_richness = if (length(non_serenei_cols) > 0) {
      rowSums(dplyr::pick(dplyr::all_of(non_serenei_cols)) > 0, na.rm = TRUE)
    } else {
      0
    },
    trap_any = trap_total > 0,
    trap_non_serenei_any = trap_non_serenei > 0,
    trap_shannon = vegan::diversity(trap_mat_all, index = "shannon"),
    trap_evenness = dplyr::if_else(trap_richness > 1, trap_shannon / log(trap_richness), 0),
    trap_prop_full = dplyr::if_else(full_total_abundance > 0, trap_total / full_total_abundance, NA_real_),
    trap_serenei_prop_full = dplyr::if_else(full_total_abundance > 0, trap_serenei / full_total_abundance, NA_real_),
    trap_non_serenei_prop_full = dplyr::if_else(full_total_abundance > 0, trap_non_serenei / full_total_abundance, NA_real_),
    trap_serenei_prop_trapezia = dplyr::if_else(trap_total > 0, trap_serenei / trap_total, NA_real_)
  )

species_summary_all <- tibble::tibble(
  species = trapezia_species,
  total_count_all54 = colSums(trap_mat_all),
  n_corals_all54 = colSums(trap_mat_all > 0),
  prevalence_all54 = n_corals_all54 / nrow(coral_metrics)
) %>%
  dplyr::arrange(dplyr::desc(total_count_all54), dplyr::desc(n_corals_all54))

readr::write_csv(species_summary_all, file.path(TAB_DIR, "trapezia_species_summary_all54.csv"))
readr::write_csv(coral_metrics, file.path(TAB_DIR, "trapezia_colony_metrics_all54.csv"))

species_long_all <- coral_metrics %>%
  dplyr::select(coral_id, reef, treatment, treatment_num, dplyr::all_of(trap_count_cols)) %>%
  tidyr::pivot_longer(dplyr::all_of(trap_count_cols), names_to = "count_col", values_to = "count") %>%
  dplyr::mutate(
    species = names(count_cols_by_species)[match(count_col, count_cols_by_species)],
    present = count > 0
  )

species_treatment_summary <- species_long_all %>%
  dplyr::group_by(species, treatment) %>%
  dplyr::summarise(
    n_corals = dplyr::n(),
    total_count = sum(count, na.rm = TRUE),
    mean_per_coral = mean(count, na.rm = TRUE),
    sd_per_coral = stats::sd(count, na.rm = TRUE),
    median_per_coral = stats::median(count, na.rm = TRUE),
    n_present = sum(present, na.rm = TRUE),
    prevalence = mean(present, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  dplyr::arrange(species, treatment)

readr::write_csv(species_treatment_summary, file.path(TAB_DIR, "trapezia_species_by_treatment_all54.csv"))

metric_cols_raw <- c(
  "full_total_abundance", "full_richness",
  "trap_total", "trap_serenei", "trap_non_serenei",
  "trap_richness", "trap_rare_richness", "trap_shannon", "trap_evenness",
  "trap_prop_full", "trap_serenei_prop_full", "trap_non_serenei_prop_full",
  "trap_serenei_prop_trapezia"
)

metric_treatment_summary_all <- coral_metrics %>%
  dplyr::select(coral_id, reef, treatment, dplyr::all_of(metric_cols_raw)) %>%
  tidyr::pivot_longer(dplyr::all_of(metric_cols_raw), names_to = "metric", values_to = "value") %>%
  dplyr::group_by(metric, treatment) %>%
  dplyr::summarise(
    n = sum(!is.na(value)),
    mean = mean(value, na.rm = TRUE),
    sd = stats::sd(value, na.rm = TRUE),
    median = stats::median(value, na.rm = TRUE),
    q25 = stats::quantile(value, 0.25, na.rm = TRUE),
    q75 = stats::quantile(value, 0.75, na.rm = TRUE),
    n_nonzero = sum(value > 0, na.rm = TRUE),
    nonzero_rate = mean(value > 0, na.rm = TRUE),
    .groups = "drop"
  )

readr::write_csv(metric_treatment_summary_all,
                 file.path(TAB_DIR, "trapezia_metric_by_treatment_all54.csv"))

# Reef-level summaries are the cleaner unit for treatment effects because
# treatment is imposed at the reef scale.
cafi_reef_full <- cafi %>%
  dplyr::filter(!is.na(reef), !is.na(treatment)) %>%
  dplyr::group_by(reef, treatment) %>%
  dplyr::summarise(
    full_total_abundance_reef = sum(count, na.rm = TRUE),
    full_richness_reef = dplyr::n_distinct(species[count > 0]),
    .groups = "drop"
  )

reef_base <- coral_metrics %>%
  dplyr::group_by(reef, treatment) %>%
  dplyr::summarise(
    n_colonies = dplyr::n_distinct(coral_id),
    trap_incidence_rate = mean(trap_any, na.rm = TRUE),
    trap_non_serenei_incidence_rate = mean(trap_non_serenei_any, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  dplyr::left_join(cafi_reef_full, by = c("reef", "treatment"))

reef_counts <- coral_metrics %>%
  dplyr::group_by(reef, treatment) %>%
  dplyr::summarise(dplyr::across(dplyr::all_of(trap_count_cols), ~ sum(.x, na.rm = TRUE)),
                   .groups = "drop")

reef_mat <- as.matrix(reef_counts[, trap_count_cols, drop = FALSE])
colnames(reef_mat) <- trapezia_species

reef_metrics <- reef_counts %>%
  dplyr::left_join(reef_base, by = c("reef", "treatment")) %>%
  dplyr::mutate(
    treatment_num = as.numeric(as.character(treatment)),
    trap_total_reef = rowSums(dplyr::pick(dplyr::all_of(trap_count_cols)), na.rm = TRUE),
    trap_serenei_reef = if (!is.na(serenei_col)) .data[[serenei_col]] else 0,
    trap_non_serenei_reef = trap_total_reef - trap_serenei_reef,
    trap_density_per_colony = trap_total_reef / n_colonies,
    trap_serenei_density_per_colony = trap_serenei_reef / n_colonies,
    trap_non_serenei_density_per_colony = trap_non_serenei_reef / n_colonies,
    trap_richness_reef = rowSums(reef_mat > 0, na.rm = TRUE),
    trap_rare_richness_reef = if (length(non_serenei_cols) > 0) {
      rowSums(reef_mat[, non_serenei_species, drop = FALSE] > 0, na.rm = TRUE)
    } else {
      0
    },
    trap_shannon_reef = vegan::diversity(reef_mat, index = "shannon"),
    trap_evenness_reef = dplyr::if_else(trap_richness_reef > 1,
                                        trap_shannon_reef / log(trap_richness_reef), 0),
    trap_prop_full_reef = dplyr::if_else(full_total_abundance_reef > 0,
                                         trap_total_reef / full_total_abundance_reef, NA_real_),
    trap_serenei_prop_full_reef = dplyr::if_else(full_total_abundance_reef > 0,
                                                 trap_serenei_reef / full_total_abundance_reef, NA_real_),
    trap_non_serenei_prop_full_reef = dplyr::if_else(full_total_abundance_reef > 0,
                                                     trap_non_serenei_reef / full_total_abundance_reef, NA_real_)
  )

readr::write_csv(reef_metrics, file.path(TAB_DIR, "trapezia_reef_metrics_all27.csv"))

reef_summary_by_treatment <- reef_metrics %>%
  dplyr::select(
    reef, treatment,
    trap_total_reef, trap_density_per_colony,
    trap_serenei_density_per_colony, trap_non_serenei_density_per_colony,
    trap_richness_reef, trap_rare_richness_reef,
    trap_non_serenei_incidence_rate,
    trap_prop_full_reef, trap_serenei_prop_full_reef, trap_non_serenei_prop_full_reef
  ) %>%
  tidyr::pivot_longer(-c(reef, treatment), names_to = "metric", values_to = "value") %>%
  dplyr::group_by(metric, treatment) %>%
  dplyr::summarise(
    n_reefs = dplyr::n(),
    mean = mean(value, na.rm = TRUE),
    sd = stats::sd(value, na.rm = TRUE),
    median = stats::median(value, na.rm = TRUE),
    q25 = stats::quantile(value, 0.25, na.rm = TRUE),
    q75 = stats::quantile(value, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

readr::write_csv(reef_summary_by_treatment,
                 file.path(TAB_DIR, "trapezia_reef_metric_by_treatment_all27.csv"))

fit_reef_treatment <- function(df, response) {
  dat <- df %>%
    dplyr::select(treatment, treatment_num, value = dplyr::all_of(response)) %>%
    dplyr::filter(is.finite(value), !is.na(treatment))

  if (nrow(dat) < 6 || dplyr::n_distinct(dat$value) < 2) {
    return(tibble::tibble(
      metric = response, n = nrow(dat), lm_F = NA_real_, lm_p = NA_real_,
      lm_r2 = NA_real_, kruskal_p = NA_real_, spearman_rho = NA_real_,
      spearman_p = NA_real_, note = "Skipped: too little variation"
    ))
  }

  fit <- stats::lm(value ~ treatment, data = dat)
  an <- stats::anova(fit)
  kw <- tryCatch(stats::kruskal.test(value ~ treatment, data = dat),
                 error = function(e) NULL)
  sp <- suppressWarnings(tryCatch(stats::cor.test(dat$treatment_num, dat$value,
                                                   method = "spearman", exact = FALSE),
                                  error = function(e) NULL))

  tibble::tibble(
    metric = response,
    n = nrow(dat),
    lm_F = unname(an["treatment", "F value"]),
    lm_p = unname(an["treatment", "Pr(>F)"]),
    lm_r2 = summary(fit)$r.squared,
    kruskal_p = if (is.null(kw)) NA_real_ else unname(kw$p.value),
    spearman_rho = if (is.null(sp)) NA_real_ else unname(sp$estimate),
    spearman_p = if (is.null(sp)) NA_real_ else unname(sp$p.value),
    note = NA_character_
  )
}

reef_test_metrics <- c(
  "trap_total_reef", "trap_density_per_colony",
  "trap_serenei_density_per_colony", "trap_non_serenei_density_per_colony",
  "trap_richness_reef", "trap_rare_richness_reef",
  "trap_non_serenei_incidence_rate",
  "trap_prop_full_reef", "trap_serenei_prop_full_reef",
  "trap_non_serenei_prop_full_reef"
)

reef_treatment_tests <- purrr::map_dfr(reef_test_metrics, ~ fit_reef_treatment(reef_metrics, .x)) %>%
  dplyr::mutate(
    lm_p_BH = stats::p.adjust(lm_p, method = "BH"),
    kruskal_p_BH = stats::p.adjust(kruskal_p, method = "BH"),
    spearman_p_BH = stats::p.adjust(spearman_p, method = "BH")
  ) %>%
  dplyr::arrange(lm_p)

readr::write_csv(reef_treatment_tests,
                 file.path(TAB_DIR, "trapezia_treatment_tests_reef_level.csv"))

fit_colony_treatment <- function(df, response) {
  dat <- df %>%
    dplyr::select(treatment, reef, value = dplyr::all_of(response)) %>%
    dplyr::filter(is.finite(value), !is.na(treatment), !is.na(reef))

  if (nrow(dat) < 8 || dplyr::n_distinct(dat$value) < 2) {
    return(tibble::tibble(
      metric = response, n = nrow(dat), n_reefs = dplyr::n_distinct(dat$reef),
      treatment_F = NA_real_, treatment_p = NA_real_, singular = NA,
      note = "Skipped: too little variation"
    ))
  }

  fit <- tryCatch(
    lmerTest::lmer(value ~ treatment + (1 | reef), data = dat,
                   control = lme4::lmerControl(check.conv.singular = "ignore")),
    error = function(e) e
  )
  if (inherits(fit, "error")) {
    return(tibble::tibble(
      metric = response, n = nrow(dat), n_reefs = dplyr::n_distinct(dat$reef),
      treatment_F = NA_real_, treatment_p = NA_real_, singular = NA,
      note = paste("Model failed:", fit$message)
    ))
  }

  an <- as.data.frame(anova(fit, ddf = "Satterthwaite"))
  tibble::tibble(
    metric = response,
    n = nrow(dat),
    n_reefs = dplyr::n_distinct(dat$reef),
    treatment_F = unname(an["treatment", "F.value"]),
    treatment_p = unname(an["treatment", "Pr(>F)"]),
    singular = lme4::isSingular(fit),
    note = NA_character_
  )
}

coral_metrics_for_models <- coral_metrics %>%
  dplyr::mutate(
    sqrt_trap_total = sqrt(trap_total),
    sqrt_trap_serenei = sqrt(trap_serenei),
    sqrt_trap_non_serenei = sqrt(trap_non_serenei),
    sqrt_trap_richness = sqrt(trap_richness),
    sqrt_trap_rare_richness = sqrt(trap_rare_richness),
    asin_trap_prop_full = asin(sqrt(pmin(pmax(trap_prop_full, 0), 1))),
    asin_trap_serenei_prop_full = asin(sqrt(pmin(pmax(trap_serenei_prop_full, 0), 1))),
    asin_trap_non_serenei_prop_full = asin(sqrt(pmin(pmax(trap_non_serenei_prop_full, 0), 1)))
  )

colony_treatment_metrics <- c(
  "sqrt_trap_total", "sqrt_trap_serenei", "sqrt_trap_non_serenei",
  "sqrt_trap_richness", "sqrt_trap_rare_richness",
  "asin_trap_prop_full", "asin_trap_serenei_prop_full",
  "asin_trap_non_serenei_prop_full"
)

colony_treatment_tests <- purrr::map_dfr(colony_treatment_metrics,
                                         ~ fit_colony_treatment(coral_metrics_for_models, .x)) %>%
  dplyr::mutate(treatment_p_BH = stats::p.adjust(treatment_p, method = "BH")) %>%
  dplyr::arrange(treatment_p)

readr::write_csv(colony_treatment_tests,
                 file.path(TAB_DIR, "trapezia_treatment_tests_colony_lmm.csv"))

fit_species_treatment <- function(df, species_name) {
  if (nrow(df) < 6 || dplyr::n_distinct(df$count) < 2) {
    return(tibble::tibble(
      species = species_name, n = nrow(df), total_count = sum(df$count),
      prevalence = mean(df$present), kruskal_count_p = NA_real_,
      spearman_count_rho = NA_real_, spearman_count_p = NA_real_,
      fisher_incidence_p = NA_real_, note = "Skipped: too little variation"
    ))
  }

  kw <- tryCatch(stats::kruskal.test(count ~ treatment, data = df),
                 error = function(e) NULL)
  sp <- suppressWarnings(tryCatch(stats::cor.test(df$treatment_num, df$count,
                                                   method = "spearman", exact = FALSE),
                                  error = function(e) NULL))
  incidence_tab <- table(df$treatment, df$present)
  fish <- if (ncol(incidence_tab) == 2 && all(rowSums(incidence_tab) > 0)) {
    tryCatch(stats::fisher.test(incidence_tab, simulate.p.value = TRUE, B = 9999),
             error = function(e) NULL)
  } else {
    NULL
  }

  tibble::tibble(
    species = species_name,
    n = nrow(df),
    total_count = sum(df$count),
    prevalence = mean(df$present),
    kruskal_count_p = if (is.null(kw)) NA_real_ else unname(kw$p.value),
    spearman_count_rho = if (is.null(sp)) NA_real_ else unname(sp$estimate),
    spearman_count_p = if (is.null(sp)) NA_real_ else unname(sp$p.value),
    fisher_incidence_p = if (is.null(fish)) NA_real_ else unname(fish$p.value),
    note = NA_character_
  )
}

species_treatment_tests <- split(species_long_all, species_long_all$species) %>%
  purrr::imap_dfr(~ fit_species_treatment(.x, .y)) %>%
  dplyr::mutate(
    kruskal_count_p_BH = stats::p.adjust(kruskal_count_p, method = "BH"),
    spearman_count_p_BH = stats::p.adjust(spearman_count_p, method = "BH"),
    fisher_incidence_p_BH = stats::p.adjust(fisher_incidence_p, method = "BH")
  ) %>%
  dplyr::arrange(kruskal_count_p)

readr::write_csv(species_treatment_tests,
                 file.path(TAB_DIR, "trapezia_species_treatment_tests_all54.csv"))

# Existing proportional/FOD scaling table used in the manuscript.
if (file.exists(scaling_path)) {
  scaling_trapezia <- readr::read_csv(scaling_path, show_col_types = FALSE) %>%
    dplyr::filter(Species %in% trapezia_species) %>%
    dplyr::arrange(Species)
} else {
  scaling_trapezia <- tibble::tibble()
}
readr::write_csv(scaling_trapezia,
                 file.path(TAB_DIR, "trapezia_existing_38species_scaling_results.csv"))

message("Rebuilding condition PC1 on the filtered physiology/growth data...")

cond_vars <- c("growth_vol_b", "protein_mg_cm2", "carb_mg_cm2",
               "zoox_cells_cm2", "afdw_mg_cm2")

physio <- read_required_csv(physio_path) %>%
  dplyr::mutate(
    coral_id = strip_fe(coral_id),
    reef = as.character(reef),
    treatment = factor(as.character(treatment), levels = c("1", "3", "6")),
    treatment_num = as.numeric(as.character(treatment))
  ) %>%
  dplyr::select(coral_id, reef, treatment, treatment_num, dplyr::all_of(cond_vars)) %>%
  tidyr::drop_na(dplyr::all_of(cond_vars))

cond_scaled <- scale(as.matrix(physio[, cond_vars, drop = FALSE]))
cond_pca <- stats::prcomp(cond_scaled, center = FALSE, scale. = FALSE)

if (sum(cond_pca$rotation[, 1]) < 0) {
  cond_pca$x[, 1] <- -cond_pca$x[, 1]
  cond_pca$rotation[, 1] <- -cond_pca$rotation[, 1]
}

cond_var_exp <- cond_pca$sdev^2 / sum(cond_pca$sdev^2)
condition_scores <- physio %>%
  dplyr::mutate(
    cond_PC1 = cond_pca$x[, 1],
    cond_PC2 = cond_pca$x[, 2]
  )

condition_loadings <- tibble::tibble(
  variable = rownames(cond_pca$rotation),
  PC1_loading = cond_pca$rotation[, 1],
  PC2_loading = cond_pca$rotation[, 2],
  PC1_variance_explained = cond_var_exp[1],
  PC2_variance_explained = cond_var_exp[2]
)

readr::write_csv(condition_scores, file.path(TAB_DIR, "trapezia_condition_scores_recomputed.csv"))
readr::write_csv(condition_loadings, file.path(TAB_DIR, "trapezia_condition_pca_loadings.csv"))

analysis_df <- coral_metrics_for_models %>%
  dplyr::inner_join(
    condition_scores %>%
      dplyr::select(coral_id, cond_PC1, cond_PC2, dplyr::all_of(cond_vars)),
    by = "coral_id"
  ) %>%
  dplyr::mutate(
    dplyr::across(dplyr::all_of(colony_treatment_metrics), z_score, .names = "{.col}_z")
  )

species_summary_condition44 <- tibble::tibble(
  species = trapezia_species,
  total_count_condition44 = colSums(as.matrix(analysis_df[, trap_count_cols, drop = FALSE])),
  n_corals_condition44 = colSums(as.matrix(analysis_df[, trap_count_cols, drop = FALSE]) > 0),
  prevalence_condition44 = n_corals_condition44 / nrow(analysis_df)
)

species_summary <- species_summary_all %>%
  dplyr::left_join(species_summary_condition44, by = "species")

readr::write_csv(species_summary, file.path(TAB_DIR, "trapezia_species_summary_all54_and_condition44.csv"))

fit_condition_model <- function(df, predictor_z, adjustment = c("unadjusted", "treatment_adjusted")) {
  adjustment <- match.arg(adjustment)
  dat <- df %>%
    dplyr::select(cond_PC1, treatment, reef, predictor = dplyr::all_of(predictor_z)) %>%
    dplyr::filter(is.finite(cond_PC1), is.finite(predictor), !is.na(reef))

  if (nrow(dat) < 8 || dplyr::n_distinct(dat$predictor) < 2) {
    return(tibble::tibble(
      predictor = predictor_z, adjustment = adjustment, n = nrow(dat),
      n_reefs = dplyr::n_distinct(dat$reef), estimate = NA_real_,
      std_error = NA_real_, df = NA_real_, t = NA_real_, p_value = NA_real_,
      conf_low = NA_real_, conf_high = NA_real_, singular = NA,
      note = "Skipped: too little variation"
    ))
  }

  form <- if (adjustment == "unadjusted") {
    cond_PC1 ~ predictor + (1 | reef)
  } else {
    cond_PC1 ~ treatment + predictor + (1 | reef)
  }

  fit <- tryCatch(
    lmerTest::lmer(form, data = dat,
                   control = lme4::lmerControl(check.conv.singular = "ignore")),
    error = function(e) e
  )

  if (inherits(fit, "error")) {
    return(tibble::tibble(
      predictor = predictor_z, adjustment = adjustment, n = nrow(dat),
      n_reefs = dplyr::n_distinct(dat$reef), estimate = NA_real_,
      std_error = NA_real_, df = NA_real_, t = NA_real_, p_value = NA_real_,
      conf_low = NA_real_, conf_high = NA_real_, singular = NA,
      note = paste("Model failed:", fit$message)
    ))
  }

  tt <- broom.mixed::tidy(fit, effects = "fixed") %>%
    dplyr::filter(term == "predictor")

  tibble::tibble(
    predictor = predictor_z,
    adjustment = adjustment,
    n = nrow(dat),
    n_reefs = dplyr::n_distinct(dat$reef),
    estimate = tt$estimate,
    std_error = tt$std.error,
    df = tt$df,
    t = tt$statistic,
    p_value = tt$p.value,
    conf_low = tt$estimate - 1.96 * tt$std.error,
    conf_high = tt$estimate + 1.96 * tt$std.error,
    singular = lme4::isSingular(fit),
    note = NA_character_
  )
}

metric_predictor_lookup <- tibble::tibble(
  label = c(
    "sqrt total Trapezia abundance",
    "sqrt T. serenei abundance",
    "sqrt non-serenei Trapezia abundance",
    "sqrt Trapezia richness",
    "sqrt rare Trapezia richness",
    "arcsin sqrt Trapezia share of full CAFI",
    "arcsin sqrt T. serenei share of full CAFI",
    "arcsin sqrt non-serenei Trapezia share of full CAFI"
  ),
  predictor = paste0(colony_treatment_metrics, "_z")
)

condition_metric_models <- purrr::map_dfr(metric_predictor_lookup$predictor, function(pred) {
  dplyr::bind_rows(
    fit_condition_model(analysis_df, pred, "unadjusted"),
    fit_condition_model(analysis_df, pred, "treatment_adjusted")
  )
}) %>%
  dplyr::left_join(metric_predictor_lookup, by = "predictor") %>%
  dplyr::relocate(label, .after = predictor) %>%
  dplyr::group_by(adjustment) %>%
  dplyr::mutate(p_value_BH = stats::p.adjust(p_value, method = "BH")) %>%
  dplyr::ungroup() %>%
  dplyr::arrange(adjustment, p_value)

readr::write_csv(condition_metric_models,
                 file.path(TAB_DIR, "trapezia_condition_metric_lmm_models.csv"))

species_predictors <- tibble::tibble(
  species = trapezia_species,
  count_col = unname(count_cols_by_species[trapezia_species]),
  incidence_col = unname(inc_cols_by_species[trapezia_species]),
  count_predictor = paste0("sqrt_", clean_name(trapezia_species), "_z"),
  incidence_predictor = paste0("incidence_", clean_name(trapezia_species))
)

for (i in seq_len(nrow(species_predictors))) {
  row <- species_predictors[i, ]
  analysis_df[[paste0("sqrt_", clean_name(row$species), "_z")]] <- z_score(sqrt(analysis_df[[row$count_col]]))
  analysis_df[[paste0("incidence_", clean_name(row$species))]] <- as.integer(analysis_df[[row$incidence_col]] > 0)
}

condition_species_abundance_models <- purrr::map_dfr(seq_len(nrow(species_predictors)), function(i) {
  pred <- species_predictors$count_predictor[i]
  dplyr::bind_rows(
    fit_condition_model(analysis_df, pred, "unadjusted"),
    fit_condition_model(analysis_df, pred, "treatment_adjusted")
  ) %>%
    dplyr::mutate(
      species = species_predictors$species[i],
      predictor_type = "sqrt abundance z"
    )
})

condition_species_incidence_models <- purrr::map_dfr(seq_len(nrow(species_predictors)), function(i) {
  pred <- species_predictors$incidence_predictor[i]
  vals <- analysis_df[[pred]]
  if (sum(vals == 1, na.rm = TRUE) < 3 || sum(vals == 0, na.rm = TRUE) < 3) {
    return(tibble::tibble(
      predictor = pred, adjustment = c("unadjusted", "treatment_adjusted"),
      n = sum(!is.na(vals)), n_reefs = dplyr::n_distinct(analysis_df$reef),
      estimate = NA_real_, std_error = NA_real_, df = NA_real_, t = NA_real_,
      p_value = NA_real_, conf_low = NA_real_, conf_high = NA_real_,
      singular = NA, note = "Skipped: incidence too sparse or constant",
      species = species_predictors$species[i], predictor_type = "incidence"
    ))
  }
  dplyr::bind_rows(
    fit_condition_model(analysis_df, pred, "unadjusted"),
    fit_condition_model(analysis_df, pred, "treatment_adjusted")
  ) %>%
    dplyr::mutate(
      species = species_predictors$species[i],
      predictor_type = "incidence"
    )
})

condition_species_models <- dplyr::bind_rows(
  condition_species_abundance_models,
  condition_species_incidence_models
) %>%
  dplyr::group_by(adjustment, predictor_type) %>%
  dplyr::mutate(p_value_BH = stats::p.adjust(p_value, method = "BH")) %>%
  dplyr::ungroup() %>%
  dplyr::arrange(adjustment, predictor_type, p_value)

readr::write_csv(condition_species_models,
                 file.path(TAB_DIR, "trapezia_species_condition_lmm_models.csv"))

correlation_predictors <- c(
  metric_predictor_lookup$predictor,
  species_predictors$count_predictor
)
trait_vars <- c("cond_PC1", cond_vars)

cor_one <- function(df, predictor, trait, method) {
  dat <- df %>%
    dplyr::select(x = dplyr::all_of(predictor), y = dplyr::all_of(trait)) %>%
    dplyr::filter(is.finite(x), is.finite(y))

  if (nrow(dat) < 8 || dplyr::n_distinct(dat$x) < 2 || dplyr::n_distinct(dat$y) < 2) {
    return(tibble::tibble(
      predictor = predictor, trait = trait, method = method, n = nrow(dat),
      estimate = NA_real_, p_value = NA_real_, note = "Skipped: too little variation"
    ))
  }

  ct <- suppressWarnings(tryCatch(stats::cor.test(dat$x, dat$y, method = method,
                                                   exact = FALSE),
                                  error = function(e) e))
  if (inherits(ct, "error")) {
    return(tibble::tibble(
      predictor = predictor, trait = trait, method = method, n = nrow(dat),
      estimate = NA_real_, p_value = NA_real_, note = paste("Failed:", ct$message)
    ))
  }

  tibble::tibble(
    predictor = predictor, trait = trait, method = method, n = nrow(dat),
    estimate = unname(ct$estimate), p_value = unname(ct$p.value), note = NA_character_
  )
}

trait_grid <- tidyr::expand_grid(
  predictor = correlation_predictors,
  trait = trait_vars,
  method = c("pearson", "spearman")
)

trait_correlations <- purrr::pmap_dfr(
  trait_grid,
  ~ cor_one(analysis_df, ..1, ..2, ..3)
) %>%
  dplyr::group_by(method) %>%
  dplyr::mutate(p_value_BH = stats::p.adjust(p_value, method = "BH")) %>%
  dplyr::ungroup() %>%
  dplyr::left_join(
    dplyr::bind_rows(
      metric_predictor_lookup %>% dplyr::transmute(predictor, label),
      species_predictors %>% dplyr::transmute(predictor = count_predictor, label = paste0(species, " sqrt abundance"))
    ),
    by = "predictor"
  ) %>%
  dplyr::relocate(label, .after = predictor) %>%
  dplyr::arrange(p_value)

readr::write_csv(trait_correlations,
                 file.path(TAB_DIR, "trapezia_condition_trait_correlations.csv"))

pair_species <- trapezia_species[colSums(trap_mat_all > 0) >= 3 | colSums(trap_mat_all) >= 5]
pairwise_species_associations <- tibble::tibble()

if (length(pair_species) >= 2) {
  pairwise_species_associations <- combn(pair_species, 2, simplify = FALSE) %>%
    purrr::map_dfr(function(pair) {
      x_count <- trap_mat_all[, pair[1]]
      y_count <- trap_mat_all[, pair[2]]
      x_inc <- as.integer(x_count > 0)
      y_inc <- as.integer(y_count > 0)

      ct_abund <- suppressWarnings(tryCatch(stats::cor.test(sqrt(x_count), sqrt(y_count),
                                                             method = "spearman", exact = FALSE),
                                            error = function(e) NULL))
      ct_inc <- if (dplyr::n_distinct(x_inc) > 1 && dplyr::n_distinct(y_inc) > 1) {
        suppressWarnings(tryCatch(stats::cor.test(x_inc, y_inc, method = "spearman", exact = FALSE),
                                  error = function(e) NULL))
      } else {
        NULL
      }

      tibble::tibble(
        species_1 = pair[1],
        species_2 = pair[2],
        abundance_spearman_rho = if (is.null(ct_abund)) NA_real_ else unname(ct_abund$estimate),
        abundance_spearman_p = if (is.null(ct_abund)) NA_real_ else unname(ct_abund$p.value),
        incidence_spearman_rho = if (is.null(ct_inc)) NA_real_ else unname(ct_inc$estimate),
        incidence_spearman_p = if (is.null(ct_inc)) NA_real_ else unname(ct_inc$p.value),
        cooccurrence_n = sum(x_inc == 1 & y_inc == 1),
        species_1_present_n = sum(x_inc == 1),
        species_2_present_n = sum(y_inc == 1)
      )
    }) %>%
    dplyr::mutate(
      abundance_spearman_p_BH = stats::p.adjust(abundance_spearman_p, method = "BH"),
      incidence_spearman_p_BH = stats::p.adjust(incidence_spearman_p, method = "BH")
    ) %>%
    dplyr::arrange(abundance_spearman_p)
}

readr::write_csv(pairwise_species_associations,
                 file.path(TAB_DIR, "trapezia_species_pairwise_associations_all54.csv"))

composition_tests <- tibble::tibble(
  scale = character(),
  matrix = character(),
  test = character(),
  term = character(),
  df = numeric(),
  statistic = numeric(),
  r2 = numeric(),
  p_value = numeric()
)

adonis_terms <- function(dist_obj, formula, data, scale_label, matrix_label) {
  fit <- vegan::adonis2(formula, data = data, permutations = 999, by = "terms")
  as.data.frame(fit) %>%
    tibble::rownames_to_column("term") %>%
    dplyr::filter(!term %in% c("Residual", "Total")) %>%
    dplyr::transmute(
      scale = scale_label,
      matrix = matrix_label,
      test = "adonis2 Bray by terms",
      term,
      df = Df,
      statistic = F,
      r2 = R2,
      p_value = `Pr(>F)`
    )
}

if (ncol(reef_mat) >= 2 && nrow(reef_mat) >= 6) {
  reef_mat_var <- reef_mat[, apply(reef_mat, 2, stats::var) > 0, drop = FALSE]
  if (ncol(reef_mat_var) >= 2) {
    reef_bray_abund <- vegan::vegdist(sqrt(reef_mat_var), method = "bray")
    reef_bray_density <- vegan::vegdist(
      sqrt(sweep(reef_mat_var, 1, reef_metrics$n_colonies, "/")),
      method = "bray"
    )

    reef_row_sums <- rowSums(reef_mat_var)
    reef_mat_prop <- sweep(reef_mat_var, 1, reef_row_sums, "/")
    reef_mat_prop[!is.finite(reef_mat_prop)] <- 0
    reef_bray_prop <- vegan::vegdist(reef_mat_prop, method = "bray")

    composition_tests <- dplyr::bind_rows(
      composition_tests,
      adonis_terms(reef_bray_abund, reef_bray_abund ~ treatment, reef_metrics,
                   "reef", "sqrt Trapezia abundance"),
      adonis_terms(reef_bray_density, reef_bray_density ~ treatment, reef_metrics,
                   "reef", "sqrt Trapezia per-colony density"),
      adonis_terms(reef_bray_prop, reef_bray_prop ~ treatment, reef_metrics,
                   "reef", "Trapezia relative composition")
    )
  }
}

trap_mat_condition <- as.matrix(analysis_df[, trap_count_cols, drop = FALSE])
colnames(trap_mat_condition) <- trapezia_species
trap_mat_condition_var <- trap_mat_condition[, apply(trap_mat_condition, 2, stats::var) > 0, drop = FALSE]

if (ncol(trap_mat_condition_var) >= 2) {
  trap_pca <- stats::prcomp(sqrt(trap_mat_condition_var), center = TRUE, scale. = TRUE)
  trap_pc1 <- trap_pca$x[, 1]
  if (stats::cor(trap_pc1, analysis_df$cond_PC1, use = "pairwise.complete.obs") < 0) {
    trap_pc1 <- -trap_pc1
    trap_pca$rotation[, 1] <- -trap_pca$rotation[, 1]
  }

  analysis_df$trap_PC1 <- trap_pc1
  analysis_df$trap_PC1_z <- z_score(trap_pc1)

  trap_pca_loadings <- tibble::tibble(
    species = rownames(trap_pca$rotation),
    PC1_loading = trap_pca$rotation[, 1],
    PC2_loading = trap_pca$rotation[, 2],
    PC1_variance_explained = (trap_pca$sdev^2 / sum(trap_pca$sdev^2))[1],
    PC2_variance_explained = (trap_pca$sdev^2 / sum(trap_pca$sdev^2))[2]
  ) %>%
    dplyr::arrange(dplyr::desc(abs(PC1_loading)))

  readr::write_csv(trap_pca_loadings,
                   file.path(TAB_DIR, "trapezia_species_pca_loadings_condition44.csv"))

  trap_pc1_models <- dplyr::bind_rows(
    fit_condition_model(analysis_df, "trap_PC1_z", "unadjusted"),
    fit_condition_model(analysis_df, "trap_PC1_z", "treatment_adjusted")
  ) %>%
    dplyr::mutate(label = "Trapezia species composition PC1")

  readr::write_csv(trap_pc1_models,
                   file.path(TAB_DIR, "trapezia_pc1_condition_lmm_models.csv"))
} else {
  trap_pca_loadings <- tibble::tibble()
  trap_pc1_models <- tibble::tibble()
}

if (ncol(trap_mat_condition_var) >= 2) {
  coral_bray <- vegan::vegdist(sqrt(trap_mat_condition_var), method = "bray")
  coral_row_sums <- rowSums(trap_mat_condition_var)
  coral_trap_prop <- sweep(trap_mat_condition_var, 1, coral_row_sums, "/")
  coral_trap_prop[!is.finite(coral_trap_prop)] <- 0
  coral_bray_prop <- vegan::vegdist(coral_trap_prop, method = "bray")

  composition_tests <- dplyr::bind_rows(
    composition_tests,
    adonis_terms(coral_bray, coral_bray ~ cond_PC1 + treatment, analysis_df,
                 "colony condition subset", "sqrt Trapezia abundance"),
    adonis_terms(coral_bray_prop, coral_bray_prop ~ cond_PC1 + treatment, analysis_df,
                 "colony condition subset", "Trapezia relative composition")
  )
}

readr::write_csv(composition_tests,
                 file.path(TAB_DIR, "trapezia_composition_tests.csv"))

message("Building figures...")

plot_metric_labels <- c(
  trap_total = "Total Trapezia per colony",
  trap_serenei = "T. serenei per colony",
  trap_non_serenei = "Non-serenei Trapezia per colony",
  trap_prop_full = "Trapezia share of full CAFI"
)

p_treatment <- coral_metrics %>%
  dplyr::select(coral_id, reef, treatment, dplyr::all_of(names(plot_metric_labels))) %>%
  tidyr::pivot_longer(dplyr::all_of(names(plot_metric_labels)),
                      names_to = "metric", values_to = "value") %>%
  dplyr::mutate(metric = factor(metric, levels = names(plot_metric_labels),
                                labels = unname(plot_metric_labels))) %>%
  ggplot2::ggplot(ggplot2::aes(x = treatment, y = value, fill = treatment)) +
  ggplot2::geom_boxplot(width = 0.55, outlier.shape = NA, alpha = 0.75) +
  ggplot2::geom_point(position = ggplot2::position_jitter(width = 0.08, height = 0),
                      size = 1.6, alpha = 0.75) +
  ggplot2::facet_wrap(~ metric, scales = "free_y", ncol = 2) +
  ggplot2::scale_fill_manual(values = TREATMENT_COLORS, guide = "none") +
  ggplot2::labs(x = "Treatment: corals per reef", y = NULL,
                title = "Trapezia colony-level patterns by treatment") +
  theme_publication(base_size = 11)

save_plot(p_treatment, file.path(FIG_DIR, "trapezia_treatment_metrics_colony_all54"),
          width = 9, height = 7)

reef_plot_labels <- c(
  trap_density_per_colony = "Total Trapezia density",
  trap_serenei_density_per_colony = "T. serenei density",
  trap_non_serenei_density_per_colony = "Non-serenei density",
  trap_prop_full_reef = "Trapezia share of full CAFI"
)

p_reef_treatment <- reef_metrics %>%
  dplyr::select(reef, treatment, dplyr::all_of(names(reef_plot_labels))) %>%
  tidyr::pivot_longer(dplyr::all_of(names(reef_plot_labels)),
                      names_to = "metric", values_to = "value") %>%
  dplyr::mutate(metric = factor(metric, levels = names(reef_plot_labels),
                                labels = unname(reef_plot_labels))) %>%
  ggplot2::ggplot(ggplot2::aes(x = treatment, y = value, fill = treatment)) +
  ggplot2::geom_boxplot(width = 0.55, outlier.shape = NA, alpha = 0.75) +
  ggplot2::geom_point(position = ggplot2::position_jitter(width = 0.08, height = 0),
                      size = 2.0, alpha = 0.85) +
  ggplot2::facet_wrap(~ metric, scales = "free_y", ncol = 2) +
  ggplot2::scale_fill_manual(values = TREATMENT_COLORS, guide = "none") +
  ggplot2::labs(x = "Treatment: corals per reef", y = NULL,
                title = "Trapezia reef-level patterns by treatment") +
  theme_publication(base_size = 11)

save_plot(p_reef_treatment, file.path(FIG_DIR, "trapezia_treatment_metrics_reef_all27"),
          width = 9, height = 7)

condition_plot_df <- analysis_df %>%
  dplyr::select(coral_id, reef, treatment, cond_PC1,
                sqrt_trap_total, sqrt_trap_serenei, sqrt_trap_non_serenei,
                asin_trap_prop_full) %>%
  tidyr::pivot_longer(
    c(sqrt_trap_total, sqrt_trap_serenei, sqrt_trap_non_serenei, asin_trap_prop_full),
    names_to = "metric", values_to = "value"
  ) %>%
  dplyr::mutate(
    metric = factor(
      metric,
      levels = c("sqrt_trap_total", "sqrt_trap_serenei",
                 "sqrt_trap_non_serenei", "asin_trap_prop_full"),
      labels = c("sqrt total Trapezia", "sqrt T. serenei",
                 "sqrt non-serenei Trapezia", "arcsin sqrt Trapezia share")
    )
  )

p_condition <- ggplot2::ggplot(condition_plot_df,
                               ggplot2::aes(x = value, y = cond_PC1, color = treatment)) +
  ggplot2::geom_point(size = 2.2, alpha = 0.85) +
  ggplot2::geom_smooth(method = "lm", se = TRUE, color = "black",
                       linewidth = 0.65, formula = y ~ x) +
  ggplot2::facet_wrap(~ metric, scales = "free_x", ncol = 2) +
  ggplot2::scale_color_manual(values = TREATMENT_COLORS) +
  ggplot2::labs(x = NULL, y = "Coral condition PC1",
                color = "Treatment",
                title = "Trapezia metrics vs coral condition") +
  theme_publication(base_size = 11)

save_plot(p_condition, file.path(FIG_DIR, "trapezia_condition_associations"),
          width = 9, height = 7)

species_heatmap_df <- species_treatment_summary %>%
  dplyr::mutate(
    species = factor(species, levels = rev(species_summary_all$species)),
    log_mean_plus1 = log1p(mean_per_coral)
  )

p_heat <- ggplot2::ggplot(species_heatmap_df,
                          ggplot2::aes(x = treatment, y = species, fill = log_mean_plus1)) +
  ggplot2::geom_tile(color = "white", linewidth = 0.5) +
  ggplot2::geom_text(ggplot2::aes(label = sprintf("%.2f", mean_per_coral)), size = 3) +
  ggplot2::scale_fill_viridis_c(name = "log1p mean\nper coral") +
  ggplot2::labs(x = "Treatment: corals per reef", y = NULL,
                title = "Trapezia mean abundance by treatment") +
  theme_publication(base_size = 11) +
  ggplot2::theme(
    legend.position = "right",
    plot.title = ggplot2::element_text(size = 15, face = "bold", hjust = 0.5)
  )

save_plot(p_heat, file.path(FIG_DIR, "trapezia_species_treatment_heatmap"),
          width = 8, height = 5.5)

if (exists("trap_pca_loadings") && nrow(trap_pca_loadings) > 0 && "trap_PC1" %in% names(analysis_df)) {
  p_pc1 <- ggplot2::ggplot(analysis_df,
                           ggplot2::aes(x = trap_PC1, y = cond_PC1, color = treatment)) +
    ggplot2::geom_point(size = 2.2, alpha = 0.85) +
    ggplot2::geom_smooth(method = "lm", se = TRUE, color = "black",
                         linewidth = 0.65, formula = y ~ x) +
    ggplot2::scale_color_manual(values = TREATMENT_COLORS) +
    ggplot2::labs(x = "Trapezia composition PC1", y = "Coral condition PC1",
                  color = "Treatment",
                  title = "Trapezia species composition vs coral condition") +
    theme_publication(base_size = 11)

  save_plot(p_pc1, file.path(FIG_DIR, "trapezia_pc1_condition_association"),
            width = 7, height = 5.5)
}

message("Writing exploratory report...")

key_species_treatment <- species_treatment_summary %>%
  dplyr::filter(species %in% c("Trapezia serenei", "Trapezia tigrina", "Trapezia guttata")) %>%
  dplyr::mutate(
    mean_per_coral = fmt_num(mean_per_coral, 3),
    prevalence = fmt_num(prevalence, 3)
  ) %>%
  dplyr::select(species, treatment, total_count, mean_per_coral, n_present, prevalence)

key_metric_summary <- metric_treatment_summary_all %>%
  dplyr::filter(metric %in% c("trap_total", "trap_serenei", "trap_non_serenei",
                              "trap_rare_richness", "trap_prop_full")) %>%
  dplyr::mutate(mean = fmt_num(mean, 3), median = fmt_num(median, 3),
                nonzero_rate = fmt_num(nonzero_rate, 3)) %>%
  dplyr::select(metric, treatment, n, mean, median, n_nonzero, nonzero_rate)

key_reef_tests <- reef_treatment_tests %>%
  dplyr::mutate(
    lm_F = fmt_num(lm_F, 3),
    lm_r2 = fmt_num(lm_r2, 3),
    lm_p = fmt_p(lm_p),
    lm_p_BH = fmt_p(lm_p_BH),
    spearman_rho = fmt_num(spearman_rho, 3),
    spearman_p = fmt_p(spearman_p)
  ) %>%
  dplyr::select(metric, n, lm_F, lm_r2, lm_p, lm_p_BH, spearman_rho, spearman_p)

key_condition_models <- condition_metric_models %>%
  dplyr::filter(adjustment == "treatment_adjusted") %>%
  dplyr::mutate(
    estimate = fmt_num(estimate, 3),
    conf_low = fmt_num(conf_low, 3),
    conf_high = fmt_num(conf_high, 3),
    p_value = fmt_p(p_value),
    p_value_BH = fmt_p(p_value_BH)
  ) %>%
  dplyr::select(label, n, n_reefs, estimate, conf_low, conf_high, p_value, p_value_BH, singular)

key_species_condition <- condition_species_models %>%
  dplyr::filter(adjustment == "treatment_adjusted", predictor_type == "sqrt abundance z") %>%
  dplyr::arrange(p_value) %>%
  dplyr::mutate(
    estimate = fmt_num(estimate, 3),
    conf_low = fmt_num(conf_low, 3),
    conf_high = fmt_num(conf_high, 3),
    p_value = fmt_p(p_value),
    p_value_BH = fmt_p(p_value_BH)
  ) %>%
  dplyr::select(species, n, estimate, conf_low, conf_high, p_value, p_value_BH, note)

key_trait_cor <- trait_correlations %>%
  dplyr::filter(!is.na(p_value), p_value < 0.10) %>%
  dplyr::arrange(p_value) %>%
  dplyr::slice_head(n = 12) %>%
  dplyr::mutate(
    estimate = fmt_num(estimate, 3),
    p_value = fmt_p(p_value),
    p_value_BH = fmt_p(p_value_BH)
  ) %>%
  dplyr::select(label, trait, method, n, estimate, p_value, p_value_BH)

scaling_md <- if (nrow(scaling_trapezia) > 0) {
  scaling_trapezia %>%
    dplyr::mutate(
      Obs_t3 = fmt_num(Obs_t3, 3),
      Exp_t3 = fmt_num(Exp_t3, 3),
      Obs_t6 = fmt_num(Obs_t6, 3),
      Exp_t6 = fmt_num(Exp_t6, 3),
      Deviation_pct_t6 = fmt_num(Deviation_pct_t6, 3)
    ) %>%
    md_table()
} else {
  "_No Trapezia rows were present in the existing 38-species scaling table._"
}

composition_md <- if (nrow(composition_tests) > 0) {
  composition_tests %>%
    dplyr::mutate(
      statistic = fmt_num(statistic, 3),
      r2 = fmt_num(r2, 3),
      p_value = fmt_p(p_value)
    ) %>%
    md_table()
} else {
  "_Composition tests were skipped because the Trapezia matrix did not have enough variation._"
}

serenei_means <- species_treatment_summary %>%
  dplyr::filter(species == "Trapezia serenei") %>%
  dplyr::arrange(treatment)

top_condition_p <- condition_metric_models %>%
  dplyr::filter(adjustment == "treatment_adjusted", !is.na(p_value)) %>%
  dplyr::arrange(p_value) %>%
  dplyr::slice_head(n = 1)

top_species_condition_p <- condition_species_models %>%
  dplyr::filter(adjustment == "treatment_adjusted", predictor_type == "sqrt abundance z",
                !is.na(p_value)) %>%
  dplyr::arrange(p_value) %>%
  dplyr::slice_head(n = 1)

report_lines <- c(
  "# Exploratory Trapezia analysis",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Scope",
  "",
  paste0("- Raw CAFI treatment/community summaries use ", nrow(coral_metrics),
         " colonies on ", dplyr::n_distinct(coral_metrics$reef), " reefs."),
  paste0("- Coral-condition associations use ", nrow(analysis_df),
         " colonies on ", dplyr::n_distinct(analysis_df$reef),
         " reefs, matching the filtered growth/physiology condition data."),
  paste0("- Trapezia species detected: ", paste(trapezia_species, collapse = ", "), "."),
  paste0("- Condition PC1 explains ", scales::percent(cond_var_exp[1], accuracy = 0.1),
         " of standardized growth/physiology variance and is oriented so higher PC1 means higher overall condition."),
  "",
  "## Main read",
  "",
  paste0("- `Trapezia serenei` is the dominant and ubiquitous congener: ",
         species_summary_all$total_count_all54[species_summary_all$species == "Trapezia serenei"],
         " individuals across ",
         species_summary_all$n_corals_all54[species_summary_all$species == "Trapezia serenei"],
         " of 54 colonies. Any-Trapezia incidence is therefore not informative."),
  paste0("- Mean `T. serenei` abundance per colony by treatment was ",
         paste(paste0(serenei_means$treatment, "-coral: ",
                      fmt_num(serenei_means$mean_per_coral, 3)), collapse = "; "),
         ". This is the clearest treatment-direction signal."),
  paste0("- The existing 38-species proportional-scaling table classifies the Trapezia rows as not significant; use that rather than treating raw above-expected deviations as significant."),
  paste0("- In treatment-adjusted condition models, the smallest metric-level p-value was ",
         if (nrow(top_condition_p) == 0) "NA" else paste0(fmt_p(top_condition_p$p_value), " for ", top_condition_p$label),
         ". In species-level treatment-adjusted abundance models, the smallest p-value was ",
         if (nrow(top_species_condition_p) == 0) "NA" else paste0(fmt_p(top_species_condition_p$p_value), " for ", top_species_condition_p$species),
         ". These should be read as exploratory screens, not confirmatory tests."),
  "",
  "## Species abundance and incidence by treatment",
  "",
  md_table(key_species_treatment),
  "",
  "## Colony-level Trapezia metrics by treatment",
  "",
  md_table(key_metric_summary),
  "",
  "## Reef-level treatment tests",
  "",
  "Treatment was imposed at the reef scale, so this table is the main screen for treatment effects. P-values are exploratory and uncorrected plus BH-corrected within this family of reef-level tests.",
  "",
  md_table(key_reef_tests),
  "",
  "## Existing 38-species scaling rows",
  "",
  scaling_md,
  "",
  "## Condition PC1 models",
  "",
  "Estimates are change in condition PC1 per 1 SD increase in the transformed Trapezia predictor, with treatment included as a covariate and reef as a random intercept.",
  "",
  md_table(key_condition_models),
  "",
  "## Species-level condition models",
  "",
  md_table(key_species_condition),
  "",
  "## Nominal individual-trait correlations",
  "",
  "This table lists unadjusted p < 0.10 screens across transformed Trapezia metrics and individual condition traits. BH-adjusted p-values are included to show how fragile the nominal signals are.",
  "",
  md_table(key_trait_cor),
  "",
  "## Trapezia species composition tests",
  "",
  composition_md,
  "",
  "## Interpretation",
  "",
  "- The strongest Trapezia pattern is ecological rather than physiological: `T. serenei` is everywhere and has higher per-colony abundance in the multi-coral treatments, but the existing proportional-scaling table does not support calling it significantly above expected.",
  "- Rare congeners are too sparse for strong species-specific inference. Their incidence and richness are useful descriptors, but the sample sizes are small enough that isolated nominal results should not drive the manuscript.",
  "- I do not see a robust signal that Trapezia abundance, diversity, incidence, or relative contribution explains overall coral condition PC1 after accounting for treatment and reef structure.",
  "- The only places worth watching are physiology-specific screens, especially zooxanthellae-related correlations for dominant or moderately common congeners. Those are candidate story details only if they remain consistent with the broader manuscript and multiple-testing caveats.",
  "",
  "## Output files",
  "",
  "- Tables: `output/MRB/exploratory/trapezia/tables`",
  "- Figures: `output/MRB/exploratory/trapezia/figures`"
)

writeLines(report_lines, file.path(OUT_DIR, "trapezia_exploration_report.md"))

message("Done. Outputs written to: ", OUT_DIR)

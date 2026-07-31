# ==============================================================================
# Species-Inclusion Sensitivity Analysis for CAFI-136 MRB Manuscript Results
# ==============================================================================
# Purpose:
#   Test how each load-bearing CAFI result changes as the community matrix includes
#   different numbers and types of taxa.
#
# Sensitivity axes:
#   1. Ranked top-N species sets based on total abundance in the full CAFI census.
#   2. The corrected manuscript 10x10 scaling set from scaling_table_38species_1row.csv.
#   3. The full observed community.
#   4. A functional "obligate/strong coral-associated + damselfish" subset.
#
# Important scope distinction:
#   - Abundance/scaling results are evaluated on the full CAFI/treatment data.
#   - Beta diversity and CAFI-condition results use the growth/physiology subset,
#     matching the condition-analysis universe.
#
# Outputs:
#   output/MRB/tables/species_inclusion_sensitivity_long.csv
#   output/MRB/tables/species_inclusion_sensitivity_result_summary.csv
#   output/MRB/tables/species_inclusion_sensitivity_functional_subset.csv
#   output/MRB/tables/species_inclusion_sensitivity_scaling_species.csv
#   output/MRB/tables/species_inclusion_sensitivity_species_condition.csv
#   output/MRB/tables/species_inclusion_sensitivity_scenarios.csv
#   output/MRB/tables/species_inclusion_sensitivity_design.md
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(purrr)
  library(stringr)
  library(tibble)
  library(forcats)
  library(vegan)
  library(cluster)
  library(lme4)
  library(lmerTest)
  library(broom.mixed)
  library(car)
  library(here)
})

set.seed(20260730)
options(stringsAsFactors = FALSE, scipen = 999, dplyr.summarise.inform = FALSE)

TAB_DIR <- here::here("output", "MRB", "tables")
dir.create(TAB_DIR, recursive = TRUE, showWarnings = FALSE)

BOOT_B <- 2000L
PERM_N <- 999L
ALPHA <- 0.05

strip_fe_local <- function(x) stringr::str_remove(as.character(x), "^FE-")

safe_p <- function(x) {
  ifelse(is.finite(x), x, NA_real_)
}

sig_label <- function(p) {
  dplyr::case_when(
    is.na(p) ~ NA_character_,
    p < 0.001 ~ "***",
    p < 0.01 ~ "**",
    p < 0.05 ~ "*",
    p < 0.10 ~ ".",
    TRUE ~ "NS"
  )
}

safe_scale <- function(X) {
  X <- as.matrix(X)
  sds <- apply(X, 2, stats::sd, na.rm = TRUE)
  means <- colMeans(X, na.rm = TRUE)
  Z <- sweep(X, 2, means, "-")
  ok <- is.finite(sds) & sds > 0
  Z[, ok] <- sweep(Z[, ok, drop = FALSE], 2, sds[ok], "/")
  Z[, !ok] <- 0
  Z[!is.finite(Z)] <- 0
  Z
}

drop_zero_variance <- function(mat) {
  mat <- as.matrix(mat)
  if (ncol(mat) == 0) return(mat)
  keep_sum <- colSums(abs(mat), na.rm = TRUE) > 0
  mat <- mat[, keep_sum, drop = FALSE]
  if (ncol(mat) == 0) return(mat)
  v <- apply(mat, 2, stats::var, na.rm = TRUE)
  mat[, is.finite(v) & v > 0, drop = FALSE]
}

np_sum_ci <- function(x, k, B = BOOT_B, probs = c(0.025, 0.5, 0.975), seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  n <- length(x)
  if (n == 0L || k < 1L || B < 1L) {
    return(setNames(rep(NA_real_, length(probs)), paste0("p", probs)))
  }
  draw <- sample.int(n, size = k * B, replace = TRUE)
  sm <- colSums(matrix(x[draw], nrow = k))
  stats::quantile(sm, probs = probs, names = TRUE, type = 7)
}

mean_ci <- function(x) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  n <- length(x)
  if (n == 0) {
    return(tibble(mean = NA_real_, sd = NA_real_, n = 0L,
                  lo = NA_real_, hi = NA_real_))
  }
  s <- stats::sd(x)
  if (!is.finite(s)) s <- 0
  tibble(
    mean = mean(x),
    sd = s,
    n = n,
    lo = mean(x) - 1.96 * s / sqrt(n),
    hi = mean(x) + 1.96 * s / sqrt(n)
  )
}

make_wide_matrix <- function(df, unit_col, units_keep, species_keep) {
  species_keep <- unique(species_keep[!is.na(species_keep) & species_keep != ""])
  units_keep <- unique(units_keep[!is.na(units_keep) & units_keep != ""])
  if (length(species_keep) == 0 || length(units_keep) == 0) {
    out <- matrix(nrow = length(units_keep), ncol = 0)
    rownames(out) <- units_keep
    return(out)
  }

  unit_sym <- rlang::sym(unit_col)
  base <- tidyr::expand_grid(
    unit = units_keep,
    species = species_keep
  )

  agg <- df %>%
    dplyr::filter(species %in% species_keep, .data[[unit_col]] %in% units_keep) %>%
    dplyr::group_by(!!unit_sym, species) %>%
    dplyr::summarise(abundance = sum(count, na.rm = TRUE), .groups = "drop") %>%
    dplyr::rename(unit = !!unit_sym)

  wide <- base %>%
    dplyr::left_join(agg, by = c("unit", "species")) %>%
    dplyr::mutate(abundance = tidyr::replace_na(abundance, 0)) %>%
    tidyr::pivot_wider(names_from = species, values_from = abundance, values_fill = 0) %>%
    dplyr::arrange(match(unit, units_keep))

  mat <- wide %>%
    tibble::column_to_rownames("unit") %>%
    as.matrix()
  storage.mode(mat) <- "numeric"
  mat
}

fit_treatment_lmm <- function(df, response_col) {
  if (!all(c(response_col, "treatment", "reef") %in% names(df))) {
    return(tibble(statistic = NA_real_, df = NA_real_, p_value = NA_real_,
                  estimate = NA_real_, direction = NA_character_, n = nrow(df)))
  }
  dat <- df %>%
    dplyr::filter(!is.na(.data[[response_col]]), !is.na(treatment), !is.na(reef)) %>%
    dplyr::mutate(treatment = factor(as.character(treatment), levels = c("1", "3", "6")),
                  reef = factor(reef))
  if (nrow(dat) < 10 || dplyr::n_distinct(dat$treatment) < 2 || dplyr::n_distinct(dat$reef) < 2) {
    return(tibble(statistic = NA_real_, df = NA_real_, p_value = NA_real_,
                  estimate = NA_real_, direction = NA_character_, n = nrow(dat)))
  }
  out <- tryCatch({
    full <- lmerTest::lmer(
      stats::as.formula(paste0(response_col, " ~ treatment + (1|reef)")),
      data = dat,
      REML = FALSE,
      control = lme4::lmerControl(check.conv.singular = "ignore")
    )
    null <- lmerTest::lmer(
      stats::as.formula(paste0(response_col, " ~ 1 + (1|reef)")),
      data = dat,
      REML = FALSE,
      control = lme4::lmerControl(check.conv.singular = "ignore")
    )
    lrt <- stats::anova(null, full)
    means <- dat %>%
      dplyr::group_by(treatment) %>%
      dplyr::summarise(mu = mean(.data[[response_col]], na.rm = TRUE), .groups = "drop")
    mu1 <- means$mu[means$treatment == "1"]
    mu6 <- means$mu[means$treatment == "6"]
    effect <- if (length(mu1) && length(mu6)) mu6 - mu1 else NA_real_
    tibble(
      statistic = unname(lrt$Chisq[2]),
      df = unname(lrt$Df[2]),
      p_value = safe_p(lrt$`Pr(>Chisq)`[2]),
      estimate = effect,
      direction = dplyr::case_when(
        is.na(effect) ~ NA_character_,
        effect > 0 ~ "positive",
        effect < 0 ~ "negative",
        TRUE ~ "zero"
      ),
      n = nrow(dat)
    )
  }, error = function(e) {
    tibble(statistic = NA_real_, df = NA_real_, p_value = NA_real_,
           estimate = NA_real_, direction = NA_character_, n = nrow(dat))
  })
  out
}

fit_numeric_lmm <- function(df, response_col, predictor_col) {
  dat <- df %>%
    dplyr::filter(!is.na(.data[[response_col]]), !is.na(.data[[predictor_col]]), !is.na(reef)) %>%
    dplyr::mutate(reef = factor(reef))
  if (nrow(dat) < 10 || dplyr::n_distinct(dat$reef) < 2 ||
      stats::var(dat[[predictor_col]], na.rm = TRUE) <= 0) {
    return(tibble(estimate = NA_real_, std_error = NA_real_, df = NA_real_,
                  statistic = NA_real_, p_value = NA_real_,
                  conf_low = NA_real_, conf_high = NA_real_, n = nrow(dat)))
  }
  out <- tryCatch({
    model <- lmerTest::lmer(
      stats::as.formula(paste0(response_col, " ~ ", predictor_col, " + (1|reef)")),
      data = dat,
      REML = TRUE,
      control = lme4::lmerControl(check.conv.singular = "ignore")
    )
    row <- broom.mixed::tidy(model, effects = "fixed", conf.int = TRUE) %>%
      dplyr::filter(term == predictor_col)
    tibble(
      estimate = row$estimate,
      std_error = row$std.error,
      df = row$df,
      statistic = row$statistic,
      p_value = safe_p(row$p.value),
      conf_low = row$conf.low,
      conf_high = row$conf.high,
      n = nrow(dat)
    )
  }, error = function(e) {
    tibble(estimate = NA_real_, std_error = NA_real_, df = NA_real_,
           statistic = NA_real_, p_value = NA_real_,
           conf_low = NA_real_, conf_high = NA_real_, n = nrow(dat))
  })
  out
}

make_distance <- function(mat, metric) {
  metric <- match.arg(metric, c("bray_sqrt", "jaccard", "gower_sqrt_z"))
  mat <- as.matrix(mat)
  if (metric == "bray_sqrt") {
    vegan::vegdist(sqrt(mat), method = "bray")
  } else if (metric == "jaccard") {
    vegan::vegdist((mat > 0) * 1, method = "jaccard", binary = TRUE)
  } else {
    as.dist(cluster::daisy(safe_scale(sqrt(mat)), metric = "gower"))
  }
}

run_permanova <- function(mat, meta, metric) {
  mat <- drop_zero_variance(mat)
  if (ncol(mat) < 2) {
    return(tibble(metric = metric, statistic = NA_real_, df = NA_real_,
                  R2 = NA_real_, p_value = NA_real_, n_units = nrow(mat)))
  }
  keep <- rowSums(mat, na.rm = TRUE) > 0
  mat <- mat[keep, , drop = FALSE]
  meta <- meta[match(rownames(mat), meta$unit), , drop = FALSE]
  meta <- meta %>% dplyr::mutate(treatment = factor(as.character(treatment), levels = c("1", "3", "6")))
  if (nrow(meta) < 6 || dplyr::n_distinct(meta$treatment) < 2) {
    return(tibble(metric = metric, statistic = NA_real_, df = NA_real_,
                  R2 = NA_real_, p_value = NA_real_, n_units = nrow(meta)))
  }
  out <- tryCatch({
    dist_obj <- make_distance(mat, metric)
    ad <- vegan::adonis2(dist_obj ~ treatment, data = meta, permutations = PERM_N)
    tibble(
      metric = metric,
      statistic = ad$F[1],
      df = ad$Df[1],
      R2 = ad$R2[1],
      p_value = safe_p(ad$`Pr(>F)`[1]),
      n_units = nrow(meta)
    )
  }, error = function(e) {
    tibble(metric = metric, statistic = NA_real_, df = NA_real_,
           R2 = NA_real_, p_value = NA_real_, n_units = nrow(meta))
  })
  out
}

calc_alpha <- function(mat) {
  mat <- as.matrix(mat)
  richness <- vegan::specnumber(mat)
  shannon <- vegan::diversity(mat, index = "shannon")
  simpson <- vegan::diversity(mat, index = "simpson")
  row_totals <- rowSums(mat)
  positive_totals <- row_totals[row_totals > 0]
  rarefied <- rep(0, nrow(mat))
  if (length(positive_totals) > 0) {
    sample_size <- max(1, min(positive_totals))
    rarefied[row_totals > 0] <- suppressWarnings(
      as.numeric(vegan::rarefy(mat[row_totals > 0, , drop = FALSE], sample = sample_size))
    )
  }
  tibble(
    unit = rownames(mat),
    richness = replace(richness, !is.finite(richness), 0),
    rarefied_richness = replace(rarefied, !is.finite(rarefied), 0),
    shannon = replace(shannon, !is.finite(shannon), 0),
    simpson = replace(simpson, !is.finite(simpson), 0)
  )
}

run_comm_pca <- function(mat, transform, cond_scores) {
  transform <- match.arg(transform, c("SQRT_CS", "HELLINGER", "SQRT"))
  mat <- drop_zero_variance(mat)
  if (ncol(mat) < 2) return(NULL)

  X <- switch(
    transform,
    SQRT_CS = sqrt(mat),
    HELLINGER = {
      H <- vegan::decostand(mat, method = "hellinger")
      H[!is.finite(H)] <- 0
      H
    },
    SQRT = sqrt(mat)
  )
  X <- drop_zero_variance(X)
  if (ncol(X) < 2) return(NULL)

  center <- transform %in% c("SQRT_CS", "HELLINGER")
  scale_flag <- transform %in% c("SQRT_CS", "HELLINGER")

  out <- tryCatch({
    pca <- stats::prcomp(X, center = center, scale. = scale_flag)
    scores <- tibble(unit = rownames(X), PC1 = pca$x[, 1])
    common <- intersect(scores$unit, cond_scores$unit)
    if (length(common) >= 3) {
      cc <- suppressWarnings(cor(
        scores$PC1[match(common, scores$unit)],
        cond_scores$condition_PC1[match(common, cond_scores$unit)],
        use = "pairwise.complete.obs"
      ))
      if (is.finite(cc) && cc < 0) {
        scores$PC1 <- -scores$PC1
        pca$rotation[, 1] <- -pca$rotation[, 1]
      }
    }
    list(
      scores = scores,
      var_pc1 = (pca$sdev[1]^2) / sum(pca$sdev^2),
      n_species_used = ncol(X)
    )
  }, error = function(e) NULL)
  out
}

run_total_scaling <- function(reef_mat, reef_meta) {
  df <- tibble(unit = rownames(reef_mat), total = rowSums(reef_mat)) %>%
    dplyr::left_join(reef_meta, by = "unit") %>%
    dplyr::filter(!is.na(treatment)) %>%
    dplyr::mutate(treatment = as.integer(as.character(treatment)))

  t1 <- df$total[df$treatment == 1]
  purrr::map_dfr(c(3L, 6L), function(k) {
    obs <- mean_ci(df$total[df$treatment == k])
    exp_ci <- np_sum_ci(t1, k = k, B = BOOT_B, seed = 1000 + k)
    direction <- dplyr::case_when(
      is.na(obs$mean) | any(is.na(exp_ci)) ~ NA_character_,
      obs$hi < exp_ci[1] ~ "Below Expected",
      obs$lo > exp_ci[3] ~ "Above Expected",
      TRUE ~ "Proportional"
    )
    exp_param <- mean(t1, na.rm = TRUE) * k
    tibble(
      treatment = k,
      observed_mean = obs$mean,
      observed_lo = obs$lo,
      observed_hi = obs$hi,
      expected_median = unname(exp_ci[2]),
      expected_lo = unname(exp_ci[1]),
      expected_hi = unname(exp_ci[3]),
      expected_parametric = exp_param,
      deviation_pct = ifelse(exp_param > 0, 100 * (obs$mean - exp_param) / exp_param, NA_real_),
      direction = direction
    )
  })
}

run_species_scaling <- function(reef_mat, reef_meta) {
  df_long <- as.data.frame(reef_mat) %>%
    tibble::rownames_to_column("unit") %>%
    tidyr::pivot_longer(-unit, names_to = "species", values_to = "abundance") %>%
    dplyr::left_join(reef_meta, by = "unit") %>%
    dplyr::filter(!is.na(treatment)) %>%
    dplyr::mutate(treatment = as.integer(as.character(treatment)))

  species <- colnames(reef_mat)
  purrr::map_dfr(species, function(sp) {
    sp_df <- df_long %>% dplyr::filter(species == sp)
    t1 <- sp_df$abundance[sp_df$treatment == 1]
    purrr::map_dfr(c(3L, 6L), function(k) {
      obs <- mean_ci(sp_df$abundance[sp_df$treatment == k])
      exp_ci <- np_sum_ci(t1, k = k, B = BOOT_B, seed = 2000 + k + match(sp, species))
      direction <- dplyr::case_when(
        is.na(obs$mean) | any(is.na(exp_ci)) ~ NA_character_,
        obs$hi < exp_ci[1] ~ "Below Expected",
        obs$lo > exp_ci[3] ~ "Above Expected",
        TRUE ~ "Proportional"
      )
      exp_param <- mean(t1, na.rm = TRUE) * k
      tibble(
        species = sp,
        treatment = k,
        observed_mean = obs$mean,
        expected_median = unname(exp_ci[2]),
        expected_parametric = exp_param,
        deviation_pct = ifelse(exp_param > 0, 100 * (obs$mean - exp_param) / exp_param, NA_real_),
        direction = direction,
        significant = direction != "Proportional"
      )
    })
  })
}

run_species_condition <- function(coral_mat, cond_model_df, species_keep) {
  mat <- as.matrix(coral_mat)
  if (ncol(mat) == 0) return(tibble())
  purrr::map_dfr(colnames(mat), function(sp) {
    df <- tibble(unit = rownames(mat), species_count = mat[, sp]) %>%
      dplyr::left_join(cond_model_df, by = "unit") %>%
      dplyr::mutate(sqrt_count = sqrt(species_count))
    fit <- fit_numeric_lmm(df, "condition_PC1", "sqrt_count")
    fit %>%
      dplyr::mutate(
        species = sp,
        included = sp %in% species_keep,
        direction = dplyr::case_when(
          estimate > 0 ~ "positive",
          estimate < 0 ~ "negative",
          TRUE ~ "zero"
        )
      )
  }) %>%
    dplyr::group_by() %>%
    dplyr::mutate(
      p_adj_BH = stats::p.adjust(p_value, method = "BH"),
      significant_BH = p_adj_BH < ALPHA
    )
}

as_result_row <- function(result_key, result_label, scenario, analysis_scope,
                          estimate = NA_real_, statistic = NA_real_, df = NA_real_,
                          R2 = NA_real_, p_value = NA_real_, significant = NA,
                          direction = NA_character_, metric = NA_character_,
                          n_units = NA_integer_, details = NA_character_) {
  tibble(
    result_key = result_key,
    result_label = result_label,
    analysis_scope = analysis_scope,
    scenario_id = scenario$scenario_id,
    scenario_type = scenario$scenario_type,
    requested_n_species = scenario$requested_n_species,
    n_species_full_scope = scenario$n_species_full_scope,
    n_species_condition_scope = scenario$n_species_condition_scope,
    metric = metric,
    estimate = estimate,
    statistic = statistic,
    df = df,
    R2 = R2,
    p_value = safe_p(p_value),
    significant = significant,
    direction = direction,
    n_units = n_units,
    details = details,
    stars = sig_label(p_value)
  )
}

# ==============================================================================
# Load data
# ==============================================================================

message("Loading raw CAFI, treatment, growth, and physiology data...")

cafi_raw <- readr::read_csv(
  here::here("data", "MRB Amount", "1. mrb_fe_cafi_summer_2021_v4_AP_updated_2024.csv"),
  show_col_types = FALSE
) %>%
  dplyr::mutate(
    coral_id = strip_fe_local(coral_id),
    species = trimws(as.character(species)),
    count = as.numeric(count),
    genus = as.character(genus),
    family = as.character(family)
  ) %>%
  dplyr::filter(!is.na(coral_id), !is.na(species), species != "", !is.na(count), count >= 0)

treat_df <- readr::read_csv(
  here::here("data", "MRB Amount", "coral_id_position_treatment.csv"),
  show_col_types = FALSE
) %>%
  dplyr::mutate(
    coral_id = strip_fe_local(coral_id),
    row = stringr::str_extract(position, "^\\d+"),
    column = stringr::str_extract(position, "(?<=-)\\d+"),
    reef = paste0("Reef_", row, "-", column),
    treatment = factor(as.character(treatment), levels = c("1", "3", "6"))
  ) %>%
  dplyr::select(coral_id, reef, treatment)

cafi_full <- cafi_raw %>%
  dplyr::left_join(treat_df, by = "coral_id") %>%
  dplyr::filter(!is.na(reef), !is.na(treatment))

growth <- readr::read_csv(here::here("data", "processed", "coral_growth.csv"), show_col_types = FALSE) %>%
  dplyr::mutate(
    coral_id = strip_fe_local(coral_id),
    treatment = factor(as.character(treatment), levels = c("1", "3", "6")),
    reef = as.character(reef)
  )

physio <- readr::read_csv(
  here::here("output", "MRB", "figures", "coral", "physio", "physio_metrics_plus_growth_filtered.csv"),
  show_col_types = FALSE
) %>%
  dplyr::mutate(
    coral_id = strip_fe_local(coral_id),
    treatment = factor(as.character(treatment), levels = c("1", "3", "6")),
    reef = as.character(reef)
  )

condition_df <- growth %>%
  dplyr::select(coral_id, reef, treatment, growth_vol_b) %>%
  dplyr::inner_join(
    physio %>%
      dplyr::select(coral_id, protein_mg_cm2, carb_mg_cm2, zoox_cells_cm2, afdw_mg_cm2),
    by = "coral_id"
  ) %>%
  tidyr::drop_na(growth_vol_b, protein_mg_cm2, carb_mg_cm2, zoox_cells_cm2, afdw_mg_cm2)

cond_mat <- condition_df %>%
  dplyr::select(growth_vol_b, protein_mg_cm2, carb_mg_cm2, zoox_cells_cm2, afdw_mg_cm2) %>%
  as.matrix()
rownames(cond_mat) <- condition_df$coral_id
cond_z <- scale(cond_mat)
cond_pca <- stats::prcomp(cond_z, center = FALSE, scale. = FALSE)
cond_scores_vec <- cond_pca$x[, 1]
cond_loadings <- cond_pca$rotation[, 1]
if (sum(cond_loadings, na.rm = TRUE) < 0) {
  cond_scores_vec <- -cond_scores_vec
  cond_loadings <- -cond_loadings
}

cond_scores <- tibble(
  unit = names(cond_scores_vec),
  condition_PC1 = as.numeric(cond_scores_vec)
)

cond_model_df <- condition_df %>%
  dplyr::transmute(
    unit = coral_id,
    coral_id,
    reef,
    treatment,
    condition_PC1 = cond_scores$condition_PC1[match(coral_id, cond_scores$unit)]
  )

cafi_condition_scope <- cafi_full %>%
  dplyr::filter(coral_id %in% condition_df$coral_id)

species_meta_full <- cafi_full %>%
  dplyr::group_by(species) %>%
  dplyr::summarise(
    total_count = sum(count, na.rm = TRUE),
    prevalence = dplyr::n_distinct(coral_id[count > 0]),
    genus = dplyr::first(na.omit(genus)),
    family = dplyr::first(na.omit(family)),
    .groups = "drop"
  ) %>%
  dplyr::arrange(dplyr::desc(total_count), dplyr::desc(prevalence), species) %>%
  dplyr::mutate(abundance_rank = dplyr::row_number())

all_species_ranked <- species_meta_full$species

species_meta_condition <- cafi_condition_scope %>%
  dplyr::group_by(species) %>%
  dplyr::summarise(
    total_count_condition = sum(count, na.rm = TRUE),
    prevalence_condition = dplyr::n_distinct(coral_id[count > 0]),
    .groups = "drop"
  )

reef_meta_full <- cafi_full %>%
  dplyr::distinct(reef, treatment) %>%
  dplyr::rename(unit = reef)

reef_meta_condition <- cafi_condition_scope %>%
  dplyr::distinct(reef, treatment) %>%
  dplyr::rename(unit = reef)

coral_meta_condition <- condition_df %>%
  dplyr::transmute(unit = coral_id, reef, treatment)

# ==============================================================================
# Define species-inclusion scenarios
# ==============================================================================

top_n_grid <- c(5, 10, 15, 20, 25, 30, 38, 50, 75, 100)
top_n_grid <- unique(top_n_grid[top_n_grid < length(all_species_ranked)])

ranked_scenarios <- purrr::map(top_n_grid, function(n) {
  tibble(
    scenario_id = sprintf("top_%03d_by_abundance", n),
    scenario_type = "ranked_top_N",
    requested_n_species = n,
    species = list(all_species_ranked[seq_len(n)])
  )
}) %>% dplyr::bind_rows()

main_species_file <- here::here("output", "MRB", "data", "scaling_table_38species_1row.csv")
main_species <- if (file.exists(main_species_file)) {
  readr::read_csv(main_species_file, show_col_types = FALSE) %>%
    dplyr::pull(Species) %>%
    unique()
} else {
  species_meta_full %>%
    dplyr::filter(total_count >= 10, prevalence >= 10) %>%
    dplyr::pull(species)
}

damselfish_species <- species_meta_full %>%
  dplyr::filter(family == "Pomacentridae" | genus == "Dascyllus") %>%
  dplyr::pull(species)

obligate_strong_coral_species <- intersect(
  all_species_ranked,
  c(
    "Caracanthus maculatus",
    "Paragobiodon modestus", "Paragobiodon lacunicolus",
    "Gobiodon unicolor",
    "Trapezia serenei", "Trapezia tigrina", "Trapezia guttata",
    "Trapezia bidentata", "Trapezia areolata", "Trapezia punctimanus",
    "Trapezia bella", "Trapezia speciosa",
    "Tetralia ocucaerulea",
    "Harpiliopsis spinigera", "Harpiliopsis beaupresii", "Harpiliopsis depressa",
    "Periclimenes watamuae", "Fennera chacei",
    "Alpheus lottini", "Alpheus diadema", "Synalpheus charon",
    "Coralliogalathea humilis"
  )
)

functional_species <- unique(c(obligate_strong_coral_species, damselfish_species))

reference_scenarios <- tibble(
  scenario_id = c("main_38_10x10_corrected", "all_observed_species", "obligate_plus_damselfish", "damselfish_only"),
  scenario_type = c("reference_main", "reference_full", "functional_subset", "functional_subset"),
  requested_n_species = c(length(main_species), length(all_species_ranked), length(functional_species), length(damselfish_species)),
  species = list(main_species, all_species_ranked, functional_species, damselfish_species)
)

scenarios <- dplyr::bind_rows(ranked_scenarios, reference_scenarios) %>%
  dplyr::mutate(
    species = purrr::map(species, ~ intersect(unique(.x), all_species_ranked)),
    n_species_full_scope = purrr::map_int(species, length),
    n_species_condition_scope = purrr::map_int(
      species,
      ~ sum(.x %in% species_meta_condition$species[species_meta_condition$total_count_condition > 0])
    )
  )

scenario_species_sets <- scenarios %>%
  dplyr::select(scenario_id, scenario_type, requested_n_species,
                n_species_full_scope, n_species_condition_scope, species) %>%
  tidyr::unnest(species) %>%
  dplyr::left_join(species_meta_full, by = "species") %>%
  dplyr::left_join(species_meta_condition, by = "species") %>%
  dplyr::arrange(scenario_id, abundance_rank)

readr::write_csv(
  scenario_species_sets,
  file.path(TAB_DIR, "species_inclusion_sensitivity_scenarios.csv")
)

# ==============================================================================
# Run all sensitivity analyses
# ==============================================================================

message("Running sensitivity analyses across ", nrow(scenarios), " scenarios...")

all_result_rows <- list()
all_scaling_species <- list()
all_species_condition <- list()

focal_species <- c(
  "Caracanthus maculatus",
  "Luniella pugil",
  "Alpheus diadema",
  "Calcinus latens",
  "Harpiliopsis spinigera",
  "Dascyllus flavicaudus",
  "Dascyllus aruanus",
  "Trapezia serenei",
  "Xanthias lamarckii",
  "Mitrella moleculina",
  "Morula zebrina"
)

for (i in seq_len(nrow(scenarios))) {
  scenario <- scenarios[i, ]
  species_keep <- scenario$species[[1]]
  message("  Scenario ", scenario$scenario_id, " (", length(species_keep), " species)")

  # Matrices for each analysis scope.
  reef_mat_full <- make_wide_matrix(
    cafi_full,
    unit_col = "reef",
    units_keep = reef_meta_full$unit,
    species_keep = species_keep
  )
  coral_mat_condition <- make_wide_matrix(
    cafi_condition_scope,
    unit_col = "coral_id",
    units_keep = condition_df$coral_id,
    species_keep = species_keep
  )
  reef_mat_condition <- make_wide_matrix(
    cafi_condition_scope,
    unit_col = "reef",
    units_keep = reef_meta_condition$unit,
    species_keep = species_keep
  )

  # 1. Total CAFI abundance scaling under Field of Dreams.
  total_scaling <- run_total_scaling(reef_mat_full, reef_meta_full)
  t6_scaling <- total_scaling %>% dplyr::filter(treatment == 6)
  all_result_rows[[length(all_result_rows) + 1]] <- as_result_row(
    "total_abundance_scaling_t6",
    "Total CAFI abundance in 6-coral reefs vs proportional expectation",
    scenario,
    "full CAFI reef-level abundance",
    estimate = t6_scaling$deviation_pct,
    significant = t6_scaling$direction != "Proportional",
    direction = t6_scaling$direction,
    metric = "percent deviation from 6 x mean single-coral reef",
    n_units = nrow(reef_mat_full),
    details = sprintf("obs=%.2f; expected=%.2f; bootstrap class=%s",
                      t6_scaling$observed_mean,
                      t6_scaling$expected_parametric,
                      t6_scaling$direction)
  )

  # 2. Species-level scaling identities and counts.
  species_scaling <- run_species_scaling(reef_mat_full, reef_meta_full) %>%
    dplyr::mutate(
      scenario_id = scenario$scenario_id,
      scenario_type = scenario$scenario_type,
      n_species_full_scope = scenario$n_species_full_scope
    )
  all_scaling_species[[length(all_scaling_species) + 1]] <- species_scaling

  species_scaling_summary <- species_scaling %>%
    dplyr::group_by(species) %>%
    dplyr::summarise(
      sig_above_any = any(direction == "Above Expected", na.rm = TRUE),
      sig_below_any = any(direction == "Below Expected", na.rm = TRUE),
      sig_any = any(significant, na.rm = TRUE),
      t6_deviation_pct = deviation_pct[treatment == 6][1],
      t6_point_dir = dplyr::case_when(
        is.na(t6_deviation_pct) ~ NA_character_,
        t6_deviation_pct >= 0 ~ "Above",
        TRUE ~ "Below"
      ),
      .groups = "drop"
    )

  sig_above_species <- species_scaling_summary %>%
    dplyr::filter(sig_above_any) %>%
    dplyr::pull(species)
  sig_below_species <- species_scaling_summary %>%
    dplyr::filter(sig_below_any) %>%
    dplyr::pull(species)

  all_result_rows[[length(all_result_rows) + 1]] <- as_result_row(
    "species_scaling_sig_above_count",
    "Number of species significantly above proportional scaling",
    scenario,
    "full CAFI reef-level abundance",
    estimate = length(sig_above_species),
    significant = length(sig_above_species) > 0,
    direction = "count",
    metric = "CI non-overlap count",
    n_units = length(species_keep),
    details = paste(sig_above_species, collapse = "; ")
  )
  all_result_rows[[length(all_result_rows) + 1]] <- as_result_row(
    "species_scaling_sig_below_count",
    "Number of species significantly below proportional scaling",
    scenario,
    "full CAFI reef-level abundance",
    estimate = length(sig_below_species),
    significant = length(sig_below_species) > 0,
    direction = "count",
    metric = "CI non-overlap count",
    n_units = length(species_keep),
    details = paste(sig_below_species, collapse = "; ")
  )
  all_result_rows[[length(all_result_rows) + 1]] <- as_result_row(
    "species_scaling_point_above_pct_t6",
    "Percent of included species with observed 6-coral density above proportional expectation",
    scenario,
    "full CAFI reef-level abundance",
    estimate = 100 * mean(species_scaling_summary$t6_point_dir == "Above", na.rm = TRUE),
    significant = NA,
    direction = ifelse(
      mean(species_scaling_summary$t6_point_dir == "Above", na.rm = TRUE) >= 0.5,
      "mostly above", "mostly below"
    ),
    metric = "point-estimate percent",
    n_units = length(species_keep),
    details = sprintf("%d above; %d below",
                      sum(species_scaling_summary$t6_point_dir == "Above", na.rm = TRUE),
                      sum(species_scaling_summary$t6_point_dir == "Below", na.rm = TRUE))
  )

  # 3. Alpha diversity treatment effects.
  alpha_df <- calc_alpha(coral_mat_condition) %>%
    dplyr::left_join(coral_meta_condition, by = "unit")
  for (metric_nm in c("richness", "rarefied_richness", "shannon", "simpson")) {
    fit <- fit_treatment_lmm(alpha_df, metric_nm)
    all_result_rows[[length(all_result_rows) + 1]] <- as_result_row(
      paste0("alpha_", metric_nm, "_treatment"),
      paste0("Treatment effect on ", stringr::str_replace_all(metric_nm, "_", " ")),
      scenario,
      "condition-subset coral-level alpha diversity",
      estimate = fit$estimate,
      statistic = fit$statistic,
      df = fit$df,
      p_value = fit$p_value,
      significant = fit$p_value < ALPHA,
      direction = fit$direction,
      metric = "LMM treatment LRT; estimate is mean(6) - mean(1)",
      n_units = fit$n
    )
  }

  # 4. Reef-level community composition treatment effect.
  for (dist_metric in c("gower_sqrt_z", "jaccard", "bray_sqrt")) {
    ad <- run_permanova(reef_mat_condition, reef_meta_condition, dist_metric)
    all_result_rows[[length(all_result_rows) + 1]] <- as_result_row(
      paste0("beta_permanova_", dist_metric),
      paste0("Treatment effect on community composition: ", dist_metric),
      scenario,
      "condition-subset reef-level beta diversity",
      estimate = ad$R2,
      statistic = ad$statistic,
      df = ad$df,
      R2 = ad$R2,
      p_value = ad$p_value,
      significant = ad$p_value < ALPHA,
      direction = NA_character_,
      metric = "PERMANOVA/adonis2",
      n_units = ad$n_units
    )
  }

  # 5. CAFI PC1 treatment and condition links.
  for (transform in c("SQRT_CS", "HELLINGER", "SQRT")) {
    pc <- run_comm_pca(coral_mat_condition, transform, cond_scores)
    if (is.null(pc)) {
      next
    }
    pc_df <- pc$scores %>%
      dplyr::left_join(coral_meta_condition, by = "unit") %>%
      dplyr::left_join(cond_model_df %>% dplyr::select(unit, condition_PC1), by = "unit")

    treatment_fit <- fit_treatment_lmm(pc_df, "PC1")
    all_result_rows[[length(all_result_rows) + 1]] <- as_result_row(
      paste0("cafi_pc1_treatment_", transform),
      paste0("Treatment effect on CAFI community PC1 (", transform, ")"),
      scenario,
      "condition-subset coral-level CAFI PCA",
      estimate = treatment_fit$estimate,
      statistic = treatment_fit$statistic,
      df = treatment_fit$df,
      p_value = treatment_fit$p_value,
      significant = treatment_fit$p_value < ALPHA,
      direction = treatment_fit$direction,
      metric = "LMM treatment LRT; PC1 aligned to condition PC1",
      n_units = treatment_fit$n,
      details = sprintf("PC1 variance=%.3f; PCA species used=%d",
                        pc$var_pc1, pc$n_species_used)
    )

    cond_fit <- fit_numeric_lmm(pc_df, "condition_PC1", "PC1")
    all_result_rows[[length(all_result_rows) + 1]] <- as_result_row(
      paste0("cafi_pc1_condition_", transform),
      paste0("CAFI community PC1 predicts coral condition PC1 (", transform, ")"),
      scenario,
      "condition-subset coral-level CAFI-condition link",
      estimate = cond_fit$estimate,
      statistic = cond_fit$statistic,
      df = cond_fit$df,
      p_value = cond_fit$p_value,
      significant = cond_fit$p_value < ALPHA,
      direction = dplyr::case_when(
        cond_fit$estimate > 0 ~ "positive",
        cond_fit$estimate < 0 ~ "negative",
        TRUE ~ "zero"
      ),
      metric = "LMM slope; PC1 aligned to condition PC1",
      n_units = cond_fit$n,
      details = sprintf("PC1 variance=%.3f; PCA species used=%d",
                        pc$var_pc1, pc$n_species_used)
    )
  }

  # 6. Per-species condition associations for included species.
  species_condition <- run_species_condition(coral_mat_condition, cond_model_df, species_keep) %>%
    dplyr::mutate(
      scenario_id = scenario$scenario_id,
      scenario_type = scenario$scenario_type,
      n_species_condition_scope = scenario$n_species_condition_scope
    )
  all_species_condition[[length(all_species_condition) + 1]] <- species_condition

  if (nrow(species_condition) > 0) {
    n_pos <- sum(species_condition$p_value < ALPHA & species_condition$estimate > 0, na.rm = TRUE)
    n_neg <- sum(species_condition$p_value < ALPHA & species_condition$estimate < 0, na.rm = TRUE)
    n_pos_bh <- sum(species_condition$significant_BH & species_condition$estimate > 0, na.rm = TRUE)
    n_neg_bh <- sum(species_condition$significant_BH & species_condition$estimate < 0, na.rm = TRUE)

    all_result_rows[[length(all_result_rows) + 1]] <- as_result_row(
      "species_condition_sig_positive_count",
      "Number of included species positively associated with coral condition",
      scenario,
      "condition-subset per-species LMMs",
      estimate = n_pos,
      significant = n_pos > 0,
      direction = "count",
      metric = "unadjusted p < 0.05 count",
      n_units = nrow(species_condition),
      details = sprintf("BH-positive=%d", n_pos_bh)
    )
    all_result_rows[[length(all_result_rows) + 1]] <- as_result_row(
      "species_condition_sig_negative_count",
      "Number of included species negatively associated with coral condition",
      scenario,
      "condition-subset per-species LMMs",
      estimate = n_neg,
      significant = n_neg > 0,
      direction = "count",
      metric = "unadjusted p < 0.05 count",
      n_units = nrow(species_condition),
      details = sprintf("BH-negative=%d", n_neg_bh)
    )

    for (sp in focal_species) {
      sp_row <- species_condition %>% dplyr::filter(species == sp)
      if (nrow(sp_row) == 0) {
        all_result_rows[[length(all_result_rows) + 1]] <- as_result_row(
          paste0("species_condition_", make.names(sp)),
          paste0(sp, " abundance predicts coral condition"),
          scenario,
          "condition-subset per-species LMMs",
          significant = NA,
          direction = "not included",
          metric = "sqrt abundance LMM",
          n_units = 0,
          details = "species not in this inclusion set"
        )
      } else {
        all_result_rows[[length(all_result_rows) + 1]] <- as_result_row(
          paste0("species_condition_", make.names(sp)),
          paste0(sp, " abundance predicts coral condition"),
          scenario,
          "condition-subset per-species LMMs",
          estimate = sp_row$estimate,
          statistic = sp_row$statistic,
          df = sp_row$df,
          p_value = sp_row$p_value,
          significant = sp_row$p_value < ALPHA,
          direction = sp_row$direction,
          metric = "sqrt abundance LMM",
          n_units = sp_row$n,
          details = sprintf("BH p=%.3f", sp_row$p_adj_BH)
        )
      }
    }
  }
}

sensitivity_long <- dplyr::bind_rows(all_result_rows) %>%
  dplyr::mutate(
    significant = dplyr::if_else(is.na(significant), NA, significant),
    p_value = safe_p(p_value),
    stars = sig_label(p_value)
  ) %>%
  dplyr::arrange(result_key, scenario_type, requested_n_species, scenario_id)

scaling_species_long <- dplyr::bind_rows(all_scaling_species)
species_condition_long <- dplyr::bind_rows(all_species_condition)

readr::write_csv(
  sensitivity_long,
  file.path(TAB_DIR, "species_inclusion_sensitivity_long.csv")
)
readr::write_csv(
  scaling_species_long,
  file.path(TAB_DIR, "species_inclusion_sensitivity_scaling_species.csv")
)
readr::write_csv(
  species_condition_long,
  file.path(TAB_DIR, "species_inclusion_sensitivity_species_condition.csv")
)

# ==============================================================================
# Build compact "which results are sensitive?" table
# ==============================================================================

reference_id <- "main_38_10x10_corrected"
functional_id <- "obligate_plus_damselfish"
whole_id <- "all_observed_species"

reference_rows <- sensitivity_long %>%
  dplyr::filter(scenario_id == reference_id) %>%
  dplyr::select(result_key,
                reference_estimate = estimate,
                reference_p = p_value,
                reference_significant = significant,
                reference_direction = direction,
                reference_details = details)

whole_rows <- sensitivity_long %>%
  dplyr::filter(scenario_id == whole_id) %>%
  dplyr::select(result_key,
                whole_estimate = estimate,
                whole_p = p_value,
                whole_significant = significant,
                whole_direction = direction,
                whole_details = details)

functional_rows <- sensitivity_long %>%
  dplyr::filter(scenario_id == functional_id) %>%
  dplyr::select(result_key,
                obligate_damselfish_estimate = estimate,
                obligate_damselfish_p = p_value,
                obligate_damselfish_significant = significant,
                obligate_damselfish_direction = direction,
                obligate_damselfish_details = details)

ranked_summary <- sensitivity_long %>%
  dplyr::filter(scenario_type == "ranked_top_N") %>%
  dplyr::group_by(result_key, result_label, analysis_scope, metric) %>%
  dplyr::summarise(
    n_ranked_scenarios = dplyr::n(),
    min_n_species = min(n_species_full_scope, na.rm = TRUE),
    max_n_species = max(n_species_full_scope, na.rm = TRUE),
    estimate_min = suppressWarnings(min(estimate, na.rm = TRUE)),
    estimate_max = suppressWarnings(max(estimate, na.rm = TRUE)),
    p_min = suppressWarnings(min(p_value, na.rm = TRUE)),
    p_max = suppressWarnings(max(p_value, na.rm = TRUE)),
    prop_ranked_sig = mean(significant %in% TRUE, na.rm = TRUE),
    ranked_sig_values = paste(sort(unique(stats::na.omit(as.character(significant)))), collapse = "/"),
    ranked_directions = paste(sort(unique(stats::na.omit(direction))), collapse = " | "),
    .groups = "drop"
  ) %>%
  dplyr::mutate(
    estimate_min = dplyr::if_else(is.infinite(estimate_min), NA_real_, estimate_min),
    estimate_max = dplyr::if_else(is.infinite(estimate_max), NA_real_, estimate_max),
    p_min = dplyr::if_else(is.infinite(p_min), NA_real_, p_min),
    p_max = dplyr::if_else(is.infinite(p_max), NA_real_, p_max)
  )

sensitivity_summary <- ranked_summary %>%
  dplyr::left_join(reference_rows, by = "result_key") %>%
  dplyr::left_join(whole_rows, by = "result_key") %>%
  dplyr::left_join(functional_rows, by = "result_key") %>%
  dplyr::mutate(
    direction_sensitive = stringr::str_detect(ranked_directions, "\\|"),
    significance_sensitive = stringr::str_detect(ranked_sig_values, "/"),
    obligate_differs_from_whole = dplyr::case_when(
      is.na(obligate_damselfish_significant) & is.na(whole_significant) ~ FALSE,
      obligate_damselfish_significant != whole_significant ~ TRUE,
      !is.na(obligate_damselfish_direction) & !is.na(whole_direction) &
        obligate_damselfish_direction != whole_direction ~ TRUE,
      TRUE ~ FALSE
    ),
    sensitivity_class = dplyr::case_when(
      result_key %in% c("species_scaling_sig_above_count",
                        "species_scaling_sig_below_count",
                        "species_scaling_point_above_pct_t6",
                        "species_condition_sig_positive_count",
                        "species_condition_sig_negative_count") ~ "identity/count depends on included species",
      stringr::str_detect(result_key, "^species_condition_") &
        stringr::str_detect(ranked_directions, "not included") ~
        "inclusion-sensitive; coefficient stable when species is included",
      direction_sensitive ~ "direction-sensitive across top-N",
      significance_sensitive & obligate_differs_from_whole ~ "significance-sensitive and functional-subset sensitive",
      significance_sensitive ~ "significance-sensitive across top-N",
      obligate_differs_from_whole ~ "functional-subset sensitive",
      TRUE ~ "not sensitive in tested scenarios"
    ),
    sensitive = sensitivity_class != "not sensitive in tested scenarios",
    sensitivity_interpretation = dplyr::case_when(
      result_key == "total_abundance_scaling_t6" ~
        "Total abundance remains close to proportional unless the set is restricted to selected functional taxa; use whole-community scaling for Field-of-Dreams claims.",
      result_key == "species_scaling_sig_above_count" ~
        "The number and identity of above-expected species necessarily change with N; the corrected 38-species set should be the stated inferential universe.",
      result_key == "species_scaling_sig_below_count" ~
        "The below-expected result is sensitive to whether Dascyllus aruanus is included; in the corrected 38-species set it is the significant below-expected species.",
      stringr::str_detect(result_key, "^alpha_") ~
        "Alpha-diversity treatment tests are weak/variable and should not be over-emphasized as robust treatment effects.",
      stringr::str_detect(result_key, "^beta_permanova_") ~
        "Community-composition treatment effects are generally robust, but metric and functional subset can change strength.",
      stringr::str_detect(result_key, "^cafi_pc1_condition_") ~
        "The CAFI-condition link is the key test for whether reduced matrices retain the feedback signal.",
      stringr::str_detect(result_key, "^cafi_pc1_treatment_") ~
        "Treatment effects on PC1 are robust if sign/significance remain stable after PC1 orientation is aligned to condition.",
      stringr::str_detect(result_key, "^species_condition_") ~
        "Per-species rows are sensitive to inclusion because absent taxa cannot be tested; coefficients themselves do not depend on other species in the matrix.",
      TRUE ~ NA_character_
    )
  ) %>%
  dplyr::select(
    result_key, result_label, analysis_scope, metric,
    reference_estimate, reference_p, reference_significant, reference_direction,
    whole_estimate, whole_p, whole_significant, whole_direction,
    obligate_damselfish_estimate, obligate_damselfish_p,
    obligate_damselfish_significant, obligate_damselfish_direction,
    estimate_min, estimate_max, p_min, p_max, prop_ranked_sig,
    ranked_sig_values, ranked_directions,
    sensitive, sensitivity_class, sensitivity_interpretation,
    reference_details, whole_details, obligate_damselfish_details
  ) %>%
  dplyr::arrange(desc(sensitive), result_key)

non_species_dependent <- tibble::tibble(
  result_key = c(
    "coral_growth_allometric_treatment",
    "coral_growth_size_corrected_treatment",
    "coral_condition_pc1_treatment",
    "individual_physiology_trait_treatment"
  ),
  result_label = c(
    "Treatment effects on coral growth allometry",
    "Treatment effect on size-corrected coral growth",
    "Treatment effect on coral condition PC1",
    "Treatment effects on individual coral physiology traits"
  ),
  analysis_scope = c(
    "coral-only growth model",
    "coral-only growth model",
    "coral-only physiology/condition model",
    "coral-only physiology model"
  ),
  metric = NA_character_,
  sensitive = FALSE,
  sensitivity_class = "not species-set dependent",
  sensitivity_interpretation = "This result does not use a CAFI species matrix, so changing the number or identity of CAFI taxa cannot alter the analysis."
)

sensitivity_summary <- dplyr::bind_rows(sensitivity_summary, non_species_dependent) %>%
  dplyr::arrange(desc(sensitive), sensitivity_class, result_key)

readr::write_csv(
  sensitivity_summary,
  file.path(TAB_DIR, "species_inclusion_sensitivity_result_summary.csv")
)

summary_md <- sensitivity_summary %>%
  dplyr::mutate(
    main38_p = dplyr::if_else(is.na(reference_p), "", formatC(reference_p, digits = 3, format = "f")),
    whole_p = dplyr::if_else(is.na(whole_p), "", formatC(whole_p, digits = 3, format = "f")),
    functional_p = dplyr::if_else(
      is.na(obligate_damselfish_p), "",
      formatC(obligate_damselfish_p, digits = 3, format = "f")
    ),
    main38_estimate = dplyr::if_else(
      is.na(reference_estimate), "",
      formatC(reference_estimate, digits = 3, format = "f")
    )
  ) %>%
  dplyr::select(
    Result = result_label,
    Scope = analysis_scope,
    `Main 38 estimate` = main38_estimate,
    `Main 38 p` = main38_p,
    `All taxa p` = whole_p,
    `Obligate+damselfish p` = functional_p,
    `Sensitivity class` = sensitivity_class,
    `How to use this` = sensitivity_interpretation
  )

summary_md_lines <- c(
  "# Species-Inclusion Sensitivity Result Summary",
  "",
  "| Result | Scope | Main 38 estimate | Main 38 p | All taxa p | Obligate+damselfish p | Sensitivity class | How to use this |",
  "|---|---|---:|---:|---:|---:|---|---|"
)

escape_md <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  stringr::str_replace_all(x, "\\|", "\\\\|")
}

summary_md_lines <- c(
  summary_md_lines,
  apply(summary_md, 1, function(row) {
    paste0("| ", paste(escape_md(row), collapse = " | "), " |")
  })
)

writeLines(
  summary_md_lines,
  file.path(TAB_DIR, "species_inclusion_sensitivity_result_summary.md")
)

functional_subset_table <- sensitivity_long %>%
  dplyr::filter(scenario_id %in% c("main_38_10x10_corrected", "all_observed_species", "obligate_plus_damselfish", "damselfish_only")) %>%
  dplyr::select(result_key, result_label, scenario_id, n_species_full_scope,
                n_species_condition_scope, estimate, p_value, significant, direction, details) %>%
  dplyr::arrange(result_key, scenario_id)

readr::write_csv(
  functional_subset_table,
  file.path(TAB_DIR, "species_inclusion_sensitivity_functional_subset.csv")
)

# Markdown design and compact summary.
main_rows <- sensitivity_summary %>%
  dplyr::filter(result_key %in% c(
    "total_abundance_scaling_t6",
    "species_scaling_sig_above_count",
    "species_scaling_sig_below_count",
    "species_scaling_point_above_pct_t6",
    "beta_permanova_gower_sqrt_z",
    "beta_permanova_jaccard",
    "cafi_pc1_treatment_SQRT_CS",
    "cafi_pc1_condition_SQRT_CS",
    "cafi_pc1_condition_HELLINGER",
    "alpha_richness_treatment",
    "alpha_rarefied_richness_treatment",
    "species_condition_Caracanthus.maculatus",
    "species_condition_Luniella.pugil",
    "species_condition_Alpheus.diadema",
    "species_condition_Dascyllus.aruanus"
  ))

md_lines <- c(
  "# Species-inclusion sensitivity analysis",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Design",
  "",
  paste0("- Ranked top-N species sets: ", paste(top_n_grid, collapse = ", "), "."),
  paste0("- Reference set: corrected manuscript 10x10 set (n = ", length(main_species), ")."),
  paste0("- Full community set: all observed species in the CAFI census (n = ", length(all_species_ranked), ")."),
  paste0("- Functional subset: obligate/strong coral-associated taxa plus damselfishes (n = ", length(functional_species), ")."),
  "- Abundance and scaling results use the full CAFI reef-level data.",
  "- Beta-diversity and CAFI-condition results use the growth/physiology subset, because coral condition is only available there.",
  "- PC1 signs are aligned so higher community PC1 is positively correlated with higher coral condition PC1 where possible.",
  "",
  "## Key Result Summary",
  "",
  "| Result | Main 38 estimate | Main 38 p | Whole-community p | Obligate+damselfish p | Sensitivity class |",
  "|---|---:|---:|---:|---:|---|"
)

fmt_num <- function(x, digits = 3) {
  ifelse(is.na(x), "", formatC(x, digits = digits, format = "f"))
}

for (j in seq_len(nrow(main_rows))) {
  row <- main_rows[j, ]
  md_lines <- c(md_lines, paste0(
    "| ", row$result_label,
    " | ", fmt_num(row$reference_estimate),
    " | ", fmt_num(row$reference_p),
    " | ", fmt_num(row$whole_p),
    " | ", fmt_num(row$obligate_damselfish_p),
    " | ", row$sensitivity_class,
    " |"
  ))
}

md_lines <- c(
  md_lines,
  "",
  "## Output files",
  "",
  "- `species_inclusion_sensitivity_result_summary.csv`: compact sensitivity classification for each result.",
  "- `species_inclusion_sensitivity_result_summary.md`: Markdown version of the compact sensitivity table.",
  "- `species_inclusion_sensitivity_long.csv`: one row per result x inclusion scenario.",
  "- `species_inclusion_sensitivity_functional_subset.csv`: direct whole-community versus obligate/damselfish comparison.",
  "- `species_inclusion_sensitivity_scaling_species.csv`: species-level observed-versus-expected classifications for each scenario.",
  "- `species_inclusion_sensitivity_species_condition.csv`: per-species condition LMMs for each scenario."
)

writeLines(md_lines, file.path(TAB_DIR, "species_inclusion_sensitivity_design.md"))

message("Done. Wrote species-inclusion sensitivity tables to ", TAB_DIR)

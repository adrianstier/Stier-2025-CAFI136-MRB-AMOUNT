# ==============================================================================
# MRB Analysis Script 5: Fish Community Analysis
# ==============================================================================
# Purpose: Analyze fish (Actinopterygii) community patterns across coral density
#          treatments. Calculates alpha diversity metrics (richness, Shannon,
#          Simpson), performs NMDS ordination, tests for treatment effects with
#          PERMANOVA, and identifies indicator species for each treatment.
#
# Inputs:
#   - data/MRB Amount/1. mrb_fe_cafi_summer_2021_v4_AP_updated_2024.csv
#   - data/MRB Amount/coral_id_position_treatment.csv
#
# Outputs:
#   - output/MRB/figures/fishes/fish_diversity_by_treatment.png
#   - output/MRB/figures/fishes/fish_nmds_ordination.png
#   - output/MRB/figures/fishes/fish_abundance_by_species.png
#   - output/MRB/tables/fish_diversity_by_treatment.csv
#   - output/MRB/tables/fish_community_metrics.csv
#   - output/MRB/tables/fish_species_abundance.csv
#   - output/MRB/tables/fish_permanova_results.csv
#   - output/MRB/tables/fish_indicator_species.csv
#   - output/MRB/objects/fish_analysis_results.rds
#
# Depends:
#   R (>= 4.3), tidyverse, vegan, indicspecies, here
#
# Run after:
#   - 1.libraries.R (loads required packages)
#   - utils.R (utility functions)
#   - mrb_config.R (configuration settings)
#
# Author: CAFI Team
# Created: 2024-11-01 (estimated)
# Last updated: 2025-11-05
#
# Reproducibility notes:
#   - NMDS stress target < 0.15 (good fit)
#   - PERMANOVA uses 999 permutations
#   - Indicator species analysis uses 999 permutations
#   - Only fish (class Actinopterygii) included in analysis
#   - All paths use here::here() for portability
# ==============================================================================

# ==============================================================================
# SETUP
# ==============================================================================

# Source libraries, utilities, and configuration
source("scripts/MRB/1.libraries.R")
source("scripts/MRB/utils.R")
source("scripts/MRB/mrb_figure_standards.R")  # For theme_publication(), colors, etc.
source("scripts/MRB/mrb_config.R")

# Set output directories
fig_dir   <- here::here("output", "MRB", "figures", "fishes")
table_dir <- here::here("output", "MRB", "tables")
obj_dir   <- here::here("output", "MRB", "objects")

# Create directories if needed
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(obj_dir, recursive = TRUE, showWarnings = FALSE)

# ==============================================================================
# DATA LOADING
# ==============================================================================

print_section("LOADING DATA")

# Load CAFI data using utility function
MRBcafi_df <- load_cafi_data()

# Load treatment information
treatment_df <- read_csv(here("data/MRB Amount/coral_id_position_treatment.csv")) %>%
  mutate(coral_id = as.factor(coral_id))

cat("✅ Data loaded\n")
cat("   CAFI records:", nrow(MRBcafi_df), "\n")
cat("   Treatment data:", nrow(treatment_df), "corals\n\n")

# ==============================================================================
# TREATMENT PROCESSING
# ==============================================================================

print_section("PROCESSING TREATMENT DATA")

# Extract position information and create reef identifier
treatment_df <- treatment_df %>%
  mutate(
    row = str_extract(position, "^\\d+"),
    column = str_extract(position, "(?<=-)\\d+"),
    replicate = str_extract(position, "[A-Za-z]+")
  ) %>%
  mutate(across(c(row, column), as.integer)) %>%
  mutate(reef = paste0("Reef_", row, "-", column))

# Merge treatment info and apply ordering
MRBcafi_df <- MRBcafi_df %>%
  left_join(treatment_df, by = "coral_id") %>%
  mutate(treatment = factor(treatment, levels = TREATMENT_ORDER))

# Check merge quality
missing_treatment <- MRBcafi_df %>% filter(is.na(treatment)) %>% nrow()
cat("✅ Treatments merged\n")
cat("   Missing treatment:", missing_treatment, "records\n\n")

# ==============================================================================
# FISH DATA EXTRACTION
# ==============================================================================

print_section("FISH COMMUNITY ANALYSIS")

print_subsection("Filtering Fish Data")

# Extract fish (Actinopterygii) with species-level identification
fishes_df <- MRBcafi_df %>%
  filter(class == "Actinopterygii" & !is.na(species))

cat("Fish data summary:\n")
cat("   Total fish records:", nrow(fishes_df), "\n")
cat("   Unique fish species:", n_distinct(fishes_df$species), "\n")
cat("   Reefs with fish:", n_distinct(fishes_df$reef), "\n\n")

# ==============================================================================
# COMMUNITY MATRIX
# ==============================================================================

print_subsection("Building Community Matrix")

# Summarize fish abundance per reef and species
fish_abundance <- fishes_df %>%
  group_by(reef, species) %>%
  summarise(total_abundance = sum(count, na.rm = TRUE), .groups = "drop")

# Create wide-format species matrix
fish_matrix <- fish_abundance %>%
  pivot_wider(names_from = species, values_from = total_abundance, values_fill = 0)

# Extract metadata
fish_metadata <- fish_matrix %>%
  dplyr::select(reef) %>%
  left_join(dplyr::select(MRBcafi_df, reef, treatment), by = "reef") %>%
  distinct() %>%
  mutate(treatment = factor(treatment, levels = TREATMENT_ORDER))

# Prepare matrix for analysis
fish_matrix2 <- fish_matrix %>%
  dplyr::select(-reef) %>%
  as.data.frame()

cat("✅ Community matrix created\n")
cat("   Dimensions:", nrow(fish_matrix), "reefs ×", ncol(fish_matrix2), "species\n\n")

# ==============================================================================
# DIVERSITY METRICS
# ==============================================================================

print_section("CALCULATING DIVERSITY METRICS")

# Calculate diversity indices
fish_richness <- rowSums(fish_matrix2 > 0)
fish_shannon <- diversity(fish_matrix2, index = "shannon")
fish_simpson <- diversity(fish_matrix2, index = "simpson")
fish_evenness <- fish_shannon / log(fish_richness + 1)  # Avoid log(0)

# Create summary dataframe
fish_community_summary <- data.frame(
  reef = fish_matrix$reef,
  treatment = fish_metadata$treatment,
  richness = fish_richness,
  shannon_diversity = fish_shannon,
  simpson_diversity = fish_simpson,
  evenness = fish_evenness,
  stringsAsFactors = FALSE
)

# Summary by treatment
diversity_by_treatment <- fish_community_summary %>%
  group_by(treatment) %>%
  summarise(
    n_reefs = n(),
    mean_richness = mean(richness),
    se_richness = sd(richness) / sqrt(n()),
    mean_shannon = mean(shannon_diversity),
    se_shannon = sd(shannon_diversity) / sqrt(n()),
    mean_evenness = mean(evenness),
    se_evenness = sd(evenness) / sqrt(n()),
    .groups = "drop"
  )

cat("Diversity metrics by treatment:\n")
print(diversity_by_treatment)
cat("\n")

# Save diversity summary
write_csv(diversity_by_treatment, file.path(table_dir, "fish_diversity_by_treatment.csv"))
write_csv(fish_community_summary, file.path(table_dir, "fish_community_metrics.csv"))

# ==============================================================================
# FIGURE 1: DIVERSITY METRICS
# ==============================================================================

print_subsection("Creating Figure 1: Diversity Metrics")

# Reshape for plotting
fish_community_summary_long <- fish_community_summary %>%
  pivot_longer(
    cols = c(richness, shannon_diversity, simpson_diversity, evenness),
    names_to = "metric",
    values_to = "value"
  ) %>%
  mutate(
    metric = factor(metric,
                   levels = c("richness", "shannon_diversity", "simpson_diversity", "evenness"),
                   labels = c("Species Richness", "Shannon Diversity", "Simpson Diversity", "Evenness"))
  )

# Create diversity plot with proper publication formatting
p_fish_metrics <- ggplot(fish_community_summary_long,
                         aes(x = treatment, y = value, fill = treatment)) +
  geom_boxplot(alpha = 0.8, outlier.shape = NA, width = 0.7,
               color = "black", linewidth = 0.7) +
  geom_point(position = position_jitter(width = 0.15),
             alpha = 0.6, size = 2.5, shape = 21,
             color = "black", stroke = 0.5) +
  facet_wrap(~ metric, scales = "free_y", ncol = 2) +
  scale_fill_treatment() +
  scale_x_discrete(labels = c("1" = "1", "3" = "3", "6" = "6")) +
  labs(
    title = "Fish Community Metrics Across Treatments",
    subtitle = "Actinopterygii diversity patterns in MRB experiment",
    x = "Number of Coral Colonies",
    y = "Metric Value"
  ) +
  theme_multipanel() +
  theme(
    legend.position = "bottom",
    strip.text = element_text(face = "bold", size = FONT_SIZE_FACET),
    strip.background = element_rect(fill = "grey95", color = "black", linewidth = 1),
    panel.spacing = unit(0.8, "cm")
  )

save_figure(
  p_fish_metrics,
  file.path(fig_dir, "fish_diversity_metrics"),
  width = PUBLICATION_WIDTH_DOUBLE,
  height = PUBLICATION_HEIGHT_STD * 1.2
)

# ==============================================================================
# SPECIES ABUNDANCE ANALYSIS
# ==============================================================================

print_section("SPECIES ABUNDANCE PATTERNS")

print_subsection("Top Fish Species")

# Identify top species by total abundance
top_fish <- fishes_df %>%
  group_by(species) %>%
  summarise(
    total_abundance = sum(count, na.rm = TRUE),
    n_occurrences = n_distinct(coral_id),
    .groups = "drop"
  ) %>%
  arrange(desc(total_abundance))

# Display top 10 species
cat("Top 10 fish species by abundance:\n")
print(head(top_fish, 10))
cat("\n")

# Save species abundance table
write_csv(top_fish, file.path(table_dir, "fish_species_abundance.csv"))

# ==============================================================================
# FIGURE 2: TOP SPECIES ABUNDANCE
# ==============================================================================

print_subsection("Creating Figure 2: Top Species Abundance")

# Select top 15 species for visualization
top_15_species <- head(top_fish$species, 15)

# Calculate abundance by treatment for top species
top_species_treatment <- fishes_df %>%
  filter(species %in% top_15_species) %>%
  group_by(species, treatment) %>%
  summarise(
    mean_abundance = mean(count),
    se_abundance = sd(count) / sqrt(n()),
    total_abundance = sum(count),
    .groups = "drop"
  ) %>%
  mutate(species = factor(species, levels = top_15_species))

# Create abundance plot with publication standards
p_top_fish <- ggplot(top_species_treatment,
                    aes(x = treatment, y = mean_abundance, fill = treatment)) +
  geom_bar(stat = "identity", alpha = 0.85, color = "black", linewidth = 0.5) +
  geom_errorbar(aes(ymin = pmax(0, mean_abundance - se_abundance),
                    ymax = mean_abundance + se_abundance),
                width = 0.25, linewidth = 0.6) +
  facet_wrap(~ species, scales = "free_y", ncol = 5) +
  scale_fill_treatment() +
  scale_x_discrete(labels = c("1" = "1", "3" = "3", "6" = "6")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = "Top 15 Fish Species Abundance by Treatment",
    subtitle = "Mean abundance (± SE) per coral colony",
    x = "Number of Coral Colonies",
    y = "Mean Abundance"
  ) +
  theme_multipanel() +
  theme(
    legend.position = "bottom",
    strip.text = element_text(face = "italic", size = FONT_SIZE_ANNOTATION),
    strip.background = element_rect(fill = "grey95", color = "black", linewidth = 0.7),
    axis.text.x = element_text(size = 9),
    axis.text.y = element_text(size = 9),
    axis.title = element_text(size = 11),
    panel.spacing.x = unit(0.4, "cm"),
    panel.spacing.y = unit(0.5, "cm")
  )

save_figure(
  p_top_fish,
  file.path(fig_dir, "top_fish_species_abundance"),
  width = PUBLICATION_WIDTH_WIDE,
  height = PUBLICATION_HEIGHT_TALL
)

# ==============================================================================
# ORDINATION ANALYSIS
# ==============================================================================

print_section("ORDINATION ANALYSIS")

print_subsection("NMDS Ordination")

# Prepare data for ordination (remove empty rows/columns)
fish_matrix_clean <- fish_matrix2[rowSums(fish_matrix2) > 0, colSums(fish_matrix2) > 0]

# Perform NMDS
set.seed(123)  # For reproducibility
fish_nmds <- metaMDS(fish_matrix_clean, distance = "bray", k = 2, trymax = 100)

cat("NMDS results:\n")
cat("   Stress:", round(fish_nmds$stress, 3), "\n")
cat("   Convergence:", fish_nmds$converged, "\n\n")

# Extract NMDS scores
nmds_scores <- as.data.frame(vegan::scores(fish_nmds, display = "sites"))
nmds_scores$reef <- fish_matrix$reef[rowSums(fish_matrix2) > 0]
nmds_scores$treatment <- fish_metadata$treatment[rowSums(fish_matrix2) > 0]

# ==============================================================================
# FIGURE 3: NMDS PLOT
# ==============================================================================

print_subsection("Creating Figure 3: NMDS Ordination")

# Calculate centroids for treatments
centroids <- nmds_scores %>%
  group_by(treatment) %>%
  summarise(
    NMDS1_mean = mean(NMDS1),
    NMDS2_mean = mean(NMDS2),
    .groups = "drop"
  )

# Create NMDS plot with publication standards (already sourced at top)
p_nmds <- ggplot(nmds_scores, aes(x = NMDS1, y = NMDS2)) +
  # Add ellipses with proper linewidth
  stat_ellipse(aes(color = treatment, fill = treatment),
               geom = "polygon", alpha = 0.25, level = 0.95,
               linewidth = 1.2) +
  # Add points with better sizing
  geom_point(aes(fill = treatment), shape = 21, size = 5,
             alpha = 0.9, stroke = 1.5, color = "black") +
  # Add centroids with clearer symbols
  geom_point(data = centroids,
             aes(x = NMDS1_mean, y = NMDS2_mean, fill = treatment),
             shape = 23, size = 8, stroke = 2.5, color = "black") +
  # Use standardized treatment color scales
  scale_fill_treatment() +
  scale_color_treatment() +
  labs(
    title = "NMDS Ordination of Fish Communities",
    subtitle = paste("Stress =", round(fish_nmds$stress, 3)),
    x = "NMDS Axis 1",
    y = "NMDS Axis 2"
  ) +
  theme_ordination() +  # Use specialized ordination theme with grid
  theme(
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.key.size = unit(1.5, "lines"),
    legend.box = "horizontal",
    panel.grid.major = element_line(color = "grey85", linewidth = 0.25)
  ) +
  coord_equal()

# Save using standardized function with square dimensions
save_figure(
  p_nmds,
  file.path(fig_dir, "fish_nmds_ordination"),
  width = PUBLICATION_HEIGHT_SQUARE,
  height = PUBLICATION_HEIGHT_SQUARE
)

# ==============================================================================
# PERMANOVA ANALYSIS
# ==============================================================================

print_section("STATISTICAL ANALYSIS")

print_subsection("PERMANOVA Test")

# Prepare data for PERMANOVA
perm_matrix <- fish_matrix_clean[!is.na(fish_metadata$treatment[rowSums(fish_matrix2) > 0]), ]
perm_treatment <- fish_metadata$treatment[rowSums(fish_matrix2) > 0]
perm_treatment <- perm_treatment[!is.na(perm_treatment)]

# Run PERMANOVA
set.seed(123)
fish_permanova <- adonis2(
  perm_matrix ~ perm_treatment,
  method = "bray",
  permutations = 999
)

cat("PERMANOVA results:\n")
print(fish_permanova)
cat("\n")

# Save PERMANOVA results
permanova_df <- as.data.frame(fish_permanova)
write_csv(permanova_df, file.path(table_dir, "fish_permanova_results.csv"))

# ==============================================================================
# INDICATOR SPECIES ANALYSIS
# ==============================================================================

print_subsection("Indicator Species Analysis")

# Prepare data for indicator species analysis
indval_matrix <- as.matrix(perm_matrix)
indval_groups <- as.numeric(perm_treatment)

# Run indicator species analysis
library(indicspecies)
fish_indval <- multipatt(indval_matrix, indval_groups,
                         control = how(nperm = 999))

# Extract significant indicators
sig_indicators <- fish_indval$sign[fish_indval$sign$p.value < 0.05, ]

if (nrow(sig_indicators) > 0) {
  cat("Significant indicator species (p < 0.05):\n")
  sig_indicators$species <- rownames(sig_indicators)

  # Select available columns dynamically
  available_cols <- c("species", names(sig_indicators)[grep("^s\\.", names(sig_indicators))],
                      "stat", "p.value")
  available_cols <- intersect(available_cols, names(sig_indicators))

  sig_indicators <- sig_indicators %>%
    arrange(p.value) %>%
    dplyr::select(all_of(available_cols))

  print(head(sig_indicators, 10))

  # Save indicator species results
  write_csv(sig_indicators, file.path(table_dir, "fish_indicator_species.csv"))
} else {
  cat("No significant indicator species found (p < 0.05)\n")
}

# ==============================================================================
# SPECIES ACCUMULATION CURVES
# ==============================================================================

print_section("SPECIES ACCUMULATION ANALYSIS")

# Calculate species accumulation curves by treatment
treatments <- unique(fish_metadata$treatment)
treatments <- treatments[!is.na(treatments)]

sac_results <- list()

for (trt in treatments) {
  # Get matrix for this treatment
  trt_rows <- which(fish_metadata$treatment == trt)
  trt_matrix <- fish_matrix2[trt_rows, colSums(fish_matrix2[trt_rows, , drop = FALSE]) > 0]

  if (nrow(trt_matrix) > 1) {
    # Calculate species accumulation
    sac <- specaccum(trt_matrix, method = "random", permutations = 100)

    # Store results
    sac_results[[as.character(trt)]] <- data.frame(
      treatment = trt,
      sites = sac$sites,
      richness = sac$richness,
      sd = sac$sd
    )
  }
}

# Combine results
sac_combined <- bind_rows(sac_results)

# ==============================================================================
# FIGURE 4: SPECIES ACCUMULATION CURVES
# ==============================================================================

print_subsection("Creating Figure 4: Species Accumulation Curves")

p_sac <- ggplot(sac_combined, aes(x = sites, y = richness, color = treatment)) +
  # Add confidence ribbons with better transparency
  geom_ribbon(aes(ymin = richness - sd, ymax = richness + sd, fill = treatment),
              alpha = 0.3, color = NA) +
  # Add lines with proper width
  geom_line(linewidth = 2, alpha = 0.9) +
  # Add points with better sizing
  geom_point(size = 4, alpha = 0.9) +
  # Use standardized treatment color scales
  scale_color_treatment() +
  scale_fill_treatment() +
  # Ensure y-axis starts at 0
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
  scale_x_continuous(breaks = scales::pretty_breaks(n = 6)) +
  labs(
    title = "Species Accumulation Curves",
    subtitle = "Fish species richness by sampling effort",
    x = "Number of Reefs Sampled",
    y = "Cumulative Species Richness",
    caption = "Shaded areas represent ± 1 standard deviation"
  ) +
  theme_publication(grid = TRUE) +  # Add grid for easier reading
  theme(
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.key.size = unit(1.5, "lines"),
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.25),
    panel.grid.minor.y = element_blank(),
    panel.grid.major.x = element_line(color = "grey95", linewidth = 0.25)
  )

# Save using standardized function
save_figure(
  p_sac,
  file.path(fig_dir, "fish_species_accumulation"),
  width = PUBLICATION_WIDTH_SINGLE,
  height = PUBLICATION_HEIGHT_STD
)

# ==============================================================================
# SAVE ANALYSIS OBJECTS
# ==============================================================================

print_section("SAVING ANALYSIS OBJECTS")

# Compile all results
fish_analysis_results <- list(
  community_matrix = fish_matrix,
  diversity_metrics = fish_community_summary,
  diversity_by_treatment = diversity_by_treatment,
  species_abundance = top_fish,
  nmds_results = fish_nmds,
  nmds_scores = nmds_scores,
  permanova_results = fish_permanova,
  indicator_species = if (exists("sig_indicators")) sig_indicators else NULL,
  species_accumulation = sac_combined
)

# Save R object
saveRDS(fish_analysis_results, file.path(obj_dir, "fish_analysis_results.rds"))

cat("✅ Analysis objects saved\n\n")

# ==============================================================================
# COMPLETION MESSAGE
# ==============================================================================

print_section("FISH ANALYSIS COMPLETED")

cat("✅ All analyses completed successfully\n\n")

cat("OUTPUTS GENERATED:\n")
cat("📊 Figures saved to:", fig_dir, "\n")
cat("   - fish_diversity_metrics.png/pdf\n")
cat("   - top_fish_species_abundance.png/pdf\n")
cat("   - fish_nmds_ordination.png/pdf\n")
cat("   - fish_species_accumulation.png/pdf\n")

cat("\n📋 Tables saved to:", table_dir, "\n")
cat("   - fish_diversity_by_treatment.csv\n")
cat("   - fish_community_metrics.csv\n")
cat("   - fish_species_abundance.csv\n")
cat("   - fish_permanova_results.csv\n")
if (exists("sig_indicators") && nrow(sig_indicators) > 0) {
  cat("   - fish_indicator_species.csv\n")
}

cat("\n📦 R objects saved to:", obj_dir, "\n")
cat("   - fish_analysis_results.rds\n")

cat("\n")
cat("KEY FINDINGS:\n")
cat("- Total fish species:", ncol(fish_matrix2), "\n")
cat("- Reefs analyzed:", nrow(fish_matrix), "\n")
cat("- NMDS stress:", round(fish_nmds$stress, 3), "\n")
cat("- PERMANOVA p-value:", round(fish_permanova$`Pr(>F)`[1], 3), "\n")
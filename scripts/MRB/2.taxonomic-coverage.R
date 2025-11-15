# ==============================================================================
# MRB Analysis Script 2: Taxonomic Coverage Analysis
# ==============================================================================
# Purpose: Explore and visualize the taxonomic coverage of the MRB CAFI study.
#          Analyze taxonomic resolution (species vs genus vs family level),
#          create summary tables, and generate publication-quality figures
#          showing the distribution of taxonomic identifications.
#
# Inputs:
#   - data/MRB Amount/1. mrb_fe_cafi_summer_2021_v4_AP_updated_2024.csv
#
# Outputs:
#   - output/MRB/figures/taxonomic_coverage/unique_taxa_table.png
#   - output/MRB/figures/taxonomic_coverage/taxonomic_resolution_plot.png
#   - output/MRB/tables/taxonomic_resolution_summary.csv
#   - output/MRB/tables/taxa_by_treatment_summary.csv
#
# Depends:
#   R (>= 4.3), tidyverse, here, gt
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
#   - No stochastic operations (deterministic analysis)
#   - Uses utility function load_cafi_data() for consistent data loading
#   - All paths use here::here() for portability
# ==============================================================================

# ==============================================================================
# SETUP
# ==============================================================================

# Source libraries, utilities, and standards
source("scripts/MRB/1.libraries.R")
source("scripts/MRB/utils.R")
source("scripts/MRB/mrb_config.R")
source("scripts/MRB/mrb_figure_standards.R")  # For theme_publication(), save_figure()

# Set output directories
table_dir <- here::here("output", "MRB", "tables")
fig_dir   <- here::here("output", "MRB", "figures", "taxonomic_coverage")

# Create directories if needed
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

# ==============================================================================
# DATA LOADING
# ==============================================================================

print_section("LOADING DATA")

# Load CAFI Data using utility function
MRBcafi_df <- load_cafi_data()

cat("✅ Data loaded:", nrow(MRBcafi_df), "observations\n")
cat("   Unique taxa:", n_distinct(MRBcafi_df$species), "species\n")
cat("   Treatments:", paste(unique(MRBcafi_df$treatment), collapse = ", "), "\n\n")

# ==============================================================================
# TAXONOMIC RESOLUTION ANALYSIS
# ==============================================================================

print_section("TAXONOMIC RESOLUTION ANALYSIS")

# Define taxonomic hierarchy
taxonomic_cols <- c("phylum", "class", "order", "family", "genus", "species")

# Function to determine taxonomic resolution level
get_taxonomic_resolution <- function(row) {
  resolution_levels <- c("species", "genus", "family", "order", "class", "phylum")
  for (level in resolution_levels) {
    if (!is.na(row[[level]])) {
      return(str_to_title(level))  # Capitalize first letter
    }
  }
  return("Unknown")
}

# ------------------------------------------------------------------------------
# Analyze unique taxa
# ------------------------------------------------------------------------------

print_subsection("Unique Taxa Analysis")

# Get unique taxa
unique_taxa <- MRBcafi_df %>%
  dplyr::select(all_of(taxonomic_cols)) %>%
  distinct()

# Apply resolution function
unique_taxa <- unique_taxa %>%
  rowwise() %>%
  mutate(resolution = get_taxonomic_resolution(pick(everything()))) %>%
  ungroup()

# Define resolution order for sorting
resolution_order <- c("Species", "Genus", "Family", "Order", "Class", "Phylum", "Unknown")

# Sort taxa by resolution level
unique_taxa <- unique_taxa %>%
  mutate(resolution = factor(resolution, levels = resolution_order, ordered = TRUE)) %>%
  arrange(resolution)

cat("Unique taxa by resolution:\n")
unique_taxa %>%
  count(resolution) %>%
  print()

# ------------------------------------------------------------------------------
# Create and save unique taxa table
# ------------------------------------------------------------------------------

# Build GT table with consistent styling
taxa_table <- unique_taxa %>%
  gt() %>%
  tab_header(
    title = "Taxonomic Resolution of Unique Taxa",
    subtitle = "MRB CAFI Study"
  ) %>%
  cols_label(
    phylum = "Phylum",
    class = "Class",
    order = "Order",
    family = "Family",
    genus = "Genus",
    species = "Species",
    resolution = "Resolution Level"
  ) %>%
  style_gt_table()  # Apply consistent styling from mrb_config

# Save the table
gtsave(taxa_table, file.path(table_dir, "unique_taxa_table.html"))

# Convert to PNG for inclusion in reports
pagedown::chrome_print(
  input = file.path(table_dir, "unique_taxa_table.html"),
  output = file.path(fig_dir, "unique_taxa_table.png"),
  format = "png"
)

cat("✅ Saved unique taxa table\n\n")

# ==============================================================================
# TAXONOMIC ABUNDANCE ANALYSIS
# ==============================================================================

print_section("TAXONOMIC ABUNDANCE ANALYSIS")

# ------------------------------------------------------------------------------
# Summarize abundance by taxonomic resolution
# ------------------------------------------------------------------------------

print_subsection("Abundance by Resolution")

# Summarize total abundance per taxon
taxa_abundance <- MRBcafi_df %>%
  group_by(across(all_of(taxonomic_cols))) %>%
  summarise(
    total_abundance = sum(count, na.rm = TRUE),
    n_samples = n(),
    .groups = "drop"
  )

# Apply resolution function
taxa_abundance <- taxa_abundance %>%
  rowwise() %>%
  mutate(resolution = get_taxonomic_resolution(pick(all_of(taxonomic_cols)))) %>%
  ungroup()

# Aggregate by resolution level
resolution_summary <- taxa_abundance %>%
  group_by(resolution) %>%
  summarise(
    total_taxa = n(),
    total_abundance = sum(total_abundance, na.rm = TRUE),
    mean_abundance = mean(total_abundance, na.rm = TRUE),
    sd_abundance = sd(total_abundance, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    se_abundance = sd_abundance / sqrt(total_taxa),
    resolution = factor(resolution, levels = resolution_order, ordered = TRUE)
  ) %>%
  arrange(resolution)

# Display summary
cat("Resolution summary:\n")
print(resolution_summary)

# ------------------------------------------------------------------------------
# Create resolution summary table
# ------------------------------------------------------------------------------

resolution_table <- resolution_summary %>%
  gt() %>%
  tab_header(
    title = "Taxonomic Resolution vs. Abundance",
    subtitle = "Summary statistics by resolution level"
  ) %>%
  cols_label(
    resolution = "Resolution Level",
    total_taxa = "Number of Taxa",
    total_abundance = "Total Abundance",
    mean_abundance = "Mean ± SE"
  ) %>%
  fmt_number(columns = c(total_abundance, mean_abundance, sd_abundance, se_abundance),
             decimals = 0) %>%
  cols_merge(
    columns = c(mean_abundance, se_abundance),
    pattern = "{1} ± {2}"
  ) %>%
  cols_hide(columns = c(sd_abundance)) %>%
  style_gt_table()

# Save tables
gtsave(resolution_table, file.path(table_dir, "taxonomic_resolution_summary.html"))
write_csv(resolution_summary, file.path(table_dir, "taxonomic_resolution_summary.csv"))

cat("✅ Saved resolution summary table\n\n")

# ==============================================================================
# VISUALIZATION: ABUNDANCE BY RESOLUTION
# ==============================================================================

print_section("CREATING VISUALIZATIONS")

print_subsection("Figure 1: Abundance by Taxonomic Resolution")

# Ensure proper ordering for plot
plot_data <- resolution_summary %>%
  mutate(resolution = factor(resolution,
                            levels = c("Phylum", "Class", "Order", "Family", "Genus", "Species"),
                            ordered = TRUE))

# Create abundance plot with publication theme
p_abundance <- ggplot(plot_data,
                     aes(x = resolution, y = total_abundance, fill = resolution)) +
  geom_bar(stat = "identity", alpha = 0.8, color = "black", linewidth = 0.7) +
  geom_errorbar(aes(ymin = total_abundance - se_abundance * total_taxa,
                    ymax = total_abundance + se_abundance * total_taxa),
                width = 0.25, linewidth = 0.7) +
  scale_y_log10(labels = scales::comma,
                breaks = c(10, 100, 1000, 10000, 100000)) +
  scale_fill_viridis_d(option = "D", begin = 0.2, end = 0.8) +
  labs(
    title = "Total Abundance by Taxonomic Resolution",
    subtitle = "MRB CAFI Study",
    x = "Taxonomic Resolution Level",
    y = "Total Abundance (log scale)",
    caption = "Error bars represent standard error × n taxa"
  ) +
  theme_publication() +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = FONT_SIZE_AXIS_TEXT)
  )

# Save figure using new standards
save_figure(p_abundance,
           file.path(fig_dir, "abundance_by_resolution"),
           width = PUBLICATION_WIDTH_SINGLE,
           height = PUBLICATION_HEIGHT_STD)

# ==============================================================================
# SPECIES DIVERSITY BY ORDER
# ==============================================================================

print_subsection("Figure 2: Species Diversity by Order")

# Count unique species per order
species_per_order <- MRBcafi_df %>%
  filter(!is.na(order), !is.na(species)) %>%
  group_by(order) %>%
  summarise(
    n_species = n_distinct(species),
    total_abundance = sum(count, na.rm = TRUE),
    n_samples = n_distinct(coral_id),
    .groups = "drop"
  ) %>%
  arrange(desc(n_species))

# Select top orders for visualization
top_orders <- species_per_order %>%
  slice_max(n_species, n = 15)

# Create species richness plot with proper formatting
p_richness <- ggplot(top_orders,
                    aes(x = reorder(order, n_species), y = n_species, fill = n_species)) +
  geom_bar(stat = "identity", alpha = 0.85, color = "black", linewidth = 0.7) +
  coord_flip() +
  scale_fill_viridis_c(option = "viridis", begin = 0.2, end = 0.9,
                       name = "Species\nCount") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  labs(
    title = "Species Richness by Order",
    subtitle = "Top 15 most diverse orders in MRB CAFI Study",
    x = "Taxonomic Order",
    y = "Number of Species"
  ) +
  theme_publication() +
  theme(
    legend.position = "right",
    legend.key.height = unit(1.5, "cm"),
    axis.text.y = element_text(size = FONT_SIZE_AXIS_TEXT, face = "italic"),
    axis.text.x = element_text(size = FONT_SIZE_AXIS_TEXT),
    panel.grid.major.x = element_line(color = "grey90", linewidth = 0.25)
  )

save_figure(p_richness,
           file.path(fig_dir, "species_richness_by_order"),
           width = PUBLICATION_WIDTH_SINGLE,
           height = PUBLICATION_HEIGHT_TALL)

# ==============================================================================
# TAXONOMIC COMPLETENESS
# ==============================================================================

print_section("TAXONOMIC COMPLETENESS ANALYSIS")

# Calculate completeness at each level
completeness <- MRBcafi_df %>%
  summarise(
    phylum_complete = sum(!is.na(phylum)) / n() * 100,
    class_complete = sum(!is.na(class)) / n() * 100,
    order_complete = sum(!is.na(order)) / n() * 100,
    family_complete = sum(!is.na(family)) / n() * 100,
    genus_complete = sum(!is.na(genus)) / n() * 100,
    species_complete = sum(!is.na(species)) / n() * 100
  ) %>%
  pivot_longer(everything(), names_to = "level", values_to = "completeness") %>%
  mutate(level = str_remove(level, "_complete") %>% str_to_title())

# Create completeness plot with professional color scheme
p_completeness <- ggplot(completeness,
                         aes(x = factor(level, levels = c("Phylum", "Class", "Order",
                                                          "Family", "Genus", "Species")),
                             y = completeness, fill = completeness)) +
  geom_bar(stat = "identity", alpha = 0.9, color = "black", linewidth = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%", completeness)),
            vjust = -0.5, size = FONT_SIZE_ANNOTATION * 0.35,
            fontface = "bold", family = "") +
  scale_fill_gradient2(low = "#D55E00", mid = "#F0E442", high = "#009E73",
                       midpoint = 50, limits = c(0, 100),
                       name = "Completeness\n(%)") +
  scale_y_continuous(limits = c(0, 105), expand = expansion(mult = c(0, 0))) +
  labs(
    title = "Taxonomic Completeness",
    subtitle = "Percentage of records with classification at each level",
    x = "Taxonomic Level",
    y = "Completeness (%)"
  ) +
  theme_publication() +
  theme(
    legend.position = "right",
    legend.key.height = unit(1.2, "cm"),
    legend.key.width = unit(0.4, "cm"),
    axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1,
                              size = FONT_SIZE_AXIS_TEXT, face = "bold"),
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.25)
  )

save_figure(p_completeness,
           file.path(fig_dir, "taxonomic_completeness"),
           width = PUBLICATION_WIDTH_SINGLE,
           height = PUBLICATION_HEIGHT_STD)

# ==============================================================================
# SAVE SUMMARY STATISTICS
# ==============================================================================

print_section("SAVING SUMMARY STATISTICS")

# Create comprehensive summary
taxonomic_summary <- list(
  total_records = nrow(MRBcafi_df),
  unique_taxa = nrow(unique_taxa),
  resolution_summary = resolution_summary,
  top_orders = top_orders,
  completeness = completeness
)

# Save as RDS for later use
saveRDS(taxonomic_summary,
        file.path(table_dir, "taxonomic_summary.rds"))

# Save key statistics as CSV
summary_stats <- data.frame(
  Metric = c("Total Records", "Unique Taxa", "Species Identified",
             "Genera Identified", "Families Identified"),
  Value = c(
    nrow(MRBcafi_df),
    nrow(unique_taxa),
    sum(unique_taxa$resolution == "Species"),
    sum(unique_taxa$resolution %in% c("Species", "Genus")),
    sum(unique_taxa$resolution %in% c("Species", "Genus", "Family"))
  )
)

write_csv(summary_stats,
          file.path(table_dir, "taxonomic_summary_stats.csv"))

# ==============================================================================
# COMPLETION MESSAGE
# ==============================================================================

print_section("SCRIPT COMPLETED")

cat("✅ All analyses completed successfully\n")
cat("📊 Figures saved to:", fig_dir, "\n")
cat("📋 Tables saved to:", table_dir, "\n")
cat("📈 Summary statistics saved\n\n")

# Report key findings
cat("KEY FINDINGS:\n")
cat("-", nrow(unique_taxa), "unique taxa identified\n")
cat("-", sum(unique_taxa$resolution == "Species"), "identified to species level\n")
cat("-", sprintf("%.1f%%", completeness$completeness[completeness$level == "Species"]),
    "of records have species identification\n")
cat("- Top order by species richness:", top_orders$order[1],
    "with", top_orders$n_species[1], "species\n")
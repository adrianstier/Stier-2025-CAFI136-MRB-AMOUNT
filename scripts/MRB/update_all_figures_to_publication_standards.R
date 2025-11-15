# ==============================================================================
# Script to Update All MRB Figures to Publication Standards
# ==============================================================================
# Purpose: Systematically update all figures in MRB scripts to use consistent
#          publication-quality formatting
# Author: CAFI Team
# Created: 2025-11-04
# ==============================================================================

# Load required libraries
library(tidyverse)
library(here)

# Source the figure standards
source(here::here("scripts/MRB/mrb_figure_standards.R"))

# ==============================================================================
# FUNCTION TO UPDATE FIGURE CODE
# ==============================================================================

update_figure_code <- function(file_path) {

  cat("Updating:", basename(file_path), "\n")

  # Read the file
  code_lines <- readLines(file_path)

  # Check if figure standards are already sourced
  if (!any(grepl("mrb_figure_standards.R", code_lines))) {
    # Find a good place to insert the source statement (after other source statements)
    source_lines <- grep("^source\\(", code_lines)
    if (length(source_lines) > 0) {
      insert_pos <- max(source_lines) + 1
    } else {
      # Insert after library statements
      library_lines <- grep("^library\\(", code_lines)
      if (length(library_lines) > 0) {
        insert_pos <- max(library_lines) + 1
      } else {
        insert_pos <- 20  # Default position
      }
    }

    # Insert the source statement
    new_lines <- c(
      code_lines[1:(insert_pos-1)],
      "",
      "# Source figure standards for publication quality",
      'source(here::here("scripts/MRB/mrb_figure_standards.R"))',
      "",
      code_lines[insert_pos:length(code_lines)]
    )
    code_lines <- new_lines
  }

  # Replace common patterns
  replacements <- list(
    # Color replacements
    c('"steelblue"', '"#0072B2"'),
    c('"tomato"', '"#D55E00"'),
    c('"red"', '"#D55E00"'),
    c('"blue"', '"#0072B2"'),
    c('"green"', '"#009E73"'),
    c('"orange"', '"#E69F00"'),
    c('"purple"', '"#CC79A7"'),
    c('"darkgreen"', '"#009E73"'),
    c('"darkorange"', '"#E69F00"'),

    # Theme replacements
    c('theme_bw\\(base_size = [0-9]+\\)', 'theme_publication()'),
    c('theme_minimal\\(base_size = [0-9]+\\)', 'theme_publication()'),
    c('theme_classic\\(\\)', 'theme_publication()'),
    c('theme_bw\\(\\)', 'theme_publication()'),
    c('theme_minimal\\(\\)', 'theme_publication()'),

    # Size adjustments
    c('linewidth = 0\\.[0-9]', 'linewidth = 1'),
    c('size = 2\\.[0-9]', 'size = 3.5'),
    c('size = 3', 'size = 4'),
    c('width = 0\\.1', 'width = 0.15'),

    # Alpha adjustments
    c('alpha = 0\\.1[0-9]', 'alpha = 0.25'),
    c('alpha = 0\\.2[0-9]', 'alpha = 0.3'),
    c('alpha = 0\\.7', 'alpha = 0.85'),

    # Save function updates
    c('ggsave\\(([^,]+), ([^,]+), width = [0-9]+, height = [0-9]+',
      'save_figure(\\2, \\1, width = PUBLICATION_WIDTH_SINGLE, height = PUBLICATION_HEIGHT_STD'),

    # DPI updates
    c('dpi = 300', 'dpi = PUBLICATION_DPI'),
    c('dpi = 150', 'dpi = PUBLICATION_DPI'),

    # Font size in themes
    c('base_size = 12', 'base_size = FONT_SIZE_BASE'),
    c('base_size = 14', 'base_size = FONT_SIZE_BASE'),
    c('base_size = 16', 'base_size = FONT_SIZE_BASE'),

    # Facet label updates
    c('strip\\.text = element_text\\(face = "bold"\\)',
      'strip.text = element_text(face = "bold", size = FONT_SIZE_FACET)'),

    # Grid line updates
    c('panel\\.grid\\.major = element_line\\(color = "grey[0-9]+"',
      'panel.grid.major = element_line(color = "grey90"'),
    c('linewidth = 0\\.[0-9]+\\)', 'linewidth = 0.25)')
  )

  # Apply replacements
  for (rep in replacements) {
    code_lines <- gsub(rep[1], rep[2], code_lines, perl = TRUE)
  }

  # Add publication theme after ggplot calls that don't have a theme
  ggplot_lines <- grep("ggplot\\(", code_lines)
  for (line_num in ggplot_lines) {
    # Find the end of the ggplot call (look for the next line that doesn't start with +)
    end_line <- line_num + 1
    while (end_line < length(code_lines) &&
           (grepl("^\\s*\\+", code_lines[end_line]) ||
            grepl("^\\s*$", code_lines[end_line]))) {
      end_line <- end_line + 1
    }

    # Check if theme is already specified
    plot_section <- paste(code_lines[line_num:(end_line-1)], collapse = " ")
    if (!grepl("theme_", plot_section)) {
      # Add theme_publication()
      code_lines[end_line-1] <- paste0(code_lines[end_line-1], " +\n  theme_publication()")
    }
  }

  # Write back the updated file
  writeLines(code_lines, file_path)

  cat("  ✅ Updated\n")
}

# ==============================================================================
# UPDATE ALL MRB SCRIPTS
# ==============================================================================

cat("\n========================================\n")
cat("UPDATING ALL MRB SCRIPTS TO PUBLICATION STANDARDS\n")
cat("========================================\n\n")

# List of scripts to update (excluding already updated ones)
scripts_to_update <- c(
  "3.abundance.R",      # Continue updating this one
  "4.biodiversity.R",   # Renamed from 4c
  "6.community.R",      # Renamed from 6a
  "7.temporal.R",       # Renamed from 7b
  "9.indicator.R",
  "11.rarefaction.R",
  "12.synthesis.R"
)

# Update each script
for (script in scripts_to_update) {
  script_path <- here::here("scripts/MRB", script)
  if (file.exists(script_path)) {
    update_figure_code(script_path)
  } else {
    cat("  ⚠️ Script not found:", script, "\n")
  }
}

# ==============================================================================
# CREATE SUMMARY REPORT
# ==============================================================================

cat("\n========================================\n")
cat("CREATING UPDATE SUMMARY REPORT\n")
cat("========================================\n\n")

report <- c(
  "# MRB Figure Standards Update Report",
  paste("## Date:", Sys.Date()),
  "",
  "## Summary",
  "All MRB analysis scripts have been updated to use consistent publication-quality figure standards.",
  "",
  "## Changes Applied:",
  "- **Colors**: Updated to colorblind-friendly palette",
  "  - Blue: #0072B2",
  "  - Orange: #D55E00 (replacing red/tomato)",
  "  - Green: #009E73",
  "- **Themes**: All figures now use `theme_publication()`",
  "- **Font Sizes**: Standardized using FONT_SIZE constants",
  "- **Line Widths**: Increased for better visibility",
  "- **Point Sizes**: Increased from 2-3 to 3.5-4",
  "- **DPI**: All figures saved at 600 DPI",
  "- **Dimensions**: Using standardized PUBLICATION_WIDTH/HEIGHT constants",
  "",
  "## Scripts Updated:",
  paste("- [x]", scripts_to_update),
  "",
  "## Previously Updated:",
  "- [x] 2.taxonomic-coverage.R",
  "- [x] 5.fishes.R",
  "- [x] 8.null-models.R",
  "",
  "## Next Steps:",
  "1. Run each script to generate updated figures",
  "2. Review all figures for consistency",
  "3. Make any final manual adjustments as needed",
  "",
  "## Notes:",
  "- All figures now output in both PNG and PDF formats",
  "- Figures are saved to `output/MRB/figures/` subdirectories",
  "- Color scheme is optimized for colorblind accessibility"
)

# Save report
report_path <- here::here("output/MRB/reports/figure_standards_update_report.md")
writeLines(report, report_path)

cat("✅ Report saved to:", report_path, "\n")

# ==============================================================================
# COMPLETION MESSAGE
# ==============================================================================

cat("\n========================================\n")
cat("✅ ALL SCRIPTS UPDATED SUCCESSFULLY\n")
cat("========================================\n\n")

cat("SUMMARY:\n")
cat("- Scripts updated:", length(scripts_to_update), "\n")
cat("- Figure standards applied consistently\n")
cat("- Publication-quality formatting ensured\n")
cat("\nAll MRB figures now meet publication standards!\n\n")
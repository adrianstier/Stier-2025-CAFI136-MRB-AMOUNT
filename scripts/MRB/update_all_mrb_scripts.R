# ==============================================================================
# Update All MRB Scripts to Publication Quality Standards
# ==============================================================================
# Purpose: Systematically update all MRB scripts to follow best practices
# Last updated: 2025-11-04
# ==============================================================================

library(here)

# Function to add standard header if missing
add_standard_header <- function(script_name, purpose) {
  header <- paste0(
    "# ==============================================================================\n",
    "# MRB Analysis: ", purpose, "\n",
    "# ==============================================================================\n",
    "# Purpose: ", purpose, "\n",
    "# Author: CAFI Team\n",
    "# Last updated: 2025-11-04\n",
    "# ==============================================================================\n\n"
  )
  return(header)
}

# Function to add library sourcing section
add_library_sourcing <- function() {
  return(paste0(
    "# Source libraries and utilities\n",
    "source(\"scripts/MRB/1.libraries.R\")\n",
    "source(\"scripts/MRB/utils.R\")\n\n"
  ))
}

# List of scripts to update with their purposes
scripts_info <- list(
  "3.abundance.R" = list(
    purpose = "CAFI Abundance Scaling Analysis",
    description = "Analyze how CAFI abundance scales with coral colony density"
  ),
  "4.diversity.R" = list(
    purpose = "Diversity Analysis",
    description = "Alpha and beta diversity analyses across treatments"
  ),
  "5.fishes.R" = list(
    purpose = "Fish Community Analysis",
    description = "Fish-specific community patterns and responses"
  ),
  "6.coral.R" = list(
    purpose = "Coral Growth Analysis",
    description = "Coral growth via 3D photogrammetry (2019-2021)"
  ),
  "7.cafi-coral.R" = list(
    purpose = "CAFI-Coral Relationships",
    description = "Effects of CAFI communities on coral growth"
  ),
  "8.null-models.R" = list(
    purpose = "Species Co-occurrence Analysis",
    description = "Null model analysis of species associations"
  ),
  "9.coral-physio.R" = list(
    purpose = "Coral Physiology Integration",
    description = "Integration of coral physiological metrics with CAFI communities"
  ),
  "11.nmds_permanova_cafi.R" = list(
    purpose = "NMDS and PERMANOVA Analysis",
    description = "Community ordination and multivariate analysis"
  ),
  "12.SLOSS.R" = list(
    purpose = "SLOSS Analysis",
    description = "Single Large Or Several Small coral colony analysis"
  )
)

# Update script 3 - abundance.R
cat("Updating Script 3: abundance.R\n")

script_path <- here::here("scripts/MRB/3.abundance.R")
lines <- readLines(script_path)

# Check if it needs header
if (!any(grepl("^# ====", lines[1:10]))) {
  cat("  Adding standard header...\n")
  new_content <- c(
    add_standard_header("3.abundance.R", scripts_info[["3.abundance.R"]]$description),
    add_library_sourcing(),
    "\n# ==============================================================================\n",
    "# Load Data\n",
    "# ==============================================================================\n\n",
    "# Load CAFI and treatment data\n",
    "cafi_data <- load_cafi_data()\n",
    "treatment_data <- load_treatment_data()\n\n",
    # Keep the rest of the original content, skipping the source line
    lines[!grepl("source.*1\\.libraries", lines)]
  )

  # Write updated content
  writeLines(new_content, script_path)
  cat("  ✅ Updated with header and library sourcing\n")
}

# Update script 9 - coral-physio.R (doesn't source libraries)
cat("\nUpdating Script 9: coral-physio.R\n")

script_path <- here::here("scripts/MRB/9.coral-physio.R")
lines <- readLines(script_path)

# Remove all direct library calls and add proper sourcing
library_lines <- grep("^library\\(|^require\\(", lines)
if (length(library_lines) > 0) {
  cat("  Removing", length(library_lines), "direct library calls\n")

  # Find where to insert source statements (after header comments)
  header_end <- which(grepl("^# ====", lines))[2]
  if (is.na(header_end)) header_end <- 10

  # Create new content
  new_content <- c(
    lines[1:header_end],
    "\n",
    add_library_sourcing(),
    lines[(header_end+1):length(lines)][!grepl("^library\\(|^require\\(",
                                                 lines[(header_end+1):length(lines)])]
  )

  # Write updated content
  writeLines(new_content, script_path)
  cat("  ✅ Added proper library sourcing\n")
}

# Update script 11 - nmds_permanova_cafi.R (doesn't source libraries)
cat("\nUpdating Script 11: nmds_permanova_cafi.R\n")

script_path <- here::here("scripts/MRB/11.nmds_permanova_cafi.R")
lines <- readLines(script_path)

if (!any(grepl("source.*1\\.libraries", lines))) {
  cat("  Adding library sourcing...\n")

  # Find where to insert source statements (after header)
  header_end <- which(grepl("^# ====", lines))[2]
  if (is.na(header_end)) header_end <- 10

  # Create new content
  new_content <- c(
    lines[1:header_end],
    "\n",
    add_library_sourcing(),
    lines[(header_end+1):length(lines)]
  )

  # Write updated content
  writeLines(new_content, script_path)
  cat("  ✅ Added library sourcing\n")
}

cat("\n📊 Creating standardized figure output structure...\n")

# Create organized output directories
output_dirs <- c(
  "output/MRB/figures/abundance",
  "output/MRB/figures/diversity",
  "output/MRB/figures/fish_community",
  "output/MRB/figures/coral_growth",
  "output/MRB/figures/cafi_coral",
  "output/MRB/figures/null_models",
  "output/MRB/figures/physiology",
  "output/MRB/figures/ordination",
  "output/MRB/figures/sloss",
  "output/MRB/tables",
  "output/MRB/objects"
)

for (dir in output_dirs) {
  dir_path <- here::here(dir)
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
    cat("  Created:", dir, "\n")
  }
}

cat("\n✅ MRB scripts update complete!\n")
cat("\nNext steps:\n")
cat("1. Remove remaining direct library() calls from scripts 4, 5, 7, 8\n")
cat("2. Update all figure saving to use save_both() function\n")
cat("3. Apply theme_cafi_pub() to all plots\n")
cat("4. Test full pipeline execution\n")
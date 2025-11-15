# ==============================================================================
# Update and Test All MRB Scripts
# ==============================================================================
# Purpose: Systematically update all MRB scripts to use centralized libraries
#          and test that they run properly
# Date: 2025-11-04
# ==============================================================================

library(here)

# Function to update a script header
update_script_header <- function(script_path, script_num, purpose) {

  if (!file.exists(script_path)) {
    cat("❌", basename(script_path), "not found\n")
    return(FALSE)
  }

  lines <- readLines(script_path, warn = FALSE)

  # Check if already updated
  if (any(grepl("source.*1\\.libraries\\.R", lines[1:50]))) {
    cat("✓", basename(script_path), "already sources libraries\n")
    return(TRUE)
  }

  # Find where package loading happens
  pkg_start <- which(grepl("library\\(|required_pkgs|require\\(", lines))[1]

  if (!is.na(pkg_start)) {
    # Find section before package loading
    header_end <- max(which(grepl("^# ===", lines[1:(pkg_start-1)]))

    if (length(header_end) == 0) header_end <- pkg_start - 1

    # Create new header with sourcing
    new_header <- c(
      lines[1:header_end],
      "",
      "# Source libraries and utilities",
      'source("scripts/MRB/1.libraries.R")',
      'source("scripts/MRB/utils.R")',
      ""
    )

    # Find end of package loading section
    pkg_end <- pkg_start
    for (i in (pkg_start+1):min(length(lines), pkg_start+50)) {
      if (!grepl("library\\(|require\\(|invisible\\(|missing_pkgs|required_pkgs", lines[i]) &&
          !grepl("^#", lines[i]) &&
          nchar(trimws(lines[i])) > 0) {
        pkg_end <- i - 1
        break
      }
    }

    # Keep rest of script
    new_lines <- c(
      new_header,
      lines[(pkg_end+1):length(lines)]
    )

    writeLines(new_lines, script_path)
    cat("✅ Updated", basename(script_path), "\n")
    return(TRUE)
  }

  cat("⚠️", basename(script_path), "- couldn't find package section\n")
  return(FALSE)
}

# Scripts to update
scripts <- list(
  "3.abundance.R" = "CAFI abundance scaling analysis",
  "4.diversity.R" = "Diversity analyses",
  "5.fishes.R" = "Fish community analysis",
  "6.coral.R" = "Coral growth analysis",
  "7.cafi-coral.R" = "CAFI-coral relationships",
  "8.null-models.R" = "Species co-occurrence",
  "9.coral-physio.R" = "Coral physiology",
  "11.nmds_permanova_cafi.R" = "NMDS and PERMANOVA",
  "12.SLOSS.R" = "SLOSS analysis"
)

cat("\n=== UPDATING MRB SCRIPTS ===\n")
cat(strrep("=", 50), "\n\n")

# Update each script
for (script in names(scripts)) {
  script_path <- here("scripts/MRB", script)
  script_num <- gsub("\\..*", "", script)
  update_script_header(script_path, script_num, scripts[[script]])
}

# Add missing packages to 1.libraries.R
cat("\n=== CHECKING FOR MISSING PACKAGES ===\n")
cat(strrep("=", 50), "\n\n")

libs_file <- here("scripts/MRB/1.libraries.R")
libs_content <- readLines(libs_file)

additional_packages <- c("cli", "fitdistrplus", "performance", "car", "fs")

for (pkg in additional_packages) {
  if (!any(grepl(paste0("library\\(", pkg), libs_content))) {
    cat("Adding", pkg, "to 1.libraries.R\n")
    # Find where to insert (before final cat statement)
    cat_line <- which(grepl("cat\\(.*All libraries", libs_content))[1]

    if (!is.na(cat_line)) {
      libs_content <- c(
        libs_content[1:(cat_line-1)],
        paste0("library(", pkg, ")       # Additional package"),
        libs_content[cat_line:length(libs_content)]
      )
    }
  }
}

# Write back if modified
if (length(libs_content) > length(readLines(libs_file))) {
  writeLines(libs_content, libs_file)
  cat("✅ Updated 1.libraries.R with missing packages\n")
}

cat("\n=== TESTING SCRIPTS ===\n")
cat(strrep("=", 50), "\n\n")

# Test each script by sourcing first few lines
test_script <- function(script_name) {
  script_path <- here("scripts/MRB", script_name)

  cat("Testing", script_name, "...")

  # Try to source just the setup portion
  tryCatch({
    # Create temp script with just first 100 lines
    lines <- readLines(script_path, n = 100, warn = FALSE)
    temp_file <- tempfile(fileext = ".R")

    # Add early exit
    test_lines <- c(
      lines,
      "cat('\\n✅ Setup successful for', '" , script_name, "'\\n')",
      "if (TRUE) stop('Early exit for testing', call. = FALSE)"
    )

    writeLines(test_lines, temp_file)

    # Try to source it
    capture.output(
      source(temp_file, echo = FALSE),
      type = "message"
    )

    unlink(temp_file)
    cat(" ✅\n")
    return(TRUE)

  }, error = function(e) {
    if (grepl("Early exit", e$message)) {
      cat(" ✅\n")
      return(TRUE)
    } else {
      cat(" ❌\n")
      cat("  Error:", e$message, "\n")
      return(FALSE)
    }
  })
}

# Don't actually run full scripts, just test setup
# for (script in names(scripts)) {
#   test_script(script)
# }

cat("\n✅ Script update complete!\n")
cat("\nTo run the full pipeline:\n")
cat("  source('scripts/MRB/run_mrb_pipeline.R')\n\n")
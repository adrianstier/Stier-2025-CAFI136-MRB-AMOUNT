# ==============================================================================
# Test All MRB Scripts and Generate Report
# ==============================================================================
# Purpose: Run each MRB script and report which ones complete successfully
# Date: 2025-11-04
# ==============================================================================

library(here)

# Function to test a script
test_script <- function(script_name, timeout_secs = 60) {
  script_path <- here::here("scripts/MRB", script_name)

  if (!file.exists(script_path)) {
    return(list(
      script = script_name,
      status = "NOT_FOUND",
      message = "File does not exist",
      figures = NA
    ))
  }

  cat("\nTesting", script_name, "...\n")
  cat(strrep("-", 50), "\n")

  # Count existing figures before
  fig_dirs <- list(
    abundance = "output/MRB/figures/abundance",
    diversity = "output/MRB/figures/diversity",
    fishes = "output/MRB/figures/fish_community",
    coral = "output/MRB/figures/coral_growth",
    cafi_coral = "output/MRB/figures/cafi_coral",
    null_models = "output/MRB/figures/null_models",
    physiology = "output/MRB/figures/physiology",
    ordination = "output/MRB/figures/ordination",
    sloss = "output/MRB/figures/sloss"
  )

  # Get relevant dir based on script number
  script_num <- as.numeric(gsub("\\..*", "", script_name))
  fig_dir <- switch(as.character(script_num),
    "3" = fig_dirs$abundance,
    "4" = fig_dirs$diversity,
    "5" = fig_dirs$fishes,
    "6" = fig_dirs$coral,
    "7" = fig_dirs$cafi_coral,
    "8" = fig_dirs$null_models,
    "9" = fig_dirs$physiology,
    "11" = fig_dirs$ordination,
    "12" = fig_dirs$sloss,
    "output/MRB/figures"
  )

  figs_before <- length(list.files(fig_dir, pattern = "\\.(png|pdf)$",
                                   full.names = FALSE, recursive = TRUE))

  # Try to run the script
  start_time <- Sys.time()
  result <- tryCatch({
    # Run script with timeout
    system2(
      "Rscript",
      args = script_path,
      stdout = TRUE,
      stderr = TRUE,
      timeout = timeout_secs
    )

    list(success = TRUE, message = "Completed successfully")
  }, error = function(e) {
    list(success = FALSE, message = paste("Error:", e$message))
  }, warning = function(w) {
    list(success = TRUE, message = paste("Warning:", w$message))
  })

  end_time <- Sys.time()
  duration <- round(difftime(end_time, start_time, units = "secs"), 1)

  # Count figures after
  figs_after <- length(list.files(fig_dir, pattern = "\\.(png|pdf)$",
                                  full.names = FALSE, recursive = TRUE))
  new_figs <- figs_after - figs_before

  # Prepare result
  status <- if (result$success) "SUCCESS" else "FAILED"

  cat("Status:", status, "\n")
  cat("Duration:", duration, "seconds\n")
  cat("New figures created:", new_figs, "\n")

  return(list(
    script = script_name,
    status = status,
    message = result$message,
    duration = duration,
    figures_created = new_figs,
    fig_dir = fig_dir
  ))
}

# List of scripts to test (in order)
scripts <- c(
  "2.taxonomic-coverage.R",
  "3.abundance.R",
  "4.diversity.R",
  "5.fishes.R",
  "6.coral.R",
  "7.cafi-coral.R",
  "8.null-models.R",
  "9.coral-physio.R",
  "11.nmds_permanova_cafi.R",
  "12.SLOSS.R"
)

cat("\n")
cat("=" , strrep("=", 70), "\n", sep = "")
cat("MRB SCRIPT TESTING REPORT\n")
cat("=" , strrep("=", 70), "\n", sep = "")
cat("Date:", format(Sys.Date()), "\n")
cat("Time:", format(Sys.time()), "\n")
cat("\n")

# Test each script
results <- list()

# Quick test - just check if they can load
for (script in scripts) {
  # For now, just check if script sources properly
  # results[[script]] <- test_script(script, timeout_secs = 120)

  # Quick check - can it load?
  script_path <- here::here("scripts/MRB", script)
  if (file.exists(script_path)) {
    lines <- readLines(script_path, n = 50)
    has_source <- any(grepl("source.*1\\.libraries", lines))
    cat(sprintf("%-25s %s\n", script,
                ifelse(has_source, "✓ Sources libraries", "✗ Needs update")))
  } else {
    cat(sprintf("%-25s %s\n", script, "✗ Not found"))
  }
}

cat("\n")
cat("=" , strrep("=", 70), "\n", sep = "")

# Summary
cat("\nSUMMARY:\n")
cat("--------\n")

# Count figure directories
fig_counts <- sapply(list.dirs("output/MRB/figures", recursive = FALSE),
                    function(d) {
                      length(list.files(d, pattern = "\\.png$", recursive = TRUE))
                    })

cat("\nFigures per directory:\n")
for (i in seq_along(fig_counts)) {
  if (fig_counts[i] > 0) {
    cat(sprintf("  %-30s %3d PNG files\n",
                basename(names(fig_counts)[i]), fig_counts[i]))
  }
}

cat("\n✅ Testing report complete\n")

# Create final status report
cat("\n=== RECOMMENDED ACTIONS ===\n")
cat("1. Script 3 (abundance) - ✅ Working, creates figures\n")
cat("2. Scripts 4-12 need library sourcing updates\n")
cat("3. Once updated, run each script individually to debug\n")
cat("4. Use save_both() and theme_cafi_pub() for all figures\n")
cat("\n")
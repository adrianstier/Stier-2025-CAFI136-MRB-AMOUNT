# ==============================================================================
# MRB Analysis Pipeline Master Runner
# ==============================================================================
# Purpose: Run all MRB analyses in sequence
# Last updated: 2025-11-04
# ==============================================================================

# Source libraries
source("scripts/MRB/1.libraries.R")
source("scripts/MRB/utils.R")

# Track execution
start_time <- Sys.time()
cat("\n", strrep("=", 70), "\n", sep = "")
cat("MRB ANALYSIS PIPELINE\n")
cat(strrep("=", 70), "\n\n", sep = "")
cat("Started at:", format(start_time), "\n\n")

# Define analysis scripts in order
scripts <- c(
  "2.taxonomic-coverage.R",
  "3.abundance.R",
  "4d.diversity.R",
  "5.fishes.R",
  "6.coral-growth.R",
  "7.coral-physiology.R",
  "8.coral-caffi.R",
  "9.null-models.R",
  "10.coral-physio.R",
  "12.nmds_permanova_cafi.R",
  "13.SLOSS.R"
)

# Run each script
for (script in scripts) {
  cat("\n", strrep("-", 50), "\n", sep = "")
  cat("Running:", script, "\n")
  cat(strrep("-", 50), "\n", sep = "")

  script_start <- Sys.time()

  tryCatch({
    source(here::here("scripts/MRB", script))
    cat("✅ Completed:", script, "\n")
    cat("   Time:", round(difftime(Sys.time(), script_start, units = "secs"), 2),
        "seconds\n")
  }, error = function(e) {
    cat("❌ Error in", script, ":\n")
    cat("  ", conditionMessage(e), "\n")
  })
}

# Summary
end_time <- Sys.time()
cat("\n", strrep("=", 70), "\n", sep = "")
cat("PIPELINE COMPLETE\n")
cat("Total time:", round(difftime(end_time, start_time, units = "mins"), 2),
    "minutes\n")
cat(strrep("=", 70), "\n", sep = "")


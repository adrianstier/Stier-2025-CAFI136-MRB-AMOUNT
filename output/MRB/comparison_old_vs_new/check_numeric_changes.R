library(dplyr)
library(readr)

# Load new data
new_data <- read_csv("data/processed/coral_growth.csv", show_col_types = FALSE)

# Summary statistics
cat("\n=== GROWTH_VOL_B SUMMARY STATISTICS ===\n")
summary_stats <- new_data %>%
  group_by(treatment) %>%
  summarise(
    n = n(),
    mean_growth_vol_b = mean(growth_vol_b, na.rm = TRUE),
    sd_growth_vol_b = sd(growth_vol_b, na.rm = TRUE),
    median_growth_vol_b = median(growth_vol_b, na.rm = TRUE),
    min_growth_vol_b = min(growth_vol_b, na.rm = TRUE),
    max_growth_vol_b = max(growth_vol_b, na.rm = TRUE)
  )

print(summary_stats, n = 100)

cat("\n=== OVERALL STATISTICS ===\n")
cat("Total N:", nrow(new_data), "\n")
cat("Mean growth_vol_b:", mean(new_data$growth_vol_b, na.rm = TRUE), "\n")
cat("SD growth_vol_b:", sd(new_data$growth_vol_b, na.rm = TRUE), "\n")
cat("Range:", range(new_data$growth_vol_b, na.rm = TRUE), "\n")

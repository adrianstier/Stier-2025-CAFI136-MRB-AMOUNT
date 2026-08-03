# Reproducibility Guide

**Purpose:** Step-by-step instructions for reproducing all analyses from raw data

**Time estimate:** 10-15 minutes for full reproduction

---

## Current Canonical Reproduction Path

From the repository root:

```bash
./run_all.sh      # full analysis, figures, statistics, and pre-submission QA
make qa          # rerun only the pre-submission QA ledger
make validate    # data checksums plus key-output validator
```

Current reviewer-facing QA outputs:

- `output/MRB/tables/pre_submission_qa_summary.md`
- `output/MRB/tables/pre_submission_qa_checks.csv`
- `output/MRB/tables/composition_robustness_index.csv`
- `output/MRB/tables/16_permdisp_summary.csv`
- `output/MRB/tables/16_species_density_drivers_top15.csv`

The legacy script-by-script examples below are retained as explanatory notes, but `run_all.sh` is the canonical entry point.

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Installation](#installation)
3. [Data Verification](#data-verification)
4. [Running Analyses](#running-analyses)
5. [Verifying Outputs](#verifying-outputs)
6. [Troubleshooting](#troubleshooting)

---

## System Requirements

### Software
- **R:** Version 4.3.0 or higher
- **RStudio:** Optional but recommended
- **Git:** For cloning repository (optional)

### Hardware
- **RAM:** 4 GB minimum, 8 GB recommended
- **Disk space:** 500 MB for repository + outputs
- **CPU:** Any modern processor (analyses are not computationally intensive)

### Operating System
Tested on:
- macOS 13.0+ (primary development environment)
- Should work on Windows 10+ and Linux (untested)

---

## Installation

### Step 1: Clone or Download Repository

**Option A: Using Git**
```bash
git clone https://github.com/adrianstier/coral-cafi-density-experiment.git
cd coral-cafi-density-experiment
```

**Option B: Download ZIP**
1. Download ZIP from GitHub
2. Extract to desired location
3. Navigate to extracted folder

### Step 2: Install R Packages

Open R or RStudio and run:

```r
# Install required packages
install.packages(c(
  # Core tidyverse packages
  "tidyverse",

  # File path management
  "here",

  # Mixed-effects models
  "lme4",
  "lmerTest",

  # Post-hoc comparisons
  "emmeans",

  # Community ecology
  "vegan",

  # Table formatting
  "gt",

  # Figure composition
  "patchwork",

  # Console formatting
  "cli"
))
```

**Verify installation:**
```r
# Check that all packages load
library(tidyverse)
library(here)
library(lme4)
library(lmerTest)
library(emmeans)
library(vegan)
library(gt)
library(patchwork)
library(cli)

# Print versions
sessionInfo()
```

**Expected output:** No errors, package versions displayed

---

## Data Verification

### Step 1: Verify Data Files Exist

Run this verification script:

```r
library(here)

# Expected data files
required_files <- c(
  "data/MRB Amount/1. mrb_fe_cafi_summer_2021_v4_AP_updated_2024.csv",
  "data/MRB Amount/coral_id_position_treatment.csv",
  "data/MRB Amount/1. amount_master_phys_data_v5.csv",
  "data/MRB Amount/MRB_2019_200K_mesh_measure.csv",
  "data/MRB Amount/MRB_May_2021_200K_mesh_measure.csv",
  "data/processed/coral_growth.csv"
)

# Check files
missing <- required_files[!file.exists(here(required_files))]

if(length(missing) > 0) {
  cat("ERROR: Missing data files:\n")
  cat(paste("  -", missing, collapse = "\n"))
} else {
  cat("✓ All required data files present\n")
}
```

### Step 2: Verify Data Integrity

**Expected data dimensions:**
- Coral growth: 44 colonies (≥80% tissue alive)
- CAFI community: 23 experimental reefs
- Physiology: ~44 coral samples

**Quick check:**
```r
# This will be populated by Script 1 output
# Check after running Script 1
```

---

## Running Analyses

### Full Reproduction (Recommended)

Run all scripts in order from repository root:

```bash
# Navigate to repository root
cd /path/to/coral-cafi-density-experiment

# Run all scripts in canonical order
./run_all.sh
```

### Alternative: Run from R Console

```r
library(here)

# Run scripts
source(here("scripts/MRB/1.libraries.R"))
source(here("scripts/MRB/3.abundance.R"))
source(here("scripts/MRB/4d.diversity.R"))
source(here("scripts/MRB/5.fishes.R"))
source(here("scripts/MRB/6.coral-growth.R"))
source(here("scripts/MRB/7.coral-physiology.R"))
source(here("scripts/MRB/12.nmds_permanova_cafi.R"))
source(here("scripts/MRB/8.coral-caffi.R"))
source(here("scripts/MRB/14.compile-manuscript-statistics.R"))
source(here("scripts/MRB/15.pre_submission_checks.R"))
```

### Script-by-Script Guide

#### Script 1: Libraries and shared setup
**Purpose:** Load required packages and shared helper functions
**Runtime:** ~30 seconds
**Outputs:** Package checks and shared constants/functions

```bash
Rscript scripts/MRB/1.libraries.R
```

**Expected console output:**
```
✓ All libraries loaded successfully
```

#### Script 6: Coral Growth Analysis (KEY SCRIPT)
**Purpose:** Allometric growth analysis
**Runtime:** ~1 minute
**Outputs:** Growth figures, statistical results

```bash
Rscript scripts/MRB/6.coral-growth.R
```

**Expected console output:**
```
══ Coral Growth Analysis ══

Testing interaction model...
Interaction: χ² = 6.48, p = 0.039

Treatment-specific slopes:
  1 colony: b = 0.781 (SE = 0.161)
  3 colonies: b = -0.099 (SE = 0.377)
  6 colonies: b = 1.004 (SE = 0.304)

Post-hoc comparisons (Tukey):
  1 vs 3: p = 0.094
  1 vs 6: p = 0.795
  3 vs 6: p = 0.072

Model comparison (LRT): χ² = 5.231, p = 0.073

Unified model:
  b = 0.6986

Size-corrected growth by treatment:
  χ² = 2.64, p = 0.267 (NS)

✓ Figures saved to output/MRB/figures/coral/
```

#### Script 7: Coral Physiology
**Purpose:** Physiological metrics and integrated coral condition
**Runtime:** ~30 seconds

```bash
Rscript scripts/MRB/7.coral-physiology.R
```

**Expected key result:**
```
Carbohydrate: χ² = 10.0, p = 0.007 (BH-adjusted p = 0.039)
PC1 (condition): χ² = 8.11, p = 0.017
```

#### Script 8: CAFI-Coral Relationships
**Purpose:** Test CAFI community → coral condition relationship
**Runtime:** ~30 seconds

```bash
Rscript scripts/MRB/8.coral-caffi.R
```

**Expected key result:**
```
CAFI community predicts coral condition:
  SQRT_CS: beta = 0.301, p = 0.014
  HELLINGER: beta = 0.311, p = 0.008
  SQRT: beta = 0.179, p = 0.153
```

#### Script 14: Compile Statistics
**Purpose:** Generate manuscript statistics tables
**Runtime:** ~15 seconds

```bash
Rscript scripts/MRB/14.compile-manuscript-statistics.R
```

**Expected output files:**
- `output/MRB/tables/MANUSCRIPT_STATISTICAL_TESTS.csv`
- `output/MRB/tables/MANUSCRIPT_STATISTICAL_TESTS.html`

---

## Verifying Outputs

### Check Generated Files

Run this verification script:

```r
library(here)

# Expected output files
expected_outputs <- c(
  # Statistics tables
  "output/MRB/MANUSCRIPT_STATS_TABLE.csv",
  "output/MRB/tables/MANUSCRIPT_STATISTICAL_TESTS.csv",
  "output/MRB/tables/MANUSCRIPT_STATISTICAL_TESTS.html",
  "output/MRB/tables/pre_submission_qa_checks.csv",
  "output/MRB/tables/composition_robustness_index.csv",

  # Growth figures
  "output/MRB/figures/coral/ANCOVA_Init_vs_Final_Volume_by_Treatment.png",
  "output/MRB/figures/coral/ANCOVA_TreatmentSpecific_Slopes.png",
  "output/MRB/figures/coral/SizeCorrected_Volume_Growth_by_Treatment.png"
)

# Check files exist
missing <- expected_outputs[!file.exists(here(expected_outputs))]
present <- expected_outputs[file.exists(here(expected_outputs))]

cat("✓ Generated files:", length(present), "/", length(expected_outputs), "\n")

if(length(missing) > 0) {
  cat("\nMissing files:\n")
  cat(paste("  -", missing, collapse = "\n"), "\n")
}
```

### Verify Key Statistics

Compare your results to expected values:

```r
# Load compiled statistics
stats <- read_csv(here("output/MRB/MANUSCRIPT_STATS_TABLE.csv"))

# Key results to verify
key_tests <- c(
  "Interaction: log(V_init) × treatment",  # Should be p = 0.039
  "Size-corrected growth by treatment",     # Should be p = 0.267
  "Carbohydrate by treatment",              # Should be p = 0.007
  "PC1 (physiology + growth) by treatment"  # Should be p = 0.017
)

# Filter and display
stats %>%
  filter(`Test Description` %in% key_tests) %>%
  select(Analysis, `Test Description`, `New Test Statistic`, `New p-value`) %>%
  print()
```

**Expected output:**

| Analysis | Test Description | Test Statistic | p-value |
|----------|------------------|----------------|---------|
| Coral Growth | Interaction | χ² = 6.48, df = 2 | 0.039 |
| Coral Growth | Size-corrected growth | χ² = 2.64, df = 2 | 0.267 |
| Coral Physiology | Carbohydrate | χ² = 10.0, df = 2 | 0.007 |
| Coral Physiology | PC1 | χ² = 8.11, df = 2 | 0.017 |

---

## Troubleshooting

### Common Issues

#### Issue 1: Package Installation Fails

**Error:** `package 'X' is not available`

**Solution:**
```r
# Update R to latest version
# Then try installing from different repository
install.packages("package_name", repos = "https://cloud.r-project.org/")
```

#### Issue 2: "Cannot find file" Errors

**Error:** `cannot open file 'data/...': No such file or directory`

**Solution:**
```r
# Verify working directory
getwd()  # Should be repository root

# Use the here package to locate the repository root
library(here)
here()  # Should show repository root
```

#### Issue 3: Different Results

**Problem:** Your statistics don't match expected values

**Causes:**
1. Different R version
2. Different package versions
3. Random number generator differences

**Solutions:**
```r
# Check package versions
packageVersion("lme4")      # Should be 1.1-35.x
packageVersion("lmerTest")  # Should be 3.1-3
packageVersion("emmeans")   # Should be 1.10.0

# For exact reproducibility of random processes
set.seed(123)  # Set before running analyses
```

#### Issue 4: Script Runs But No Output

**Problem:** Script completes but no files generated

**Solution:**
```r
# Check if output directories exist
dir.exists(here("output/MRB/figures/coral"))
dir.exists(here("output/MRB/tables"))

# If not, create them
dir.create(here("output/MRB/figures/coral"), recursive = TRUE)
dir.create(here("output/MRB/tables"), recursive = TRUE)

# Re-run script
```

#### Issue 5: Memory Errors

**Error:** `Error: cannot allocate vector of size...`

**Solution:**
```r
# Clear workspace
rm(list = ls())
gc()

# Increase memory limit (Windows only)
memory.limit(size = 8000)  # 8 GB

# Or run scripts one at a time instead of all at once
```

---

## Validation Checklist

Use this checklist to confirm successful reproduction:

- [ ] All R packages installed without errors
- [ ] All data files present and verified
- [ ] Script 1 runs successfully (data organization)
- [ ] Script 6 runs successfully (growth analysis)
  - [ ] Interaction p-value = 0.039
  - [ ] Size-corrected growth p-value = 0.267
- [ ] Script 7 runs successfully (physiology)
  - [ ] Carbohydrate p-value = 0.007
  - [ ] PC1 p-value = 0.017
- [ ] Script 8 runs successfully (CAFI-coral)
  - [ ] SQRT_CS p-value = 0.014
  - [ ] HELLINGER p-value = 0.008
  - [ ] SQRT p-value = 0.153
- [ ] Script 14 creates statistics tables
- [ ] All expected output files generated
- [ ] Key statistics match expected values
- [ ] All figures generated successfully

---

## Advanced: Session Information

For maximum reproducibility, record your session information:

```r
# After running all scripts
sink(here("output/MRB/session_info.txt"))
sessionInfo()
sink()
```

This creates a record of:
- R version
- Platform/OS
- Package versions
- Locale settings

Include this file when reporting reproducibility issues.

---

## Getting Help

### Issue Resolution Priority

1. **Check this guide** - Most common issues covered in Troubleshooting
2. **Check README.md** - General information and overview
3. **Check script comments** - Each script has detailed inline documentation
4. **Check GitHub Issues** - See if others have encountered similar problems
5. **Contact authors** - adrian.stier@ucsb.edu

### Reporting Issues

When reporting reproducibility issues, include:

1. **Your environment:**
   ```r
   sessionInfo()
   ```

2. **The error message** (full text)

3. **What you tried:**
   - Which script failed?
   - At what line?
   - What have you already attempted?

4. **Your session information file** (`output/MRB/session_info.txt`)

---

## Success!

If all scripts run successfully and key statistics match, you have successfully reproduced the analyses.

Your outputs are now in:
- `output/MRB/figures/` - All figures
- `output/MRB/tables/` - Statistical tables
- `output/MRB/MANUSCRIPT_STATS_TABLE.csv` - Complete results

You can now:
- Review the statistical approaches
- Examine the figures
- Verify the manuscript statistics
- Modify analyses for your own research

---

**Last Updated:** November 15, 2025
**Status:** Tested and verified

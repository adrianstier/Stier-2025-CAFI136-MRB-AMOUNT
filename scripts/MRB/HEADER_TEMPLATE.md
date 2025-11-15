# MRB Script Header Template & Standards

**Version:** 1.0
**Last Updated:** 2025-11-05
**Purpose:** Standardize all R script headers for publication-quality code review

---

## Gold Standard Template

Use this template for **all analysis scripts** (numbered scripts 1-12):

```r
# ==============================================================================
# MRB Analysis Script [N]: [Short Descriptive Title]
# ==============================================================================
# Purpose: [2-3 sentence description of what this script does, its role in the
#          pipeline, and key analytical methods used. Be specific but concise.]
#
# Inputs:
#   - data/MRB Amount/[filename.csv]                # [Description]
#   - data/MRB Amount/[another_file.csv]            # [Description]
#   - output/MRB/objects/[previous_results.rds]     # [If depends on prior script]
#
# Outputs:
#   - output/MRB/figures/[subdir]/[figure_name].png # [Description]
#   - output/MRB/figures/[subdir]/[figure_name].pdf # [Same figure, PDF format]
#   - output/MRB/tables/[table_name].csv            # [Description]
#   - output/MRB/objects/[data_object].rds          # [For downstream scripts]
#
# Depends:
#   R (>= 4.3), tidyverse, [package1], [package2], [package3]
#
# Run after:
#   - 1.libraries.R (always required first)
#   - utils.R (utility functions, always required)
#   - [N-1].[previous_script].R (if sequentially dependent)
#
# Author: [Author Name] or CAFI Team
# Created: YYYY-MM-DD
# Last updated: YYYY-MM-DD
#
# Reproducibility notes:
#   - set.seed([value]) for all stochastic operations
#   - Bootstrap iterations: [N] (for publication)
#   - Permutation tests: [N] iterations
#   - All paths use here::here() for cross-platform portability
#   - [Any other reproducibility-critical information]
# ==============================================================================
```

---

## Utility/Config Script Template

Use this for **utility files** (utils.R, mrb_config.R, mrb_figure_standards.R):

```r
# ==============================================================================
# [Module Name]
# ==============================================================================
# Purpose: [Brief description of module's role]
#          [Additional context if needed]
#
# Author: CAFI Team
# Created: YYYY-MM-DD
# Last updated: YYYY-MM-DD
# License: CC-BY 4.0 (optional, for shared utilities)
# ==============================================================================
# Functions/Constants included:
#   [CATEGORY 1]:
#     - function_name_1()        # Brief description
#     - function_name_2()        # Brief description
#
#   [CATEGORY 2]:
#     - constant_name_1          # Brief description
#     - constant_name_2          # Brief description
# ==============================================================================

#' Function Name
#'
#' [Detailed description of what the function does]
#'
#' @param param1 Description of parameter 1
#' @param param2 Description of parameter 2
#' @return Description of return value
#' @examples
#' function_name(param1 = "value", param2 = 10)
#' # Returns: ...
function_name <- function(param1, param2) {
  # Function body
}
```

---

## Section Header Standards

Use these **consistent section dividers** throughout the script body:

### Primary Section (Major workflow step)
```r
# ==============================================================================
# [SECTION NAME IN CAPS]
# ==============================================================================
```

### Subsection (Within a major section)
```r
# ---- [Subsection description] ------------------------------------------------
```

### Function-based section headers (for user feedback)
```r
print_section("SECTION NAME")      # Prints major section header
print_subsection("Subsection Name") # Prints subsection header
```

---

## Key Principles

### 1. **Complete Metadata**
Every script MUST include:
- ✅ Purpose statement (what and why)
- ✅ Inputs (all data files with descriptions)
- ✅ Outputs (all figures, tables, R objects)
- ✅ Dependencies (R version, packages)
- ✅ Run order (prerequisite scripts)
- ✅ Author and dates
- ✅ Reproducibility notes

### 2. **Consistent Divider Style**
- Use `=` for primary dividers (80 characters)
- Use `-` for subsections (70 characters after "# ----")
- NO mixing of styles within a file

### 3. **Descriptive Output Paths**
List ALL outputs with brief descriptions:
```r
# Outputs:
#   - output/MRB/figures/abundance/obs_vs_exp_abundance.png  # Observed vs expected plot
#   - output/MRB/figures/abundance/top20_species_panel.png   # Top 20 species breakdown
#   - output/MRB/tables/abundance_statistics.csv            # Bootstrap CI results
```

### 4. **Reproducibility First**
Document anything that affects reproducibility:
- Seeds for random number generation
- Bootstrap/permutation iteration counts
- Filtering thresholds
- Statistical significance levels
- Software version requirements

### 5. **Path Portability**
Always use `here::here()` for file paths:
```r
# ✅ GOOD
data <- read_csv(here("data", "MRB Amount", "filename.csv"))

# ❌ BAD
data <- read_csv("../data/MRB Amount/filename.csv")
data <- read_csv("/Users/username/project/data/filename.csv")
```

---

## Common Anti-Patterns to Avoid

### ❌ Don't Do This:
```r
# script.R
# does analysis stuff
# date: sometime in 2025
```

### ❌ Don't Do This:
```r
# ===========
# Title
# ===========
# (inconsistent number of = signs)
```

### ❌ Don't Do This:
```r
# Script does everything from data loading to final figures
# (too vague)
```

### ❌ Don't Do This:
```r
# Outputs: makes figures
# (not specific enough)
```

---

## Script-Specific Guidelines

### Analysis Scripts (1-12)
- **Purpose:** Should explain the scientific question, not just "analyze data"
- **Inputs:** List every CSV, RDS, Excel file read
- **Outputs:** List every PNG, PDF, CSV, RDS file created
- **Dependencies:** Be specific about key packages (e.g., vegan, lme4, not just tidyverse)

### Utility Scripts (utils.R, config files)
- **Function Documentation:** Use roxygen-style comments (`#'`)
- **Examples:** Provide at least one example per exported function
- **Organization:** Group related functions under clear category headers

### Pipeline Scripts (run_*, test_*, update_*)
- **Purpose:** Clearly state whether it runs all/some scripts, tests them, or updates something
- **Outputs:** Specify console output format (e.g., "Prints progress to console with emoji indicators")
- **Error Handling:** Document behavior on script failure

---

## Quality Checklist

Before committing script changes, verify:

- [ ] Header includes all 8 required sections (Purpose, Inputs, Outputs, Depends, Run after, Author, Dates, Repro notes)
- [ ] All input files are listed with relative paths from project root
- [ ] All output files are listed with descriptions
- [ ] Package dependencies are complete and version-specified if critical
- [ ] Reproducibility notes include seed, iteration counts, thresholds
- [ ] Section dividers use consistent `=` (80 chars) for major, `-` for minor
- [ ] No absolute paths (use `here::here()` everywhere)
- [ ] Date format is YYYY-MM-DD
- [ ] Purpose is 2-3 sentences, specific to this script's role

---

## Migration Strategy

### Priority 1: Critical Gaps (IMMEDIATE)
- **Script 6** (6.coral.R): Add complete header with inputs/outputs
- **Script 9** (9.coral-physio.R): ✅ Already updated

### Priority 2: Missing Metadata (HIGH)
Add Inputs/Outputs sections to:
- Script 2 (2.taxonomic-coverage.R)
- Script 5 (5.fishes.R)
- Script 8 (8.null-models.R)

### Priority 3: Standardization (MEDIUM)
Ensure consistent format in:
- Scripts 3, 4d, 7, 11, 12 (already good, just standardize section order)
- Script 1 (1.libraries.R): Add inputs/outputs (none/memory)
- Utils, Config, Standards files: Verify function documentation

### Priority 4: Polish (LOW)
- Add reproducibility notes to all scripts
- Standardize subsection divider style (---- vs ==== mixing)
- Verify all dates are up-to-date

---

## Examples by File Type

### Example: Analysis Script
See **3.abundance.R** or **7.coral-caffi.R** for gold standard examples.

### Example: Utility Script
See **utils.R** for gold standard function documentation.

### Example: Config Script
See **mrb_config.R** for gold standard configuration file structure.

---

## Version History

| Version | Date       | Changes                                      |
|---------|------------|----------------------------------------------|
| 1.0     | 2025-11-05 | Initial template based on codebase audit    |

---

## Contact

For questions about header standards:
- Review this template first
- Check examples in scripts 3, 7, or utils.R
- Discuss proposed changes in team meetings before modifying template

---

**Remember:** Good headers are not just documentation—they're a promise to your future self and collaborators that this code is understandable, reproducible, and maintainable.

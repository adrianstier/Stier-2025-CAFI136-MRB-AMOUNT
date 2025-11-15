# MRB CAFI Analysis Pipeline

This directory contains R scripts for analyzing coral-associated fish and invertebrate (CAFI) communities across experimental coral density treatments at the Moorea Reef Back (MRB) site.

## Overview

The analysis examines how CAFI community composition, abundance, and diversity scale with coral colony density (1, 3, or 6 colonies per treatment), and how these communities affect coral growth and physiology.

## Quick Start

### Run Complete Pipeline

```r
# From project root:
source("scripts/run_all_analyses.R")
```

### Run Individual Scripts

```r
# Must run in order:
source("scripts/MRB/1.libraries.R")        # Load packages
source("scripts/MRB/2.taxonomic-coverage.R") # Taxonomic analysis
source("scripts/MRB/3.abundance.R")        # Abundance scaling
source("scripts/MRB/4.diversity.R")        # Diversity metrics
source("scripts/MRB/5.fishes.R")          # Fish community
source("scripts/MRB/6.coral.R")           # Coral growth
# ... etc
```

## Pipeline Structure

### Core Analysis Scripts

| Script | Description | Outputs |
|--------|-------------|---------|
| **1.libraries.R** | Load all required R packages | (none) |
| **2.taxonomic-coverage.R** | Analyze taxonomic resolution (species vs genus vs family) | `figures/unique_taxa_table.png` |
| **3.abundance.R** | Test abundance scaling with coral density | `figures/abundance/*.png` |
| **4.diversity.R** | Calculate alpha/beta diversity, PERMANOVA | `figures/diversity/*.png` |
| **5.fishes.R** | Fish-specific community analysis | `figures/fishes/*.png` |
| **6.coral.R** | Coral growth from 3D photogrammetry (2019→2021) | `figures/coral/*.png` |
| **7.cafi-coral.R** | CAFI effects on coral growth (mixed models) | `figures/coral-cafi/*.png` |
| **8.null-models.R** | Species co-occurrence null models | `figures/null-models/*.png` |
| **9.coral-physio.R** | Coral physiology × CAFI community | `figures/physio/*.png` |
| **utils.R** | Common utility functions | (sourced by other scripts) |

### Alternative/Experimental Scripts

| Script | Status | Description |
|--------|--------|-------------|
| **3a.abundance.R** | Alternative | Alternative abundance analysis |
| **3b.abundance.R** | Alternative | Another abundance approach |
| **4b.diversity.R** | Alternative | Alternative diversity metrics |
| **4c.diversity.R** | Alternative | Diversity with different methods |
| **4d.diversity.R** | Alternative | Yet another diversity approach |
| **7a.coral-cafi.R** | Alternative | Alternative CAFI-coral analysis |
| **7b.coral-caffi.R** | Alternative | Typo variant (archived?) |
| **12.SLOSS.R** | Specialized | Single Large Or Several Small analysis |

> **Note:** The numbered scripts (e.g., `3.abundance.R`) are the primary/current versions. Scripts with letters (e.g., `3a`, `3b`) are alternatives or experimental variants.

## Data Requirements

### Primary Data Files

All data files should be in `data/MRB Amount/`:

```
data/MRB Amount/
├── 1. mrb_fe_cafi_summer_2021_v4_AP_updated_2024.csv    # Main CAFI data
├── coral_id_position_treatment.csv                       # Treatment assignments
├── coral_growth_surface_area_change.csv                  # Processed growth data
├── MRB_2019_200K_mesh_measure.csv                       # 3D mesh data (2019)
├── MRB_May_2021_200K_mesh_measure.csv                   # 3D mesh data (2021)
├── 1. amount_manual_colony_measurements_dec2019_and_may2021.xlsx  # Manual measurements
└── 1. amount_master_phys_data_v5.csv                    # Physiology data
```

### Metadata

```
data/MRB Amount/
└── README_amount_physio_metadata_v6.xlsx  # Variable definitions
```

## Output Structure

```
output/MRB/
├── figures/
│   ├── abundance/          # Abundance scaling plots
│   ├── diversity/          # Diversity metrics plots
│   ├── fishes/            # Fish community plots
│   ├── coral/             # Coral growth plots
│   ├── coral-cafi/        # CAFI-coral interaction plots
│   ├── physio/            # Physiology plots
│   └── null-models/       # Co-occurrence plots
├── tables/                # Statistical tables (CSV, HTML)
└── objects/               # Cached R objects (RDS)
```

## Key Variables

### Community Data (`MRBcafi_df`)

| Variable | Type | Description |
|----------|------|-------------|
| `coral_id` | factor | Unique coral colony ID (e.g., "FE-POC61") |
| `species` | character | Scientific name |
| `count` | integer | Number of individuals observed |
| `treatment` | factor | Coral density treatment (1, 3, or 6) |
| `site` | factor | Sampling site |
| `row`, `column` | integer | Spatial position on reef |

### Coral Growth Data

| Variable | Type | Description | Units |
|----------|------|-------------|-------|
| `coral_id` | character | Colony identifier | — |
| `delta_volume` | numeric | Change in volume (2021 - 2019) | cm³ |
| `delta_surface_area` | numeric | Change in surface area | cm² |
| `size_corrected_volume_growth` | numeric | Growth / initial surface area | cm³/cm² |
| `treatment` | factor | Coral density treatment | 1, 3, or 6 |
| `reef` | character | Reef location | — |

## Statistical Approaches

### 1. Abundance Scaling

- **Method:** Compare observed vs. expected abundance under proportional scaling
- **Expected:** If linear, 3 corals → 3× abundance, 6 corals → 6× abundance
- **Models:** Bootstrap 95% CIs, t-distribution for small samples
- **Key Result:** Sub-linear scaling suggests saturation or competition

### 2. Diversity Analysis

- **Alpha Diversity:** Species richness, Shannon-Wiener, Simpson
- **Beta Diversity:** NMDS ordination, PERMANOVA
- **Rarefaction:** Account for different sampling intensities

### 3. Coral Growth

- **Data:** 3D photogrammetry (2019 vs. 2021)
- **Metrics:** Volume, surface area, height changes
- **Allometry:** Log-log regressions (initial vs. final)
- **Treatment Effects:** Mixed models with reef random effects

### 4. CAFI-Coral Relationships

- **Response:** Size-corrected volume growth
- **Predictors:** Abundance of key species
- **Models:** `lmer(growth ~ abundance + (1|reef))`
- **Co-occurrence:** Null models (permatfull, oecosimu)

### 5. Physiology Integration

- **PCA:** Coral condition score from protein, carbs, zoox, AFDW
- **RDA:** Constrain physiology by community composition
- **Envfit:** Overlay species vectors on ordination

## Utility Functions

The `utils.R` module provides reusable functions to reduce code duplication:

### Data Loading

```r
# Load CAFI data with caching
cafi_data <- load_cafi_data()

# Load treatment assignments
treatment_data <- load_treatment_data()

# Load coral growth data
growth_data <- load_coral_growth_data()
```

### Plotting

```r
# Use standard theme
ggplot(data, aes(x, y)) +
  geom_point() +
  theme_cafi()

# Publication theme
ggplot(data, aes(x, y)) +
  geom_point() +
  theme_cafi_pub()

# Save in both PNG and PDF
save_both(my_plot, "output/MRB/figures/my_figure")
```

### Community Analysis

```r
# Create community matrix
comm <- create_community_matrix(
  data = cafi_data,
  id_col = "coral_id",
  species_col = "species",
  count_col = "count"
)

# Filter rare species
comm_filtered <- filter_rare_taxa(
  comm$matrix,
  min_total = 20,
  min_sites = 5
)
```

### Statistical Models

```r
# Fit mixed model with reef random effect
results <- fit_reef_lmm(
  response = "growth",
  predictor = "treatment",
  data = my_data
)

# Access results
results$model       # lmer model object
results$anova       # Type III ANOVA
results$tidy        # Tidy coefficients
results$emmeans     # Estimated marginal means
```

## Common Workflows

### Add a New Species-Level Analysis

```r
# 1. Load data
source("scripts/MRB/1.libraries.R")
source("scripts/MRB/utils.R")
cafi_data <- load_cafi_data()

# 2. Subset to your species
my_species_data <- cafi_data %>%
  filter(species == "Species name")

# 3. Join with coral growth
growth_data <- load_coral_growth_data()
analysis_data <- my_species_data %>%
  left_join(growth_data, by = "coral_id")

# 4. Run analysis
model <- fit_reef_lmm(
  response = "size_corrected_volume_growth",
  predictor = "count",
  data = analysis_data
)

# 5. Visualize
p <- ggplot(analysis_data, aes(count, size_corrected_volume_growth)) +
  geom_point() +
  geom_smooth(method = "lm") +
  theme_cafi_pub() +
  labs(title = "My Species Effect on Growth")

save_both(p, "output/MRB/figures/my_analysis")
```

### Add Treatment Comparison

```r
# Load data with treatments
growth_data <- load_coral_growth_data()
treatment_data <- load_treatment_data()

data <- growth_data %>%
  left_join(treatment_data, by = "coral_id")

# Fit model
model <- fit_reef_lmm(
  response = "delta_volume",
  predictor = "treatment",
  data = data
)

# Post-hoc comparisons
emmeans(model$model, pairwise ~ treatment, adjust = "tukey")
```

## Troubleshooting

### "Package not found"

```r
# Install missing packages
install.packages("package_name")

# Or install all at once
source("scripts/MRB/1.libraries.R")  # Will error on missing package
# Install the missing one, then re-run
```

### "Data file not found"

- Check that you're in the project root: `getwd()` should end in `CAFI_2025`
- Verify data files exist: `list.files("data/MRB Amount")`
- Use `here::here()` for all paths

### "Can't find function X"

```r
# Make sure utils are loaded
source("scripts/MRB/utils.R")

# Or for specific functions:
?load_cafi_data      # Help for utils functions
```

### Scripts run slow

```r
# Enable caching for data loading
cafi_data <- load_cafi_data(use_cache = TRUE)  # Default

# Reduce bootstrap iterations (testing only!)
n_boot <- 100  # Instead of 1000

# Parallelize bootstraps (advanced)
library(future)
plan(multisession, workers = 4)
```

## Version Control

These scripts use Git for version control. Commit messages should be descriptive:

```bash
git add scripts/MRB/my_script.R
git commit -m "Add species X analysis to CAFI-coral script"
git push
```

## Citation

If you use these analyses, please cite:

> Stier Lab. (2025). CAFI 2025: Coral-Associated Fauna and Invertebrates Effects on Coral Growth. University of California, Santa Barbara.

## Contact

For questions or issues:
- Open a GitHub issue
- Contact: [email]
- Lab website: [URL]

---

**Last Updated:** 2025-10-24
**Maintained by:** CAFI Analysis Team

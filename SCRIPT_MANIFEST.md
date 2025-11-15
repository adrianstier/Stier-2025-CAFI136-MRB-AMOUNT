# Analysis Scripts Manifest

**Purpose:** Complete description of all analysis scripts, their dependencies, and outputs

---

## Script Execution Order

Scripts should be run in numerical order. Dependencies are listed for each script.

```
1 → 2 → 3 → 4d → 5 → 6 → 7 → 8 → 12 → 14
```

---

## Script Details

### 1. Data Organization
**File:** `scripts/MRB/1.data-organization.R`

**Purpose:** Load and organize all raw data files

**Dependencies:**
- None (first script)

**Inputs:**
- `data/MRB/coral/*.csv` - Coral growth measurements
- `data/MRB/cafi/*.csv` - CAFI community data
- `data/MRB/physiology/*.csv` - Physiological measurements

**Outputs:**
- Organized data objects in R environment
- Console summary of data dimensions

**Key Functions:**
- Data import
- Quality filtering (≥80% tissue alive)
- Data structure verification

**Runtime:** ~30 seconds

---

### 2. Exploratory Figures
**File:** `scripts/MRB/2.exploratory-figures.R`

**Purpose:** Generate exploratory visualizations

**Dependencies:**
- Script 1 (data organization)

**Inputs:**
- Organized data from Script 1

**Outputs:**
- `output/MRB/figures/exploratory/*.png` - Exploratory plots

**Key Functions:**
- Distribution plots
- Relationship visualizations
- Data quality checks

**Runtime:** ~30 seconds

---

### 3. CAFI Community Analysis
**File:** `scripts/MRB/3.cafi-community.R`

**Purpose:** Analyze CAFI abundance and richness by treatment

**Dependencies:**
- Script 1

**Inputs:**
- CAFI community data

**Outputs:**
- `output/MRB/figures/cafi/*.png` - CAFI abundance/richness figures
- Statistical test results (console)

**Key Analyses:**
- Total CAFI abundance vs coral number
- Species richness vs coral number
- Negative binomial GLMs

**Key Results:**
- Total abundance: LR χ² = 105.5, p < 0.0001
- Species richness: LR χ² = 95.2, p < 0.0001

**Runtime:** ~30 seconds

---

### 4d. CAFI Diversity
**File:** `scripts/MRB/4d.cafi-diversity.R`

**Purpose:** Calculate rarefied species richness

**Dependencies:**
- Script 1

**Inputs:**
- CAFI community data

**Outputs:**
- Rarefied richness estimates
- Diversity figures

**Key Analyses:**
- Rarefaction curves
- Standardized richness comparisons

**Runtime:** ~30 seconds

---

### 5. CAFI Composition
**File:** `scripts/MRB/5.cafi-composition.R`

**Purpose:** Analyze community composition differences

**Dependencies:**
- Script 1

**Inputs:**
- CAFI community matrix

**Outputs:**
- `output/MRB/figures/cafi/community_composition*.png` - NMDS plots
- PERMANOVA results

**Key Analyses:**
- NMDS ordination
- PERMANOVA
- Species-level responses

**Key Results:**
- PERMANOVA: F₂,₂₀ = 2.01, R² = 0.17, p = 0.015

**Runtime:** ~30 seconds

---

### 6. Coral Growth Analysis ⭐ KEY SCRIPT
**File:** `scripts/MRB/6.coral-growth.R`

**Purpose:** Allometric growth analysis with unified model approach

**Dependencies:**
- Script 1

**Inputs:**
- Coral volume measurements (initial and final)
- Treatment assignments

**Outputs:**
- `output/MRB/figures/coral/ANCOVA_Init_vs_Final_Volume_by_Treatment.png`
- `output/MRB/figures/coral/ANCOVA_TreatmentSpecific_Slopes.png`
- `output/MRB/figures/coral/SizeCorrected_Volume_Growth_by_Treatment.png`
- Statistical results to console and data objects

**Key Analyses:**

1. **Interaction Model:**
   - Model: `log(V_final) ~ log(V_initial) × treatment + (1|reef)`
   - Tests if allometric slopes differ by treatment
   - Result: χ² = 6.48, df = 2, **p = 0.039**

2. **Treatment-Specific Slopes:**
   - 1 colony: b = 0.781 (SE = 0.161, 95% CI [0.450, 1.112])
   - 3 colonies: b = -0.099 (SE = 0.377, 95% CI [-0.862, 0.665])
   - 6 colonies: b = 1.004 (SE = 0.304, 95% CI [0.385, 1.622])

3. **Post-hoc Comparisons (Tukey):**
   - 1 vs 3: p = 0.094
   - 1 vs 6: p = 0.795
   - 3 vs 6: p = 0.072
   - All NS after adjustment

4. **Model Comparison (LRT):**
   - Interaction vs parallel slopes
   - χ² = 5.231, df = 2, p = 0.073 (marginal)

5. **Unified Model:**
   - Model: `log(V_final) ~ log(V_initial) + treatment + (1|reef)`
   - Unified b = 0.6986
   - Used for all size-corrections

6. **Size-Corrected Growth:**
   - Metric: growth_vol_b = V_final / V_initial^0.6986
   - Treatment effect: χ² = 2.64, df = 2, **p = 0.267 (NS)**

7. **Alternative Metrics:**
   - SA-scaled growth: χ² = 3.24, p = 0.198 (NS)
   - ΔV ~ SA (treatment): χ² = 2.46, p = 0.292 (NS)
   - ΔV ~ SA (interaction): χ² = 1.92, p = 0.383 (NS)

**Key R Functions:**
- `lmer()` - Linear mixed-effects models
- `anova()` - Type III Wald χ² tests
- `emtrends()` - Extract and compare slopes
- `emmeans()` - Post-hoc comparisons

**Runtime:** ~1 minute

**Important Notes:**
- This script implements Craig Osenberg's unified allometric model approach
- Interaction model results reported in Methods (Analytic approach)
- Main result (p = 0.267) reported in Results

---

### 7. Coral Physiology
**File:** `scripts/MRB/7.coral-physiology.R`

**Purpose:** Analyze physiological metrics and create integrated performance PC1

**Dependencies:**
- Script 1
- Script 6 (for size-corrected growth metric)

**Inputs:**
- Carbohydrate content (mg/cm²)
- Protein content (mg/cm²)
- Zooxanthellae density (cells/cm²)
- Ash-free dry mass (mg/cm²)
- Size-corrected growth (from Script 6)

**Outputs:**
- `output/MRB/figures/physiology/*.png` - Physiology boxplots and PC plots
- Statistical results to console

**Key Analyses:**

1. **Individual Metrics:**
   - Carbohydrate: χ² = 10.0, df = 2, **p = 0.007**
     - BH-adjusted: **p = 0.039**
   - Protein: χ² = 3.04, df = 2, p = 0.219 (NS)
   - Zooxanthellae: χ² = 1.70, df = 2, p = 0.428 (NS)
   - AFDW: χ² = 4.40, df = 2, p = 0.111 (NS)

2. **Integrated Performance PC1:**
   - Combines: carbohydrate, protein, zooxanthellae, AFDW, growth_vol_b
   - PC1 explains ~52.5% variance
   - Treatment effect: χ² = 8.11, df = 2, **p = 0.017**

3. **Multiple Testing:**
   - Benjamini-Hochberg correction applied
   - Only carbohydrate remains significant after correction

**Key R Functions:**
- `lmer()` - Linear mixed models
- `prcomp()` - Principal components analysis
- `p.adjust()` - Multiple testing correction

**Runtime:** ~30 seconds

---

### 8. CAFI-Coral Community Relationships
**File:** `scripts/MRB/8.cafi-coral-community.R`

**Purpose:** Test whether CAFI community composition predicts coral performance

**Dependencies:**
- Script 1
- Script 7 (for coral performance PC1)

**Inputs:**
- CAFI community matrix
- Coral performance PC1 (from Script 7)

**Outputs:**
- `output/MRB/figures/cafi-coral/*.png` - Relationship plots
- Statistical results to console

**Key Analyses:**

1. **CAFI Community PCA:**
   - Applied to square-root transformed abundances
   - Multiple transformation approaches for robustness

2. **CAFI → Coral Performance:**
   - Model: `PC1_coral ~ PC1_CAFI + (1|reef)`
   - Multiple transformations tested:
     - SQRT_CS (centered-scaled square-root): **p = 0.00085**
     - HELLINGER: **p = 0.014**
     - SQRT (simple square-root): **p = 0.042**
   - All transformations show significant relationship

**Key Results:**
- Robust, highly significant relationship across transformations
- CAFI community structure predicts coral condition

**Key R Functions:**
- `prcomp()` - PCA on CAFI communities
- `lmer()` - Mixed models
- `decostand()` - Data transformations (vegan package)

**Runtime:** ~30 seconds

---

### 12. Publication Figures
**File:** `scripts/MRB/12.publication-figures.R`

**Purpose:** Generate all publication-quality figures

**Dependencies:**
- Scripts 1, 3, 5, 6, 7, 8

**Inputs:**
- All analyzed data

**Outputs:**
- `output/MRB/figures/publication-figures/*.png` - Final publication figures
- High-resolution (300 DPI)
- Consistent styling and themes

**Key Figures:**
- CAFI abundance and richness
- Community composition (NMDS)
- Coral growth (3-panel: slopes, interaction, size-corrected)
- Coral physiology
- CAFI-coral relationships

**Runtime:** ~1 minute

---

### 14. Compile Manuscript Statistics
**File:** `scripts/MRB/14.compile-manuscript-statistics.R`

**Purpose:** Compile all statistical tests into manuscript-ready tables

**Dependencies:**
- Scripts 6, 7, 8 (requires statistical comparison table)

**Inputs:**
- `output/MRB/MANUSCRIPT_STATS_TABLE.csv` - Statistical comparison table

**Outputs:**
- `output/MRB/tables/MANUSCRIPT_STATISTICAL_TESTS.csv` - Complete stats (CSV)
- `output/MRB/tables/MANUSCRIPT_STATISTICAL_TESTS.html` - Formatted table (HTML)
- Console summary of key findings

**Key Functions:**
- Reads statistical comparison table
- Formats for manuscript
- Generates human-readable HTML table
- Provides summary statistics

**Output Columns:**
- test_id
- section (Coral Growth, Physiology, CAFI-Coral)
- Analysis description
- Test statistic
- df
- p-value (formatted)
- Significance markers
- Effect size
- Impact (PRIMARY, NEW, UNCHANGED)
- Manuscript location

**Runtime:** ~15 seconds

---

## Quick Reference: Which Script Does What?

| Question | Script |
|----------|--------|
| How does CAFI abundance change with coral number? | 3 |
| How does CAFI species richness change with coral number? | 3, 4d |
| Does CAFI composition differ by treatment? | 5 |
| Does coral growth differ by treatment? | 6 |
| Do allometric slopes differ by treatment? | 6 |
| What is the unified allometric exponent? | 6 |
| Do physiological metrics differ by treatment? | 7 |
| What is integrated coral performance (PC1)? | 7 |
| Does CAFI community predict coral performance? | 8 |
| Generate publication figures | 12 |
| Compile all statistics for manuscript | 14 |

---

## Output File Guide

### Figures

**Coral Growth:**
- `output/MRB/figures/coral/ANCOVA_Init_vs_Final_Volume_by_Treatment.png`
  - Panel A for Figure X (parallel slopes)

- `output/MRB/figures/coral/ANCOVA_TreatmentSpecific_Slopes.png`
  - Panel B for Figure X (interaction model)

- `output/MRB/figures/coral/SizeCorrected_Volume_Growth_by_Treatment.png`
  - Panel C for Figure X (size-corrected growth)

**Physiology:**
- `output/MRB/figures/physiology/*.png`
  - Carbohydrate, protein, zooxanthellae, AFDW by treatment
  - PC1 (integrated performance) by treatment

**CAFI-Coral:**
- `output/MRB/figures/cafi-coral/*.png`
  - CAFI community PC1 vs coral performance PC1
  - Multiple transformation approaches

### Tables

**Statistical Results:**
- `output/MRB/MANUSCRIPT_STATS_TABLE.csv`
  - Complete comparison table (old vs new results)

- `output/MRB/tables/MANUSCRIPT_STATISTICAL_TESTS.csv`
  - Manuscript-ready statistics table

- `output/MRB/tables/MANUSCRIPT_STATISTICAL_TESTS.html`
  - Formatted HTML table for review

### Documentation

**Key Reference Documents:**
- `output/MRB/KEY_STATISTICS_FOR_MANUSCRIPT.md`
  - Quick reference with copy-paste ready text
  - Figure legends
  - Methods text
  - Results text

- `output/MRB/MANUSCRIPT_UPDATE_SUMMARY.md`
  - Summary of analysis approach
  - Key findings
  - Manuscript section updates

---

**Last Updated:** November 15, 2025

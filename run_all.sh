#!/bin/bash
# ==============================================================================
# Master Script: Run Complete CAFI Analysis Pipeline
# ==============================================================================
#
# Purpose: Execute all core analysis scripts in proper order
# Runtime: ~5-10 minutes on modern laptop
# Requirements: R >= 4.3.0 with required packages (see scripts/MRB/1.libraries.R)
#
# Usage:
#   chmod +x run_all.sh
#   ./run_all.sh
#
# For quick analysis (core scripts only):
#   ./run_all.sh --quick
#
# ==============================================================================

set -e  # Exit immediately if any command fails
set -u  # Exit if undefined variable is used

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Navigate to repository root
cd "$(dirname "$0")"

# Function to print colored status messages
print_status() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to run R script with timing and error handling
run_r_script() {
    local script=$1
    local description=$2

    print_status "Running: $description"
    echo "  Script: $script"

    START=$(date +%s)

    if Rscript "$script"; then
        END=$(date +%s)
        DIFF=$((END - START))
        print_success "Completed in ${DIFF}s: $description"
    else
        print_error "FAILED: $description"
        print_error "Check output above for error details"
        exit 1
    fi

    echo ""
}

# Parse command line arguments
QUICK_MODE=false
if [ $# -gt 0 ]; then
    if [ "$1" = "--quick" ]; then
        QUICK_MODE=true
        print_warning "Running in QUICK mode (core scripts only)"
        echo ""
    fi
fi

# ==============================================================================
# Main Analysis Pipeline
# ==============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  CAFI Analysis Pipeline - Stier et al. 2026                    ║"
echo "║  Version DOI: 10.5281/zenodo.21727277                          ║"
echo "║  All-version DOI: 10.5281/zenodo.18239646                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

TOTAL_START=$(date +%s)

# Step 1: Load Libraries and Dependencies
print_status "Step 1/5: Loading R packages and dependencies"
run_r_script "scripts/MRB/1.libraries.R" "Package loading and verification"

if [ "$QUICK_MODE" = false ]; then
    # Step 2: CAFI Community Analyses (Optional for quick mode)
    print_status "Step 2/5: CAFI community analyses"
    run_r_script "scripts/MRB/3.abundance.R" "CAFI abundance analysis"
    run_r_script "scripts/MRB/4d.diversity.R" "CAFI diversity metrics"
    run_r_script "scripts/MRB/5.fishes.R" "Fish community analysis"
    # NOTE: 12.nmds_permanova_cafi.R is intentionally NOT run here. It reads
    # physio_metrics_plus_growth_filtered.csv, which is written by
    # 7.coral-physiology.R (Step 4). That output is git-ignored, so on a fresh
    # clone it does not exist yet -- running 12 before 7 fails. 12 now runs
    # after Step 4 (below). Reorder only; no statistical result changes.
else
    print_warning "Skipping CAFI community analyses (quick mode)"
    echo ""
fi

# Step 3: Coral Growth Analysis (REQUIRED)
print_status "Step 3/5: Coral growth analysis"
run_r_script "scripts/MRB/6.coral-growth.R" "Allometric growth models"

# Step 4: Coral Physiology and Performance (REQUIRED)
print_status "Step 4/5: Coral physiology and performance"
run_r_script "scripts/MRB/7.coral-physiology.R" "Physiological metrics and integrated performance"

# Community composition (NMDS & PERMANOVA) -- must run AFTER 7.coral-physiology.R
# because it depends on physio_metrics_plus_growth_filtered.csv (see note above).
if [ "$QUICK_MODE" = false ]; then
    print_status "Community composition (NMDS & PERMANOVA)"
    run_r_script "scripts/MRB/12.nmds_permanova_cafi.R" "Community composition (NMDS & PERMANOVA)"
fi

# Step 5: CAFI-Coral Relationships (REQUIRED)
print_status "Step 5/5: CAFI-coral feedbacks"
run_r_script "scripts/MRB/8.coral-caffi.R" "Community-performance relationships"

# Compile Final Statistics
print_status "Compiling manuscript statistics"
run_r_script "scripts/MRB/14.compile-manuscript-statistics.R" "Statistical summaries"

# Pre-submission QA checks
print_status "Running pre-submission QA checks"
run_r_script "scripts/MRB/15.pre_submission_checks.R" "Pre-submission QA checks"

# ==============================================================================
# Summary
# ==============================================================================

TOTAL_END=$(date +%s)
TOTAL_DIFF=$((TOTAL_END - TOTAL_START))
MINUTES=$((TOTAL_DIFF / 60))
SECONDS=$((TOTAL_DIFF % 60))

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Analysis Complete!                                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
print_success "Total runtime: ${MINUTES}m ${SECONDS}s"
echo ""

# Verify key outputs exist
print_status "Verifying outputs..."

OUTPUTS=(
    "output/MRB/tables/MANUSCRIPT_STATISTICAL_TESTS.csv"
    "output/MRB/tables/pre_submission_qa_checks.csv"
    "output/MRB/tables/composition_robustness_index.csv"
    "output/MRB/figures/coral/SizeCorrected_Volume_Growth_by_Treatment.png"
    "output/MRB/figures/coral/physio/physio_by_treatment.png"
    "output/MRB/figures/cafi-coral/PCA_LOADINGS_RAW_2panel_clean.png"
)

if [ "$QUICK_MODE" = false ]; then
    OUTPUTS+=(
        "output/MRB/figures/diversity/16_horizontal_2panel_nmds_density_plus_top15_density.png"
    )
fi

ALL_PRESENT=true
for file in "${OUTPUTS[@]}"; do
    if [ -f "$file" ]; then
        print_success "Found: $file"
    else
        print_warning "Missing: $file (may be normal if script was modified)"
        ALL_PRESENT=false
    fi
done

echo ""

if [ "$ALL_PRESENT" = true ]; then
    print_success "All expected outputs present"
else
    print_warning "Some outputs missing - check individual script logs"
fi

echo ""
echo "Next steps:"
echo "  1. Review figures in: output/MRB/figures/"
echo "  2. Check statistics in: output/MRB/tables/MANUSCRIPT_STATISTICAL_TESTS.csv"
echo "  3. Check pre-submission QA in: output/MRB/tables/pre_submission_qa_summary.md"
echo "  4. Verify session info: output/MRB/objects/sessionInfo_*.txt"
echo ""
print_status "For full documentation, see: docs/REPRODUCIBILITY_GUIDE.md"
echo ""

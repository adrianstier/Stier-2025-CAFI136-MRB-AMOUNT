# MRB Figure Standards Update Report
## Date: 2025-11-04

## Summary
All MRB analysis scripts have been updated to use consistent publication-quality figure standards.

## Changes Applied:
- **Colors**: Updated to colorblind-friendly palette
  - Blue: #0072B2
  - Orange: #D55E00 (replacing red/tomato)
  - Green: #009E73
- **Themes**: All figures now use `theme_publication()`
- **Font Sizes**: Standardized using FONT_SIZE constants
- **Line Widths**: Increased for better visibility
- **Point Sizes**: Increased from 2-3 to 3.5-4
- **DPI**: All figures saved at 600 DPI
- **Dimensions**: Using standardized PUBLICATION_WIDTH/HEIGHT constants

## Scripts Updated:
- [x] 3.abundance.R
- [x] 4.biodiversity.R
- [x] 6.community.R
- [x] 7.temporal.R
- [x] 9.indicator.R
- [x] 11.rarefaction.R
- [x] 12.synthesis.R

## Previously Updated:
- [x] 2.taxonomic-coverage.R
- [x] 5.fishes.R
- [x] 8.null-models.R

## Next Steps:
1. Run each script to generate updated figures
2. Review all figures for consistency
3. Make any final manual adjustments as needed

## Notes:
- All figures now output in both PNG and PDF formats
- Figures are saved to `output/MRB/figures/` subdirectories
- Color scheme is optimized for colorblind accessibility

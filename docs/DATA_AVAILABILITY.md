# Data Availability Statement

## Overview

All data and analysis code used to generate the manuscript results and figures are publicly available.

## Data Repository

**Primary Repository:** GitHub
**URL:** https://github.com/adrianstier/coral-cafi-density-experiment
**Current archived version DOI:** 10.5281/zenodo.21727277
**All-version concept DOI:** 10.5281/zenodo.18239646

## Archived Version

A permanent archived version has been deposited at Zenodo:
- **Current version:** v1.0.3 final resubmission snapshot
- **Version-specific DOI:** [10.5281/zenodo.21727277](https://doi.org/10.5281/zenodo.21727277)
- **All-version concept DOI:** [10.5281/zenodo.18239646](https://doi.org/10.5281/zenodo.18239646)
- **Archive URL:** https://zenodo.org/records/21727277

## Data Description

| Dataset | Description | Format | Size |
|---------|-------------|--------|------|
| CAFI community data | Fish and invertebrate observations | CSV | ~1 MB |
| Coral physiology | Tissue composition measurements | CSV | ~50 KB |
| 3D photogrammetry | Coral size and growth metrics | CSV | ~100 KB |
| Treatment assignments | Experimental design | CSV | ~5 KB |

## Access

- **License:** CC-BY 4.0 (Creative Commons Attribution)
- **Access:** Unrestricted public access
- **Format:** Plain-text CSV files (no proprietary formats)

## How to Access

1. **Clone the repository:**
   ```bash
   git clone https://github.com/adrianstier/coral-cafi-density-experiment.git
   ```

2. **Download as ZIP:**
   - Visit the repository URL: https://github.com/adrianstier/coral-cafi-density-experiment
   - Click "Code" → "Download ZIP"

3. **Archived version (recommended for reproducibility):**
   - Visit: https://doi.org/10.5281/zenodo.21727277
   - Download the v1.0.3 final resubmission snapshot

## Code Availability

All analysis code used to generate the manuscript results and figures is included in the repository:

| Directory | Contents |
|-----------|----------|
| `scripts/MRB/` | R analysis scripts and the pre-submission QA ledger |
| `scripts/MRB/utils.R` | Utility functions |
| `scripts/MRB/mrb_figure_standards.R` | Figure formatting |

## Reproducibility

To reproduce all analyses:

1. Install R (≥4.3.0) and required packages (see `scripts/MRB/1.libraries.R`)
2. Run the full pipeline with `./run_all.sh`
3. See `REPRODUCIBILITY_GUIDE.md` for detailed instructions

## Citation

If you use this data or code, please cite:

```
Stier, A.C., Primo, A., Curtis, J.S., & Osenberg, C.W. (2026). Habitat amount
reshapes coral-associated communities and host condition. Ecology Letters.
DOI: [to be added]
```

Analysis archive:

```
Stier, A.C. (2026). adrianstier/coral-cafi-density-experiment: v1.0.3 -
Final Resubmission Snapshot [Software]. Zenodo.
https://doi.org/10.5281/zenodo.21727277
```

## Contact

For questions about data access:
- **Email:** astier@ucsb.edu
- **Issues:** https://github.com/adrianstier/coral-cafi-density-experiment/issues

## Ethical Statement

- Field work was conducted with appropriate permits from the French Polynesian government
- No endangered species were collected
- All coral manipulations followed established ethical guidelines for reef research

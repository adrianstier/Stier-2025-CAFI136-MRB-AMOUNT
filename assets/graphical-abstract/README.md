# Graphical abstract

Graphical abstract for *Habitat amount reshapes coral-associated communities and
host condition* (Stier, Primo, Curtis & Osenberg), submitted to *Ecology Letters*.

## Files

| File | Description |
|---|---|
| `CAFI136_graphical_abstract.pdf` | Submission file. Vector, no embedded rasters, 50 x 60 mm. |
| `CAFI136_graphical_abstract.png` | 600 dpi raster preview. |
| `build_graphical_abstract.py` | Builds the figure from `art/`. Writes the SVG, PDF and PNG. |
| `find_pockets.py` | Derives `pockets.npy` from the coral colony artwork. |
| `pockets.npy` | Coordinates of the interstitial gaps between coral branches. |
| `art/` | Colony and species artwork used by the build. |

## Rebuilding

Requires Python 3 with `numpy` and `Pillow`, and `rsvg-convert` (librsvg) on the path.

```sh
python3 build_graphical_abstract.py     # -> SVG, PDF, PNG
python3 find_pockets.py                 # only if the colony artwork changes
```

The PDF is emitted at exactly 141.73 x 170.08 pt (50 x 60 mm), the maximum size
*Ecology Letters* allows for a graphical abstract, and contains no raster images.

## What the figure shows

Adding coral does not crowd each colony. Per-colony occupant totals are flat
across treatments (97, 85 and 84 animals per colony on 1-, 3- and 6-coral reefs;
chi-square = 0.77, df = 2, p = 0.680), consistent with the Field of Dreams
expectation rather than Propagule Redirection. What changes is *which* taxa are
present (PERMANOVA F(2,20) = 2.01, R-squared = 0.17, p = 0.015) and host condition
(PC1Coral chi-square = 8.11, p = 0.017; carbohydrate chi-square = 10.05, p = 0.007).

Two deliberate choices in the artwork:

- **Both colonies are drawn the same size.** Size-corrected growth showed no
  treatment effect (chi-square = 2.61, p = 0.271), so a size difference would
  assert a result the data do not support. Condition is conveyed by tissue colour.
- **Crabs and snails appear on both sides.** No taxon is exclusive to isolated
  colonies, so the figure shows a shift in the mix rather than a clean split.

Animal sizes are approximately proportional to measured medians, square-root
compressed so that the smallest taxon remains legible at print size. The coral is
not to scale.

## Artwork provenance

All artwork is redrawn or traced from reference illustrations. Licences below are
recorded per source; entries marked *unverified* still need provenance confirmed
before publication.

| Artwork | Source | Licence |
|---|---|---|
| `dascyllus_aruanus` | IAN/UMCES Symbol Library | CC BY-SA 4.0 |
| `diala_albugo` | H. Zell | CC BY-SA 3.0 |
| `periclimenes_watamuae` | Moorea Biocode | CC BY-NC-SA 3.0 |
| `pascula_muricata` | K. Stender | All rights reserved - permission required |
| remaining species and colony art | see `art/` | unverified |

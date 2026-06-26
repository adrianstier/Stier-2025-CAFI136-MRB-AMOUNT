# ==============================================================================
# File: fig_concept_hypotheses.R
# Purpose: Conceptual Introduction figure contrasting the two competing
#          hypotheses for how coral-associated fishes & invertebrates (CAFI)
#          respond to the AMOUNT of coral habitat, plus the feedback to coral
#          condition. Rendered with PhyloPic organism silhouettes over a
#          schematic reefscape.
#
#   (A) Total occupants vs. amount of coral habitat:
#         Field of Dreams        -> increases proportionally (linear)
#         Propagule Redirection  -> fixed regional supply, ~constant total
#   (B) Occupants PER COLONY vs. amount of coral habitat:
#         Field of Dreams        -> constant per-colony density (flat)
#         Propagule Redirection  -> per-colony density declines (supply diluted)
#   (C) Feedback: more coral habitat shifts the CAFI community and feeds back
#         to LOWER per-colony coral condition (the paper's result).
#
# Outputs:
#   manuscript/Figure-revisions/FigureX_concept_hypotheses.{pdf,png}      (~170 mm)
#   manuscript/Figure-revisions/FigureX_concept_graphical_abstract.{pdf,tif} (50x60 mm)
#   manuscript/Figure-revisions/FigureX_concept_legend.md                 (caption + credits)
#
# Silhouettes: PhyloPic (rphylopic). Cached as committed PNGs under
#   assets/silhouettes/ so the script runs offline & reproducibly; only
#   re-downloaded if a cached file is missing AND network is available.
#   See assets/silhouettes/ATTRIBUTION.txt for artists & licenses.
#
# Packages: ggplot2, patchwork, tibble, dplyr, grid, png, grDevices.
#   rphylopic is used ONLY to (re)build the silhouette cache when absent.
# ==============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
  library(tibble)
  library(dplyr)
  library(grid)
  library(png)
})

# ---- palette ----------------------------------------------------------------
# Two end-member hypotheses (Okabe-Ito):
col_fod <- "#0072B2"  # Field of Dreams        (blue)
col_pr  <- "#D55E00"  # Propagule Redirection  (vermillion)
# Treatment colours used throughout the paper (coral number 1 / 3 / 6):
col_t1  <- "#E69F00"  # 1 colony  (gold)
col_t3  <- "#56B4E9"  # 3 colonies (sky blue)
col_t6  <- "#009E73"  # 6 colonies (green)
# Reef / occupant accents:
col_sand   <- "#F4ECD9"  # seafloor band
col_sand2  <- "#E9DCBE"  # seafloor edge
col_fish   <- "#0072B2"  # fishes
col_crus   <- "#D55E00"  # shrimps & crabs
col_snail  <- "#7A5C99"  # snails (corallivores)
col_ill    <- "#9AA7B0"  # "lower condition" / bleached coral grey

# ---- silhouette cache (PhyloPic) --------------------------------------------
SIL_DIR <- "assets/silhouettes"
SIL_UUID <- c(
  coral  = "19cbe092-a0f1-4107-b6f3-2dffeeda2668",  # Pocillopora (branching colony)
  fish   = "0ac52ecf-5bd5-4bbf-9cf2-35531546d04a",  # Pomacentridae (damselfish, e.g. Dascyllus)
  crab   = "fbb93c22-618f-4901-aade-2d07a9797e02",  # Brachyura (coral-guard crab)
  shrimp = "0ea8e976-df74-4306-8d3d-a81093a287b3",  # Caridea (shrimp)
  snail  = "f2c24e9a-382c-4f73-8692-b7251e630d9d"   # Muricidae (corallivorous snail)
)

# Load a silhouette as an RGBA array [nrow x ncol x 4]; rebuild cache if missing.
load_sil <- function(name) {
  f <- file.path(SIL_DIR, paste0(name, ".png"))
  if (!file.exists(f)) {
    if (!requireNamespace("rphylopic", quietly = TRUE))
      stop("Missing silhouette '", f, "' and rphylopic is not installed. ",
           "Install rphylopic (needs internet) to rebuild assets/silhouettes/.")
    message("Cache miss for '", name, "': downloading from PhyloPic ...")
    dir.create(SIL_DIR, recursive = TRUE, showWarnings = FALSE)
    arr <- unclass(rphylopic::get_phylopic(uuid = SIL_UUID[[name]],
                                           height = 700, format = "raster"))
    png::writePNG(array(as.numeric(arr), dim = dim(arr)), f)
  }
  png::readPNG(f)
}
SIL <- lapply(names(SIL_UUID), load_sil)
names(SIL) <- names(SIL_UUID)

# Recolour a black+alpha silhouette to `hex` (alpha preserved), optional flip.
recolor_sil <- function(arr, hex, alpha = 1, flip = FALSE) {
  rgb <- grDevices::col2rgb(hex) / 255
  out <- arr
  out[, , 1] <- rgb[1]; out[, , 2] <- rgb[2]; out[, , 3] <- rgb[3]
  out[, , 4] <- arr[, , 4] * alpha
  if (flip) out <- out[, rev(seq_len(dim(out)[2])), , drop = FALSE]
  out
}

# annotation_custom grob that draws a silhouette CENTERED at (x, y) at an
# absolute size (height h_mm) so its aspect ratio is preserved in any panel.
sil_layer <- function(name, x, y, h_mm, hex = "#000000",
                      alpha = 1, flip = FALSE) {
  arr <- recolor_sil(SIL[[name]], hex, alpha = alpha, flip = flip)
  asp <- dim(arr)[1] / dim(arr)[2]                  # height / width
  g <- grid::rasterGrob(arr,
                        width  = grid::unit(h_mm / asp, "mm"),
                        height = grid::unit(h_mm, "mm"),
                        interpolate = TRUE)
  annotation_custom(g, xmin = x, xmax = x, ymin = y, ymax = y)
}

# ---- conceptual curves (x = amount of coral habitat) ------------------------
x  <- seq(1, 6, length.out = 200)
df_total <- bind_rows(
  tibble(x = x, y = 0.85 * x, hyp = "Field of Dreams"),       # linear, proportional
  tibble(x = x, y = 1.4,      hyp = "Propagule redirection")  # constant regional supply
)
df_percol <- bind_rows(
  tibble(x = x, y = 1.0,      hyp = "Field of Dreams"),       # constant per colony
  tibble(x = x, y = 1.0 / x,  hyp = "Propagule redirection")  # diluted 1/n
)

arrow_x <- arrow(length = unit(2.0, "mm"), type = "closed")

# ---- shared schematic theme (no numeric ticks) ------------------------------
theme_concept <- function(base = 11) {
  theme_classic(base_size = base) +
    theme(
      axis.text       = element_blank(),
      axis.ticks      = element_blank(),
      axis.line       = element_line(colour = "grey35", linewidth = 0.5),
      axis.title.x    = element_text(face = "plain", colour = "grey20",
                                     margin = margin(t = 3)),
      axis.title.y    = element_text(face = "plain", colour = "grey20",
                                     margin = margin(r = 3)),
      plot.title      = element_text(face = "bold", size = base, hjust = 0,
                                     margin = margin(b = 2)),
      plot.margin     = margin(7, 12, 5, 8),
      panel.grid      = element_blank(),
      legend.position = "none"
    )
}

# Seafloor band shared by panels A & B (corals sit here; curves rise above 0).
seafloor <- function(xlo, xhi, floor_y) {
  list(
    annotate("rect", xmin = xlo, xmax = xhi, ymin = floor_y, ymax = 0,
             fill = col_sand, colour = NA),
    annotate("segment", x = xlo, xend = xhi, y = 0, yend = 0,
             colour = col_sand2, linewidth = 0.9)
  )
}

# A small "habitat-amount" coral ramp on the seafloor: 1 -> 3 -> 6 colonies.
coral_ramp <- function(yb, h1) {
  list(
    # 1 colony (gold)
    sil_layer("coral", 1.30, yb, h1 * 0.92, col_t1),
    # 3 colonies (sky blue)
    sil_layer("coral", 3.05, yb,            h1 * 0.80, col_t3),
    sil_layer("coral", 3.50, yb - h1*0.012, h1 * 0.92, col_t3),
    sil_layer("coral", 3.95, yb,            h1 * 0.80, col_t3),
    # 6 colonies (green)
    sil_layer("coral", 4.85, yb,            h1 * 0.74, col_t6),
    sil_layer("coral", 5.25, yb,            h1 * 0.88, col_t6),
    sil_layer("coral", 5.65, yb,            h1 * 0.74, col_t6),
    sil_layer("coral", 5.05, yb - h1*0.016, h1 * 0.80, col_t6),
    sil_layer("coral", 5.45, yb - h1*0.016, h1 * 0.80, col_t6),
    sil_layer("coral", 5.85, yb,            h1 * 0.66, col_t6)
  )
}

# ---- Panel A: total occupants ----------------------------------------------
flrA <- -1.55
pA <- ggplot(df_total, aes(x, y, colour = hyp)) +
  seafloor(0.55, 6.7, flrA) +
  coral_ramp(yb = flrA/2 + 0.05, h1 = 7.2) +
  geom_line(linewidth = 1.25, lineend = "round") +
  # occupants riding each curve (fishes = "occupants")
  sil_layer("fish", 5.55, 5.05, 6.4, col_fish, flip = TRUE) +
  sil_layer("fish", 4.75, 4.35, 5.2, col_fish, flip = TRUE) +
  sil_layer("fish", 5.55, 1.62, 5.6, col_pr,   flip = TRUE) +
  annotate("text", x = 2.0, y = 3.05, label = "Field of\nDreams",
           colour = col_fod, fontface = "bold", hjust = 0.5,
           size = 3.3, lineheight = 0.9) +
  annotate("text", x = 2.85, y = 0.78, label = "Propagule\nredirection",
           colour = col_pr, fontface = "bold", hjust = 0.5,
           size = 3.3, lineheight = 0.9) +
  scale_colour_manual(values = c("Field of Dreams" = col_fod,
                                 "Propagule redirection" = col_pr)) +
  scale_x_continuous(limits = c(0.55, 6.7), expand = c(0, 0)) +
  scale_y_continuous(limits = c(flrA, 5.9), expand = c(0, 0)) +
  labs(title = "Total occupants",
       x = "Amount of coral habitat →",
       y = "Total occupants →") +
  theme_concept() +
  coord_cartesian(clip = "off")

# ---- Panel B: occupants per colony -----------------------------------------
flrB <- -0.62
pB <- ggplot(df_percol, aes(x, y, colour = hyp)) +
  seafloor(0.55, 6.7, flrB) +
  coral_ramp(yb = flrB/2 + 0.02, h1 = 3.0) +
  geom_line(linewidth = 1.25, lineend = "round") +
  # per-colony occupants: constant under FoD, diluted under PR
  sil_layer("fish", 2.0, 1.13, 4.6, col_fod, flip = TRUE) +
  sil_layer("fish", 5.2, 1.13, 4.6, col_fod, flip = TRUE) +
  sil_layer("fish", 5.25, 0.30, 4.2, col_pr, flip = TRUE) +
  annotate("text", x = 3.55, y = 1.18, label = "Field of Dreams",
           colour = col_fod, fontface = "bold", hjust = 0.5, size = 3.3) +
  annotate("text", x = 3.75, y = 0.60, label = "Propagule\nredirection",
           colour = col_pr, fontface = "bold", hjust = 0.5,
           size = 3.3, lineheight = 0.9) +
  scale_colour_manual(values = c("Field of Dreams" = col_fod,
                                 "Propagule redirection" = col_pr)) +
  scale_x_continuous(limits = c(0.55, 6.7), expand = c(0, 0)) +
  scale_y_continuous(limits = c(flrB, 1.32), expand = c(0, 0)) +
  labs(title = "Occupants per colony",
       x = "Amount of coral habitat →",
       y = "Occupants per colony →") +
  theme_concept() +
  coord_cartesian(clip = "off")

# ---- Panel C: feedback to the foundation species ---------------------------
# Three stages on a shared seafloor, linked by arrows, with a feedback loop.
flrC <- 0
pC <- ggplot() +
  # seafloor
  annotate("rect", xmin = 0, xmax = 30, ymin = -1.2, ymax = 0,
           fill = col_sand, colour = NA) +
  annotate("segment", x = 0, xend = 30, y = 0, yend = 0,
           colour = col_sand2, linewidth = 1) +

  # ---- Stage 1: MORE CORAL HABITAT (rich, dense community) ----
  sil_layer("coral", 3.1, 0.95, 9.5, col_t1) +
  sil_layer("coral", 4.6, 0.85, 9.5, col_t3) +
  sil_layer("coral", 6.1, 0.95, 9.5, col_t6) +
  sil_layer("coral", 3.9, 1.55, 7.6, col_t6) +
  sil_layer("coral", 5.4, 1.55, 7.6, col_t1) +
  sil_layer("fish",  3.0, 3.0, 5.4, col_fish, flip = TRUE) +
  sil_layer("fish",  5.6, 3.1, 5.4, col_fish) +
  sil_layer("fish",  4.6, 3.65, 4.6, col_fish, flip = TRUE) +
  sil_layer("shrimp", 2.5, 2.05, 4.4, col_crus) +
  sil_layer("crab",   6.3, 1.95, 4.6, col_crus) +
  sil_layer("snail",  4.4, 0.62, 3.0, col_snail) +
  annotate("text", x = 4.6, y = -0.55, label = "More coral habitat",
           fontface = "bold", size = 3.3, colour = "grey15") +

  # arrow 1 -> 2
  annotate("segment", x = 8.7, xend = 11.0, y = 1.4, yend = 1.4,
           arrow = arrow_x, linewidth = 0.8, colour = "grey25") +

  # ---- Stage 2: SHIFTED CAFI COMMUNITY (more corallivores) ----
  sil_layer("coral", 14.3, 0.95, 9.5, col_t6) +
  sil_layer("coral", 15.7, 0.9,  8.4, col_t3) +
  sil_layer("snail", 13.7, 1.9, 4.2, col_snail) +
  sil_layer("snail", 15.6, 2.1, 4.6, col_snail, flip = TRUE) +
  sil_layer("snail", 14.8, 0.7, 3.2, col_snail) +
  sil_layer("crab",  16.4, 1.7, 4.4, col_crus) +
  sil_layer("fish",  13.4, 3.0, 4.2, col_fish, flip = TRUE) +
  annotate("text", x = 15.0, y = -0.55, label = "Shift in CAFI community",
           fontface = "bold", size = 3.3, colour = "grey15") +

  # arrow 2 -> 3
  annotate("segment", x = 18.5, xend = 20.8, y = 1.4, yend = 1.4,
           arrow = arrow_x, linewidth = 0.8, colour = "grey25") +

  # ---- Stage 3: LOWER CORAL CONDITION (pale, declining colony) ----
  sil_layer("coral", 24.5, 0.9, 10.5, col_ill) +
  annotate("segment", x = 26.6, xend = 26.6, y = 1.7, yend = 0.5,
           arrow = arrow(length = unit(2.2, "mm"), type = "closed"),
           linewidth = 0.9, colour = col_pr) +
  annotate("text", x = 24.5, y = -0.55, label = "Lower coral condition",
           fontface = "bold", size = 3.3, colour = "grey15") +

  # ---- feedback loop: stage 3 back to stage 1 ----
  annotate("curve", x = 24.5, xend = 4.8, y = 3.05, yend = 3.05,
           curvature = -0.32, arrow = arrow_x, linewidth = 0.7,
           colour = "grey45", linetype = "22") +
  annotate("text", x = 14.6, y = 4.95,
           label = "negative feedback",
           fontface = "italic", size = 3.1, colour = "grey45") +

  scale_x_continuous(limits = c(0, 30), expand = c(0, 0)) +
  scale_y_continuous(limits = c(-1.2, 5.4), expand = c(0, 0)) +
  labs(title = "Feedback to the foundation species") +
  theme_void(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 11, hjust = 0,
                                  margin = margin(b = 2)),
        plot.margin = margin(6, 10, 4, 10)) +
  coord_cartesian(clip = "off")

# ---- assemble: A | B on top, C spanning bottom ------------------------------
fig <- (pA | pB) / pC +
  plot_layout(heights = c(1, 0.78)) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 12))

dest <- "manuscript/Figure-revisions"
dir.create(dest, recursive = TRUE, showWarnings = FALSE)
ggsave(file.path(dest, "FigureX_concept_hypotheses.pdf"), fig,
       width = 170, height = 132, units = "mm", dpi = 300, device = cairo_pdf)
ggsave(file.path(dest, "FigureX_concept_hypotheses.png"), fig,
       width = 170, height = 132, units = "mm", dpi = 300, bg = "white")
message("Saved FigureX_concept_hypotheses to ", dest)

# ==============================================================================
#  GRAPHICAL ABSTRACT  (Ecology Letters; stand-alone, legible at 50 x 60 mm)
#  Supported result ONLY (Propagule Redirection): increasing coral AMOUNT
#  dilutes occupants PER COLONY, which weakens the positive Pocillopora-CAFI
#  mutualist feedback, so per-colony coral CONDITION declines.
#
#  Two stacked states on a 5:6 portrait (x 0-10 -> 50 mm, y 0-12 -> 60 mm,
#  so 1 data unit = 5 mm on both axes; absolute-mm silhouettes stay undistorted).
#   - 1 colony  : one vivid PINK colony, helpers PACKED on it  -> condition up
#   - 6 colonies: six PALE-GREY colonies, helpers spread thin  -> condition down
#  A tapering green ribbon (thick -> thin, top -> bottom) shows the positive
#  feedback dampening. Text is kept to 4 strings, all >= 6 pt at 50 x 60 mm.
#  (ggplot text size in mm; pt = size * 2.845, so size >= 2.2 -> >= 6.26 pt.)
# ==============================================================================
col_pink <- "#DC6E94"   # healthy / vivid Pocillopora
col_pale <- "#B9BFC5"   # pale, low-condition colony
col_pos  <- "#009E73"   # positive (mutualist) feedback
GA_PT <- 2.845276       # ggplot text size (mm) -> points

# Tapering curved ribbon as a filled polygon (quadratic Bezier spine, width
# shrinking w0 -> w1 along its length); used for the weakening feedback.
taper_ribbon <- function(x0, y0, x1, y1, w0, w1, bend = 0.6, n = 80) {
  t  <- seq(0, 1, length.out = n)
  cx <- (x0 + x1) / 2 + bend
  cy <- (y0 + y1) / 2
  bx <- (1 - t)^2 * x0 + 2 * (1 - t) * t * cx + t^2 * x1
  by <- (1 - t)^2 * y0 + 2 * (1 - t) * t * cy + t^2 * y1
  dx <- 2 * (1 - t) * (cx - x0) + 2 * t * (x1 - cx)
  dy <- 2 * (1 - t) * (cy - y0) + 2 * t * (y1 - cy)
  L  <- sqrt(dx^2 + dy^2); nx <- -dy / L; ny <- dx / L
  w  <- w0 + (w1 - w0) * t
  data.frame(
    x = c(bx + nx * w / 2, rev(bx - nx * w / 2)),
    y = c(by + ny * w / 2, rev(by - ny * w / 2))
  )
}
ribbon_df <- taper_ribbon(8.75, 8.0, 8.65, 4.0, w0 = 0.58, w1 = 0.07, bend = 0.5)

ga <- ggplot() +
  # ---- weakening positive feedback (drawn first, behind everything) ----
  geom_polygon(data = ribbon_df, aes(x, y), inherit.aes = FALSE,
               fill = col_pos, alpha = 0.85, colour = NA) +
  annotate("segment", x = 8.67, xend = 8.63, y = 4.35, yend = 3.6,
           arrow = arrow(length = unit(1.6, "mm"), type = "closed"),
           linewidth = 0.2, colour = col_pos) +

  # ---- title ----
  annotate("text", x = 5, y = 11.35, label = "More habitat, worse condition",
           fontface = "bold", size = 3.05, colour = "grey10", hjust = 0.5) +

  # ================= STATE 1: 1 colony (helpers packed, healthy) =============
  annotate("segment", x = 0.7, xend = 4.6, y = 7.05, yend = 7.05,
           colour = col_sand2, linewidth = 0.7) +
  sil_layer("coral",  2.5, 8.35, 14, col_pink) +
  sil_layer("fish",   2.2, 9.75, 5.4, col_fish, flip = TRUE) +
  sil_layer("fish",   3.5, 9.45, 4.6, col_fish, flip = TRUE) +
  sil_layer("shrimp", 1.2, 8.55, 4.4, col_crus) +
  sil_layer("crab",   3.7, 8.35, 4.4, col_crus) +
  sil_layer("snail",  2.7, 7.55, 2.8, col_snail) +
  # condition UP (green)
  annotate("segment", x = 4.95, xend = 4.95, y = 7.8, yend = 9.25,
           arrow = arrow(length = unit(1.9, "mm"), type = "closed"),
           linewidth = 1.4, colour = col_pos) +
  annotate("text", x = 2.5, y = 6.5, label = "1 colony",
           size = 2.55, fontface = "bold", colour = "grey15", hjust = 0.5) +

  # progression arrow (more habitat: 1 -> 6 colonies)
  annotate("segment", x = 2.5, xend = 2.5, y = 6.0, yend = 4.9,
           arrow = arrow(length = unit(2.0, "mm"), type = "closed"),
           linewidth = 1.0, colour = "grey30") +

  # ================= STATE 2: 6 colonies (helpers diluted, pale) =============
  annotate("segment", x = 0.35, xend = 8.05, y = 2.3, yend = 2.3,
           colour = col_sand2, linewidth = 0.7) +
  sil_layer("coral", 0.80, 2.9, 4.8, col_pale) +
  sil_layer("coral", 2.05, 2.9, 4.8, col_pale) +
  sil_layer("coral", 3.30, 2.9, 4.8, col_pale) +
  sil_layer("coral", 4.55, 2.9, 4.8, col_pale) +
  sil_layer("coral", 5.80, 2.9, 4.8, col_pale) +
  sil_layer("coral", 7.05, 2.9, 4.8, col_pale) +
  # helpers spread ~one per colony, most colonies now empty (diluted)
  sil_layer("fish",   0.80, 3.55, 2.7, col_fish, flip = TRUE) +
  sil_layer("crab",   3.30, 3.5, 2.7, col_crus) +
  sil_layer("shrimp", 5.80, 3.55, 2.7, col_crus) +
  # condition DOWN (red)
  annotate("segment", x = 8.15, xend = 8.15, y = 3.85, yend = 2.4,
           arrow = arrow(length = unit(1.9, "mm"), type = "closed"),
           linewidth = 1.4, colour = col_pr) +
  annotate("text", x = 3.9, y = 1.4, label = "6 colonies",
           size = 2.55, fontface = "bold", colour = "grey15", hjust = 0.5) +

  # ---- one-line mechanism ----
  annotate("text", x = 5, y = 0.45, label = "occupants diluted per colony",
           size = 2.45, fontface = "italic", colour = "grey25", hjust = 0.5) +

  scale_x_continuous(limits = c(0, 10), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 12), expand = c(0, 0)) +
  theme_void() +
  theme(plot.margin = margin(1, 1, 1, 1)) +
  coord_cartesian(clip = "off")

ggsave(file.path(dest, "FigureX_concept_graphical_abstract.pdf"), ga,
       width = 50, height = 60, units = "mm", dpi = 300, device = cairo_pdf)
ggsave(file.path(dest, "FigureX_concept_graphical_abstract.tif"), ga,
       width = 50, height = 60, units = "mm", dpi = 600,
       bg = "white", compression = "lzw")
message("Saved FigureX_concept_graphical_abstract to ", dest)
message(sprintf("GA text sizes (pt @ 50x60 mm): title=%.1f, labels=%.1f, mechanism=%.1f",
                3.05 * GA_PT, 2.55 * GA_PT, 2.45 * GA_PT))

# ==============================================================================
#  FULL-SIZE TWO-HYPOTHESIS FIGURE  (FigureX_hypothesis_feedback.{pdf,png})
#  Two side-by-side panels — FIELD OF DREAMS (predicted, not observed) vs
#  PROPAGULE REDIRECTION (supported) — each showing, top -> bottom:
#    (1) a schematic DEFINITION GRAPH (total + per-colony prediction curves),
#    (2) a 3-node clockwise loop CORAL -> CAFI COMMUNITY -> CONDITION -> CORAL,
#    (3) a 2-line outcome footer.
#  Honesty cues (from review): the supported PR panel DOMINATES (saturated,
#  heavy frame, drop shadow); the rejected FoD panel is MUTED. The middle node
#  is the agnostic "CAFI COMMUNITY" (incl. non-mutualists). Loop edges carry
#  EVIDENCE tiers: CORAL->COMMUNITY solid (measured manipulation);
#  COMMUNITY->CONDITION dashed "correlational"; CONDITION->CORAL dashed
#  "hypothesized". FoD total = proportional / per-colony flat; PR total =
#  rising-but-SUB-PROPORTIONAL / per-colony declining. CORAL node = the .ai
#  Pocillopora art (deep = healthy, pale = stressed); silhouettes neutral
#  charcoal (colour means hypothesis identity only).
#  Panel coords: x 0-60, y 0-100 (0.6 aspect); 1 unit ~ 1.5 mm at print.
#  Smallest label = size 2.5 mm -> 7.1 pt (FF_PT below confirms).
# ==============================================================================
FF_PT <- 2.845276
coral_pink <- png::readPNG("assets/coral_art/pocillopora_pink.png")   # healthy
coral_pale <- png::readPNG("assets/coral_art/pocillopora_pale.png")   # stressed
col_sil <- "#39414A"   # neutral charcoal for ALL silhouettes

# blend a colour toward white by fraction f (used to mute the rejected panel)
lighten <- function(hex, f = 0.4) {
  cc <- grDevices::col2rgb(hex) / 255
  grDevices::rgb(cc[1] + (1 - cc[1]) * f,
                 cc[2] + (1 - cc[2]) * f,
                 cc[3] + (1 - cc[3]) * f)
}

# place a pre-coloured RGBA raster centred at (x,y), aspect preserved (mm)
art_layer <- function(arr, x, y, h_mm) {
  asp <- dim(arr)[1] / dim(arr)[2]
  annotation_custom(grid::rasterGrob(arr,
                      width = grid::unit(h_mm / asp, "mm"),
                      height = grid::unit(h_mm, "mm"), interpolate = TRUE),
                    xmin = x, xmax = x, ymin = y, ymax = y)
}
# round node / badge disc of absolute radius r_mm centred at data (x,y)
node_circle <- function(x, y, r_mm, fill, border, lwd = 1, lty = "22") {
  annotation_custom(grid::circleGrob(r = grid::unit(r_mm, "mm"),
                      gp = grid::gpar(fill = fill, col = border,
                                      lwd = lwd, lty = lty)),
                    xmin = x, xmax = x, ymin = y, ymax = y)
}

make_panel <- function(side) {
  fod <- side == "FoD"
  mc  <- function(col, f = 0.45) if (fod) lighten(col, f) else col  # mute FoD
  hyp   <- if (fod) col_fod else col_pr
  hcol  <- mc(hyp, 0.42)
  head  <- if (fod) "FIELD OF DREAMS" else "PROPAGULE REDIRECTION"
  mark  <- if (fod) "✗" else "✓"
  badge <- if (fod) "#9AA3AB" else "#1FA45C"           # grey vs green disc
  cap   <- if (fod) "occupants track habitat 1:1 → per-colony constant"
           else     "supply added sub-proportionally → per-colony declines"
  coral_art <- if (fod) coral_pink else coral_pale
  coral_bd  <- if (fod) lighten(col_pink, 0.15) else "#9AA7B0"
  fr_fill   <- if (fod) "#F4F8FC" else "#FDEEE5"
  fr_col    <- if (fod) lighten(col_fod, 0.55) else col_pr
  fr_lwd    <- if (fod) 1.3 else 2.6

  cxC <- 30; cyC <- 50    # CORAL (top)
  cxM <- 44; cyM <- 30    # CAFI COMMUNITY (bottom-right)
  cxN <- 16; cyN <- 30    # CONDITION (bottom-left)

  # ---- definition graphs ----
  graph <- if (fod) list(
    annotate("segment", x = 13, xend = 51, y = 74, yend = 86,
             colour = mc("#7FB5E0", 0.25), linewidth = 1.0, linetype = "31"),
    annotate("segment", x = 13, xend = 51, y = 80, yend = 80,
             colour = mc(col_fod, 0.25), linewidth = 1.8),
    annotate("text", x = 46.5, y = 87.3, label = "total ↑",
             colour = mc("#3F86C4", 0.2), size = 2.5, fontface = "italic"),
    annotate("text", x = 22.5, y = 81.7, label = "per colony — flat",
             colour = mc(col_fod, 0.2), size = 2.5, fontface = "bold")
  ) else {
    ptot <- data.frame(x = seq(13, 51, length.out = 45))
    ptot$y <- 76 + 7.0 * sqrt((ptot$x - 13) / 38)        # sub-proportional rise
    list(
      annotate("segment", x = 13, xend = 51, y = 76, yend = 89,
               colour = "grey80", linewidth = 0.7, linetype = "12"),  # 1:1 ghost
      annotate("text", x = 48.3, y = 89.7, label = "1:1",
               colour = "grey55", size = 2.5),
      geom_line(data = ptot, aes(x, y), inherit.aes = FALSE,
                colour = "#E0995E", linewidth = 1.2, linetype = "31"),
      annotate("segment", x = 13, xend = 51, y = 86, yend = 74,
               colour = col_pr, linewidth = 1.8),
      annotate("text", x = 36, y = 84.2, label = "total ↑ (sub-proportional)",
               colour = "#BC5E2A", size = 2.5, fontface = "italic"),
      annotate("text", x = 39, y = 74.5, label = "per colony ↓",
               colour = col_pr, size = 2.5, fontface = "bold")
    )
  }

  # ---- CAFI community node: many (FoD) vs few (PR), neutral charcoal ----
  mut <- if (fod) list(
    sil_layer("fish",   cxM - 3.2, cyM + 2.7, 3.2, col_sil, flip = TRUE),
    sil_layer("fish",   cxM + 3.0, cyM + 2.3, 3.2, col_sil),
    sil_layer("shrimp", cxM - 3.6, cyM - 1.4, 3.4, col_sil),
    sil_layer("crab",   cxM + 3.3, cyM - 1.7, 3.6, col_sil),
    sil_layer("shrimp", cxM + 0.3, cyM + 3.5, 3.2, col_sil),
    sil_layer("snail",  cxM - 0.9, cyM - 3.0, 3.0, col_sil)
  ) else list(
    sil_layer("fish",   cxM - 2.3, cyM + 1.5, 3.4, col_sil, flip = TRUE),
    sil_layer("snail",  cxM + 2.4, cyM - 1.4, 3.0, col_sil)
  )

  # ---- condition tick: up/green vs down/vermillion ----
  tick <- if (fod)
    annotate("segment", x = cxN, xend = cxN, y = cyN - 3.6, yend = cyN + 3.6,
             arrow = arrow(length = unit(2.4, "mm"), type = "closed"),
             linewidth = 2.3, colour = mc("#1A9E5A", 0.35))
  else
    annotate("segment", x = cxN, xend = cxN, y = cyN + 3.6, yend = cyN - 3.6,
             arrow = arrow(length = unit(2.4, "mm"), type = "closed"),
             linewidth = 2.3, colour = col_pr)
  cond_sub  <- if (fod) "↑ good" else "↓ worse"
  cond_subc <- if (fod) mc("#1A7F49", 0.3) else col_pr

  # ---- 2-line outcome footer (badges carry the verdict) ----
  out1  <- if (fod) "STRONG feedback maintained" else "WEAK feedback (diluted)"
  out2  <- if (fod) "predicted — not observed"
           else     "supported ✓ · condition falls as amount rises"
  out2c <- if (fod) "grey35" else "#177A47"
  out2f <- if (fod) "italic" else "bold"

  # ---- evidence-tiered loop arrows (clockwise) ----
  a_solid <- mc("grey25", 0.4)
  a_dash  <- mc("grey45", 0.35)
  ar  <- arrow(length = unit(2.3, "mm"), type = "closed")
  ar2 <- arrow(length = unit(1.9, "mm"), type = "closed")

  shadow <- if (!fod) list(annotation_custom(grid::roundrectGrob(r = unit(4, "mm"),
                       gp = grid::gpar(fill = "grey70", col = NA, alpha = 0.45)),
                     xmin = 1.9, xmax = 59.6, ymin = 0.6, ymax = 97.7)) else list()

  ggplot() + shadow +
    annotation_custom(grid::roundrectGrob(r = unit(4, "mm"),
                        gp = grid::gpar(fill = fr_fill, col = fr_col, lwd = fr_lwd)),
                      xmin = 1, xmax = 59, ymin = 1.5, ymax = 98.5) +
    # header bar: badge at LEFT, title centred in remaining width
    node_circle(8.5, 95, 4.7, badge, badge, lwd = 0.5, lty = "solid") +
    annotate("text", x = 8.5, y = 94.7, label = mark, colour = "white",
             fontface = "bold", size = 5.4) +
    annotate("text", x = 34, y = 95, label = head, fontface = "bold",
             colour = hcol, size = 3.3) +
    # definition graph box + schematic axes
    annotation_custom(grid::roundrectGrob(r = unit(2.2, "mm"),
                        gp = grid::gpar(fill = "white", col = "grey78", lwd = 0.8)),
                      xmin = 5, xmax = 55, ymin = 68, ymax = 90) +
    annotate("segment", x = 12, xend = 12, y = 73, yend = 87.5,
             arrow = arrow(length = unit(1.6, "mm"), type = "closed"),
             colour = "grey35", linewidth = 0.6) +
    annotate("segment", x = 12, xend = 52, y = 73, yend = 73,
             arrow = arrow(length = unit(1.6, "mm"), type = "closed"),
             colour = "grey35", linewidth = 0.6) +
    annotate("text", x = 8.4, y = 80.5, label = "occupants", angle = 90,
             colour = "grey35", size = 2.5) +
    annotate("text", x = 33, y = 70.3, label = "coral amount →",
             colour = "grey35", size = 2.5) +
    graph +
    annotate("text", x = 30, y = 64.4, label = cap, fontface = "italic",
             colour = "grey25", size = 2.85) +
    # loop arrows: solid = measured, dashed = inferred
    annotate("curve", x = cxC + 5.2, xend = cxM - 1.2,
             y = cyC - 4.6, yend = cyM + 5.4, curvature = 0.42,
             arrow = ar, linewidth = 1.9, colour = a_solid, lineend = "round") +
    annotate("curve", x = cxM - 4.6, xend = cxN + 4.6,
             y = cyM - 5.0, yend = cyN - 5.0, curvature = 0.42,
             arrow = ar2, linewidth = 1.4, colour = a_dash, linetype = "22") +
    annotate("curve", x = cxN + 1.2, xend = cxC - 5.2,
             y = cyN + 5.4, yend = cyC - 4.6, curvature = 0.42,
             arrow = ar2, linewidth = 1.4, colour = a_dash, linetype = "22") +
    annotate("text", x = 30, y = 26.0, label = "correlational",
             colour = mc("grey35", 0.3), size = 2.5, fontface = "italic") +
    annotate("text", x = 11.4, y = 43.5, label = "hypothesized", angle = 62,
             colour = mc("grey35", 0.3), size = 2.5, fontface = "italic") +
    # nodes
    node_circle(cxC, cyC, 8.3, "#FFFFFF", coral_bd, lwd = 1.4) +
    art_layer(coral_art, cxC, cyC, 13) +
    node_circle(cxM, cyM, 7.8, mc("#EDF7F1", 0.3), mc("#2E8B57", 0.35), lwd = 1.2) +
      mut +
    node_circle(cxN, cyN, 7.8, mc("#FBF1D8", 0.3), mc("#E0A500", 0.35), lwd = 1.2) +
      tick +
    annotate("text", x = cxC, y = 59.6, label = "CORAL", fontface = "bold",
             colour = "grey20", size = 2.6) +
    annotate("text", x = cxM, y = 21.2, label = "CAFI COMMUNITY",
             fontface = "bold", colour = "grey20", size = 2.6) +
    annotate("text", x = cxM, y = 17.9, label = "shifts\n(incl. non-mutualists)",
             colour = "grey35", size = 2.5, lineheight = 0.86) +
    annotate("text", x = cxN, y = 21.2, label = "CONDITION", fontface = "bold",
             colour = "grey20", size = 2.6) +
    annotate("text", x = cxN, y = 18.3, label = cond_sub, fontface = "bold",
             colour = cond_subc, size = 2.5) +
    # outcome footer (2 lines)
    annotate("text", x = 30, y = 11.6, label = out1, fontface = "bold",
             colour = hcol, size = 2.95) +
    annotate("text", x = 30, y = 7.6, label = out2, fontface = out2f,
             colour = out2c, size = 2.6) +
    scale_x_continuous(limits = c(0, 60), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0, 100), expand = c(0, 0)) +
    theme_void() +
    theme(plot.margin = margin(1, 1, 1, 1)) +
    coord_cartesian(clip = "off")
}

fig2 <- (make_panel("FoD") | make_panel("PR")) +
  plot_layout(widths = c(1, 1)) +
  plot_annotation(
    title = "More habitat, worse condition",
    subtitle = paste0("Coral amount rises 1→6 colonies: two fates for the ",
                      "Pocillopora–CAFI feedback"),
    caption = "Feedback arrows:  solid = measured  ·  dashed = inferred (correlational / hypothesized)",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5,
                                margin = margin(b = 2)),
      plot.subtitle = element_text(size = 10, hjust = 0.5, colour = "grey35",
                                   margin = margin(b = 4)),
      plot.caption = element_text(size = 8.5, hjust = 0.5, colour = "grey30",
                                  margin = margin(t = 3)),
      plot.margin = margin(4, 5, 3, 5)))

ggsave(file.path(dest, "FigureX_hypothesis_feedback.pdf"), fig2,
       width = 184, height = 168, units = "mm", dpi = 300, device = cairo_pdf)
ggsave(file.path(dest, "FigureX_hypothesis_feedback.png"), fig2,
       width = 184, height = 168, units = "mm", dpi = 300, bg = "white")
message("Saved FigureX_hypothesis_feedback to ", dest)
message(sprintf("Two-hypothesis fig smallest label = %.1f pt (size 2.5 mm)",
                2.5 * FF_PT))

# ---- companion legend / credits --------------------------------------------
legend_txt <- paste0(
  "Figure X. Two hypotheses for how the amount of coral habitat shapes the ",
  "coral-associated fish and invertebrate (CAFI) community, and the feedback ",
  "to coral condition. (A) Total occupants vs. amount of coral habitat: the ",
  "Field of Dreams hypothesis predicts a proportional increase (blue), whereas ",
  "Propagule Redirection predicts a roughly constant regional supply that is ",
  "redistributed (vermillion). (B) Occupants per colony: Field of Dreams ",
  "predicts constant per-colony density (blue); Propagule Redirection predicts ",
  "declining per-colony density as a fixed supply is diluted across more ",
  "colonies (vermillion). (C) More coral habitat shifts the CAFI community ",
  "(toward corallivores) and feeds back to lower per-colony coral condition. ",
  "Coral colonies are coloured by the experimental habitat-amount treatment ",
  "(1 = gold, 3 = sky blue, 6 = green).\n\n",
  "Organism silhouettes from PhyloPic (https://www.phylopic.org); see ",
  "assets/silhouettes/ATTRIBUTION.txt for artists and licenses. Pocillopora ",
  "coral (Guillaume Dera, CC0); damselfish (perevolotsky, CC0); crab ",
  "(Carter Johnson, CC BY 4.0); shrimp (Douglas Teles da Rosa, CC BY 4.0); ",
  "muricid snail (Karla Martinez, CC BY 3.0).\n\n",
  "---\n\n",
  "Graphical abstract (50 x 60 mm). Increasing the amount of coral habitat ",
  "redistributes a roughly fixed regional supply of coral-associated fishes ",
  "and invertebrates (CAFI), diluting occupants per colony: a single colony ",
  "(left, pink) hosts a packed mutualist community, whereas six colonies ",
  "(below, pale) share the same occupants thinly. This weakens the positive ",
  "CAFI-Pocillopora feedback (tapering green ribbon) so per-colony coral ",
  "condition declines (green up-arrow vs. red down-arrow). Silhouettes from ",
  "PhyloPic: Pocillopora (Guillaume Dera, CC0); damselfish (perevolotsky, ",
  "CC0); crab (Carter Johnson, CC BY 4.0); shrimp (Douglas Teles da Rosa, ",
  "CC BY 4.0); muricid snail (Karla Martinez, CC BY 3.0).\n\n",
  "---\n\n",
  "Figure X (two-hypothesis feedback figure; FigureX_hypothesis_feedback). ",
  "Increasing coral amount (1 → 6 colonies) sets up two fates for the ",
  "positive Pocillopora–CAFI feedback. LEFT — Field of Dreams (rejected, ✗): ",
  "occupants track habitat one-to-one, so total occupants rise proportionally ",
  "and per-colony density stays constant; coral condition would be unchanged ",
  "with amount. This prediction was NOT observed. RIGHT — Propagule ",
  "Redirection (supported, ✓): regional supply is added sub-proportionally, so ",
  "total occupants rise but less than one-to-one and per-colony density ",
  "declines; per-colony coral condition falls as amount rises (“more habitat, ",
  "worse condition”). In each clockwise loop CORAL → CAFI COMMUNITY → ",
  "CONDITION → CORAL, the middle node is the whole coral-associated community ",
  "(it shifts with amount and includes non-mutualists, not only mutualists); ",
  "its silhouette density encodes many-vs-few occupants per colony. Evidence ",
  "is distinguished by arrow style: the CORAL → community link (the measured ",
  "manipulation) is SOLID; the community → condition link is DASHED because it ",
  "is correlational (community PC1 → condition PC1, β ≈ 0.29, p ≈ 0.04); the ",
  "condition → coral feedback closure is DASHED and labelled hypothesized. The ",
  "CORAL node is the project Pocillopora illustration, deep-toned (healthy) vs. ",
  "pale (stressed); CONDITION is a green up-tick vs. a vermillion down-tick; ",
  "silhouettes are neutral charcoal so colour denotes hypothesis identity only. ",
  "Coral artwork in assets/coral_art/; PhyloPic silhouettes credited above.\n"
)
writeLines(legend_txt, file.path(dest, "FigureX_concept_legend.md"))
message("Saved FigureX_concept_legend.md to ", dest)

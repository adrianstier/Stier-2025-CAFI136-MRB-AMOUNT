#!/usr/bin/env python3
"""Build the CAFI136 graphical abstract.

Ecology Letters: within 50 x 60 mm, legible at that size, minimal text, tif/pdf.

Message: adding coral does not crowd each colony (per-colony density flat,
chi2 = 0.77, p = 0.680) - it changes WHICH taxa live there (PERMANOVA
F = 2.01, R2 = 0.17, p = 0.015).

Placement follows the colony's own structure: invertebrates sit in the
interstitial gaps between branches and are occluded by the branch highlights in
front, so they peek out rather than sit on top. Fishes are too large for any gap (the biggest
pocket is ~2.2 mm radius against a 5.9 mm damselfish), so they hover at the
colony margin in front - which is also how they actually behave.

Animal sizes are BALLPARK proportional: ordering and rough magnitude follow the
measured medians, square-root compressed so the real 8.6x range fits a panel
where the smallest taxon must still read. Coral is not to scale.
"""
import os, re, subprocess, math
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ART  = os.path.join(HERE, "art")

W, H = 50.0, 60.0
FONT = "Helvetica Neue, Helvetica, Arial, sans-serif"
BLUE, ORANGE, INK, GREY = "#0072B2", "#D55E00", "#1a1a1a", "#8a8a8a"

# measured medians (mm) from the CAFI size records, n = 3-302 per taxon
REAL = {"dascyllus_flavicaudus": 40.0, "dascyllus_aruanus": 34.3,
        "caracanthus_maculatus": 32.1, "halichoeres_trimaculatus": 24.0,
        "harpiliopsis_spinigera": 14.4, "pascula_muricata": 7.5,
        "mitrella_moleculina": 6.0, "periclimenes_watamuae": 6.0,
        "trapezia_serenei": 5.1, "apataxia_cerithiiformis": 4.0,
        "xanthias_lamarckii": 4.0, "diala_albugo": 3.0}
BASE = 2.0
# Snails are drawn ~1.5x above the ballpark ladder. They are the taxa carrying
# the six-colony result (Apataxia +350%, Mitrella +1500%) and at their true
# ballpark size (2.0-2.5 mm) they disappear. Declared in the caption.
# Shrimps and snails are 3-6 mm real, so on the ballpark ladder they land at
# 2-3 mm on the page and disappear. They also carry the community signal, so
# they are lifted above the ladder. Declared in the caption.
EMPHASIS = {"apataxia_cerithiiformis": 1.45, "mitrella_moleculina": 1.45,
            "diala_albugo": 1.55, "pascula_muricata": 0.92,
            "harpiliopsis_spinigera": 1.28, "periclimenes_watamuae": 1.45,
            "trapezia_serenei": 1.45, "xanthias_lamarckii": 1.30}
SIZE = {k: BASE * math.sqrt(v / 4.0) * EMPHASIS.get(k, 1.0) for k, v in REAL.items()}

_cache = {}


def adjust(svg, sat=1.0, mul=1.0, add=0.0, contrast=1.0):
    """Recolour every hex fill in place.

    SVG *filters* (feColorMatrix / feComponentTransfer) are rasterised when the
    document is written to PDF, which turned the corals and every animal inside
    the filtered groups fuzzy. Doing the same maths directly on the path fills
    keeps the artwork vector at any zoom.
    """
    def fix(m):
        pre, hexv = m.group(1), m.group(2)
        r, g, b = (int(hexv[i:i+2], 16) for i in (0, 2, 4))
        lum = 0.2126*r + 0.7152*g + 0.0722*b
        out = []
        for c in (r, g, b):
            c = lum + (c - lum) * sat        # saturation about luminance
            c = 128.0 + (c - 128.0) * contrast   # contrast about mid-grey
            c = c * mul + add * 255.0        # brightness
            out.append(max(0, min(255, int(round(c)))))
        return f"{pre}#{out[0]:02x}{out[1]:02x}{out[2]:02x}"
    return re.sub(r'(fill="|fill:\s*)#([0-9A-Fa-f]{6})', fix, svg)


def load(path):
    if path in _cache:
        return _cache[path]
    s = open(path).read()
    m = re.search(r'viewBox="([\d.eE+\-\s]+)"', s)
    if m:
        vb = [float(v) for v in m.group(1).split()]
    else:                                  # IAN symbols have no viewBox
        w = re.search(r'\bwidth="([\d.]+)', s)
        h = re.search(r'\bheight="([\d.]+)', s)
        vb = [0, 0, float(w.group(1)) if w else 100.0, float(h.group(1)) if h else 100.0]
    inner = re.sub(r'</svg>\s*$', '', re.sub(r'^.*?<svg[^>]*>', '', s, flags=re.S), flags=re.S)
    inner = re.sub(r'<(title|desc|metadata)[^>]*>.*?</\1>', '', inner, flags=re.S)
    for tag in ("RDF", "Work", "namedview"):
        inner = re.sub(rf'<[a-zA-Z]+:{tag}\b.*?</[a-zA-Z]+:{tag}>', '', inner, flags=re.S)
        inner = re.sub(rf'<[a-zA-Z]+:{tag}\b[^>]*/>', '', inner, flags=re.S)
    inner = re.sub(r'<\?xml[^>]*\?>', '', inner)
    inner = re.sub(r'<!--.*?-->', '', inner, flags=re.S)
    vw, vh = vb[2], vb[3]
    # Image Trace renders the page as a near-white full-canvas path. Match it
    # structurally. NB a trailing \b fails: in "h1260v1048" the digit and the
    # command letter are both word chars, so use a non-numeric lookahead.
    m2 = re.search(r'<path\b[^>]*?>', inner, re.S)
    if m2:
        tag = m2.group(0)
        fill = re.search(r'fill:\s*#([0-9A-Fa-f]{6})', tag)
        d    = re.search(r'\sd="([^"]{0,200})', tag)
        if fill and d:
            r, g, b = (int(fill.group(1)[i:i+2], 16) for i in (0, 2, 4))
            head = d.group(1)
            if min(r, g, b) >= 0xF5 and \
               re.search(rf'[hH]{int(round(vw))}(?![\d.])', head) and \
               re.search(rf'[vV]{int(round(vh))}(?![\d.])', head):
                inner = inner[:m2.start()] + inner[m2.end():]
    _cache[path] = (inner, vw, vh)
    return _cache[path]


def coral_layers():
    """Split the traced colony into back (shadow+bodies) and front (highlights)."""
    inner, vw, vh = load(os.path.join(ART, "pocillopora_colony.svg"))
    L = {m.group(2): m.group(1) for m in
         re.finditer(r'(<g id="(layer\d+)_\w+"[^>]*>.*?</g>)', inner, re.S)}
    outer = re.search(r'<g(\s+transform="[^"]+")>', inner)
    tf = outer.group(1) if outer else ""
    return tf, L, vw, vh


CTF, CL, CVW, CVH = coral_layers()
POCKETS = np.load(os.path.join(HERE, "pockets.npy"))


def coral(cx, cy, w, part, gid, opacity=None, tint=None):
    """Three planes so occupants can be woven through the branches:
         'shadow' - the interstitial dark, furthest back
         'bodies' - the branch masses that actually occlude
         'front'  - highlights on the near faces of the branches
    An occupant drawn after 'shadow' is deep in the colony; after 'bodies' it
    sits among the branch tips; after 'front' it is clear of the colony.
    """
    keys = {"shadow": ["layer2"], "bodies": ["layer0"],
            "back": ["layer2", "layer0"], "front": ["layer1"]}[part]
    body = "".join(CL[k] for k in keys if k in CL)
    if tint:
        body = adjust(body, **tint)
    s = w / CVW
    x, y = cx - w / 2, cy - CVH * s / 2
    op = f' opacity="{opacity}"' if opacity else ""
    return (f'<g id="{gid}" transform="translate({x:.3f},{y:.3f}) scale({s:.5f})"{op}>'
            f'<g{CTF}>{body}</g></g>\n')


def coral_whole(cx, cy, w, gid, rot=0.0, opacity=None, tint=None):
    inner, vw, vh = load(os.path.join(ART, "pocillopora_colony.svg"))
    if tint:
        inner = adjust(inner, **tint)
    s = w / vw
    op = f' opacity="{opacity}"' if opacity else ""
    r = f' rotate({rot:.1f})' if rot else ''
    return (f'<g id="{gid}" transform="translate({cx:.3f},{cy:.3f}){r} '
            f'scale({s:.5f}) translate({-vw/2:.1f},{-vh/2:.1f})"{op}>{inner}</g>\n')


# Depth cues, applied together rather than one at a time:
#   size      - further objects are smaller
#   height    - further objects sit higher in the frame
#   contrast  - further objects lose saturation and gain lightness (aerial
#               perspective, the same reason distant hills go pale blue)
#   occlusion - draw order; nearer things overlap further ones
# depth runs 0 (touching the reader) to 1 (furthest back).
def depth_scale(depth):
    return 1.0 - 0.30 * depth

def depth_tint(depth):
    if depth <= 0.01:
        return None
    return dict(sat=1.0 - 0.30 * depth, mul=1.0 + 0.06 * depth,
                add=0.035 * depth, contrast=1.0 - 0.10 * depth)


def animal(taxon, cx, cy, gid, flip=False, rot=0.0, depth=0.0):
    inner, vw, vh = load(os.path.join(ART, taxon + ".svg"))
    t = depth_tint(depth)
    if t:
        inner = adjust(inner, **t)
    w = SIZE[taxon] * depth_scale(depth); s = w / vw
    sx = -s if flip else s
    return (f'<g id="{gid}" transform="translate({cx:.3f},{cy:.3f}) rotate({rot:.1f}) '
            f'scale({sx:.5f},{s:.5f}) translate({-vw/2:.1f},{-vh/2:.1f})">{inner}</g>\n')


def pocket_xy(idx, cx, cy, w):
    """Pocket centre -> figure coords for a colony drawn at (cx,cy) width w."""
    fx, fy, _ = POCKETS[idx]
    h = w * CVH / CVW
    return cx - w / 2 + fx * w, cy - h / 2 + fy * h


def text(x, y, s, size, colour=INK, weight="normal", anchor="middle", style="normal"):
    return (f'<text x="{x:.2f}" y="{y:.2f}" font-family="{FONT}" font-size="{size}" '
            f'font-weight="{weight}" font-style="{style}" fill="{colour}" '
            f'text-anchor="{anchor}">{s}</text>\n')


out = [f'<?xml version="1.0" encoding="UTF-8"?>\n'
       f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
       f'width="{W}mm" height="{H}mm" viewBox="0 0 {W} {H}">\n'
       f'<rect width="{W}" height="{H}" fill="#ffffff"/>\n']

# Three beats, matching the three things the figure shows: the manipulation,
# the community result (PERMANOVA F = 2.01, R2 = 0.17, p = 0.015) and the host
# result (PC1Coral chi2 = 8.11, p = 0.017). "Poorer condition" rather than
# "weaker" so it matches the good/poor labels in the condition row below.
out.append(text(W/2, 4.6, "More coral shifts occupants", 2.85, INK, "bold"))
out.append(text(W/2, 8.1, "and lowers coral condition", 2.85, INK, "bold"))

LX, RX = 12.6, 37.4
CY, CW = 27.4, 19.4

out.append(f'<line x1="25" y1="11.5" x2="25" y2="40.6" stroke="{GREY}" stroke-width="0.15"/>\n')
out.append(text(LX, 12.0, "1 colony", 2.5, BLUE, "bold"))
out.append(text(RX, 12.0, "6 colonies", 2.5, ORANGE, "bold"))

# Smaller than the focal colony and set behind it, so the eye reads one colony
# in front of five more rather than six competing shapes. Desaturated toward
# grey (not just faded) so they recede without turning into white blobs.
# Five neighbours arranged so each reads as a SEPARATE colony - the reader
# should be able to count six. Previously they overlapped the focal colony and
# each other, blurring into one mass, and were too faint to register at all.
# Five neighbours placed so each reads as a SEPARATE colony - the reader should
# be able to count six. Kept clear of the "6 colonies" label above (baseline
# y = 13.6) and inside the 50 mm trim; previously they overlapped both.
# The focal colony sits closest to the reader; these five overlap it and are
# drawn first, so they read as neighbours BEHIND it rather than as a ring of
# separate colonies. Each still protrudes enough to be counted.
# All five sit ABOVE and BEHIND the focal colony, which is drawn last and lowest
# in the frame. Height in frame is the depth cue: anything below the focal reads
# as nearer than it, which is what a bottom-centre neighbour was doing.
# A shallow arc across the top, so all five clear the focal colony's upper edge
# and each shows a distinct crown. Flanking positions were tried first and
# failed - the focal colony is wide enough that side neighbours were swallowed
# entirely, leaving only three of the six countable.
# Graded by depth rather than uniform: the outer pair sits nearest (lower,
# larger, more saturated) and the centre furthest, so the cluster recedes
# instead of reading as a flat row of cut-outs.
# Keep the tan hue - desaturating toward white would read as BLEACHED coral,
# which is a claim the paper does not make. Recede by alpha and a little
# contrast loss only.
# Condition also shown as pigmentation: the solitary colony sits slightly
# darker and more saturated than the crowded one. Deliberately subtle - pushing
# the crowded colony toward white would read as BLEACHING, which is not what
# the paper reports. Symbiodiniaceae density is one of the PC1Coral metrics,
# so tissue colour is a fair visual proxy for condition.
out.append('<defs>'
           '<filter id="cond_hi"><feColorMatrix type="saturate" values="1.35"/>'
           '<feComponentTransfer><feFuncR type="linear" slope="0.80"/>'
           '<feFuncG type="linear" slope="0.78"/><feFuncB type="linear" slope="0.74"/>'
           '</feComponentTransfer></filter>'
           '<filter id="cond_lo"><feColorMatrix type="saturate" values="0.72"/>'
           '<feComponentTransfer><feFuncR type="linear" slope="1.08" intercept="0.06"/>'
           '<feFuncG type="linear" slope="1.07" intercept="0.06"/>'
           '<feFuncB type="linear" slope="1.06" intercept="0.055"/>'
           '</feComponentTransfer></filter></defs>\n')
out.append('<defs><filter id="recede"><feColorMatrix type="saturate" values="0.85"/>'
           '<feComponentTransfer><feFuncA type="linear" slope="0.50"/></feComponentTransfer>'
           '</filter></defs>\n')

# --- scenes: each colony carries the same six species listed below it --------
# Fishes are far too large for any branch gap (the largest pocket is ~2.2 mm
# radius against a 5.9 mm damselfish), so they hover at the colony margin in
# front - which is also how they behave. Invertebrates sit in the mapped
# interstitial pockets, occluded by the branch highlights drawn after them.
COND_HI = dict(sat=1.48, mul=0.74, contrast=1.34)
COND_LO = dict(sat=0.72, mul=1.09, add=0.045, contrast=1.20)
# Occupants now sit at three depths so they weave through the branches:
#   "deep"  - drawn after the interstitial shadow, so branch bodies AND
#             highlights pass in front. Only part of the animal shows.
#   "among" - drawn after the branch bodies, so only the near-face highlights
#             cross it. Reads as tucked between branches but stays legible.
#   "front" - clear of the colony.
# Positions straddle the colony outline where possible: an animal half over
# coral and half over white background reads at 4 mm; one wholly inside the
# colony mass does not, whatever the occlusion.
# ROW 1 - the manipulation. Same colony drawn at the same size, once on the
# left and six times on the right, so the treatment is unambiguous and the
# 6x habitat difference is literal rather than implied by ghosting.
# ROW 2 - the result. The focal colony from each treatment, large enough that
# its occupants are legible, with a connector showing where it came from.
COND_HI = dict(sat=1.48, mul=0.74, contrast=1.34)
COND_LO = dict(sat=0.72, mul=1.09, add=0.045, contrast=1.20)

PATCH_W, PATCH_Y = 4.0, 16.6
out.append(coral_whole(LX, PATCH_Y, PATCH_W, "patch_L", tint=COND_HI))
# Spaced 6.4 mm apart horizontally and 6.0 mm vertically so a ring can enclose
# ONE colony without touching its neighbours; at the previous 5.6/4.4 spacing
# the colonies overlapped and the ring cut through four of them.
for i, (px, py) in enumerate([(32.0, 14.0), (37.4, 14.0), (42.8, 14.0),
                              (32.0, 19.2), (37.4, 19.2), (42.8, 19.2)]):
    out.append(coral_whole(px, py, PATCH_W, f"patch_R{i}", tint=COND_LO))

# connectors: this colony, enlarged below
out.append('<defs><marker id="dn" viewBox="0 0 10 10" refX="7" refY="5" '
           f'markerWidth="3.4" markerHeight="3.4" orient="auto">'
           f'<path d="M0,2 L8,5 L0,8 z" fill="{GREY}"/></marker></defs>\n')
# A ring around one colony in each treatment, and the arrow leaves THAT colony,
# so row 2 reads as "this one, enlarged" rather than as a summary of the group.
for cx, cy, rr in ((LX, PATCH_Y, 2.8), (37.4, 19.2, 2.4)):
    out.append(f'<circle cx="{cx}" cy="{cy}" r="{rr}" fill="none" '
               f'stroke="{GREY}" stroke-width="0.28" stroke-dasharray="0.9 0.7"/>\n')
    out.append(f'<line x1="{cx}" y1="{cy+rr+0.5:.1f}" x2="{cx}" y2="25.4" '
               f'stroke="{GREY}" stroke-width="0.3" stroke-linecap="butt" '
               f'marker-end="url(#dn)"/>\n')

CY, CW = 31.4, 18.8
# Colony L spans x 1.6-23.6, R spans 26.4-48.4, both y 25.5-41.7.
# Occupants are spread across the INTERIOR as well as the margin, and repeated
# roughly in proportion to their per-colony abundance:
#   solitary  Periclimenes 8.89, Harpiliopsis 5.50, D. aruanus 4.94,
#             Trapezia 4.67, Apataxia 1.00, Caracanthus 0.83, Halichoeres 0.44
#   6-colony  Trapezia 6.61, Apataxia 4.50, Harpiliopsis 3.94, Diala 2.67,
#             Mitrella 1.78, D. aruanus 1.67, Xanthias 0.56
# Interior animals sit at "deep" or "among" so branch bodies and highlights
# cross them; that occlusion is what makes an interior position read as inside
# the colony rather than pasted over it.
# Colony L spans x 2.8-22.4, R spans 27.6-47.2, both y 24.4-38.9 (CY 31.6,
# CW 19.6). Every position below is inside that box - when the colonies were
# resized earlier these coordinates were left at their old values and several
# animals ended up floating beneath the colony, crowding the key row.
# Repeats track measured per-colony abundance:
#   solitary  Periclimenes 8.89, Harpiliopsis 5.50, D. aruanus 4.94,
#             Trapezia 4.67, Apataxia 1.00, Caracanthus 0.83, Halichoeres 0.44
#   6-colony  Trapezia 6.61, Apataxia 4.50, Harpiliopsis 3.94, Diala 2.67,
#             Mitrella 1.78, D. aruanus 1.67, Xanthias 0.56
# Placement follows how these animals actually use a Pocillopora head:
#   damselfishes  hover in the water just above and around the colony, so they
#                 sit in front and clear of the crown
#   coral croucher wedges deep among the branches - centre of the colony
#   crabs, shrimp, snails  move over the branch surfaces, spread throughout
# Almost everything is therefore ON the coral at shallow depth (only the near
# face highlights cross it) rather than buried under branches, where at 3-5 mm
# it simply disappears.
# Colony L spans x 2.8-22.4, R 27.6-47.2, both y 24.4-38.9.
# Most invertebrates now sit in "front" - drawn after every coral layer, so they
# rest ON the branch surfaces rather than being crossed by them. Only a few stay
# deeper: the croucher, which genuinely wedges into the colony, plus one shrimp
# and one crab per side to keep some sense of depth.
# Colony L spans x 3.2-22.0, R 28.0-46.8, both y 24.5-38.4.
SCENE = {
  "L": {"deep":  [("caracanthus_maculatus",  12.2, 32.2, True,  -4, 0.16)],
        "among": [("periclimenes_watamuae",   6.6, 29.8, False,-14, 0.05),
                  ("trapezia_serenei",        8.8, 32.4, False,  0, 0.04)],
        "front": [("dascyllus_flavicaudus",   7.0, 23.4, False,-12, 0.0),
                  ("dascyllus_aruanus",      15.4, 22.8, True,   8, 0.0),
                  ("dascyllus_aruanus",      20.2, 26.4, True,  12, 0.0),
                  ("dascyllus_aruanus",       4.8, 27.0, False, -9, 0.0),
                  ("periclimenes_watamuae",  15.2, 28.4, True,  18, 0.0),
                  ("periclimenes_watamuae",  10.0, 36.2, False, -6, 0.0),
                  ("harpiliopsis_spinigera", 18.2, 32.4, True,   8, 0.0),
                  ("harpiliopsis_spinigera",  5.2, 34.6, False, -8, 0.0),
                  ("trapezia_serenei",       13.6, 35.8, True,   0, 0.0),
                  ("apataxia_cerithiiformis", 8.0, 27.4, True,  24, 0.0),
                  ("halichoeres_trimaculatus",18.8, 36.8, True,   6, 0.0)]},
  "R": {"deep":  [("xanthias_lamarckii",     36.8, 32.4, False,  0, 0.16)],
        "among": [("apataxia_cerithiiformis",31.6, 29.6, False, 18, 0.05),
                  ("trapezia_serenei",       33.6, 32.6, False,  0, 0.04)],
        "front": [("dascyllus_aruanus",      43.2, 23.8, True,   9, 0.0),
                  ("apataxia_cerithiiformis",43.0, 30.2, True, -14, 0.0),
                  ("apataxia_cerithiiformis",35.2, 36.4, False, 10, 0.0),
                  ("diala_albugo",           40.2, 28.2, True,  22, 0.0),
                  ("diala_albugo",           29.8, 33.4, False,-12, 0.0),
                  ("trapezia_serenei",       41.4, 34.8, True,   0, 0.0),
                  ("trapezia_serenei",       44.6, 27.8, False,  0, 0.0),
                  ("harpiliopsis_spinigera", 39.2, 37.2, True,   6, 0.0),
                  ("harpiliopsis_spinigera", 45.0, 33.2, True, -10, 0.0),
                  ("mitrella_moleculina",    29.6, 36.8, True, -16, 0.0),
                  ("pascula_muricata",       33.6, 26.8, False,  4, 0.0)]}}

for side, cx, tint in (("L", LX, COND_HI), ("R", RX, COND_LO)):
    sc = SCENE[side]
    out.append(f'<g id="{side}_panel">\n')
    out.append(coral(cx, CY, CW, "shadow", f"coral_{side}_shadow", tint=tint))
    out.append(f'<g id="{side}_deep">\n')
    for i, (tx, x, y, fl, rot, dp) in enumerate(sc["deep"]):
        out.append(animal(tx, x, y, f"{side}d{i}", fl, rot, dp))
    out.append('</g>\n')
    out.append(coral(cx, CY, CW, "bodies", f"coral_{side}_bodies", tint=tint))
    out.append(f'<g id="{side}_among">\n')
    for i, (tx, x, y, fl, rot, dp) in enumerate(sc["among"]):
        out.append(animal(tx, x, y, f"{side}a{i}", fl, rot, dp))
    out.append('</g>\n')
    out.append(coral(cx, CY, CW, "front", f"coral_{side}_front", tint=tint))
    out.append('</g>\n')
    out.append(f'<g id="{side}_front">\n')
    for i, (tx, x, y, fl, rot, dp) in enumerate(sc["front"]):
        out.append(animal(tx, x, y, f"{side}f{i}", fl, rot, dp))
    out.append('</g>\n')

# --- who lives there: one row of icons per treatment ------------------------
# The six species most characteristic of each treatment, named by occupancy
# (% of the 18 colonies per treatment holding them). Same taxa that populate
# the colony above, laid out so they can be told apart.
# Five taxa per group at 4.4 mm - a middle setting. Six at 3.5 mm were below
# useful resolution (the four pale shells read as one repeated shape); three at
# 5.6 mm lost too much of the community. Order alternates body plans so no two
# adjacent icons share a silhouette.
KEY = {"L": ["dascyllus_aruanus", "periclimenes_watamuae", "caracanthus_maculatus",
             "harpiliopsis_spinigera", "dascyllus_flavicaudus"],
       "R": ["apataxia_cerithiiformis", "trapezia_serenei", "diala_albugo",
             "xanthias_lamarckii", "mitrella_moleculina"]}
# rule between the colonies and the occupant key, matching the one above the
# condition row so the figure reads as three separated bands
out.append(f'<line x1="6.0" y1="42.6" x2="{W-6.0:.1f}" y2="42.6" '
           f'stroke="#e4e4e4" stroke-width="0.25"/>\n')
KEY_Y, KEY_PITCH, KEY_ICO = 47.0, 4.3, 4.0
for side, cx in (("L", LX), ("R", RX)):
    for i, tx in enumerate(KEY[side]):
        x = cx - 2.0 * KEY_PITCH + i * KEY_PITCH
        inner, vw, vh = load(os.path.join(ART, tx + ".svg"))
        sc = KEY_ICO / max(vw, vh)
        out.append(f'<g id="{side}_key{i}" transform="translate({x:.2f},{KEY_Y:.2f}) '
                   f'scale({sc:.5f}) translate({-vw/2:.1f},{-vh/2:.1f})">{inner}</g>\n')
out.append(text(LX, 50.8, "fishes and shrimp", 1.95, BLUE, "bold"))
out.append(text(RX, 50.8, "snails and crabs", 1.95, ORANGE, "bold"))

# --- coral condition ---------------------------------------------------------
out.append(f'<line x1="6.0" y1="53.2" x2="{W-6.0:.1f}" y2="53.2" '
           f'stroke="#e4e4e4" stroke-width="0.25"/>\n')
inner, vw, vh = load(os.path.join(ART, "pocillopora_colony.svg"))
CROW = 57.0
for cx, tint, label, col in ((LX, COND_HI, "good condition", BLUE),
                             (RX, COND_LO, "poor condition", ORANGE)):
    sc = 4.4 / max(vw, vh)
    out.append(f'<g transform="translate({cx-7.6:.2f},{CROW:.1f}) scale({sc:.5f}) '
               f'translate({-vw/2:.1f},{-vh/2:.1f})">{adjust(inner, **tint)}</g>\n')
    out.append(text(cx + 2.2, CROW + 0.7, label, 1.95, col, "bold"))

out.append('</svg>\n')

svg = os.path.join(HERE, "CAFI136_graphical_abstract.svg")
open(svg, "w").write("".join(out))
print("wrote", svg)
for fmt, extra in (("pdf", []), ("png", ["--dpi-x", "600", "--dpi-y", "600"])):
    subprocess.run(["rsvg-convert", "-f", fmt] + extra +
                   ["-o", svg.replace(".svg", "." + fmt), svg], check=True)
print("rendered pdf + png")

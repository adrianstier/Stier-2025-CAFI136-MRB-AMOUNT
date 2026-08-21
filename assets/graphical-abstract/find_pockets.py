#!/usr/bin/env python3
"""Locate the interstitial pockets in a traced coral colony.

The darkest tonal layer of the trace is the shadow between branches. Rasterise
just that layer, drop the perimeter outline, and the remaining interior blobs
are the places an occupant can sit and still peek out.

Prints pocket centroids and radii as fractions of the colony bounding box, so
they can be used directly as placement coordinates at any output size.
"""
import re, os, subprocess, tempfile
import numpy as np
from PIL import Image

HERE  = os.path.dirname(os.path.abspath(__file__))
CORAL = os.path.join(HERE, "art", "pocillopora_colony_vector.svg")
RES = 700


def layer_svg(which, path):
    s = open(CORAL).read()
    vb = re.search(r'viewBox="([\d.\s-]+)"', s).group(1).split()
    W, H = float(vb[2]), float(vb[3])
    tf = re.search(r'<g(\s+transform="[^"]+")>', s)
    tf = tf.group(1) if tf else ""
    keep = "".join(m.group(1) for m in
                   re.finditer(r'(<g id="(layer\d+)_\w+"[^>]*>.*?</g>)', s, re.S)
                   if m.group(2) in which)
    open(path, "w").write(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W:.0f}" height="{H:.0f}" '
        f'viewBox="0 0 {W:.0f} {H:.0f}"><g{tf}>{keep}</g></svg>')
    return W, H


def raster(svgpath, w):
    png = svgpath.replace(".svg", ".png")
    subprocess.run(["rsvg-convert", "-w", str(w), "-b", "white", "-o", png, svgpath], check=True)
    return np.asarray(Image.open(png).convert("L"))


def label(mask):
    """Tiny connected-component labeller (4-connectivity, union-find)."""
    h, w = mask.shape
    lab = np.zeros((h, w), np.int32); parent = {}
    def find(a):
        while parent[a] != a: parent[a] = parent[parent[a]]; a = parent[a]
        return a
    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb: parent[max(ra, rb)] = min(ra, rb)
    nxt = 1
    for y in range(h):
        for x in range(w):
            if not mask[y, x]: continue
            up = lab[y-1, x] if y and mask[y-1, x] else 0
            lf = lab[y, x-1] if x and mask[y, x-1] else 0
            if up and lf: lab[y, x] = min(up, lf); union(up, lf)
            elif up or lf: lab[y, x] = up or lf
            else: lab[y, x] = nxt; parent[nxt] = nxt; nxt += 1
    for y in range(h):
        for x in range(w):
            if lab[y, x]: lab[y, x] = find(lab[y, x])
    return lab


with tempfile.TemporaryDirectory() as td:
    dark_svg = os.path.join(td, "dark.svg")
    W, H = layer_svg({"layer2"}, dark_svg)
    dark = raster(dark_svg, RES)
    all_svg = os.path.join(td, "all.svg")
    layer_svg({"layer0", "layer1", "layer2"}, all_svg)
    body = raster(all_svg, RES)

    colony = body < 250                       # whole colony silhouette
    gaps = (dark < 150) & colony              # shadow between branches

    # erode once to drop the thin perimeter outline and branch edging
    e = gaps.copy()
    e[1:-1, 1:-1] &= gaps[:-2, 1:-1] & gaps[2:, 1:-1] & gaps[1:-1, :-2] & gaps[1:-1, 2:]
    for _ in range(2):
        p = e.copy()
        e[1:-1, 1:-1] &= p[:-2, 1:-1] & p[2:, 1:-1] & p[1:-1, :-2] & p[1:-1, 2:]

    lab = label(e)
    ys, xs = np.where(colony)
    y0, y1, x0, x1 = ys.min(), ys.max(), xs.min(), xs.max()
    bw, bh = x1 - x0, y1 - y0

    out = []
    for k in range(1, lab.max() + 1):
        m = lab == k
        n = int(m.sum())
        if n < 60: continue
        yy, xx = np.where(m)
        cy, cx = yy.mean(), xx.mean()
        r = float(np.sqrt(n / np.pi))
        out.append((n, (cx - x0) / bw, (cy - y0) / bh, r / bw))
    out.sort(reverse=True)
    print(f"colony bbox {bw}x{bh}px at {RES}px wide;  {len(out)} usable pockets\n")
    print(f"{'px':>6}  {'x_frac':>7} {'y_frac':>7} {'r_frac':>7}")
    for n, fx, fy, fr in out[:12]:
        print(f"{n:6d}  {fx:7.3f} {fy:7.3f} {fr:7.3f}")
    np.save(os.path.join(HERE, "pockets.npy"),
            np.array([(fx, fy, fr) for _, fx, fy, fr in out]))

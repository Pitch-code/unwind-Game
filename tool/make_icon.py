#!/usr/bin/env python3
"""Render Unwind's app icon and store art with no third-party libraries.

The sandbox has no imaging library and no network, so this draws everything by
hand (anti-aliased discs and round-capped segments over a radial-gradient
background) and encodes PNGs using only the standard library's zlib.

The motif ties the game together: a small plant whose stem and leaves are pins
joined by ropes — the untangle puzzle — topped by a bloom — the zen garden.

Outputs:
  assets/icon/ic_master.png        1024  full icon (launcher legacy + source)
  assets/icon/ic_foreground.png    1024  transparent, padded (adaptive fg)
  docs/store/icon-512.png           512  Google Play app icon
  docs/store/feature-graphic.png  1024x500  Play feature graphic
"""

import math
import os
import struct
import zlib

# ---- palette (matches the in-game colours) --------------------------------
BG_CENTER = (36, 64, 52)
BG_EDGE = (14, 26, 20)
ROPE = (111, 167, 144)
PIN = (143, 224, 192)
PIN_HI = (200, 245, 224)
BLOOM = (231, 197, 106)
BLOOM_HI = (247, 226, 150)
SHADOW = (0, 0, 0)

# ---- plant geometry in unit space (0..1, y downward) ----------------------
# A symmetric sprout: a central stem of pins with two mirrored pairs of leaves
# and a bloom on top. Symmetry is what makes it read as a plant, not a figure.
BASE = (0.50, 0.85)
N1 = (0.50, 0.635)  # lower stem node (carries the wide lower leaves)
N2 = (0.50, 0.44)   # upper stem node (carries the narrow upper leaves)
BLOOM_P = (0.50, 0.25)
LEAF_L1 = (0.255, 0.55)
LEAF_R1 = (0.745, 0.55)
LEAF_L2 = (0.33, 0.35)
LEAF_R2 = (0.67, 0.35)

ROPES = [
    (BASE, N1),
    (N1, N2),
    (N2, BLOOM_P),
    (N1, LEAF_L1),
    (N1, LEAF_R1),
    (N2, LEAF_L2),
    (N2, LEAF_R2),
]
# (point, radius-in-unit, is_bloom)
PINS = [
    (BASE, 0.032, False),
    (N1, 0.036, False),
    (N2, 0.036, False),
    (LEAF_L1, 0.030, False),
    (LEAF_R1, 0.030, False),
    (LEAF_L2, 0.028, False),
    (LEAF_R2, 0.028, False),
    (BLOOM_P, 0.078, True),
]
ROPE_W = 0.024  # unit half-width; scaled to pixels later


def _clamp01(v):
    return 0.0 if v < 0 else (1.0 if v > 1 else v)


class Canvas:
    def __init__(self, w, h):
        self.w = w
        self.h = h
        self.buf = [0.0] * (w * h * 4)

    def fill_radial(self, cx, cy, maxr, c0, c1):
        buf = self.buf
        w = self.w
        for y in range(self.h):
            dy = y - cy
            row = y * w * 4
            for x in range(w):
                dx = x - cx
                t = _clamp01(math.sqrt(dx * dx + dy * dy) / maxr)
                i = row + x * 4
                buf[i] = c0[0] + (c1[0] - c0[0]) * t
                buf[i + 1] = c0[1] + (c1[1] - c0[1]) * t
                buf[i + 2] = c0[2] + (c1[2] - c0[2]) * t
                buf[i + 3] = 255.0

    def _blend(self, x, y, color, cov):
        if cov <= 0:
            return
        if cov > 1:
            cov = 1.0
        i = (y * self.w + x) * 4
        b = self.buf
        ia = 1.0 - cov
        b[i] = color[0] * cov + b[i] * ia
        b[i + 1] = color[1] * cov + b[i + 1] * ia
        b[i + 2] = color[2] * cov + b[i + 2] * ia
        b[i + 3] = 255.0 * cov + b[i + 3] * ia

    def disc(self, cx, cy, r, color, aa=1.3, alpha=1.0):
        x0 = max(0, int(cx - r - aa))
        x1 = min(self.w - 1, int(cx + r + aa) + 1)
        y0 = max(0, int(cy - r - aa))
        y1 = min(self.h - 1, int(cy + r + aa) + 1)
        for y in range(y0, y1 + 1):
            dy = y - cy
            for x in range(x0, x1 + 1):
                dx = x - cx
                d = math.sqrt(dx * dx + dy * dy)
                cov = _clamp01((r - d) / aa) * alpha
                self._blend(x, y, color, cov)

    def segment(self, p1, p2, hw, color, aa=1.3):
        ax, ay = p1
        bx, by = p2
        x0 = max(0, int(min(ax, bx) - hw - aa))
        x1 = min(self.w - 1, int(max(ax, bx) + hw + aa) + 1)
        y0 = max(0, int(min(ay, by) - hw - aa))
        y1 = min(self.h - 1, int(max(ay, by) + hw + aa) + 1)
        vx, vy = bx - ax, by - ay
        vv = vx * vx + vy * vy or 1.0
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                t = ((x - ax) * vx + (y - ay) * vy) / vv
                t = _clamp01(t)
                px, py = ax + t * vx, ay + t * vy
                d = math.hypot(x - px, y - py)
                cov = _clamp01((hw - d) / aa)
                self._blend(x, y, color, cov)

    def to_png_bytes(self):
        w, h = self.w, self.h
        raw = bytearray()
        buf = self.buf
        stride = w * 4
        for y in range(h):
            raw.append(0)  # filter type 0
            base = y * stride
            for i in range(base, base + stride):
                v = buf[i]
                raw.append(0 if v < 0 else (255 if v > 255 else int(v + 0.5)))

        def chunk(typ, data):
            payload = typ + data
            return (
                struct.pack(">I", len(data))
                + payload
                + struct.pack(">I", zlib.crc32(payload) & 0xFFFFFFFF)
            )

        ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
        return (
            b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", ihdr)
            + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
            + chunk(b"IEND", b"")
        )


def draw_plant(cv, size, pad, with_bg):
    """Draw the plant into cv, mapping unit coords into a padded square."""
    span = size * (1 - 2 * pad)
    off = size * pad

    def m(pt):
        return (off + pt[0] * span, off + pt[1] * span)

    if with_bg:
        cv.fill_radial(size * 0.5, size * 0.42, size * 0.72, BG_CENTER, BG_EDGE)

    hw = ROPE_W * span
    # soft drop shadows first, for a little depth
    for pt, r, _ in PINS:
        mx, my = m(pt)
        cv.disc(mx, my + r * span * 0.35, r * span * 1.12, SHADOW, alpha=0.22)
    # ropes
    for a, b in ROPES:
        cv.segment(m(a), m(b), hw, ROPE)
    # pins, then highlights
    for pt, r, is_bloom in PINS:
        mx, my = m(pt)
        rp = r * span
        base_col = BLOOM if is_bloom else PIN
        hi_col = BLOOM_HI if is_bloom else PIN_HI
        cv.disc(mx, my, rp, base_col)
        cv.disc(mx - rp * 0.32, my - rp * 0.32, rp * 0.42, hi_col, alpha=0.9)


def write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)
    print(f"wrote {path} ({len(data)} bytes)")


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    master = Canvas(1024, 1024)
    draw_plant(master, 1024, 0.11, with_bg=True)
    write(os.path.join(root, "assets/icon/ic_master.png"), master.to_png_bytes())

    # Adaptive foreground: transparent, extra padding for the circular mask.
    fg = Canvas(1024, 1024)
    draw_plant(fg, 1024, 0.22, with_bg=False)
    write(os.path.join(root, "assets/icon/ic_foreground.png"), fg.to_png_bytes())

    store = Canvas(512, 512)
    draw_plant(store, 512, 0.11, with_bg=True)
    write(os.path.join(root, "docs/store/icon-512.png"), store.to_png_bytes())

    # Feature graphic: the plant centred on the gradient.
    feat = Canvas(1024, 500)
    feat.fill_radial(1024 * 0.5, 500 * 0.5, 660, BG_CENTER, BG_EDGE)
    span = 430
    off_x = 512 - 0.5 * span
    off_y = 250 - 0.55 * span  # unit y-centre of the plant is ~0.55

    def mf(pt):
        return (off_x + pt[0] * span, off_y + pt[1] * span)

    hw = ROPE_W * span
    for pt, r, _ in PINS:
        mx, my = mf(pt)
        feat.disc(mx, my + r * span * 0.35, r * span * 1.12, SHADOW, alpha=0.20)
    for a, b in ROPES:
        feat.segment(mf(a), mf(b), hw, ROPE)
    for pt, r, is_bloom in PINS:
        mx, my = mf(pt)
        rp = r * span
        feat.disc(mx, my, rp, BLOOM if is_bloom else PIN)
        feat.disc(mx - rp * 0.32, my - rp * 0.32, rp * 0.42,
                  BLOOM_HI if is_bloom else PIN_HI, alpha=0.9)
    write(os.path.join(root, "docs/store/feature-graphic.png"), feat.to_png_bytes())


if __name__ == "__main__":
    main()

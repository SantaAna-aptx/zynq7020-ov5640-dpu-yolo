#!/usr/bin/env python3
"""Check the colour balance of a captured RGB565 frame.

The live capture from the unified bitstream looked slightly green-cast. That can be benign (the
scene is a white-tiled wall under fluorescent light, and the OV5640's auto white balance needs a
moment to converge) or a real register problem. Pure R/B swap would show up as red<->blue, not
green, so the useful test is whether green dominates both other channels across the whole frame.

Usage: python check_colour.py <frame.raw> [width] [height]
"""
import sys
import struct

path = sys.argv[1]
w = int(sys.argv[2]) if len(sys.argv) > 2 else 1025
h = int(sys.argv[3]) if len(sys.argv) > 3 else 720
want = w * h * 2

data = open(path, 'rb').read()[:want]
n = len(data) // 2
print(f"file        : {path}")
print(f"bytes       : {len(data)}  pixels: {n}  ({w}x{h} expects {want})")

rs = gs = bs = 0
r_hi = g_hi = b_hi = 0
for i in range(0, len(data) - 1, 2):
    lo, hi = data[i], data[i + 1]
    v = lo | (hi << 8)                      # little-endian RGB565
    r = (v >> 11) & 0x1F
    g = (v >> 5) & 0x3F
    b = v & 0x1F
    # normalise to 8 bit so the channels are comparable
    r8, g8, b8 = r * 255 // 31, g * 255 // 63, b * 255 // 31
    rs += r8; gs += g8; bs += b8
    if r8 > r_hi: r_hi = r8
    if g8 > g_hi: g_hi = g8
    if b8 > b_hi: b_hi = b8

print(f"mean R/G/B   : {rs/n:6.1f} / {gs/n:6.1f} / {bs/n:6.1f}")
print(f"max  R/G/B   : {r_hi} / {g_hi} / {b_hi}")

# AWB quality: how far the cast is from neutral, and which way.
mean = (rs + gs + bs) / (3 * n)
print(f"deviation    : R {(rs/n-mean)/mean*100:+6.1f}%   G {(gs/n-mean)/mean*100:+6.1f}%   "
      f"B {(bs/n-mean)/mean*100:+6.1f}%")

# Bin the frame into grey-world patches: for a mid-brightness neutral wall the OV5640 AWB should
# hold R~=G~=B. A large green excess that survives across quadrants points at a register problem.
print()
print("per-quadrant mean R/G/B (a real cast is uniform, a scene artefact is not):")
for qy in range(2):
    row = []
    for qx in range(2):
        x0, x1 = qx * w // 2, (qx + 1) * w // 2
        y0, y1 = qy * h // 2, (qy + 1) * h // 2
        qr = qg = qb = qn = 0
        for y in range(y0, y1):
            base = (y * w + x0) * 2
            for x in range(x0, x1):
                off = base + (x - x0) * 2
                if off + 1 >= len(data):
                    break
                v = data[off] | (data[off + 1] << 8)
                qr += ((v >> 11) & 0x1F) * 255 // 31
                qg += ((v >> 5) & 0x3F) * 255 // 63
                qb += (v & 0x1F) * 255 // 31
                qn += 1
        row.append(f"({qr/qn:5.1f},{qg/qn:5.1f},{qb/qn:5.1f})")
    print("   " + "  ".join(row))

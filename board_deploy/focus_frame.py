#!/usr/bin/env python3
"""Render one captured frame and report a focus score.

Usage: focus_frame.py <raw> <png> <png_latest> <width> <height> [--swap-rb]

The score is the variance of the Laplacian over the green channel - the standard "how sharp is
this" measure. A blurry frame has almost no high-frequency content and scores low; a sharp one
scores high. It is only meaningful for comparing frames of the same scene, which is exactly the
situation when somebody is turning a lens in front of a fixed scene.

--swap-rb exchanges the red and blue channels. This camera sends BGR565, so the swap IS needed
while the PL still runs the old sensor register 0x4300 = 0x60; once the rebuilt bitstream with
0x4300 = 0x61 is loaded the data is true RGB and the swap must be left off.
"""
import sys
import numpy as np
from PIL import Image

args = [a for a in sys.argv[1:] if not a.startswith('--')]
swap_rb = '--swap-rb' in sys.argv
raw, png, png_latest, w, h = args[0], args[1], args[2], int(args[3]), int(args[4])

flat = np.fromfile(raw, dtype='<u2')
need = w * h
if flat.size < need:
    print('too few samples: %d < %d' % (flat.size, need))
    sys.exit(1)

mu = flat[:need].reshape(h, w).astype(np.uint16)
R = ((mu >> 11) & 0x1F) * (255.0 / 31)
G = ((mu >> 5) & 0x3F) * (255.0 / 63)
B = (mu & 0x1F) * (255.0 / 31)
if swap_rb:
    R, B = B, R

img = np.dstack([R, G, B]).astype(np.uint8)
Image.fromarray(img).save(png)
if png_latest != png:
    Image.fromarray(img).save(png_latest)

# Laplacian variance on the green channel: differences to the 4 neighbours.
g = G.astype(np.float32)
lap = (4.0 * g[1:-1, 1:-1] - g[:-2, 1:-1] - g[2:, 1:-1] - g[1:-1, :-2] - g[1:-1, 2:])
score = float(lap.var())
print('SCORE=%.1f  mean=%.1f  min=%d  max=%d  swap_rb=%s'
      % (score, img.mean(), img.min(), img.max(), swap_rb))

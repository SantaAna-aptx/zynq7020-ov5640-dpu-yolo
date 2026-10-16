#!/usr/bin/env python3
"""Measure the camera's true line width from a raw capture, then render it.

The frame_writer now stores the pixel stream contiguously (a rolling window), so the row
pitch in DDR is exactly the camera's real line length - which is not necessarily 1280.
Rendering at the wrong width produces diagonal streaking, so measure it first.

Usage:  measure_line_width.py <raw> [<png>] [lo] [hi]
"""
import sys
import numpy as np
from PIL import Image

raw = sys.argv[1]
png = sys.argv[2] if len(sys.argv) > 2 else None
lo = int(sys.argv[3]) if len(sys.argv) > 3 else 1180
hi = int(sys.argv[4]) if len(sys.argv) > 4 else 1380

flat = np.fromfile(raw, dtype='<u2').astype(np.float64)
n = flat.size
print('samples: %d' % n)

scores = []
for w in range(lo, hi + 1):
    h = n // w
    if h < 16:
        continue
    m = flat[:h * w].reshape(h, w)
    # adjacent rows of a correctly rasterised image are very similar
    c1 = np.corrcoef(m[:-1].ravel(), m[1:].ravel())[0, 1]
    scores.append((c1, w, h))

# Adjacent-row correlation alone cannot tell 1024 from 1025: a 1-pixel-per-row drift still
# leaves neighbours similar while the picture slowly shears. Also score how well the FIRST row
# matches a row far down the frame - a wrong pitch destroys that long-range agreement.
long_scores = {}
for c, w, h in scores:
    m = flat[:h * w].reshape(h, w)
    far = max(1, h - 1)
    long_scores[w] = np.corrcoef(m[0], m[far])[0, 1]

scores.sort(key=lambda t: (t[0] + long_scores[t[1]]) / 2.0, reverse=True)
print('\n=== ranked by (adjacent + long-range)/2 ===')
for c, w, h in scores[:8]:
    print('   width %4d : adjacent %+.4f  long-range %+.4f  -> %.4f'
          % (w, c, long_scores[w], (c + long_scores[w]) / 2.0))
scores.sort(reverse=True)
print('\n=== best 8 widths (row-to-row correlation) ===')
for c, w, h in scores[:8]:
    print('   width %4d (%4d rows) : %+.4f' % (w, h, c))

best_c, best_w, best_h = scores[0]
print('\nBEST: width=%d rows=%d corr=%+.4f' % (best_w, best_h, best_c))

if png:
    # Render ONE frame, not the whole buffer. The buffer is 1280x720 words but the camera's real
    # frame is (best_w x 720): rendering everything shows the rolling wrap and the next frame's
    # start as extra "tiles", which is what made the picture look pieced together.
    h = min(n // best_w, 720)
    m = flat[:h * best_w].reshape(h, best_w).astype(np.uint16)
    # The sensor emits BGR565, so swap red and blue to get true colour (verified on hardware:
    # the RGB reading turned a red bottle blue).
    R = (m & 0x1F) * (255.0 / 31)
    G = ((m >> 5) & 0x3F) * (255.0 / 63)
    B = ((m >> 11) & 0x1F) * (255.0 / 31)
    Image.fromarray(np.dstack([R, G, B]).astype(np.uint8)).save(png)
    print('saved %s (%dx%d)' % (png, best_w, h))

    # also render at 1280 for comparison
    alt = png.replace('.png', '_1280.png')
    if alt != png:
        h2 = n // 1280
        m2 = flat[:h2 * 1280].reshape(h2, 1280).astype(np.uint16)
        R = ((m2 >> 11) & 0x1F) * (255.0 / 31)
        G = ((m2 >> 5) & 0x3F) * (255.0 / 63)
        B = (m2 & 0x1F) * (255.0 / 31)
        Image.fromarray(np.dstack([R, G, B]).astype(np.uint8)).save(alt)
        print('saved %s (1280x%d) for comparison' % (alt, h2))

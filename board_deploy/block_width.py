#!/usr/bin/env python3
"""Find the true line width block by block.

A single global width search can be fooled: if the raster is a few pixels short per row the
whole picture shears, and some near-harmonic width can still score well overall. Splitting the
capture into blocks and measuring each one separately shows whether one width explains the
entire frame, and whether the alignment drifts with distance from the top.
"""
import sys
import numpy as np

raw = sys.argv[1] if len(sys.argv) > 1 else r'E:\yoloProject\board_deploy\frame_noseam.raw'
flat = np.fromfile(raw, dtype='<u2').astype(np.float64)
n = flat.size
print('samples: %d' % n)


def best_width(block, lo=900, hi=1400):
    best = (-2.0, 0)
    for w in range(lo, hi + 1):
        h = block.size // w
        if h < 8:
            continue
        m = block[:h * w].reshape(h, w)
        c = np.corrcoef(m[:-1].ravel(), m[1:].ravel())[0, 1]
        if c > best[0]:
            best = (c, w)
    return best


print('\n=== global ===')
for lo, hi in ((900, 1400), (400, 1100), (400, 2100)):
    c, w = best_width(flat, lo, hi)
    print('   range %4d..%4d -> width %4d  corr %+.4f' % (lo, hi, w, c))

print('\n=== blocks of 150k samples ===')
for i in range(0, n - 150000 + 1, 150000):
    c, w = best_width(flat[i:i + 150000])
    print('   block @%7d -> width %4d  corr %+.4f' % (i, w, c))

print('\n=== cumulative: does the best width drift as we add rows? ===')
w0 = best_width(flat, 900, 1400)[1]
print('   reference width from the global search: %d' % w0)
for rows in (50, 100, 200, 400, 800):
    need = rows * w0
    if need > n:
        break
    m = flat[:need].reshape(rows, w0)
    c = np.corrcoef(m[:-1].ravel(), m[1:].ravel())[0, 1]
    print('   first %4d rows at width %d : %+.4f' % (rows, w0, c))

print('\n=== does a per-row shear explain it? cross-correlate row 0 against row k ===')
w0 = 1025
m = flat[: (n // w0) * w0].reshape(-1, w0)
r0 = m[0] - m[0].mean()
for k in (1, 10, 50, 100, 200, 400):
    if k >= m.shape[0]:
        break
    rk = m[k] - m[k].mean()
    cc = np.correlate(rk, r0, 'full')
    lag = int(np.argmax(cc)) - (w0 - 1)
    print('   row %4d vs row 0 : best shift %+5d px' % (k, lag))

#!/usr/bin/env python3
"""Render one captured frame four ways so the correct colour interpretation is obvious.

The camera data reaches DDR as 16-bit words that this host reads little-endian. Two independent
things can be wrong, and both produce a plausible-looking but wrongly coloured picture:

  A  as-is                R = bits[15:11], G = bits[10:5], B = bits[4:0]
  B  R/B fields swapped   R = bits[ 4: 0], G = bits[10:5], B = bits[15:11]
  C  bytes swapped        swap the two bytes of every 16-bit word, then interpret as A
  D  bytes swapped + R/B  swap the bytes, then interpret as B

Whichever matches the real scene tells us whether to change the sensor's output byte order
(register 0x4300, whose low nibble selects it) or the host-side interpretation.

Usage: colour_variants.py <raw> <outprefix> [width] [height]
"""
import sys
import numpy as np
from PIL import Image

raw = sys.argv[1]
prefix = sys.argv[2]
w = int(sys.argv[3]) if len(sys.argv) > 3 else 1025
h = int(sys.argv[4]) if len(sys.argv) > 4 else 720

words = np.fromfile(raw, dtype='<u2')[: w * h].reshape(h, w)


def render(m, swap_rb):
    m = m.astype(np.uint16)
    if swap_rb:
        r5 = m & 0x1F
        g6 = (m >> 5) & 0x3F
        b5 = (m >> 11) & 0x1F
    else:
        r5 = (m >> 11) & 0x1F
        g6 = (m >> 5) & 0x3F
        b5 = m & 0x1F
    R = r5 * (255.0 / 31)
    G = g6 * (255.0 / 63)
    B = b5 * (255.0 / 31)
    return np.dstack([R, G, B]).astype(np.uint8)


swapped = ((words & 0x00FF) << 8) | (words >> 8)          # byte-swap every word

variants = [
    ('A_as_is',              words,   False),
    ('B_RB_swapped',         words,   True),
    ('C_bytes_swapped',      swapped, False),
    ('D_bytes_and_RB',       swapped, True),
]

for name, m, swap_rb in variants:
    img = render(m, swap_rb)
    out = '%s_%s.png' % (prefix, name)
    Image.fromarray(img).save(out)
    # mean of each channel is a cheap fingerprint of the interpretation
    print('%-18s mean R=%6.1f G=%6.1f B=%6.1f   -> %s'
          % (name, img[:, :, 0].mean(), img[:, :, 1].mean(), img[:, :, 2].mean(), out))

#!/usr/bin/env python3
"""Convert a raw RGB565 camera frame into a JPG the board's inference app can read.

The camera writes RGB565 (2 bytes/pixel, little-endian) into 0x08000000. The board's app reads
images with cv::imread, so the frame has to become a real image file first; that conversion is
done here on the PC because the board has no compiler and no image tooling.

Channel order note: the unified bitstream used for D4 is the colour-fixed build (register
0x4300 = 0x61), which makes the sensor emit true RGB565. Pass --swap-rb if a build with the old
0x4300 = 0x60 is loaded instead (that one lands BGR, which turned a red bottle blue).

Usage: raw565_to_jpg.py <raw> <jpg> [width] [height] [--swap-rb]
"""
import sys
import numpy as np
from PIL import Image

args = [a for a in sys.argv[1:] if not a.startswith('--')]
swap = '--swap-rb' in sys.argv
raw, out = args[0], args[1]
w = int(args[2]) if len(args) > 2 else 1025
h = int(args[3]) if len(args) > 3 else 720

words = np.fromfile(raw, dtype='<u2')
if words.size < w * h:
    print('ERROR: only %d samples, need %d' % (words.size, w * h))
    sys.exit(1)
m = words[: w * h].reshape(h, w)

R = ((m >> 11) & 0x1F) * (255.0 / 31)
G = ((m >> 5) & 0x3F) * (255.0 / 63)
B = (m & 0x1F) * (255.0 / 31)
if swap:
    R, B = B, R

img = np.dstack([R, G, B]).astype(np.uint8)
Image.fromarray(img).save(out, quality=92)
print('saved %s  %dx%d  swap_rb=%s  mean=%.1f' % (out, w, h, swap, img.mean()))

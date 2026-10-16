#!/usr/bin/env python3
"""Locate a cross compiler for the board's ARM hard-float target.

The board has no compiler of its own (no gcc/g++/cc), so a native closed-loop app must be built
on the PC. The existing tiny_yolo_image_diag4 is "ARM hard-float ELF", which means it was linked
with an arm-linux-gnueabihf toolchain. This looks in the places such a toolchain actually lives,
instead of scanning whole drives.
"""
import os
import glob

CANDIDATES = [
    r'C:\Xilinx',
    r'D:\Xilinx',
    r'E:\Xilinx',
    r'D:\vivado2019.1',
    r'E:\vivado2023',
    r'C:\petalinux',
    r'D:\petalinux',
    r'E:\petalinux',
    r'C:\Users\HP\.petalinux',
    r'E:\yoloProject\petalinux_projects',
    r'C:\Program Files\Xilinx',
    r'C:\Program Files (x86)\Xilinx',
]

PATTERNS = ['arm-linux-gnueabihf-g++*', 'arm-xilinx-linux-gnueabi-g++*',
            'arm-linux-gnueabi-g++*', '*-linux-gnueabihf-g++*']

found = []
for root in CANDIDATES:
    if not os.path.isdir(root):
        continue
    # depth-limited walk: toolchains sit a few levels down
    base_depth = root.rstrip('\\').count('\\')
    for dirpath, dirnames, filenames in os.walk(root):
        if dirpath.count('\\') - base_depth > 6:
            dirnames[:] = []
            continue
        for pat in PATTERNS:
            for f in glob.glob(os.path.join(dirpath, pat)):
                if os.path.isfile(f):
                    found.append(f)

print('=== candidate cross compilers ===')
if found:
    for f in found[:20]:
        print('   ', f)
else:
    print('    none found in the usual locations')

print()
print('=== SDK-like sysroots in petalinux_projects ===')
for base in (r'E:\yoloProject\petalinux_projects', r'E:\yoloProject'):
    if os.path.isdir(base):
        for d in os.listdir(base)[:25]:
            p = os.path.join(base, d)
            if os.path.isdir(p):
                marker = os.path.join(p, 'environment-setup-cortexa9hf-vfp-neon-petalinux-linux')
                if os.path.exists(marker):
                    print('    SDK at', marker)
print()
print('=== DNNDK ZedBoard package contents ===')
for sub in ('bin', 'lib', 'include', 'python'):
    p = os.path.join(r'E:\yoloProject\dnndk_v3.1\ZedBoard\pkgs', sub)
    if os.path.isdir(p):
        items = os.listdir(p)
        print('   %-8s %s' % (sub + ':', ', '.join(items[:12])))

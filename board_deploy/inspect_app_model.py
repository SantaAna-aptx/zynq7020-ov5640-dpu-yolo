#!/usr/bin/env python3
"""Analyse the working app binary to find out how the DPU model got inside it.

dpuLoadKernel("tiny_yolo") needs the compiled network somewhere. The board has no .elf file
anywhere, and the app is 9 MB, so the model is almost certainly embedded as a binary blob.
Knowing exactly how lets a new program embed it the same way.

Usage: python inspect_app_model.py <app-binary>
"""
import re
import struct
import sys

path = sys.argv[1]
data = open(path, 'rb').read()
print(f"file        : {path}")
print(f"size        : {len(data)} bytes")

# --- 1) ELF headers inside the file (an embedded model .elf) ---
print()
print("=== embedded ELF headers (\\x7fELF) ===")
offs = [m.start() for m in re.finditer(b'\x7fELF', data)]
print(f"count: {len(offs)}")
for off in offs[:10]:
    if off + 0x34 > len(data):
        continue
    ei_class = data[off + 4]
    ei_data = data[off + 5]
    e_machine = struct.unpack_from('<H', data, off + 18)[0]
    # e_shoff at 0x20 (32-bit), e_shnum at 0x30, e_shstrndx at 0x32
    e_shoff = struct.unpack_from('<I', data, off + 0x20)[0]
    print(f"  @0x{off:08X}  class={ei_class} endian={ei_data} machine=0x{e_machine:04X} "
          f"shoff=0x{e_shoff:X}")

# --- 2) interesting strings ---
print()
print("=== strings mentioning the kernel / model ===")
for pat in (b'tiny_yolo', b'dpu_tiny', b'.elf', b'kernel', b'dpuLoadKernel',
            b'_binary_', b'hineon', b'n2cube'):
    hits = [m.start() for m in re.finditer(re.escape(pat), data)]
    if hits:
        sample = []
        for h in hits[:4]:
            s = data[max(0, h - 24):h + 56]
            s = re.sub(rb'[^\x20-\x7e]', b'.', s).decode()
            sample.append(s)
        print(f"  {pat.decode():16s} {len(hits):5d} hits")
        for s in sample:
            print(f"      ...{s}...")

# --- 3) dynamic section hints: what does it link against? ---
print()
print("=== NEEDED libraries (from .dynstr) ===")
for m in re.finditer(rb'lib[\w.+-]*\.so[\w.]*', data):
    pass
libs = sorted(set(m.group(0).decode(errors='replace')
                  for m in re.finditer(rb'lib[\w.+-]*\.so[\w.]*', data)))
for l in libs[:40]:
    print("   " + l)

# --- 4) linker-defined binary blob symbols (objcopy -I binary creates these) ---
print()
print("=== objcopy-style blob symbols ===")
blob = sorted(set(m.group(0).decode(errors='replace')
                  for m in re.finditer(rb'_binary_[\w]+_(start|end|size)', data)))
if blob:
    for b in blob[:20]:
        print("   " + b)
else:
    print("   (none - model is not embedded via objcopy, or symbols were stripped)")

print()
print("=== .rodata-looking large blobs (candidate model payload) ===")
# DNNDK model ELFs are a few MB; report the largest runs of low-entropy binary after the ELF
if offs:
    first = offs[0]
    print(f"   first embedded ELF at 0x{first:X}; bytes from there to EOF: {len(data)-first}")

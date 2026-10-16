#!/usr/bin/env python3
# dump_frame.py -- copy the frame_writer's frame buffer (0x08000000, 1280x720 RGB565) to a file.
#
# Why not dd: with "mem=120M" the kernel's RAM ends at 120 MB and /dev/mem refuses read()
# beyond that, so `dd if=/dev/mem` returns 0 bytes. busybox devmem works because it uses mmap,
# and mmap may map physical addresses outside the kernel's RAM - so do the same from Python.
#
# A single 1.8 MB mapping hung the board, so this maps one small window at a time and prints
# progress after each window: if it ever hangs again, the last printed offset tells us the
# exact threshold.
import mmap, os, sys, hashlib

BASE  = 0x08000000
# The camera's real line is 1025 pixels, so one frame is 1025*720*2 = 1,476,000 bytes, not
# 1280*720*2. Dumping only what is needed shortens every grab, which matters for the live focus
# loop. Override with a second argument or the SIZE env var.
DEFAULT_H = int(os.environ.get('FRAME_H', 720))
DEFAULT_W = int(os.environ.get('FRAME_W', 1025))
SIZE  = int(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_W * DEFAULT_H * 2
CHUNK = int(os.environ.get('CHUNK', 65536))
OUT   = sys.argv[1] if len(sys.argv) > 1 else '/www/frame.raw'

fd = os.open('/dev/mem', os.O_RDWR)
data = bytearray()
try:
    off = 0
    while off < SIZE:
        n = min(CHUNK, SIZE - off)
        try:
            mm = mmap.mmap(fd, n, mmap.MAP_SHARED, mmap.PROT_READ, offset=BASE + off)
            data += mm[:]
            mm.close()
        except Exception as e:
            print("mmap failed at offset 0x%08X (%d bytes): %s" % (BASE + off, n, e))
            break
        off += n
        if (off % (CHUNK * 8)) == 0 or off >= SIZE:
            print("  %7d / %d bytes" % (off, SIZE))
finally:
    os.close(fd)

with open(OUT, 'wb') as f:
    f.write(data)
print("wrote %s (%d bytes) md5=%s" % (OUT, len(data), hashlib.md5(bytes(data)).hexdigest()))
if len(data) >= 16:
    print("first words: " + " ".join(data[i:i+4][::-1].hex() for i in range(0, 16, 4)))

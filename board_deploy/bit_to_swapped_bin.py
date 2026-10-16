#!/usr/bin/env python
"""Convert a Vivado .bit into the word-swapped .bin that Zynq's fpga_manager needs.

The kernel rejects a raw .bit ("could not find a sync word. Bitstream must be a byte
swapped .bin file"). Zynq's PCAP DMA expects every 32-bit word byte-reversed, e.g.
AA995566 -> 6655AA99.

Usage: python bit_to_swapped_bin.py <in.bit> <out.bin>
"""
import sys


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else \
        r"E:\yoloProject\vivado_projects\unified\unified.runs\impl_1\design_1_wrapper.bit"
    dst = sys.argv[2] if len(sys.argv) > 2 else \
        r"E:\yoloProject\board_deploy\design_1_wrapper_sw.bin"

    data = bytearray(open(src, "rb").read())
    # The .bit header must be dropped: PCAP needs the raw configuration stream.
    # A Vivado .bit starts with 0x00 0x09 0x0F 0xF0 0x0F 0xF0 0x0F 0xF0 0x0F 0xF0 ...
    # The FPGA bitstream itself begins at the 0xAA995566 sync word.
    sync = bytes([0xAA, 0x99, 0x55, 0x66])
    idx = data.find(sync)
    if idx < 0:
        print("ERROR: sync word AA995566 not found")
        return 1
    print(f"header={idx} bytes, payload={len(data)-idx} bytes")
    body = data[idx:]
    if len(body) % 4:
        body += b"\x00" * (4 - len(body) % 4)
    swapped = bytearray(len(body))
    for i in range(0, len(body), 4):
        swapped[i:i+4] = body[i:i+4][::-1]
    open(dst, "wb").write(bytes(swapped))
    print(f"wrote {dst} ({len(swapped)} bytes), first words: "
          + " ".join(f"{b:02X}" for b in swapped[:8]))
    return 0


if __name__ == "__main__":
    sys.exit(main())

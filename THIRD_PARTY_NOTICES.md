# Third-Party Notices

The original work in this repository is licensed under the **MIT License** (see [`LICENSE`](LICENSE)).

The files listed below are **third-party code** and are **not** covered by that licence.
All rights remain with their respective authors. They are kept in this repository only so
that the camera path can be reproduced end to end.

---

## 1. `rtl/I2C_OV5640_1280720_Config.v`

| | |
|---|---|
| Author | **CrazyBingo** — <https://www.cnblogs.com/crazybingo> |
| Header | `Copyright 2012, All Rights Reserved` |
| Purpose | OV5640 power-on register configuration table (720p RGB565, 252 entries) |
| Local changes | appended duplicate entries for `0x3820` / `0x3821` (the low three bits of `0x3820` differ from the reference design); `0x4300 = 0x61` was **kept unchanged** after measuring per-channel means (R 79.4 / G 91.8 / B 80.8 — R ≈ B rules out an R/B swap). See `skill/pitfalls/dvp-camera-bringup.md` section 3.10 for the register-table caveats, including a `LUT_SIZE` truncation that makes the highest-index entry unreachable |

⚠️ The original header additionally states `CONFIDENTIAL IN CONFIDENCE` — *"This confidential
and proprietary software may be only used as authorized by a license agreement."*
**No written redistribution permission has been obtained from the author.**

## 2. `rtl/i2c_timing_ctrl_reg16_dat8_wronly.v`

| | |
|---|---|
| Author | **CrazyBingo** |
| Purpose | SCCB/I2C timing controller (250 kHz master, 32-bit config word `{0x78, reg16, data8}`) |
| Local changes | SCL slowed to 33 kHz; SDA changed to open-drain; sticky-ACK output added |

⚠️ Carries the same `CONFIDENTIAL IN CONFIDENCE` header as item 1.

## 3. `rtl/asyn_fifo.v`

| | |
|---|---|
| Author | see the file header |
| Purpose | asynchronous FIFO |
| Local changes | none |

---

## If you intend to redistribute or use this commercially

For items 1 and 2 you must either obtain permission from the original author, or replace them
with your own implementation — an SCCB host controller plus an OV5640 register table written
from the sensor datasheet. Removing them does not affect the rest of the design, but the
camera capture path will not work without an equivalent replacement.

## Not distributed in this repository

The following are **not** included here and must be obtained from AMD:

- DNNDK v3.1 (`libn2cube`, `libdputils`, `libhineon`, `dnnc`, …)
- DPU TRD
- Vivado-generated IP wrappers and any other AMD/Xilinx proprietary IP source

The DPU model blob `board_deploy/deephi_rel.o` was extracted from a working on-board
application; see section 12 of [`README.md`](README.md) for provenance.

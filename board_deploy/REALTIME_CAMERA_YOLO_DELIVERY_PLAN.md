# 摄像头实时目标识别 —— 交付计划与当前状态

> 目标：MZ7X（xc7z020）上跑通 **OV5640 实时画面 + YOLOv3-tiny(DPU) 目标检测**，浏览器可看画面与检测框，
> 端到端 ≥4 FPS、延迟 <400 ms，上电自启动，1 小时长跑稳定。
> 本文档 = 交付计划 + 当前进度 + 待执行的实验队列。配套证据文档：`CAMERA_HANDOFF_20261010.md`

---

## 一、验收标准（DoD）

| # | 验收项 | 判定方式 |
|---|---|---|
| D1 | 摄像头采集通路可用 | VDMA `S2MM_DMASR` 错误位为 0、`FRMCNT` 持续递增、DDR 帧缓冲内容随画面变化 |
| D2 | 画面正确 | 导出整帧 → PNG，人眼确认场景/方向/颜色；遮挡镜头应显著变暗 |
| D3 | DPU 推理可用 | `devmem 0x40000000` = `0x0D9C13F1`；对 8 张标准答案图跑出与历史一致的结果（8/8 命中、`identical=1`）|
| D4 | 摄像头→推理闭环 | 命令行工具：抓一帧 → 推理 → 输出类别/框并保存带框图 |
| D5 | 实时性能 | 浏览器 M-JPEG 画面 + 检测框，≥4 FPS，手在镜头前晃动框跟随延迟 <400 ms |
| D6 | 产品化 | 断电重启自动进入服务（无需人工 SSH）；1 小时连续运行无崩溃/泄漏 |
| D7 | 归档 | 新 `.bit`/字交换 `.bin`/`BOOT.BIN`/应用源码/脚本/文档 |

---

## 二、当前状态（已完成且**已上板验证**的部分）

| 项 | 状态 | 证据 |
|---|---|---|
| 摄像头 RTL 6 处缺陷 | ✅ 已修 | SDA 开路漏极、tlast、tuser、AXIS 握手、FIFO 读死锁、**FIFO CDC 同步器接反时钟** |
| 时序收敛 | ✅ **本项目史上首次** | `WNS=+0.583 / WHS=+0.003 / TNS=THS=0`（交接前为 −7.0…−10.5 ns）|
| 摄像头活起来 | ✅ 上板实测 | MMCM 锁定=1、XCLK 门=1、SCCB ACK=1、PCLK 变化、`fifo_ovf=0` |
| 帧边界（SOF/tuser）| ✅ 上板实测 | `sof_seen=1`；SOF 速率实测 **≈30 次/秒 = 30 fps、每帧一次** |
| BD 存储通路 | ✅ 已补齐并 validate | `vdma S2MM → vdma_icc → HP3`；`dpu DATA0/1 → HP0/1`；`dpu INSTR → SmartConnect → HP2` |
| VDMA 视频寄存器写入卡死 | ✅ 已修 | 换成 `vdma_icc`（axi_interconnect）后 `VSIZE/HSIZE/STRIDE/FS1/FS2` 写入+回读正常 |
| 行结束改为确定性计数 | ✅ 已实现+仿真过 | tlast 固定在第 1280 个像素、每帧 720 行后停止；`cam_tb2` → `SIM_RESULT=PASS` |
| 上板 bring-up 可靠性 | ✅ 已大幅改善 | `lib_bringup.tcl`：DAP 自恢复 + 目标按名字解析 + 验证式停机 + PL 唤醒；连续 3/3 成功 |
| 字交换 .bin（fpga_manager 用）| ✅ 已生成 | `board_deploy/unified_cam_sw.bin`（同步字 66 55 99 AA ✓）|

## 三、当前唯一未解技术点

**VDMA 始终不提交帧**：`S2MM_DMASR = 0x00014811`（`ERR_INTERNAL` + `ERR_FSZ_MORE`），
`FRMCNT` 恒为 1，DDR 帧缓冲没有像素。已知：

* SOF 速率、行结束结构、AXIS 握手、连线、VDMA 的 `s2mm_tuser` 配置**都正确**；
* **错误位在 PL 配置完成后、软件还什么都没做时就已置位**（此时摄像头正在往"未启动的 VDMA"里推流）；
* 清错后再启动，错误在 2 s 内重新出现。

→ 最强假设：**VDMA 在"帧中途"启动**（我们启动它时摄像头早已在流），第一帧对齐不上，
错误一旦latch 就再难恢复。需要"启动 VDMA 早于摄像头出数据"的时序，或先让 VDMA 进入干净状态。

### 待执行实验队列（P1，按顺序，每步都有明确判定）

| 实验 | 做法 | 判定 |
|---|---|---|
| E1 | 预填帧缓冲为 `0xDEADBEEF` → 启动 S2MM → 回读 | 变成 `FFFFFFFF` = VDMA **确实在写**（只是数据全白）；仍是 `DEADBEEF` = 完全没写 |
| E2 | 复位后**先读回 SR 确认错误位已清零**，再启动 | 确认"清错"本身是否生效 |
| E3 | 在 PL 配置后**尽快**启动 VDMA（跳过 `pl_wakeup` 的等待，改为最小访问）| 若第一帧就干净 → 确认是"中途启动"问题 |
| E4 | 把 VDMA 换成简单 AXI-Stream FIFO/BRAM 从机，直接观察原始流结构 | 分离"流结构问题"与"VDMA 配置问题" |
| E5 | 核对 `S2MM_FRMSTORE(0x48)`（当前写 3 回读 0）与 `PARKPTR/WRTREF` | 循环模式必须有可用 frame store |

**E1 是最高优先级**——它一次性区分"没写"与"写了但全白（数据线问题）"。

---

## 四、后续阶段计划

### P2：把画面拿到手（预计 0.5 天，依赖 P1）

1. **板子启动链**：确认板上 Linux 启动镜像（QSPI/SD）能载入新比特流，且 FCLK0=50 MHz：
   * 路线 A（推荐）：JTAG 先载 bitstream，再让板子从 QSPI 启动 Linux（沿用项目原有的引导脚本）；
   * 路线 B：把新 bitstream 打进 `BOOT.BIN`（FSBL 载入），配合新 `.bit/.bin` 重新打包。
2. **上板抓帧**：复用 `capture_phase1.py` 的框架（串口/SSH + devmem + `dd if=/dev/mem`），
   改成我们的几何：`HSIZE=0x0A00`(1280×2B)、`VSIZE=0x02D0`(720)、三帧缓冲 `0x08000000/0x0A000000/0x0C000000`。
3. **导出 PNG**：`pull_frame.py` 把 `/dev/shm/F0.raw` 拉回 PC → `rgb565_to_png.py` 转 PNG → 人眼确认（D2）。
4. 若画面偏色/错位：调 RGB565 字节序/RGB 顺序（代码里预留 swizzle 开关）。

### P3：接 DPU 推理（预计 0.5 天）

1. 板上确认 DPU：`insmod dpu.ko` → `devmem 0x40000000` 应为 `0x0D9C13F1`。
2. 复用 `tiny_yolo_image_diag.cpp`（OpenCV + n2cube）：把"读 JPG"入口换成"读摄像头帧缓冲"：
   `mmap(/dev/mem, 0x08000000)` → RGB565→BGR888 → `cv::resize` 到 416×416 → 量化 int8 → `dpuRunTask` → NMS → 画框。
3. **门禁**：对着打印的标准答案图（kite.jpg 等）→ 输出类别与框正确（D3/D4）。
4. 性能：把历史 0.34 s 的 float resize 换成 `cv::resize`，目标单帧 ~175 ms。

### P4：实时闭环与交付（预计 1 天）

1. 主循环：抓帧 → 推理 → 画框 → M-JPEG 推流（Flask `multipart/x-mixed-replace`），双缓冲防撕裂。
2. 性能验收：≥4 FPS、延迟 <400 ms（D5）。
3. 产品化：应用装进 rootfs、rc5.d 自启动脚本（含"比特流已加载"与"insmod"两步），断电重启自动进入服务（D6）。
4. 长跑：1 小时无崩溃/无泄漏（`top` 观察）；归档 `.bit/.bin/BOOT.BIN/源码/脚本/文档`（D7）。

---

## 五、需要你配合的事项

| 事项 | 说明 |
|---|---|
| **给板子断电重启一次** | 当前 DAP 已硬卡死，JTAG 软件复位已无法恢复（必须物理断电）|
| 板子启动方式确认 | 现在板子从 QSPI 还是 SD 启动？启动到 Linux 的镜像是否就是你们已验证的那套（含 dpu.ko/DNNDK）？|
| 网络/串口 | 沿用原来的 COM10(115200) + 网口 192.168.1.50 即可 |

## 六、脚本/产物清单（本轮新增）

| 用途 | 文件 |
|---|---|
| 可靠上板库（自恢复） | `board_deploy/lib_bringup.tcl` |
| 抓帧验证（含预填模式判定） | `board_deploy/capture_v24.tcl`（E1）、`capture_v19.tcl`、`capture_v23.tcl`（CR 变体）|
| 调试字/帧率测量 | `board_deploy/diag_read.tcl`、`sof_rate.tcl` |
| 帧导出→PNG | `board_deploy/dump_frame.tcl` + `rgb565_to_png.py` |
| 字交换 .bin | `board_deploy/bit_to_swapped_bin.py` → `unified_cam_sw.bin` |
| BD 手术脚本 | `bd_mempath_v5.tcl`（补存储通路）、`bd_vdma_icc3.tcl`（换 vdma_icc）、`fixup_bd.tcl`（validate+generate）、`unlock_dpu.tcl`（解 IP 锁）|
| 重建脚本 | `rebuild_sda_oe_fix.tcl`（RTL）、`rebuild_mempath.tcl`（BD）|
| 仿真 | `rtl/cam_tb2.v`（`xsim cam_sim5` → `SIM_RESULT=PASS`）|

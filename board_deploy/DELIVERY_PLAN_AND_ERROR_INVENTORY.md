# 摄像头实时采集识别系统 —— 问题梳理、修复计划与交付方案

> ## ✅ 2026-10-12 里程碑：**采集通路打通，真实帧数据已写入 DDR**
>
> 按用户确认的方案 B，自研了轻量采集写入器 `rtl/frame_writer.v`（约 120 行）：
> 收 `m_axis` 16-bit 像素 → 每 4 个拼成 64-bit → 单拍 AXI4 写（AW/W/B）→ 直写 DDR；
> `tuser` 复位写指针（每帧从 `0x08000000` 开始）。**完全绕开 AXI VDMA**。
>
> BD 改动：删除 `axi_vdma_cam` + `vdma_icc`，新增 `frame_writer_0`：
> `cam_top/m_axis_video → frame_writer_0/s_axis`、`frame_writer_0/m_axi → ps7/S_AXI_HP3`，
> **整条链路统一跑 FCLK0（50 MHz）**（HP3 也从 clk_out1 改到 FCLK0），
> 地址 `0x00000000 + 512M → HP3 DDR`。
>
> 构建结果：**WNS +1.046 / TNS 0.000 / WHS +0.051 / THS 0.000**（去掉 VDMA 后时序余量明显变好）。
>
> 上板实测（板载 Linux + `busybox devmem`，串口）：
> ```
> W0=0x00600060  W4=0x00400041  W8=0x00400040  W12=0x00400040
> W16=0x00400040 W20=0x00200040
> MID=0x08410020  MID2=0x08410841        <-- 全是真实像素，不再是 DEADBEEF/FFFFFFFF ✓✓
> ```
> 即**摄像头 → 帧缓冲 的通路已经工作**。仿真 `fw_tb.v` 也 PASS（96/96 beat、数据/地址/AXI 握手全对，
> 含随机 ready 停摆）。
>
> **待办**：① 调试字显示 `fifo_ovf=1`（写入器偶发跟不上，单拍写需要改成 2 拍以上流水或加小缓冲）；
> ② 把整帧 `dd` 出来转 PNG 做视觉确认（板子网络 192.168.1.50 与 PC 同网段，SSH 密钥已装好）；
> ③ 之后接 DPU 推理与实时闭环。

> 目标：米联客 MZ7X（xc7z020）上 **OV5640 实时画面 + YOLOv3-tiny(DPU) 目标检测**，
> 浏览器可看画面与检测框，≥4 FPS，上电自启动（**板子当前从 QSPI 启动**）。
> 本文档 = ①错误全清单 ②当前唯一阻塞 ③修复步骤（带判定点）④QSPI 下的交付方案。
> 配套：`CAMERA_HANDOFF_20261010.md`（技术证据）、`REALTIME_CAMERA_YOLO_DELIVERY_PLAN.md`（DoD）

---

## 一、错误全清单（已定位的全部问题）

| # | 现象 | 根本原因 | 修复 | 状态 |
|---|---|---|---|---|
| 1 | 摄像头完全不通信（SCCB 无 ACK） | BD 把 `cmos_sda_oe` 接进 `IOBUF.T`（**高有效**三态），RTL 却写成"仅 ACK 槽驱动" → START/数据位全高阻 | `i2c_sdat_OE = i2c_sdat_out`（开路漏极写法） | ✅ 板上 `sccb_ack=1` |
| 2 | VDMA 永远看不到行结束 | EOL 在 `px_valid_w=0` 的拍置位，进不了 FIFO | 行尾与最后一个像素同拍 | ✅ 仿真+上板 |
| 3 | VDMA 每行都当新帧 | `tuser` 每行都发 | 改为每帧一次（`frame_on` 只由 VSYNC 清） | ✅ 仿真+上板 |
| 4 | 数据丢拍/AXIS 违例 | tready=0 时改数据、无背压 | 标准 AXIS 握手（`can_issue`/`rd_issued_r`） | ✅ 仿真验证含停摆 |
| 5 | 读指针死锁 | 修 4 时引入的 `head_ok` 门控 | 删除该死锁 | ✅ 自查发现 |
| 6 | `fifo_ovf=1`、丢像素、**且时序永不收敛** | `async_fifo_18b.v` 两条 CDC 同步链**接反时钟**（`wr_full` 由读域寄存器组合驱动 BRAM 写使能） | 交换同步器时钟域（v3） | ✅ `fifo_ovf=0`；时序首次收敛 |
| 7 | 时序 −7.0…−10.5 ns | 除 #6 外，DVP 输入约束缺 `-clock_fall`（OV5640 下降沿出数据），报 −3.04 ns 假 hold | `set_input_delay -clock_fall` | ✅ WNS/WHS 转正 |
| 8 | 抓不到帧（DDR 无像素） | **BD 里根本没有存储通路**：VDMA/DPU 的 M_AXI 全悬空 | 补 `vdma→vdma_icc→HP3`、`dpu DATA0/1→HP0/1`、`INSTR→SmartConnect→HP2` | ✅ validate 通过 |
| 9 | DPU 超频（300 MHz） | clk_out3 原为 300M | 改 100/100/200（与已验证工程一致） | ✅ |
| 10 | BD 无法 validate/generate | `design_1_dpu_eu_0_0` "IP contains locked subcore" 导致 BD 整体锁定；`IS_LOCKED` 只读 | `upgrade_ip` → 锁自动解除 | ✅ |
| 11 | 写 VDMA 视频寄存器（0xA0+）AP 卡死 | 单用 `axi_protocol_converter` 桥接 AXI4→AXI3 | 换成已验证工程同款 `vdma_icc`（axi_interconnect 1×1，内含 auto_pc） | ✅ 写入+回读正常 |
| 12 | **上板"时好时坏"**：DDR/PL 全部读回 FFFFFFFF、DAP 卡死 | **`ps7_init` 撞 xsdb 禁止访问的 DDR PHY 地址 `0xF8006078`**，把 PS 互连留在坏状态 | 新增 `ps7_init_safe.tcl`（只跳过 DDR PHY，DDR 已由 FSBL 初始化）；`halt_core` 自恢复；目标选择兼容 APU 容器/id 漂移；**PL 写必须 `mwr -force`** | ✅ 整链一次跑通 |
| 13 | PL 发出 bitstream 后无响应、时序 WNS −6.98/WHS −6.09 | ① 缺少工程自带的 `CLOCK_DEDICATED_ROUTE` 豁免（`rtl/clock_route_fix.xdc`：`clk_in1`/`FCLK_CLK0`，REQP-1578）；② 结果 placer **跳过某个 DPU 高扇出网络的 BUFG 插入**（`Place 46-33`），该网络走普通互连 → **7.5 ns 时钟插入偏斜** | 补齐三处豁免 + 用 **Explore** place/route 指令让 placer 放下 BUFG | ✅ **WNS +0.750 / WHS +0.051**（时序收敛），PL 全部从机可读 |
| 14 | VDMA 一启动就带错误位（`SR=0x00014811`） | 摄像头在 VDMA 未启动时持续灌流，错误位一旦 latch 就清不掉（通道复位也不清，帧计数由输入流驱动） | cam_top 上电静默窗口 **11→130 帧（≈4.3 s）**，让软件先启动 S2MM | ✅ VDMA 启动后 `SR=0x00010000`、**err=000** |
| 15 | **（当前唯一未解）** 摄像头开始出流后 VDMA 报 `DMAIntErr+FSZ_MORE(SOF LATE)`，帧永不提交 | **软件侧**：CR 的 **Fsync Source Select**（bit[6:5]）没设！S2MM 用 tuser 同步时驱动要 `CrBits \|= 0x40`（`xaxivdma.c: case XAXIVDMA_S2MM_TUSER_FSYNC`），我们一直写 `0x00010013`（bit6=0）→ VDMA 去听**没有连接的 `s2mm_fsync` 端口** → 永远等不到帧同步 → "SOF LATE" | 正确 CR = `0x00010013 \| 0x40 = 0x00010053` | ⚠ **已修但在板上仍未提交帧**（见 #16） |
| 16 | 同上：VDMA 看不到 tuser | **BD 连线**：`cam_top/m_axis_video_tuser` 在 BD 里是一个**独立的、未连接的引脚**（接口 `m_axis_video` 只带 tdata/tlast/tvalid/tready）→ VDMA 的 `s_axis_s2mm_tuser` 什么都没收到 | **已显式连接**：`connect_bd_net cam_top/m_axis_video_tuser axi_vdma_cam/s_axis_s2mm_tuser`（BD 接受并覆盖接口连接）；同时重建了 cam_top 的 module reference（原先它已无法解析 `ov5640_cam_top`，导致构建直接失败）| ✅ 生成网表已确认出现独立网络 `cam_top_m_axis_video_tuser`；新比特流 **WNS +0.750 / WHS +0.051**，待上板复验 |
| 17 | PL 写偶发 `Memory write aborted. Fault status 0x8` | DAP 访问端口状态不干净 | 实测规律：**先做一次 DDR（PS 侧）访问，再做 PL 写**；仍偶发时用 `force_recover` + 重新载流 | ✅ 有可行序列 |
| 18 | 构建报 `Nothing was found in the project to match 'ov5640_cam_top'` | 早前的 `update_module_reference` 破坏了 module reference | 删除并重建 cam_top 单元（`delete_bd_objs` + `create_bd_cell -type module -reference`）+ 重新关联 RTL + 重新连线 | ✅ 构建恢复 |
| 19 | post-route physopt（hold fix）跑飞 | 实测把 WHS 从 −0.373 恶化到 −6.996 并卡死 1–2 h | 迭代用 `rebuild_fast/rebuild_quick.tcl`（关掉该 step）；最终用 **Explore** 收敛 | ✅ 规避 |

---

## 二、当前唯一阻塞（#15）的证据链

### 2.4 【最新进展 2026-10-12】两条路线都试过了，结论如下

| 路线 | 结果 |
|---|---|
| **A. tuser 帧同步**（`C_USE_S2MM_FSYNC=2` + CR=`0x00010053`）| **时序干净（WNS +0.750 / WHS +0.051）✓，PL 完全正常 ✓，摄像头出流 ✓（`sof_seen=1`）——但 VDMA 仍报 `err=081 (SOF LATE)`、`frmcnt` 恒为 1、DDR 0 像素 ✗**。已确认：tuser 引脚已在 BD 里显式连接（生成网表出现独立网络 `cam_top_m_axis_video_tuser`）✓、板上加载的 .bin md5 与本地一致（`5db9fb...092`）✓、CR 的 fsync 源已按驱动设成 tuser ✓ —— 但这个 IP 实例就是不认 |
| **B. 自由运行**（`C_USE_S2MM_FSYNC=0` + `SOF=0`）| 功能上本应最稳（完全不依赖 tuser，按 VSIZE 行数分帧），**但该配置始终无法通过时序**：Explore 指令下路由到 `WHS −7.100 / THS −4801`（确定性复现），Quick 指令下 `WNS −7.198 / WHS −5.015` ✗ → 下到板上 **PL 是死的**（一读 `0x41220000` 就把 PS 挂死）✗ |

> 期间查明：B 路线叠加 hold 灾难的一个直接原因是 —— 切到 `FSYNC=0` 后那条显式 tuser 连线
> 变成**悬空网络** ✗。删掉后路由立刻从 `WHS −7.100` 回到 `WHS −0.374`（正常收敛曲线）✓；
> 但 B 路线最终的 `WNS −7.198` 仍不过，说明该配置本身还有别的问题（待查）。

### 2.5 下一步（二选一）

**已排除的路线**：自由运行（`C_USE_S2MM_FSYNC=0`）在功能上最理想，但该配置**根本无法通过时序**
（Explore 下路由到 `WHS −7.100`，Quick 下 `WNS −7.198 / WHS −5.015`）→ 下板后 PL 是死的 ✗。
把 DPU 时钟从 200 降到 150 MHz 也没能改变这个结果。**该 IP 在 fsync=0 模式下的网表有问题，此路不通。**

**剩下两条**：

| 路线 | 做法 | 代价/风险 |
|---|---|---|
| **A. 用专用 `s2mm_fsync` 端口** | BD 改 `C_USE_S2MM_FSYNC=1`（该模式用**专用 fsync 引脚**而不是 tuser）；RTL 里增加一个输出 `s2mm_fsync`（每帧第一个像素处拉高，即现有的 `px_sof_w`），接过去；CR 里 fsync 源选"同通道 fsync"（bit6=0, bit5=0）| 1 次重建（~20 min）。风险：该模式同样没试过，可能又有新怪癖 |
| **B. 自研轻量采集写入器**（推荐）| 约 150 行 RTL：收 `m_axis` 16-bit 像素 → 每 2 个拼成 32-bit → 一个小 **AXI4 主机**（AW/W/B 通道，突发写）直接把行/帧写进 DDR（SOF 复位地址、VSYNC 换缓冲）。接到现有的 HP3 端口（`vdma_icc` 或直接 `ps7/S_AXI_HP3`），把 VDMA 整个换掉 | 0.5–1 天。**好处：彻底不依赖这个 IP 的任何 fsync/tuser 语义**，而摄像头数据流已被硬件验证是确定性的 1280×720 ✓ |

> 已有可用的干净比特流与产物（都存好了）：
> * `board_deploy/bit_tuser_connected.bit`：**时序干净（WNS +0.750 / WHS +0.051）**、PL 全部从机可读、
>   摄像头实测出流（`sof_seen=1`）—— 唯一缺陷是 VDMA 不认 tuser
> * `board_deploy/unified_tuser_fixed_sw.bin`：上者的字交换版（已在板上验证 md5 一致）
> * 上板流程脚本：`board_capture_flow.ps1`（串口安装 SSH 密钥 → scp 上传 → fpga_manager 载流 →
>   PL 复位 → 用 devmem 配 VDMA → 判定），`serial_cmd.ps1`（串口命令）

---

## 二·旧、采集阻塞的原始证据链

**已确认全部正确**：
* 摄像头：`mmcm_locked=1`、XCLK 门=1、`sccb_ack=1`、`fifo_ovf=0`
* 帧边界：`sof_seen=1`；**实测 SOF ≈30 次/秒 = 30 fps、每帧正好一次**（`sof_rate.tcl`）
* 行结束：确定性计数，`tlast` 固定在第 **1280** 个像素（`cam_tb2` → `SIM_RESULT=PASS`）
* AXIS 握手 / BD 连线（生成 HDL 已核对 `s_axis_s2mm_tuser` 已连）
* VDMA 配置：`C_USE_S2MM_FSYNC=2`(s2mm_tuser)、`C_S2MM_SOF_ENABLE=1`、`NUM_FSTORES=3`
* VDMA 启动干净：`SR=0x00010000`、`err=000`（静默窗口修复生效）
* DDR 通路：预填 `0xDEADBEEF` 可读回

**现象**：t=2 s 时 `err=000`；t=4 s（摄像头开始出流，`sof_seen=1`）后 `err=081`
（`DMAIntErr(bit4) + FSZ_MORE(bit11)`），`FRMCNT` 恒为 1，DDR 中 128/128 个字**仍是预填模式**。

**✅ 已判定（`vdma_fsync_probe.tcl`，2026-10-11）**：把 **VSIZE 设为 1**（tuser 模式下"一帧=1 行"，
只要看到一次 tuser 就该立刻提交一帧）后：

```
=== VSIZE=1 ===
  poll0 SR=00010000 err=000 | sof_seen=0     <- 摄像头还在静默窗口，干净
  poll1 SR=00014810 err=081 | sof_seen=1     <- 摄像头一出流立刻报错
  poll2/3 同上，frmcnt 恒为 1，ioc=0，DDR 0 像素
```

**→ VDMA 根本没有收到 tuser**（否则 VSIZE=1 时每帧都会提交）。行尾 tlast 是有的
（`line_in_frame` 在动、无 LSZ 错误），所以问题**仅在 tuser 这一根线**。

**两个已定位的直接原因**（都在这一轮查明，见 #15/#16）：
1. **软件**：CR 的 fsync 源必须选 tuser → `CR = 0x00010053`（bit6=1）。已修。
2. **BD**：`cam_top.m_axis_video` 接口**没有 `HAS_TUSER`** 属性 → 接口连接不携带 TUSER。
   生成 HDL 里虽有同名 wire，但 VDMA 实际收不到。

**P1 收尾计划（下一步执行，按顺序）**：

1. **给板子断电重启**（当前板载 Linux 已无串口响应，JTAG 也枚举不出 A9 核，软件复位无效）
2. 板子起来后，**一条命令完成验证**：
   ```
   powershell -File E:\yoloProject\board_deploy\capture_via_linux.ps1
   ```
   它做三件事：JTAG 载入 `bit_tuser_connected.bit`（含 tuser 修复 + 时序收敛）→ 从串口用
   `busybox devmem` 脉冲 PL 复位（重启 cam_top 的 SCCB 配置与静默窗口）→ 用 **CR=0x00010053**
   启动 S2MM 并读回 `SR` 与帧缓冲。
3. **判定**：
   * `SR` 的 `frmcnt` 递增（`=2,3,4…`）、`err=000`、`W0/W4…` 不再是 `0xDEADBEEF` → **采集通了** ✓
     → 接着 `dd if=/dev/mem` 拉整帧 → PC 侧 `rgb565_to_png.py` 出 PNG → 人眼确认
   * 仍 `err=081` → 说明该 IP 的 tuser 语义仍有问题 → 走下面的自由运行方案
4. **兜底（已可构建，因为 module reference 已修好）**：BD 里把 `C_USE_S2MM_FSYNC=0`、
   `C_S2MM_SOF_ENABLE=0`（自由运行：完全不依赖 tuser，按 VSIZE 行数分帧），用
   `rebuild_explore.tcl` 重建。注意该配置历史上出现过 hold 问题（WHS −7.1），需要 Explore 指令
   并确认 `Post Routing Timing Summary` 的 WHS 为正。

> **重要操作规律（本轮踩坑换来，务必遵守）**
> * **不要再用 JTAG 载流**：实测两次，`fpga -f` 在 Linux 运行期间会让 PS 挂死（A9 核不再枚举、
>   串口无响应、网络不可达，只能断电）。改用 **Linux 的 fpga_manager** 载流（这也是最终产品的做法）：
>   `echo cam.bin > /sys/class/fpga_manager/fpga0/firmware`（文件是**字交换**的 .bin，
>   `bit_to_swapped_bin.py` 生成；同步字应为 `66 55 99 AA`）
> * 所有寄存器读写都从**板载 Linux**（串口 + `busybox devmem`）做 —— DAP 的 PL 写路径既不稳定
>   （`Fault status 0x8`）又会打挂 AP；Linux 的写入是普通内存访问，稳定可靠
> * 摄像头出图需要 **XCLK/MMCM 就绪 + SCCB 配置完成 + 静默窗口（130 帧≈4.3 s）**；
>   若 `devmem 0x41220000` 的 bit3（`sof_seen`）为 0，先脉冲一次 PL 复位（`0xF8000240` = 0xF→0）
> * FCLK0 必须 50 MHz（`0xF8000170` 读回 `0x00400500`），否则要按 SLCR unlock 序列写
> * 板子 IP `192.168.1.50`，root 可登录；已生成密钥 `board_deploy/board_key`，
>   用 `board_capture_flow.ps1 -InstallKey` 一次装入即可用 scp 快速传文件

**兜底方案（按代价从低到高，已按推荐顺序排好）**：

| 方案 | 做法 | 代价 |
|---|---|---|
| **(a) 自由运行模式**（推荐先试） | BD 把 `C_USE_S2MM_FSYNC=0`、`C_S2MM_SOF_ENABLE=0`：VDMA 完全按 VSIZE 行数分帧、不依赖 tuser；我们的流是确定性 1280×720，天然吻合。**注意**：该配置上次路由出现 hold 问题（WHS −7.1）→ 必须配 `rebuild_explore.tcl`；若仍不收敛，给 `s_axis_s2mm` 路径加 `set_max_fanout` 或改用 `-directive AlternateCLBRouting` | 1 次重建（~20 min） |
| (b) ILA 观测 | 在 BD 里加 `system_ila` 挂在 `s_axis_s2mm_tuser/tvalid/tready/tlast` 上，直接看该信号在实现后有没有按帧翻转 | 1 次重建 + 上板 |
| **(c) 自研轻量采集写入器**（最可控） | 约 150 行 RTL：`m_axis` 收像素 → 每 2 个 16-bit 拼成 32-bit → 用一个小 AXI4 主机突发写入帧缓冲（SOF 复位地址、VSYNC 换缓冲）。**彻底摆脱 VDMA 的 fsync/tuser 语义**，只需一个 AXI 主机 + 现有的 HP 端口 | 0.5–1 天，但之后不会再被 VDMA 的任何怪癖卡住 |

> 注：已核实**生成网表里 tuser 是连着的**（`design_1.v`：`.s_axis_s2mm_tuser(cam_top_m_axis_video_TUSER)` ←
> `.m_axis_video_tuser(cam_top_m_axis_video_TUSER)`），BD 里 `cam_top/m_axis_video_tuser` 引脚也存在；
> 只是接口元数据缺 `HAS_TUSER`（重连接口、`update_module_reference`、`set_property CONFIG.HAS_TUSER` 均未能改掉它）。
> 所以"tuser 到底有没有被 VDMA 采到"只剩 ILA 或换方案两条路。

---

## 三、修复步骤（带判定点）

### P1 采集通路（当前阶段）

| 步骤 | 做法 | 判定 |
|---|---|---|
| **P1.1** | 跑 `vdma_fsync_probe.tcl`：**VSIZE=1** 启动（tuser 模式下一帧=1 行） | `FRMCNT` 快速上涨 + DDR 出现像素 → **tuser 正常**（排除 A）；完全不动 → **tuser 没到 VDMA**（A 成立） |
| **P1.2** | 若 A 成立：核对 `s_axis_s2mm_tuser` 到 VDMA 的**实际网表**连接（生成 HDL + `report_net`），并检查 VDMA 的 `C_S2MM_SOF_ENABLE` 是否真的生效（读 `0x43010048` 等） | 定位后修 BD/RTL |
| **P1.3** | 若 B 成立：把调试字改成"**每帧 tlast 计数**（饱和）"重建，实测两帧之间到底多少行 | 数值应为 720；若远超，定位多发行尾的位置 |
| **P1.4** | 若 C 成立：核对 HSIZE（我们的流是 16-bit、1280 像素/行 = **2560 字节**）与 VDMA 的位宽解释 | LSZ 错误位应出现 |
| **P1.5** | 兜底方案：把 VDMA 改为**自由运行**（`C_USE_S2MM_FSYNC=0`，不依赖 tuser，纯按 VSIZE 行数分帧）——注意该配置上次路由出现 hold 问题，需用 Explore 指令重建 | `FRMCNT` 递增 + DDR 出像素 |
| **P1.6** | 出图验收：`dump_frame.tcl` 拉整帧 → `rgb565_to_png.py` → 人眼确认（遮挡镜头应变暗） | PNG 正确 |

> 关键工具已就绪：`capture_v28.tcl`（含 PL 写预热，顺序敏感：**PL 写必须早于 DDR 访问**）、
> `vdma_fsync_probe.tcl`、`dump_frame.tcl`、`rgb565_to_png.py`、`lib_bringup.tcl`

### P2 板上软件栈（QSPI 启动）

板子从 **QSPI** 启动（BOOT.BIN + `image.ub` + rootfs，含 DNNDK：`dpu.ko`、`libn2cube`、
`libhineon`、`tiny_yolo_image` 已验证 8/8 命中）。

| 步骤 | 做法 |
|---|---|
| **P2.1** | **开发期快速验证**：板子正常从 QSPI 启动进 Linux → 通过 JTAG `fpga -f <新.bit>` 覆盖 PL → `insmod dpu.ko` → `devmem 0x40000000` 应为 `0x0D9C13F1` |
| **P2.2** | **FCLK0=50 MHz**：新设计的 camera ACLK 依赖 50 MHz。开发期用 `ensure_fclk0_50mhz`（SLCR 直写）或 `ps7_init_safe` + 时钟写；**交付期必须在 FSBL/BOOT.BIN 里把 FCLK0 做成 50 MHz**（否则上电默认 15.625 MHz） |
| **P2.3** | 抓帧程序：板上 `onboard_grab.py`（mmap `/dev/mem` @0x08000000 → RGB565→BGR → PNG）或 C 版本 |
| **P2.4** | 接推理：把 `tiny_yolo_image_diag.cpp` 的输入从"读 JPG"换成"读摄像头帧缓冲"，`cv::resize` 到 416×416 → `dpuRunTask` → NMS → 画框 |
| **P2.5** | **门禁**：对 8 张标准答案图跑出与历史一致结果（8/8、`identical=1`） |

### P3 实时闭环与性能

| 步骤 | 做法 | 目标 |
|---|---|---|
| **P3.1** | 主循环：抓帧 → 推理 → 画框 → M-JPEG 推流（`multipart/x-mixed-replace`），双缓冲防撕裂 | ≥4 FPS |
| **P3.2** | 性能优化：把历史 0.34 s 的 float resize 换成 `cv::resize`；DPU 输出解析只算必要节点 | 单帧 ~175 ms |
| **P3.3** | 延迟测量：手在镜头前晃动，检测框跟随 <400 ms | DoD |

### P4 交付与验收

| 步骤 | 做法 |
|---|---|
| **P4.1** | **QSPI 交付镜像**：用 FSBL + 新 bitstream 重打 `BOOT.BIN`（含 FCLK0=50M 设置），连同 rootfs/应用烧回 QSPI；上电即进入服务 |
| **P4.2** | 自启动：`rc5.d` 脚本（载 bitstream 若需 / `insmod dpu.ko` / 启动 M-JPEG 服务） |
| **P4.3** | 1 小时长跑（无崩溃/无泄漏）+ 端到端验收（D1–D7） |
| **P4.4** | 归档：`.bit` / 字交换 `.bin` / `BOOT.BIN` / 应用源码 / 全部脚本 / 文档 |

---

## 四、回退方案（若 P1 迟迟不通）

已验证工程 `vivado_projects/yoloproject` 的 **DPU 通路是通的**（8/8 命中），只有摄像头采集是坏的。
若 unified 的 VDMA 迟迟修不通，可把本轮修好的摄像头 RTL 用一个薄封装适配回 yoloproject
（其摄像头 IP 需要旧端口表：`inout cmos_sda`、无 `dbg_*`、ACLK 100 MHz），代价约 0.5–1 天。

---

## 五、当前环境备忘（每次上板必读）

1. **不要跑 `ps7_init`** → 用 `ps7_init_safe`（`ps7_init` 会撞 `0xF8006078` 打挂 PS 互连）
2. **PL 写必须 `mwr -force`**；且**第一次 PL 写要早于任何 DDR 访问**（否则 AP 卡死）
3. 目标 id/名字会漂移（`targets 2` 可能是 FPGA！）→ 用 `select_a9` 按列表解析
4. `halt_core` 自带自恢复（DAP `rst -system`/`-srst` 轮试）；卡死到无法恢复时**给板子断电重启**
5. 迭代构建：`rebuild_explore.tcl`（关 physopt + Explore 指令，15–20 min，时序收敛）
6. XDC 三处 `CLOCK_DEDICATED_ROUTE FALSE` 缺一不可（`cmos_pclk_IBUF` + `clk_in1` + `FCLK_CLK0`）

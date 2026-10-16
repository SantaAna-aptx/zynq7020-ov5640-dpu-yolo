# OV5640 摄像头移植 —— 上板接管报告

> 接手来源：MiniMax Code 会话 `mvs_074852fcbb98401ba349d39161e04a2d`
> （由 ZCode 会话「Fork of YOLO验证摄像头」迁移而来）
> 接手时间：2026-10-09 22:00 → 2026-10-10 13:40
> 平台：米联客 MZ7X（xc7z020clg400-2），工程 `vivado_projects\unified`

---

## 摘要（一句话）

**摄像头已经修活并在板上验证；工程里另外两个结构性缺陷（BD 完全没有存储通路、以及整份设计从来没满足过时序）也一并定位并修复，
时序首次收敛（WNS=+0.538 / WHS=+0.018 ns）；当前唯一剩余阻塞是"给 VDMA 写完视频寄存器后 AXI 卡死"，已定位到与新增的 VDMA→HP3 数据通路有关。**

---

## 0. 接手时的状态

| 项目 | 状态 |
|---|---|
| MiniMax 会话最后一个动作 | 「Force rebuild including cam_top IP」成功（21:11:16） |
| 比特流 | `vivado_projects\unified\unified.runs\impl_1\design_1_wrapper.bit`（21:11:05） |
| 交接时待办 | 上板读取打包调试位，判定 MMCM 锁定 / XCLK / PCLK |
| 会话期间已修的三处 | BD 里 SDA 被常 0 IOBUF 短接、PL I2C 引擎 ACK 期间推挽驱动、cam_top MMCM 输入超规格、`reset_run synth_1` 不重跑 OOC IP |

会话结束后（21:18–21:33）曾有人尝试上板，但 DAP 已卡死（`0x30000021`），未取得数据。

---

## 1. 本轮定位并修复的 5 个真实缺陷

### 缺陷 1（根因）：SCCB 的 SDA 三态极性反了 —— 摄像头从来没有收到过任何一条命令

* BD 接线：`cam_top/cmos_sda_oe` → `sda_iobuf/T`，而 `IOBUF.T` 是**高有效三态**（T=1 高阻，T=0 驱动）；
* 原 RTL：`assign i2c_sdat_OE = bir_en ? 1'b0 : 1'b1;`
  → 只在 4 个 ACK 槽驱动总线（还驱动成高电平），**START 条件和全部数据位都处于高阻**；
* 结果：SCL 在动、SDA 从不拉低，OV5640 收不到任何寄存器写入，`i2c_config_done` 却因为 ACK 校验被注释掉而照样置 1（假完成）；
* 修复（与老师的 `uii2c.v` 用法一致，`.I(sda_o)` / `.T(sda_o)`）：

```verilog
assign i2c_sdat_OUT = i2c_sdat_out;
assign i2c_sdat_OE  = i2c_sdat_out;   // 0→拉低，1→释放（开路漏极）
```

* 同时加了 sticky ACK 观测位，让「传感器到底答没答」变成可读的 1 bit。

### 缺陷 2：cam_top 从未发出 AXI-Stream 的 `tlast`

* 原 RTL 在 HREF 拉低的**那一拍**置 `px_eol_w`，但同一拍 `px_valid_w = 0` → 不满足 `fifo_wr`，**EOL 标志永远进不了 FIFO**；
* 后果：VDMA 永远看不到行结束 → 报 `ERR_FSZ_MORE`，一帧都不提交 → DDR 里没有像素；
* 修复：让 `tlast` 与「本行最后一个像素」同拍（`line_end_w = href_d & ~cmos_href`）。

### 缺陷 3：`tuser`(SOF) 每行都发，应该每帧一次

* 原 RTL 在每行结束时清 `frame_on`，于是每行第一个像素都置 SOF；
* 修复：`frame_on` 只在 VSYNC 下降沿清。

### 缺陷 4：AXI-Stream 握手不合规

* 原逻辑 `assign fifo_rd = ~fifo_empty;` 无条件弹出 FIFO：
  * `tready=0` 时 `tdata` 仍在变（协议违规）；
  * VDMA 停顿时直接丢拍；
* 修复：标准的 1 深度保持寄存器 + 背压（`can_issue = !axis_valid_r | axis_consumed`），并遵守「同步读 FIFO 的数据在 `rd_en` 下一拍才有效」的时序。

### 缺陷 5：（修复 4 时自己引入、自查发现）读指针死锁

* 用 `fifo_dout[17]` 去门控 `rd_en` 是循环依赖 —— 数据要等读才有效 → **永久死锁**，AWXIS 一拍都不出；
* 修复：读的决策不再依赖 `fifo_dout`，改为读到之后再判断是否丢弃（SOF 之前的数据）。
* **这次先用 xsim 仿真验证再重建**（`rtl/cam_tb2.v`）：

```
[TB] checked 128 beats, 2 frames, errors=0
[TB] fifo_ovf=0 mmcm_locked=1
SIM_RESULT=PASS      ← 含 tready 停摆（每 97 拍停 23 拍）仍不丢数据、tdata 不乱变
```

---

## 2. 上板验证证据（本轮实测）

| 项 | 结果 | 来源 |
|---|---|---|
| FCLK0 | `0x00400500` = **50 MHz** ✓ | 读 `0xF8000170` |
| MMCM 锁定 | **1** ✓ | 调试字 bit7 |
| XCLK 门控 | **1** ✓（24 MHz 已送到传感器） | 调试字 bit6 |
| SCCB ACK | **1** ✓（OV5640 真的应答了） | 调试字 bit5（sticky） |
| PCLK | **在跑** ✓（多次采样低 4 位都在变） | 调试字 bit[3:0] |
| 原始引脚（probe 工程实测） | HREF 高 39/低 21、VSYNC 高 58/低 2、PCLK 计数 60 次采样全不同、数据线出现 0x00/0x20/0x40 | `probe_pins_out.log` |
| DDR 访问真实性 | 4/4 模式写读回一致 ✓ | `ddr_test_out.log` |
| VDMA 寄存器 | VERSION=`0x62000050`（v6.2），可读可写 ✓ | `vdma_probe_out.log` |
| 分块读带宽 | 4 KB/次 ≈ 190–227 KB/s（1.8 MB 帧约 9 s） | `ddr_test_out.log` |

结论：**摄像头这一侧已经活了** —— 时钟链、SCCB 配置、PCLK/VSYNC/HREF/数据全部正常，
画面对应数据偏暗（0x00 附近），不是数据线浮空。

---

## 3. 本轮修复的第六个缺陷：async_fifo_18b.v 跨时钟同步器接错时钟

`rtl/async_fifo_18b.v` 的两条格雷码同步链时钟接反（`rptr_sync` 用读时钟、`wptr_sync` 用写时钟），
正确写法是"读指针同步进**写**时钟域、写指针同步进**读**时钟域"。后果两条，都被实测到：

1. `wr_full` 由读域寄存器组合算出、直接驱动 BRAM 写使能 → 一条原始跨时钟路径
   `clk_fpga_0 → cmos_pclk_clk`。**这是整份设计唯一不收敛的时钟对**：
   ```
   From Clock      To Clock        WNS(ns)   TNS(ns)  Failing
   clk_fpga_0      cmos_pclk_clk   -9.212   -204.172      24
   cmos_pclk_clk   clk_fpga_0      -5.564   -158.846      34
   （其余所有时钟对，含 DPU 的 clk_out2/clk_out3，全部满足）
   ```
2. `wr_full`/`rd_empty` 跨域直接采样、没有同步器 → 满/空标志不可靠 → 丢像素、行长错乱。
   实测印证：修好前调试字 `fifo_ovf=1`，修好后 `fifo_ovf=0`。

修复后（v3）+ XDC 声明 `cmos_pclk_clk` 与 `clk_fpga_0` 异步，xsim 仍 `SIM_RESULT=PASS`。

## 4. 时序收敛结果（本项目史上第一次）

| 构建 | WNS | TNS | WHS | THS |
|---|---|---|---|---|
| 交接前所有构建 | −7.0 … −10.5 ns | 大量失败 | −0.1 … −4.0 | 大量失败 |
| DPU 时钟改回 100/200 | −9.2 ns | −1061 | −0.06 | −0.06 |
| + FIFO CDC 修复 + 时钟组 | +0.538 | 0.000 | −0.575 | −2.2 ps |
| + DVP 输入约束 `-clock_fall` | **+0.538** | **0.000** | **+0.018** | **0.000** ✅ |

最后一个关键点是**相机数据输入约束**：OV5640 在 PCLK **下降沿**输出数据、cam_top 在**上升沿**采样，
因此 `set_input_delay` 必须带 `-clock_fall`；不带的话工具按上升沿检查输入路径，报出
`cmos_data[*] → data_d_reg[*]` 的 **−3.04 ns 假 hold 违例**，而这条无法收敛的违例正是让
"post-route hold fix"阶段空转数小时的原因。

## 5. 当前剩余阻塞（唯一条）

### 5.-1 【2026-10-11 凌晨】构建侧新阻塞：时钟树偏斜导致 PL 全死

板上现象：最近几次构建出的 bitstream，**PL 一个从机都不响应**（`0x41220000` / `0x4301002C` 全 `FFFFFFFF`），
但**板子本身是好的**——载入 9/30 的旧 bitstream 后 `0x40000000 = 0x0D9C13F1`（DPU 正常应答）✓。

根因（已从 `*_timing_summary_routed.rpt` 读到硬证据）：

| 时钟域 | WNS | 失败端点 | WHS | 失败端点 |
|---|---|---|---|---|
| `clk_fpga_0` (50M) | +8.173 ✓ | 0 | **−6.087** | 1777 |
| `clk_out2` (100M) | **−6.975** | 1584 | −0.275 | 157 |
| `clk_out3` (200M) | −4.280 | 503 | −0.087 | 59 |

最差路径的 **数据路径只有 1.616 ns，而 slack = −6.087 ns**，且 `Requirement = 0.000 ns` →
说明是**同域内时钟偏斜约 7.7 ns**（目的时钟比源时钟早到 ~7.7 ns）。这不是逻辑问题，是
**时钟树/布局布线问题**（同一份设计在 19:28 那次构建是干净的：WNS +0.583 / WHS +0.003 ✓）。
失败路径集中在 IP 内部（VDMA 的内建异步行缓存 FIFO、`axi_periph` 的 `auto_pc`）✓，与"时钟偏斜"吻合。

**下一步（已排好）**：
1. 删掉 `unified.runs/*` 后**强制全量重建**（已做过一次，仍复现同值；需确认实现确实重跑，
   而不是复用缓存——`STATS.WNS` 跨构建**逐位相同**（−6.974744/−6.087299）非常可疑）；
2. 若确认重跑后仍失败，换 `route_design` 指令（`Explore` / `AlternateCLBRouting`）或
   用 `create_clock` 之外的时钟约束方式（例如把 clk_wiz 的三路输出显式 `create_generated_clock`），
   重点是把 `clk_fpga_0` / `clk_out2` 的偏斜压下去；
3. 通过后再跑 P1 的上板抓帧验证（`capture_v27.tcl`：预填模式判定）。
4. 关掉 post-route physopt 与默认 route 指令的"hold fix 迭代"（实测会把 WHS 从 −0.373 恶化到
   −6.996 并卡死 1–2 小时）——迭代期用 `rebuild_fast.tcl` / `rebuild_quick.tcl`。

### 5.0 两个重要发现（2026-10-10 晚）

**(a) "上板不稳定"的真因 = `ps7_init`** ✅ 已修复

```
halt_core 后：      DDR 写/读 0x0A000000 = OK，SLCR 可读
跑 ps7_init：       Memory read error at 0xF8006078. Blocked address.
                    Access can hang PS interconnect        <-- 就死在这里
之后：              DDR 和 PL 访问全部 FFFFFFFF，DAP 卡死
```
即 `ps7_init` 在 DDR PHY 段（`0xF8006078`，xsdb 明令禁止访问）出错，把 PS 互连留在坏状态，
这才是"有时能读、有时全 FFFFFFFF"的根源。修法：
* 新增 `ps7_init_safe.tcl`：只跳过 DDR PHY 那一段（DDR 已由 FSBL 初始化），其余 MIO/PLL/时钟照跑；
* `halt_core` 自恢复（DAP `rst -system` / `rst -srst` 挨个试），目标选择兼容"只列 APU 容器"与 id 漂移；
* **PL 写必须 `mwr -force`**（不带会报 `Blocked address`）。

修复后整链一次跑通：`DDR 读写 OK → FCLK0=0x00400500 → 载 bitstream → camera=0xEA` ✓。

**(b) VDMA 数据面从不写 DDR —— 判定测试（预填模式法）**

预填帧缓冲为 `0xDEADBEEF` → 启动 S2MM → 回读：

| 时刻 | 结果 |
|---|---|
| 启动前 | `SR = 0x00014811`（**错误位在软件动手前就已置位**），写 `0x43010034=0xFF0` **清不掉** |
| 配置寄存器 | `VSIZE/HSIZE/STRIDE/FS1` 写入并回读全部正确 ✓ |
| 运行 7 s 后 | `SR=0x00014810`（RUNSTOP 生效），`FRMCNT` 恒为 1 |
| 帧缓冲 | **64/64 个字仍是 `0xDEADBEEF`** → VDMA 一个字节都没写 ✗ |

同时流侧已全部验证正确：`sof_seen=1`、SOF 实测 **≈30 次/秒 = 每帧一次**、tlast 确定性落在第 1280 像素、
`fifo_ovf=0`、确定性 1280×720 帧结构仿真 `PASS`。

**当前假设**：VDMA 在"未启动"状态下被摄像头持续灌流，`ERR_INTERNAL/ERR_FSZ_MORE` 一旦 latch 就再也
清不掉（通道复位也不清，因为帧计数由输入流驱动），于是数据面永远不工作。
**验证性修复**：把 `cam_top` 上电后的静默窗口从 11 帧（≈0.37 s）加长到 **130 帧（≈4.3 s）**，
让软件有时间在摄像头出第一帧之前把 S2MM 配置好并启动 ✓（仿真 `PASS`，正在重建验证）。

### 5.1 已解决：VDMA 视频寄存器写入卡死 ✅

把单独的 `axi_protocol_converter` 换成已验证工程同款结构后解决：
```tcl
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 vdma_icc
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] [get_bd_cells vdma_icc]
# axi_vdma_cam/M_AXI_S2MM -> vdma_icc/S00_AXI ; vdma_icc/M00_AXI -> ps7/S_AXI_HP3
# ACLK/S00_ACLK/M00_ACLK = clk_out1 ; ARESETN* = rst_100/peripheral_aresetn
```
验证：`VSIZE/HSIZE/STRIDE/FS1` 现在全部写入成功并正确回读（之前写 `0xA0` 就 AP 卡死）。
`vdma_icc/s00_couplers` 内部自动插入了 `auto_pc`（AXI4→AXI3）✓，与 yoloproject 完全同构。

> 顺带解决：BD 曾因 `design_1_dpu_eu_0_0`（"IP contains locked subcore"）而**整体锁定**，
> 导致 `validate_bd_design`/`generate_target`/`make_wrapper` 全被拒（`BD 5-336`、`filemgmt 20-1365`）。
> `IS_LOCKED` 是只读属性改不了；**`upgrade_ip [get_ips design_1_dpu_eu_0_0]` 之后锁自动解除** ✓。

> VDMA 参数已对齐已验证工程：`C_USE_S2MM_FSYNC=2`(s2mm_tuser)、`C_S2MM_SOF_ENABLE=1`、
> `C_NUM_FSTORES=1`；流位宽保持 16 bit（我们的 camera IP 每个 beat 一个 RGB565 像素，
> 已验证工程是 32 bit，所以 HSIZE/STRIDE 不能照抄）。
> 注：`S2MM_FRMSTORE(0x48)` 在本 IP 中是**可选调试寄存器**（驱动里 `XAXIVDMA_ENABLE_DBG_FRMSTORE_REG`
> 未使能时为 no-op），所以"写 3 回读 0"是正常的，不是故障。

> **构建注意**：`impl_1` 的 post-route physopt（hold fix）在本设计上会跑飞——实测把 WHS 从
> −0.373 ns 恶化到 −6.996 ns 并卡住 1–2 小时。已加 `rebuild_fast.tcl`（关掉该 step）用于迭代；
> 需要严格时序收敛时用 `rebuild_mempath.tcl` 并耐心等它收敛（本设计有过 +0.003 ns 的干净记录）。

### 5.2 仍存在：VDMA 永远不提交帧（FSZ_MORE）

诊断比特流实测：

| 观测 | 值 | 说明 |
|---|---|---|
| 调试字 `sof_seen` | 1 | SOF **确实**打到了 AXIS（tuser 有输出）|
| 调试字 `skip_ge10` | 1 | 采集已使能（已跳过 11 帧）|
| 实测 SOF 速率 | **≈29–30 次/秒** | 即 **30 fps、每帧一次 SOF** ✓ 正常 |
| `fifo_ovf` | 0 | 采集 FIFO 不再溢出（FIFO CDC 修复生效）|
| VDMA `SR` | `0x00014810` | `ERR_INTERNAL` + `ERR_FSZ_MORE`，`frmcnt` 恒为 1 |
| VSIZE 扫描 | 720/750/800/900/960/1080/1440 **全部 FSZ_MORE** | 即"每帧行数 > 1440" |
| DDR | 无有效像素 | 帧从未提交 |

**结论**：SOF（帧边界）速率正常、RTL 确实发出 tuser、BD 连线在生成的 HDL 中核对无误、
存储通路与已验证工程同构——但 VDMA 认为"两帧之间有 1400 行以上"，即它看到的 **tlast（行结束）
次数远多于真实行数**（真实 720 行/帧，若每行出现 ≥2 次 tlast 就会超过 1440）。

### 5.3 建议的下一步（按优先级）

1. **测 tlast 速率**：调试字再加一个 EOL 计数器（PCLK 域，采样换算次/秒）。
   期望 = 30 fps × 720 行 = **21 600 次/秒**；若实测明显偏高，即确认"多余 tlast"，
   根因就在 `line_end_w = href_d & ~cmos_href`（HREF 上任何毛刺/间隙都会产生一次假行尾）。
   修法：对 HREF 做 2–3 拍稳定判定，或要求该行已收到足量像素才认行尾。
2. 若 tlast 速率正常：核对 VDMA 的 `S2MM_FRMSTORE(0x48)` / `PARKPTR` / `C_NUM_FSTORES`
   组合（当前写 3 回读 0，可疑）；或临时把 VDMA 换成简单 AXI-Stream FIFO 直接看原始流结构。
3. 上板 bring-up 仍偶发（第一次 PL 访问可能打挂 AP）：`pl_wakeup`（SLCR unlock + 写
   `FPGA_RST_CTRL=0` + lock）能显著提高成功率，但仍非 100%；必要时给板子断电重启。

## 6. 第二个结构性缺陷：BD 原本完全没有存储通路（已补齐）

```
interface_nets 全部内容（修复前）：
  ps7_DDR / ps7_FIXED_IO / ps7_M_AXI_GP0
  axi_periph_M00_AXI → dpu_eu_0/S_AXI        （控制口）
  axi_periph_M01_AXI → axi_vdma_cam/S_AXI_LITE（控制口）
  axi_periph_M02_AXI → dbg_gpio/S_AXI        （调试口）
  cam_top_m_axis_video → axi_vdma_cam/S_AXIS_S2MM（视频流入口）
```

也就是说：

* `axi_vdma_cam/M_AXI_S2MM` **没有连到任何 HP 口**（`design_1.hwh` 里这些端口 `SIGNAME="undef"`）；
* `dpu_eu_0/DPU0_M_AXI_DATA0 / DATA1 / INSTR` **也都没有连**；
* 板级表现完全吻合：VDMA `S2MM_DMASR = 0x00014810` → `ERR_INTERNAL(0x10) + ERR_FSZ_MORE(0x800)`，
  数据搬运器没有 slave，帧永远不提交 → DDR 里没有像素 → 采集 FIFO 回压溢出（`fifo_ovf=1`）。

**这是「抓不到图」的直接原因，与摄像头本身无关。** 无论摄像头修得多好，这个 BD 都抓不到帧。

对照已验证过的 `yoloproject`（8/8 识别通过）——它的通路是完整的：

```
ov5640_0/m_axis_video        → axi_vdma_0/S_AXIS_S2MM
axi_vdma_0/M_AXI_S2MM        → vdma_icc/S00_AXI → vdma_icc/M00_AXI → ps7/S_AXI_HP3
dpu_eu_0/DPU0_M_AXI_DATA0    → ps7/S_AXI_HP0
dpu_eu_0/DPU0_M_AXI_DATA1    → ps7/S_AXI_HP1
dpu_eu_0/DPU0_M_AXI_INSTR    → axi_smc_instr → ps7/S_AXI_HP2
```

补充事实：unified 只启用了 HP0/HP1（HP2/HP3 = 0），且我直接把 VDMA 接到 HP0 时被 Vivado 拒绝：
`M_AXI_S2MM` 是 **AXI4**，`S_AXI_HP0` 是 **AXI3** → 必须像 yoloproject 那样经过一个互连（`vdma_icc`）做协议转换。

> 本次未对 BD 做任何修改：`connect_bd_intf_net` 报错后脚本即退出，没有执行 `save_bd_design`；
> `design_1.bd` 时间戳仍是 19:13:09，并额外留了 `design_1.bd.bak_vdma_hp0` 备份。

---

## 7. 下一步方案（含执行情况）

### 方案 A（推荐，延续当前 unified 方向）：补齐 unified 的存储通路 —— ✅ 已执行

1. ✅ 已加 `axi_pc_vdma`（axi_protocol_converter，AXI4→AXI3，64bit）：
   `axi_vdma_cam/M_AXI_S2MM → axi_pc_vdma/S_AXI`，`axi_pc_vdma/M_AXI → ps7/S_AXI_HP3`
   （同属 clk_wiz clk_out1 = 100 MHz，无需时钟转换）
2. ✅ 已启用 HP2/HP3 并接上 DPU 三个 master：
   `DPU0_M_AXI_DATA0 → HP0`、`DATA1 → HP1`（AXI3 直连，同 clk_out2 域）、
   `DPU0_M_AXI_INSTR → axi_smc_instr(SmartConnect, 32→64bit) → HP2`
3. ✅ `validate_bd_design` 通过并已保存（备份：`design_1.bd.bak_before_mempath`）
4. ✅ 已发现并修复**第二个结构性缺陷**：unified 工程一直**没满足时序**
   （历次构建 WNS = −7.0 / −7.2 / −8.4 / −9.4 / −10.5 ns），原因是把 DPU 超频到
   clk_out2=150 MHz / clk_out3=300 MHz；已验证的 yoloproject 是 100/200 MHz（WNS=+0.505）。
   已把 clk_out2/clk_out3 改为 100/200 MHz 并重建（`fix_clocks_and_rebuild.tcl`）。
   > 实证：WNS=−10 ns 时连 VDMA 的控制寄存器访问都会 AP 超时（AXI 握手被破坏），
   > 所以"时序不收敛"不是纸面问题，是当时抓不到帧的直接叠加原因之一。


### 方案 B：把本轮的 5 个摄像头修复移植回已验证的 yoloproject

* yoloproject 已有完整 VDMA/DPU 通路与 PetaLinux 应用，接上去就能直接跑 YOLO；
* 代价：其摄像头是打包 IP `design_1_ov5640_0_0_1`，需要替换该 IP 的 RTL 源码后重新打包；
* 风险：IP 重新打包流程；收益：直接接入已验收的 8/8 识别链路

---

## 8. 复用手册（本轮踩坑换来的，务必沿用）

### 5.0 【本轮第六个真实缺陷】采集 FIFO 的跨时钟同步器接错了时钟（同时解释"时序不收敛"）

`rtl/async_fifo_18b.v` 里两条同步链的时钟接反了：

```verilog
// 错误版本
always @(posedge rd_clk) {rptr_sync2, rptr_sync1} <= {rptr_sync1, rptr_g};  // 读指针却用读时钟打拍
always @(posedge wr_clk) {wptr_sync2, wptr_sync1} <= {wptr_sync1, wptr_g};  // 写指针却用写时钟打拍
```

正确做法是"读指针同步进**写**时钟域（供 `wr_full` 用）、写指针同步进**读**时钟域（供 `rd_empty` 用）"。
接反的后果有两条，而且都被实测到了：

1. `wr_full` 由读域寄存器组合逻辑算出、直接驱动 BRAM 写使能 → 一条原始跨时钟路径
   `clk_fpga_0 → cmos_pclk_clk`。**这正是整份设计里唯一不收敛的时钟对**：
   ```
   From Clock      To Clock        WNS(ns)   TNS(ns)  Failing
   clk_fpga_0      cmos_pclk_clk   -9.212   -204.172      24
   cmos_pclk_clk   clk_fpga_0      -5.564   -158.846      34
   （其余所有时钟对，包括 DPU 的 clk_out2/clk_out3，全部满足时序）
   ```
   最差路径：`u_fifo/rptr_sync2_reg[5]/C → u_fifo/mem_reg/WEA[0]`，requirement 0.005 ns。
2. `wr_full` / `rd_empty` 都是跨域直接采样、没有同步器 → 满/空标志在硬件上不可靠
   → 丢像素、行长度错乱 → VDMA `ERR_FSZ_MORE` + FIFO 溢出。

**修复**：把两条 always 块的时钟互换（v3），并在 `board_deploy/unified.xdc` 里把
`cmos_pclk_clk` 与 `clk_fpga_0` 声明为异步（剩下的跨域信号只有调试/状态量）。
修完 xsim 仍 `SIM_RESULT=PASS`。

> 注意：XDC 里**不能用 `if`**（`Designutils 20-1307`），而且 `clk_fpga_0`、`clk_24m`
> 在**综合阶段**还不存在（PS7/MMCM 是黑盒），引用它们会在综合阶段报一条 CRITICAL WARNING，
> 但**实现阶段会正常生效**（XDC 在实现时会重新读取）。

### 5.1 Zynq 板上调试访问（本项目最容易踩的地方）

1. **失败的调试访问会把 DAP AP 打挂**（`APB AP transaction error, DAP status 0x...21`），
   APU 目标消失；软件恢复唯一可行方法是：`targets -set -filter {name =~ "DAP*"}` 后 `rst -system`（等 5–6 s）。
2. **读内存前必须 `rst -processor -stop`**：只 `stop` 不清 MMU，读任何地址都会
   `MMU section translation fault`；`rst -processor -stop` 后 core 处于 `(Vector Catch)`，读才正常。
3. **选 core 0 用 id（`targets 2`）**：reset 前后目标名字会变（`Cortex-A9` ↔ `ARM Cortex-A9 MPCore #0`），
   按名字过滤会选不中。
4. **PS/SLCR 地址用普通 `mrd/mwr`；PL 地址（0x4xxxxxxx）才加 `-force`。**
5. **`ps7_init.tcl` 必须在全局作用域 `source`**：写在 proc 里 source 会静默失败，
   FCLK0 会停在 boot 镜像的 15.625 MHz（`0x00200500`）而不是 50 MHz（`0x00400500`）。
6. **每次 `fpga` 下载比特流后 core 会被放开**，必须重新 `rst -processor -stop`，否则所有访问报
   `Cannot write memory if not stopped`。
7. **不要用大批量 `mrd -bin`**（会打挂 DAP）；分块 4 KB 读约 200 KB/s。
8. 这些已固化成库：`board_deploy\lib_bringup.tcl`（`ps_bringup` / `ensure_fclk0_50mhz` /
   `load_bitstream` / `halt_core` / `rdv` / `rdp` / `wr`）。

### 5.2 重建流程

* **改 RTL 后必须 `reset_run design_1_cam_top_0_synth_1`**，否则 OOC IP 不会重综合（老坑）；
* 重建脚本：`board_deploy\rebuild_sda_oe_fix.tcl`（reset cam_top OOC + synth_1 + impl_1 → 约 34 min）；
* **重建前先跑仿真**：`rtl\run_sim.bat` 用的是老 TB，请改用 `cam_tb2.v`（新 TB 已按修正后的
  tlast/tuser 语义校验，并带 tready 停摆测试），省下一次 35 分钟的盲重建。

---

## 9. 本轮产物清单

| 类别 | 路径 | 说明 |
|---|---|---|
| RTL（已修） | `rtl\ov5640_cam_top.v` | tlast/tuser/AXIS 握手/FIFO 溢出标志/调试打包 |
| RTL（已修） | `rtl\i2c_timing_ctrl_reg16_dat8_wronly.v` | 开路漏极 SDA + sticky ACK 输出 |
| 仿真 | `rtl\cam_tb2.v` （`xsim cam_sim2`） | 128 拍 / 2 帧 / 0 错误 / SIM_RESULT=PASS |
| 比特流 | `vivado_projects\unified\unified.runs\impl_1\design_1_wrapper.bit` | 2026-10-10 00:17，含全部 5 处修复 |
| 上板库 | `board_deploy\lib_bringup.tcl` | 可靠上板/复位/读寄存器 |
| 上板脚本 | `board_deploy\capture_v5.tcl`、`capture_v6.tcl`、`probe_pins.tcl`、`dump_frame.tcl`、`ddr_test.tcl`、`reset_types.tcl`、`sel_test.tcl` | 采集判定、原始引脚、帧导出、DDR 校验、复位策略 |
| 图像工具 | `board_deploy\rgb565_to_png.py` | RGB565 → PNG（待抓帧成功后使用） |
| 关键日志 | `board_deploy\capture_v5_out.log`、`probe_pins_out.log`、`ddr_test_out.log`、`capture_v6_out.log` | 本文档全部证据来源 |
| 根因/进度 | `board_deploy\CAMERA_HANDOFF_20261010.md`（本文件） | — |

# 综合与实现报告

> 对应赛题 3.3.5.1 第 3 条：**综合与实现报告，含资源占用、时钟频率与关键性能指标**。
> 另含 3.3.5.3 第 4 条要求的**优化前后性能与资源对比表**。

---

## 1. 工程与工具

| 项 | 值 |
|---|---|
| 工程 | `vivado_projects/unified/unified.xpr` |
| 顶层 | `design_1_wrapper` |
| 器件 | **`7z020-clg400-2`**（Zynq-7020，速度等级 −2） |
| 工具 | **Vivado v2019.1**（win64）Build 2552052 |
| 实现状态 | Fully Placed / Routed |
| 报告时间 | 2026-10-15 23:02（utilization）、23:14（timing） |
| 本目录原始报告 | [`utilization_placed.rpt`](utilization_placed.rpt)（11,180 B）<br>[`timing_summary_extract.txt`](timing_summary_extract.txt)（从 1,034,593 B 的完整报告提取） |

> **关于工具版本**：本作品使用 Vivado **2019.1**，低于赛题推荐的 2026.1/2025.2。
> 原因与可复现性保证见 [`../../report/design_report.md`](../../report/design_report.md) §8.1。

---

## 2. 时序结果

```
    WNS(ns)      TNS(ns)  TNS Failing Endpoints  TNS Total Endpoints
      0.718        0.000                      0                144296
    WHS(ns)      THS(ns)  THS Failing Endpoints  THS Total Endpoints
      0.051        0.000                      0                144256
   WPWS(ns)     TPWS(ns)  TPWS Failing Endpoints  TPWS Total Endpoints
      2.000        0.000                       0                 72192

All user specified timing constraints are met.
```

| 指标 | 数值 | 余量评价 |
|---|---|---|
| **WNS**（建立） | **+0.718 ns** | 正余量，0 个失败端点 |
| **WHS**（保持） | **+0.051 ns** | 正余量但**很紧**，0 个失败端点 |
| WPWS（脉冲宽度） | +2.000 ns | 充裕 |

### 2.1 时钟频率

| 时钟 | 周期 (ns) | 频率 (MHz) | 用途 |
|---|---|---|---|
| `clk_fpga_0` | 20.000 | **50.000** | PS FCLK0，摄像头采集域 + `frame_writer` + `S_AXI_HP3` |
| `cmos_pclk_clk` | 10.000 | 100.000（约束值） | 摄像头 PCLK 采样域（**实际 84 MHz**，约束取更紧的值） |
| `clk_out2`（`m_axi_dpu_aclk`） | 10.000 | **100.000** | DPU 数据面 + 指令 |
| **`clk_out3`（`dpu_2x_clk`）** | **5.000** | **200.000** | DPU 内部 2x 域 |
| `clk_24m` | 41.667 | 24.000 | OV5640 XCLK |
| `clkfb` / `clkfbout` | 40.000 / 20.000 | 25.000 / 50.000 | MMCM 反馈 |

> **⚠️ 关键约束：`clk_out3` 必须精确等于 `clk_out2` 的 2 倍（200 = 2 × 100）。**
> 这不是时序偏好 —— DPU IP 自己生成的约束文件
> （`dpu_ip/dpu/ttcl/timing_clocks_xdc.ttcl`）使用
> `set_multicycle_path 2 -setup -from dpu_2x_clk -to m_axi_dpu_aclk`，
> 表明 **2x 域按"2 个 2x 周期 = 1 个 1x 周期"的节拍工作，这是 RTL 的功能假设**。
> 若两路时钟不是整数倍关系（例如 100/150 MHz），相位持续漂移，
> 推理输出会变成**每次都不一样的随机结果**。本工程在实现历史上正是踩过这个坑。

---

## 3. 资源占用

### 3.1 整个设计（`report_utilization -file ..._utilization_placed.rpt`）

| 资源 | 使用 | 可用 | 占比 |
|---|---|---|---|
| Slice LUTs | 37,338 | 53,200 | **70.18%** |
| └ LUT as Logic | 35,110 | 53,200 | 66.00% |
| └ LUT as Memory | 2,228 | 17,400 | 12.80% |
| Slice Registers | 67,932 | 106,400 | **63.85%** |
| **Slice** | **13,057** | **13,300** | **98.17%** ← 最紧 |
| Block RAM Tile | 123.5 | 140 | **88.21%** |
| └ RAMB36/FIFO | 112 | 140 | 80.00% |
| └ RAMB18 | 23 | 280 | 8.21% |
| **DSP48E1** | **212** | **220** | **96.36%** ← 次紧 |
| BUFGCTRL | 4 | 32 | 12.50% |
| MMCME2_ADV | 2 | 4 | 50.00% |
| Bonded IOPADs | 130 | 130 | 100% |
| F7 / F8 Muxes | 320 / 52 | 26,600 / 13,300 | 1.20% / 0.39% |

### 3.2 DPU 单独（OOC 综合）

| 资源 | DPU | 整个设计 | **DPU 占整个设计的比例** |
|---|---|---|---|
| LUT | 34,019 | 37,338 | **91.1%** |
| FF | 63,101 | 67,932 | **92.9%** |
| BRAM | 123 | 123.5 | **99.6%** |
| DSP | 212 | 212 | **100%** |

**结论：本设计的资源瓶颈完全由 DPU 决定。**
DSP 已用掉 **96.36%**、BRAM **88.21%**、Slice **98.17%** ——
**没有任何余量去放大、复制或加深加速器**。

这正是 §4 中选择"**降低关键路径耗时（软件方案）**"而不是
"**提高加速器吞吐（硬件方案）**"的直接原因：
硬件方向在 7z020 上已经**物理上不可行**。

### 3.3 一条相关的资源教训

设计过程中，一个 1024×18b 的异步 FIFO 用"跨时钟域 read-first"语义写出来，
**综合成了约 19,000 个触发器而不是 BRAM**；改写成标准 BRAM 模板后
**省下 3,500 个 slice**。

**这正是"DPU + 摄像头"这个组合最终能塞进 7z020 的原因**
（Slice 占用最终是 98.17%，如果那 3,500 个 slice 没省下来，设计根本放不下）。

---

## 4. ⭐ 优化前后的性能与资源对比

> 这是赛题 3.3.5.3 第 4 条明确要求的表格。

### 4.1 主要优化：显示/推理解耦

| 指标 | 优化前（单线程耦合） | 优化后（双线程解耦） | 变化 |
|---|---|---|---|
| **显示帧率** | 2.4 fps | **7.4 – 7.5 fps** | **+208%** |
| 显示通路单帧耗时 | 328 ms | **~120 ms** | **−63%** |
| 显示通路阶段构成 | grab/cvt/pre/**dpu**/**decode**/draw/jpeg | **grab/cvt/draw/jpeg** | 去掉 pre 与 decode |
| 检测框更新率 | 2.4 /s | 3.9 /s | +63% |
| 画面分辨率 | 1025×720 | 1025×720 | 不变 |
| 画面撕裂 | 无 | 无 | 不变 |
| **比特流** | `unified_clkfix_sw.bin` | **完全相同**（md5 `54e99b97…`） | **零硬件改动** |
| **LUT / FF / BRAM / DSP** | 37,338 / 67,932 / 123.5 / 212 | **完全相同** | **零资源增长** |
| **WNS / WHS** | +0.718 / +0.051 ns | **完全相同** | 时序不变 |

> **同一个比特流、同一个二进制模型，跑出了 2.4 fps 与 7.5 fps 两个结果** ——
> 因此这 3 倍增益**可证明是纯软件的**。
>
> 这也是对赛题 3.3.4"**合理使用片上资源，避免以显著的资源代价换取有限的性能收益**"
> 的正面回应：**本次性能提升的资源代价是 0。**

### 4.2 逐阶段耗时明细（优化前，60 帧平均）

| 阶段 | 耗时 (ms) | 占比 | 是否仍在显示通路上 |
|---|---|---|---|
| grab（等帧边界 + memcpy 1.4 MB） | 58.9 | 14.7% | ✅ 是 |
| cvt（RGB565→BGR） | 6.5 | 1.6% | ✅ 是 |
| pre（letterbox 416 + 量化） | 55.4 | 13.8% | ❌ 已移出 |
| **dpu（硬件推理）** | **125.5** | **31.4%** | ❌ 已移出 |
| decode（YOLO 解码 + NMS） | 60.7 | 15.2% | ❌ 已移出 |
| draw（画框 + 状态栏） | 11.3 | 2.8% | ✅ 是 |
| **jpeg（编码）** | **81.2** | **20.3%** | ✅ 是 |
| **合计** | **399.5** | **→ 2.4 fps** | |

优化后显示通路：`grab 33.7 + cvt 6.5 + draw ~3 + jpeg 80.0 ≈ 120 ms < 133.33 ms` → 7.4 fps。

### 4.3 次要优化：解码路径扁平化

| 项 | 优化前 | 优化后 | 变化 |
|---|---|---|---|
| decode 耗时 | 60.7 ms | **49.2 ms** | −11.5 ms |

做法：把 `detect()` 里 26×26 层构造的 676×3 = 2028 个 `vector<vector<vector<float>>>`
改为扁平数组。风险极低，且结果可用 `RAWOUT` 逐字节比对验证。

### 4.4 ⚠️ 一次**无效**的优化（诚实记录）

| 项 | 预期 | **实测** |
|---|---|---|
| JPEG 质量 72 → 60 | 省约 20 ms | **只省 1.2 ms**（81.2 → 80.0 ms） |

原因：JPEG 的耗时主要在**色彩转换、DCT 与量化表**，
质量参数**只影响熵编码**阶段。所以"降质量换速度"这条路在本实现上不成立，
它只适合当带宽杠杆（单帧 66 KB → 52.8 KB，−20%）。

**更重要的是**：这一轮微优化（解码扁平化 + JPEG 质量）总共省了 12.7 ms，
**帧率一点没变** —— 因为 `340.6 ms` 与 `327.8 ms` 都落在同一级帧率"台阶"里
（详见 §4.5）。

### 4.5 为什么省了 12.7 ms 却不涨帧率：帧率台阶效应

```
T_total = ceil(T_proc / T_cam) × T_cam        T_cam = 133.33 ms
```

| `T_proc` | `T_total` | fps |
|---|---|---|
| < 133.3 ms | 133.3 ms | **7.5** |
| 133.3 – 266.7 ms | 266.7 ms | 3.75 |
| **266.7 – 400.0 ms** | **400.0 ms** | **2.50** ← 微优化前后都在这一级 |
| 400.0 – 533.3 ms | 533.3 ms | 1.88 |

因为每一轮循环都以"等下一个帧边界"结束，总时间必须是帧周期的整数倍，
`ceil()` 就是量化器本身。

**实测验证**：

| 场景 | `T_proc` | `ceil` | 预测 `T_total` | **实测** |
|---|---|---|---|---|
| 微优化前 | 340.6 ms | 3 | 400 ms | **399.5 ms** |
| 微优化后 | 327.8 ms | 3 | 400 ms | **399.4 ms** |

等待相位交叉验证：`340.6 mod 133.33 = 73.9` → 预测等待 59.4 ms，**实测 58.9 ms**；
`327.8 mod 133.33 = 61.1` → 预测 72.2 ms，**实测 71.6 ms**。
**残差 ≤ 0.6 ms（< 0.2%）。**

**结论**：要跨到下一级台阶（3.75 fps），`T_proc` 必须降到 266.7 ms 以下，
当时**还差 61.1 ms**。这就是为什么值得换思路（解耦），而不是继续挤那 12 ms。

---

## 5. `check_timing` 摘要

| 检查项 | 结果 |
|---|---|
| `no_clock`（无时钟的寄存器/锁存器引脚） | **0** |
| 多时钟 / 生成时钟 / 组合环 | 见原始报告，无致命项 |
| 时序约束满足情况 | `All user specified timing constraints are met.` |

**已知的一条未处理 DRC**（非时序，属 BRAM 异步控制检查）：

```
[DRC REQP-1840] RAMB18 async control check: ... design_1_i/cam_top/inst/u_fifo/mem_reg ...
  driven by a register that has an active asynchronous set or reset.
  This may cause corruption of the memory contents and/or read values
```

出现在 `cam_top` 跨时钟 FIFO 的 BRAM 上。**当前画面干净**，
但**若出现随机坏行或噪声，应优先查这里**。详见
[`../../report/design_report.md`](../../report/design_report.md) §9.3。

---

## 6. 如何在别处复现本报告

```tcl
# 打开工程并重新生成两份报告
open_project vivado_projects/unified/unified.xpr
open_run impl_1
report_utilization   -file build/reports/utilization_placed.rpt
report_timing_summary -max_paths 10 -file build/reports/timing_summary_routed.rpt -warn_on_violation
```

> ⚠️ **重建前请先跑 IP 锁定检查**（[`../../skill/checks/check_ip_lock_status.tcl`](../../skill/checks/check_ip_lock_status.tcl)）。
> IP 处于 locked 状态时 Vivado **只打印警告然后沿用旧网表**，
> 构建会"成功"但你的改动不在比特流里。
> 构建后还应比对**比特流去掉头部后的载荷 md5** 是否变化
> （见 [`../../skill/pitfalls/vivado-ooc-module-reference-stale.md`](../../skill/pitfalls/vivado-ooc-module-reference-stale.md)）。

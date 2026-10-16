# DPU 推理结果非确定 → 检查 2x 时钟是否为精确 2 倍

| 项 | 内容 |
|---|---|
| **类型** | 踩坑清单 |
| **适用场景** | DPU 特性开关全部 `Enabled`、`dpuOpen` 也通过了，但推理输出是**每次都不一样**的垃圾（荒谬类别、越界框坐标） |
| **使用方法** | 看应用自检里的 `identical=` 字段；用 `inspect_bd_clocks2.py` 核对两路时钟频率 |
| **失效条件** | 仅适用于 DPU IP v3.0（内部有 2x 时钟域）。若 DPU 只有一个时钟输入，本项不适用 |
| **已验证效果** | 把 `clk_out3` 从 150 MHz 改回 200 MHz 后，输出由随机垃圾变为 `identical=1`，且与历史验收记录逐字节一致 |
| **投入** | 定位约 2 小时；修复 1 行 Tcl + 一次重建 |

---

## 现象

特性开关修好、`dexplorer -w` 六项全 `Enabled`，但推理结果是**非确定的垃圾**：

```
Class name: carrot   [ID]:51  conf=0.679179  box=(-1510,-5858)-(1997,6246)
Class name: hot dog  [ID]:52  conf=0.731059  box=(-404,-7462)-(886,8080)
... 15 个荒谬类别，置信度只有两个固定值
DETERM_CHECK: run1=-8615966 run2=-9379926 identical=0     ← 每次跑都不一样
BOXES: raw=0 after_nms=0
```

而同一块板、同一内核、同一 `dpu.ko`、同一张输入图，换回已知良好的比特流就是
`identical=1` + `raw=6 nms=3`。

## 根因

**`identical=0` 这个"非确定性"本身就是最强的线索：非确定性几乎一定是时钟/时序问题，不是配置问题。**
配置错误会稳定地错，时钟错误会随机地错。

DPU IP 自己生成的约束文件 `dpu_ip/dpu/ttcl/timing_clocks_xdc.ttcl` 暴露了它的功能假设：

```tcl
##########################
# constrains for DDR-DSP #
##########################
set clk_2x [get_clocks -of_objects [get_ports dpu_2x_clk     ]]
set clk_1x [get_clocks -of_objects [get_ports m_axi_dpu_aclk ]]
set_multicycle_path 2 -setup -start -from $clk_2x -to $clk_1x
set_multicycle_path 2 -setup -end   -from $clk_1x -to $clk_2x
```

`set_multicycle_path 2` 的前提是两个时钟成**精确 2 倍**关系。
IP 内部 2x 域的状态机按"2 个 2x 周期 = 1 个 1x 周期"的节拍工作 ——
**这不是单纯的时序约束放宽，而是 RTL 的功能假设**。

出问题的工程里两路时钟是 **100 MHz 与 150 MHz：不是整数倍关系**，两者相位持续漂移，
2x 域对 1x 域的节拍随机错位，于是每次跑结果都不同。

MMCM 解算对照：

| | clk_out1 | clk_out2 | clk_out3 | MMCM 解 |
|---|---|---|---|---|
| 正常工程 | 100 | **100** | **200** ✅ 2 倍 | `MULT_F 20, DIVIDE_F 10, DIVIDE1 10, DIVIDE2 5` → VCO 1000 |
| 出问题 | 100 | **100** | **150** ❌ 1.5 倍 | `MULT_F 18, DIVIDE_F 9, DIVIDE1 9, DIVIDE2 6` → VCO 900 |
| 修复后 | 100 | **100** | **200** ✅ | 与正常工程**逐位一致** |

> **为什么会退化成 150**：当初大概是为了让时序更容易收敛而把 `clk_out3` 从 200 降到了 150，
> 但没意识到它破坏了 2x 关系。
>
> **为什么一直没暴露**：该工程的 DPU 计算通路**此前从未被验证过** ——
> 历史文档只记录了"DPU 签名寄存器能读出来"。
> **"寄存器活着"和"算得对"是两件完全不同的事**，这是整条踩坑线上最贵的一课。

## 排查步骤

1. **先看 `identical=`**：应用里内建一个"同图跑两次、比较输出字节"的自检，是最省事的判据。
   `identical=0` → 直接跳到时钟，不要再去查配置。
2. 核对两路时钟频率与比例：
   ```python
   # inspect_bd_clocks2.py —— 只读，打印 clk_wiz 频率、DPU 时钟引脚及其驱动者
   ```
   要求：`freq(dpu_2x_clk) == 2 × freq(m_axi_dpu_aclk)`，且**精确相等**（不能是 1.5 倍、2.0 倍附近）。
3. 确认 `dpu_2x_clk` 不是由任何 FCLK 直接驱动，而是由同一个 MMCM 的两个输出驱动
   （同一 MMCM 才保证相位关系确定）。

## 修复

```tcl
set_property CONFIG.CLKOUT3_REQUESTED_OUT_FREQ 200 [get_bd_cells clk_wiz_0]
```

**影响面评估**：`clk_out3` 在整个设计里只驱动两处 —— `dpu_eu_0/dpu_2x_clk` 和
`rst_300/slowest_sync_clk`。提高它对其他部分零影响，而 200 MHz 是已验证收敛过的配置。

### 旁证：排除"摄像头抢 DDR 带宽"这条线

| 通路 | PS 端口 | 时钟域 |
|---|---|---|
| DPU（数据 0/1/2 + 指令） | `S_AXI_HP0/1/2` | clk_out2 = 100 MHz |
| 摄像头写入 | `S_AXI_HP3` | FCLK_CLK0 = 50 MHz |

端口分开，摄像头写入约 44 MB/s，对 DDR3 带宽压力很小。
所以"摄像头抢带宽导致 DPU 算错"的可能性很低 —— 这条旁证把矛头更明确地指向了时钟比例。

参考脚本：`fix_clk2x_and_build.tcl`（改频率 → 校验 2 倍比例 → 校验 DPU 特性 → 再构建，
任一门禁不过就 `exit 1` 拒绝出片，避免白等四十分钟）。

## 提炼过程 —— 从哪些失败与观察中总结出来

1. **最初按"配置问题"排查**：反复确认特性开关、重跑 `dexplorer -w`，全部正常，陷入僵局。
2. **转折点**：注意到输出**每次都不一样**。把"非确定性"当成独立证据类别，而不是"错得离谱"，
   立刻把范围从配置转向时序/时钟。
3. **决定性证据不是来自本项目**，而是来自 IP 安装目录里的 `.ttcl` 文件。
   **教训：IP 生成的约束文件是理解 IP 功能假设的权威来源，值得优先翻。**
4. **承认盲区**：该项目此前只验证了"DPU 寄存器可读"，从未验证"DPU 算得对"。
   于是把"同图跑两次比对输出"固化成应用的常驻自检（`DETERM_CHECK`），
   以后任何改动都能立刻发现回归。

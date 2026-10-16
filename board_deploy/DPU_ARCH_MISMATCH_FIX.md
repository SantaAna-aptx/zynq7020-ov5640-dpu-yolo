# DPU 架构不匹配 — 根因与修复记录

> 日期: 2026-10-15 晚 · 板卡: MZ7X (XC7Z020-2CLG400) · 工程: `vivado_projects\unified\unified.xpr`
> 结论: 统一比特流（摄像头 + DPU 同一比特流）里的 DPU IP **少了三个特性开关**，导致
> DNNDK 在 `dpuOpen` 阶段直接拒绝加载模型。已定位、已修复、正在重建。

---

## 1. 现象

板卡侧一切正常（内核起来了、`/dev/dpu` 建出来了、DPU 签名读得到），但一跑推理就退出：

```
sh-4.4# cd /home/root/d3 && ./tiny_yolo_image_diag4 dog.jpg
[DNNDK] DPU configuration mismatch for kernel tiny_yolo - parameter: Conv+Leakyrelu,
        DPU kernel: Enabled, DPU IP: Disabled.
```

含义：**模型（DPU kernel）要求 Conv+Leakyrelu，硬件（DPU IP）说没有**。`dpuOpen` 直接失败，
一个框都不出。

注意 `insmod dpu.ko` 是成功的（`rc=0`），DPU 寄存器也有响应（`ID=0x0D9C13F1 SIG=0x0C014450`），
所以这不是"DPU 死了"，而是**DPU 配置与模型不匹配**。

## 2. 决定性对照实验（无需断电）

板卡已启动的情况下用 `fpga_manager` 原地换比特流，逐个用 `dexplorer -w` 让 DPU **自己报**它的特性表：

| 特性 | `dpu_fclk0.bin`（D3 已验证 8/8） | `unified_color_sw.bin`（统一流） | 模型要求 |
|---|---|---|---|
| DepthwiseConv | Enabled | Enabled | Enabled |
| DepthwiseConv+Relu6 | Enabled | Enabled | Enabled |
| **Conv+Leakyrelu** | Enabled | **Disabled** ❌ | Enabled |
| Conv+Relu6 | Enabled | Enabled | Enabled |
| **Channel Augmentation** | Enabled | **Disabled** ❌ | Enabled |
| **Average Pool** | Enabled | **Disabled** ❌ | Enabled |
| IP Timestamp | 2026-09-20 01:00:00 | 2026-10-12 12:30:00 | — |

同一个内核、同一套 `dpu.ko`、同一份 `dog.jpg`：

- `dpu_fclk0.bin` → `DETERM_CHECK: run1=-7891502 run2=-7891502 identical=1`、`BOXES: raw=6 after_nms=3` ✅
- `unified_color_sw.bin` → 上面那条 mismatch，直接退出 ❌

**同时这条对照实验证明 `mem=120M cma=48M` 对 DPU 完全够用**（D3 的 8/8 结果在这个内核/CMA 配置下
原样复现），此前"cma 导致内核死亡"的判断是误诊（见 §5）。

## 3. 根因：BD 里 `dpu_eu_0` 少了三个参数

统一工程 BD 里 `dpu_eu_0` 只显式写了 5 个参数：

```tcl
ARCH {1152}  DWCV_ENA {1}  LOAD_AUGM {0}
POOL_AVERAGE {0}  CONV_RELU_ADDON {2}  S_AXI_CLK_INDEPENDENT {0}
```

而这几个参数是**主开关**，其余特性全由 IP 自己的生成函数推导（来源：
`dpu_ip/dpu/gui/dpu_eu_v3_0.gtcl`，即 IP 的权威定义）：

```tcl
CONV_LEAKYRELU = (CONV_RELU_ADDON==1 || CONV_RELU_ADDON==3) ? 1 : 0
CONV_RELU6     = (CONV_RELU_ADDON==2 || CONV_RELU_ADDON==3) ? 1 : 0
DWCV_RELU6     = DWCV_ENA ? CONV_RELU6 : 0
DWCV_PARALLEL  = DWCV_ENA ? ARCH_PP/2 : 0

DNNDK_PRINT:
  Channel Augmentation = (LOAD_AUGM==0)     ? Disabled : Enabled
  DepthWiseConv        = (DWCV_ENA==0)      ? Disabled : Enabled
  AveragePool          = (POOL_AVERAGE==0)  ? Disabled : Enabled
  ReLU Type            = (CONV_RELU_ADDON==2) ? "ReLU + ReLU6" : "ReLU + LeakyReLU + ReLU6"
```

代入原值：`CONV_RELU_ADDON=2` → 只有 ReLU6、没有 LeakyReLU；`POOL_AVERAGE=0` → 无平均池化；
`LOAD_AUGM=0` → 无通道增强。三条正好对应上表三个 ❌。

（几何参数本身其实是对的：`ARCH_ICP=12`、`ARCH_OCP=12`、`ARCH_PP=4`、`BANK_WGT_N=13`、
`DWCV_PARALLEL=2`、`CONV_DSP_NUM=192`、`SUM_DSP_NUM=212`、`SUM_BRAM_N=123.0` 全都和已知良好配置
`design_1_regen.tcl` 一致。**只有那三个开关设错了。**）

### 修复（三个参数）

```tcl
CONFIG.CONV_RELU_ADDON 2 -> 3    # → CONV_LEAKYRELU=1 且 CONV_RELU6=1，DWCV_RELU6 跟着变 1
CONFIG.POOL_AVERAGE    0 -> 1    # → AveragePool:Enabled
CONFIG.LOAD_AUGM       0 -> 1    # → Channel Augmentation:Enabled
```

修复后 `DNNDK_PRINT`：

```
...Channel Augmentation:Enabled;DepthWiseConv:Enabled;AveragePool:Enabled;
   ReLU Type:ReLU + LeakyReLU + ReLU6...DSP Slice Count:212;...Block-RAM Count:123.0
```

四个要求全部满足，且 DSP/BRAM 用量不变（这三个开关不占额外 DSP/BRAM）。
脚本：`board_deploy/fix_dpu_features.tcl`

## 4. 第二个坑：IP 被锁 → 会静默沿用旧网表

改完参数后直接 build，日志里出现：

```
WARNING: [Vivado 12-4801] The synthesis checkpoint for IP '...design_1_dpu_eu_0_0.xci' is
         available but stale and the IP is locked.
WARNING: [Project 1-577]  IP run design_1_dpu_eu_0_0_synth_1 is ... out of date. Since the IP
         is locked, the synthesis checkpoint cannot be updated. The out-of-date checkpoint
         will be used and it may result in incorrect behavior.
```

**这就是"改了参数但比特流没变"的经典陷阱**（与 `rebuild_force_ooc.tcl` 记录过的 cam_top OOC 陷阱同类）。
更麻烦的是所有 IP 的 `.dcp` 产物都缺失，而对 BD 执行 `reset_target`/`generate_target` 会被拒绝：

```
CRITICAL WARNING: [filemgmt 20-1365] Unable to generate target(s) ... Block design contains locked IPs.
```

鸡生蛋问题。`report_ip_status` 给出的锁定原因和药方：

| IP | 状态 | 建议 |
|---|---|---|
| `design_1_dpu_eu_0_0` | IP contains locked subcore | Upgrade IP |
| `design_1_ps7_0` / `dbg_gpio` / `rst_100` / `rst_cam` | Stale IP file detected | Upgrade IP |
| `design_1_cam_top_0` / `frame_writer_0_0` | Stale module reference | Refresh module reference |

**解法：`upgrade_ip`**。逐 IP 执行后锁定数 5 → 0，随后 `generate_target all` 才被允许。
完整流程见 `board_deploy/unlock_regen_and_build.tcl`，其中带一道保险：
`upgrade_ip` **可能重置 IP 配置**，所以升级之后必须重新校验那三个参数 + `DNNDK_PRINT`，
不满足就直接 `exit 1` 拒绝构建（避免白等四十分钟拿到一个没用的比特流）。

## 5. 顺带纠正的两个误判

- **`cma` 不是凶手。** 之前"`mem=120M cma=80M` 导致内核无输出死亡"的判断是错的。翻 16:03 的日志：

  ```
  setenv bootargs ... mem=120M cma=80M
  Loading Device Tree to 1fff9000, end 1ffff7c6 ... OK     ← 512 MB
  Starting kernel ...                                       ← 之后永远沉默
  ```

  `fdt_high` 没设，U-Boot 把设备树搬到 RAM 顶端 512 MB，而内核只认前 120 MB —— **又是设备树够不着**，
  跟 CMA 无关。
- **`image.ub` 的加载地址必须低。** `image.ub` 放在 `0x10000000` 时，它内部的 DTB 子镜像
  （偏移 `0x3F2BE4`）会落到 `0x103F2BE4` ≈ 260 MB，同样在 120 MB 之外 → `Starting kernel ...` 后静默挂死。
  改为加载到 `0x01000000` 后 DTB 落在 ≈20 MB，稳在 cap 内。这是 20:08 那次挂死的真正原因。

## 6. 已验证的启动配方（含摄像头 + DPU 同一个比特流）

```text
fatload mmc 0:1 0x01000000 image.ub          # 必须低地址，见 §5
setenv fdt_high 0xffffffff                   # 禁止 U-Boot 把 DTB 搬到 RAM 顶端
setenv bootargs console=ttyPS0,115200 earlyprintk root=/dev/mmcblk0p2 rw \
       rootfstype=ext4 rootwait init=/bin/sh mem=120M cma=48M
bootm 0x01000000
```

`mem=120M`：把摄像头写的 `0x08000000`(128 MB) 帧缓存挡在内核 RAM 之外。
`cma=48M`：DPU 张量靠 CMA（DTB 里只有 `xlnk` 节点，`cma=256M` 是写在 DTB 的 bootargs 里的，
会被 U-Boot 的 `bootargs` 完全覆盖）。实测 `CmaTotal: 49152 kB / CmaFree: 48872 kB`，
CMA 落在 `0x04800000`，与摄像头帧缓存 `0x08000000` **不重叠**，DPU 8/8 复现成功。

之后照 `FCLK0_ROOT_CAUSE.md` 的时钟配方写 `0xF8000170 = 0x00201400` 等。

## 7. 第二个根因：`dpu_2x_clk` 必须是 `m_axi_dpu_aclk` 的**精确 2 倍**

修好特性开关后，`dexplorer -w` 六项全 `Enabled` 了，但推理结果是**非确定的垃圾**：

```
Class name: carrot   [ID]:51  conf=0.679179  box=(-1510,-5858)-(1997,6246)
Class name: hot dog  [ID]:52  conf=0.731059  box=(-404,-7462)-(886,8080)
... 15 个荒谬类别，置信度只有两个固定值
DETERM_CHECK: run1=-8615966 run2=-9379926 identical=0     ← 每次跑都不一样
BOXES: raw=0 after_nms=0
```

而同一块板、同一内核、同一 `dpu.ko`、同一 `dog.jpg`，`dpu_fclk0.bin`（D3）是
`identical=1` + `raw=6 nms=3`。**`identical=0` 这个非确定性本身就是关键线索。**

### 证据：DPU IP 自己生成的约束

`dpu_ip/dpu/ttcl/timing_clocks_xdc.ttcl`：

```tcl
##########################
# constrains for DDR-DSP #
##########################
set clk_2x [get_clocks -of_objects [get_ports dpu_2x_clk     ]]
set clk_1x [get_clocks -of_objects [get_ports m_axi_dpu_aclk ]]
set_multicycle_path 2 -setup -start -from $clk_2x -to $clk_1x
set_multicycle_path 2 -setup -end   -from $clk_1x -to $clk_2x
```

`multicycle 2` 的前提是两个时钟成**精确 2 倍**关系。IP 内部 2x 域的状态机按"2 个 2x 周期 = 1 个
1x 周期"的节拍工作，**这不是单纯的时序约束，而是 RTL 的功能假设**。

### 对照：能跑通的工程用的是 100/200

`vivado_projects/yoloproject`（D3 比特流的来源）：

| | clk_out1 | clk_out2 | clk_out3 |
|---|---|---|---|
| 用途 | s_axi | **m_axi_dpu_aclk** | **dpu_2x_clk** |
| yoloproject（正常） | 100 | **100** | **200** ✅ 2 倍 |
| unified（算错） | 100 | **100** | **150** ❌ 1.5 倍 |

MMCM 解算：
- yoloproject：`PRIM_IN 50, MULT_F 20, DIVIDE_F 10, DIVIDE1 10, DIVIDE2 5` → VCO 1000 → 100/100/200
- unified（错）：`MULT_F 18, DIVIDE_F 9, DIVIDE1 9, DIVIDE2 6` → VCO 900 → 100/100/**150**
- unified（修后）：`MULT_F 20, DIVIDE_F 10, DIVIDE1 10, DIVIDE2 5` → VCO 1000 → 100/100/200
  —— **和 D3 逐位一致**

100 MHz 与 150 MHz **不是整数倍关系**，两者相位持续漂移，2x 域对 1x 域的节拍会随机错位，
这正是"每次跑结果都不同"的来源。

### 为什么一直没暴露

统一工程当初大概为了让时序更容易收敛，把 clk_out3 从 200 降到了 150，但没意识到它破坏了
2x 关系。更关键的是：**统一工程的 DPU 计算通路此前从未被验证过**。`SESSION_UNIFIED.md` 只记录了
"DPU 签名 0x0D9C13F1 读出"，即只证明了 DPU 的寄存器活着 —— 而"寄存器活着"和"算得对"是两件
完全不同的事（`FCLK0_ROOT_CAUSE.md` 里那个"S_AXI 应答但计算域全死"正是同一类陷阱）。

### 修复

```tcl
set_property CONFIG.CLKOUT3_REQUESTED_OUT_FREQ 200 [get_bd_cells clk_wiz_0]
```

`clk_out3` 在整个设计里只驱动两处：`dpu_eu_0/dpu_2x_clk` 和 `rst_300/slowest_sync_clk`，
提高它对其他部分零影响。而 200 MHz 比 D3 的配置更保守（D3 就是这个频率且收敛成功）。
脚本：`board_deploy/fix_clk2x_and_build.tcl`

### 旁证：摄像头与 DPU 不共用 HP 端口

| 通路 | PS 端口 | 时钟域 |
|---|---|---|
| DPU（数据 0/1/2 + 指令） | `S_AXI_HP0/1/2` | clk_out2 = 100 MHz |
| 摄像头 frame_writer | `S_AXI_HP3` | FCLK_CLK0 = 50 MHz |

端口分开，摄像头约 44 MB/s 的写入对 DDR3 带宽压力很小，所以"摄像头抢 DDR 导致 DPU 算错"
的可能性很低 —— 这条把矛头更明确地指向时钟比例。

## 8. 相关脚本

| 脚本 | 作用 |
|---|---|
| `fix_dpu_features.tcl` | 改那三个参数 + 校验 `DNNDK_PRINT` + 保存/校验/生成产物 |
| `probe_dpu_features.tcl` | 只读探针：逐个试参数、看哪个开关点亮哪个特性 |
| `inspect_dpu_params.tcl` | 只读：列出 IP 暴露的全部 `CONFIG.*` 及其当前值 |
| `diagnose_ip_lock.tcl` | `report_ip_status` + 逐 IP `upgrade_ip`，把锁定数打到 0 |
| `unlock_regen_and_build.tcl` | 解锁 → 复核 DPU 特性（防止 upgrade 重置）→ 重新生成 → 构建 |
| `fix_clk2x_and_build.tcl` | 把 `dpu_2x_clk` 从 150 改回 200 MHz，校验 2 倍比例 + DPU 特性，再构建 |
| `inspect_bd_clocks2.py` | 只读：打印 clk_wiz 频率、DPU 时钟引脚及其驱动者 |
| `dpu_arch_probe.ps1` | 板卡侧原地对照两个比特流的 `dexplorer -w` + 应用自检 |
| `d5_verify.ps1` | 已启动的板子上原地验收（不用断电） |
| `d5_full.ps1` | 从抢 U-Boot 到四项验收一次做完（板子刚上电时用） |
| `check_colour.py` | 统计 RGB565 帧的各通道均值，判断色偏还是寄存器问题 |

## 9. 验收标准

1. `dexplorer -w` 六项全 `Enabled`（✔ 已由 `dpu_fclk0.bin` 证明该判据可达）
2. `tiny_yolo_image_diag4 dog.jpg` → `identical=1`、`BOXES: raw=6 after_nms=3`
3. `0x41220000` 调试字非零、`0x08000000`/`0x08040000` 帧数据非零且随时间变化
4. 闭环：摄像头实时帧 → PC 转 JPG → DPU 推理 → 回传带框结果图

## 10. 排查顺序小结（下次遇到"DPU 不对"照这个顺序走）

1. `dexplorer -w` 看六项特性是否与模型要求一致（`ddump -f <elf> -d` 给要求）
2. 看 `identical=` 是 1 还是 0 —— **非确定性几乎一定是时钟/时序问题，不是配置问题**
3. 查 `dpu_2x_clk == 2 × m_axi_dpu_aclk`（`inspect_bd_clocks2.py`）
4. 查 `FCLK0 = 0x00201400`（50.000 MHz 整）与 `0xF800012C`
5. 只有以上都对，才去怀疑比特流之外的软件/内存问题

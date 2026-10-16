# DPU 特性开关与模型要求不匹配

| 项 | 内容 |
|---|---|
| **类型** | 踩坑清单 |
| **适用场景** | 在 Xilinx DPU IP（`dpu_eu` v3.0）上部署 DNNDK 量化模型，板端 `dpuOpen` 阶段直接报 `DPU configuration mismatch` |
| **使用方法** | 按"排查步骤"逐条对照模型要求与 IP 实际特性；按"修复"改 Block Design 参数 |
| **失效条件** | 仅适用于 DPU IP v3.0 这一代（Arch B1152 / B4096 等）。Vitis AI / DPU v4.x 的配置机制不同，参数名与推导规则都不一样。另外，若模型本身不含 LeakyReLU 或平均池化，这几个开关即使关着也不会报错 |
| **已验证效果** | 改 3 个参数后 `dpuOpen` 通过，8 张测试图 8/8 命中标准答案，`identical=1` |
| **投入** | 定位约 1 小时（板端对照实验，无需断电）；修复 3 行 Tcl + 一次重建 |

---

## 现象

板卡侧一切正常：内核起来了、`/dev/dpu` 建出来了、`insmod dpu.ko` 返回 0、DPU 签名寄存器读得到
（`ID=0x0D9C13F1 SIG=0x0C014450`）。但一跑推理就退出，一个框都不出：

```
sh-4.4# ./tiny_yolo_image_diag4 dog.jpg
[DNNDK] DPU configuration mismatch for kernel tiny_yolo - parameter: Conv+Leakyrelu,
        DPU kernel: Enabled, DPU IP: Disabled.
```

字面含义：**模型要求 Conv+LeakyReLU，硬件说没有**。

> 关键判断：`insmod` 成功 + 寄存器有响应，说明**这不是"DPU 死了"，而是"DPU 配置与模型不匹配"**。
> 两者是完全不同的排查方向，先分清能省很多时间。

## 根因

Block Design 里 `dpu_eu_0` 只显式写了 5 个参数，其中 3 个是**主开关**，其余特性全部由 IP 的
生成函数推导：

```tcl
ARCH {1152}  DWCV_ENA {1}  LOAD_AUGM {0}
POOL_AVERAGE {0}  CONV_RELU_ADDON {2}  S_AXI_CLK_INDEPENDENT {0}
```

推导规则的权威来源是 IP 安装目录下的 `dpu_ip/dpu/gui/dpu_eu_v3_0.gtcl`：

```tcl
CONV_LEAKYRELU = (CONV_RELU_ADDON==1 || CONV_RELU_ADDON==3) ? 1 : 0
CONV_RELU6     = (CONV_RELU_ADDON==2 || CONV_RELU_ADDON==3) ? 1 : 0
DWCV_RELU6     = (DWCV_ENA ? CONV_RELU6 : 0)
DWCV_PARALLEL  = (DWCV_ENA ? ARCH_PP/2 : 0)

# 这几个开关直接决定 DNNDK_PRINT 打印出来的特性表：
DNNDK_PRINT:
  Channel Augmentation = (LOAD_AUGM==0)     ? Disabled : Enabled
  DepthWiseConv        = (DWCV_ENA==0)      ? Disabled : Enabled
  AveragePool          = (POOL_AVERAGE==0)  ? Disabled : Enabled
  ReLU Type            = (CONV_RELU_ADDON==2) ? "ReLU + ReLU6"
                                              : "ReLU + LeakyReLU + ReLU6"
```

代入上表原值：`CONV_RELU_ADDON=2` → 只有 ReLU6、**没有 LeakyReLU**；`POOL_AVERAGE=0` → 无平均池化；
`LOAD_AUGM=0` → 无通道增强。三条正好对应三条 `Disabled`。

> ⚠️ 容易误判的地方：几何参数（`ARCH_ICP`、`ARCH_OCP`、`ARCH_PP`、`BANK_WGT_N`、`CONV_DSP_NUM`、
> `SUM_DSP_NUM`、`SUM_BRAM_N`）**全都是对的**，和已知良好配置逐项一致。
> 只有那三个开关错了 —— 所以"参数大部分正确"不代表没问题。

## 排查步骤

板子**不用断电**，用 `fpga_manager` 原地换比特流，做对照实验：

1. 让 DPU **自己报**特性表，而不是去猜：
   ```sh
   dexplorer -w
   ```
2. 让模型**自己报**要求：
   ```sh
   ddump -f tiny_yolo.elf -d
   ```
3. 逐项对照，重点看这几个名字：`Conv+Leakyrelu`、`Channel Augmentation`、`Average Pool`、
   `DepthwiseConv`、`Conv+Relu6`、`IP Timestamp`。

对照实验的实际结果（同一内核、同一 `dpu.ko`、同一张图，只换比特流）：

| 特性 | 已验证良好的比特流 | 出问题的比特流 | 模型要求 |
|---|---|---|---|
| DepthwiseConv | Enabled | Enabled | Enabled |
| DepthwiseConv+Relu6 | Enabled | Enabled | Enabled |
| **Conv+Leakyrelu** | Enabled | **Disabled** ❌ | Enabled |
| Conv+Relu6 | Enabled | Enabled | Enabled |
| **Channel Augmentation** | Enabled | **Disabled** ❌ | Enabled |
| **Average Pool** | Enabled | **Disabled** ❌ | Enabled |

左边那个比特流跑出 `identical=1`、`BOXES: raw=6 after_nms=3`；右边直接 mismatch 退出。

> 这个对照实验还**顺带证伪了一个误诊**：当时以为 `mem=120M cma=48M` 内存配置有问题，
> 但已验收良好的比特流在同一内核、同一 CMA 配置下原样复现 8/8，
> 说明 **CMA 配置与该故障无关**。

## 修复

```tcl
set_property CONFIG.CONV_RELU_ADDON 3 [get_bd_cells dpu_eu_0]   ;# 2 -> 3
set_property CONFIG.POOL_AVERAGE    1 [get_bd_cells dpu_eu_0]   ;# 0 -> 1
set_property CONFIG.LOAD_AUGM       1 [get_bd_cells dpu_eu_0]   ;# 0 -> 1
```

改完 `DNNDK_PRINT` 应变成：

```
...Channel Augmentation:Enabled;DepthWiseConv:Enabled;AveragePool:Enabled;
   ReLU Type:ReLU + LeakyReLU + ReLU6...DSP Slice Count:212;...Block-RAM Count:123.0
```

**这三个开关不占额外 DSP/BRAM**，打开它们用量不变（实测 212 DSP / 123 BRAM 前后一致）。
这是"改配置不吃资源"的好例子 —— 不要因为怕超资源而保守地关掉它们。

参考脚本：`fix_dpu_features.tcl`（改参数 → 校验 `DNNDK_PRINT` → 保存 → 生成产物）、
`probe_dpu_features.tcl`（只读探针，逐个试参数看哪个开关点亮哪个特性）、
`inspect_dpu_params.tcl`（列出 IP 暴露的全部 `CONFIG.*` 当前值）。

## 提炼过程 —— 从哪些失败与观察中总结出来

1. **最初的错误方向**：先怀疑"DPU 硬件坏了 / 比特流加载失败 / 内存不够"，
   花时间在 `devmem` 读寄存器和调 CMA 大小上。**突破口是那条报错信息的字面意思**：
   `DPU kernel: Enabled, DPU IP: Disabled` 已经把答案写出来了 —— 是配置对比，不是硬件故障。
2. **转折点**：意识到"能让 DPU 自己报特性表"（`dexplorer -w`）比猜测快得多，
   于是设计了"同一内核换比特流"的对照实验，一次就把范围从"整个系统"缩到"三个布尔开关"。
3. **最有价值的副产品**：顺带证伪了此前"`cma` 导致内核死亡"的误判，
   说明**对照实验的价值不止于当前问题**。
4. **最后的教训**：修完参数直接 build，结果比特流没变 —— 引出下一条
   [IP 被锁定导致静默沿用旧网表](vivado-stale-ip-netlist.md)。

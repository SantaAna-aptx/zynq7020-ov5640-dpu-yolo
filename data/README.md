# data/ —— 测试数据与参考结果

赛题 3.3.5.1 要求提交"**上板工程、运行脚本、实测输出与参考结果的比对数据**"。
本目录把散落在开发过程中的实测输出整理成**可核查**的结构。

```
data/
├── README.md                    本文件
├── validation_scorecard.md      ⭐ 8 图标准答案验收 + 确定性（黄金比对）检查
├── measured_performance.md      ⭐ 实测性能：帧率、逐阶段耗时、推流带宽、/stat 响应
└── raw/                         原始输出，未经改写
    ├── batch_fixed_results.log          8 图完整板端输出（306 行）
    ├── validation_scorecard_source.md   当时的验收评分卡
    ├── validation_scorecard_early.md    早期评分卡（仅 683 B，保留作对比）
    └── troubleshooting_dpu_probe_fault.log  排查过程的失败记录（见下）
```

---

## 1. 两份整理文档

| 文件 | 回答什么问题 |
|---|---|
| [`validation_scorecard.md`](validation_scorecard.md) | **功能对不对** —— 8 张标准图逐张列出检出类别、置信度、框坐标、`raw/nms` 计数，以及每张图的 `DETERM_CHECK` 确定性值 |
| [`measured_performance.md`](measured_performance.md) | **性能是多少** —— 摄像头帧率独立测量、优化前后逐阶段耗时、`/stat` 响应 schema、M-JPEG 带宽、JPEG 质量参数的真实影响 |

两份文档里的**每个数字都能在 `raw/` 里找到来源**。

---

## 2. 原始数据

### `raw/batch_fixed_results.log`（306 行）

8 张标准图的完整板端输出，每张图包含三段：

1. `#### IMAGE: <文件名>` 与图像尺寸
2. 两次推理的 `RAWOUT[0]` / `RAWOUT[1]`（DPU 两个输出层的统计量）
3. `Class name / conf / box` 检出列表、`RUN1_DECODE` / `RUN2_DECODE`、`DETERM_CHECK`、`BOXES`

自检能力：文件里有 **8 个 `DETERM_CHECK`、8 个 `BOXES:`、8 个 `#### IMAGE:`**，
数量对不上就说明记录不完整。

### `raw/validation_scorecard_source.md`

当时生成的验收评分卡（含"修复链路回顾"一段，是很好的历史索引）。

### `raw/validation_scorecard_early.md`

**早期**的评分卡，只有 683 B。保留它是为了显示记录是逐步完善的，
不宜与最终评分卡混用。

### ⚠️ `raw/troubleshooting_dpu_probe_fault.log`

**这是一个失败记录，不是成功结果。**

它记录了排查过程中某一次的状态：

```
Unhandled fault: external abort on non-linefetch (0x018) at 0xb6fab000
>>> DPU SIGNATURE: CHECK: Unhandled fault ...
ls: cannot access '/dev/dpu': No such file or directory
[DPU][712] Checking DPU signature at addr = 0x40f00000
PC is at dpu_probe+0x134/0xfdc [dpu]
```

**含义**：在**比特流尚未加载（或加载的是厂商比特流）**的状态下访问 DPU 的寄存器窗口，
PL 里没有对应的 AXI 从设备应答 → external abort → 内核 oops。

它对应的是"**必须先加载比特流，再 `insmod`**"这条顺序约束
（见 [`../skill/pitfalls/bitstream-word-swap-and-load-order.md`](../skill/pitfalls/bitstream-word-swap-and-load-order.md)）。

**为什么把它留在仓库里**：它是一份真实的踩坑证据，
说明"`insmod` 段错误"这类现象的确切形态。但文件名必须让人一眼看出它是排查记录，
**不能与成功结果放在一起而不加区分**。

---

## 3. 数据可信度

| 项 | 说明 |
|---|---|
| 来源 | **全部来自板端实测**，非仿真推断、非估算 |
| 原始性 | `raw/` 下的文件**未经改写**；整理文档中的每个数字都标注了出处 |
| 时间跨度 | `validation_scorecard_source.md` 为 2026-09-22；性能数据为最终交付版本（2026-10-16） |
| 一致性 | 8 图结果与历史验收记录**逐字节一致**（同一 `DETERM_CHECK` 值） |
| 已知的不一致 | 开发日志中存在 13 处自相矛盾之处，已在 [`../skill/pitfalls/logs-contradict-and-code-wins.md`](../skill/pitfalls/logs-contradict-and-code-wins.md) 逐条裁决并记录 |

### 3.1 关于"确定性"的分量

`DETERM_CHECK: run1 = run2, identical=1` 是本项目**最强的正确性证据**，因为：

- 它检验的是**真实硬件在真实配置下**的输出确定性；
- 它能发现**仿真无法发现**的问题（例如 DPU 的 2x 时钟不是精确 2 倍时，
  特性开关全对、模型也加载成功，只有输出每次不同）；
- 它是**可回归**的：任何改动之后重跑一次即可知道有没有破坏计算正确性。

---

## 4. 关于"实时场景检出 0 个目标"

`measured_performance.md` 里记录了实时推流的 `boxes: 0`。
**这不是故障**，原因见该文档 §5：实时场景中没有 COCO 类别的显著目标。

判别依据是三件事同时成立：

| 证据 | 值 |
|---|---|
| 确定性 | `identical=1`（实时帧） |
| 数据在变化 | 重复推理的置信度 0.977 → 0.818 → 0.562 |
| 计数在增长 | `display_frames` 与 `inferences` 持续增加 |

---

## 5. 如何自己复现这些数据

```sh
# 1) 确认比特流真的生效（不要相信 state 字段，它是假阳性）
echo ID=$(busybox devmem 0x40000000) SIG=$(busybox devmem 0x40f00000)
# 期望: ID=0x0D9C13F1  SIG=0x0C014450

# 2) 确认 PL 时钟正确
busybox devmem 0xF8000170          # 应为 0x00201400（精确 50.000 MHz）

# 3) 确认摄像头在出流
busybox devmem 0x41220000          # 相机行计数器，应在 0..44 之间滚动

# 4) 逐张跑 8 图，检查 identical=1 与 BOXES 计数
```

完整流程见 [`../skill/templates/zynq-power-cycle-bringup.md`](../skill/templates/zynq-power-cycle-bringup.md)。

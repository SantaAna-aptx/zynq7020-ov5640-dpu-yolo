# build/ —— 可复现构建与综合实现报告

赛题 3.3.5.1 要求提交"**可复现的构建脚本**"与"**综合与实现报告**"。

```
build/
├── README.md                    本文件
└── reports/
    ├── SUMMARY.md               ⭐ 综合与实现报告（含优化前后性能资源对比表）
    ├── utilization_placed.rpt   Vivado 原始资源报告（11,180 B）
    └── timing_summary_extract.txt  时序摘要（从 1,034,593 B 的完整报告提取）
```

---

## 1. 报告

| 文件 | 内容 |
|---|---|
| [`reports/SUMMARY.md`](reports/SUMMARY.md) | 工具与器件信息、时序结果（WNS +0.718 / WHS +0.051 ns）、时钟频率表、资源占用（整个设计与 DPU 单独）、**优化前后性能与资源对比表**、`check_timing` 摘要 |
| [`reports/utilization_placed.rpt`](reports/utilization_placed.rpt) | Vivado `report_utilization` 原始输出，可直接核对 SUMMARY 里的每个数字 |
| [`reports/timing_summary_extract.txt`](reports/timing_summary_extract.txt) | 从 1 MB 的 `report_timing_summary` 中提取的关键段落（Design Timing Summary / Clock Summary / Intra Clock Table），含源报告行号 |

**为什么放"提取版"而不是完整的 1 MB 时序报告**：完整报告里绝大部分是逐条路径明细，
对评审没有信息量。提取版保留了**全部结论性数据**并标注了源报告行号，
需要细节时可回原始工程重新生成（命令见 SUMMARY §6）。

---

## 2. 可复现构建脚本

**按赛题推荐的目录结构，构建脚本本应放在本目录下。**
本作品的脚本位于 `board_deploy/`，原因与对照关系见根 [`README.md`](../README.md) §13。
此处列出与本目录职责对应的脚本：

| 脚本 | 作用 |
|---|---|
| `board_deploy/build_cam_stream.ps1` | 交叉编译板端应用；**编译后自动校验 7 个 `.deephi.*` 模型段**，数量不符即报警 |
| `vivado_projects/unified/*.tcl` | Vivado 工程构建脚本（BD 修改、IP 解锁、生成产物、实现、出片） |
| `design_1_regen.tcl` | 已知良好的 Block Design 参数（对照参考，**含 DPU 三个关键特性开关**） |

### 2.1 构建前的门禁（强烈建议）

| 门禁 | 检查 | 不做会怎样 |
|---|---|---|
| [`../skill/checks/check_ip_lock_status.tcl`](../skill/checks/check_ip_lock_status.tcl) | Block Design 是否有 IP 被锁定 | Vivado **只警告然后沿用旧网表**，构建"成功"但改动不在比特流里 |
| [`../skill/checks/check_dpu_model_sections.ps1`](../skill/checks/check_dpu_model_sections.ps1) | 可执行文件里模型段是否为 7 个 | 链接器可能**静默丢弃**模型段，上板加载模型时才失败 |

**两个检查合计不到两秒，能挡掉一次约 40 分钟的构建或一次板上往返。**

### 2.2 构建后的验证

改了 RTL 或 IP 参数之后，**比对比特流去掉头部后的载荷 md5**，
必须与上一版不同。整个文件的 md5 每次都不同（头部含时间戳），不能用它判断。

若载荷 md5 相同 → 你的改动根本没进比特流，无论工具报告了什么。

---

## 3. 报告数据的来源与时间

| 报告 | 生成时间 | 对应工程状态 |
|---|---|---|
| `utilization_placed.rpt` | 2026-10-15 23:02 | Fully Placed |
| `timing_summary_extract.txt` | 2026-10-15 23:14 | Routed，时序全部满足 |

两份报告都来自**最终交付的那一版比特流**（`unified_clkfix_sw.bin`，
md5 `54e99b97a838cdfb155c7b7cd72252fa`，4,045,516 B）所对应的实现结果。

# 设计报告

本目录是赛题 3.3.5.3 要求的**设计报告**与**大模型协作记录**。

| 文件 | 内容 |
|---|---|
| [`design_report.md`](design_report.md) | 设计报告主体 |
| [`llm_collaboration.md`](llm_collaboration.md) | 大模型协作记录（提示词、自我纠错轨迹、智能体工作流设计） |

---

## 赛题七项要求 → 章节映射

赛题 3.3.5.3 列出了设计报告必须包含的七项内容。对照关系如下：

| # | 赛题要求 | 对应章节 |
|---|---|---|
| 1 | 选题背景与创新点：为什么选这个题目，它解决了什么实际问题，前人做过什么 | [`design_report.md`](design_report.md) **§1** |
| 2 | 设计原理与功能框图 | [`design_report.md`](design_report.md) **§2** |
| 3 | 软硬件划分依据与接口设计 | [`design_report.md`](design_report.md) **§3** |
| 4 | 优化过程，含优化前后的性能与资源对比表 | [`design_report.md`](design_report.md) **§4** |
| 5 | 大模型协作记录：提示词、模型回答、自我纠错轨迹、智能体工作流设计 | [`llm_collaboration.md`](llm_collaboration.md)（全部）；<br>[`design_report.md`](design_report.md) §6 为摘要 |
| 6 | 技能包的提炼过程：从哪些失败或观察中总结、如何验证有效、边界如何确定 | [`design_report.md`](design_report.md) **§7**；技能包本体见 [`../skill/`](../skill/README.md) |
| 7 | 复现说明：一份可供他人从零开始完整执行的操作步骤 | [`design_report.md`](design_report.md) **§8**（前提与校验值）；<br>完整步骤见 [`../skill/templates/zynq-power-cycle-bringup.md`](../skill/templates/zynq-power-cycle-bringup.md) 与 [`../skill/templates/cross-compile-without-board-sysroot.md`](../skill/templates/cross-compile-without-board-sysroot.md) |

额外补充的两节（赛题未要求，但评审会关心）：

| 章节 | 内容 |
|---|---|
| [`design_report.md`](design_report.md) **§5** | **功能正确性如何被确认** —— 赛题 3.3.5.1 要求"说明功能正确性是如何确认的"，因此单列一章 |
| [`design_report.md`](design_report.md) **§9** | **已知限制与未证实项** —— 含一条未处理的 DRC 警告与五项明确标注为"未证实"的内容 |

---

## 数据来源

本报告中的**全部数值**来自三类可核查的来源，未使用估算值：

| 来源 | 具体文件 |
|---|---|
| Vivado 工具生成报告 | `vivado_projects/unified/unified.runs/impl_1/design_1_wrapper_utilization_placed.rpt`<br>`…/design_1_wrapper_timing_summary_routed.rpt` |
| 板端实测日志 | `board_deploy/batch_fixed_results.log`（8 图原始输出）<br>`board_deploy/VALIDATION_SCORECARD_FINAL.md`（验收评分卡）<br>`board_deploy/final_result.log` |
| 仿真 | `sim/logs/`（`xvlog` / `xelab` / `xsim` 三段日志） |

归档副本见 [`../build/reports/`](../build/reports/) 与 [`../data/`](../data/)。

---

## 写作原则

1. **区分"已证实 / 未证实 / 已排除"三档。** 未证实的内容明确标出，不作为结论引用。
2. **每个非显然的取值都写明理由**（尤其是"省掉会怎样"的失败模式）。
3. **记录被否决的方案与否决理由** —— 这比"我们这么做了"更有复用价值。
4. **不掩饰误判。** 报告中包含一次被推翻的误诊（`llm_collaboration.md` §3.1）
   和 13 处日志矛盾的裁决过程（§3.9）。

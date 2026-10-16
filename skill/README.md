# 技能包 —— Zynq / FPGA 视觉加速项目可复用经验

本目录把本项目开发过程中**真实踩过的坑、验证过的做法、和用过的提示词**提炼成可复用的形式，
供他人直接搬到自己题目上。

---

## 1. 这个技能包的组织方式

| 目录 | 内容 | 回答的问题 |
|---|---|---|
| [`pitfalls/`](pitfalls/) | **踩坑清单**（11 项） | "我遇到这个现象，该查什么？" |
| [`templates/`](templates/) | **案例模板**（3 项） | "我要做这件事，应该怎么搭，为什么这么搭？" |
| [`checks/`](checks/) | **校验脚本**（2 个） | "怎么让这类错误变成硬失败，而不是静默通过？" |
| [`prompts/`](prompts/) | **提示词工作流**（2 项） | "怎么让大模型在这类任务上稳定输出有用的东西？" |

### 写作上刻意保留的两样东西

1. **具体的数值** —— 寄存器值、频率、毫秒数、段数、相关系数。
   抽象成"频率不匹配"就失去了复用价值。
2. **走过的弯路** —— 每项都有"提炼过程"一节，记录**当时错误地以为是什么**，
   以及是什么观察把方向掰回来的。
   这部分比结论更有用，因为下一个遇到同样问题的人，大概率也会先往那个错方向走。

### 每一项都写明的四件事

**类型 / 适用场景 / 使用方法 / 失效条件**。
其中**失效条件**是刻意强调的 —— 一条经验不知道边界，就无法安全复用。

---

## 2. 最快的上手路径（按你的目标选）

| 你的目标 | 从这里开始 |
|---|---|
| 刚拿到一块**没有自启动**的 Zynq 板，不知道怎么从冷板跑到应用 | [`templates/zynq-power-cycle-bringup.md`](templates/zynq-power-cycle-bringup.md) |
| 板子**没有编译器**，要在主机上交叉编译 | [`templates/cross-compile-without-board-sysroot.md`](templates/cross-compile-without-board-sysroot.md) |
| 接了**并行接口摄像头**，画面不对 / 没数据 | [`pitfalls/dvp-camera-bringup.md`](pitfalls/dvp-camera-bringup.md) —— **按它的顺序查，不要跳** |
| 在 Zynq 上部署 **DPU / DPU 类加速器**，模型加载失败或结果不对 | [`pitfalls/dpu-model-vs-ip-features.md`](pitfalls/dpu-model-vs-ip-features.md) 起，依次往后 |
| **改了 RTL/IP 但板上行为没变** | [`pitfalls/vivado-ooc-module-reference-stale.md`](pitfalls/vivado-ooc-module-reference-stale.md) 与 [`vivado-stale-ip-netlist.md`](pitfalls/vivado-stale-ip-netlist.md)（两条都要查） |
| 实时显示被**慢加速器**拖死 | [`templates/decouple-slow-accelerator-from-display-path.md`](templates/decouple-slow-accelerator-from-display-path.md) |
| 被要求"**全面检查一遍**"，不想退化成复述 | [`prompts/layered-self-audit.md`](prompts/layered-self-audit.md) |
| 故障现象模糊，**可能原因一大堆** | [`prompts/evidence-first-diagnosis.md`](prompts/evidence-first-diagnosis.md) |
| 要写报告，但**记录互相矛盾** | [`pitfalls/logs-contradict-and-code-wins.md`](pitfalls/logs-contradict-and-code-wins.md) |

---

## 3. 全部条目

### 3.1 踩坑清单（`pitfalls/`）

| 文件 | 适用场景 | 使用方法 | 失效条件 |
|---|---|---|---|
| [`dvp-camera-bringup.md`](pitfalls/dvp-camera-bringup.md) | 并行接口（DVP：PCLK/VSYNC/HREF/D[7:0]）摄像头采集：噪声、错位、斜向拖影、垂直重复、接缝、颜色异常，或完全没有数据 | **严格按 §0→§1→§2→§3 顺序查**（先通信 → 再有数据 → 再谈几何） | 串行接口（MIPI/LVDS）摄像头不适用；用厂商已验证 IP 时 §3/§4 多不适用 |
| [`dpu-model-vs-ip-features.md`](pitfalls/dpu-model-vs-ip-features.md) | 加速器 `dpuOpen` 报 `configuration mismatch`，模型要的特性 IP 说没有 | 让加速器自己报特性表，让模型自己报要求，逐项对照；改 BD 参数 | 仅适用于该代 DPU IP（v3.0，Arch B1152 等）；模型不含 LeakyReLU/平均池化时开关关着也不报错 |
| [`dpu-nondeterminism-clock-ratio.md`](pitfalls/dpu-nondeterminism-clock-ratio.md) | 特性全 `Enabled`、加载也过了，但推理输出**每次都不一样** | 先看自检里的 `identical=`；核对两路时钟是否**精确** 2 倍 | 仅适用于内部有 2x 时钟域的 DPU IP；单时钟加速器不适用 |
| [`dpu-input-buffer-clobber.md`](pitfalls/dpu-input-buffer-clobber.md) | 连续推理时**第一次对、后面错**，结果逐渐漂移 | 加"同图跑两次比对"的自检；每次推理前重新写输入张量 | 特定于 DNNDK v3.x 任务接口；已在每次推理前重写输入的写法不会遇到 |
| [`dpu-clock-domain-and-gating.md`](pitfalls/dpu-clock-domain-and-gating.md) | 控制口寄存器读得出来，但**任务超时 / 无中断** | 分清控制域与计算域；用"写入后读回"判断每个 FCLK 是否存活 | Zynq-7000（PS7）的寄存器地址；MPSoC 地址不同，但"内核门控时钟"这个陷阱一样 |
| [`bitstream-word-swap-and-load-order.md`](pitfalls/bitstream-word-swap-and-load-order.md) | Linux 下运行时加载 PL 比特流；`insmod` 段错误或内核 oops | 确认字交换格式；**先加载比特流再 `insmod`**；不要相信 `state` 字段 | 仅适用于运行时 `fpga_manager` 加载；由 FSBL/U-Boot 在启动阶段加载时不适用 |
| [`vivado-stale-ip-netlist.md`](pitfalls/vivado-stale-ip-netlist.md) | 改了 IP 参数后重建，**比特流里还是旧参数** | 构建日志搜 `Project 1-577` / `12-4801`；用 `report_ip_status` 复核锁定数 | Vivado 2019.x 的 IP 锁定机制；纯 RTL 工程（无 IP）不适用 |
| [`vivado-ooc-module-reference-stale.md`](pitfalls/vivado-ooc-module-reference-stale.md) | 改了 RTL 后重建，**板上行为毫无变化**，而构建全部成功 | 构建前强制重置 BD 的 OOC 子工程；构建后比对**载荷 md5**（不是整个文件） | 适用于 BD 里以 module reference 引入的 RTL；纯 RTL 工程没有这层 OOC |
| [`zynq-boot-memory-ceiling.md`](pitfalls/zynq-boot-memory-ceiling.md) | 内核打印 `Starting kernel ...` 之后**永久沉默** | 用 U-Boot 打印的 DTB 加载地址与 `mem=` 做一次算术 | 适用于用 `mem=` 限制内核内存的场景；不限内存或不用 FIT 镜像时诱因不同 |
| [`debugging-environment-traps.md`](pitfalls/debugging-environment-traps.md) | 命令"执行了"却没效果、结果文件是陈旧的、串口突然不应答、脚本报奇怪的解析错 | 联调脚本上线前逐条核对这六类 | 部分条目特定于最小根文件系统与 USB 转串口芯片，换环境不一定复现 |
| [`logs-contradict-and-code-wins.md`](pitfalls/logs-contradict-and-code-wins.md) | 长周期工程的日志/注释/文档对同一件事有多种说法；要据此写报告或交接 | 按"实测 > 代码 > 产物 > 文档 > 注释"裁决；用**三档标注法**分类 | 只适用于长期、多轮、多份记录并存的项目；单一权威记录的项目不适用 |

### 3.2 案例模板（`templates/`）

| 文件 | 适用场景 | 使用方法 | 失效条件 |
|---|---|---|---|
| [`decouple-slow-accelerator-from-display-path.md`](templates/decouple-slow-accelerator-from-display-path.md) | 实时显示被一个慢阶段（硬件推理、复杂后处理、编码）拖死，且"结果尽量新"比"严格同帧"重要 | 先测各阶段耗时与帧周期，用台阶公式判断处在哪一级；若显示路径本身已低于帧周期，就按双线程结构拆开 | ① 要求画面与结果**严格同帧**；② 显示路径**自身**就已超过帧周期 —— 那必须先优化显示路径 |
| [`zynq-power-cycle-bringup.md`](templates/zynq-power-cycle-bringup.md) | 板子**没有自启动**，每次上电都要从零带到"应用在跑"，且要可重复、能自动判定 | 按 Phase A–H 执行；**关键步骤必须在通电之前武装好** | 板子有可用自启动机制、或已固化进 SD 启动镜像时，多数步骤多余 |
| [`cross-compile-without-board-sysroot.md`](templates/cross-compile-without-board-sysroot.md) | 板子**没有编译器、没有 sysroot**，依赖一批只存在于板子上的库 | 先确定工具链与 glibc 版本，再从板子采集 sysroot，用给定链接参数编译，最后用段计数验证产物 | 板子自带编译器；或工具链 glibc **比板子新**（那时免 libc sysroot 的前提不成立） |

### 3.3 校验脚本（`checks/`）

| 文件 | 适用场景 | 使用方法 | 失效条件 |
|---|---|---|---|
| [`check_dpu_model_sections.ps1`](checks/check_dpu_model_sections.ps1) | 模型段被链接进可执行文件的方案（段名 `.deephi.*` 之类），**每次链接后**都该查 | `.\check_dpu_model_sections.ps1 -Binary .\app [-Expected 7] [-ToolchainBin <dir>]`；退出码 0/1 | 段数阈值需按你自己的模型实测确定（本项目的 tiny_yolo 是 7 段） |
| [`check_ip_lock_status.tcl`](checks/check_ip_lock_status.tcl) | 每次 Vivado 构建**之前**当门禁用 | `vivado -mode batch -source check_ip_lock_status.tcl -tclargs <project.xpr> [bd_file]`；退出码 0/1 | 适用于有 IP 的 Block Design 工程；⚠️ 通用化改写后**尚未在完整工程上跑过**，首次接入请人工确认输出 |

详见 [`checks/README.md`](checks/README.md)，其中也如实标明了每个脚本的**验证状态**。

### 3.4 提示词工作流（`prompts/`）

| 文件 | 适用场景 | 使用方法 | 失效条件 |
|---|---|---|---|
| [`layered-self-audit.md`](prompts/layered-self-audit.md) | 被要求"全面检查 / 地毯式排查 / 确保没问题"；或联调卡住、怀疑某环节其实没生效 | 把提示词正文整段贴给大模型，把方括号里的项目替换成你自己的系统信息 | 这是**检查框架**不是自动化工具，需要真的去跑那些读回命令；纯仿真环境要把第 5–6 层换成波形断言 |
| [`evidence-first-diagnosis.md`](prompts/evidence-first-diagnosis.md) | 故障现象模糊、可能原因一大堆、且试错成本高（例如改一次要等 40 分钟构建） | 把提示词正文贴给大模型，并附上**原始现象**（完整报错/日志/观测数据）而不是你的结论 | 依赖存在"已知良好的对照配置"；完全没有基线时要退化成二分法逐段验证 |

---

## 4. 这个技能包最核心的六条经验

如果只能带走六条：

1. **不要假设参数值。** 摄像头"配置为 1280"但"实际输出 1025"，
   这个假设制造了一个假象并误导排查数周。
   **当所有推理都对不上时，设计一个只依赖数据本身的测量。**
   → [`dvp-camera-bringup.md`](pitfalls/dvp-camera-bringup.md) §0.1

2. **区分"错误"的形态，比分析错误的内容更有用。**
   稳定地错 → 配置问题；**随机地错 → 时钟/时序**；第一次对后面错 → 状态被污染。
   两个完全不同的根因可以有完全相同的现象，区分它们靠**更细的观察维度**。
   → [`evidence-first-diagnosis.md`](prompts/evidence-first-diagnosis.md)

3. **"构建成功"在 Vivado 里是有层次的。**
   综合成功、实现成功、时序收敛、出片成功 —— **都不能证明你的改动被采纳了**。
   唯一可靠的证据是**产物内容变了**（比对载荷 md5）或**回板上读回实际配置**。
   → [`vivado-ooc-module-reference-stale.md`](pitfalls/vivado-ooc-module-reference-stale.md)、
   [`vivado-stale-ip-netlist.md`](pitfalls/vivado-stale-ip-netlist.md)

4. **凡是"静默失败"的操作，都要有对应的自动检查。**
   本项目在工具链、链接器、比特流、寄存器表四处都遇到"不报错但没生效"。
   两个校验脚本加起来不到两秒，能挡掉一次 40 分钟的构建或一次板上往返。
   → [`checks/`](checks/)

5. **不要在关键路径上放慢的东西 —— 把它移出去。**
   显示通路本来只需要 94 ms，被 230 ms 的推理串在同一个循环里拖到 2.4 fps。
   拆线程后 7.5 fps，**硬件和比特流完全没动**。
   → [`decouple-slow-accelerator-from-display-path.md`](templates/decouple-slow-accelerator-from-display-path.md)

6. **如实标注"未证实"，比假装完成更有价值。**
   本项目梳理出 **13 处**记录互相矛盾，其中 2 处是"声称已完成的修复其实没有达成目标"。
   报告分"已证实 / 未证实 / 已排除"三档，既诚实，也防止把假设当成果报出去。
   → [`logs-contradict-and-code-wins.md`](pitfalls/logs-contradict-and-code-wins.md)

---

## 5. 关于 PYNQ Skill 的说明（如实交代）

赛题对**通用 PYNQ Skill** 有单独加分。**本项目没有使用 PYNQ 框架**，
因此本技能包中**不含** PYNQ 专属内容。

选择不使用 PYNQ 的理由：本项目需要自研的 DVP 采集 RTL、
需要在 PS 侧做双线程实时调度与 `/dev/mem` 直接访问帧缓存，
并且要以 PetaLinux + 自研 C++ 常驻进程的形式交付；
PYNQ 的 Overlay + Jupyter 形态与这套结构不匹配。

不过本技能包中**多数内容与 PYNQ 无关地可迁移**：
踩坑清单针对的是 IP 配置、时钟关系、构建产物、跨时钟域设计；
案例模板针对的是 bring-up 流程、交叉编译闭环、线程解耦与帧率模型。
这些换成 PYNQ 平台同样适用。

---

## 6. 提炼过程与验证状态

### 6.1 这些内容是怎么提炼出来的

1. **先做矛盾扫描**：把项目里关于同一件事的所有说法并列，逐条按证据强度裁决。
   这一步找出了 13 处矛盾，并**推翻了先前写进项目 README 的两处错误结论**
   （关于两个摄像头寄存器的实际作用）。
2. **再按"现象"而非"技术分类"组织**：联调时是从现象出发的，
   所以 `pitfalls/README.md` 提供了一张"看到什么 → 去看哪篇"的检索表。
3. **每篇都保留"提炼过程"**：记录当时的错误方向与扭转它的那个观察。
4. **可执行的东西做成脚本**，而不是停留在描述。

### 6.2 验证状态（如实说明）

| 类别 | 状态 |
|---|---|
| 踩坑清单、案例模板、提示词工作流 | ✅ 内容来自本项目**实际发生并已定位**的问题与**已实测**的做法；带具体数值 |
| `check_dpu_model_sections.ps1` | ✅ **已在真实产物上实测**：识别 7 段、payload 9,022,093 字节、成功与两条失败路径退出码正确 |
| `check_ip_lock_status.tcl` | ⚠️ 逻辑来自本项目实际使用的诊断脚本，**通用化改写后尚未在完整工程上跑过**；首次接入请人工确认 |

### 6.3 本文档中标注为"未证实"的内容

为避免误导，以下内容在本项目里**没有被证明**，引用时请注意：

- 某两个摄像头寄存器（`0x3820`/`0x3821`）的补丁**没有达成**其目标（补丁后行宽仍是 1025）
- 一条 DVP 输入延迟约束（`-clock_fall`）被报告为已应用，但**当前代码树里找不到它**
- 某传感器引脚（PWDN）接地后**仍然零 ACK**，因此记为"已排除"而非"已修复"
- 传感器 IO 电平域与 FPGA bank 不匹配：记录为"最大嫌疑"，**未证实**
- 一处 ROM 表的长度常量存在截断（索引 258 的条目不可达）

# pitfalls/ —— 踩坑清单

每一条都是**真实发生过、并且花掉了可观时间**的问题。
写法统一为：**现象 → 根因 → 排查步骤 → 修复 → 提炼过程**。

写法上刻意保留了两个东西：

- **具体的数值**（寄存器值、频率、毫秒数、段数）。抽象成"频率不匹配"就失去了复用价值。
- **走过的弯路**。"提炼过程"一节记录的是**当时错误地以为是什么**，以及是什么观察把方向掰回来的。
  这部分比结论更有复用价值 —— 因为下一个遇到同样问题的人，大概率也会先往那个错方向走。

---

## 按"现象"检索

联调时通常是从现象出发去查，所以这里按现象组织，而不是按技术分类。

| 你看到的现象 | 去看 |
|---|---|
| 画面**噪声**大 / 采样不稳 | [DVP 摄像头采集排错](dvp-camera-bringup.md) §2.2（PCLK 约束） |
| 画面**斜向拖影** / 每 4 行重复 | [DVP 摄像头采集排错](dvp-camera-bringup.md) §0.1、§3.6 —— **先读"不要假设行宽"** |
| 画面**垂直重复 4 次** | [DVP 摄像头采集排错](dvp-camera-bringup.md) §3.5、§3.6 |
| 画面**方块状接缝** | [DVP 摄像头采集排错](dvp-camera-bringup.md) §3.4 |
| 画面**垂直方向乱序** | [DVP 摄像头采集排错](dvp-camera-bringup.md) §3.7（VSYNC 极性） |
| 画面只有**一半**（上半噪声 / 下半黑） | 抓帧产物问题：`dd` 从 `/dev/mem` 读到未映射 DDR。改用 `mmap` 并按 64 KB 分块 |
| 摄像头**零个 ACK** / 芯片 ID 读回 `0xFF` | [DVP 摄像头采集排错](dvp-camera-bringup.md) §1.1、§1.2、§1.5 |
| 摄像头寄存器读回正常但**完全没有数据** | [DVP 摄像头采集排错](dvp-camera-bringup.md) §1.5（PWDN）、§2.1（MMCM） |
| 数据流**完全没有行边界** / DMA 报 `FSZ_MORE` | [DVP 摄像头采集排错](dvp-camera-bringup.md) §3.1、§3.2 |
| 时序**怎么都收敛不了** | [DVP 摄像头采集排错](dvp-camera-bringup.md) §4.1（CDC FIFO 时钟域接反） |
| 怀疑**红蓝互换** | [DVP 摄像头采集排错](dvp-camera-bringup.md) §3.9 —— 用通道均值判定；本项目实测**不存在** R/B 交换 |
| `DPU configuration mismatch ... DPU IP: Disabled` | [加速器特性开关与模型不匹配](dpu-model-vs-ip-features.md) |
| 推理结果**每次都不一样**（荒谬类别、越界坐标） | [2x 时钟是否为精确 2 倍](dpu-nondeterminism-clock-ratio.md) |
| **第一次对、后面错**，结果逐渐漂移 | [输出写污染了输入缓冲区](dpu-input-buffer-clobber.md) |
| 控制口寄存器读得出来，但**任务超时 / 无中断** | [时钟域与内核门控](dpu-clock-domain-and-gating.md) |
| `insmod` 段错误 / 内核 oops | [比特流字交换与加载顺序](bitstream-word-swap-and-load-order.md) |
| `Invalid bitstream, could not find a sync word` | [比特流字交换与加载顺序](bitstream-word-swap-and-load-order.md) |
| **改了 RTL 但板上行为毫无变化** | [OOC 子工程用了旧网表](vivado-ooc-module-reference-stale.md) |
| **改了 IP 参数但比特流没变** | [IP 被锁定，静默沿用旧网表](vivado-stale-ip-netlist.md) |
| `[Project 1-577]` / `12-4801` 警告 | [IP 被锁定，静默沿用旧网表](vivado-stale-ip-netlist.md) |
| `Unable to generate target(s) ... contains locked IPs` | [IP 被锁定，静默沿用旧网表](vivado-stale-ip-netlist.md) |
| 内核卡在 `Starting kernel ...` 后**永久沉默** | [设备树落在内存上限之外](zynq-boot-memory-ceiling.md) |
| 板子**完全没反应**（串口不应答） | [联调环境陷阱](debugging-environment-traps.md) §2 |
| 命令"执行了"但没有任何效果 | [联调环境陷阱](debugging-environment-traps.md) §1 |
| 应用好像跑了，结果是**陈旧的** | [联调环境陷阱](debugging-environment-traps.md) §1 |
| 脚本报"正则模式末尾非法"并刷屏 | [联调环境陷阱](debugging-environment-traps.md) §5 |
| `reboot` 之后板子再也没起来 | [联调环境陷阱](debugging-environment-traps.md) §4 |
| 文档、注释、日志对同一件事**说法互相矛盾** | [建立权威顺序](logs-contradict-and-code-wins.md) |

---

## 全部条目

### 摄像头 / 采集

| 文件 | 一句话 |
|---|---|
| [`dvp-camera-bringup.md`](dvp-camera-bringup.md) | 本项目最长的一条线。核心教训：**不要假设行宽**；排查顺序必须是"先能通信 → 再有数据 → 再谈数据对不对" |

### 加速器 / 推理

| 文件 | 一句话 |
|---|---|
| [`dpu-model-vs-ip-features.md`](dpu-model-vs-ip-features.md) | 三个布尔开关决定了模型能不能被加载；推导规则在 IP 自己的 `.gtcl` 文件里 |
| [`dpu-nondeterminism-clock-ratio.md`](dpu-nondeterminism-clock-ratio.md) | `set_multicycle_path 2` 不只是时序约束，而是 RTL 的功能假设：两路时钟必须精确 2 倍 |
| [`dpu-input-buffer-clobber.md`](dpu-input-buffer-clobber.md) | 输出写覆盖输入缓冲区；指纹是"第一次一定对" |
| [`dpu-clock-domain-and-gating.md`](dpu-clock-domain-and-gating.md) | 内核会关掉"未使用"的时钟；用"写入后读回"判断时钟是否存活 |

### 构建 / 比特流

| 文件 | 一句话 |
|---|---|
| [`vivado-stale-ip-netlist.md`](vivado-stale-ip-netlist.md) | IP 锁定时工具只警告、然后沿用旧网表成功出片；且有鸡生蛋的解锁顺序 |
| [`vivado-ooc-module-reference-stale.md`](vivado-ooc-module-reference-stale.md) | BD 的 module reference 在独立 OOC 子工程里综合，`reset_run synth_1` 不会让它重跑；铁证是两次构建的**载荷 md5 逐字节相同** |
| [`bitstream-word-swap-and-load-order.md`](bitstream-word-swap-and-load-order.md) | `.bin` 要字交换；`state=operating` 是假阳性；必须先加载比特流再 `insmod` |

### 启动 / 系统

| 文件 | 一句话 |
|---|---|
| [`zynq-boot-memory-ceiling.md`](zynq-boot-memory-ceiling.md) | 设备树落到了 `mem=` 上限之外 → 内核静默挂死；判据是**算 DTB 的绝对落点** |

### 联调环境

| 文件 | 一句话 |
|---|---|
| [`debugging-environment-traps.md`](debugging-environment-traps.md) | 六类"命令静默失效"与"假阳性"，包括重定向到不存在的目录会让整条命令被拒 |

### 工程记录

| 文件 | 一句话 |
|---|---|
| [`logs-contradict-and-code-wins.md`](logs-contradict-and-code-wins.md) | 长周期工程的日志**必然**互相矛盾。建立"实测 > 代码 > 产物 > 文档 > 注释"的权威顺序，并用**三档标注法**（已证实 / 未证实 / 已排除）如实分类 |

---

## 几条贯穿全篇的共性

这些坑表面上属于不同技术领域，但**失败的机制高度相似**，值得单独指出来：

### 1. 工具报告成功，但你要的东西没生效

`state=operating`（生效的是旧比特流）、构建成功（参数没被采纳）、
命令执行了（被 shell 拒绝）、`insmod` 返回 0（但模块没真正工作）。

**对策**：永远用**功能性的、端到端的证据**验证，
而不是相信状态字段或返回码。
"读一个只有你的设计才有的寄存器"比"看状态字段"可靠得多。

### 2. 现象相同，根因不同

`identical=0` 既可能是时钟比例错误，也可能是输入缓冲区被污染。
区分它们靠的是**更细的观察维度**（"第几次开始错"），而不是更用力地检查同一个现象。

**对策**：遇到"说不清"的问题时，先问"**这个现象还有哪些更细的形态特征是我没观察的？**"

### 3. 对照实验的价值往往超出当前问题

"同一内核换比特流"这个实验不仅定位了参数问题，
还顺带证伪了一个无关的怀疑（内存配置）。

**对策**：设计对照实验时多花十分钟，让它能同时回答多个问题。

### 4. 只读定位远优于改后重建

本项目的三次关键定位全部只读完成。
在"改一次要等 40 分钟"的环境里，**这个习惯的价值可以直接换算成小时**。

**对策**：动手改之前，先穷尽只读手段。

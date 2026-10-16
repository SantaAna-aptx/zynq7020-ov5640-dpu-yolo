# YOLOv3-tiny DPU 加速项目 —— 阶段性复盘与 OV5640 实时识别规划

> 项目平台：米联客 MZ7X（Zynq-7020 XC7Z020-2CLG400，速度等级 -2）
> 目标：YOLOv3-tiny（tiny-yolo-v2-voc 结构，B1152 DPU）在 PL 端 DPU 上完成推理
> 本文档生成：2026-09-22 深夜，阶段验收 **8/8 图片命中全部标准答案、8/8 DETERM identical=1** 之后

---

# 第一部分：项目总览与当前状态

## 1.1 项目目标回顾

| 目标项 | 验收标准 | 当前状态 |
|---|---|---|
| DPU 比特流（B1152）在 MZ7X 上运行 | DPU 可被驱动加载、可执行任务 | ✅ 达成 |
| 推理结果正确 | 与标准答案对照命中 | ✅ 8/8 图全命中 |
| 推理结果确定性 | 相同输入多次执行输出一致 | ✅ identical=1 |
| 完整软件栈 | dpu.ko + DNNDK 运行时 + 应用 | ✅ 已固化到 rootfs |
| 下一阶段 | OV5640 摄像头实时目标识别 | 📋 本文档规划 |

## 1.2 最终软硬件形态

```
┌─────────────────────── Zynq-7020 ───────────────────────┐
│  PS (ARM Cortex-A9 ×2)          PL (Artix-7 等效)       │
│  ├── DDR3 1GB (CPU 侧)          ├── DPU B1152 ×1 (dpu_eu│
│  ├── 16MB dpu_eu 地址窗口        │   内含 2 个 B1152 核) │
│  │   0x40000000 (核心0)         ├── clk_wiz: 50→100/200 │
│  │   0x40F00000 (核心1)         ├── HP0/1/2 ← m_axi 100M│
│  ├── IO_PLL 1000MHz             ├── clk_out3 → 2x  200M │
│  ├── FCLK0 50MHz → clk_wiz      ├── HP3 + 相机域 clk_out1│
│  ├── GP0 ← S_AXI 控制口 (FCLK0) ├── ov5640_cam_top      │
│  └── IRQ61 dpu_isr              └── axi_vdma_0 (s2mm)   │
└──────────────────────────────────────────────────────────┘
        软件: PetaLinux 2019.1 (kernel 4.19) + DNNDK 3.x
        应用: tiny_yolo_image (输入刷新修复版, md5 cab658fb)
        网络引导: QSPI U-Boot → init=/bin/sh → 配网 → SSH
```

**关键固化产物**（都在 `E:\yoloProject\` 下）：

| 产物 | 路径 | MD5 |
|---|---|---|
| 修复版比特流 .bit | `board_deploy\sd_delivery\design_1_wrapper_fclk0.bit` | d530f7ef |
| 字交换 .bin（fpga 用） | `web\design_1_wrapper_fclk0_sw.bin` | 456d272a |
| SD 启动产品件 | `board_deploy\sd_delivery\BOOT_NEW_FCLK0.BIN` | c25bfa27 |
| 修复版应用（已装板） | 板上 `/usr/bin/tiny_yolo_image` | cab658fb |
| 评分卡 | `board_deploy\VALIDATION_SCORECARD_FINAL.md` | 8/8 PASS |
| 根因档案 | `board_deploy\FCLK0_ROOT_CAUSE.md` | — |
| 8 图原始输出 | `board_deploy\batch_fixed_results.log` | — |

---

# 第二部分：完整执行历程（时间线复盘）

## 阶段 0：环境与基线搭建（项目早期）

1. **Vivado 工程**：建立 `yoloproject` 工程，导入 DPU TRD IP 仓库（`e:/dpu_ip_repo/zcu102-dpu-trd-2019-1`），搭建 BD：PS7 + dpu_eu(DPU B1152×2 核) + clk_wiz + 4×proc_sys_reset + axi_smc/axi_smc_instr（SmartConnect）+ ov5640_cam_top + axi_vdma。
2. **PetaLinux 工程**（VMware Ubuntu 内 `~/plnx_zturn`）：内核 4.19-xilinx-v2019.1 + DNNDK（dpu.ko/libn2cube/libhineon）+ 自研 tinyyolo 应用配方。
3. **应用**：tiny_yolo_image——读 JPG → letterbox 416×416 → DNNDK 推理 → NMS → 画框/存图；后续我们加装了 DIAG 诊断插桩（RAWOUT/IN_SUM/DETERM_CHECK）。
4. **验证框架**：8 张标准测试图 + 人工标注的标准答案（GROUND_TRUTH）+ 评分卡生成器（compare_results.py）。
5. **部署通道**：串口 COM10（CP210x，115200）+ 网口 SSH（板子 192.168.1.50，PC 192.168.1.100）。

## 阶段 1：发现核心问题 —— "跑通但结果乱"

- 系统能跑通、能出识别框，但**同一图片多次推理结果不同**（DETERM_CHECK identical=0）。
- 定位手段：给应用加 DIAG 插桩，打印输入/输出的 int8 校验和 → 确认"输入相同、输出不同"= **DPU 计算面不确定**。
- 当时（错误地）归因于：DPU 要求 `dpu_2x_clk` 严格等于 `m_axi_dpu_aclk` 的 2 倍，而原设计时钟比不对。
- **教训**：当时的归因方向后来被证明只是"问题之一"，真正的多层问题被后面的逐层剥离才全部挖出。

## 阶段 2：时钟域手术（BD 改造）

- `bd_clkfix2/3.tcl`：把 DPU m_axi、HP0/1/2、axi_smc_instr 移到 clk_wiz clk_out2(100MHz)，dpu_2x 移到 clk_out3(200MHz)，相机域留在 clk_out1。
- 构建脚本加入**硬门禁**（build_*.tcl）：综合后网表级校验 `dpu_2x_clk` 的驱动必须来自 clk_wiz 而非任何 FCLK，否则拒绝出片；WNS 必须为正。
- 产出 WNS=+0.44ns 的 `2xfix` 比特流。**但注意：这个比特流当时从未真正在板上跑起来过**（见阶段 4）。

## 阶段 3：部署通道的连环坑（SD 卡 / 串口 / 引导）

这一阶段占用了大量时间，问题全部是**工程环境类**而非算法类：

1. **SD 卡 BootROM 兼容性**：32GB 卡直插板子 SD 启动无任何串口输出 → BootROM 对该卡不兼容（静默失败）。改走 QSPI 引导链。
2. **SD FAT 分区反复损坏**：改用"在 Debian(EMMC) 里 dd 干净 FAT16 镜像到 p1 + 回读校验"的无竞态写入方案。
3. **串口登录正则**：`root@plnx_zturn:~#` 提示符与 `[~#] ` 正则不匹配 → 修为 `[~#]+ `。
4. **getty 之死**：短时间大量登录失败触发 systemd 限流，把串口 getty 杀死，控制台永久沉默。**教训：对登录提示符的自动化试探必须限速。**
5. **init=/bin/sh 下 OpenCV "NEON NOT AVAILABLE" 崩溃**：并非 OpenCV 问题，而是该环境下 `/proc` 未挂载，CPU 特性探测读不到。挂载 /proc 即恢复。
6. **USB 串口适配器是板子供电的**：板子每次断电，COM 口从电脑上消失再重枚举，**所有已打开的串口句柄全部失效**——这是连续几次"断电后收不到任何字节"假象的根源（上午 11:19 能看到 U-Boot 输出纯属旧监视器每 20 秒重开端口的侥幸）。

## 阶段 4：FCLK1 之谜与"假阳性 state"

- 时钟手术后 DPU 任务超时。逐层排查发现 FCLK1_CTRL 寄存器恒为 0（内核 clkc 驱动把"无消费者"的 FCLK1 门控）。
- `clk_ignore_unused`、APER_CLK_CTRL 门控位的尝试全部无效（且当时测试环境混乱，结论不可靠）。
- **关键解法**：不再纠缠 FCLK1，把 clk_wiz 输入从 FCLK1 改接到**唯一被证明存活的 FCLK0**（bd_fclk0in.tcl），重建比特流（WNS=+0.505，双门禁通过）。
- **同时发现重大假阳性**：`/sys/class/fpga_manager/fpga0/state` 读到 `operating` **不代表我们的比特流加载成功**——它只表示 PL 里"有"比特流（QSPI 里厂商出厂比特流）。事实上 2xfix 与 fclk0 两个新比特流在板上一度从未成功加载过，之前所有"验证"跑的都是厂商比特流。

## 阶段 5：无人值守引导体系（interceptor v1→v5）

板子物理断连（串口被拔、网线被拔、需要重启）期间，我们搭建了全自动接管体系：

| 版本 | 关键能力 | 失败原因/改进 |
|---|---|---|
| watcher | 串口探测 + Xilinx MAC ping 过滤公司网假响应 | 用错凭据暴打 Debian 登录（差点搞死 getty）→ 停用 |
| v1/v2 | 抓 U-Boot 横幅、ESC 狂发打断倒计时 | 串口设备重枚举杀死句柄 → v2 加自动重开端口 |
| v3 | 原始串口数据全量落盘（不再盲飞）、修好打断键逻辑 | 首次完整拦住倒计时、U-Boot 命令全通 |
| v4 | `setenv bootargs ... init=/bin/sh` 注入跳过坏的开机脚本，进 shell 删除 S96dpuboot | 解决 S96 里 insmod 段错误把内核打挂的问题 |
| v5 | init=/bin/sh → 手动挂载 → 配网 192.168.1.50 → 手动起 dropbear → SSH 接管 | 绕开 getty 挂起，成为最终稳定形态 |

**这一阶段把"物理按键断电重启"变成唯一需要人工的环节，其余全自动。**

## 阶段 6：逐层剥离——四层叠加问题的最终破案（当天）

### 第 1 层：fpga_manager 固件加载（两坑）
- 内核 dmesg 直接给出答案：`Invalid bitstream, could not find a sync word. Bitstream must be a byte swapped .bin file`
- 坑 A：.bin 必须是**字交换**格式（AA995566 → 6655AA99）。
- 坑 B：sysfs 加载必须 `echo 文件名 > firmware`（内核自己去 /lib/firmware 取），`cat 文件 > firmware` 会把文件内容当文件名。
- 加载成功后 `devmem 0x40000000` 读到 `0x0D9C13F1`——这一次是我们自己的 DPU。

### 第 2 层：FCLK0 频率（寄存器位域完全猜错）
- 症状：insmod 挂死内核（AXI 访问停在死时钟域）。
- 实测三颗 PLL：`IO_PLL_CTRL=0x1E00 → FDIV=30 → IO_PLL = 33.333×30 = 1000MHz`（**此前一直按 500MHz 假设**）。
- 查内核源码 `drivers/clk/zynq/clkc.c` 得到 FPGA_CLK_CTRL 真实位域：
  - SRCSEL = bits[5:4]（0/1=IO PLL，2=ARM PLL，3=DDR PLL）
  - DIV0 = bits[13:8]（6bit）
  - DIV1 = bits[25:20]（FCLK = PLL/(DIV0)，DIV1 实测对本 PLL 直连无效）
  - 门控 = 寄存器+8 的 bit0（1=禁止）
- **最终配置 `0x00201400`**：SRCSEL=0(IO PLL) + DIV0=20 → FCLK0 = 1000/20 = **50.000MHz 精确**。
- 旁证：DPU 任务耗时随配置精确变化（div10→0.25s，div20→0.1255s），反向验证频率正确。

### 第 3 层：驱动加载顺序
- dpu.ko 探针流程：从 DTB 的 `dpu_eu@40000000`（16MB 窗口）取基址 → 校验核心 0 签名 → 校验 `0x40F00000` 的核心 1 签名。
- **厂商出厂比特流没有 16MB 窗口** → 在厂商比特流上 insmod 必然总线 abort → 内核 oops（此前所有 S96dpuboot 开机 insmod 段错误的真因）。
- **正确顺序：先加载（我们的）比特流 → 再 insmod。**

### 第 4 层：输出污染输入缓冲（最隐蔽）
- 现象：DPU 任务能完成、中断正常，但同任务多次执行输出**每次都不同**——且**每次开机后整个漂移序列逐位重放**（run1=-7218229, run2=-7594799, run3=-7297247, run4=-7256802 永远一致）。
- 破案实验：给诊断程序加"每次执行后都解码"，发现 **RUN1 解码 raw=1 nms=1（检出狗！）**，之后全灭。
- 结论：**DPU 写输出的过程中污染了任务输入缓冲区**；第一次执行读到的输入是干净的，之后读的是被上一次输出覆写过的脏数据；由于污染内容取决于上次输出，整个序列呈现"确定性漂移"。
- **修复：每次执行前刷新输入缓冲区（重新 set_input_image）** → 4 次执行全部收敛到 -7218229，identical=1，每次都检出目标。

### 验收
8 图 × 标准答案：全部命中、全部 identical=1（评分卡见 `VALIDATION_SCORECARD_FINAL.md`）。识别质量优异（truck 99%、kite 95%、dog 98% 等）。

---

# 第三部分：问题—错误—解决—教训 总表

| # | 问题/错误 | 表层现象 | 真实根因 | 解决 | 教训 |
|---|---|---|---|---|---|
| 1 | DETERM identical=0（最初症状） | 同图不同果 | 多层叠加（见 #3/#5/#6） | 逐层剥离 | 表象是复合问题时，不要接受第一个"说得通"的解释 |
| 2 | 时钟比错误假设 | 归因于 1:1 或 1:6 | 修复时钟比后问题依旧 | 保留修复但不视为根治 | "修复后依旧"本身就是排除法的关键证据 |
| 3 | fpga 加载从未成功 | state=operating 假阳性 | .bin 未字交换 + cat 内容当文件名 | 字交换 + echo 文件名 | **对任何"成功"信号要构造反例验证其灵敏度** |
| 4 | insmod 段错误/内核 oops | S96 开机必挂 | 厂商比特流无 16MB 窗口，探针 0x40F00000 abort | 先载我方比特流再 insmod；删 S96 | 驱动与硬件形态（地址窗口）必须匹配 |
| 5 | FCLK1 死 → DPU 计算域死 | 任务超时 | 内核 clkc 门控 FCLK1；clk_wiz 输入死 | clk_wiz 输入改接 FCLK0 | 选择"被证明存活"的时钟源，而非"理论上该活"的 |
| 6 | FCLK0 频率错 → 算错/挂死 | insmod 挂内核 | IO_PLL 实为 1000MHz；位域猜错 | 实测 PLL + 查内核源码定位域 | **寄存器位域以内核源码为准，不靠记忆** |
| 7 | 每次断电串口"死了" | 0 字节 | CP210x 由板子供电，断电即重枚举 | 句柄死亡自动重开 | 监控程序要假设物理层随时重枚举 |
| 8 | 登录暴打搞死 getty | 串口永久沉默 | systemd 对登录失败限流 | 停用暴打；凭据先验证 | 对有状态的服务端要"慢速+已验证凭据" |
| 9 | init=/bin/sh 下 OpenCV 崩 | NEON NOT AVAILABLE | /proc 未挂载 | mount /proc | 环境差异伪装成代码 bug |
| 10 | SD 直启无输出 | 静默 | BootROM 与该卡不兼容 | 走 QSPI 链 | 引导失败先分 BootROM/UBOOT/kernel 三段 |
| 11 | DPU 输出污染输入 | 逐执行漂移但开机可重放 | 输出写覆写输入缓冲 | 每次执行前刷新输入 | "确定性漂移"≠随机错误，是状态机问题 |
| 12 | U-Boot 倒计时抓不住 | 错过打断窗口 | 横幅出现到超时只有 2s | 横幅即触发 ESC 狂发 | 对窄时间窗要"早触发、持续发" |

## 方法论总结（可直接复用的调试经验）

1. **一次只动一个变量**；每个实验必须能证伪。
2. **给"成功"信号构造反例**（假阳性检测）：state=operating 的教训。
3. **确定性可重放的"随机"不是随机**：开机逐位重放的漂移序列指向状态污染而非时序裕量。
4. **用任务耗时反推频率**：DPU 任务时间与 2x 时钟严格成反比，是最便宜的"频率计"。
5. **让内核自己说话**：dmesg 一行 "must be a byte swapped .bin" 顶几小时的猜测；寄存器位域查内核驱动源码而不是 TRM 记忆。
6. **构建脚本里放硬门禁**：网表级连线校验不过就拒绝出片，杜绝"以为改了其实没改"。
7. **全量原始日志落盘**：串口原始 RX 全量写文件，事后任何一步都能复盘。
8. **物理层问题先排查后软件**：串口消失 → 先查设备在位状态（Get-PnpDevice / PnP 事件日志）。

---

# 第四部分：知识点详解教程（为下一阶段预备）

## 4.1 Zynq-7000 时钟体系（本项目踩坑最深）

```
PS_CLK (33.333MHz 晶振)
   ├─ ARM_PLL (FDIV=40 → 1333MHz) → CPU
   ├─ DDR_PLL (FDIV=32 → 1066MHz) → DDR 控制器
   └─ IO_PLL  (FDIV=30 → 1000MHz) → 外设 + FCLK0..3
                                     │
        FPGA_CLK_CTRL (SLCR 0xF8000170 + 0x10×n):
        [5:4]  SRCSEL: 00/01=IO_PLL, 10=ARM_PLL, 11=DDR_PLL
        [13:8] DIV0（实测硬件按原始值分频：20 → 1000/20=50MHz）
        [25:20] DIV1（对 FCLK 实测不起作用）
        +8 偏移寄存器 bit0：1=门控禁止
```

- **内核 clkc 驱动**会在 late_init 阶段门控"无消费者"的时钟——设备树里没人引用的 FCLK 会被关掉（FCLK1 之死）。对策：给 FCLK0 挂一个消费者，或像本项目一样干脆不用它。
- **实测 PLL 频率的公式**：`IO_PLL_CTRL(0xF8000108) 的 [18:12]=FDIV；频率 = PS_CLK × FDIV`。
- **clk_wiz (MMCM)**：VCO = CLKIN × M / DIVCLK，7 系列 MMCM VCO 范围 600–1440MHz（-2 速度等级）。输入 50MHz、M=20 → VCO=1000 → out2=100（÷10）、out3=200（÷5）。**输入频率只要让 VCO 在范围内且输出满足时序，功能就正确**（同步逻辑与频率无关，只与建立时间有关）。

## 4.2 DPU (B1152) 时钟与地址

- 三组时钟：`s_axi_aclk`（控制口，FCLK0）、`m_axi_dpu_aclk`（核心时钟，= clk_wiz out2 100MHz）、`dpu_2x_clk`（计算阵列时钟，必须精确 = 2× m_axi，且**同源同 MMCM** 以保证相位）。
- dpu_eu 包装器内含 **2 个 B1152 核心**，占据 **16MB 窗口**；DTB 节点 `dpu_eu@40000000`，核心 0 在 +0x0，核心 1 在 +0xF00000。
- dpu.ko 探针顺序 = 先读 DTB 基址 → 校验核心 0 签名 `0x0D9C13F1` → 校验 +0xF00000 核心签名 → 创建 `/dev/dpu`。
- 中断：`IRQ61 dpu_isr`，每个任务 2 次（双核各一）。
- **性能基线**：tiny-yolo 416×416 单任务 @2x=200MHz = **125.5ms**（约 8 FPS 上限）。

## 4.3 fpga_manager（zynq-fpga）使用规范

```bash
# 1) .bin 必须是字交换格式：每 4 字节反序（AA995566 → 6655AA99），同步字在 offset 48
# 2) 放入 /lib/firmware/
# 3) 加载（用文件名！不是 cat 内容）：
echo 0 > /sys/class/fpga_manager/fpga0/flags
echo design_1_wrapper.bin > /sys/class/fpga_manager/fpga0/firmware
cat /sys/class/fpga_manager/fpga0/state     # operating
```

- ⚠️ `state=operating` 是**假阳性重灾区**：加载失败时它显示的是"上一个仍在运行的比特流"。真验证 = 读 DPU 签名寄存器（`devmem 0x40000000` == `0x0D9C13F1`）或 dmesg 无 "Invalid bitstream"。
- 从 .bit 提取并字交换的脚本：`board_deploy\bit2bin.py` + `board_deploy\swapbin.py`。

## 4.4 引导链与无人值守接管

```
上电 → BootROM(QSPI) → FSBL(加载QSPI比特流+初始化PS) → U-Boot(倒计时2s)
  → 默认链: 引导 EMMC Debian（厂商系统）
  → 我们拦截: ESC 打断 → setenv bootargs 'root=/dev/mmcblk0p2 rw init=/bin/sh'
     → fatload mmc 0:1 0x2000000 image.ub → bootm
     → PetaLinux kernel 4.19 → /bin/sh (跳过全部 rc 脚本)
     → mount proc/sys/dev → ifconfig eth0 192.168.1.50 → dropbear → SSH 接管
```

- FIT 镜像（image.ub）的 bootargs 会被 U-Boot env `bootargs` **覆盖**（fdt_chosen fixup）——这是注入 `init=` 的通道。
- 板载串口适配器是**板子供电**的：板子断电 = USB 设备消失重枚举 = 所有已打开串口句柄失效，程序必须自动重连。
- U-Boot 倒计时窗口只有 ~2 秒：见到 U-Boot 横幅就持续发 ESC，不要等 "Hit any key"。

## 4.5 DNNDK 软件栈与"输入污染"机制

```
tiny_yolo_image
 ├─ dpuOpen()          ← /dev/dpu
 ├─ dpuLoadKernel()    ← dpu.xmodel (指令+权重 ELF)
 ├─ dpuCreateTask()    ← 分配输入/输出/中间缓冲区（一段连续 DDR）
 ├─ set_input_image()  ← CPU 写输入区（resize+量化 int8）
 ├─ dpuRunTask()       ← ioctl → 驱动 flush/invalidate → DPU 取指/读输入/写输出 → ISR
 └─ 读输出 → NMS → 画框
```

- **污染机制**：DPU 写输出的物理写入会波及任务缓冲区内相邻区域（输入区），第 2 次执行读到的输入已被第 1 次输出改写。表现为"确定性漂移"（每次开机漂移序列完全一致）。
- **修复（已固化）**：每次执行前重新 `set_input_image`。对实时视频场景这**天然满足**——每帧都是新输入，问题自动消失。
- Zynq-7000 的 HP 口**不带硬件缓存一致性**，CPU 与 DPU 之间的数据同步依赖 DNNDK 驱动在 ioctl 里做 cache flush/invalidate——所以应用层绝不能绕过 DNNDK 直接改任务缓冲区后不做同步。

## 4.6 PetaLinux 根文件系统要点

- sysvinit：`/etc/rc5.d/S*` 按序执行；一个脚本挂死=整个引导挂死（syslog→getty 之间曾经卡住）。
- 救援模式：`init=/bin/sh` 绕过全部 rc 脚本，进 shell 后手动 `mount -t proc none /proc; mount -t sysfs none /sys; mount -t devtmpfs none /dev`。
- 串口 root 登录受 `/etc/securetty` 限制（Debian 侧 root 直接被拒），而 dropbear/SSH 不受限——**能走 SSH 就别走串口登录**。
- rootfs 是 SD 卡 p2 的 ext4（rw 挂载）→ 直接改板上的 `/usr/bin` 就等于改产品固件，重启持久生效。

---

# 第五部分：下一阶段规划 —— OV5640 实时目标识别

## 5.1 现状盘点（BD 里已有的相机资产）

BD 中已存在且已连通（clkfix2/3 时期的布线）：

| 组件 | 现状 | 说明 |
|---|---|---|
| `ov5640_cam_top`（自研 RTL） | 在 BD 中 | DVP 并口接收 + 内部 I2C（`I2C_OV5640_1280720_Config.v`，1280×720 配置） |
| 相机域时钟 | clk_wiz clk_out1 = 100MHz | `ov5640_0/ACLK` 与 HP3 同域 |
| `axi_vdma_0` | 只配了 **s2mm**（相机→DDR），64bit，1 个 frame store | **没有 mm2s**（无回写显示通路） |
| ⚠️ 已知 DRC | 相机复位 `proc_sys_reset_1` 在 FCLK0 域，而相机时钟在 clk_out1 域 | validate 时有 CRITICAL WARNING，**必须修复** |
| 显示输出 | **无** | MZ7X 无现成 HDMI/ VGA 管线 → 结果走网络（正好我们有 Web UI） |

## 5.2 总体架构方案

```
OV5640 (DVP, 720p@30) ──► ov5640_cam_top ──► VDMA s2mm ──► HP3 ──► DDR 帧缓冲(0x1xxxxxxx)
                                                                     │
 CPU 应用循环 (每帧):                                                  ▼
   1. 等 VDMA 帧完成 (s2mm ioctl/DMA中断 或 轮询 s2mm 状态)     /dev/mem 直读帧缓冲
   2. /dev/mem 或 VDMA 读出 1280×720 RGB565 → cv::Mat           (无需 mm2s)
   3. cv::resize → 416×416 + 量化 int8 (替代现有慢速 float resize)
   4. set_input_image → dpuRunTask → 输出                     (~125ms @200MHz)
   5. NMS 解码 + 画框                                           (<5ms)
   6. 结果推流: Flask Web UI (M-JPEG / WebSocket) ← PC 浏览器
```

**吞吐预算（首版目标 5 FPS，优化后 7-8 FPS）**：

| 环节 | 预算 | 依据/优化手段 |
|---|---|---|
| VDMA 写帧 | ~15ms（720p@30 管道内流水，不阻塞） | 30FPS 摄像头自带节拍 |
| 取帧+格式转换 | ~10ms | RGB565→BGR888 CPU 循环可 NEON 化 |
| resize+量化 | ~8ms | **必须替换现有 0.34s 的 float resize_image**（用 cv::resize INTER_AREA/NEAREST） |
| DPU 推理 | 125.5ms | 可选优化：2x 提速到 300MHz → ~84ms（需重定时） |
| NMS+绘制+编码 JPEG | ~15ms | JPEG 质量 70 |
| **合计** | **~175ms ≈ 5-6 FPS** | 首版达标线：≥4 FPS |

## 5.3 分步实施计划（每步带验证门禁）

### Step 1：修相机复位域 + 相机点活（0.5 天）
- BD：为 clk_out1 域加独立 `proc_sys_reset`（ext_reset_in=FCLK_RESET0_N，slowest_sync_clk=clk_out1），把 `ov5640_0/ARESETN`、VDMA 相应复位改接到新复位块；消除 validate 的 CRITICAL WARNING。
- VDMA s2mm 目标地址设到 DDR 空闲段（如 0x10000000，避开 CMA 0x30000000 和内核）。
- **门禁**：板子上电（FSBL 载出厂比特流也行）→ 相机上电 → 用 devmem 读 VDMA 状态寄存器 `s2mm status`（0x40040034 附近）确认 `HALTED` 位清除、`SGIncld` 计数增长；`/dev/mem` 读帧缓冲地址看到**随画面变化的非零数据**（镜头遮黑应接近 0）。

### Step 2：单帧抓取程序（0.5 天）
- 写 `grab_frame`：ioctl VDMA 启动 s2mm → 轮询完成 → `/dev/mem` 拷贝 1.84MB 到用户态 cv::Mat → 存 PNG。
- **门禁**：PC 端打开 PNG，人眼确认画面（对焦、方向、色彩条）。

### Step 3：接入 DPU 推理闭环（0.5 天）
- grab_frame + 现有 diag4 推理路径拼成单帧"拍照→识别"命令行工具。
- **门禁**：摄像头对着打印的标准答案图片（先用 kite.jpg 打印件）→ 命令行输出对应类别与框。

### Step 4：实时循环 + Web 推流（1 天）
- 主循环按 5.2 的预算串联；Web UI 增加 `/stream`（M-JPEG，multipart/x-mixed-replace）与最近检测结果 JSON。
- **门禁**：浏览器 4 FPS 以上流畅出框；手在镜头前晃动，框跟随延迟 < 400ms。

### Step 5：性能优化 + 稳定性（1 天）
- 替换 letterbox 为 cv::resize 直缩放（YOLO 输入对比例失真不敏感，先直缩放，精度损失后续再评估 letterbox）。
- DPU 2x 提频评估：50→66.7MHz 输入（VCO 1333 合法）→ 2x=266MHz，任务 ~94ms；需重跑时序确认 WNS>0。
- 连续运行 1 小时无死机、无内存泄漏（top 观察）。
- **门禁**：1 小时压测 + FPS 曲线平稳。

### Step 6：产品化固化（0.5 天）
- 修复版应用固化进 rootfs（本次已装 /usr/bin，视频版替换后同样操作）。
- 上电自启动脚本（谨慎：先手动验证后放 rc5.d，脚本必须包含"比特流已由 FSBL 加载"与"DPU 驱动 insmod"两步）。
- **门禁**：整板断电重启 → 自动进入识别服务（无需人工 SSH）。

## 5.4 需要预备的知识清单（按优先级）

1. **Xilinx AXI VDMA 驱动**（PG022 + kernel `drivers/dma/xilinx/xilinx_dma.c`）：s2mm 的寄存器（MM2S/S2MM_DMACR、status、start address）、非 SG 模式 direct register 轮询法（最简单）、中断法。
2. **OV5640 DVP 时序**：PCLK/HREF/VSYNC 极性与 cam_top RTL 对齐；720p RGB565 输出格式寄存器（我们的 I2C 配置 IP 已固化为 1280×720，确认输出格式是 RGB565 还是 YUV422——**看 cam_top RTL 的像素打包**）。
3. **/dev/mem + mmap 直读 DDR**：`open("/dev/mem") + mmap` 帧缓冲基址；注意 DDR 物理地址与 CPU 虚拟地址映射。
4. **OpenCV 移动端优化**：`cv::resize` 在 NEON 上的表现、`cv::imencode(".jpg")` 的耗时控制。
5. **M-JPEG 推流协议**：HTTP multipart boundary 写法；Flask `Response(generator, mimetype='multipart/x-mixed-replace')`。
6. **中断与线程**：应用里 VDMA 完成中断（或轮询）与推理线程的解耦（双缓冲防撕裂：VDMA 写 A 帧时处理 B 帧）。

## 5.5 风险与预案

| 风险 | 概率 | 预案 |
|---|---|---|
| 相机复位域修复后仍不出图 | 中 | 分段示证：先看 VDMA 是否收到数据（读 DDR 变化），再查 I2C 配置是否完成（cam_cfg_done 信号，BD 里有该端口），最后查 PCLK/HREF/VSYNC 极性 |
| RGB565/YUV 格式判断错 | 中 | 抓一帧 PNG，纯色对准镜头看通道分布；错则改 swizzle |
| HP3 带宽与 DPU 抢占 | 低 | 720p RGB565 仅 ~442MB/s，DDR3 1066MHz×4B 足够 |
| DPU 提频后时序不过 | 低 | 保留 100/200 稳定档；提频作为独立实验分支 |
| getty/rc5.d 挂死影响产品自启动 | 中 | 产品自启动脚本放 rc5.d 时逐个验证；必要时仍用 init=/bin/sh + 自启动 shell 的兜底方案（当前验证形态已证明稳定） |
| 长跑内存泄漏 | 中 | cv::Mat 复用、DNNDK task 常驻不复建；top 监控 |

## 5.6 明确的"完成定义"（DoD）

1. 上电 → 自动进入识别服务（无人值守）
2. 浏览器实时画面 + 检测框，≥4 FPS，端到端延迟 < 400ms
3. 标准答案图片实测：对相机展示 8 张测试图，全部正确检出
4. 1 小时连续运行无崩溃
5. 全套产物归档：新 .bit/.bin/BOOT.BIN/rootfs、应用源码、脚本、文档（沿用本次的归档结构）

## 5.7 实施进展（2026-09-24 凌晨更新）

**原项目相机通路的三处结构性缺陷已全部定位并修复：**

| # | 缺陷 | 修复 |
|---|---|---|
| 1 | VDMA 控制口 S_AXI_LITE 未连接（软件无法配置） | 接入 SmartConnect M01 分支，地址 0x43C00000/64K |
| 2 | VDMA 存储通路缺失（M_AXI_S2MM → HP3 互连不存在） | 复刻原厂 v10 蓝图：vdma_icc（AXI 互连+FIFO+regslice） |
| 3 | 相机数据口 cmos_data[7:0] 顶层端口从未创建（数据线悬空绑 0） | 创建端口并接入 ov5640_0 |

**额外发现并修复的性能缺陷**：相机模块的异步 FIFO（1024×18b）被综合成 **1.9 万个触发器 + 6.4K LUT**（跨时钟读优先语义阻断 BRAM 推断），改为标准 BRAM 模板后省出 ~3,500 slices——这正是"加了相机通路就超容量"的原因（此前双核 DPU 设计已用到器件 95% 的 slice）。

**当前卡点（物理层）**：新比特流（含完整相机通路）已构建成功并部署，VDMA 能正常完成帧传输，但抓到的帧 99.3% 为 0xFF——**数据线浮空，相机模块未驱动总线**。已排除软件因素（I2C 配置由 PL RTL 自动执行、位流已验证、抓帧链路已验证）。等用户做排线重插/方向/型号检查后，一上电即可自动完成抓帧验证（morning_run.py 已布防）。

**经验补充**：
- `ram_style = "block"` 属性不是万能的——当存储读与带复位的寄存器逻辑混在同一个 always 块时，综合器仍会拒绝 BRAM 推断；必须把存储读分离到独立 always 块（标准 BRAM 模板）。
- 利用率报告要跑 `report_utilization -hierarchical`（从 open_run 打开的完整设计），黑盒子检查点看不到 IP 内部。
- 跨时钟域 FIFO 的指针路径（灰码 CDC）时序违例是良性的（格雷码本身就是为此设计），应在 XDC 中 set_max_delay -datapath_only 收敛而不是当真违例处理。

---

# 附录 A：板上命令速查（已验证可用）

```bash
# ---- 时钟（FCLK0 = 50MHz 精确）----
devmem 0xF8000108                     # IO_PLL_CTRL, FDIV=[18:12]（实测 30 → 1000MHz）
devmem 0xF8000170 32 0x00201400       # SRCSEL=IO_PLL(0) DIV0=20 → FCLK0=50.000MHz
devmem 0xF8000178 32 0x00000000       # 解除 FCLK0 门控
devmem 0xF8000170                     # 回读应为 0x00201400

# ---- 加载比特流（.bin 必须字交换！）----
echo 0 > /sys/class/fpga_manager/fpga0/flags
echo design_1_wrapper.bin > /sys/class/fpga_manager/fpga0/firmware
cat /sys/class/fpga_manager/fpga0/state            # 期望 operating
devmem 0x40000000                                  # 期望 0x0D9C13F1（真验证）

# ---- DPU 驱动（必须在比特流加载之后！）----
insmod /home/root/dpu.ko                            # dmesg 应见 "DPU signature checking done!"
ls -la /dev/dpu
cat /proc/interrupts | grep dpu                     # IRQ61 计数随任务增长

# ---- 推理（输入刷新修复版）----
cd /home/root && ./tiny_yolo_image_diag4 blackdog.jpg
# 期望：DETERM_CHECK identical=1 且 RUN1/RUN2 都检出目标
```

# 附录 B：PC 端工具速查

```powershell
# 串口自动引导（板子断电重上电后全自动接管）
python E:\yoloProject\board_deploy\interceptor5.py
# 全套验证（SSH 自动重试 + PLL实测 + FCLK0设置 + 加载 + insmod + 冒烟 + 批量）
python E:\yoloProject\board_deploy\autotest_fclk0.py
# .bit → 字交换 .bin
python E:\yoloProject\board_deploy\bit2bin.py in.bit out.bin
python E:\yoloProject\board_deploy\swapbin.py
# 评分卡
python E:\yoloProject\board_deploy\make_scorecard.py
```

# 附录 C：本阶段产物归档清单

| 类别 | 文件 |
|---|---|
| 比特流 | `sd_delivery\design_1_wrapper_fclk0.bit`、`web\design_1_wrapper_fclk0_sw.bin`、`sd_delivery\BOOT_NEW_FCLK0.BIN` |
| BD/构建脚本 | `vivado_projects\scripts\bd_fclk0in.tcl`、`build_fclk0.tcl`（含网表级门禁） |
| 应用源码 | `board_deploy\tiny_yolo_image_diag.cpp`（含输入刷新修复，VM 配方已同步） |
| 诊断/测试 | `autotest_fclk0.py`、`decisive_test.py`、`batch_fixed.py`、`make_scorecard.py` |
| 引导接管 | `interceptor3/4/5.py`、`uboot_boot_fclk0.py`、`listen_pure.py` |
| 文档 | `FCLK0_ROOT_CAUSE.md`、`VALIDATION_SCORECARD_FINAL.md`、本文档 |

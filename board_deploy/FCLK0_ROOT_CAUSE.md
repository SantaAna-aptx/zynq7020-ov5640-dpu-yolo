# DPU 计算死机：证据收敛与修复计划（FCLK0 重接线）

生成时间：2026-09-22 上午。本文档由自主会话生成，记录"为什么确定是时钟问题、为什么改成 FCLK0、接下来怎么验证"。

## 一、证据链（为什么范围收敛到"clk_wiz 输入时钟 = FCLK1 死亡"）

| # | 事实 | 来源 |
|---|---|---|
| 1 | DPU 签名寄存器 0x40000000 读到 0x0D9C13F1 → **S_AXI 控制口活着** | 板上 devmem |
| 2 | S_AXI 控制口时钟 = **FCLK_CLK0**（BD 网表确认） | clkfix2.log AFTER dump |
| 3 | FCLK0_CTRL(0xF8000170) 在内核 late_init 之后仍读回 0x00400A00（除频 10，使能）→ **FCLK0 实测存活** | 板上 devmem |
| 4 | 昨晚 DPU 能跑计算（m_axi 当时接 FCLK0）→ **FCLK0 能进 PL 并驱动数据面** | 昨晚验证记录 |
| 5 | DPU 任务超时、dpu_isr=0、AP_CTRL=0 → **计算域（m_axi/2x）死** | dpu_state.log |
| 6 | 计算域唯一来源 = clk_wiz（clk_out2=100M, clk_out3=200M），clk_wiz 输入 = **FCLK_CLK1** | bd_clkfix2.tcl 注释 + BD 文件 |
| 7 | FCLK1_CTRL(0xF8000174) 写入不保持，读回 0x00000000 → **FCLK1 死亡** | 板上 devmem |

结论：6→7→5→(3,4) 构成完整闭环。**FCLK1 是设计中唯一未被证明存活的时钟，而它恰好是计算域的唯一源头。**

已排除：
- 内核门控假设的"clk_ignore_unused 无效"反例：该测试运行在 init=/bin/sh 环境下，参数可能根本没进 cmdline（U-Boot 引导链不带），结论不可靠 → 不影响本修复
- 复位卡死假设：ext_reset_in 全部正确接 FCLK_RESET0_N，复位域时钟归属正确；dcm_locked 未连接——但昨晚同一接法能跑通，排除
- 1:1 时钟比假设（旧 DETERM=0 的根因）：新设计已是精确 2:1 同 MMCM，构建门禁已验证

## 二、修复（已执行）

**bd_fclk0in.tcl**：`clk_wiz_0/clk_in1` 从 FCLK_CLK1 网改接 **FCLK_CLK0** 网（50.000MHz，与 PRIM_IN_FREQ=50 精确匹配 → VCO=1000MHz → clk_out2=100.000M / clk_out3=200.000M 精确）。
- BD 已改、validate 通过、FCLK_CLK1 网完全悬空（无害）
- **build_fclk0.tcl** 重建比特流，含两道硬门禁：
  1. dpu_2x_clk 不得由任何 FCLK 驱动
  2. （新增）clk_in1 必须由 FCLK_CLK0 网驱动，否则拒绝出片
- WNS 要求 >0（上版 +0.44ns，本次频率不变应一致）

## 三、验证计划（板上，autotest_fclk0.py 一键执行）

1. **通道发现**：串口（自动枚举非蓝牙 COM）→ 登录 → 配网；或直接 SSH 192.168.1.50/.10
2. **加载**：SFTP 传 design_1_wrapper_fclk0.bin → fpga_manager 加载 → state=operating
3. **冒烟**：devmem 签名 → insmod dpu.ko → tiny_yolo_image blackdog.jpg（180s 超时）
4. **鉴别探针**（若仍挂起）：后台跑任务 + 读 AP_CTRL(0x40000008)/中断计数：
   - AP_CTRL bit0 置位 + 无中断 → 计算时钟域仍死（clk_wiz 未锁定）→ 下一层排查 MMCM 参数
   - AP_CTRL 全零 → 控制口写路径/复位问题 → 检查 proc_sys_reset
5. **DETERM**：应用内建，输出 `DETERM_CHECK identical=1` 即确定性通过
6. **8 图批量** → autopilot_exec.log → compare_results.py 评分卡
7. **交付物**：VM 内 petalinux-package 重打 BOOT_NEW_FCLK0.BIN（FSBL+新比特流+U-Boot）

## 四、执行状态（2026-09-22 上午更新）

- ✅ bd_fclk0in.tcl：clk_in1 已改接 FCLK_CLK0，validate 通过
- ✅ build_fclk0.tcl：构建完成，**WNS=+0.505ns**，双门禁通过（dpu_2x←clk_wiz clkout3；clk_in1←FCLK_CLK0 网表级确认）
- ✅ design_1_wrapper_fclk0.bin（4045564B，md5 db3c036208723d37eb16f877007cdd30）
- ✅ BOOT_NEW_FCLK0.BIN（4568776B，md5 c25bfa27a7b8098c136b80728723d627，FSBL+新比特流+U-Boot，SD 启动产品件）
- ✅ autotest_fclk0.py：一键板上验证脚本（通道发现→加载→冒烟→鉴别探针→DETERM→8图批量）
- 🔄 watcher_fclk0.py 后台监视中：每 20s 探测串口流量 / 带 Xilinx MAC(00-0A-35) 的 ping；任一通道恢复即自动执行全套验证

## 六、最终结果（2026-09-22 晚）

**🏆 验收通过：8/8 图片命中全部标准答案，8/8 DETERM identical=1。**

完整修复链（四层问题逐层剥离）：
1. **时钟源**：clk_wiz 输入 FCLK1（被内核 clkc 门控，寄存器恒 0）→ 改接 FCLK0
2. **时钟频率**：实测 IO_PLL=1000MHz（非 500！）→ FCLK0_CTRL=0x00201400（IO_PLL mux bit21 + DIV0=20）→ FCLK0=50.000MHz 精确 → m_axi=100/2x=200 精确 2:1
3. **固件加载**：zynq-fpga 驱动要求**字交换 .bin**（否则 "Invalid bitstream, could not find a sync word"）且通过 `echo 文件名 > firmware` 加载；`state=operating` 在加载失败时也是假阳性（显示的是 QSPI 厂商比特流）
4. **驱动顺序**：必须先加载比特流再 insmod（dpu.ko 探针访问 dpu_eu 16MB 窗口内 0x40F00000；厂商比特流无此窗口 → insmod 段错误/内核 oops）
5. **计算正确性**：DPU 输出写会污染任务输入缓冲区（每次执行后输入被改写 → 后续执行读脏数据 → 确定性漂移）；第一次执行的计算始终正确（RUN1 检出目标）。**修复：应用在每次执行前刷新输入缓冲区** → DETERM identical=1，8 图全检出
6. **开机卡死**：根因 rc5.d 里旧 S96dpuboot 在坏比特流状态下 insmod 导致内核 oops；已删除该脚本。另 getty 启动阶段存在挂起问题（产品开机流程待加固——当前验证环境用 init=/bin/sh + 手动配网/起 SSH 绕开）

关键产物：
- sd_delivery/design_1_wrapper_fclk0.bin（字交换版，md5 456d272a）
- sd_delivery/BOOT_NEW_FCLK0.BIN（FSBL+修复比特流+U-Boot，md5 c25bfa27）
- 板上 /usr/bin/tiny_yolo_image = 输入刷新修复版（md5 cab658fb，已固化到 SD p2 rootfs）
- VALIDATION_SCORECARD_FINAL.md（8/8 PASS 评分卡）
- batch_fixed_results.log（完整 8 图原始输出）

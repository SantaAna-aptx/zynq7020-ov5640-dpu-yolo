
# 统一设计（DPU+相机）会话总结 — 2026-10-09

## 重大成果（全部验证）

1. **统一比特流编译成功并加载运行**：2019.1 从零重建 unified 工程（DPU B1152 + cam_top 相机采集 + VDMA S2MM + PS7 全量 MZ7X 参数 + 50MHz 时钟方案），fpga_manager 加载 operating，**DPU 签名 0x0D9C13F1 读出**——DPU 在统一设计里活着。
2. **完整工程重建工具链**：build_unified_v2.tcl（BD 生成）+ build_unified_stage2b.tcl（编译）+ gen_system_top.py（顶层生成，sda 三态拆分+IOBUF）+ transfer_and_verify.py（断点续传传输）。每一环都实测通过。
3. **相机硬件已被证明可工作**（老师组合 JTAG 验证：直插模组实时出图）——CEP 座/Bank35/时钟链硬件无问题。
4. **root 密码解锁**：SD 与 eMMC 双 rootfs shadow 均写入板上 crypt 生成的 hash（应为 yolo123），但 login 仍拒（securetty 有 ttyPS0；PAM 层原因未明）。dropbear -w 假说未及验证。

## 当前唯一未通：统一设计里的相机流（DDR 零写入）

统一 bit 下：VDMA S2MM running（Halted=0）、dbg 探针 GPIO @0x41220000 external abort（探针自身的 AXI 访问也异常——0x41220000 段可能整体未正确映射到 AXI，或加载的 bit 与预期不符——md5 d612674b 与上一版相同存疑，需核验 impl 重跑是否真正包含 M02/dbg 变更）。

cam_top→相机链的可能断点（按概率）：
1. dbg_gpio 探针本身未正确进 bit（地址映射/综合问题）——**先解决探针可读性**
2. cam_top 自愈 SCCB 引擎（PL 33kHz）在 MZ7X 上的 I2C 时序/上电窗口问题
3. cam_top retry FSM 的 pclk 判定窗口与实际相机启动时间不匹配
4. I2C_OV5640_1280720_Config LUT（奥唯思表）与直插模组（老师款）参数差异

## 换模块后（或继续调试时）的验证流程

1. 复位 → U-Boot 抓取 → init=/bin/bash → /mnt2 tmpfs
2. transfer_and_verify.py（断点续传传 unified.bin → 加载 → FCLK0=50 → VDMA 启动 → dbg 读数 → 帧样本回传）
3. dbg_pclk_cnt 读数判定：变化=PCLK 活（相机在输出）；不变=XCLK/配置问题
4. i2c_done=1 且 pclk 活 → DDR 应出帧 → 渲染验证

## 关键文件

- unified 工程：E:/yoloProject/vivado_projects/unified（2019.1）
- 统一 bin：E:/yoloProject/board_deploy/unified.bin（最新=d612674b，注意核验 impl 重跑是否包含最终 BD）
- 脚本：build_unified_v2.tcl / build_unified_stage2b.tcl / gen_system_top.py / transfer_and_verify.py / instant_takeover.py
- 老师 bit（已验证出图）：simple-version system_wrapper.bit + cam_5640.elf（JTAG 流程已验证）

## 已知坑（新会话必读）

- 2019.1 安装（D:ivado2019.1）间歇性 IP 脚本读取失败（builtin.tcl/xguifrmwork）——重试可过
- Vivado batch 会被 Bash 工具的 cancel 连带杀掉——用 run_in_background 且避免中途 cancel
- axi_vdma 引脚名（2019.1）：s_axi_lite_aclk/m_axi_s2mm_aclk/axi_resetn（非 s_axi_aclk/m_axi_aclk）
- axi_gpio 输入引脚不支持位选——总线整体连接
- 串口 LF-only；/tmp 是死链接（写 /home/root）；rootfs 满勿放大文件（用 tmpfs）
- transfer_and_verify 断点续传按 .p_N 文件存在性跳过——换 bin 后必须 rm -f /mnt2/unified.p_*
- 正常启动走 eMMC rootfs（root:*锁定+securetty 有 ttyPS0+密码对仍拒=PAM 层未明）；调试用 U-Boot 接管 init=/bin/bash


## 追加：XSDB 白名单发现（2026-10-09 深夜）

读 dbg_gpio @0x41220000 的 external abort 有**两个独立来源**，均已定位：
1. **XSDB/hw_server 层**：`Memory read error...PL AXI slave ports access is not allowed. This address has not been added to the memory map`——hw_server 2023.2 对 JTAG 内存访问引入 PL AXI 地址白名单。**mrd -force 静默失败**；configparams -mem-map 不是有效语法。**正解**：hw_server 启动参数 -mem-map（语法需查 UG 文档）或换 xsdb 版本。
2. **Linux /dev/mem 层**：kernel external abort = PL 真无响应（dbg_gpio 是否真在 bit 内仍需 Linux 侧确认——diag2 流程从未读过 probe GPIO，留作下次首测）。

## 统一 bit 版本疑云（已澄清）

impl_1/design_1_wrapper.bit（10-09 15:20，M02 时钟修复后）转换的 unified.bin md5 = d612674b，与更早版本相同——Vivado 确定性综合下 BD 逻辑未变（M02 时钟连线不改变功能逻辑）时 bit 内容可以相同。**无法从 md5 判断 dbg_gpio 是否在 bit 内**——需 Linux 侧实测读 0x41220000（无 abort = 在）。

## 用户回来后的三选项

A. **修 XSDB 白名单**：查 hw_server 2023.2 -mem-map 语法（Xilinx 文档 UG 或论坛），声明 GP0 区间后 dbg_gpio 读数立即可得。成本最低。
B. **Linux 侧首测 probe**：SW1 拨回 QSPI → 复位 → 我接管 bash → /mnt2 → 传 unified.bin（30min）→ fpga_manager 加载 → **读 0x41220000**（Linux /dev/mem 无白名单——这一读是 dbg_gpio 在不在 bit 的终审判决）。
C. **物理验证**：JTAG 模式 + HDMI + 示波器/逻辑分析仪看 XCLK/PCLK（需要仪器）。

推荐顺序：A（查文档 10 分钟）→ B（成熟流程 40 分钟）。

# MZ7X YOLOv3-DPU 项目调试总结与全面扫盲指南

> 本文档由 AI 助手根据完整调试历史撰写，用于指导后续的系统性排查。
> 更新时间：项目上板调试阶段

## 一、系统架构（当前最终形态）

```
┌─────────────────────────────────────────────────────┐
│ MZ7X (Zynq-7020 XC7Z020-2CLG400)                     │
│                                                       │
│  PS (ARM Cortex-A9 ×2)          PL (FPGA)             │
│  ├─ DDR3 1GB @0x0-0x3FFFFFFF   ├─ dpu_eu B1152 单核   │
│  ├─ SDIO0 → TF 卡(启动+rootfs) │ │  ├ INSTR(32b)      │
│  ├─ SDIO1 → eMMC 8GB(出厂)     │ │  ├ DATA0(64b)→HP0  │
│  ├─ UART1 → USB_MINI(串口)     │ │  ├ DATA1(64b)→HP1  │
│  ├─ GEM0 → 网口(直连PC)        │ │  └ IRQ→IRQ_F2P[?]  │
│  ├─ FCLK0 → DPU 2x/m_axi/HP   ├─ axi_smc_instr→HP2   │
│  └─ FCLK1 → clk_wiz→100/150/300 ├─ ov5640→VDMA→HP3    │
│                                  └─ axi_smc→GP0(控制)  │
└─────────────────────────────────────────────────────┘
```

## 二、调试时间线与已修复问题

| # | 问题 | 根因 | 修复 | 状态 |
|---|------|------|------|------|
| 1 | INSTR 端口 32-bit 需要 smc 桥接 | B1152 INSTR 口 32-bit，直连 64-bit HP2 失配 | axi_smc_instr 桥接 | ✅ |
| 2 | dpu.ko probe Oops | PL 未配置（U-Boot $filesize 变量空） | loadb 用固定数字 | ✅ |
| 3 | 串口无登录提示 | rootfs inittab 缺 ttyPS0 getty | 板端修 inittab | ✅ |
| 4 | DPU 中断号错误（61→68） | 交接配置换算错误 | dts 修正 | ⚠️ 待 GIC 实验终审 |
| 5 | DPU 任务超时（时钟假说） | clk_wiz 50MHz 参数化 vs FCLK0 实际频率失配 | 多方案：PRIM 修正/reset 接地/FCLK 直驱 | ⚠️ 见六节分析 |

## 三、当前状态（最新一轮实测）

- FPGA：FCLK 直驱版位流（c74e7a10）已加载 ✓
- FCLK0：50.8MHz（devmem 0x00400A00）✓
- **DPU IRSR = 1**（首次出现！之前全为 0）→ **DPU 核心疑似已完成任务并挂起中断**
- GIC 中断 100（SPI 68）已注册但计数 0
- **待实验**：运行中读 GIC ISPR 全寄存器（0xF8F01200-0xF8F01214），定位真实中断线

## 四、全面扫盲清单（每个层面必须核对的项目）

### L1. Vivado BD 层
- [ ] DPU_eu CONFIG：ARCH=1152、核心数 1、S_AXI_FREQ=50、M_AXI_FREQ=150（IP 内部参数化假设）
- [ ] 时钟连接：2x_clk/m_axi/HP_ACLK/smc_instr aclk 全部 FCLK0；s_axi_aclk/ov5640 全部 clk_out1
- [ ] 复位：proc_sys_reset_0(150M域)、rst_300M(300M域)、proc_sys_reset_1(s_axi域) ext=FCLK_RESET0_N
- [ ] clk_wiz reset 接 const_rst0(dout=0)
- [ ] 中断：dpu_interrupt→IRQ_F2P[0]（LEVEL_HIGH）
- [ ] 地址：DPU M_AXI×3 → HP0/1/2_DDR 段 off=0 range=1GB；DPU S_AXI→GP0 0x40000000
- [ ] ov5640 引脚约束（camera.xdc）与 VDMA 连接

### L2. 位流
- [ ] date/time 与重建时间吻合（确认加载的是最新版）
- [ ] MD5 与构建产物一致

### L3. PetaLinux 设备树（system-user.dtsi）
- [ ] dpu@0x40000000 + dpucore(interrupts=<0 XX 4>，XX=真实中断号)
- [ ] xlnk 节点
- [ ] bootargs cma=256M
- [ ] console=ttyPS0

### L4. rootfs
- [ ] inittab getty（ttyPS0）
- [ ] dpu.ko（4.19.0-xilinx-v2019.1）
- [ ] libn2cube/libhineon/libdputils（配套版本）
- [ ] tiny_yolo_image + dog.jpg + dpu_tiny_yolo.elf
- [ ] OpenCV（/proc 挂载即检 NEON）

### L5. 运行时
- [ ] FCLK0 使能（0x00400A00 → 50.8MHz @ IO_PLL=508.3）
- [ ] RST_FPGA0 释放（0xF800021C=1）
- [ ] insmod dpu.ko
- [ ] GIC 注册验证：grep dpu /proc/interrupts

## 五、DPU 任务执行数据链（诊断用）

```
任务提交 → DPU 内置 DMA 经 HP 读 DDR 数据 → 核心执行（2x 域）
→ 完成置 ISR(bit0) + 拉高 dpu_interrupt → IRQ_F2P[0]
→ GIC SPI(61-91 段某号) → 内核 dpu_isr → counter+1 → n2cube 返回
```

## 六、终极诊断矩阵

| 症状组合 | 结论 | 修复方向 |
|---------|------|---------|
| ISR=1 运行中 + GIC ISPR 有挂起位 | 任务完成✓ 中断线活✓ | 内核中断号改为 ISPR 推算值 |
| ISR=1 运行中 + GIC ISPR 全 0 | 任务完成✓ 中断线断✗ | BD 中断连接/极性/电气 |
| ISR=0 + IRSR=1 + HP 计数涨 | 任务执行中卡死 | DPU 内部/时钟域 |
| ISR=0 + IRSR=0 + HP 计数 0 | 任务未开始 | 指令加载/时钟域 |

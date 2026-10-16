# MZ7X YOLOv3-DPU 项目软件层完整自查报告（COMPREHENSIVE AUDIT）

> 生成时间：2026-09-16
> 背景：上板调试发现 DPU 任务超时，经逐层排查定位多个根因并修复。
> 本文档记录全部已验证项、已修复项、待办项与永久化方案。

## 一、故障定位史（时间线）

| # | 现象 | 根因 | 修复 | 验证 |
|---|------|------|------|------|
| 1 | DPU INSTR 端口无地址映射 | BD 地址编辑器只有 DPU S_AXI 一条 | 确认 INSTR 经 axi_smc_instr 桥映射 | ✅ |
| 2 | dpu.ko probe 触发内核Oops（外部abort） | PL 未配置（fpga loadb 失败：$filesize 空变量） | U-Boot 里用固定数字 4045676 | ✅ |
| 3 | 系统启动无串口登录提示 | rootfs /etc/inittab 缺 ttyPS0 getty；且首次追加时 id 字段超 4 字符被拒 | 板端 sed 删坏行 + echo "s0::respawn:/bin/start_getty 115200 ttyPS0" >> /etc/inittab | ✅ |
| 4 | DPU 中断号错误 | 交接配置写 SPI 61，实际 IRQ_F2P[0]=SPI 68 | dts interrupts <0 61 4> → <0 68 4>，重建 image.ub | ✅（/proc/interrupts 显示 GIC-0 100） |
| 5 | DPU 任务提交后超时、核心不执行 | **clk_wiz MMCM 参数化输入 50MHz，但 PS FCLK0 实际输出与之不符 → MMCM 失锁 → 无任何 PL 时钟** | ① BB 改 PRIM_IN_FREQ=50 + clk_wiz reset 接地（位流 bb3）② 软件确认 FCLK0=50.8MHz（devmem 0x00400A00）③ 终极方案：**DPU/HP0-2/复位域时钟全部改接 FCLK_CLK0 直驱**（新位流 e42456b3） | 板端验证中 |

## 二、硬件层（Vivado BD）审计

### 2.1 时钟架构（FCLK 直驱版，当前位流 e42456b3）
| 时钟 | 来源 | 消费者 | 验证 |
|------|------|--------|------|
| FCLK_CLK0（50.8MHz，devmem 使能） | PS SLCR | dpu_eu_0/dpu_2x_clk（核心域） | 位流内连接 ✓ |
| FCLK_CLK0 | PS SLCR | dpu_eu_0/m_axi_dpu_aclk（HP 口） | ✓ |
| FCLK_CLK0 | PS SLCR | S_AXI_HP0/1/2_ACLK（PS 侧） | ✓ |
| FCLK_CLK0 | PS SLCR | rst_300M、proc_sys_reset_0 的 slowest_sync_clk | ✓ |
| clk_out1（100MHz） | clk_wiz（PRIM=50 修正） | DPU s_axi_aclk、axi_smc、VDMA lite、ov5640 ACLK | 保留（signature 读证明 clk_out1 活） |
| FCLK_RESET0_N | PS | proc_sys_reset_0/1/2/rst_300M ext_reset_in | 默认释放 ✓，另写 RST_FPGA0=1 保险 |

### 2.2 数据通路
- DPU DATA0→HP0、DATA1→HP1（64-bit 直连）
- DPU INSTR(32)→axi_smc_instr→HP2（32→64）
- DPU S_AXI→axi_smc→GP0（寄存器域）
- ov5640→VDMA→DDR（摄像头路径，待摄像头接入验证）

### 2.3 中断
- dpu_interrupt → IRQ_F2P[0]（LEVEL_HIGH）→ GIC SPI 68 → 内核 IRQ 100 → dpu_isr ✓

### 2.4 遗留警告（无害）
- cam_cfg_done 端口无物理引脚（DRC 降级）
- hp ACLK 的 FREQ_HZ 属性已统一 50MHz

## 三、软件层（PetaLinux）审计

### 3.1 设备树（system-user.dtsi，已上板验证 100 号中断）
- bootargs：console=ttyPS0,115200 earlycon root=/dev/mmcblk0p2 rw rootwait cma=256M ✓
- dpu@0x40000000 + dpucore(interrupts=<0 68 4>) ✓
- xlnk ✓
- ⚠️ 待办：无其他缺失

### 3.2 rootfs（已验证项）
- /usr/bin/tiny_yolo_image（内嵌 9MB 模型）✓
- /usr/lib：libn2cube/libhineon/libdputils ✓
- /home/root/dpu.ko（vermagic 匹配）✓
- OpenCV 3.4.3（NEON ✓ /proc 挂载即检）✓
- /etc/inittab：s0::respawn:/bin/start_getty 115200 ttyPS0 ✓
- Dropbear SSH ✓

### 3.3 版本配套
- dpu.ko ↔ libn2cube：check_driver_ver 通过 ✓
- 模型 dpu_tiny_yolo.elf：B1152 ✓

## 四、运行时依赖清单（每次上电）

### 4.1 手动引导路径（当前可用，出厂 U-Boot + 手动命令）
```
U-Boot: mmc dev 0 / fatload bit / fpga loadb 0 0x1000000 4045676 / fatload image.ub / bootm
Linux: devmem 0xF8000008 32 0xDF0D
       devmem 0xF8000170 32 0x00400A00      ← FCLK0 = 50.8MHz
       devmem 0xF800021C 32 0x00000001      ← 释放 PL 复位线
       insmod /home/root/dpu.ko
       tiny_yolo_image /home/root/dog.jpg
```

### 4.2 永久化（三选一，按优先级）
- **P0（立即可做）**：写入板端 /etc/rc.local（每次 init 自动 devmem+insmod）——需 rootfs 可写（rw ✓）
- **P1**：TF 档命中后，FSBL(ps7_init) 自动配 FCLK，仅需 rc.local insmod
- **P2**：hdf 重导出（PS 配置 FCLK0=50MHz）→ BOOT.BIN 重打包 → BOOT.BIN 全自动（FCLK+bit 都由 FSBL/U-Boot 完成）

## 五、验证结果

（板端验证进行中，结果追加于此）

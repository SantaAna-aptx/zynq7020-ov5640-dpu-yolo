# MZ7X (Zynq-7020) YOLOv3-tiny DPU — SD 卡交付与上板指南

> 项目：米联客 MZQ7X（XC7Z020-2CLG400）YOLOv3-tiny DPU 加速 + OV5640 摄像头
> 交付日期：2026-09-14　交付目录：`E:\yoloProject\board_deploy\sd_delivery\`

## 一、交付物清单（已验证）

| # | 文件 | 大小 | 说明 |
|---|------|------|------|
| 1 | BOOT.BIN | 4.57 MB | FSBL + **DPU v18 位流**（4.05MB bit，DPU B1152+OV5640+VDMA）+ U-Boot |
| 2 | image.ub | 4.16 MB | 内核 4.19.0-xilinx-v2019.1 + 设备树（dpu@0x40000000、IRQ 29、xlnk、cma=256M） |
| 3 | rootfs.ext4 | 479 MB | 根文件系统（内容见下） |
| 4 | design_1_wrapper.bit | 4.05 MB | 原始位流（备用/单独烧写 PL 用） |
| 5 | dpu.ko | 50 KB | DPU 驱动独立副本（rootfs 内已含） |
| 6 | dexplorer / ddump | ~100 KB | DNNDK 板端调试工具（rootfs 未内置，可后拷入） |

## 二、rootfs.ext4 内置内容（已挂载逐项验证 ✓）

- `/usr/bin/tiny_yolo_image` — DPU 推理程序（ARM hard-float ELF，**内嵌 9MB dpu_tiny_yolo.elf 模型**）
- `/usr/lib/libn2cube.so`、`libhineon.so`、`libdputils.so`(+3.4) — DNNDK v3.1 运行时
- `/home/root/dpu.ko` — DPU 驱动（vermagic 4.19.0-xilinx-v2019.1，与本内核精确匹配）
- OpenCV 3.4.x（124 个库文件）
- bootargs：`console=ttyPS0,115200 root=/dev/mmcblk0p2 rw cma=256M`

## 三、SD 卡制作步骤

1. SD 卡分区（若已分好则跳过）：p1 = FAT32 ≥64MB（启动），p2 = ext4 ≥1GB（rootfs）
2. 将 `BOOT.BIN`、`image.ub` 复制到 **p1（FAT32）根目录**
3. 将 `rootfs.ext4` 整体写入 **p2 分区**：
   - Windows：用 Win32DiskImager / balenaEtcher 选 rootfs.ext4 写入 p2 对应的盘
   - Linux：`sudo dd if=rootfs.ext4 of=/dev/sdX2 bs=4M conv=fsync`
4.弹出 SD 卡，插到 MZ7X 卡槽，启动开关置 **SD 档**

## 四、上电启动与验证

1. 串口连接 PC（115200-8-N-1），上电
2. U-Boot 自动引导 → 登录 `root` / `root`
3. 加载 DPU 驱动并验证：
   ```
   insmod /home/root/dpu.ko
   dmesg | grep -i dpu        # 应显示 DPU 探测（0x40000000, irq 29）
   ./dexplorer --v            # 可选：显示 DPU 版本与配置（需先拷入并 chmod +x）
   ```
4. 运行推理：
   ```
   tiny_yolo_image            # 加载内嵌模型，执行一次 YOLOv3-tiny 推理并打印检测结果
   ```
   正常输出：DPU 版本打印、推理耗时（B1152 单核约 100+ms/帧）、检测目标列表。

## 五、OV5640 摄像头

- 模块接 MZ7X 的 J5 摄像头座（20P CEP，引脚映射已按硬件手册核对，bank35 LVCMOS33）
- PL 数据通路：ov5640_cam_top（SCCB 初始化 + DVP 采集）→ AXI-VDMA → DDR
- RTL 已通过 xsim 全帧仿真；`cam_cfg_done`（SCCB 配置完成指示）为内部调试信号，硬件无此线，位流中自动放置于空闲 IO

## 六、软件验证状态（全部通过 ✓）

| 项 | 状态 |
|----|------|
| BD v18：DPU DATA0→HP0、DATA1→HP1、INSTR→SmartConnect→HP2（32→64b）| ✅ |
| 时钟域：dpu_2x_clk=300MHz(clk_out3)、AXI=150MHz(clk_out2)、控制=50MHz；各域独立复位 | ✅ |
| 位流：synth→opt→place→**route 成功**→write_bitstream 成功（4.05MB） | ✅ |
| 设备树：dpu 节点 + xlnk + cma=256M | ✅ |
| tinyyolo 应用：yocto 配方编译（内嵌模型）| ✅ |
| DNNDK 运行时库打入 rootfs | ✅ |
| dpu.ko打入 rootfs（内核版本精确匹配）| ✅ |
| rootfs 挂载逐项验证 | ✅ |
| BOOT.BIN 打包（v18 位流）| ✅ |

## 七、已知事项

- `cam_cfg_done` 端口无物理引脚（write_bitstream 时 DRC NSTD/UCIO 已按标准做法降级为警告），不影响功能
- PetaLinux 构建中的 qemu-xilinx-native 编译失败为已知无关项（4578/4578 关键任务全部成功）
- 若上电串口无输出：确认 SD 档、串口为 UART0、115200；确认 BOOT.BIN 为本包 v18 版本
- DNNDK 工具链版本 v3.1，模型 `dpu_tiny_yolo.elf` 由 dnnv3.1 编译器生成（B1152 指令集）

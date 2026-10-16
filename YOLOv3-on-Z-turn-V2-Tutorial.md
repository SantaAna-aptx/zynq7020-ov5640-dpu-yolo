# 在米联客 Z-turn Board V2 (MYS-7Z020-V2) 上部署 YOLOv3 完整教程

> **目标平台**：MYIR Z-turn Board V2（MYS-7Z020-V2，XC7Z020-2CLG400）
> **配套工具链**：**Vivado 2019.1 + SDK 2019.1 + PetaLinux 2019.1 + DNNDK v3.1 + DPU v3.1**
> **开发主机**：Windows 11 + VMware Ubuntu 16.04.7（VM 分配 8 GB RAM / 4-6 核）
> **最终目标**：在 Z-turn Board V2 的 PL 端合成 DPU，量化编译 YOLOv3，并在 PS 端实时推理

> **📝 v2 修订说明（2026-09-06）**：本版已对照原作者 GitBook/GitHub 原文逐章核对并修正错误，修正处均带 ⚠️ 标记：
> ① 设备树改为 DNNDK v3.1 正确写法（`xlnk` + `xilinx,dpu`/`xilinx,dpucore`），删除错误的 `dpuczdx8g`+reserved-memory 写法（见 3.3）
> ② 新增 DPU 内核驱动模块（recipes-modules）步骤——旧版完全缺失，不做板上就没有 `/dev/dpu`（见 3.2.6）
> ③ 新增 bootargs `cma=256M` 配置——旧版缺失，缺了 `dnndk_init` 必失败（见 3.2.4）
> ④ 量化/编译命令改为 DNNDK v3.1 真实语法：`decent_q inspect` + `--input_fn`/`--calib_iter`、`dlet` 从 .hwh 生成 .dcf、`dnnc --parser=tensorflow`（见 4.5/4.6）
> ⑤ 板端运行时改用官方 `zynq7020_dnndk_v3.1` 包，废弃自建 yocto recipe（见 3.4/6.1.2）
> ⑥ PS 端 C++ 程序修正为 N2Cube v3.1 真实 API：int8 量化/反量化、输出顺序按大小自动判断（见 5.2）
> ⑦ 修正 Zynq-7000 术语错误：`M_AXI_GP0` 必须使能；`S_AXI_LPD`/`FPD` 是 MPSoC 叫法（见 2.4.3/2.5）

> **🔧 v3 修订说明（2026-09-14，MZQ7X 实战验证交付版）**：以下要点来自本项目从零到 SD 卡交付的全流程实测，适用于 MZQ7X/Z-turn（XC7Z020-CLG400）同构平台：
> ⑧ **DPU INSTR 端口是 32-bit**（DATA0/DATA1 为 64-bit）：INSTR 直连 64-bit HP 口会位宽不匹配，须经过 SmartConnect（NUM_SI=1, NUM_MI=1）做 32→64 宽度转换后再接 HP2；DATA0→HP0、DATA1→HP1 可直连。
> ⑨ **dpu_2x_clk 必须接 300MHz 且与 m_axi_dpu_aclk(150MHz) 同源**（同一 MMCM 输出），误接 50MHz FCLK 会导致 DPU 跑错时钟域；并为 300MHz 域单独配 proc_sys_reset 复位。
> ⑩ **cam_cfg_done 类冗余顶层端口**（硬件无对应引脚）会在 write_bitstream 触发 DRC NSTD-1/UCIO-1 硬错误：为端口补 IOSTANDARD 约束 + 用 `STEPS.WRITE_BITSTREAM.TCL.PRE` hook 将两条 DRC 降级为 Warning。
> ⑪ **DNNDK 闭源 .so 打进 PetaLinux rootfs（yocto/RPM 后端）三件套**：`FILES_${PN}-dev = "${includedir}"`（防 dev-elf QA）、`INSANE_SKIP_${PN} += "dev-so ldflags arch file-rdeps"`、`SKIP_FILEDEPS_${PN} = "1"`（防 dnf 报 nothing provides libxxx.so）——`PRIVATE_LIBS` 对 RPM 后端无效；且 libdputils.so 必须以实体文件安装（不能 ln -s）。
> ⑫ 交叉编译推理程序不要直接调 `arm-xilinx-linux-gnueabi-g++`（缺 ARM C++ 头文件），应建 `petalinux-create -t apps` 应用配方，`DEPENDS += "opencv"` 后由 yocto 以完整目标 sysroot 编译，模型 .elf 直接作为链接输入内嵌。
> ⑬ 全流程实测产物见 `E:\yoloProject\board_deploy\sd_delivery\`（BOOT.BIN + image.ub + rootfs.ext4 + dpu.ko + dexplorer），交付说明见同目录 `SD_DELIVERY.md`。

---

## 🔗 参考开源项目

本教程基于以下两个由 **andre1araujo** 维护的开源项目改造（针对 Z-turn Board V2 做了适配）：

### 1. GitHub 代码仓库

**URL**：[https://github.com/andre1araujo/YOLO-on-PYNQ-Z2](https://github.com/andre1araujo/YOLO-on-PYNQ-Z2)

**说明**：
- 这是本教程的**核心代码来源**，包含 DPU IP 配置、YOLOv3 量化编译脚本、PS 端 C++/Python 推理程序、PetaLinux 工程参考
- 原项目针对 PYNQ-Z2，**90% 代码可直接复用**，仅需修改 BSP、设备树、PS 配置参数
- **本教程与原项目使用完全一致的工具链版本**（Vivado 2019.1 + DNNDK v3.1），所以代码兼容性最好
- 克隆命令：
  ```bash
  git clone https://github.com/andre1araujo/YOLO-on-PYNQ-Z2
  ```
- **重要提醒**：原作者项目自 2020 年后基本停止更新（依赖的工具链 DNNDK v3.1 已被 Xilinx 官方淘汰），但代码本身完整可用

### 2. 分步教程（GitBook）

**URL**：[https://andre-araujo.gitbook.io/yolo-on-pynq-z2/](https://andre-araujo.gitbook.io/yolo-on-pynq-z2/)

**说明**：
- 这是配套的**图文教程**，比 GitHub README 更详细，分 8 章讲解每一步操作
- **强烈建议**先通读一遍这个 GitBook，对整个流程有大致概念后再来看本教程
- 内容包括：
  - 第 1-3 章：DPU 硬件设计、Linux 镜像构建、SD 卡烧写
  - 第 4 章：DNNDK 模型量化编译（DECENT_Q + DNNC）
  - 第 5-7 章：PS 端 C++ 应用、实时视频流处理、性能优化
  - 第 8 章：常见问题与进阶调试
- **注意**：GitBook 教程里的截图是 Vivado 2019.1 的界面，与你实际用的工具版本一致 ✅

### 两者的关系

```
┌─────────────────────────────────────────────────────────┐
│  GitBook 教程（"是什么/为什么"）                        │
│  https://andre-araujo.gitbook.io/yolo-on-pynq-z2/       │
│                                                         │
│  ↓  概念理解后，看代码                                    │
│                                                         │
│  GitHub 仓库（"怎么做"）                                  │
│  https://github.com/andre1araujo/YOLO-on-PYNQ-Z2        │
│                                                         │
│  ↓  实际移植到 Z-turn V2 时                              │
│                                                         │
│  本教程（本文件，针对 Z-turn V2 的差异点）                │
│  YOLOv3-on-Z-turn-V2-Tutorial.md                        │
└─────────────────────────────────────────────────────────┘
```

### 给原作者 star ⭐（如果这个项目帮到了你）

这是原作者的开源贡献，如果本教程或原项目对你有帮助：
- 给 GitHub 仓库点 star：[⭐ Star on GitHub](https://github.com/andre1araujo/YOLO-on-PYNQ-Z2)
- 在 GitBook 教程下留言感谢
- 这些都是开源社区最直接的鼓励

---

## 目录

- [第 0 章：为什么这个教程存在 —— PYNQ-Z2 与 Z-turn V2 的差异](#第-0-章为什么这个教程存在--pynq-z2-与-z-turn-v2-的差异)
- [第 1 章：环境准备与工具链安装](#第-1-章环境准备与工具链安装)
- [第 2 章：Vivado 2019.1 硬件设计 —— 在 Z-turn V2 上合成 DPU v3.1](#第-2-章vivado-20191-硬件设计--在-z-turn-v2-上合成-dpu-v31)
- [第 3 章：PetaLinux 2019.1 构建 Linux 镜像](#第-3-章petalinux-20191-构建-linux-镜像)
- [第 4 章：DNNDK v3.1 量化编译 YOLOv3](#第-4-章dnndk-v31-量化编译-yolov3)
- [第 5 章：PS 端部署程序（C++，N2Cube API）](#第-5-章ps-端部署程序c-n2cube-api)
- [第 6 章：SD 卡烧写与上电启动](#第-6-章sd-卡烧写与上电启动)
- [第 7 章：功能验证与常见问题排查](#第-7-章功能验证与常见问题排查)
- [附录 A：资源占用估算](#附录-a资源占用估算)
- [附录 B：关键命令速查](#附录-b关键命令速查)

---

## 第 0 章：为什么这个教程存在 —— PYNQ-Z2 与 Z-turn V2 的差异

### 0.1 原项目和目标板的对比

| 项目 | andre1araujo 原项目 (PYNQ-Z2) | 你的目标板 (Z-turn V2) | 是否需要修改 |
|---|---|---|---|
| SoC | XC7Z020-1CLG400C | XC7Z020-2CLG400 | ✅ 速度等级不同 |
| 速度等级 | -1 | -2（更快）| ✅ 选器件时要改 |
| DDR3 | 512MB / 16-bit / 1050 Mbps | **1GB / 32-bit / 1066 Mbps** | ✅ Vivado PS 配置要改 |
| 工具链 | Vivado 2019.1 + DNNDK v3.1 + DPU v3.1 | **Vivado 2019.1 + DNNDK v3.1 + DPU v3.1** | ✅ **完全一致！** |
| 板级支持包 | Digilent PYNQ-Z2 BSP | MYIR 官方 BSP / 自建 | ✅ 需自己建 |
| 外设 | HDMI IN/OUT、Pmod、Arduino、RPi header | HDMI OUT、USB-UART、OTG、1G Ethernet、TF、CAN、G-sensor | ✅ 不影响 DPU |

### 0.2 关键结论（基于这个工具链版本）

**为什么 DPU bitstream 可以跨板复用？**
- DPU 是**芯片级 IP**，不是板级 IP。一段给 XC7Z020 合成的 bitstream 可以烧到任何用 XC7Z020 的板子上。
- DPU v3.1 IP 只用 PL 端的 DSP/BRAM/LUT，不绑定任何板级外设引脚。
- 你和 PYNQ-Z2 的 SoC 唯一区别是 -1 vs -2（速度等级 -2 反而更快），资源完全一样（85K logic cells、220 DSP、4.9Mb BRAM）。

**为什么我们选用这套工具链？**
- 这正好是**原作者 andre1araujo 项目**用的工具链版本组合（Vivado 2019.1 + DNNDK v3.1）。
- 这套组合在你的 Ubuntu 16.04 上**官方支持**，无需升级系统。
- 网上关于这套工具链的中文教程、CSDN 博客、CSDN 资源最多，踩过的坑都有解决方案。

**为什么不能直接烧原作者的 SD 卡镜像？**
- 原作者提供的预编译镜像 `pynqz2_dpu_ml16.rar` 是为 PYNQ-Z2 BSP 编译的（DDR 时钟、UART 配置、设备树全不一样），在你的 Z-turn V2 上根本启动不起来。
- **必须**用 Z-turn V2 的 BSP（或自建 zynq 模板）重新构建 PetaLinux 工程。
- 这是整个教程里**最关键的一步**。

**原作者代码能复用多少？**
- **90% 直接用**：
  - DPU IP 配置参数（Arch=B1152，Clock=100/150/300 MHz）
  - YOLOv3-tiny 量化编译步骤
  - 后处理代码（YOLO decode + NMS，画框）
  - README 里 90% 的命令行操作
- **需要修改的 10%**：
  - Vivado 工程里 Board 文件替换
  - PetaLinux 工程完全重新建（不能用作者的预编译镜像）
  - SD 卡启动 XDC 约束（如果用 PL 引脚）

### 0.3 我们要做的事情

```
┌────────────────────────────────────────────────────────────────────┐
│  Step 1: Vivado 2019.1（VMware Ubuntu 或 Windows 上跑）            │
│    Block Design: Zynq + DPU v3.1 (Arch=B1152) + Clock/Reset       │
│    ↓                                                                │
│  生成 bitstream + 导出 .hdf                                        │
└────────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────────┐
│  Step 2: PetaLinux 2019.1（必须在 VMware Ubuntu 上跑）             │
│    petalinux-create --template zynq + import .hdf                  │
│    配置 kernel、设备树、DPU 节点                                   │
│    ↓                                                                │
│  生成 BOOT.BIN、image.ub、rootfs.tar.gz                            │
└────────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────────┐
│  Step 3: DNNDK v3.1（VMware Ubuntu 上跑）                          │
│    DECENT_Q 量化  → yolov3_quantized.pb                             │
│    DNNC 编译     → yolov3.elf                                      │
└────────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────────┐
│  Step 4: PS 端 C++ 程序（VMware Ubuntu 交叉编译）                  │
│    用 N2Cube API 加载 elf                                          │
│    OpenCV 做预处理 + 后处理 NMS                                     │
│    ↓                                                                │
│  编译产物 yolov3_app 拷贝到板子                                    │
└────────────────────────────────────────────────────────────────────┘
```

---

## 第 1 章：环境准备与工具链安装

### 1.1 硬件清单

| 物料 | 数量 | 备注 |
|---|---|---|
| Z-turn Board V2 (MYS-7Z020-V2) | 1 | 已购 |
| 5V / 2A 电源适配器 | 1 | 板子自带 |
| Micro-USB 线 | 1 | 接 USB-UART 调试 |
| 以太网线 (RJ45) | 1 | SSH + 推理数据回传 |
| HDMI 线 + 显示器 | 1 | 可选，用于显示图像 |
| TF 卡 (≥16GB, Class 10) | 1 | 推荐 32GB |
| USB-UART 串口线 | 1 | 如果 Micro-USB 不识别则需要 |
| **VMware Ubuntu 16.04.7 VM** | 1 | **分配 8 GB RAM / 4-6 核** |
| 宿主机 | Windows 11 (16 GB RAM) | 也可在 Windows 上跑 Vivado 2019.1（图形界面版），VM 里跑 PetaLinux |

### 1.2 软件安装总览

| 工具 | 版本 | 用途 | 装在哪 |
|---|---|---|---|
| Vivado | **2019.1** | 综合 DPU bitstream | VMware Ubuntu 或 Windows（GUI）|
| SDK | **2019.1** | 交叉编译 PS 端代码 | 随 Vivado 一起装 |
| PetaLinux | **2019.1** | 构建 Linux 镜像 | **必须在 VMware Ubuntu 16.04** |
| DNNDK | **v3.1** | 量化 + 编译 + 运行时 | **必须在 VMware Ubuntu 16.04** |
| DPU IP | **v3.1** | PL 端的 DPU 加速器 | Vivado IP 库 |

### 1.3 VMware 虚拟机调整（必须先做）

> ⚠️ **你的 VM 当前是 3.8 GB RAM，PetaLinux build 必定 OOM 崩溃，必须先调整。**

#### 1.3.1 关闭 Ubuntu 电源（不是挂起）

```
VMware Workstation → 右键虚拟机 → Power Off
```

#### 1.3.2 调整内存和 CPU

```
VMware → 编辑虚拟机设置（Edit virtual machine settings）
→ 内存（Memory）：改为 **8192 MB**（8 GB）
→ 处理器（Processors）：**处理器数量 4**（你 i7-13620H 10 核，给 VM 4-6 核够用）
```

#### 1.3.3 启动 Ubuntu，验证内存

```bash
free -h
```

应该看到 `total` 接近 8 GB。如果还是 3.8 GB，说明 VMware 配置没生效，关机重试。

### 1.4 Ubuntu 16.04 系统准备

#### 1.4.1 更换 apt 源（Ubuntu 16.04 已 EOL）

```bash
# 备份原 sources.list
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak

# 替换为 old-releases 源
sudo sed -i 's/archive.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list
sudo sed -i 's/security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list

sudo apt update
```

#### 1.4.2 修改 /bin/sh 为 bash

```bash
# Ubuntu 默认 sh 指向 dash，PetaLinux 安装脚本会失败
sudo dpkg-reconfigure dash
# 弹出界面选择 <No>

# 验证
ls -l /bin/sh
# 应该显示 /bin/sh -> bash
```

#### 1.4.3 安装 PetaLinux 2019.1 依赖包

```bash
sudo apt-get install -y \
    gawk build-essential gcc-multilib g++-multilib \
    git-core diffstat unzip texinfo chrpath socat \
    cpio python python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping libsdl1.2-dev \
    xterm pax screen zlib1g-dev libtool autoconf \
    libselinux1 bison flex libssl-dev libncurses5-dev \
    net-tools wget

# 32 位支持库
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y zlib1g:i386 libstdc++6:i386
```

### 1.5 安装 Vivado 2019.1

#### 1.5.1 下载 Vivado 2019.1 安装包

Xilinx 官方下载（需要 AMD/Xilinx 账号，免费注册）：

```
https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html

→ Vivado 2019.1 版本
→ 选择 "Vivado HLx 2019.1: All OS installer - Single-File Download"
```

文件名：`Xilinx_Vivado_SDK_2019.1_0524_1430_Lin64.bin`（约 17 GB）

#### 1.5.2 安装

```bash
cd ~/Downloads

# 装到 /opt/Xilinx（标准路径）
chmod +x Xilinx_Vivado_SDK_2019.1_0524_1430_Lin64.bin
sudo ./Xilinx_Vivado_SDK_2019.1_0524_1430_Lin64.bin
```

弹出图形安装界面：

1. **Select Install Type**：`Vivado HL Webpack`（免费版，支持 Zynq-7000）
2. **Select Edition to Install**：Webpack
3. **Devices**：
   - 勾选 ✅ **SoCs and 7-series FPGAs**（必须，XC7Z020 在这里）
   - ❌ 不勾选 UltraScale（你用不到，省空间）
4. **Install Location**：`/opt/Xilinx/Vivado/2019.1`
5. 接受 3 个 license（选 Accept）

> ⚠️ 注意：如果你想 Windows 上跑 Vivado GUI（更流畅），也在 Windows 上装一遍。

### 1.6 安装 PetaLinux 2019.1

#### 1.6.1 下载 PetaLinux 2019.1

```
https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools/archive.html

→ PetaLinux 2019.1
→ "PetaLinux 2019.1 Installer"
```

文件名：`petalinux-v2019.1-final-installer.run`（约 7 GB）

#### 1.6.2 安装

```bash
# Ubuntu 用户必须是普通用户，不能用 root
# petalinux 装到普通用户可写路径
mkdir -p /opt/pkg/petalinux
chmod 755 /opt/pkg

chmod +x petalinux-v2019.1-final-installer.run
./petalinux-v2019.1-final-installer.run /opt/pkg/petalinux
```

按提示接受 3 个 license（输入 `y`）。安装完后：

```bash
source /opt/pkg/petalinux/2019.1/settings.sh

# 加入 .bashrc
echo "source /opt/pkg/petalinux/2019.1/settings.sh" >> ~/.bashrc
source ~/.bashrc

# 验证
petalinux-version
# 应该输出：2019.1
```

### 1.7 安装 DNNDK v3.1

#### 1.7.1 下载 DNNDK v3.1

```
https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/ai-inference/ai-tools-archive.html

→ DNNDK v3.1
→ DNNDK v3.1 - x86_64.tar.gz
```

文件名：`DNNDK_v3.1_x86_64.tar.gz`（约 800 MB）

#### 1.7.2 解压与安装

```bash
# 解压
tar -xzvf DNNDK_v3.1_x86_64.tar.gz
cd DNNDK_v3.1

ls -lh
# 应该看到（具体文件名随版本略有差异，认准这几样东西）：
# decent_q-3.1-cp36-cp36m-linux_x86_64.whl    # 量化 Python 工具（wheel）
# dnnc、dlet                                   # 主机端编译器 + .dcf 生成工具（4.6 用 dlet）
# zynq7020_dnndk_v3.1.tar.gz                   # ★ 板端运行时（xdputil + libn2cube/libdnn），第 6 章烧卡用
# n2cube 开发包（头文件 + 库）                  # 交叉编译 PS 端程序用（5.3 用）

# 安装 DECENT_Q（量化工具）
sudo pip3 install decent_q-3.1-cp36-cp36m-linux_x86_64.whl

# 解压主机端工具和板端运行时（后续章节用）
tar -xzvf dnnc-3.1-Linux.tar.gz -C ~/dnnc_tool/
tar -xzvf n2cube-3.1.tar.gz -C ~/n2cube_tool/
tar -xzvf zynq7020_dnndk_v3.1.tar.gz -C ~/dnndk_board/   # ★ 板端运行时，第 6 章拷到 SD 卡，别删
```

#### 1.7.3 配置 DNNDK 环境变量

```bash
# 加入 .bashrc
cat >> ~/.bashrc << 'EOF'

# DNNDK v3.1
export DECENTQ_PATH=/usr/local/bin/decent_q
export DNNC=/home/santaqiro/dnnc_tool/dnnc
export DLET=/home/santaqiro/dnnc_tool/dlet
export N2CUBE_PATH=/home/santaqiro/n2cube_tool/n2cube
EOF

source ~/.bashrc

# 验证
decent_q --help 2>&1 | head -5
$DNNC --version 2>&1 | head -3
```

### 1.8 安装 DPU v3.1 IP

#### 1.8.1 下载 DPU IP v3.1

DPU IP v3.1 在 DNNDK 安装包里其实已经有了。或者从 Xilinx 官方下载：

```
https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/ai-inference/ai-tools-archive.html

→ DNNDK v3.1
→ DPU IP (v3.1) tarball
```

文件名：`DPU_IP_v3.1.tar.gz`（约 1 MB）

#### 1.8.2 解压 DPU IP

```bash
tar -xzvf DPU_IP_v3.1.tar.gz
# 解压到 DPU_TRD/dpu_ip/ 目录下
ls DPU_TRD/dpu_ip/
# 应该看到 DPU 相关的 .zip 和 .tcl
```

这个目录后面在 Vivado 里会作为 IP 仓库添加。

> 📌 **DPU TRD 已就绪（本地）**：本教程配套的 DPU IP 与 DPU 内核驱动已从社区镜像
> `github.com/sumilao/Zynq-7000-DPU-TRD` 下载到 `E:\yoloProject\dpu_trd\reference-files\`：
> - `ip_repo/dpu/` → DPU IP 仓库，VLNV 为 **`xilinx.com:ip:dpu_eu:2.0`**（Zynq-7000 版 DPU，
>   与 DNNDK 3.1 / dnnc-dpu1.4.0 配套；Vivado 里以 `dpu_eu` 搜索添加，不是 DPU v3.1 的 dpuczdx8g）
> - `files/recipes-modules/dpu/` → 3.2.6 要用的 DPU 内核驱动配方
> - `files/dpu.dtsi` → 3.3 设备树的官方参考写法
> - `prebuilts/pynq-z2-dpu.bsp` → 参考 BSP（PYNQ-Z2 的，只作对照，不能直接用于 Z-turn V2）

### 1.9 验证工具链

| 检查项 | 命令 | 期望输出 |
|---|---|---|
| Vivado | `vivado -version` | Vivado v2019.1 |
| PetaLinux | `petalinux-version` | 2019.1 |
| DECENT_Q | `decent_q --help` | 显示帮助 |
| DNNC | `~/dnnc_tool/dnnc --version` | 显示版本 |
| DLET | `~/dnnc_tool/dlet` | 显示用法 |
| /bin/sh | `ls -l /bin/sh` | → bash |
| 内存 | `free -h` | total ≥ 7 GB |
| Python 3 | `python3 --version` | 3.5.x（Ubuntu 16.04 默认）|

---

## 第 2 章：Vivado 2019.1 硬件设计 —— 在 Z-turn V2 上合成 DPU v3.1

### 2.1 整体目标

在 Vivado 2019.1 中创建一个 Block Design：

```
┌──────────────────────────────────────────────────────────┐
│  Zynq-7000 Processing System (PS)                         │
│    - Cortex-A9 双核                                       │
│    - DDR3 Controller (32-bit, 接 Z-turn 的 1GB DDR3)     │
│    - UART1 (MIO 48-49) → USB-UART                        │
│    - SD0 (MIO 40-45) → TF 卡                             │
│    - ENET0 (MIO 16-27) → 1G PHY                          │
└──────────────────────────────────────────────────────────┘
              │ M_AXI_GP0
              ▼
┌──────────────────────────────────────────────────────────┐
│  AXI Interconnect                                         │
└──────────────────────────────────────────────────────────┘
              │ s_axi_control
              ▼
┌──────────────────────────────────────────────────────────┐
│  DPU v3.1                                                │
│    - Number of DPU Cores: 1                              │
│    - Architecture: B1152                                  │
│    - S_AXI Clock: 100 MHz                                │
│    - M_AXI DPU Clock: 150 MHz                            │
│    - DPU 2x Clock: 300 MHz                               │
│    - DSP48 Width: 27-bit                                 │
│    - RAM Usage: Low                                       │
└──────────────────────────────────────────────────────────┘
```

### 2.2 创建 Vivado 工程

#### 2.2.1 启动 Vivado

```bash
source /opt/Xilinx/Vivado/2019.1/settings64.sh
vivado &
```

#### 2.2.2 新建工程

```
File → Project → New → Next

Project name: zturn_v2_dpu
Project location: ~/vivado_projects
勾选 "Do not specify sources at this time" → Next

Project Type: RTL Project → Next
```

#### 2.2.3 选择目标器件

**关键步骤** —— 选择 Z-turn V2 对应的器件：

| 选项 | 设置 |
|---|---|
| 搜索框 | 输入 `xc7z020` |
| 选中 | `xc7z020clg400-2`（注意是 -2 不是 -1）|
| 速度等级 | -2 |

> ⚠️ Z-turn V2 用的是 -2 速度等级（更快的等级），不是 -1。如果错选 -1，bitstream 会验证失败。

点 Next → Finish。

### 2.3 添加 DPU IP 仓库

#### 2.3.1 解压 DPU IP

```bash
# 假设你已经下载并解压 DPU IP v3.1
ls ~/Downloads/DPU_TRD/dpu_ip/
# 应该有 dpu.xop 文件或者 zip 压缩包
```

#### 2.3.2 在 Vivado 中添加 IP 仓库

```
菜单栏 → Tools → Settings → IP → Repository

点击 "+" → 选择 ~/Downloads/DPU_TRD/dpu_ip/
点击 OK

Vivado 会扫描并显示 "1 Repository and 1 IP found"
```

### 2.4 创建 Block Design

#### 2.4.1 新建 Block Design

```
Flow Navigator → IP INTEGRATOR → Create Block Design

Design name: system
确认 → OK
```

#### 2.4.2 添加 Zynq PS IP

```
Diagram 画布空白处右键 → Add IP
搜索：zynq
选择：ZYNQ7 Processing System → 双击添加
```

#### 2.4.3 配置 Zynq PS（关键步骤）

双击 ZYNQ7 IP，进入配置界面：

**（1）DDR Configuration 页**：

| 参数 | 设置 |
|---|---|
| Memory Part | MT41K256M16HA-125（Z-turn V2 兼容型号）|
| Effective DRAM Width | 32-bit |
| DRAM Operating Speed | 1066 Mbps（Z-turn V2 支持的最高速率）|
| DRAM Size | 1GB（会自动填入）|

> 💡 如果列表里没有 MT41K256M16HA-125，选 MT41J128M16 或其他 Micron DDR3 型号也行，参数手动填入：容量 256M16、Row=15、Bank=3、Column=10。

**（2）Clock Configuration 页**：

| 参数 | 设置 |
|---|---|
| Input Frequency | 33.333 MHz（Z-turn V2 PS 参考时钟）|
| CPU Frequency | 667 MHz（Z-turn V2 默认值，安全范围）|
| DDR Frequency | 533 MHz |

> 💡 Z-turn V2 的 CPU 最高支持 866 MHz，但 667 MHz 是官方推荐值（更稳定）。

**（3）Peripheral I/O Pins 页**（按需勾选）：

| 外设 | MIO | 用途 |
|---|---|---|
| ✅ UART1 | MIO 48-49 | 串口调试（Z-turn V2 USB-UART）|
| ✅ SD 0 | MIO 40-45 | TF 卡启动 |
| ✅ ENET 0 | MIO 16-27 | 千兆以太网 |
| ✅ USB 0 | MIO 28-39 | USB OTG（可选）|

**（4）PS-PL Configuration 页**：

> ⚠️ 旧版此处的 "S AXI HP0 **FPD**" 是 Zynq UltraScale+（MPSoC）的叫法，Zynq-7000 菜单里就叫 S AXI HP0。

| 参数 | 设置 |
|---|---|
| S AXI HP0 | ✅ Enable（DPU 数据读/写通道）|
| S AXI HP1 | ✅ Enable（可选，带宽冗余）|
| S AXI HP2 / HP3 | ❌ 不需要 |
| S AXI GP0 | ❌ 不需要 |
| **M AXI GP0** | ✅ **Enable（PS 通过它访问 DPU 控制寄存器，必须开！）** |
| S AXI ACP | ❌ 不需要 |

> ⚠️ **修正**：旧版把 M AXI GP0 写成 Disable，这是错的——DPU 的 `s_axi_control`（AXI-Lite 从端口）
> 要挂到 M_AXI_GP0 上，关掉它 PS 就无法访问 DPU 寄存器，`xdputil`/推理全都会失败。

**（5）MIO Configuration 页**：
- Bank 0/1/2 电压：LVCMOS 3.3V（Z-turn V2 的 MIO 电压）

点击 OK。

#### 2.4.4 添加 DPU IP

```
Diagram 画布 → Add IP
搜索：DPU
选择：DPU v3.1
双击添加
```

#### 2.4.5 配置 DPU IP（关键参数）

双击 DPU IP：

| 参数 | 推荐值 | 说明 |
|---|---|---|
| **DPU Architecture** | **B1152** | **重要！Zynq-7020 最高就 B1152，更高会装不下**|
| DPU Cores | 1 | XC7Z020 资源只够 1 个 DPU core |
| DSP48 Width | 27-bit | 最高性能 |
| RAM Usage | Low | 用 BRAM 而非 URAM，XC7Z020 没有 URAM |
| Softmax | Disable | CPU 实现 softmax（更省资源）|
| DepthwiseConv | Enable | 启用深度可分离卷积（YOLOv3 tiny 需要）|

**Clock Configuration**：

| 参数 | 设置 |
|---|---|
| DPU S AXI Clock | 100 MHz |
| DPU M AXI Clock | **150 MHz** |
| DPU 2x Clock | **300 MHz** |

> ⚠️ DPU clock 不要贪高，B1152 在 -2 速度等级下 150/300 MHz 是稳的。强行跑 200/400 可能时序违例。

**Summary 页**：检查资源占用：

| 资源 | B1152 占用估计 | Zynq-7020 可用 |
|---|---|---|
| LUT | ~25,000 | 53,200 |
| DSP | ~190 | 220 |
| BRAM | ~100 (36Kb) | 140 |

应该都能装下。如果超了，降到 B1024。

点击 OK。

#### 2.4.6 添加 Clocking Wizard

DPU 需要 3 个时钟：s_axi_aclk、dpu_2x_clk、m_axi_aclk。Clocking Wizard 要产生这 3 个时钟。

```
Add IP → 搜索：Clocking Wizard
选择：Clocking Wizard v6.0
```

配置：

| 输出 | 频率 | 用途 |
|---|---|---|
| clk_out1 | 100 MHz | DPU S_AXI 时钟 |
| clk_out2 | 300 MHz | DPU 2x 时钟 |
| clk_out3 | 150 MHz | DPU M_AXI 时钟 |

输入时钟接 Zynq PS 输出的 `FCLK_CLK0`（默认 100 MHz）。

#### 2.4.7 添加 Processor System Reset（3 个）

DPU 三个时钟域各需要一个复位 IP。

```
Add IP → Processor System Reset
放置 3 个，分别对应：
- ext_reset_in → 接 Zynq 的 FCLK_RESET0_N
- slowest_sync_clk → 接对应的 DPU 时钟
- dcm_locked → 接 Clocking Wizard 的 locked 输出
```

### 2.5 端口互连（关键）

#### 2.5.1 自动连线

```
Diagram 画布 → 顶部菜单 → Run Connection Automation
- 勾选 "All Automation"
- 点击 OK
```

Vivado 会自动帮你连接：
- Zynq 的 `M_AXI_GP0` → AXI Interconnect → DPU 的 `s_axi_control`（AXI-Lite 控制寄存器端口）
- Zynq 的 `S_AXI_HP0` ← DPU 的 `M_AXI`（DPU 数据读/写）

> 💡 修正：旧版写的 `S_AXI_LPD` 是 Zynq UltraScale+ 的端口叫法，Zynq-7000 上 DPUCZDX8G 的
> 控制口叫 `s_axi_control`、数据口叫 `M_AXI`（以你例化 IP 实际显示的端口名为准）。

#### 2.5.2 手动修正 DPU 时钟连接

DPU IP 有 3 个时钟端口：

```
DPU.s_axi_aclk   → clk_wizard/clk_out1 (100 MHz)
DPU.dpu_2x_clk   → clk_wizard/clk_out2 (300 MHz)
DPU.m_axi_aclk   → clk_wizard/clk_out3 (150 MHz)
```

对应 3 个 Processor System Reset 的 `slowest_sync_clk` 也连相同时钟。

#### 2.5.3 中断连接

```
DPU.interrupt → Zynq IRQ_F2P[0:0]
```

#### 2.5.4 验证设计

```
Tools → Validate Design (F6)
应该看到 "Validation successful"
```

### 2.6 添加 XDC 约束（基础版）

如果你不用 PL 引脚外设（DPU 是 PL 内部逻辑），XDC 可以为空。但建议加一个伪约束让 Vivado 安静：

```tcl
# zturn_v2_dpu.xdc
# 基本约束：DPU 是内部逻辑，不需要外部引脚
# 如果你用 PL 引脚外设（如 LED、按键），按需添加

# 例如：
# set_property -dict {PACKAGE_PIN E14 IOSTANDARD LVCMOS33} [get_ports led]
# set_output_delay 0 [get_ports led]
```

### 2.7 生成 Output Products

```
Sources 窗口 → 右键 design_1.bd → Generate Output Products
弹出窗口：
- Synthesis Options: Global
- Run Implementation: 暂时不选
点击 Generate
```

等待综合完成。

### 2.8 生成 Bitstream

```
Flow Navigator → PROGRAM AND DEBUG → Generate Bitstream

弹出窗口直接 OK
等待综合 + 实现 + bitstream 生成（约 20-40 分钟）
```

### 2.9 创建 HDL Wrapper

```
Sources 窗口 → 右键 design_1.bd → Create HDL Wrapper
选择 "Let Vivado manage wrapper and auto-update" → OK
```

### 2.10 导出硬件平台（.hdf）

> ⚠️ **重要**：Vivado 2019.1 导出的是 **.hdf** 文件，**不是** 2023.2 的 .xsa。PetaLinux 2019.1 用 .hdf。

```
File → Export → Export Hardware...

- Type: Pre-synthesis
  （勾不勾 Include bitstream 都可以，PetaLinux 会自己用 system.bit）
- Export to: ~/vivado_projects/zturn_v2_dpu/
- File name: system.hdf  ← 注意是 .hdf 不是 .xsa
- 点击 OK
```

**生成的关键文件**：

```
~/vivado_projects/zturn_v2_dpu/
├── system.hdf                       ← PetaLinux 用这个（不是 .xsa！）
├── system.bit                       ← FPGA bitstream
├── system_bd.tcl
├── design_1_wrapper.v
└── ...
```

---

## 第 3 章：PetaLinux 2019.1 构建 Linux 镜像

### 3.1 创建 PetaLinux 工程

```bash
source /opt/pkg/petalinux/2019.1/settings.sh

cd ~/petalinux_projects

# 创建工程模板（zynq 7000 系列）
petalinux-create -t project \
    --template zynq \
    --name zturn_v2_dpu_plnx

cd zturn_v2_dpu_plnx
```

### 3.2 导入 Vivado 硬件

```bash
petalinux-config --get-hw-description=~/vivado_projects/zturn_v2_dpu/
```

这会打开图形配置界面（`menuconfig`）。**关键配置项**：

#### 3.2.1 配置 Subsystem AUTO Hardware Settings

```
Subsystem AUTO Hardware Settings  --->
    Advanced Bootable Images Storage Settings  --->
        boot image settings  --->
            (X) image not in bootable partition    # 关闭
```

#### 3.2.2 配置 RootFS 类型

```
Image Packaging Configuration  --->
    Root filesystem type  --->
        (X) SD card    # 选择 SD 卡启动
```

#### 3.2.3 配置 Kernel 和 U-Boot

```
Linux Components Selection  --->
    [*] linux-xlnx    # 启用 Linux 内核

Auto Config Settings  --->
    [*] Enable Auto Config of U-Boot  --->
        (X) Yes
```

#### 3.2.4 配置内核启动参数 bootargs（关键，旧版缺失）

DNNDK 的 xlnk 内存管理从 CMA 里分配连续内存，**bootargs 必须带 `cma=256M`**，
否则后面板子上 `dnndk_init()` 直接失败（报内存分配错误）：

```
DTG Settings  --->
    [ ] Generate bootargs automatically        # 取消自动生成
        kernel bootargs  --->
            console=ttyPS0,115200 root=/dev/mmcblk0p2 rw earlyprintk rootfstype=ext4 rootwait cma=256M
```

> ⚠️ Z-turn V2 有 1GB DDR，给 CMA 预留 256M 是安全值，不够可调到 512M。

#### 3.2.5 退出并保存

```
按 ESC 退出 → Save? Yes → Exit
```

#### 3.2.6 拷入 DPU 内核驱动模块 recipes-modules（关键，旧版完全缺失）

> ⚠️ 板子上的 `/dev/dpu` 设备节点由 `dpu.ko` 内核模块创建。**这个模块不在 PetaLinux 源码里**，
> 要从 Xilinx 官方 **DPU TRD 2019.1** 的 BSP 里提取（`zcu102-dpu-trd-2019-1-190809.zip`，
> 下载页见 1.8）。没有这一步，设备树节点写得再对也不会有 `/dev/dpu`，`xdputil query` 直接报错。

```bash
# 1. 解开 BSP（本质是个压缩包，用 7z 即可）
7z x zcu102-dpu-trd-2019-1-190809.zip -o/tmp/dpu_trd

# 2. 在解包内容里找到 project-spec/meta-user/recipes-modules/
#    （含 dpu 模块的 .bb 配方和驱动源码），整个目录拷进你的工程
cp -rv /tmp/dpu_trd/<bsp包名>/project-spec/meta-user/recipes-modules/ \
       project-spec/meta-user/

# 3. 注册到 rootfs：在 project-spec/meta-user/conf/user-rootfsconfig 末尾追加
echo "CONFIG_dpu" >> project-spec/meta-user/conf/user-rootfsconfig

# 4. 在 project-spec/meta-user/conf/petalinuxbsp.conf 末尾追加
#    ⚠️ 注意引号里 dpu 前面有一个空格，这是 bitbake append 语法的硬性要求
echo 'IMAGE_INSTALL_append = " dpu"' >> project-spec/meta-user/conf/petalinuxbsp.conf
```

> 💡 **备选方案**：DNNDK 板端包（`ZedBoard/pkgs/driver/dpu.ko`）里也带了一个预编译的 dpu.ko
> （对应 xilinx 4.19 内核，与 PetaLinux 2019.1 的内核同版本）。若 recipes-modules 提取困难，
> 可直接把这个 .ko 拷到板上 `insmod`。但源码编译（recipes-modules）能精确匹配你的内核配置，优先推荐。

### 3.3 添加 DPU 设备树节点（DNNDK v3.1 专用写法）

> ⚠️ **写法修正**：DNNDK v3.1 时代的设备树与 Vitis AI（2020.2+）完全不同。本节采用 DNNDK v3.1
> 官方写法（`xlnk` + `xilinx,dpu`/`xilinx,dpucore`），与 3.2.6 拷入的 dpu 内核模块、第 1 章的
> DNNDK v3.1 运行时配套。**不要**照抄网上 2020.2+ 教程里的 `xlnx,dpuczdx8g-1.0` +
> reserved-memory 写法——那是另一套驱动模型，和 DNNDK v3.1 不兼容，照抄必然 `dnndk_init` 失败。

PetaLinux 会根据 .hdf 自动生成 PL 设备树（pl.dtsi），但不含 DNNDK 需要的 xlnk 与 DPU 驱动节点，需手动补：

```bash
# 打开 user device tree
vim project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi
```

完整内容（可直接粘贴；两处标 ★ 的参数按你的 Vivado 设计修改）：

```dts
/include/ "system-conf.dtsi"

/ {
    /* xlnk：DNNDK 的 CMA 内存管理节点，缺了它 dnndk_init 必失败 */
    xlnk {
        compatible = "xlnx,xlnk-1.0";
        #clock-cells = <0>;
        clock-names = "s_axi_aclk";
        clocks = <&misc_clk_0>;
    };

    /* DPU：3.2.6 拷入的 dpu.ko 通过 compatible = "xilinx,dpu" 匹配此节点 */
    dpu@0x4F000000 {
        compatible = "xilinx,dpu";
        base-addr = <0x4F000000>;              /* ★ 与节点地址一致 */
        dpucore {
            compatible = "xilinx,dpucore";
            interrupt-parent = <&intc>;
            interrupts = <0 29 4>;             /* ★ 见下方说明 */
            core-num = <0x1>;                  /* 单核 B1152 */
        };
    };
};
```

**★ 参数怎么确定（必须与你的 Vivado 设计一致）**：

- **基地址（base-addr）**：Vivado → Address Editor，找 DPU 挂在 M_AXI_GP0 下的基地址
  （原作者的设计是 0x4F000000，以你的为准；节点名 `dpu@0x...` 和 `base-addr` 要一起改）
- **中断号**：DPU interrupt 接到 IRQ_F2P 的第 n 位，设备树就写 `<0 (29+n) 4>`
  （IRQ_F2P 第 0 位对应 GIC SPI 61，设备树里 SPI 中断号要减 32 → 29；接第 1 位就是 30）
- `misc_clk_0`：pl.dtsi 里自动生成的时钟节点名。第一次 `petalinux-build` 后到
  `components/plnx_workspace/device-tree/device-tree/pl.dtsi` 里确认实际名字，不同就改

（可选）如果要接 USB 摄像头，还需按原作者 GitBook 增加 ulpi-phy 节点并把 `usb0` 设为 host 模式，
同时在内核配置里打开 USB 选项（见 3.5）。

### 3.4 DNNDK 板端运行时（zynq7020_dnndk_v3.1）与 OpenCV

#### 3.4.1 板端运行时：不进 rootfs，烧卡时直接拷（推荐）

> 💡 **做法修正**：旧版教你自己写 yocto recipe 把 n2cube 编进 rootfs——繁琐且容易踩 bitbake 的坑。
> DNNDK v3.1 官方的板端运行时以 **ZedBoard 子包**形式随包发布（与 Z-turn V2 同为 Zynq-7020 芯片，
> 直接可用），内含：
> - `driver/dpu.ko`：DPU 内核驱动（板端 install.sh 自动 insmod/modprobe，开机自动加载）
> - `bin/` 的 `dexplorer、ddump、dsight`：DPU 状态查询/调试工具
>   （⚠️ DNNDK 3.1 时代叫 `dexplorer`，`xdputil` 是 Vitis AI 之后才有的工具名）
> - `lib/libn2cube.so、libdputils.so.3.x、libhineon.so`：N2Cube 运行库
> - `include/`（n2cube.h、dputils.h、dnndk.h）、python wheel、官方 samples（含 .elf 示例模型）

它的使用方式是**构建完成后拷到 SD 卡 rootfs 的 `/home/root/`**（见 6.1.2），不参与 PetaLinux 构建；
主机端交叉编译时链接 n2cube 开发包里的头文件和库（见 5.3）。

#### 3.4.2 添加 OpenCV

YOLOv3 推理程序需要 OpenCV 做图像处理。PetaLinux 2019.1 内置 OpenCV 配方：

```bash
petalinux-config -c rootfs
```

```
Filesystem Packages  --->
    misc  --->
        [*] opencv
        [*] opencv-dev         # 编译板端程序要用头文件，务必勾上

PetaLinux Package Groups  --->
    [*] packagegroup-petalinux-opencv    # 也可以直接勾这个完整组
```

按 `Y` 选中需要的包。退出保存。

### 3.5 配置 Kernel

> ⚠️ **修正**：2019.1 内核里**没有** "Xilinx DPU driver"（CONFIG_XILINX_DPU）这个选项——
> 别在内核菜单里找。DPU 驱动就是 3.2.6 拷入的 `dpu.ko` 模块（由设备树 `xilinx,dpu` 节点匹配加载），
> `petalinux-build` 时会自动编进 rootfs。

```bash
petalinux-config -c kernel
```

（可选，仅当要接 USB 摄像头时）打开 USB 相关支持：

```
Device Drivers  --->
    USB support  --->
        [*] USB announce new devices
        [*]   USB Video Class (UVC)    # USB 摄像头
    ChipIdea Highspeed Dual Role Controller（Zynq-7000 的 USB0 是 ChipIdea IP）
        [*]   ChipIdea host support
```

退出保存。

### 3.6 构建 PetaLinux

```bash
cd ~/petalinux_projects/zturn_v2_dpu_plnx
petalinux-build
```

第一次构建需要 1-2 小时（8 GB VM 内存足够）。

构建产物在 `images/linux/` 下：

```
images/linux/
├── BOOT.BIN                            ← 启动文件
├── image.ub                             ← 内核 + 设备树
├── rootfs.tar.gz                        ← 根文件系统
├── system.bit                           ← DPU bitstream
├── zynq_fsbl.elf                        ← FSBL
├── u-boot.elf                           ← U-Boot
└── system.hdf                           ← 备份的硬件描述
```

### 3.7 生成最终 BOOT.BIN

```bash
petalinux-package --boot \
    --fsbl images/linux/zynq_fsbl.elf \
    --fpga images/linux/system.bit \
    --u-boot --force
```

---

## 第 4 章：DNNDK v3.1 量化编译 YOLOv3

### 4.1 模型选择

YOLOv3 有 3 个常见变体：

| 模型 | 大小 | 推理速度（在 B1152 上）| 推荐度 |
|---|---|---|---|
| **YOLOv3-tiny** | ~17MB | ~0.45 秒/帧 | ⭐⭐⭐ 原作者就用这个 |
| YOLOv3 | ~248MB | 跑不动，资源不够 | ❌ |
| YOLOv4-tiny | ~25MB | ~0.5 秒/帧 | ⭐⭐ 备选 |

**推荐使用 YOLOv3-tiny**（原作者也是用它）。

### 4.2 获取预训练权重

```bash
mkdir -p ~/yolov3_model && cd ~/yolov3_model

# 下载 YOLOv3-tiny 预训练权重（COCO 80 类）
wget https://pjreddie.com/media/files/yolov3-tiny.weights

# 下载 Darknet 配置
wget https://raw.githubusercontent.com/pjreddie/darknet/master/cfg/yolov3-tiny.cfg

# 下载 COCO 类别名
wget https://raw.githubusercontent.com/pjreddie/darknet/master/data/coco.names
```

### 4.3 Darknet → TensorFlow → Keras

DNNDK v3.1 需要 TensorFlow 1.x 冻结图（`*.pb`）。

#### 4.3.1 安装 TensorFlow 1.15

```bash
# DNNDK v3.1 配 TF 1.15（兼容性最好）
pip3 install tensorflow==1.15

# 安装 Keras（用于 darknet → keras 转换）
pip3 install keras==2.2.4
pip3 install opencv-python-headless
```

#### 4.3.2 转换 Darknet 到 Keras

```bash
cd ~/yolov3_model
git clone https://github.com/qqwweee/keras-yolo3.git
cd keras-yolo3

# 把权重和 cfg 复制过来
cp ../yolov3-tiny.weights .
cp ../yolov3-tiny.cfg .

# 转换（用原作者的 convert.py）
python3 convert.py yolov3-tiny.cfg yolov3-tiny.weights yolov3-tiny.h5

mv yolov3-tiny.h5 ~/yolov3_model/
```

#### 4.3.3 Keras → 冻结图（frozen pb）

```bash
cat > ~/yolov3_model/keras_to_pb.py << 'EOF'
"""Keras .h5 转换为 TensorFlow 冻结图 .pb"""
import tensorflow as tf
from tensorflow.python.framework import graph_io
from tensorflow.keras.models import load_model
from tensorflow.keras import backend as K

INPUT_H5 = '/home/santaqiro/yolov3_model/yolov3-tiny.h5'
OUTPUT_PB = '/home/santaqiro/yolov3_model/yolov3-tiny.pb'

def freeze_session(K_session, output_names):
    """冻结 Keras session 为 frozen graph"""
    graph = K_session.graph
    graph_final = tf.graph_util.remove_training_nodes(graph.as_graph_def())
    graph_final = tf.graph_util.convert_variables_to_constants(
        K_session, graph_final, output_names)
    return graph_final

K.set_learning_phase(0)
K.set_image_data_format('channels_last')

model = load_model(INPUT_H5, compile=False)
print(f"[INFO] 模型输入: {model.input.shape}")
print(f"[INFO] 模型输出数: {len(model.outputs)}")
for i, out in enumerate(model.outputs):
    print(f"  Output {i}: {out.shape}")

# 创建输出节点名称（YOLOv3 tiny 有 2 个输出）
output_names = [out.op.name for out in model.outputs]
print(f"[INFO] 输出节点: {output_names}")

# 冻结并保存
frozen_graph = freeze_session(K.get_session(), output_names)
graph_io.write_graph(frozen_graph, '/home/santaqiro/yolov3_model/',
                     'yolov3-tiny.pb', as_text=False)

print(f"[INFO] 冻结图已保存: {OUTPUT_PB}")
EOF

python3 ~/yolov3_model/keras_to_pb.py
```

输出：`yolov3-tiny.pb`（约 35 MB）。

### 4.4 准备校准数据集

DECENT_Q 量化需要校准图片（不带标签）。

```bash
mkdir -p ~/yolov3_model/calib_images

# 下载 COCO val2017（约 1GB，val2017.zip）
# 或者从 ImageNet 抽 200 张
ls ~/yolov3_model/calib_images/ | wc -l
# 应该看到 200+ 个 .jpg 文件
```

### 4.5 DECENT_Q 量化

#### 4.5.1 先 inspect：拿到真实的输入/输出节点名

不同转换脚本生成的节点名不同，**量化前必须先 inspect**（这也是排错的第一步）：

```bash
decent_q inspect --input_frozen_graph /home/santaqiro/yolov3_model/yolov3-tiny.pb
```

记录输出里的：
- input node（通常叫 `image_input` / `input_1` / `input_image` 之类）
- 两个 output node（keras-yolo3 转出的 tiny 通常是 `conv2d_9/BiasAdd`（13×13）和
  `conv2d_12/BiasAdd`（26×26））

#### 4.5.2 编写校准输入函数 graph_input_fn.py

> ⚠️ **语法修正**：DNNDK v3.1 通过 `--input_fn` 指定一个 Python 函数来喂校准图片，
> **不是** `--calib_images_dir` / `--calib_batch_size`（那是 Vitis AI 1.x+ 的语法，v3.1 不认）。

```bash
cat > ~/yolov3_model/graph_input_fn.py << 'EOF'
"""DECENT_Q 校准输入函数：按迭代序号返回一张预处理好的校准图"""
import os
import cv2

CALIB_DIR = '/home/santaqiro/yolov3_model/calib_images'
INPUT_H, INPUT_W = 416, 416

def calib_input(iter):
    files = sorted(f for f in os.listdir(CALIB_DIR)
                   if f.lower().endswith(('.jpg', '.jpeg', '.png')))
    img = cv2.imread(os.path.join(CALIB_DIR, files[iter % len(files)]))
    img = cv2.resize(img, (INPUT_W, INPUT_H))
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    return img.astype('float32') / 255.0
EOF
```

#### 4.5.3 执行量化

```bash
cat > ~/yolov3_model/quantize.sh << 'EOF'
#!/bin/bash
set -e

INPUT_PB=/home/santaqiro/yolov3_model/yolov3-tiny.pb
OUTPUT_DIR=/home/santaqiro/yolov3_model/quantized

# ★ 节点名以 4.5.1 inspect 的输出为准
INPUT_NODES="image_input"
OUTPUT_NODES="conv2d_9/BiasAdd,conv2d_12/BiasAdd"

rm -rf $OUTPUT_DIR && mkdir -p $OUTPUT_DIR

# graph_input_fn.py 必须能被 import 到，所以在它所在目录下执行
cd ~/yolov3_model

decent_q quantize \
    --input_frozen_graph $INPUT_PB \
    --input_nodes $INPUT_NODES \
    --output_nodes $OUTPUT_NODES \
    --input_shapes 416,416,3 \
    --input_fn graph_input_fn.calib_input \
    --calib_iter 100 \
    --output_dir $OUTPUT_DIR

echo "[INFO] 量化完成！"
ls -lh $OUTPUT_DIR
EOF

chmod +x ~/yolov3_model/quantize.sh
~/yolov3_model/quantize.sh
```

> 💡 `--calib_iter 100` 表示喂 100 张校准图，COCO 抽 100~200 张即可。
> 如果 inspect 显示输入节点带 batch 维导致 shape 报错，把 `--input_shapes` 改成 `1,416,416,3`
> 并让 `calib_input` 返回时加一维（`img[np.newaxis, ...]`）。

输出（`$OUTPUT_DIR`）：

```
quantized/
├── deploy.pb                       ← 量化后的冻结图
├── quantize_eval_model.pb          ← 量化评估模型
└── quantization_log.txt            ← 量化日志
```

### 4.6 用 dlet 生成 .dcf，再 DNNC 编译为 .elf

> ⚠️ **关键修正**：DNNC 的 `--dcf` 参数要的是**由你自己的硬件生成的 .dcf**（DPU Configuration
> File，记录 B1152 架构、时钟、内存布局等），不是网传的 arch.json。.dcf 用 DNNDK 自带的 `dlet`
> 工具、从 Vivado 工程的 `.hwh` 硬件描述文件生成。**换一次硬件设计就要重新生成一次 .dcf**；
> bitstream 和 .dcf 不配套时，dnnc 能过但板上推理会出错。

```bash
# 1. 找到 .hwh（两种位置任选其一，design_1 换成你的 BD 名）
#    a) Vivado 工程目录：
ls ~/vivado_projects/zturn_v2_dpu/zturn_v2_dpu.srcs/sources_1/bd/design_1/hw_handoff/design_1.hwh
#    b) 或直接解压导出的 system.hdf（.hdf 本质是 zip，里面就有 .hwh）
unzip -o ~/vivado_projects/zturn_v2_dpu/system.hdf -d /tmp/hdf_extract
ls /tmp/hdf_extract/*.hwh

# 2. 生成 .dcf
cd ~/yolov3_model
dlet -f /tmp/hdf_extract/design_1.hwh zturn_v2.dcf
ls -lh zturn_v2.dcf
```

```bash
cat > ~/yolov3_model/compile.sh << 'EOF'
#!/bin/bash
set -e

QUANT_PB=/home/santaqiro/yolov3_model/quantized/deploy.pb
OUTPUT_DIR=/home/santaqiro/yolov3_model/compiled
DCF=/home/santaqiro/yolov3_model/zturn_v2.dcf

rm -rf $OUTPUT_DIR && mkdir -p $OUTPUT_DIR

dnnc \
    --parser=tensorflow \
    --frozen_pb=$QUANT_PB \
    --dcf=$DCF \
    --output_dir=$OUTPUT_DIR \
    --net_name=yolov3_tiny \
    --cpu_arch=arm32

echo "[INFO] 编译完成！"
ls -lh $OUTPUT_DIR
EOF

chmod +x ~/yolov3_model/compile.sh
~/yolov3_model/compile.sh
```

输出：

```
compiled/
├── yolov3_tiny.elf             ← 给 DPU 跑的模型文件！
└── dpu_yolov3_tiny.o           ← 编译中间产物
```

---

## 第 5 章：PS 端部署程序（C++，N2Cube API）

### 5.1 N2Cube API 与 Vitis AI vart API 对比

| 操作 | DNNDK v3.1（N2Cube）| Vitis AI 3.5（vart）|
|---|---|---|
| 头文件 | `#include <n2cube.h>` | `#include <vitis/ai/dpu_task.hpp>` |
| 创建 task | `dlopen` + `dpuCreateKernel` | `DpuTask::create()` |
| 加载模型 | `dpuCreateKernel`（加载 .elf） | 构造时自动 |
| 推理 | `dpuRunTask` | `task->run()` |
| 释放 | `dpuDestroyKernel` | `task.reset()` |

### 5.2 完整 C++ 程序

> 💡 本章代码已按 N2Cube v3.1 官方 API 修订（`dpuCreateKernel`/`dpuCreateTask`/`dpuGetInputTensor`/
> `dpuGetOutputTensor`/`dpuGetTensorAddress` 等）。两个要点：
> ① DPU 的输入输出都是 **int8 量化数据**——输入要按 scale 量化、输出要按 scale 反量化，
> scale 一律用 `dpuGetTensorScale` 从 DPU 读，**不要硬编码**；
> ② 两个输出的 13×13/26×26 顺序按张量大小自动判断（旧版写死顺序，换模型就画乱框）。
> 如个别函数签名与你的 `n2cube.h` 有出入，以头文件为准，并建议对照原项目仓库 `Deployment/` 目录源码。

创建 `yolov3_main.cpp`：

```cpp
// yolov3_main.cpp
// PS 端 YOLOv3-tiny 推理程序（基于 N2Cube DNNDK v3.1 API）

#include <iostream>
#include <vector>
#include <string>
#include <chrono>
#include <opencv2/opencv.hpp>

#include <n2cube.h>   // DNNDK v3.1 N2Cube API

using namespace std;
using namespace cv;

// ==================== YOLOv3-tiny 配置 ====================
static const int INPUT_W = 416;
static const int INPUT_H = 416;
static const int NUM_CLASSES = 80;

// COCO 80 类名称（按 YOLOv3 输出顺序）
static const char* COCO_CLASSES[] = {
    "person", "bicycle", "car", "motorbike", "aeroplane",
    "bus", "train", "truck", "boat", "traffic light",
    "fire hydrant", "stop sign", "parking meter", "bench", "bird",
    "cat", "dog", "horse", "sheep", "cow",
    "elephant", "bear", "zebra", "giraffe", "backpack",
    "umbrella", "handbag", "tie", "suitcase", "frisbee",
    "skis", "snowboard", "sports ball", "kite", "baseball bat",
    "baseball glove", "skateboard", "surfboard", "tennis racket", "bottle",
    "wine glass", "cup", "fork", "knife", "spoon",
    "bowl", "banana", "apple", "sandwich", "orange",
    "broccoli", "carrot", "hot dog", "pizza", "donut",
    "cake", "chair", "sofa", "pottedplant", "bed",
    "diningtable", "toilet", "tvmonitor", "laptop", "mouse",
    "remote", "keyboard", "cell phone", "microwave", "oven",
    "toaster", "sink", "refrigerator", "book", "clock",
    "vase", "scissors", "teddy bear", "hair drier", "toothbrush"
};

// YOLOv3-tiny anchors（darknet 默认）
static const float ANCHORS[6][2] = {
    {10, 14}, {23, 27}, {33, 23},   // 13x13 尺度
    {30, 61}, {62, 45}, {59, 119}   // 26x26 尺度
};

static const float CONF_THRESHOLD = 0.25f;
static const float NMS_THRESHOLD = 0.45f;

struct Detection {
    cv::Rect box;
    int class_id;
    float confidence;
};

// ==================== 数学工具 ====================
inline float sigmoid(float x) {
    return 1.0f / (1.0f + std::exp(-x));
}

// ==================== YOLO 输出解码 ====================
// ⚠️ DPU 输出是 int8 量化数据：每个值先乘 scale 反量化，再进 sigmoid/exp
vector<Detection> decode_one_scale(
    const int8_t* data,
    float scale,
    int grid_w, int grid_h,
    const float anchors[3][2],
    int stride,
    float conf_threshold)
{
    vector<Detection> detections;
    const int EACH_BOX = 5 + NUM_CLASSES;

    for (int h = 0; h < grid_h; h++) {
        for (int w = 0; w < grid_w; w++) {
            for (int n = 0; n < 3; n++) {
                int idx = (h * grid_w + w) * 3 * EACH_BOX + n * EACH_BOX;

                float obj_conf = sigmoid(data[idx + 4] * scale);
                if (obj_conf < conf_threshold) continue;

                // 找最高类别置信度
                float max_class_conf = 0;
                int max_class_id = -1;
                for (int c = 0; c < NUM_CLASSES; c++) {
                    float class_conf = sigmoid(data[idx + 5 + c] * scale);
                    if (class_conf > max_class_conf) {
                        max_class_conf = class_conf;
                        max_class_id = c;
                    }
                }
                float confidence = obj_conf * max_class_conf;
                if (confidence < conf_threshold) continue;

                // 中心坐标
                float bx = (sigmoid(data[idx + 0] * scale) + w) * stride;
                float by = (sigmoid(data[idx + 1] * scale) + h) * stride;
                float bw = std::exp(data[idx + 2] * scale) * anchors[n][0];
                float bh = std::exp(data[idx + 3] * scale) * anchors[n][1];

                int x1 = int(bx - bw / 2);
                int y1 = int(by - bh / 2);
                int w_ = int(bw);
                int h_ = int(bh);

                detections.push_back({
                    cv::Rect(x1, y1, w_, h_),
                    max_class_id,
                    confidence
                });
            }
        }
    }
    return detections;
}

// ==================== NMS ====================
vector<Detection> nms(vector<Detection>& dets, float nms_threshold) {
    vector<Detection> result;
    if (dets.empty()) return result;

    std::sort(dets.begin(), dets.end(),
              [](const Detection& a, const Detection& b) {
                  return a.confidence > b.confidence;
              });

    vector<bool> suppressed(dets.size(), false);
    for (size_t i = 0; i < dets.size(); i++) {
        if (suppressed[i]) continue;
        result.push_back(dets[i]);
        for (size_t j = i + 1; j < dets.size(); j++) {
            if (suppressed[j]) continue;
            if (dets[i].class_id != dets[j].class_id) continue;

            cv::Rect intersection = dets[i].box & dets[j].box;
            float inter_area = intersection.area();
            float union_area = dets[i].box.area() + dets[j].box.area() - inter_area;
            float iou = (union_area > 0) ? inter_area / union_area : 0;

            if (iou > nms_threshold) {
                suppressed[j] = true;
            }
        }
    }
    return result;
}

// ==================== 主程序 ====================
int main(int argc, char** argv) {
    if (argc < 3) {
        cerr << "用法: " << argv[0] << " <model.elf> <image_path>" << endl;
        return 1;
    }

    string model_path = argv[1];
    string image_path = argv[2];

    // 1. 初始化 N2Cube
    cout << "[INFO] 初始化 N2Cube..." << endl;
    int ret = dnndk_init();
    if (ret != 0) {
        cerr << "[ERROR] dnndk_init 失败: " << ret << endl;
        return 1;
    }

    // 2. 创建 DPU Kernel（加载 .elf）
    cout << "[INFO] 创建 DPU Kernel: " << model_path << endl;
    DPUKernel* kernel = nullptr;
    ret = dpuCreateKernel(&kernel, model_path.c_str());
    if (ret != 0 || kernel == nullptr) {
        cerr << "[ERROR] 加载 ELF 失败: " << ret << endl;
        return 1;
    }

    // 3. 创建 DPU Task（0 = DPU_MODE_NORMAL）
    DPUTask* task = dpuCreateTask(kernel, 0);
    if (task == nullptr) {
        cerr << "[ERROR] 创建 DPU Task 失败" << endl;
        return 1;
    }

    // 4. 获取输入输出 Tensor（DNNDK v3.1 标准流程：先拿 DTensor，再取地址/大小/量化 scale）
    // ★ 节点名与 4.5 量化时指定的 input_nodes/output_nodes 一致
    const char* INPUT_NODE    = "image_input";          // ★ 以 decent_q inspect 结果为准
    const char* OUTPUT_NODE_0 = "conv2d_9/BiasAdd";     // 13×13
    const char* OUTPUT_NODE_1 = "conv2d_12/BiasAdd";    // 26×26

    DTensor* inT   = dpuGetInputTensor(task, INPUT_NODE);
    DTensor* outT0 = dpuGetOutputTensor(task, OUTPUT_NODE_0);
    DTensor* outT1 = dpuGetOutputTensor(task, OUTPUT_NODE_1);

    int8_t* input_data    = (int8_t*)dpuGetTensorAddress(inT);
    int8_t* output_data_0 = (int8_t*)dpuGetTensorAddress(outT0);
    int8_t* output_data_1 = (int8_t*)dpuGetTensorAddress(outT1);

    int input_size    = dpuGetTensorSize(inT);     // 416*416*3 = 519168
    int output_size_0 = dpuGetTensorSize(outT0);   // 13×13×255 = 43095
    int output_size_1 = dpuGetTensorSize(outT1);   // 26×26×255 = 172380

    // 量化 scale 一律从 DPU 读，不要硬编码
    float input_scale    = dpuGetTensorScale(inT);
    float output_scale_0 = dpuGetTensorScale(outT0);
    float output_scale_1 = dpuGetTensorScale(outT1);

    cout << "[INFO] 输入大小: " << input_size << " bytes" << endl;
    cout << "[INFO] 输出 0 大小: " << output_size_0 << " bytes" << endl;
    cout << "[INFO] 输出 1 大小: " << output_size_1 << " bytes" << endl;

    // 5. 读取图像
    Mat img = imread(image_path);
    if (img.empty()) {
        cerr << "[ERROR] 无法读取图像: " << image_path << endl;
        return 1;
    }
    cout << "[INFO] 输入图像: " << img.size() << endl;

    // 6. 预处理：resize 到 416x416 + BGR→RGB + normalize
    Mat resized, rgb, normalized;
    resize(img, resized, Size(INPUT_W, INPUT_H));
    cvtColor(resized, rgb, COLOR_BGR2RGB);
    normalized = rgb.clone();
    normalized.convertTo(normalized, CV_32F, 1.0 / 255.0);  // [0, 1]

    // 7. float [0,1] 输入 → int8 量化（scale 用第 4 步从 DPU 读到的 input_scale）
    for (int h = 0; h < INPUT_H; h++) {
        for (int w = 0; w < INPUT_W; w++) {
            Vec3f px = normalized.at<Vec3f>(h, w);   // RGB，[0,1]
            for (int c = 0; c < 3; c++) {
                int q = (int)roundf(px[c] / input_scale);
                if (q < -128) q = -128;
                if (q > 127)  q = 127;
                input_data[(h * INPUT_W + w) * 3 + c] = (int8_t)q;
            }
        }
    }

    // 8. 推理
    cout << "[INFO] 开始 DPU 推理..." << endl;
    auto start = chrono::high_resolution_clock::now();
    ret = dpuRunTask(task);
    auto end = chrono::high_resolution_clock::now();

    if (ret != 0) {
        cerr << "[ERROR] 推理失败: " << ret << endl;
        return 1;
    }

    double duration = chrono::duration_cast<chrono::milliseconds>(end - start).count() / 1000.0;
    cout << "[INFO] 推理时间: " << duration << " 秒" << endl;

    // 9. 后处理：解码两个尺度的输出
    // ⚠️ 输出顺序不要写死：keras-yolo3 转出的模型是 [13x13, 26x26]，DNNC 编译后顺序还可能变。
    //    稳妥做法是按张量大小自动判断：13×13 = 43095 个元素，26×26 = 172380 个元素
    vector<Detection> all_dets;

    if (output_size_0 < output_size_1) {
        // 输出0 = 13x13（大目标尺度：前 3 个 anchor，stride 32）
        auto dets_0 = decode_one_scale(output_data_0, output_scale_0, 13, 13,
                                       (const float (*)[2])&ANCHORS[0],
                                       INPUT_W / 13,
                                       CONF_THRESHOLD);
        all_dets.insert(all_dets.end(), dets_0.begin(), dets_0.end());

        // 输出1 = 26x26（小目标尺度：后 3 个 anchor，stride 16）
        auto dets_1 = decode_one_scale(output_data_1, output_scale_1, 26, 26,
                                       (const float (*)[2])&ANCHORS[3],
                                       INPUT_W / 26,
                                       CONF_THRESHOLD);
        all_dets.insert(all_dets.end(), dets_1.begin(), dets_1.end());
    } else {
        // 输出0 = 26x26，输出1 = 13x13
        auto dets_0 = decode_one_scale(output_data_0, output_scale_0, 26, 26,
                                       (const float (*)[2])&ANCHORS[3],
                                       INPUT_W / 26,
                                       CONF_THRESHOLD);
        all_dets.insert(all_dets.end(), dets_0.begin(), dets_0.end());

        auto dets_1 = decode_one_scale(output_data_1, output_scale_1, 13, 13,
                                       (const float (*)[2])&ANCHORS[0],
                                       INPUT_W / 13,
                                       CONF_THRESHOLD);
        all_dets.insert(all_dets.end(), dets_1.begin(), dets_1.end());
    }

    // 10. NMS
    auto final_dets = nms(all_dets, NMS_THRESHOLD);
    cout << "[INFO] 检测到 " << final_dets.size() << " 个目标" << endl;

    // 11. 画框并保存
    for (const auto& det : final_dets) {
        // 映射回原图尺寸
        int x1 = det.box.x * img.cols / INPUT_W;
        int y1 = det.box.y * img.rows / INPUT_H;
        int w = det.box.width * img.cols / INPUT_W;
        int h = det.box.height * img.rows / INPUT_H;

        rectangle(img, Rect(x1, y1, w, h), Scalar(0, 255, 0), 2);
        string label = format("%s: %.2f", COCO_CLASSES[det.class_id], det.confidence);
        putText(img, label,
                Point(x1, y1 - 5),
                FONT_HERSHEY_SIMPLEX, 0.5, Scalar(0, 255, 0), 2);
        cout << "  - " << label << " @ "
             << x1 << "," << y1
             << " size " << w << "x" << h << endl;
    }

    imwrite("result.jpg", img);
    cout << "[INFO] 结果已保存到 result.jpg" << endl;

    // 12. 清理
    dpuDestroyTask(task);
    dpuDestroyKernel(kernel);
    dpuFinalize();

    return 0;
}
```

### 5.3 交叉编译脚本

在主机 Ubuntu 上编译出能在 Z-turn V2 上跑的 ARM 可执行文件。

```bash
# ① 打包并安装 PetaLinux SDK（一次性；提供交叉工具链 + sysroot 里的 OpenCV）
cd ~/petalinux_projects/zturn_v2_dpu_plnx
petalinux-package --sysroot
# 生成 images/linux/sdk.sh，安装到任意目录：
./images/linux/sdk.sh -d ~/sdk -y
source ~/sdk/environment-setup-armv7ahf-neon-xilinx-linux-gnueabi

# ② 验证交叉编译器
echo $CXX        # arm-xilinx-linux-gnueabihf-g++（SDK 环境会自动带上 --sysroot）
$CXX --version

# ③ 编译（OpenCV 头文件/库直接来自 SDK sysroot）
$CXX -O2 -std=c++11 \
    -I/home/santaqiro/n2cube_tool/n2cube/include \
    -L/home/santaqiro/n2cube_tool/n2cube/lib \
    yolov3_main.cpp \
    -o yolov3_app \
    -lopencv_core -lopencv_imgproc -lopencv_imgcodecs -lopencv_highgui \
    -ln2cube -ldputils -lhineon -lpthread

echo "[INFO] 编译完成：yolov3_app"
file yolov3_app
# 应该输出：ELF 32-bit LSB executable, ARM, ...
```

> 💡 **修正说明**：旧版写的 "source settings.sh 后直接用 $CXX" 不可靠（settings.sh 并不导出 CXX），
> 正确做法是 `petalinux-package --sysroot` 打包 SDK 并 source 它的环境脚本。
> 链接库 `-ln2cube -ldputils -lhineon -lpthread` 是 DNNDK v3.1 官方 sample Makefile 的原文参数；
> 头文件需要 `n2cube.h` + `dputils.h`（开发包 include 目录里都有）。

### 5.4 部署到 Z-turn V2

```bash
# 假设板子 IP 是 192.168.1.99
scp yolov3_app root@192.168.1.99:/home/root/
scp ~/yolov3_model/compiled/yolov3_tiny.elf root@192.168.1.99:/home/root/
scp test_image.jpg root@192.168.1.99:/home/root/
```

---

## 第 6 章：SD 卡烧写与上电启动

### 6.1 准备 SD 卡

#### 6.1.1 SD 卡分区（首次启动）

```bash
# 在主机 Ubuntu 上识别 SD 卡
lsblk
# 假设 SD 卡是 /dev/sdb

# 分区
sudo fdisk /dev/sdb

# 在 fdisk 中：
# d → 删除所有现有分区
# n → 新建分区1：起始默认，+512M，类型 FAT32 (W95 / LBA)
# n → 新建分区2：起始默认，结束默认，类型 Linux (83)
# w → 保存退出

# 格式化
sudo mkfs.vfat -F 32 -n BOOT /dev/sdb1
sudo mkfs.ext4 -L rootfs /dev/sdb2
```

#### 6.1.2 拷贝启动文件

```bash
BOOT=/media/santaqiro/BOOT
ROOT=/media/santaqiro/rootfs

# 拷贝 BOOT.BIN 和内核到 FAT 分区
cp ~/petalinux_projects/zturn_v2_dpu_plnx/images/linux/BOOT.BIN $BOOT/
cp ~/petalinux_projects/zturn_v2_dpu_plnx/images/linux/image.ub $BOOT/

# 解压根文件系统到 ext4 分区
sudo rm -rf $ROOT/*
sudo tar -xvf ~/petalinux_projects/zturn_v2_dpu_plnx/images/linux/rootfs.tar.gz \
    -C $ROOT

# 部署模型和应用
sudo cp yolov3_tiny.elf $ROOT/home/root/
sudo cp yolov3_app $ROOT/usr/bin/
sudo chmod +x $ROOT/usr/bin/yolov3_app
sudo cp coco.names $ROOT/home/root/
sudo cp test_image.jpg $ROOT/home/root/

# ★ 拷入 DNNDK 板端运行时（ZedBoard 子包：dpu.ko 驱动 + dexplorer 工具 + libn2cube/libdputils 库）
sudo cp -r ~/dnndk_board/xilinx_dnndk_v3.1/ZedBoard $ROOT/home/root/

# 同步 + 卸载
sync
umount $BOOT $ROOT
```

### 6.2 设置 Z-turn V2 启动模式

Z-turn V2 的启动模式跳线：

```
JP1 (Boot Mode): SD 卡启动位（参考用户手册）
JP2 (Power):    REG 位置
```

### 6.3 上电启动

1. 把 TF 卡插入 Z-turn V2 卡槽
2. 插上 5V 电源
3. 通过 Micro-USB 连接主机（USB-UART 调试）
4. 在主机上打开串口终端（115200 8N1）：
   ```bash
   sudo minicom -D /dev/ttyUSB0
   # 或
   sudo screen /dev/ttyUSB0 115200
   ```
5. **打开电源开关**，看到启动日志

### 6.4 登录与基本配置

```bash
# 默认登录（如果 PetaLinux 默认配置）
用户名：root
密码：root
```

设置网络：

```bash
ifconfig eth0 192.168.1.99
```

通过 SSH 登录：

```bash
ssh root@192.168.1.99
```

### 6.5 验证 DPU 是否识别

```bash
# 在板子上执行（⚠️ DNNDK v3.1 的 DPU 查询工具叫 dexplorer，不是 xdputil；
# xdputil 是 Vitis AI 之后才出现的工具名）
dexplorer                          # 直接运行打印 DPU 状态/用法
ls /dev/dpu* && lsmod | grep dpu   # 驱动加载成功应有 /dev/dpu 与 dpu 模块
# 若 /dev/dpu 不存在：进 ZedBoard 包目录执行 ./install.sh（自动装 dpu.ko 并 modprobe）
```

正常输出（示意；dexplorer 的输出格式与旧版所写 xdputil 不同）：

```
DPU IP Spec : 1 DPU Core, B1152 Arch
DPU Frequency : 150MHz
```

能看到 `B1152` / `1 DPU Core` 相关信息，说明 DPU 已经成功加载！

---

## 第 7 章：功能验证与常见问题排查

### 7.1 第一次推理

```bash
# 在 Z-turn V2 上
cd /home/root

./yolov3_app yolov3_tiny.elf test_image.jpg
```

正常输出：

```
[INFO] 初始化 N2Cube...
[INFO] 创建 DPU Kernel: yolov3_tiny.elf
[INFO] 输入大小: 519168 bytes      # 416×416×3 int8
[INFO] 输出 0 大小: 43095 bytes    # 13×13×255 int8
[INFO] 输出 1 大小: 172380 bytes   # 26×26×255 int8
[INFO] 输入图像: [1920, 1080]
[INFO] 开始 DPU 推理...
[INFO] 推理时间: 0.432 秒
[INFO] 检测到 3 个目标
  - person: 0.89 @ 320,180 size 180x320
  - car: 0.76 @ 850,540 size 380x220
  - dog: 0.55 @ 1100,420 size 120x140
[INFO] 结果已保存到 result.jpg
```

### 7.2 性能基准测试

```bash
# DNNDK v3.1 自带的查询/调试工具（无独立 benchmark 子命令，直接跑应用计时即可）
dexplorer
ddump
```

### 7.3 常见问题与解决方案

#### 问题 1：DPU 无法识别（`xdputil query` 报错）

**症状**：

```
open /dev/dpu failed
```

**排查**：

```bash
# 检查内核是否识别 DPU
dmesg | grep -i dpu
ls /dev/dpu*

# 检查设备树（DNNDK v3.1 写法：xlnk + xilinx,dpu）
ls /proc/device-tree/ | grep -E "dpu|xlnk"
cat /proc/device-tree/dpu*/compatible 2>/dev/null
# 应该看到 xilinx,dpu / xilinx,dpucore / xlnx,xlnk-1.0

# 检查 dpu 模块加载情况（3.2.6 的 recipes-modules）
dmesg | grep -i dpu
```

**解决**：

- 设备树节点未生效 → 修改 `system-user.dtsi`（见 3.3），重新 `petalinux-build`
- bitstream 未加载 → 检查 `system.bit` 是否被打包到 BOOT.BIN
- dpu.ko 没装进 rootfs → 检查 3.2.6 的 recipes-modules 步骤（`CONFIG_dpu` + `IMAGE_INSTALL_append = " dpu"`），重新 `petalinux-build`
- xlnk 节点缺失或 bootargs 没有 `cma=256M` → 见 3.2.4 和 3.3

#### 问题 2：启动时 kernel panic（Unable to mount root fs）

**症状**：

```
VFS: Cannot open root device "mmcblk0p2"
```

**排查**：

- SD 卡第二个分区没有 ext4 文件系统
- 设备树中的 mmc 配置错误

**解决**：

```bash
# 重新分区 + 重新拷贝（见 6.1）
```

#### 问题 3：DDR 不工作，启动卡住

**症状**：

```
ERROR: DDR initialization failed
```

**排查**：

- Vivado 中 PS 配置的 DDR 参数与 Z-turn V2 实际不匹配
- 速度等级选错（-1 错选为 -2 或反之）

**解决**：

- Z-turn V2 用的 DDR3 是 NT5CC256M16ER-EK（两片 256Mx16 = 32-bit 1GB）
- 在 Zynq PS 配置里选 **MT41K256M16HA-125** 或手动配置：256M16、Row=15、Bank=3、Column=10
- 时钟 1066 Mbps，速度等级 -2

#### 问题 4：综合/实现时报 DPU 资源不够

**症状**：

```
ERROR: [Place 30-58] DPUCZDX8G instance ... requires more DSPs than available
```

**解决**：

- 把 DPU Architecture 从 B1600 降到 **B1152**
- 把 Softmax 设为 Disable
- 把 RAM Usage 设为 Low

#### 问题 5：DNNC 编译失败

**症状**：

```
[ERROR] DNNC failed: unsupported layer
```

**解决**：

- 检查 YOLOv3-tiny 是否有不支持的算子（Leaky ReLU 需要在 config 里 enable）
- 重新量化时用 `--input_nodes` 和 `--output_nodes` 指定正确节点
- 检查 .dcf 是否由你当前硬件的 .hwh 生成（见 4.6），bitstream 与 .dcf 必须配套

#### 问题 6：推理结果全是乱框 / 精度很差

**症状**：

- 推理时间正常，但画框位置完全错误

**解决**：

- .dcf 不配套：必须用你当前硬件 .hwh 生成的 .dcf（见 4.6），对应 B1152 配置
- 输入数据归一化不对：必须 `/255.0`
- 输出解码顺序错了：YOLOv3-tiny 有 2 个输出张量，顺序可能是 `[13x13, 26x26]` 也可能是 `[26x26, 13x13]`，需要调试：
  ```bash
  # 在板子上看输出 tensor 大小判断
  ./yolov3_app yolov3_tiny.elf test.jpg
  # 看哪个输出是 13x13（43095 个元素），哪个是 26x26（172380 个元素）
  ```
- 输出忘了反量化：DPU 输出是 int8，必须乘 `dpuGetTensorScale` 返回的 scale（见 5.2 代码）

#### 问题 7：PetaLinux 编译 OOM

**症状**：

```
[ERROR] petalinux-build 失败：Out of memory
```

**解决**：

- 关掉 VM 里其他程序
- 减少 PetaLinux 并行编译数：
  ```bash
  petalinux-build -j 2
  ```

---

## 附录 A：资源占用估算

### A.1 DPU v3.1 B1152 在 XC7Z020 上的资源

| 资源 | B1152 占用 | Zynq-7020 总数 | 余量 |
|---|---|---|---|
| LUT | ~22,000 | 53,200 | 41% |
| LUTRAM | ~5,000 | 17,400 | 71% |
| FF | ~40,000 | 106,400 | 62% |
| BRAM (36Kb) | ~100 | 140 | 28% |
| DSP | ~190 | 220 | 14%（⚠️ 紧张）|

### A.2 内存占用

| 模块 | 大小 | 用途 |
|---|---|---|
| YOLOv3-tiny 权重 | ~17MB | 存储在 ext4 文件系统 |
| DPU 指令缓存 | ~1MB | 存储在 BRAM |
| 推理中间特征图 | ~30-80MB | 存在 DDR 中 |
| 系统 + 应用 | ~150MB | rootfs |

### A.3 推理时间（YOLOv3-tiny @ B1152）

| 阶段 | 耗时 |
|---|---|
| 数据传输 PS → DPU | ~50ms |
| DPU 推理 | ~350ms |
| 数据传输 DPU → PS | ~30ms |
| 后处理 (NMS) | ~10ms |
| **总计** | **~0.45 秒/帧** |

实时性：约 **2 FPS**。

---

## 附录 B：关键命令速查

### B.1 Vivado 2019.1

```tcl
# 创建工程（GUI）
File → Project → New

# 验证设计
Tools → Validate Design (F6)

# 生成 Output Products
右键 design_1.bd → Generate Output Products

# 生成 Bitstream
Flow Navigator → Generate Bitstream

# 导出硬件（注意是 .hdf）
File → Export → Export Hardware → Pre-synthesis → Include bitstream → system.hdf
```

### B.2 PetaLinux 2019.1

```bash
# 创建工程
petalinux-create -t project --template zynq --name <NAME>

# 配置
petalinux-config                  # 主配置
petalinux-config -c kernel        # 内核配置
petalinux-config -c rootfs        # 文件系统配置
petalinux-config -c u-boot        # U-Boot 配置

# 导入硬件（注意是 .hdf）
petalinux-config --get-hw-description=<PATH_TO_HDF_DIR>

# 构建
petalinux-build
petalinux-build -j 2              # 限制并行数为 2（VM 内存紧张时用）

# 清理
petalinux-build -c <component> -x distclean
petalinux-build -x mrproper       # 全清

# 生成 BOOT.BIN
petalinux-package --boot --fsbl images/linux/zynq_fsbl.elf \
    --fpga images/linux/system.bit --u-boot --force

# 查看版本
petalinux-version
```

### B.3 DNNDK v3.1（量化 + 编译）

```bash
# 查看模型节点名（量化前必做）
decent_q inspect --input_frozen_graph model.pb

# 量化（v3.1 语法：--input_fn + --calib_iter，先 cd 到 graph_input_fn.py 所在目录）
decent_q quantize \
    --input_frozen_graph model.pb \
    --input_nodes <inspect 得到的输入节点> \
    --output_nodes <输出节点1>,<输出节点2> \
    --input_shapes 416,416,3 \
    --input_fn graph_input_fn.calib_input \
    --calib_iter 100 \
    --output_dir ./quantized

# 由 Vivado 的 .hwh 生成 DPU 描述文件（换硬件设计后要重新生成）
dlet -f design_1.hwh zturn_v2.dcf

# 编译
dnnc \
    --parser=tensorflow \
    --frozen_pb quantized/deploy.pb \
    --dcf zturn_v2.dcf \
    --output_dir ./compiled \
    --net_name yolov3_tiny \
    --cpu_arch arm32
```

### B.4 板端调试

```bash
# DPU 状态查询（DNNDK v3.1 工具叫 dexplorer；Vitis AI 之后才改叫 xdputil）
dexplorer
ls -la /dev/dpu*

# 查看设备树
cat /proc/device-tree/model
ls /sys/firmware/devicetree/base/

# 查看 DPU 设备
ls -la /dev/dpu*

# 查看内核日志
dmesg | grep -i dpu
dmesg | grep -i fpga

# 查看内存
free -h

# 查看 CPU 信息
cat /proc/cpuinfo
```

---

## 附录 C：参考资源

| 资源 | 链接 |
|---|---|
| 原项目 GitHub | https://github.com/andre1araujo/YOLO-on-PYNQ-Z2 |
| 原项目 GitBook | https://andre-araujo.gitbook.io/yolo-on-pynq-z2/ |
| DNNDK 用户指南 (UG1327) | 见 Xilinx Archive |
| DPU IP 文档 (PG338 v3.1) | 见 Xilinx Archive |
| PetaLinux 文档 (UG1144) | https://docs.xilinx.com/r/en-US/ug1144-petalinux-tools-reference-guide |
| Vivado 文档 (UG973) | https://docs.xilinx.com/r/en-US/ug973-vivado-release-notes-install-license |
| MYIR Z-turn V2 产品页 | https://www.myirtech.com/list.asp?id=708 |
| MYIR Z-turn V2 原理图 | 见 MYIR 官网 Downloads |
| Zynq-7000 TRM (UG585) | https://docs.xilinx.com/r/en-US/ug585-zynq-7000-SoC-TRM |

---

## 附录 D：版本对应表（本教程使用）

| 工具 | 版本 | 对应 DPU IP | Linux |
|---|---|---|---|
| Vivado | 2019.1 | DPU v3.1 | Linux 4.19 |
| PetaLinux | 2019.1 | - | Linux 4.19 |
| DNNDK | v3.1 | DPU v3.1 | Linux 4.19 |
| Python | 3.5/3.6 | - | - |
| TensorFlow | 1.15 | - | - |
| OpenCV | 3.x | - | - |

> 本教程使用 **Vivado 2019.1 + PetaLinux 2019.1 + DNNDK v3.1**。
> 这是 andre1araujo 原项目用的工具链组合，Ubuntu 16.04 官方支持。

---

**写在最后**：

这个版本（Vivado 2019.1）的教程是基于原作者项目的**工具链原版**，**90% 的步骤可以直接复用原作者项目**。

**与 Vivado 2023.2 教程的关键区别**：

| 项目 | 2019.1 版 | 2023.2 版 |
|---|---|---|
| Vivado 工程导出 | `.hdf` | `.xsa` |
| PS 软件开发 | SDK（已包含在 Vivado 里）| Vitis（独立 IDE）|
| 模型量化 | `decent_q` | `vai_q_tensorflow2` |
| 模型编译 | `dnnc` | `vai_c_xir` |
| 板端 API | N2Cube (`n2cube.h`) | vart (`dpu_task.hpp`) |
| OS 兼容 | Ubuntu 16.04 ✅ | Ubuntu 20.04 ✅ |
| Docker | 不需要 | 需要（Vitis AI Docker）|

按本教程 2-3 周内可以跑通 YOLOv3-tiny 推理。遇到问题先看原作者项目和社区资源（Vivado 2019.1 的中文资料很多）。

---

**最后更新**：2026-09-06
**目标读者**：Z-turn Board V2 用户，已有 VMware Ubuntu 16.04 环境

# E:\yoloProject 项目结构与 VMware 共享文件夹配置

> **配套教程**：[YOLOv3-on-Z-turn-V2-Tutorial.md](YOLOv3-on-Z-turn-V2-Tutorial.md)
> **目标**：在 Windows 主机 `E:\yoloProject` 和 VMware Ubuntu 之间建立无缝的文件共享通道，避免 scp 反复传输

---

## 目录

- [第 1 部分：E:\yoloProject 目录结构设计](#第-1-部分eyoloproject-目录结构设计)
- [第 2 部分：VMware 共享文件夹配置](#第-2-部分vmware-共享文件夹配置)
- [第 3 部分：Ubuntu VM 里的使用规范](#第-3-部分ubuntu-vm-里的使用规范)
- [第 4 部分：常见问题排查](#第-4-部分常见问题排查)

---

## 第 1 部分：E:\yoloProject 目录结构设计

### 1.1 完整结构

```
E:\yoloProject\                                       (Windows 主机)
│
├── README.md                                          ← 本文件
├── YOLOv3-on-Z-turn-V2-Tutorial.md                    ← 主教程
│
├── vivado_projects\                                   ← Vivado 工程根目录
│   └── zturn_v2_dpu\                                  ← 我们的 Vivado 工程
│       ├── system.hdf                                 ← PetaLinux 用的硬件描述
│       ├── system.bit                                 ← FPGA bitstream
│       ├── design_1_wrapper.v
│       └── ...
│
├── petalinux_projects\                                ← PetaLinux 工程根目录
│   └── zturn_v2_dpu_plnx\                             ← 我们的 PetaLinux 工程
│       ├── project-spec\
│       ├── images\linux\                              ← build 输出
│       │   ├── BOOT.BIN
│       │   ├── image.ub
│       │   └── rootfs.tar.gz
│       └── ...
│
├── yolov3_model\                                      ← 模型工作目录
│   ├── weights\                                       ← 预训练权重
│   │   └── yolov3-tiny.weights
│   ├── darknet_cfg\                                   ← Darknet 配置
│   │   └── yolov3-tiny.cfg
│   ├── keras_model\                                   ← Keras 中间格式
│   │   └── yolov3-tiny.h5
│   ├── frozen_pb\                                     ← TF 冻结图
│   │   └── yolov3-tiny.pb
│   ├── calib_images\                                  ← 量化校准图片集
│   │   ├── 0001.jpg
│   │   └── ...
│   ├── quantized\                                     ← DECENT_Q 量化输出
│   │   └── deploy.pb
│   ├── compiled\                                      ← DNNC 编译输出
│   │   └── yolov3_tiny.elf
│   └── scripts\                                       ← 模型转换脚本
│       ├── keras_to_pb.py
│       ├── quantize.sh
│       └── compile.sh
│
├── dnnc_tool\                                         ← DNNDK v3.1 工具解压
│   ├── dnnc\                                          ← DNNC 编译器
│   │   ├── dnnc
│   │   └── arch.json
│   └── ...
│
├── n2cube_tool\                                       ← N2Cube 运行时解压
│   └── n2cube\
│       ├── lib\
│       │   ├── libn2cube.so
│       │   └── libDNNDK.so
│       └── include\
│           └── n2cube.h
│
├── dpu_ip\                                            ← DPU v3.1 IP 仓库
│   └── DPU_TRD\
│       └── dpu_ip\
│
├── sdcard\                                            ← 烧写 SD 卡相关
│   ├── BOOT\                                          ← FAT32 分区镜像
│   └── rootfs\                                        ← ext4 分区镜像
│
├── board_deploy\                                      ← 部署到板子的文件
│   ├── yolov3_tiny.elf                                ← 模型
│   ├── yolov3_app                                     ← 编译好的可执行文件
│   └── test_images\                                   ← 测试图片
│       └── test_image.jpg
│
├── docs\                                              ← 个人笔记、参考资料
│   ├── setup_notes.md                                 ← 装机笔记
│   ├── issues_log.md                                  ← 踩坑记录
│   └── references\                                    ← PDF 文档
│
└── .gitignore                                         ← Git 忽略（可选）
```

### 1.2 各目录的用途说明

| 目录 | 主机端操作 | VM 端操作 | 备注 |
|---|---|---|---|
| `vivado_projects\` | ✅ 编辑 | 编译 | 在哪里建都行，建议在 VM 里 |
| `petalinux_projects\` | ❌ | ✅ 必做 | 必须在 Ubuntu 里 |
| `yolov3_model\` | ✅ 编辑 | ✅ 处理 | 共享最频繁 |
| `dnnc_tool/` | ❌ | ✅ 用 | DNNC 是 Linux 程序 |
| `n2cube_tool/` | ❌ | ✅ 用 | 交叉编译 + 部署到板子 |
| `dpu_ip/` | ❌ | ✅ 用 | Vivado IP 仓库 |
| `sdcard/` | ✅ 编辑 | ✅ 拷贝 | 最终镜像文件 |
| `board_deploy/` | ✅ 编辑 | ✅ 编译 | 板子跑的最终文件 |
| `docs/` | ✅ 编辑 | ❌ | 仅主机查看 |

### 1.3 一次性创建所有目录

在 Windows PowerShell 里跑（管理员权限）：

```powershell
cd E:\yoloProject

$dirs = @(
    "vivado_projects",
    "petalinux_projects",
    "yolov3_model\weights",
    "yolov3_model\darknet_cfg",
    "yolov3_model\keras_model",
    "yolov3_model\frozen_pb",
    "yolov3_model\calib_images",
    "yolov3_model\quantized",
    "yolov3_model\compiled",
    "yolov3_model\scripts",
    "dnnc_tool",
    "n2cube_tool",
    "dpu_ip",
    "sdcard\BOOT",
    "sdcard\rootfs",
    "board_deploy\test_images",
    "docs\references"
)

foreach ($d in $dirs) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}

Get-ChildItem -Recurse | Where-Object { $_.PSIsContainer } | Select-Object FullName
```

或一行命令：

```powershell
mkdir E:\yoloProject\vivado_projects, E:\yoloProject\petalinux_projects, E:\yoloProject\yolov3_model\weights, E:\yoloProject\yolov3_model\darknet_cfg, E:\yoloProject\yolov3_model\keras_model, E:\yoloProject\yolov3_model\frozen_pb, E:\yoloProject\yolov3_model\calib_images, E:\yoloProject\yolov3_model\quantized, E:\yoloProject\yolov3_model\compiled, E:\yoloProject\yolov3_model\scripts, E:\yoloProject\dnnc_tool, E:\yoloProject\n2cube_tool, E:\yoloProject\dpu_ip, E:\yoloProject\sdcard\BOOT, E:\yoloProject\sdcard\rootfs, E:\yoloProject\board_deploy\test_images, E:\yoloProject\docs\references
```

---

## 第 2 部分：VMware 共享文件夹配置

### 2.1 第一步：VMware 添加共享文件夹

> ⚠️ 必须先**关闭 Ubuntu 电源**，不是挂起。

1. VMware Workstation 主界面
2. 选中你的 Ubuntu VM
3. 点「编辑虚拟机设置（Edit virtual machine settings）」
4. 切到「选项（Options）」标签
5. 选「共享文件夹（Shared Folders）」
6. 默认是「已禁用（Disabled）」，改为「**总是启用（Always Enabled）**」
7. 点击「添加（Add）」按钮：

```
添加共享文件夹向导：
├─ 主机路径（Host path）: E:\yoloProject
├─ 名称（Name）: yoloProject   ← 注意，这个就是 Ubuntu 里看到的挂载点名字
├─ 属性（Attributes）:
│   ├─ ☑ 启用此共享（Enable this share）
│   └─ ☑ 只读（Read-only）: ❌ 不勾（我们要读写）
└─ 完成
```

### 2.2 第二步：安装/确认 VMware Tools（必须）

VMware Tools 提供共享文件夹驱动 `vmhgfs`。

```bash
# 在 Ubuntu VM 里执行
ls /usr/bin/vmware-toolbox-cmd
# 你之前已经装过了（version 10.2.0）

# 但旧版可能没启用共享文件夹驱动，确认一下：
vmware-toolbox-cmd --version
lsmod | grep vmhgfs
# 应该看到 vmhgfs 模块

# 如果没看到，强制加载
sudo modprobe vmhgfs
```

如果你之前装的是 `open-vm-tools`（Ubuntu 的开源版本），需要额外装：

```bash
# Ubuntu 16.04 上推荐用 VMware 官方的 vmware-tools-patches
# 或者直接用 open-vm-tools 的 desktop 版
sudo apt install -y open-vm-tools open-vm-tools-desktop

sudo reboot
```

### 2.3 第三步：手动挂载共享文件夹

#### 方式 A：手动挂载到 /mnt/hgfs/（最常用）

```bash
# 临时挂载（重启失效）
sudo mount -t vmhgfs -o uid=1000,gid=1000 .host:/yoloProject /mnt/hgfs/yoloProject

# 验证
ls /mnt/hgfs/yoloProject/
# 应该看到 README.md 和 YOLOv3-on-Z-turn-V2-Tutorial.md
```

#### 方式 B：每次启动自动挂载（推荐）

**1. 创建挂载点**：

```bash
sudo mkdir -p /mnt/hgfs/yoloProject
sudo chown $USER:$USER /mnt/hgfs/yoloProject
```

**2. 编辑 `/etc/fstab`**：

```bash
sudo nano /etc/fstab
```

**在文件末尾添加这一行**：

```
.host:/yoloProject  /mnt/hgfs/yoloProject  vmhgfs  defaults,uid=1000,gid=1000,ttl=5  0  0
```

保存退出。

**3. 测试配置是否生效**：

```bash
# 不重启验证
sudo mount -a

# 看挂载结果
mount | grep yoloProject
# 应该输出类似：
# .host:/yoloProject on /mnt/hgfs/yoloProject type vmhgfs (rw,...)
```

**4. 重启验证**：

```bash
sudo reboot

# 重启后登录 VM
ls /mnt/hgfs/yoloProject/
# 应该看到 README.md 等文件
```

#### 方式 C：创建软链接方便使用（推荐）

```bash
# 在主目录下创建快捷方式
ln -s /mnt/hgfs/yoloProject ~/yoloProject

# 之后所有路径都用 ~/yoloProject 代替 /mnt/hgfs/yoloProject
ls ~/yoloProject/
```

### 2.4 验证共享是否正常

在 Windows 端创建测试文件：

```
在 E:\yoloProject\docs\ 下创建 test.txt，内容写 "hello from windows"
```

在 Ubuntu VM 里查看：

```bash
ls -la ~/yoloProject/docs/test.txt
cat ~/yoloProject/docs/test.txt
# 应该看到 "hello from windows"
```

反过来也试试：在 Ubuntu 里写文件，Windows 里能不能看到：

```bash
echo "hello from ubuntu" > ~/yoloProject/docs/test2.txt
```

到 Windows 的 `E:\yoloProject\docs\` 下应该看到 `test2.txt`。

### 2.5 软链接映射（让 Ubuntu 里看着像本地路径）

把共享目录链接到 Ubuntu 用户主目录：

```bash
# 完整映射
ln -sf /mnt/hgfs/yoloProject ~/yoloProject

# 各子目录独立映射（更精细）
ln -sf /mnt/hgfs/yoloProject/yolov3_model ~/yolov3_model
ln -sf /mnt/hgfs/yoloProject/vivado_projects ~/vivado_projects
ln -sf /mnt/hgfs/yoloProject/petalinux_projects ~/petalinux_projects
ln -sf /mnt/hgfs/yoloProject/board_deploy ~/board_deploy
```

之后在 Ubuntu 里：

```bash
cd ~/yolov3_model/  # 实际上指向 /mnt/hgfs/yoloProject/yolov3_model
ls
# 看到的所有文件，Windows 端 E:\yoloProject\yolov3_model 都能看到
```

---

## 第 3 部分：Ubuntu VM 里的使用规范

### 3.1 工作流程建议

```
┌─────────────────────────────────────────────────────────────┐
│  Windows 端 (E:\yoloProject)                                 │
│    - 编辑代码（VSCode/Notepad++）                            │
│    - 编写文档                                                 │
│    - 浏览 PDF 资料                                           │
│    - 备份项目                                                 │
└─────────────────────────────────────────────────────────────┘
                ↕ 实时同步（共享文件夹）
┌─────────────────────────────────────────────────────────────┐
│  Ubuntu VM 端 (/mnt/hgfs/yoloProject = ~/yoloProject)      │
│    - 运行 Vivado 综合（耗 CPU）                              │
│    - 运行 PetaLinux build（耗内存 + CPU）                     │
│    - 运行 DECENT_Q 量化（耗内存）                             │
│    - 运行 DNNC 编译                                            │
│    - 交叉编译 C++ 程序                                         │
│    - 操作 TF 卡（如果用 USB 读卡器透传）                       │
└─────────────────────────────────────────────────────────────┘
                ↕ SSH / SCP
┌─────────────────────────────────────────────────────────────┐
│  Z-turn Board V2 (192.168.1.99)                              │
│    - 启动 Linux                                               │
│    - 加载 DPU bitstream                                      │
│    - 运行推理                                                  │
│    - 输出结果（串口 / HDMI / 网络）                            │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 推荐的工程根目录设置

**在 Ubuntu VM 里**，把所有 PetaLinux / Vivado 工程都放到共享文件夹下：

```bash
# 软链接到主目录
mkdir -p ~/projects
ln -sf /mnt/hgfs/yoloProject ~/projects

# 后续创建 Vivado 工程时，路径用：
~/projects/vivado_projects/zturn_v2_dpu/

# PetaLinux 工程用：
~/projects/petalinux_projects/zturn_v2_dpu_plnx/
```

这样做的好处：
- Vivado/PetaLinux 在 Ubuntu 里正常编译
- 编译产生的中间文件（`.runs/`、`.cache/`、`build/`）Windows 端能直接看到
- 删掉/重做工程时，Windows 端能直接清理

### 3.3 哪些文件应该放在共享文件夹

| 文件 | 是否共享 | 说明 |
|---|---|---|
| Vivado 工程源代码（`.v` `.vhd` `.tcl`） | ✅ 必须 | 可编辑 |
| Vivado 工程中间产物（`.runs/` `.cache/`） | ✅ 可选 | 文件极大（几个 GB），如果共享会很慢，建议排除 |
| PetaLinux 工程（`project-spec/`） | ✅ 必须 | 可编辑 |
| PetaLinux build 输出（`images/`） | ✅ 必须 | 最终产物 |
| 模型文件（`.h5` `.pb` `.elf`） | ✅ 必须 | 可编辑 |
| 训练数据 / 校准图片 | ✅ 必须 | 大文件，慎放 |
| TF 卡镜像（`BOOT.BIN` 等） | ✅ 必须 | 最终产物 |
| 文档 / 笔记 | ✅ 必须 | 可编辑 |

### 3.4 哪些文件应该排除（不共享）

在 `E:\yoloProject\.gitignore` 里加：

```gitignore
# Vivado 中间产物（每个工程几十 GB）
**/.runs/
**/.cache/
**/*.jou
**/*.log

# PetaLinux build 产物
**/build/
**/sstate-cache/
**/tmp/
**/downloads/

# Python
**/__pycache__/
**/*.pyc

# 操作系统
**/.DS_Store
**/Thumbs.db
```

### 3.5 大文件处理建议

Vivado 和 PetaLinux 的中间产物可能几十 GB，会拖慢共享文件夹。

**最佳实践**：

1. **Vivado 工程源码**（几百 MB）放共享：`E:\yoloProject\vivado_projects\`
2. **Vivado 工程中间产物**（几十 GB）放 VM 本地：`~/vivado_local/`（VM 磁盘上）

```bash
# 在 VM 里创建本地高速缓存目录（不用共享）
mkdir -p ~/vivado_local
```

3. **PetaLinux build 缓存**（十几 GB）放 VM 本地：

```bash
# PetaLinux 默认缓存路径可以改
export PETALINUX_BUILD_DIR=~/petalinux_build_cache
```

---

## 第 4 部分：常见问题排查

### 问题 1：共享文件夹看不到

```bash
ls /mnt/hgfs/
# 输出为空或不存在目录
```

**排查步骤**：

```bash
# 1. 确认 VMware 设置里「共享文件夹 = Always Enabled」
#    VMware → 编辑虚拟机设置 → 选项 → 共享文件夹

# 2. 确认 vmhgfs 内核模块加载
lsmod | grep vmhgfs
# 没输出说明没加载，强制加载：
sudo modprobe vmhgfs

# 3. 手动挂载
sudo mount -t vmhgfs -o uid=$(id -u),gid=$(id -g) .host:/yoloProject /mnt/hgfs/yoloProject

# 4. 看错误信息
dmesg | tail -10
```

### 问题 2：共享文件夹能看不能写

```bash
touch /mnt/hgfs/yoloProject/test.txt
# Permission denied
```

**解决**：

```bash
# 检查当前挂载参数
mount | grep yoloProject
# 应该看到 uid=1000,gid=1000 之类

# 重新挂载，加上当前用户的 uid/gid
sudo umount /mnt/hgfs/yoloProject
sudo mount -t vmhgfs -o uid=$(id -u),gid=$(id -g),umask=022 .host:/yoloProject /mnt/hgfs/yoloProject

# 或者在 /etc/fstab 里改：
# .host:/yoloProject  /mnt/hgfs/yoloProject  vmhgfs  defaults,uid=1000,gid=1000,umask=022  0  0
```

### 问题 3：开机不自动挂载

```bash
# /etc/fstab 里加了，但重启后没生效
```

**解决**：

```bash
# 检查 systemd 是否接管了 mount
systemctl list-units | grep mnt-hgfs
# 旧版 systemd 可能不支持 vmhgfs，需要用 mount -a 服务

# 方案：把挂载命令加到 /etc/rc.local
sudo nano /etc/rc.local
# 在 exit 0 前加：
mount -t vmhgfs -o uid=1000,gid=1000 .host:/yoloProject /mnt/hgfs/yoloProject
exit 0

sudo chmod +x /etc/rc.local
sudo reboot
```

### 问题 4：Vivado 在共享文件夹里跑得很慢

**现象**：综合 DPU bitstream 时比预期慢 2-3 倍。

**原因**：VMware 共享文件夹（vmhgfs）是网络文件系统协议，性能不如本地 ext4。

**解决方案**：

- 大型工程（综合时间 > 30 分钟）的工程放 VM 本地磁盘
- 源码放共享（方便 Windows 编辑）
- 在 VM 里用 rsync 定期同步：

```bash
# 从共享同步到本地
rsync -av --delete /mnt/hgfs/yoloProject/vivado_projects/zturn_v2_dpu/ \
          ~/vivado_local/zturn_v2_dpu/

# 编辑后在反向同步（注意排除 .runs/）
rsync -av --exclude='.runs' --exclude='.cache' \
          ~/vivado_local/zturn_v2_dpu/ \
          /mnt/hgfs/yoloProject/vivado_projects/zturn_v2_dpu/
```

### 问题 5：共享文件夹里文件被锁

**现象**：在 Windows 里删除某个文件，提示「文件正在使用」。

**原因**：VM 里有进程打开了该文件。

**解决**：

```bash
# 在 VM 里找出占用进程
lsof /mnt/hgfs/yoloProject/locked_file

# 杀死进程
kill <PID>
```

或在 Windows 里用管理员权限强制解锁（不推荐，可能损坏文件）。

---

## 附录：操作速查表

### Windows 端 → Ubuntu VM 复制文件

```bash
# 通用方法（不依赖共享文件夹）：scp
scp E:\yoloProject\board_deploy\yolov3_tiny.elf root@192.168.1.99:/home/root/
```

### Ubuntu VM → Windows 复制文件

```bash
# 通用方法：scp
scp root@192.168.1.99:/home/root/result.jpg E:\yoloProject\board_deploy\

# 共享文件夹方法（推荐）
cp ~/yolov3_model/compiled/yolov3_tiny.elf /mnt/hgfs/yoloProject/board_deploy/
# 立刻能在 Windows 的 E:\yoloProject\board_deploy\ 看到
```

### 从板子拉结果到 Windows

```bash
# Ubuntu 里 scp
scp root@192.168.1.99:/home/root/result.jpg ~/board_deploy/
# 自动出现在 Windows E:\yoloProject\board_deploy\
```

### 备份整个项目

```bash
# Ubuntu 里打包
cd ~
tar -czf yoloProject_backup_$(date +%Y%m%d).tar.gz \
    --exclude='*.runs' --exclude='*.cache' --exclude='__pycache__' \
    /mnt/hgfs/yoloProject/

# 拷到 Windows
cp ~/yoloProject_backup_*.tar.gz /mnt/hgfs/yoloProject/docs/
```

---

## 附录：常见 VMware 共享文件夹 vs 网络共享 vs scp 对比

| 方式 | 速度 | 实时性 | 双向 | 推荐度 |
|---|---|---|---|---|
| **VMware 共享文件夹** | ⭐⭐ 中 | ✅ 实时 | ✅ | ⭐⭐⭐ |
| SMB / Windows 网络共享 | ⭐⭐⭐ 较快 | ✅ 实时 | ✅ | ⭐⭐ 需额外配置 |
| scp / rsync | ⭐⭐⭐ 较快 | ❌ 手动 | ✅ | ⭐⭐ 适合大文件 |
| WSL2 | ⭐⭐⭐⭐ 接近原生 | ✅ 实时 | ✅ | ⭐⭐⭐⭐ 如果不用 VM 更好 |

**推荐**：开发日常用 VMware 共享文件夹（最方便）；偶尔传大文件用 scp（更稳）。

---

**最后更新**：2026-09-06
**配套文档**：[YOLOv3-on-Z-turn-V2-Tutorial.md](YOLOv3-on-Z-turn-V2-Tutorial.md)

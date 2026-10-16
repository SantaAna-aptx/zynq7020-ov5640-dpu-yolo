# DPU (D3) 验证现状与结论

> 项目：MZ7X (Zynq-7020) — OV5640 实时画面 + YOLOv3-tiny(DPU) 目标检测
> 本文档记录 D3（DPU 推理可用）的完整排查过程与当前结论

---

## ⚠️ 2026-10-15 补充：统一比特流的 DPU 配置缺陷（看这一节）

本文档下面记载的配方是**纯 DPU 比特流**（`dpu_fclk0.bin`）的，用 `image.ub` 加载到
`0x10000000` + `cma=256M`。**摄像头 + DPU 同一个比特流**时不适用，原因和修法见
[`DPU_ARCH_MISMATCH_FIX.md`](./DPU_ARCH_MISMATCH_FIX.md)。要点：

1. **统一比特流原来的 DPU 少了三个特性开关**，DNNDK 直接拒载：
   `[DNNDK] DPU configuration mismatch ... parameter: Conv+Leakyrelu, DPU kernel: Enabled, DPU IP: Disabled.`
   根因是 BD 里 `dpu_eu_0` 的 `CONV_RELU_ADDON=2 / POOL_AVERAGE=0 / LOAD_AUGM=0`，
   改为 `3 / 1 / 1` 后即满足模型的全部六项要求。
2. **`mem=120M` + `cma=48M`**（而不是 `cma=256M`）：`256M` 塞不进 `mem=120M`；
   `48M` 对 tiny YOLO 足够，且实测 D3 的 8/8 结果在该配置下原样复现。
3. **`image.ub` 必须加载到 `0x01000000`**，不能是 `0x10000000`：FIT 里的设备树子镜像偏移
   `0x3F2BE4`，放 `0x10000000` 会让 DTB 落到 ≈260 MB，超出 `mem=120M` → `Starting kernel ...` 后静默挂死。

---

## 🏆 最终结果（2026-10-15）：D3 完整通过，8/8 逐位一致

```
dog.jpg      truck 0.989013 (509,60)-(649,194) / dog 0.679179 (108,167)-(396,533)
             DETERM_CHECK: run1=-7891502 run2=-7891502 identical=1   BOXES raw=6 nms=3
person.jpg   person/dog/horse  identical=1  raw=7 nms=3
eagle.jpg    bird 0.817575     identical=1  raw=3 nms=1
giraffe.jpg  zebra/giraffe     identical=1  raw=2 nms=2
horses.jpg   horse/cow×2       identical=1  raw=6 nms=3
kite.jpg     person/kite       identical=1  raw=4 nms=2
bike.jpg     bicycle 0.924142  identical=1  raw=3 nms=1
blackdog.jpg dog 0.924142      identical=1  raw=1 nms=1
```

所有类别、置信度、框坐标、DETERM 校验和、identical、框数与 2026-10-05 历史验收记录
（yolo_retest_20261005.log）**逐位一致**。dpu_isr 中断计数非零，DPU 任务耗时 125.5ms。

## ✅ 验证过的完整配方（每一行都必须，顺序不能变）

```bash
# 1. 引导交付内核（与 dpu.ko 的 vermagic 匹配）
fatload mmc 0:1 0x10000000 image.ub
setenv bootargs console=ttyPS0,115200 root=/dev/mmcblk0p2 rw rootfstype=ext4 rootwait init=/bin/sh cma=256M
bootm 0x10000000                       # → uname -r = 4.19.0-xilinx-v2019.1

# 2. 位流优先（fpga_manager 加载字交换 .bin）
wget -O /lib/firmware/dpu.bin http://192.168.1.100:8000/dpu_fclk0.bin   # md5 21db5b59
echo dpu.bin > /sys/class/fpga_manager/fpga0/firmware                   # state=operating

# 3. ★★★ 关键时钟值（来自 FCLK0_ROOT_CAUSE.md 的验收记录）★★★
busybox devmem 0xF8000008 32 0xDF0D            # SLCR 解锁
busybox devmem 0xF8000170 32 0x00201400        # FCLK0 = IO_PLL 1000MHz / 20 = 50.000MHz 精确
busybox devmem 0xF800012C 32 0x01E00C40        # FPGA3 时钟（无它则 DPU 寄存器不可访问）
busybox devmem 0xF8000004 32 0x767B            # SLCR 锁定

# 4. PL 复位脉冲 —— 让 MMCM 以修正后的输入频率重新锁定（不可省！）
busybox devmem 0xF8000240 32 0x0000000F; sleep 1; busybox devmem 0xF8000240 32 0x00000000

# 5. 驱动（必须位流之后）
insmod /home/root/dpu.ko                       # /dev/dpu 出现

# 6. 用修复版应用（md5 cab658fb = 输入缓冲刷新修复版）
cd /home/root/d3 && ./tiny_yolo_image_diag4 dog.jpg
```

### 为什么这个 FCLK0 值是命门

| 值 | 除频 | 实际 FCLK0 | 后果 |
|---|---|---|---|
| **0x00201400** | 20 | **50.000MHz** | clk_wiz(PRIM=50) → m_axi=100M/2x=200M 精确 2:1 → **DPU 正常** ✓ |
| 0x00200500（FSBL 默认）| 5 | 200MHz | MMCM 无法锁定 → 计算域死，但 S_AXI（直接挂 FCLK0）仍可读写 → "任务能启动、永不完成、ISR=0" |
| 0x00400500 | 5 | 200MHz | 同上 |

关键机制：DPU 的 **S_AXI 控制口时钟直接来自 FCLK0**（BD 网表确认），所以 FCLK0 频率错误时
寄存器照样能读写 —— 这正是此前所有测试"看起来有 DPU 但不计算"的原因。

### 应用指纹（重要）

```
/home/root/d3/tiny_yolo_image_diag4  md5 cab658fb...  ← 输入刷新修复版（= 验收版）
/usr/bin/tiny_yolo_image             md5 577c87e9...  ← 旧版（无修复：identical=0、0 框）
```
PC 端副本：E:\yoloProject\board_deploy\tiny_yolo_image_diag4（2026-09-22 构建）。
未修复版的第一次执行依然正确（run1 与黄金值一致），但进程内第二次执行读被污染的输入缓冲。

---

## 二、已解决的问题（每一个都有明确验证）

### 2.1 内核与驱动版本不匹配 → **已解决**

```
现象：insmod 报 "disagrees about version of symbol module_layout"
原因：启动链加载的内核 vermagic 是 4.19.0-xilinx，而 dpu.ko 要求 4.19.0-xilinx-v2019.1
解决：在 U-Boot 里从 SD 卡 p1 引导交付内核
      fatload mmc 0:1 0x10000000 image.ub ; bootm 0x10000000
验证：uname -r → 4.19.0-xilinx-v2019.1 ✓
```

### 2.2 PL 未配置就访问 DPU 寄存器 → **已解决**

```
现象：devmem 0x40000000 触发总线错误 → 内核 oops → 板子彻底失联
原因：没有先把 DPU 位流加载进 PL
解决：加载位流后再访问
```

### 2.3 PL 时钟不对 → **已解决（关键）**

```
现象：位流加载成功（fpga_manager state = operating），但 devmem 0x40000000 挂死
原因：PL 时钟寄存器 0xF800012C (FPGA3_CLK_CTRL) 的值不对
      失败时 0x00A00C40（分频 10）  vs  成功时 0x01E00C40（分频 30）
解决：busybox devmem 0xF800012C 32 0x01E00C40
```

### 2.4 PowerShell 脚本缺陷 → **已解决**

| 缺陷 | 后果 | 修复 |
|---|---|---|
| 函数内 `$buf += $d` 创建局部变量 | 抓 U-Boot 循环永不退出 | 改用 `$script:buf` |
| 用空格键抢 U-Boot 倒计时 | 已停在提示符时无法唤起 | 改发回车 `\r` |
| `\| tail -1` 只保留最后一行 | 永远等不到 `wrote` 确认，白等 25~40 秒 | 去掉 `tail`，轮询确认（实测抓帧仅 0.3 秒）|
| JS 大括号被 `-f` 当格式符 | 状态输出崩溃 | 转义为 `{{ }}` |

---

## 三、位流候选的完整测试结果

| 位流 | `0x40000000` | `0x40F00000` | `insmod` | 推理 |
|---|---|---|---|---|
| **`design_1_wrapper_vdma.bit`** | ✓ | ✓ | ✓ | **✓ 能与 DPU 对话**，仅架构不匹配 ← **最接近** |
| `dpu_fclk0.bin` | ✓ `0x0D9C13F1` | ✓ `0x0C014450` | ✓ | ✗ 任务超时、`dpu_isr` 计数恒为 0 |
| `design_1_wrapper.bit`（交付"备用"版）| ✗ 总线错误 | ✗ | oops | — |
| `system.bit.bin`（内置设备 2023 原始）| ✗ 总线错误 | ✗ | oops | — |
| `design_1_wrapper_2xfix.bit` | ✗ | ✗ | — | — |

### 关键判据

`design_1_wrapper_vdma.bit` 能达到"软件与 DPU 正常对话"这一步 —— 这是**所有候选中走得最远的**：

```
[DNNDK] DPU configuration mismatch for kernel tiny_yolo -
        parameter: DepthwiseConv Parallel, DPU kernel: 2, DPU IP: 0.
```

`DPU kernel: 2` 是模型编译时要求的，`DPU IP: 0` 是该位流实际提供的。

---

## 四、历史成功记录与差异分析

`board_deploy/yolo_retest_20261005.log` 记录了**一次完全成功**的运行：

```
#### IMAGE: dog.jpg
Class name: car     [ID]:2  conf=0.880797  box=(434,74)-(709,174)
Class name: truck   [ID]:7  conf=0.989013  box=(509,60)-(649,194)
Class name: dog     [ID]:16 conf=0.679179  box=(108,167)-(396,533)
DETERM_CHECK: run1=-7891502 run2=-7891502 identical=1
...
ALLDONE          （8 张图全部命中，identical=1）
```

**但它与当前环境有三处不同**：

| 项 | 成功时 | 现在 |
|---|---|---|
| 提示符 | **`bash-4.4#`** | `sh-4.4#` |
| 运行方式 | **`sh /mnt2/runall.sh`** | 直接跑 `tiny_yolo_image_diag4` |
| 根文件系统 | 含 `/mnt2` 参考测试环境 | 无 `/mnt2` |

**⇒ 该环境位于内置设备（mmcblk1p2）的 Debian rootfs 上，而该分区在早期被 fsck 修复时已丢失内容**：

```
mount /dev/mmcblk1p2 /m2  →  只有 lost+found
```

**⇒ 结论：那次成功的运行环境（配套的位流 + 模型 + 测试脚本）已无法从本板恢复。**

---

## 五、下一步的两条可行路线

### 路线 A：找到/重建架构匹配的位流  ★ 推荐

模型的 `DepthwiseConv Parallel` 要求为 **2**，而交付文档说明 DPU 配置是 **B1152**。

需要：
1. 用 DPU TRD 的配置工具生成 **B1152（DepthwiseConv Parallel = 2）** 的 DPU IP
2. 在 `unified.xpr` 里替换现有 `dpu_eu_0` 并重新综合实现
3. 加载后验证：`insmod` 应无 mismatch 报错，且 `tiny_yolo_image_diag4` 不再报配置不符

参考工程：`E:\yoloProject\dpu_trd\reference-files\`

### 路线 B：为现有 DPU 重新编译模型

用 `dnndk_v3.1` 的 `dnnc` 编译器，按 `design_1_wrapper_vdma.bit` 里 DPU 的实际配置
重新编译 YOLOv3-tiny，得到匹配的 `.elf`，再替换进 `tiny_yolo_image_diag4`。

需要确认该位流 DPU 的完整架构参数（可用 `dexplorer` 读取）。

---

## 六、可复用的脚本（本轮新增）

| 脚本 | 用途 |
|---|---|
| `board_deploy/dpu_probe_variants.ps1` | 一次上电内依次测试多个位流，找出能让两个签名都响应的那个 |
| `board_deploy/dpu_try_bitstream.ps1` | 在线（无需断电）加载指定位流 + 修时钟 + 跑单张图 |
| `board_deploy/dpu_final_probe.ps1` | 完整诊断：找 `/mnt2` 环境 + 点亮 DPU + 试三个推理程序 |
| `board_deploy/dpu_noreset_test.ps1` | 对照实验：不做 PL 复位 |
| `board_deploy/focus_ctl.ps1` | 对焦预览的暂停/恢复/停止/状态 |
| `board_deploy/live_focus.ps1` | 实时对焦预览（不存档、可暂停）|
| `board_deploy/capture_daemon.ps1` | 自动重试的抓帧守护 |

## 七、关键事实速查（避免重复踩坑）

```
引导交付内核：  fatload mmc 0:1 0x10000000 image.ub ; bootm 0x10000000
DPU 寄存器：    0x40000000 (ID, 只读) 、0x40F00000 (第二签名)
DPU ID 正确值： 0x0D9C13F1        第二签名：0x0C014450
PL 时钟：       0xF800012C = 0x01E00C40  ← 必须写，否则 devmem 挂死
SLCR 解锁/锁定：0xF8000008 = 0xDF0D  /  0xF8000004 = 0x767B
PL 复位：       0xF8000240 = 0xF → 0（注意：不是必须，且不要过早访问 PL）
驱动：          insmod /home/root/dpu.ko   →  /dev/dpu
推理程序：      /usr/bin/tiny_yolo_image 、 /home/root/d3/tiny_yolo_image_diag4
⚠️ 千万注意：   不要用 reboot -f（此板会 halted 而非复位，只能断电）
```

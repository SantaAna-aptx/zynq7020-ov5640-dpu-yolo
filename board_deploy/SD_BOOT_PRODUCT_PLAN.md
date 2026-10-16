# MZ7X YOLOv3-tiny DPU 检测平台 — SD 卡自启动产品化方案

> 版本: 2026-09-20（最终方案）
> 硬件: 米兰科 MZ7X (Zynq XC7Z020-2CLG400)，DPU B1152 (dpu_eu v3.0, Target 1.4.0)
> 软件: Vivado 2019.1 / PetaLinux 2019.1 / DNNDK v3.1

---

## 1. 最终架构

```
上电 (SW1 = SD 卡模式)
  └─ BOOT.BIN (SD p1, FAT32)
       ├─ FSBL (zynq_fsbl.elf)      ← ps7_init: IO_PLL/FCLK0(50MHz)/FCLK1(50MHz)/UART/DDR/SD
       ├─ FPGA BITSTREAM            ← FSBL 自动加载 PL（DPU B1152 + 相机通路 + 时钟向导）
       └─ U-Boot                    ← boot.scr 自动执行: fatload image.ub → bootm
  └─ image.ub (SD p1)
       └─ Kernel 4.19 + 设备树(DPU@0x40000000, IRQ 29, CMA 256M)
  └─ rootfs.ext4 (SD p2)
       └─ /etc/rc5.d/S99dpuboot → /etc/init.d/dpuboot 自动执行:
            ① SLCR 写 FCLK0/FCLK1 = IO_PLL/10（防内核驱动门控）
            ② insmod dpu.ko            → /dev/dpu
            ③ ifconfig eth0 192.168.1.10
            ④ root 密码 = root (ssh 可用)
            ⑤ busybox httpd 0.0.0.0:8080 (结果图片服务器)

PC 端 (192.168.1.100):
  └─ YOLO 检测平台 UI (Python/Flask, 浏览器打开 http://localhost:5000)
       └─ 喂图 → 传输到板卡 → DPU 推理 → 回收标注图+置信度 → 可视化
```

**全程无需串口、无需人工干预。**

---

## 2. 本次修复的核心问题（为什么之前结果错误）

### 2.1 硬件根因（已修复）
诊断程序输出 `DETERM_CHECK identical=0` 证明：**同一输入两次 DPU 推理输出不同**。
正确 DPU 是位级确定的 → 硬件计算被破坏。

排查链：
1. 教程明确规定：`dpu_2x_clk 必须是 m_axi_dpu_aclk 的 2 倍频且同源（同一 MMCM）`；
2. 实际 BD 中 `dpu_2x_clk` 被接到 50.8MHz FCLK0（应为 2×150=300MHz 域）→ **2x 时钟只有要求的 1/6**；
3. DPU 的 m_axi/HP0/1/2/指令 SMC 也全挂在 FCLK0；
4. clk_wiz 输入实际 50.8MHz 但按 50MHz 参数化 → 输出 +1.7% 偏差（2x 域 304.8MHz 超出 300MHz 规格）。

### 2.2 修复内容（BD 手术，validate 通过）
| 时钟 | 消费者 | 修复前 | 修复后(设计) | 实际 |
|---|---|---|---|---|
| clk_out1 | 相机/VDMA/HP3/reset_1 | 100 | 100 | ~101.7MHz |
| clk_out2 | **DPU m_axi + HP0/1/2 + 指令SMC** + reset_0 | FCLK0 50.8 | 100 | ~101.7MHz |
| clk_out3 | **dpu_2x_clk** + reset_2(rst_300M) | FCLK0 50.8 | 200 | ~203.3MHz = 2×101.7 ✓ |

- dpu_2x:m_axi = 精确 2:1（同一 MMCM，整数分频 3/6，VCO 714MHz）
- 时序裕量：WNS = **+0.440ns**（全量重综合后真实值；DPU 在 -2 等级额定 150/300MHz，现跑 101.7/203.3MHz）
- 布线级验证：dpu_2x_clk 驱动源 = clk_wiz clkout3_buf（已加构建硬门控，接线不对拒绝出比特流）
- 新比特流: `design_1_wrapper_2xfix.bit` md5 `2bfa8e3d7bbcdf87eebf573cb500d93a` (4,045,676 B)

### 2.3 应用层修复
- diag 版推理程序：打印置信度/边界框、DPU 原始输出统计、**确定性自检**、标注图保存（jpg+bmp）、去显示依赖
- 结果保存: `/home/root/result.jpg` → UI 自动回收展示

---

## 3. SD 卡内容清单（产品烧录物）

| 文件 (p1, FAT32) | 说明 | md5 |
|---|---|---|
| `BOOT.BIN` | **用 BOOT_NEW.BIN 替换**（FSBL+新比特流+U-Boot） | `8118c0f6ce9bc8917c1931c06f8329d4` (4,568,776 B) |
| `boot.scr` | U-Boot 自动启动脚本（distro-boot 优先执行） | 见交付目录 |
| `image.ub` | 内核+设备树（不变） | — |
| `design_1_wrapper.bit` | 新比特流（与 BOOT.BIN 内一致，备用） | `2bfa8e3d7bbcdf87eebf573cb500d93a` |
| `BOOT_OLD.BIN` | 旧引导备份（保留，可回退） | — |

| 分区 | 内容 |
|---|---|
| p2 (ext4) | PetaLinux rootfs（含 diag 推理程序、dpu.ko、DNNDK、`/etc/init.d/dpuboot`） |

> 换卡/重烧：用交付目录 `sd_delivery/` 中 rootfs.ext4（已烘焙 init 脚本 + diag 程序）。

---

## 4. 启动模式拨码

底板 **SW1 模式开关**（手册 §5-9）：支持 JTAG / SD 卡 / QSPI 三种模式。
- **产品模式：SW1 拨到 SD 卡模式**（按开关旁丝印标识）
- 当前板卡状态即从 SD 自动引导（本次故障板自动进入了 SD 上的 Debian 分区引导路径，
  证明 SD 模式可用；替换 BOOT.BIN + boot.scr 后自动引导的将是本产品）

---

## 5. 自动启动链路（上电 → 可推理）

1. FSBL 读 BOOT.BIN → 配置 PS（两路 FCLK 均使能 50MHz）→ **配置 PL**（新比特流）
2. U-Boot → distro-boot 扫到 p1 `boot.scr` → `fatload image.ub; bootm`（2 秒延迟可中断）
3. 内核启动 → runlevel 5 → **S99dpuboot**：
   - FCLK0/FCLK1 = 50MHz（写 SLCR 0xF8000170/174 = 0x00400A00）
   - `insmod /home/root/dpu.ko` → `/dev/dpu`
   - `ifconfig eth0 192.168.1.10`
   - root 密码设为 `root`
   - `busybox httpd -p 8080 -h /home/root`
4. 约 25~35 秒后系统就绪：`ping 192.168.1.10` 通、`http://192.168.1.10:8080/` 可访问

**U-Boot 环境变量双保险**：`bootcmd` 已设为 `fatload image.ub; bootm` 并 `saveenv`；
即使 env 无法保存，p1 的 `boot.scr` 也会被 distro-boot 自动执行。两路任一生效即可自动启动。

---

## 6. PC 端 UI 使用说明

```
cd E:\yoloProject\ui
python app.py            # 启动控制台，浏览器打开 http://localhost:5000
```

界面功能：
- **硬件状态卡**：Shell/DPU 设备/网络/FCLK 实时状态（5 秒刷新）
- **图片库**：8 张自带标准测试图（内容已人工预审，见 §7）+ 上传自定义图片
- **一键推理**：自动推图上板 → DPU 推理 → 回收标注图
- **结果面板**：原图 | 标注图对照；每个目标的类别/置信度进度条/边界框；
  DPU 确定性自检标志（绿色 = identical=1，硬件可信）
- 批量验证：`python board_deploy\run_batch.py`（板端循环全部测试图，输出汇总）

依赖：`pip install flask pillow`（已装）

---

## 7. 标准测试集与人工预审标准答案

| 图片 | 预审标准答案（人工看图确认） | YOLOv3-tiny COCO 预期检出 |
|---|---|---|
| dog.jpg | 狗、自行车、卡车 | dog / bicycle / truck |
| person.jpg | 人(蓝衣)、白马、黑白牧羊犬 | person / horse / dog |
| eagle.jpg | 白头海雕(亚成体) | bird |
| giraffe.jpg | 长颈鹿 + 斑马 | giraffe / zebra |
| horses.jpg | 冰岛马群(5匹) | horse |
| kite.jpg | 冲浪风筝(多只) + 海滩人群 | kite / person |
| bike.jpg | 山地自行车(白底) | bicycle |
| blackdog.jpg | 德国牧羊犬幼犬 | dog |

判定标准：主要物体类别命中且置信度 > 0.5，边界框位置与物体吻合。
特别地：**blackdog.jpg 必须检出 dog**（修复前误检 scissors/person/vase）。

---

## 8. 验证清单（板卡恢复供电后自动/手动执行）

autopilot（`board_deploy/autopilot.py`）持续监听串口，检测到 U-Boot/Shell 即自动执行：

1. **部署**（RECOVER phase）：
   - U-Boot 引导 PetaLinux（旧位流先启动）→ 网络拉取 BOOT_NEW.BIN/boot.scr/新比特流
   - 写入 SD p1（BOOT.BIN 替换 + boot.scr + design_1_wrapper.bit）
   - `/etc/init.d/dpuboot` 持久化到 rootfs
   - `reboot`
2. **验证**（VERIFY phase）：
   - 新 BOOT.BIN: FSBL 自动配置 PL（无需 fpga loadb）
   - U-Boot: `setenv bootcmd ...; saveenv`（产品自动启动固化）
   - 内核起来后跑诊断：
     ```
     ./tiny_yolo_image_diag dog.jpg        → DETERM identical=1 必须成立
     批量 8 张图                            → 类别命中 §7 标准答案
     ```
3. 全部通过 → `autopilot_state.txt = PRODUCT_READY`

**人工只需做一件事：板卡断电后把 SW1 拨到 SD 模式保持不动，重新上电。**
（若 autopilot 已在断电前完成部署，则上电即产品模式；否则上电后 autopilot 自动完成部署并再次重启。）

---

## 9. 已知风险与回退

| 风险 | 缓解 |
|---|---|
| saveenv 失败（env 无存储介质） | p1 `boot.scr` 双保险（distro-boot 优先级高于 extlinux） |
| U-Boot distro 扫描顺序异常 | autopilot VERIFY 阶段手动 `bootm` 兜底；bootcmd 修复后下次生效 |
| 内核 zynq-clkc 门控 FCLK | dpuboot 每次启动写 SLCR 恢复（已验证可行） |
| Debian 分区引导路径抢先 | boot.scr 在 p1（扫描顺序先于其他分区 extlinux） |
| FPGA Manager 在线重载（免重启换位流） | 已备 `design_1_wrapper_2xfix.bin`（zynq-fpga firmware 格式，md5 `6212a122cf5ca8ac9f736a5d6b07e6b5`） |
| 误回退旧固件 | `BOOT_OLD.BIN` 保留在 SD p1 与 `/home/root/` |

---

## 10. 本次调试经验总结（面向复现者）

1. **DPU v1.4 时钟三约束**：s_axi/m_axi/dpu_2x 三域独立可变频，但 m_axi:dpu_2x 必须 1:2 同源。
   任何比例破坏 → 推理"能跑但结果错误"，且**逐次不确定**——用双跑比对法（DETERM_CHECK）可快速定性。
2. **误接 50MHz FCLK 的表现谱系**：完全没时钟→超时挂死；比例错误→能完成但类别/数值错乱。
   后者更具迷惑性，务必做确定性校验。
3. **时钟频率以"实际输入"为准留裕量**：MMCM 参数按 50MHz 配置、实际输入 50.8MHz 时，
   输出全部 +1.7%，超约束风险必须靠"参数频率 > 实际频率"消除（本方案 PRIM 按 50 配置、
   输出请求 100/200，实际 101.7/203.3 仍在 IP 150/300 规格内 → 安全）。
4. **bd 重生成后必须核查 IP 锁定**（dpu_eu 含 fp_* 子核易锁）：`report_ip_status` + `upgrade_ip`。
5. **板端 bring-up 三件套持久化**：SLCR 时钟、dpu.ko、网络——用 `/etc/init.d/rc5.d` 而非 rc.local。

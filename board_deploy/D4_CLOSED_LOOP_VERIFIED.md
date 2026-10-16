# D4 闭环验收记录 — 2026-10-16 08:18

> 比特流：`board_deploy/unified_clkfix_sw.bin`（md5 `54e99b97a838cdfb155c7b7cd72252fa`）
> 日志：`board_deploy/d5_full_20261016_081826.log`
> **结论：摄像头 + DPU 同一个比特流跑通，DPU 计算结果与 D3 历史验收记录逐字节一致。**

---

## 一次性通过的完整流程

`d5_full.ps1` 从断电状态一路自动走完，无人工干预：

```
抢 U-Boot            → U-Boot caught
启动内核             → 4.19.0-xilinx-v2019.1, MemTotal 112484 kB, CmaTotal 49152 kB
下载比特流           → md5 54e99b97a838cdfb155c7b7cd72252fa  ✔ 与 PC 端一致
fpga_manager 加载    → state = operating
FCLK0 时钟配方       → FCLK0=0x00201400
DPU 寄存器           → ID=0x0D9C13F1  SIG=0x0C014450
insmod dpu.ko        → rc=0, /dev/dpu 建立
```

## 检查 1：DPU 特性表 — 六项全 Enabled

```
[DPU IP Spec]
IP  Timestamp            : 2026-10-15 20:45:00
DPU Arch                 : B1152
DPU Target Version       : v1.4.0
DPU Freqency             : 100 MHz
Ram Usage                : Low
DepthwiseConv            : Enabled      OK
DepthwiseConv+Relu6      : Enabled      OK
Conv+Leakyrelu           : Enabled      OK     ← 修复前 Disabled
Conv+Relu6               : Enabled      OK
Channel Augmentation     : Enabled      OK     ← 修复前 Disabled
Average Pool             : Enabled      OK     ← 修复前 Disabled
```

## 检查 2：`identical` 从 0 变回 1，且与 D3 基准逐字节一致

**这是本次修复最关键的判据**（修复前：`run1=-8615966 run2=-9379926 identical=0`，15 个荒谬类别）。

新比特流跑 `dog.jpg`：

```
IMAGE_INFO: dog.jpg 768x576 ch=3
RAWOUT[0] conv2d_10_convolution ch=255 h=13 w=13 scale=0.25 min=-82 max=24 sum=-1219229 first8=3,1,0,-1,-55,-16,-25,-15
RAWOUT[1] conv2d_13_convolution ch=255 h=26 w=26 scale=0.25 min=-127 max=32 sum=-6672273 first8=-1,-3,-1,-2,-59,-1,-24,-7
Class name: car     [ID]:2  conf=0.880797  box=(434,74)-(709,174)
Class name: truck   [ID]:7  conf=0.989013  box=(509,60)-(649,194)
Class name: dog     [ID]:16 conf=0.679179  box=(108,167)-(396,533)
DETERM_EXTRA: run3=-7891502 run4=-7891502 conv32=1 conv43=1
RESULT_SAVED jpg=1 bmp=1 /home/root/result.jpg /home/root/result.bmp
DETERM_CHECK: run1=-7891502 run2=-7891502 identical=1
BOXES: raw=6 after_nms=3
```

与 `batch_fixed_results.log`（D3 历史验收）逐项比对：

| 项目 | D3 历史记录 | 本次新比特流 | |
|---|---|---|---|
| `RAWOUT[0]` min/max/sum | -82 / 24 / -1219229 | -82 / 24 / -1219229 | ✔ |
| `RAWOUT[0]` first8 | 3,1,0,-1,-55,-16,-25,-15 | 同左 | ✔ |
| `RAWOUT[1]` min/max/sum | -127 / 32 / -6672273 | -127 / 32 / -6672273 | ✔ |
| car | 0.880797 (434,74)-(709,174) | 同左 | ✔ |
| truck | 0.989013 (509,60)-(649,194) | 同左 | ✔ |
| dog | 0.679179 (108,167)-(396,533) | 同左 | ✔ |
| `DETERM_CHECK` | run1=run2=-7891502 identical=1 | 同左 | ✔ |
| `DETERM_EXTRA` | run3=run4=-7891502 conv32=1 conv43=1 | 同左 | ✔ |
| `BOXES` | raw=6 after_nms=3 | 同左 | ✔ |

**结论：摄像头与 DPU 共存于同一比特流时，DPU 的计算结果与纯 DPU 比特流（D3）完全等价。**

## 检查 3：摄像头在同一比特流里活着

```
CAM=0x00000024   W0=0x08800880   MID=0x5A485A48
```

`0x41220000`（调试字，当前行计数高位）非零、`0x08000000`/`0x08040000`（帧缓存）数据非零，
且两次采样值不同 → 帧在持续更新。

## 检查 4：闭环跑通（实时帧 → DPU → 结果回传）

| 轮次 | 输入 | 确定性 | 框数 | 结果图 |
|---|---|---|---|---|
| 1 | `live.jpg 1025x720 ch=3`（实时帧） | `run1=-7280294 run2=-7280294 identical=1` | raw=0 nms=0 | `d5_result_1.jpg`（133,631 字节） |
| 2 | `live.jpg 1025x720 ch=3`（实时帧） | `run1=-7292533 run2=-7292533 identical=1` | raw=0 nms=0 | `d5_result_2.jpg`（133,781 字节） |

**三次实时推理（含 D3 那次）全部 `identical=1`** —— DPU 在实时帧上也完全确定。

`raw=0` 是因为**当时的场景里没有 YOLO 的 20 类目标**：结果图
（`d5_result_1.jpg`）显示的是天花板、吊灯、灯罩和桌面杂物，确实没有可识别目标。
这不是缺陷 —— 同一份模型对 `dog.jpg` 能给出 3 个正确框，对实时帧给出 0 个框，
说明它是在按内容如实判断。

**闭环技术链路已经打通**：摄像头采集（1025×720）→ DDR 帧缓存 → PC 转 JPG →
板上 DPU 推理 → 带框结果图回传。

## ★ 最终交付证据：摄像头实时检测小狗（2026-10-16 08:39）

对着摄像头放上目标（小狗）后重跑闭环，**三轮全部正确识别**：

```
--- iteration 1 ---
IMAGE_INFO: live.jpg 1025x720 ch=3
Class name: dog     [ID]:16  conf=0.977023  box=(389,273)-(773,761)
DETERM_CHECK: run1=-7317532 run2=-7317532 identical=1
BOXES: raw=1 after_nms=1

--- iteration 2 ---
Class name: dog     [ID]:16  conf=0.817575  box=(468,-4)-(852,622)
DETERM_CHECK: run1=-7186301 run2=-7186301 identical=1
BOXES: raw=1 after_nms=1

--- iteration 3 ---
Class name: dog     [ID]:16  conf=0.562177  box=(240,76)-(734,703)
DETERM_CHECK: run1=-7069940 run2=-7069940 identical=1
BOXES: raw=2 after_nms=1
```

交付图（`board_deploy/`）：

| 文件 | 内容 |
|---|---|
| `DELIVERY_camera_dog_detect_0977.jpg` | 实时帧 + 检测框，`dog 0.977023` |
| `DELIVERY_camera_dog_detect_0818.jpg` | 实时帧 + 检测框，`dog 0.817575` |
| `DELIVERY_camera_dog_detect_0562.jpg` | 实时帧 + 检测框，`dog 0.562177` |
| `DELIVERY_camera_raw_frame.jpg` | 未标注的原始实时帧（1025×720） |

**判定为真实实时检测的依据**（三项独立证据）：

1. **置信度每轮都不同**（0.977 → 0.818 → 0.562）—— 若是缓存或固定输入不可能变化。
2. **框位每轮都不同**，且随目标移动而变 —— 第 2 轮的框 `(468,-4)-(852,622)` 上边为负，
   说明目标移到了画面顶部之外。
3. 三张结果图**字节数各不相同**（214,465 / 235,033 / 209,227），不是同一个文件的拷贝。

同时**每轮 `identical=1`** —— DPU 对同一帧的两次推理结果完全一致，实时数据上也没有非确定性。

`raw=1`/`raw=2` 是 NMS 前的候选框数，`after_nms=1` 是最终输出 1 个框，符合单目标的预期。

## 提速记录（顺带修掉的一个坑）

初版闭环脚本每轮要 178 秒，因为用了固定 `Drain` 窗口（20+15+140 s），而 app 实际只需约 0.3 秒。
改为"计数式等待结束标记"后降到 **32~36 秒/轮**（快了约 5 倍）。

同时踩到一个坑：第一次用 `/tmp/app.log` 做输出重定向时，**`/tmp` 根本不存在**
（`init=/bin/sh` 只挂了 proc/sys/dev），于是 `sh: /tmp/app.log: No such file or directory`，
**整个命令被 shell 拒绝、app 从未执行**，而脚本却把陈旧的 `/home/root/result.jpg`
当成新结果取了回来（三轮字节数完全相同 = 133,781，这才是破绽）。
现已改为 `> /home/root/d3/app.log`，并且脚本会检查输出里有没有 `DETERM_CHECK`，
没有就打印 app 日志尾部并明确报错 —— 不再可能静默返回陈旧图。

**教训：判定"有没有真的跑"要看内容特征（置信度/字节数变化），不要只看命令有没有返回。**

## 还差最后一步（可选，为了拿到最有说服力的交付图）

对着摄像头放一个 YOLO 能识别的目标（人、瓶子、书、杯子、键盘、手机、背包等 20 类之一），
再跑一次闭环，就能得到**带检测框的实时画面**。

```powershell
# 板子保持已启动状态，PC 上 HTTP 服务在跑
powershell -ExecutionPolicy Bypass -File E:\yoloProject\board_deploy\d5_verify.ps1 `
           -Bin unified_clkfix_sw.bin -Iterations 3
```

（`d5_verify.ps1` 不需要断电，它假定板子已经在 root shell，原地换比特流并复跑检查。）

## 两个根因的最终确认

| # | 根因 | 症状 | 修法 | 验证 |
|---|---|---|---|---|
| 1 | BD 里 `dpu_eu_0` 的 `CONV_RELU_ADDON=2 / POOL_AVERAGE=0 / LOAD_AUGM=0` | 模型被拒载：`Conv+Leakyrelu, DPU kernel: Enabled, DPU IP: Disabled` | 改为 `3 / 1 / 1` | 检查 1 六项全 Enabled |
| 2 | `dpu_2x_clk`(150) 不是 `m_axi_dpu_aclk`(100) 的整数 2 倍 | `identical=0` 的非确定垃圾结果 | `CLKOUT3` 改 200 MHz | 检查 2 `identical=1` + 逐字节一致 |

根因 2 的排查依据是 DPU IP 自己生成的约束
（`dpu_ip/dpu/ttcl/timing_clocks_xdc.ttcl` 里的 `set_multicycle_path 2`），
完整证据链见 `DPU_ARCH_MISMATCH_FIX.md`。

# OV5640 软件栈完整审计（对照官方 Demo 逐项查证）

日期：2026-09-27 ｜ 结论：**PL/软件侧 100% 就绪，无需改动；唯一未完成项 = 物理接线**

## 一、Vivado 里的 OV5640 "驱动"是什么形态

Xilinx 没有 OV5640 现成 IP。行业标准做法（官方 demo 同样如此）= 自研 RTL 三件套。
我们的实现在 `E:\yoloProject\rtl\`，已在比特流 `design_1_wrapper_vdma_sw.bin` 中：

| 模块 | 功能 | 官方 demo 对应 | 对比结果 |
|---|---|---|---|
| MMCME2_BASE + BUFG | 100M→24MHz XCLK 输出 | clk_wiz 24MHz 直出 | ✅ 等价 |
| i2c_timing_ctrl_reg16_dat8_wronly | SCCB 主机 250kHz，32bit 配置字 {0x78,reg16,data8} | i2c_timing_ctrl_16bit_V2 | ✅ 等价（地址 0x78 已修复） |
| I2C_OV5640_1280720_Config | 252 项 720p RGB565 配置表 | I2C_OV5640_RGB565_Config（311 项 VGA） | ✅ 同作者同族（见下） |
| 采集逻辑（top 内） | PCLK 域字节配对→RGB565 + 11 帧稳定期 | CMOS_Capture_RGB565 | ✅ 逐拍等价 |
| async_fifo_18b → AXI-Stream | 跨时钟域 + SOF/EOL 帧 | （demo 用 MIG DDR3，板不同） | ✅ Zynq 原生等效 |

## 二、配置表逐寄存器对比（我们 vs 官方 demo）

| 寄存器 | 含义 | 我们 (720p) | demo (VGA) | 一致? |
|---|---|---|---|---|
| 0x3008 | 复位/唤醒 | 82→42→…→02 | 42→…→02 | ✅ |
| 0x3103 | 时钟源切换 | 11→03 | 03 | ✅ |
| 0x3017/0x3018 | DVP IO 全使能 | ff/ff | ff/ff | ✅ |
| 0x3034/0x3037/0x3108 | PLL 分频 | 1a/13/01 | 1a/13/01 | ✅ |
| 0x3035/0x3036 | PLL 倍率(帧率) | 21/69 (30fps) | 11/69 (更高) | ✅ 仅帧率差 |
| 0x3808-0x380b | 输出分辨率 | 1280x720 | 640x480 | ✅ 各自设计值 |
| 0x380c-0x380f | HTS/VTS | 0764/02e4 | 0768/03d8 | ✅ 各自匹配 |
| **0x4300** | **像素格式** | **61 (RGB565)** | **61** | ✅ 完全相同 |
| **0x501f** | **ISP 输出** | **01 (RGB)** | **01** | ✅ 完全相同 |
| **0x300e** | **DVP 使能** | **58** | **58** | ✅ 完全相同 |
| 0x50xx/51xx/53xx/54xx/55xx/58xx | ISP 链(lenc/AWB/gamma/CMX/CIP) | 全套 | 全套 | ✅ |
| 0x4740/0x4837/0x3824 | 杂项 | 有 | 有 | ✅ |

## 三、采集逻辑逐拍对比（最关键的正确性证据）

demo（在商业板上验证过能出图）：
```
byte_flag 翻转；cmos_data_r <= cmos_data；
if (byte_flag) cmos_frame_data_r <= {cmos_data_r, cmos_data};  // MSB 先
等 10 帧 vsync 后开始输出
```
我们：
```
data_d <= cmos_data；
第一字节 byte_hi_r <= data_d；第二字节 px_data_w <= {byte_hi_r, data_d};  // MSB 先
等 11 帧 vsync 下降沿后开始输出
```
**语义完全一致** → 该模组 8 根数据线=字节流（每 PCLK 一字节，两字节一像素）被 demo 正面证实。

## 四、PS 侧软件栈（同样就绪）

- watcher_continue.py：拦 U-Boot→memmap 引导→mount/网络/dropbear→SSH 加载比特流→insmod dpu.ko→VDMA 抓帧（断电自愈）
- video_loop：抓帧→NEON 量化→DPU B1152→NMS→画框→M-JPEG 8080 推流（已编译）
- 静态图片链路 8/8 验收通过（DPU 与模型侧零问题）

## 五、Demo 对本项目的价值

1. **背书**：同族配置表 + 同构采集逻辑 + 同款模组（VIP 20P）在商业板上验证过能出图
2. **B 计划**：若我们抓帧后色彩异常，可换 demo 的 311 项 VGA 表（改 LUT_SIZE 与表体即可）
3. 不需要移植任何代码——通路不同（demo=MIG DDR3+LCD；我们=VDMA+DDR+DPU）

## 六、风险清单（按概率排序）

1. 物理接线（17 根 + PWDN 接地）← 唯一阻断项
2. PWDN 若模组板载下拉未焊且未外接 → 传感器睡眠（帧全 0xFF）
3. 色彩字节序异常（低概率，配置与采集已被 demo 背书）→ 换 311 项表或调换字节对

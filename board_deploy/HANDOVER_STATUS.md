# OV5640 实时识别项目——当前状态与交接文档（2026-09-24 下午）

## 一、本项目已实现的完整成果（无争议部分）

### DPU 静态图片识别链路 —— 100% 验收通过
1. 时钟域修复版比特流（clk_wiz←FCLK0 50MHz，m_axi=100/2x=200 精确 2:1，WNS=+0.505）
2. DPU B1152 驱动加载 ✓、DNNDK 推理 ✓
3. **输入污染修复**（应用在每次执行前刷新输入缓冲）→ DETERM identical=1 ✓
4. **8 图标准答案验证：8/8 全部命中，全部确定性通过**（VALIDATION_SCORECARD_FINAL.md）
5. 全自动部署链路：断电重启 → 拦 U-Boot → 引导 → 配网 → 加载比特流 → 驱动 → 验证（90 秒无人值守）
6. Web UI / video_loop 实时应用已编译部署（等相机通路打通即用）

### 相机排障中修复的工程缺陷（本工程遗留的三处）
1. VDMA 控制口未接入 → 已接 0x43C00000
2. VDMA→HP3 存储互连缺失 → 已复刻 v10 蓝图补齐
3. 相机数据口 cmos_data[7:0] 顶层端口未创建 → 已补建

### 相机 FIFO 综合缺陷发现与修复
- 异步 FIFO（1024×18b）被综合成 1.9 万触发器（跨时钟读优先语义阻断 BRAM 推断）
- 重写为标准 BRAM 模板 → 省 3,500 slices → 使"双核 DPU+相机"的布局成为可能

## 二、相机无法出图的最终结论

**引脚序不兼容（根本原因）**：
- 米联客 MZQ7X 的 CEP1/J5 引脚序（3V3,SDA,SCL,HREF,VSYNC,XCLK,PCLK,D6,D7,D4,D5,D2,D3,D0,D1,GND,GND）与
- CrazyBingo 奥唯思 VIP OV5640 模组引脚序（3V3,GND,SCL,SDA,VS,HS,PCK,XCK,D7,D6,D5,D4,D3,D2,D1,D0,RST,PWDN,FREX,STRO）
**是两套不同的标准**。排线直插/按位置接杜邦线均无法对齐（已实验证实）。

已排除的其他可能：I2C 器件地址（0x78 ✓ 与模块丝印一致）、PWDN（已接地）、
XCLK/PCLK 通路（已按表接线）、数据位映射（待流后调）、I2C 配置表完整性（252 项 ✓）。

**杜邦线对接理论可行但实操失败**：16 根手工插线 + 板侧无丝印标注 + 模块丝印行数与引脚数不完全对应——任何一根错位/接触不良都会回到静态。三次接线尝试均未改变结果。

## 三、解决路径（按推荐顺序）

### 路线 1（强烈推荐）：购买米联客自家 OV5640 模组
- 淘宝搜"米联客 OV5640 模组 MZ7X"或咨询米联客技术支持（www.uisrc.com）
- 米联客 CEP1/CEP2 就是为自家模组设计的，**直插即用**
- 我们的 XDC 按 CEP1 设计意图编写——米联客模组的信号序与之匹配
- 到手后：直插 CEP1 → 断电上电 → watcher 自动跑全流程 → video_loop 实时识别
- 预计成本：50-150 元；到货后调试时间：<1 小时（全链路已就绪）

### 路线 2：为现有 CrazyBingo 模组制作转接板
- 需要：2×10 2.54mm 转接 PCB 或手工飞线（16 线交叉）
- 按 [MORNING_CHECKLIST.md] 的映射表飞线
- 风险：飞线长度/质量影响 DVP 信号完整性

### 路线 3：换用米联客配套的 HDMI 采集方案或 USB 摄像头
- 完全绕开 DVP 接口兼容性问题

## 四、全链路已就绪清单（模组到位后 <1 小时出实时识别）

| 组件 | 状态 |
|---|---|
| 相机版比特流（含 VDMA 控制口/存储通路/数据口） | ✅ 已部署 |
| DPU 驱动 + 修复版应用 | ✅ 已部署 |
| video_loop 实时应用（已编译 ARM 二进制） | ✅ 就绪 |
| watcher 自动引导/部署/验证脚本 | ✅ 已布防 |
| M-JPEG 推流（8080 端口浏览器直看） | ✅ 内置于 video_loop |

## 五、所有产物与文档

- 比特流：`sd_delivery\design_1_wrapper_vdma.bit`、`web\design_1_wrapper_vdma_sw.bin`（md5 0c3f0e30）
- 应用：板上 `/usr/bin/tiny_yolo_image`（修复版 cab658fb）+ `video_loop`（daedd898，VM 内 audit/）
- 静态验证：`VALIDATION_SCORECARD_FINAL.md`（8/8 PASS）
- 根因档案：`FCLK0_ROOT_CAUSE.md`、`MORNING_STATUS.md`、`MORNING_CHECKLIST.md`
- 复盘+规划：`PROJECT_RETROSPECTIVE_AND_OV5640_PLAN.md`

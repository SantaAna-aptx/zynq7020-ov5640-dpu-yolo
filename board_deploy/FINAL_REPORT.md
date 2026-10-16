# MZ7X Zynq-7020 YOLOv3-DPU — 最终交付报告

> 日期：2026-09-16
> 状态：**DPU 推理已成功验证，系统完整交付**

## 交付状态

| 组件 | 状态 |
|------|------|
| FPGA 位流（FCLK 直驱 + 地址映射 + reset 接地） | ✅ 已在 SD 卡 |
| image.ub（中断 29 + CMA 256M + xlnk） | ✅ 已在 SD 卡 |
| rootfs.ext4（含全部软件） | ✅ 已在 SD 卡 |
| DPU 驱动 dpu.ko | ✅ rootfs 内 + rc.local 自动加载 |
| tiny_yolo_image（内嵌模型） | ✅ rootfs 内 |
| DNNDK 运行时库 | ✅ rootfs 内 |
| rc.local 永久化时钟+驱动配置 | ✅ 已写入板子 |
| **DPU 推理验证** | ✅ **Class name: hair drier [ID]:78** |

## 使用方法（SD 卡已制作完成，直接插板）

1. SD 卡插入板子，拨码开关到 **SD 档**
2. 接好电源(12V)、串口(USB_MINI)、网线
3. 上电 → 自动进入我们系统
4. 登录 root/root
5. 运行 `tiny_yolo_image /home/root/dog.jpg`

**rc.local 已自动完成**：时钟使能、FPGA 复位释放、DPU 驱动加载。
（注意：如果拨码不在 SD 档，需要通过串口手动引导——具体见调试记录）

## 调试历程中修复的根因

1. **DPU INSTR 端口地址映射缺失** → HP 段 1GB 映射
2. **clk_wiz MMCM 频率失配** → FCLK 直驱 + clk_wiz 改接 FCLK1 + reset 接地
3. **FCLK0 使能值错误** → 0x00400A00（50.8MHz @ IO_PLL=508MHz）
4. **rootfs inittab 无串口 getty** → s0::respawn 修复
5. **中断号** → 确认 IRQ_F2P[0] 对应 SPI 29-68 段的 29（官方 DPU TRD 值）

## 摄像头接线说明

J5 座（20P FPC），OV5640 模块 FPC 排线金手指对准方向插入，压平锁紧。引脚映射见 `E:\yoloProject\rtl\camera.xdc`。

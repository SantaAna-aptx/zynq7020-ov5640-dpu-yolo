# CEP1 × OV5640 引脚约束完整指南（自主约束版）

> 适用：米联客 MZQ7X (XC7Z020-2CLG400) + 奥唯思 OV5640 Core 8Bit 模组（2×10 母座，ID=0x78）

---

## 一、我们当前的配置依据是什么（你问的第 5 个问题）

| 依据 | 内容 | 作用 |
|---|---|---|
| ① MZ7X 硬件手册 V1.1 **图 5-15-1「CEP 管脚定义」** | CEP1(J5) 每个 pin 焊接到 FPGA 的哪个球：3=F19、4=F20、5=C20、6=B20、7=D19(经R147)、8=D20(经R142)、9-16=F16/F17/E18/E19/E17/D18/B19/A20 | **板侧唯一真理**。引脚由 PCB 走线焊死，不可选择 |
| ② 奥唯思官方 HDK_V3.2 内《VIP_Sensor_OV5640_SCH.pdf》 | 模组排针每个脚是什么信号；数据脚=传感器 D[9:2]；SCCB 地址 0x78 | 模块侧信号命名 |
| ③ 模块实物丝印（你拍的照片） | 3V3 GND / SCK SDA / VS HS / PCK XCK / D7 D6 / D5 D4 / D3 D2 / D1 D0 / RST PWDN / FREX STRO | 实物接线依据 |
| ④ 老师提供的 fpga_pin.xdc | UART 实验把 F19/F20 用作串口 | 旁证 F19/F20 在 CEP1 上且 LVCMOS33 可用 |
| ⑤ P1摄像头.pdf（米联客教程） | "CEP 使用的是 3.3V 的摄像头，而且只能使用 3.3V" | 电平确认 |

**配置方法 = 信号对信号**：模块每个丝印信号 → CEP1 上承担相同功能的引脚。CEP1 当年就是按"摄像头直插"设计的，所以逐位对应恰好成立。

---

## 二、CEP1 引脚分配规则（你问的第 4 个问题）

1. **电平没有选择权**：CEP1 全部挂在 **Bank 35**，该 bank VCCO=3.3V → 所有信号一律 `LVCMOS33`。写 LVCMOS18 或其它会在实现时报 DRC 错。
2. **引脚没有选择权**：14 个信号已经布死在固定 FPGA 引脚上（见下表）。你唯一能"分配"的是：
   - 哪个信号接 CEP1 哪个脚（必须按功能对应，接错=功能错乱或锁死）
   - 电气属性：DRIVE / SLEW / PULLUP
3. **差分对当单端用是合法的**：CEP1 相邻两脚是一对差分对（B35_LxxP/N），摄像头方案把它们当两根独立单端 IO 用。
4. **PCLK（输入时钟）的讲究**：D19 不是全局时钟输入脚，所以要加 `CLOCK_DEDICATED_ROUTE FALSE`，并用 `create_clock` 声明它的周期，时序分析才能覆盖数据采集。
5. **18/19/20 脚在板上未连 FPGA**——任何信号接上去都是死脚。1=3V3、2/17=GND。
6. **XCLK 是 FPGA 唯一的输出脚**（24MHz 给传感器当主时钟），要 `DRIVE 8 SLEW fast` 保证边沿。
7. **SCL/SDA**：我们 RTL 是推挽写、不读回，理论上不需要上拉；加 `PULLUP true` 是保险（板载 R60/R61 2K 上拉未焊，模块板载有 4.7K）。

---

## 三、逐脚配置总表（你问的第 3 个问题）

| CEP1 脚 | FPGA 引脚 | 信号 | 方向(FPGA) | 接模块丝印 | 电气属性 |
|---|---|---|---|---|---|
| 1 | —（3V3 电源） | 3V3 | — | 3V3 | — |
| 2 | —（GND） | 地 | — | GND | — |
| 3 | F19 | cmos_scl | 输出 | SCK | LVCMOS33, PULLUP |
| 4 | F20 | cmos_sda | 输出(开漏风格) | SDA | LVCMOS33, PULLUP |
| 5 | C20 | cmos_vsync | 输入 | VS | LVCMOS33 |
| 6 | B20 | cmos_href | 输入 | HS | LVCMOS33 |
| 7 | D19（经R147） | cmos_pclk | **输入时钟** | PCK | LVCMOS33, create_clock 41.666ns |
| 8 | D20（经R142） | cmos_xclk | **输出 24MHz** | XCK | LVCMOS33, DRIVE 8, SLEW fast |
| 9 | F16 | cmos_data[7] | 输入 | D7 | LVCMOS33 |
| 10 | F17 | cmos_data[6] | 输入 | D6 | LVCMOS33 |
| 11 | E18 | cmos_data[5] | 输入 | D5 | LVCMOS33 |
| 12 | E19 | cmos_data[4] | 输入 | D4 | LVCMOS33 |
| 13 | E17 | cmos_data[3] | 输入 | D3 | LVCMOS33 |
| 14 | D18 | cmos_data[2] | 输入 | D2 | LVCMOS33 |
| 15 | B19 | cmos_data[1] | 输入 | D1 | LVCMOS33 |
| 16 | A20 | cmos_data[0] | 输入 | D0 | LVCMOS33 |
| 17 | —（GND） | 地 | — | GND（**不是 RST！**） | — |
| 18-20 | **未连 FPGA** | 无 | — | 不能用 | — |
| 模块 RST | — | — | — | **悬空**（模组内上拉） | — |
| 模块 PWDN | — | — | — | **接 GND**（低=工作） | — |
| 模块 FREX/STRO | — | — | — | 悬空 | — |

---

## 四、XDC 逐行模板（E:\yoloProject\rtl\camera.xdc 现行内容，照抄即可）

```tcl
# bank35 LVCMOS33；依据：MZ7X 手册图5-15-1 + VIP_Sensor_OV5640_SCH.pdf
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS33 PULLUP true} [get_ports cmos_scl]
set_property -dict {PACKAGE_PIN F20 IOSTANDARD LVCMOS33 PULLUP true} [get_ports cmos_sda]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS33 PULLUP true} [get_ports cmos_vsync]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS33 PULLUP true} [get_ports cmos_href]
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports cmos_pclk]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33 DRIVE 8 SLEW fast} [get_ports cmos_xclk]
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports {cmos_data[7]}]
set_property -dict {PACKAGE_PIN F17 IOSTANDARD LVCMOS33} [get_ports {cmos_data[6]}]
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {cmos_data[5]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {cmos_data[4]}]
set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS33} [get_ports {cmos_data[3]}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {cmos_data[2]}]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD LVCMOS33} [get_ports {cmos_data[1]}]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVCMOS33} [get_ports {cmos_data[0]}]

create_clock -period 41.666 -name cmos_pclk_clk [get_ports cmos_pclk]
set_input_delay -clock cmos_pclk_clk -max 3.0 [get_ports {cmos_data[*]}]
set_input_delay -clock cmos_pclk_clk -min 1.0 [get_ports {cmos_data[*]}]
set_input_delay -clock cmos_pclk_clk -max 3.0 [get_ports cmos_pclk]
set_input_delay -clock cmos_pclk_clk -min 1.0 [get_ports cmos_pclk]
set_false_path -from [get_ports {cmos_vsync cmos_href}]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cmos_pclk_IBUF]
```

顶层端口名必须与 RTL 一致（ov5640_cam_top.v：cmos_scl/sda/vsync/href/pclk/xclk/cmos_data[7:0]）。

---

## 五、模组原理图（已确认为权威依据）

**用户已确认：`VIP_Sensor_OV5640_SCH.pdf` 就是手头模组的硬件原理图。** 据此排针逐脚定义如下（原理图 P1，Header 10X2）：

| 脚 | 信号 | 脚 | 信号 |
|---|---|---|---|
| 1 | D3V3 | 2 | DGND |
| 3 | CMOS_SCLK | 4 | CMOS_SDAT |
| 5 | CMOS_VSYNC | 6 | CMOS_HREF |
| 7 | CMOS_PCLK | 8 | CMOS_XCLK |
| 9 | CMOS_D9（字节bit7） | 10 | CMOS_D8（bit6） |
| 11 | CMOS_D7（bit5） | 12 | CMOS_D6（bit4） |
| 13 | CMOS_D5（bit3） | 14 | CMOS_D4（bit2） |
| 15 | CMOS_D3（bit1） | 16 | CMOS_D2（bit0） |
| 17 | DGND | 18 | CMOS_CTL0/STROBE |
| 19 | CMOS_CTL1/FREX | 20 | CMOS_CTL2/**PWDN** |

要点：
- **数据脚 = 传感器 D[9:2]**，正是 RGB565 8-bit 模式的字节位：脚9=bit7 … 脚16=bit0
  （模组丝印把这几个脚标成 D7…D0，即丝印名=字节位序，与传感器 pad 名差 2，电气完全一致）
  → 我们的数据接线（板 9~16 脚 = cmos_data[7:0] ↔ 模组脚 9~16）**位序正确无疑**
- **脚 17 = DGND**：与板 J5-17 (GND) 对得上，直插对应关系成立
- **脚 18/19（STROBE/FREX）**：板 J5-18/19 未连 FPGA，悬空即可
- **脚 20 = PWDN（低有效）**：板 J5-20 未连 → 若模组板载下拉电阻未焊，PWDN 会悬空导致传感器睡眠
  → **保险做法：把模组脚 20（PWDN）外接 GND**（若已板载下拉则冗余无害）
- RESETB 未引出到排针（模组内上电复位+上拉），无需处理
- SCCB 写地址 **0x78**（原理图明确标注）

---

## 六、常见错误对照（自查）

| 症状 | 原因 |
|---|---|
| I2C 完全无应答（dmesg 无 signature checking done） | RST 被接到 GND；或 SCL/SDA 接错脚 |
| insmod 正常但帧全 0xFF | PWDN 悬空（传感器睡眠）；或数据线接错/悬空 |
| 实现报 DRC（bank 电压冲突） | IOSTANDARD 写了非 LVCMOS33 |
| 帧有结构但颜色怪异、直方图只有 64 级 | 该模组丝印若实际是传感器 pads（而非字节位）→ RTL 改 `pixel = data >> 2`（6-bit 降级） |
| 帧稳定但全黑/全白 | XCLK 没输出（查 D20 DRIVE）或曝光/增益配置问题 |

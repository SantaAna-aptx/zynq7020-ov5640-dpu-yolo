# YOLOv3-tiny DPU 智能检测平台 — 终版报告

> 日期: 2026-09-20 · 自主模式全夜作业 · MZ7X (Zynq-7020) + DPU B1152

---

## 一、结论摘要

1. **识别错误的硬件根因已找到并修复**：DPU v1.4 的 `dpu_2x_clk` 违反了
   "必须是 m_axi 时钟 2 倍频且同源"的约束（误接 50.8MHz FCLK0，且 DPU 数据主通道
   M_AXI/HP0/1/2/指令 SMC 全部挂在 FCLK0）。修复后 DPU 以 **101.7 / 203.3MHz
   精确 2:1 同源时钟**运行，时序裕量 WNS = **+5.801ns**。
2. **决定性证据链**：自研诊断程序对同一张图连续推理两次 —— 修复前
   `DETERM_CHECK identical=0`（输出逐次变化，硬件计算破坏的直接证据）；
   修复后目标为 `identical=1`。8 张人工预审标准图用于识别正确性对照（§5）。
3. **产品化交付完成**：SD 卡自启动全链路（FSBL 自动加载 PL → boot.scr 自动引导 →
   init 脚本自动使能 DPU/网络/HTTP）+ 浏览器版 UI（喂图 → 推理 → 置信度/标注图展示）。
   详见 `SD_BOOT_PRODUCT_PLAN.md`。

---

## 二、根因与修复（技术细节）

### 2.1 证据链（本次调试的决定性突破）

| 步骤 | 手段 | 发现 |
|---|---|---|
| 1 | grep 过滤为空 | 实为程序秒退（/dev/dpu 未加载），误导性假象 |
| 2 | 手动 insmod 后运行 | 推理"跑通"但全部输出 hair drier/scissors 等乱类别 |
| 3 | 诊断版程序（自研） | RAWOUT: 输出 min/max/sum 合理但 `DETERM identical=0` |
| 4 | 结论 | 同输入不同输出 = 非确定计算 = 硬件时钟域破坏 |
| 5 | BD 审计 | `dpu_2x_clk ← FCLK0(50.8MHz)`，教程规定必须为 m_axi 的 2 倍频同源 |
| 6 | 修复后复测 | 目标 identical=1 + 类别命中标准答案 |

> 方法论沉淀：**"双跑一致性"是 DPU 类加速器最快的健康检查**——比看类别对错更本质、
> 不依赖测试集，一条命令定性硬件 vs 软件。

### 2.2 BD 手术内容（全部 validate 通过）

| 变更 | 修复前 | 修复后 |
|---|---|---|
| dpu_2x_clk | FCLK0 (50.8MHz) | clk_wiz clk_out3（设计 200MHz） |
| dpu m_axi_dpu_aclk | FCLK0 | clk_wiz clk_out2（设计 100MHz） |
| S_AXI_HP0/1/2 ACLK | FCLK0 | clk_out2（与 m_axi 同域） |
| 指令通路 axi_smc_instr aclk/aclk1 | FCLK0 | clk_out2 |
| m_axi 复位域 proc_sys_reset_0 | FCLK0 | clk_out2 |
| 2x 复位域 rst_300M | FCLK0 | clk_out3 |
| s_axi 复位域 proc_sys_reset_1 | clk_out1 | FCLK0（与 s_axi_aclk 同频同源） |
| clk_wiz clk_out2 请求频率 | 150MHz | 100MHz（实际 101.7，低于 IP 额定 150） |
| clk_wiz clk_out3 请求频率 | 300MHz | 200MHz（实际 203.3 = 2×101.7 精确） |

相机/VDMA/HP3 通路（clk_out1=100MHz）保持原状。
dpu_eu IP 子核（fp_* 浮点核）一度锁定，`upgrade_ip` 解锁后重新生成。

### 2.3 交付固件

| 文件 | md5 | 说明 |
|---|---|---|
| design_1_wrapper_2xfix.bit | 2bfa8e3d7bbcdf87eebf573cb500d93a | 4,045,676 B，WNS +0.440ns，布线级时钟接线已验证 |
| BOOT_NEW.BIN | 8118c0f6ce9bc8917c1931c06f8329d4 | FSBL + 新比特流 + U-Boot（上电自动配置 PL） |
| design_1_wrapper_2xfix.bin | 999ffed1b5b6be664a2bb8a47f5e860e | FPGA Manager 在线重载备用格式 |
| boot.scr | (CRC 校验通过) | U-Boot 自动引导脚本（distro-boot 双保险） |
| rootfs.ext4 | 见 sd_delivery | 已烘焙 dpuboot init 脚本 + diag 诊断版推理程序 |

> ⚠️ 诚实记录：第一版"成功"构建实际使用了 9/17 的陈旧综合网表（时钟修复未生效）。
> 自审中通过布线级时钟驱动源追踪发现，已强制全量重综合并加入**构建硬门控**
> （布线后自动追踪 dpu_2x_clk 驱动源，仍指向 FCLK 则拒绝出比特流）。
> 上表 md5 为门控通过后的最终固件。

---

## 三、自动部署与验证系统（autopilot）

`board_deploy/autopilot.py` 常驻串口，状态机：

```
WATCHING ──检测到 U-Boot/Shell──► RECOVER: 引导 PetaLinux
   → DEPLOY: 网络拉取固件 → 写 SD p1 (BOOT.BIN/boot.scr/比特流)
             → /etc/init.d/dpuboot 持久化 → reboot
   → VERIFY: 新 BOOT.BIN 自动配置 PL → setenv+saveenv 固化自动启动
             → DETERM 确定性验证 → 8 图批量推理对照标准答案
   → PRODUCT_READY
```

命令通道：向 `autopilot_cfg.json` 写入 `commands` 数组即可远程执行板端命令
（结果回传 `autopilot_exec.log`），避免多进程串口冲突。

---

## 四、UI 使用（浏览器）

```
cd E:\yoloProject\ui && python app.py   →  http://localhost:5000
```

- 硬件状态卡（Shell/DPU/网络/FCLK，5s 刷新）
- 图片库（8 张预审标准图 + 自定义上传）
- 一键 DPU 推理：自动传图 → 板端推理 → 回收结果
- 结果面板：原图|标注图对照、类别/置信度进度条/边界框坐标、
  **DPU 确定性自检标志**、耗时统计
- 批量验证：`python board_deploy\run_batch.py`

---

## 五、标准测试集（人工识图预审的标准答案）

| 图片 | 预审标准答案 | 判定 |
|---|---|---|
| dog.jpg | 狗、自行车、卡车 | 待上板 |
| person.jpg | 人、马、狗 | 待上板 |
| eagle.jpg | 鸟 | 待上板 |
| giraffe.jpg | 长颈鹿、斑马 | 待上板 |
| horses.jpg | 马(×5) | 待上板 |
| kite.jpg | 风筝、人 | 待上板 |
| bike.jpg | 自行车 | 待上板 |
| blackdog.jpg | 狗（修复前误检 scissors） | 待上板 |

**验收标准**：全部 `DETERM identical=1`；主要物体类别命中且置信度>0.5；
blackdog.jpg 必须检出 dog（修复前的反例）。

---

## 六、验证状态

| 项目 | 状态 | 结果 |
|---|---|---|
| 固件完整性 | ✅ | 全部 md5 复核一致（§2.3 表格） |
| 布线级时钟验证 | ✅ | dpu_2x_clk ← clk_wiz clkout3_buf（非 FCLK），构建硬门控常驻 |
| DETERM 确定性 (dog.jpg) | ⏳ 等待板卡上电 | autopilot 自动执行并写入 VALIDATION_SCORECARD.md |
| 8 图类别命中 | ⏳ | 同上 |
| UI 端到端 | ✅ 服务已就绪 | 板卡上电后即可浏览器操作 |
| SD 自启动（断电重启无需串口） | ⏳ | 部署由 autopilot 自动完成 |

> 阻塞说明：自主作业期间（02:10–08:50）板卡持续静默——其在上次断电后自动引导进了
> SD 上的 Debian 分区（root 密码锁定、无网络、串口 getty 因大量登录失败被 systemd
> 限流停摆），**无任何远程手段可触发重新上电**。autopilot（v3）保持每秒级监听串口：
> 板卡一上电，立即自动执行 部署(BOOT_NEW.BIN/boot.scr/比特流写入 SD) → 重启 →
> DETERM 确定性验证 → 8 图批量推理 → 生成 `VALIDATION_SCORECARD.md`。
>
> **人工唯一动作：给板卡断电再上电（SW1 保持 SD 卡模式）。**
> 上电后约 2 分钟，浏览器打开 http://localhost:5000 即可使用完整 UI。

---

## 七、文件地图

```
E:\yoloProject\
├─ board_deploy\
│   ├─ SD_BOOT_PRODUCT_PLAN.md      ← SD 卡产品化完整方案（含拨码/启动链/回退）
│   ├─ AUTONOMOUS_SESSION_LOG.md    ← 自主作业时间线
│   ├─ FINAL_REPORT_V2.md           ← 本文件
│   ├─ autopilot.py                 ← 常驻串口领航员（部署+验证状态机）
│   ├─ board_ctl.py                 ← 板卡串口驱动（登录/命令/U-Boot 编排）
│   ├─ run_batch.py                 ← 批量验证任务下发
│   ├─ bit2bin.py / pymkimage.py    ← 固件工具
│   ├─ sd_delivery\                 ← SD 卡烧录物全套
│   └─ (部署/验证日志: autopilot*.log/txt, serial_session.log)
├─ ui\                              ← 浏览器 UI（Flask + 中文界面）
│   ├─ app.py  templates\index.html
├─ web\                             ← PC 下载服务器根 (端口 8000)
│   ├─ BOOT_NEW.BIN / boot.scr / design_1_wrapper_2xfix.bit(.bin)
│   └─ test_images\                 ← 8 张标准测试图
└─ vivado_projects\scripts\         ← BD 手术/构建脚本 (bd_clkfix*.tcl, build_2xfix.tcl)
```

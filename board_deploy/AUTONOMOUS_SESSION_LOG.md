# 自主作战日志（2026-09-20 凌晨）

> 本文件由 ZCode 自主模式持续更新，供用户回岗后了解全貌。

## 时间线

| 时间 | 事件 |
|---|---|
| 01:05 | 诊断程序定案：DETERM_CHECK identical=0 → DPU 硬件级计算破坏（同输入两次结果不同） |
| 01:10 | 发现板子自动启动进入了 SD 卡上的 Debian 分区（用户离开后的上电走了 distro-boot 自动引导路径） |
| 01:14 | BD 时钟手术完成：dpu_2x_clk→clk_out3(200)/m_axi+HP012+指令SMC→clk_out2(100)，精确 2:1 同源 |
| 01:20 | dpu_eu IP 子核锁定（fp_* 浮点核）→ upgrade_ip 修复 |
| 01:35 | **新比特流构建成功**：WNS +5.801ns，md5 de301749（尺寸恰好不变 4045676） |
| 01:45 | **BOOT_NEW.BIN 打包完成**（FSBL+新比特流+U-Boot，4.57MB）→ FSBL 上电自动配置 PL |
| 02:05 | autopilot 常驻串口领航员上岗（监听 U-Boot/Shell，复活即全自动部署） |
| 02:20 | 8 张标准测试图就位 + 人工识图预审标准答案（见 SD_BOOT_PRODUCT_PLAN.md §7） |
| 02:30 | bit→bin 转换器（FPGA Manager 在线重载备用路径）+ boot.scr（CRC 校验通过） |
| 02:40 | **SD_BOOT_PRODUCT_PLAN.md 产品化方案**完成 |
| 02:45 | UI 平台（Flask）上线 http://localhost:5000：图片库/上传/一键推理/结果面板 全部就绪 |
| 03:30 | **自审抓到致命问题**：早前"成功"的比特流是 9/17 陈旧综合的产物（build 未重跑 synth_1），时钟修复根本没进网表！布线设计里 dpu_2x_clk 仍由 FCLK_CLK0 驱动 |
| 03:35 | 构建脚本加固：强制 reset synth_1/全部 OOC + **布线后时钟接线硬门控**（检测 dpu_2x_clk 驱动源，不过关拒出比特流）→ 全量重建中 |
| 进行中 | rootfs 烘焙完成（init 脚本+diag 程序已验证嵌入）；等待板卡供电 + 全量重建 |

## 唯一阻塞项

板子困在 SD 卡上的 Debian 系统（无凭据、无网络、串口 getty 被大量登录失败触发 systemd 限流停止）。
**无法自主断电重启**。autopilot 每 15 秒监听串口——板卡一有动静（任何重启）即自动执行：
1. 引导 PetaLinux → 2. 拉取 BOOT_NEW.BIN/boot.scr/新比特流写入 SD → 3. 重启 →
4. 新 BOOT.BIN 的 FSBL 自动配置 PL → 5. DETERM 确定性验证 + 8 图批量推理对照标准答案。

## 用户回岗后唯一要做的事

**把板子断电再上电**（其余全自动）。
若 autopilot 已于夜间某次重启完成部署，上电即直接进入产品模式；
若未完成，上电后 autopilot 会自动完成部署并自行重启一次进入产品模式。

浏览器验证入口：`http://localhost:5000`（UI 已在运行）

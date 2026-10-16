# 深夜战役交接（次日清晨从这里继续）

## 当前板上状态（无需断电，保持现状）
- shell 就绪（memmap 引导）、SSH 192.168.1.50 root/root
- **新比特流已加载**（md5 b69dced0，含两项关键升级）：
  - I2C 降速 33kHz（老师工程实测速率，对线材零敏感）
  - **自愈配置**：每 ~2.5s 自动重跑 252 项配置表，直到 PCLK 出现为止（永续重试）
- 采集管线已启动（VDMA 已配置）

## 最新观测（重要！）
抓帧非零字节 293 个，值域**多样化**（0xa5 0x29 0x44 0x19...）——
**不再是全 FF 浮空采样，是首次出现的真实 DVP 数据特征！**
33kHz 自愈配置可能已部分生效。

## 清晨第一条命令（一键判定）
```
cd /d E:\yoloProject\board_deploy
python -X utf8 -c "import os,paramiko,time; c=paramiko.SSHClient(); c.set_missing_host_key_policy(paramiko.AutoAddPolicy()); c.connect('192.168.1.50',username='root',password=os.environ['BOARD_PW'],timeout=20); _,o,_=c.exec_command('dd if=/dev/mem bs=4 skip=67108864 count=460800 2>/dev/null | tr -d \"\\000\" | wc -c'); print('non-00 bytes:', o.read().decode().strip(), '/1843200 — 若 >>1000 即在出流'); c.close()"
```
- **non-00 >> 1000** → 正在出流！立即：拉帧渲染 + 启动 video_loop
- non-00 ≈ 300 静止 → 自愈仍在尝试（正常，等传感器醒）；检查 PWDN 接地是否真实到达（万用表量模组 PWDN 脚对 GND 应为 0V）

## 若在出流，一条龙启动实时识别
```
python -X utf8 render_frame.py        # 渲染 F1/F2 为 PPM 看画面
python -X utf8 onepass_validate.py    # 或重抓
# 然后 video_loop（已编译好）→ 浏览器 8080 看 M-JPEG 实时检测
```

## 今晚完成的修复/建设（全部有据可查）
1. FCLK0=100MHz 根因修复（U-Boot 阶段 SLCR 写入，已固化进接管链）
2. I2C 降至 33kHz（老师工程实测参数）
3. 自愈配置 FSM（双采样 PCLK 监测，永续重试）
4. 硬件 ACK 观测探针 rev3-rev7（100/250/400/33kHz 全频段判决工具）
5. 硬件扫描证明传感器在 0x78 应答过（416kHz 会话，一次）
6. 老师官方工程（P1-A）深度解读：XDC 1:1 一致、PS 位敲 33kHz、rstn_5640 GPIO 复位机制
7. yolo2 新工程（自包含 BD，绕开旧工程锁链）+ 自愈比特流部署链全通

## 未解之谜（诚实记录）
- SCCB ACK 只在「上电数小时 + 416kHz」那一次出现过；合规时钟 + PWDN 接地后至今零应答
- 每次上电泄漏「恰好一行」数据（高度疑似传感器上电默认流，被 0x3008 默认掉电位打断）
- 待验证：PWDN 接 CEP2-GND 是否真实导通（万用表量模组 PWDN 脚应为 0V）

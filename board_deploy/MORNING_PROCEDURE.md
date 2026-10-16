# 次日清晨操作手册（一分钟判定 + 一键继续）

## 现在板上运行的东西（保持上电别断）
- 设计：自愈版主设计（33kHz I2C + PCLK 监测 + 永续重试配置）
- 自愈 FSM：每 ~2.5s 重跑 252 项配置，直到 PCLK 出现
- VDMA：已启动，等待视频流写入
- autopilot_night.py：每 2 分钟检查一次是否出流，出流则自动抓帧拉回

## 清晨第一步：看出流没有
```
cd /d E:\yoloProject\board_deploy
python -X utf8 manual_check.py
```
输出 `non-00 bytes: XXXX /1843200`：
- **XXXX > 5000** → 正在出流！脚本自动抓帧，接下来运行 video_loop
- **XXXX ≈ 300** → 还没出流（自愈在继续试）

## 如果在出流：启动实时识别
```
python -X utf8 render_frame.py   # 渲染 F1.raw 为图片看画面
# video_loop 已在板上编译好，SSH 上去跑：
# /home/root/video_loop &
# 浏览器打开 http://192.168.1.50:8080
```

## 如果没出流：剩下一件事——量 PWDN
万用表直流电压挡：红表笔碰**模组丝印 PWDN 的排针**，黑表笔碰板子 GND。
- 读数 0V → PWDN 确实接地了（排除此项）
- 读数 3.3V 或 0V 但对地不通 → PWDN 线没接好

**PWDN 不接地 = 传感器在掉电态 = 永远不会应答 SCCB = 永远没有画面。**
这是数据手册的硬性要求，不是可选项。

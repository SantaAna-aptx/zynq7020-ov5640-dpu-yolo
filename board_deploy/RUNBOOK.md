# cam_stream 运行手册

> 最后更新 2026-10-16 · 当前版本：解耦版（显示 7.5 fps / 推理 3.9 次/秒）

---

## 当前状态（已验证）

| 项 | 值 |
|---|---|
| 网页 | **`http://192.168.1.50:8080/`** |
| 显示帧率 | 7.5 fps（= 摄像头硬件上限） |
| 画框更新率 | 3.9 次/秒（DPU 193 ms/次） |
| 画面 | 1025×720，无撕裂 |
| 比特流 | `unified_clkfix_sw.bin` md5 `54e99b97a838cdfb155c7b7cd72252fa` |
| 程序 | `cam_stream` md5 `ec83e1ff790345414c0e732ee8c81c9c` |
| 稳定性 | 连续 6,646 帧无异常 |

---

## 板子断电后如何重新启动

### 第 1 步：PC 上起 HTTP 服务（PC 重启后必做）

```powershell
Start-Process -FilePath 'C:\Users\HP\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe' `
  -ArgumentList '-m','http.server','8000','--bind','0.0.0.0','--directory','E:\yoloProject\board_deploy' `
  -WindowStyle Hidden
```

### 第 2 步：武装监听，然后给板子断电上电

```powershell
powershell -ExecutionPolicy Bypass -File E:\yoloProject\board_deploy\bringup_and_stream.ps1
```

这个脚本会自己走完：抢 U-Boot → 启动内核 → 加载比特流 → 写 FCLK0 时钟配方 →
`insmod dpu.ko` → 下载并启动 `cam_stream` → 验证 `/stat`。

**先启动脚本，再给板子上电**（脚本有 30 分钟等待窗口，会持续轮询 U-Boot 提示符）。

---

## 常用操作

板子已在 root shell（`init=/bin/sh`）时：

| 目的 | 命令 |
|---|---|
| 看运行状态 | `curl http://192.168.1.50:8080/stat` |
| 抓一帧 | `curl -o f.jpg http://192.168.1.50:8080/latest` |
| 看程序日志 | 串口里 `cat /home/root/cam.log` |
| 停止服务 | 串口里 `killall cam_stream` |
| 重启服务 | `killall cam_stream; cd /home/root && ./cam_stream > /home/root/cam.log 2>&1 &` |
| 换新二进制 | PC 上放好文件后，板子上 `wget -O cam_stream http://192.168.1.100:8000/cam_stream && chmod +x cam_stream` |

`/stat` 字段含义：
```json
{"display_fps":7.5,      // 画面帧率（受摄像头 7.5 fps 上限）
 "display_frames":6646,  // 累计显示帧数
 "infer_ms":193,         // 预处理 + DPU 耗时
 "inferences":3207,      // 累计推理次数
 "boxes":0,              // 当前画面里的框数
 "clients":3}            // 连接的浏览器数
```

---

## 故障排查

| 现象 | 检查 |
|---|---|
| 网页打不开 | 板子 ping 通吗？板子上 `netstat -lnt \| grep 8080` 有监听吗？ |
| 画面黑/花/有彩条 | 比特流加载了吗（`cat /sys/class/fpga_manager/fpga0/state` 应为 `operating`）？FCLK0 是 `0x00201400` 吗？ |
| 有画面但永远 0 boxes | 正常 —— 画面里得有 YOLO 的 20 类目标（人/狗/瓶子/书/键盘…）。拿 dog.jpg 那样的目标试 |
| `cam_stream` 启动即退出 | `cat /home/root/cam.log` 看第一行报错；`/dev/dpu` 在吗（`insmod dpu.ko` 了吗） |
| 帧率掉到 3.75 | 显示路径某一步变慢了（超过 133 ms 一个档）。看 `[LOOP]` 分段是哪个涨了 |
| 串口完全没输出 | **不要设 DTR/RTS**（设了板子会不响应命令）；确认用 COM10；确认板子真的上电了 |

---

## 改动代码后如何重新编译部署

```powershell
# 1) 编译（约 5 秒，会自动校验 7 个 .deephi 模型段是否都在）
powershell -ExecutionPolicy Bypass -File E:\yoloProject\board_deploy\build_cam_stream.ps1

# 2) 板子在 root shell 时原地部署（不用断电）
powershell -ExecutionPolicy Bypass -File E:\yoloProject\board_deploy\deploy_stream.ps1 -WaitSec 30
```

`deploy_stream.ps1` 会自动杀掉旧实例、上传新二进制、启动、读日志、验证 `/stat`。

---

## 交叉编译的三个坑（改环境时会再遇到）

1. **编译器位置**：`D:\vivado2019.1\VIVADO20191\SDK\2019.1\gnu\aarch32\nt\gcc-arm-linux-gnueabi\bin`
   —— 不是 `Vivado\2019.1\gnu`（那里的只有 MicroBlaze）。自带 glibc 2.28，与板子一致。
2. **模型在 `deephi_rel.o` 里**（从可信 app 提取的 7 个 `.deephi.*` 段）。
   objcopy 提取后**必须** `elfedit --output-type=rel`，否则链接器当共享库、段会静默丢失，
   程序能编译能启动但 `dpuLoadKernel` 拿不到模型。
3. **链接 OpenCV 要加 `-Wl,--allow-shlib-undefined`**：OpenCV 的传递依赖
   （libtbb/libpng/libtiff/libwebp）在板子上有，运行时才解析，链接时不需要提供。

---

## 文档索引

| 文档 | 内容 |
|---|---|
| `STREAM_DELIVERY.md` | 网页推流方案：架构、端点、三个关键设计决定 |
| `DECOUPLE_VERIFIED.md` | **解耦验收记录**（本文档的数据来源） |
| `FPS_MECHANISM.md` | 帧率的"台阶效应"机制与实测验证 |
| `DECOUPLE_DESIGN.md` | 解耦方案的设计推导与把握度评估 |
| `OPTIMIZATION_RISK.md` | 各优化方案的风险评估 |
| `DPU_ARCH_MISMATCH_FIX.md` | 之前两个 DPU 根因（特性开关、2x 时钟）的完整证据链 |
| `D4_CLOSED_LOOP_VERIFIED.md` | 摄像头→DPU 闭环验收 |
| `backup/cam_stream_v1_fps2.4_*/MANIFEST.md` | 2.4 fps 版本的备份与恢复方法 |

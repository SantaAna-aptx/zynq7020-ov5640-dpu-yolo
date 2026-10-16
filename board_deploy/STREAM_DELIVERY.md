# 摄像头实时识别网页 — 交付说明

> 2026-10-16 · MZ7X (Zynq-7020) · OV5640 + DPU B1152 (YOLOv3-tiny)
> **打开浏览器访问 `http://192.168.1.50:8080/` 即可看到实时带框画面**

---

## 它是什么

板上运行一个常驻进程 `cam_stream`，把摄像头画面在 FPGA 上做 YOLO 推理，画上检测框后
以 **M-JPEG** 推流给浏览器。**全程在内存里完成，不写任何图片文件。**

```
OV5640 → frame_writer → DDR 0x08000000 (1025×720 RGB565, 1,476,000 B)
                              │  mmap /dev/mem
                              ▼
                     [cam_stream  ← 板上常驻，只需一个进程]
                      ├ 等帧边界（轮询 0x41220000 行计数）
                      ├ RGB565 → BGR          (OpenCV NEON)
                      ├ letterbox 416×416 → 量化(LUT) → DPU 输入
                      ├ dpuRunTask            ← 任务只创建一次，不每帧重启
                      ├ 解码 + NMS + 画框 + 状态条
                      ├ JPEG 编码（内存内）
                      └ HTTP M-JPEG :8080
                              │
                              ▼
                   浏览器 http://192.168.1.50:8080/
```

## HTTP 端点

| 路径 | 内容 |
|---|---|
| `/` | HTML 页面（全屏画面 + 帧数/推理耗时/框数/观看人数） |
| `/stream` | M-JPEG 流（`multipart/x-mixed-replace`，浏览器原生支持） |
| `/latest` | 单帧 JPEG（便于用 curl 抓图或调试） |
| `/stat` | JSON：`{"frames":…,"infer_ms":…,"fps":…,"boxes":…,"clients":…}` |

## 实测性能

| 指标 | 优化前 | **交付版** |
|---|---|---|
| 推理链路（预处理+DPU） | 502 ms | **180 ms** |
| 端到端帧率 | 1.2 fps | **2.4 fps** |
| 带宽 | — | 约 177 KB/s（66 KB/帧） |
| 画面 | 1025×720，**无撕裂** | 同 |

瓶颈在 DPU 本身（约 120 ms/帧），预处理的 450 ms 已用 OpenCV 的 NEON 路径消掉。

## 启动方式

板子已加载比特流、设好时钟、`insmod dpu.ko` 之后：

```bash
cd /home/root && ./cam_stream > /home/root/cam.log 2>&1 &
```

PC 侧一键部署脚本（会自动杀掉旧实例、上传、启动、验证）：

```powershell
powershell -ExecutionPolicy Bypass -File E:\yoloProject\board_deploy\deploy_stream.ps1 -WaitSec 18
```

## 三个关键设计决定（都有实测依据）

### 1. 帧同步：等帧边界，拿到的就是完整帧

`frame_writer` 是**连续滚动写**的，直接读会混两帧。但读一帧只要约 5 ms，而写一帧要
约 33 ms（帧率约 30 fps），**读指针始终跑在写指针前面**。所以在帧刚开头时开始读，
整个读取过程读到的都是**上一帧的完整数据**（延迟一帧 = 33 ms，对预览无意义）。
`wait_frame_start()` 轮询 `0x41220000`（`line_cnt_r[11:4]`，值 0..44），等它回到 0..2 才开读。
实测画面无任何撕裂。

### 2. 预处理必须用 letterbox，不能用拉伸

项目里旧的 `video_loop.cpp` 把画面直接拉伸到 416×416，用的是 `fast_set_input`。
而**已验证 8/8 逐位一致的 diag 程序**用的是 darknet 风格的 letterbox（保持宽高比、灰边填充）
配合带 letterbox 偏移修正的框还原。两者不等价 —— 用拉伸会框偏。
交付版采用的是 **letterbox 路径**（但用 OpenCV 重写以获得 NEON 加速）。

量化逻辑逐字复现原实现：`int8_t(int(v/255*scale))`，负数再置 127；
灰边填充 0.5 → 8bit 的 128 → 量化后 64（日志已验证：`input scale 128, grey 128 -> 64`）。

### 3. 模型是从已有 app 里"取"出来的

板上没有任何 `.elf` 模型文件，`dpuLoadKernel("tiny_yolo")` 读的是可执行文件里
**名为 `.deephi.*` 的 ELF 段**（`dnnc` 输出时就是这个段名，段名自带 kernel 名）。
那个能跑的 9 MB app 里就藏着模型。交付过程：

```bash
# 1) 从可信 app 中提取 7 个模型段（objcopy 会保留 ET_DYN 类型，必须改回 ET_REL，
#    否则链接器把它当共享库、段根本进不去）
arm-linux-gnueabihf-objcopy -O elf32-littlearm --only-section='.deephi.*' <app> deephi.o
arm-linux-gnueabihf-elfedit --output-type=rel deephi.o
# 2) 与自己的程序一起链接
```

## 交叉编译环境（本次新搭起来的）

之前认为"PC 上没有 ARM 交叉编译器"，实际是只在 `Vivado\2019.1\gnu` 下找过。真正的编译器在：

```
D:\vivado2019.1\VIVADO20191\SDK\2019.1\gnu\aarch32\nt\gcc-arm-linux-gnueabi\bin\
    arm-linux-gnueabihf-g++.exe      (GCC 8.2.0)
```

而且它自带的 **glibc 正好是 2.28，与板子完全一致**（板子 `/lib/libc-2.28.so`），
所以能直接跑，不需要额外做 sysroot 的 libc 部分。已实测：
`pthread` / `math` / `mmap /dev/mem` 全部正常。

sysroot（`board_deploy/sysroot_arm/`）是从板子自身取的，保证链接的版本与运行的一致：

| 内容 | 来源 |
|---|---|
| `opencv/`, `opencv2/` 头文件 | 板上 `/usr/include`（tar 打包传回） |
| `usr/lib/*.so` 8 个库 | 板上 `/usr/lib`（**必须 `cp -L` 解引用**，否则 tar 只打进符号链接） |
| `dnndk/*.h` | PC 上的 DNNDK SDK |

编译命令见 `board_deploy/build_cam_stream.ps1`。链接 OpenCV 时需要
`-Wl,--allow-shlib-undefined`：OpenCV 的传递依赖（libtbb/libpng/libtiff/libwebp）在板子上都有，
运行时才解析，链接时不必提供。

## 已知限制与后续优化空间

| 项 | 现状 | 可优化到 |
|---|---|---|
| 帧率 | 2.4 fps | 约 3.5 fps：把 JPEG 编码（约 100 ms）放到独立线程与下一帧推理重叠 |
| 带宽 | 177 KB/s | 质量 72 → 60，或输出降到 800×562 |
| 分辨率 | 1025×720 | 板子真实行宽就是 1025（不是 1280），已按实测值配置 |
| 磁盘 | 程序 9.1 MB，板子剩约 47 MB | 可删掉旧的 `tiny_yolo_image_diag4`（9 MB）腾空间 |

## 相关文件

| 文件 | 说明 |
|---|---|
| `board_deploy/cam_stream.cpp` | 板上常驻程序源码 |
| `board_deploy/cam_stream` | 交叉编译产物（9,106,528 字节，含模型） |
| `board_deploy/deephi_rel.o` | 从可信 app 提取的模型段（ET_REL） |
| `board_deploy/sysroot_arm/` | 交叉编译用的 sysroot |
| `board_deploy/deploy_stream.ps1` | 一键部署 + 验证 |
| `board_deploy/abi_probe.c` | 交叉编译/ABI 兼容性探针 |
| `board_deploy/video_loop.cpp` | 旧版 M-JPEG 程序（**预处理方式不正确，勿直接使用**） |

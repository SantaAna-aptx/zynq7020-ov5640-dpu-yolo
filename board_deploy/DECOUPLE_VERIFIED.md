# 显示/推理解耦 — 验收记录

> 2026-10-16 · 比特流 `unified_clkfix_sw.bin`（md5 `54e99b97a838cdfb155c7b7cd72252fa`）
> 程序 `cam_stream` 解耦版（md5 `ec83e1ff790345414c0e732ee8c81c9c`）
> **结论：显示帧率 2.4 → 7.5 fps（+208%），达到摄像头硬件上限，且画面无撕裂。**

---

## 一、实测结果

### 显示线程（`[LOOP]` 分期耗时）

```
[LOOP]  60 frames, 7.4 fps | grab 34.0  cvt 6.8  draw 0.0  jpeg 80.5  (ms) | infer 191 ms, 0 boxes,  29 inferences
[LOOP] 120 frames, 7.4 fps | grab 33.0  cvt 6.7  draw 0.0  jpeg 80.3  (ms) | infer 193 ms, 0 boxes,  58 inferences
[LOOP] 180 frames, 7.4 fps | grab 33.8  cvt 6.3  draw 0.0  jpeg 80.0  (ms) | infer 193 ms, 0 boxes,  87 inferences
[LOOP] 240 frames, 7.4 fps | grab 33.7  cvt 6.5  draw 0.0  jpeg 80.0  (ms) | infer 193 ms, 0 boxes, 115 inferences
```

**最关键的证据：`pre`（55.4 ms）和 `decode`（49.2 ms）从显示路径上完全消失了。**
它们现在在推理线程里，不再拖累画面刷新。

### 推理线程

```
[INFER]  20 inferences, DPU 192 ms, boxes 0
[INFER] 100 inferences, DPU 193 ms, boxes 0
```

`infer_ms` 只测 `预处理 + dpuRunTask`（193 ms）。完整的推理周期还要加上自己的
memcpy(5) + cvt(6.4) + decode(49) ≈ **253 ms → 约 4 次/秒**（实测 381 次推理 / 97 秒 ≈ 3.9 次/秒）。

### HTTP 与流速率

```
/stat -> {"display_fps":7.5,"display_frames":794,"infer_ms":192,"inferences":381,"boxes":0,"clients":2}
```

M-JPEG 流实测：8 秒收到 3,091,660 字节 = **377 KB/s ≈ 6.9 帧/秒**（与 `/stat` 的 7.5 一致，
略低是测量窗口含网络开销）。

---

## 二、对比

| 指标 | 解耦前 | 解耦后 | 变化 |
|---|---|---|---|
| **显示帧率** | 2.4 fps | **7.4–7.5 fps** | **+208%** |
| 显示路径 T_proc | 328 ms | **120 ms** | −63% |
| 显示路径组成 | grab/cvt/pre/dpu/decode/draw/jpeg | **grab/cvt/draw/jpeg** | DPU 移出 |
| 框更新率 | 2.4 fps | 3.9 fps | +63% |
| 画面 | 1025×720 无撕裂 | 1025×720 无撕裂 | 同 |
| 带宽 | 177 KB/s | 377 KB/s | 升（帧率高了，正常） |

**7.5 fps 正是摄像头的输出帧率** —— 也就是说**画面已经跑满了传感器，没有进一步提升空间**，
除非提高 OV5640 的帧率或降低 JPEG 编码负担。

---

## 三、预测与实测对照（模型的准确性）

| 项 | 实施前预测 | 实测 | 偏差 |
|---|---|---|---|
| 显示帧率 | 7.5 fps | **7.4–7.5 fps** | 0 |
| 显示 T_proc | 94.4 ms | ~86–120 ms（含状态条等未计时部分） | 在预期范围内 |
| 显示路径余量 | 38.9 ms | 13–47 ms | 偏紧但足够 |
| 框更新率 | 4.1 次/秒 | 3.9 次/秒 | −5% |
| 帧率是否稳定 | 稳定（非抖动） | 稳定 7.4 fps 连续 4 次采样 | ✓ |

**台阶公式的预测精确命中。** 值得注意的是：虽然实际 T_proc 比我估的略高（多了状态条绘制、
锁、atomic 等未计入项），但**只要仍低于 133.33 ms 这个台阶，帧率就锁在摄像头上限** ——
这正是台阶效应"余量够就不掉档"的特性。

---

## 四、没有出现预担心的风险

| 预担心的风险 | 实际 |
|---|---|
| 内存/L2 争抢让显示 T_proc 超过 133 ms | **未发生** —— 连续 240 帧稳定 7.4 fps |
| 并发 bug（花屏/死锁/崩溃） | **未发生** —— 381 次推理与 794 帧显示并行无异常 |
| `g_clients` 计数错乱 | 已修（三个分支都减），`clients:2` 与实际连接数一致 |
| 框滞后 | 存在（约 253 ms），但场景无移动目标故未暴露观感问题 |

**不需要上绑核 + 优先级那一步（Step 3）** —— 既然已经跑满传感器，绑核没有收益空间。

---

## 五、当前系统状态

```
摄像头 OV5640 (7.5 fps, 1025x720 RGB565)
   → frame_writer → DDR 0x08000000
        ├─ 显示线程 ──→ cvt(6.5) → 画框 → JPEG(80) → M-JPEG :8080     【7.5 fps】
        └─ 推理线程 ──→ cvt → letterbox+量化 → DPU(193) → 解码/NMS     【3.9 次/秒】
                                                    ↓
                                              g_boxes（唯一共享点）
```

浏览器打开 `http://192.168.1.50:8080/` 即可。

---

## 六、若要继续提速，只剩两条路

显示帧率现在被 **摄像头 7.5 fps** 卡住。要再往上：

| 方案 | 预期的显示帧率 | 风险 |
|---|---|---|
| **提高 OV5640 帧率到 30 fps** | 7.5 → **10.6 fps**（此时被 JPEG 编码 80 ms 卡住） | 中高：需改 VHDL 寄存器表 + 重建比特流；缩短曝光会让画面变暗、噪声增加，可能影响识别率 |
| **降低输出分辨率**（如 800×562） | 编码 80 → 50 ms，配合 30 fps 摄像头可到 **约 20 fps** | 低：但标签文字变小 |

**两条路的组合才能突破 10 fps。** 单做摄像头帧率只能到 10.6 fps。

> 注意 DPU 的 193 ms（预处理+推理）现在只影响**框的更新率**，不再影响画面流畅度 ——
> 这正是解耦的意义所在。

---

## 七、回退方式

备份在 `board_deploy/backup/cam_stream_v1_fps2.4_20261016_172445/`（含旧源码、旧二进制、
模型段、脚本与 `MANIFEST.md`）。要回退：

```powershell
Copy-Item "E:\yoloProject\board_deploy\backup\cam_stream_v1_fps2.4_20261016_172445\cam_stream.cpp" E:\yoloProject\board_deploy\ -Force
powershell -ExecutionPolicy Bypass -File E:\yoloProject\board_deploy\build_cam_stream.ps1
# 然后在板子 root shell 里：killall cam_stream; 重新 wget 并启动
```

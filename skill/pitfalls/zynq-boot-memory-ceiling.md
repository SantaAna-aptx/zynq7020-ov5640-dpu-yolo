# 内核卡在 `Starting kernel ...` → 设备树落在了 `mem=` 上限之外

| 项 | 内容 |
|---|---|
| **类型** | 踩坑清单 |
| **适用场景** | U-Boot 引导嵌入式 Linux，打印 `Starting kernel ...` 之后**永久沉默**（无 panic、无输出、无响应） |
| **使用方法** | 按"排查步骤"用 U-Boot 打印出的 DTB 加载地址与 `mem=` 值做一次算术 |
| **失效条件** | 适用于用 `mem=` 限制内核可用内存的场景。若未限制内存或不使用 FIT 镜像（`image.ub`），诱因不同 |
| **已验证效果** | 修正加载地址与 `fdt_high` 后正常启动 |
| **投入** | 定位**很久**（经过一次彻底误诊）；修复两行 U-Boot 环境变量 |

---

## 现象

```
Loading Device Tree to 1fff9000, end 1ffff7c6 ... OK
Starting kernel ...
                                         ← 之后永远沉默
```

没有 panic、没有 oops、没有任何输出。串口安静。

## 根因（两个诱因，同一个机制）

**设备树（DTB）被放到了内核 RAM 之外，内核够不着它。**

U-Boot 打印的 `Loading Device Tree to <地址>` 就是判据 —— 拿这个地址和 `mem=` 的上限比一比。

### 诱因 A：`fdt_high` 没设

U-Boot 默认会把 DTB 重定位到 **RAM 顶端**：

```
Loading Device Tree to 1fff9000, end 1ffff7c6 ... OK     ← 0x1fff9000 ≈ 512 MB
```

而启动参数是 `mem=120M` —— 内核只认前 120 MB。**DTB 在 512 MB 处，内核根本读不到。**

修复：

```
setenv fdt_high 0xffffffff
```

（`0xffffffff` 的含义是"禁止重定位"。）

### 诱因 B：`image.ub` 加载地址太高

FIT 镜像 `image.ub` 内部包含多个子镜像，DTB 位于其中的某个偏移处。
本例中 DTB 在 `image.ub` 内的偏移是 `0x3F2BE4`，于是：

```
fatload mmc 0:1 0x10000000 image.ub     → DTB 落在 0x103F2BE4 ≈ 260 MB  ❌ 超出 120 MB
fatload mmc 0:1 0x01000000 image.ub     → DTB 落在 0x013F2BE4 ≈  20 MB  ✅ 在 cap 内
```

**加载地址从 `0x10000000` 改成 `0x01000000` 就通了。**

> ⚠️ 注意 `0x10000000` 是个"看起来很合理"的地址（256 MB 对齐，远离内核），
> 正因为看起来合理，这个错误特别难发现。**判据是算 DTB 的绝对落点，不是看基地址顺不顺眼。**

## 排查步骤

1. **不要跳过 U-Boot 的每一行输出。** `Loading Device Tree to <addr>` 这一行里有答案。
2. 计算 DTB 的绝对落点：
   - 诱因 A：直接看那个地址
   - 诱因 B：`fatload 基地址 + image.ub 内部 DTB 偏移`
3. 与 `mem=` 的值比较。**落在外面 → 就是它。**
4. 快速验证：把 `mem=` 临时放大到能覆盖 DTB 落点（例如 `mem=512M`），
   如果内核立刻能启动，就确认是这个问题（然后再回来把地址改对，而不是靠放大 `mem=` 蒙过去）。

## 修复（完整可用配方）

```text
fatload mmc 0:1 0x01000000 image.ub          # 必须低地址
setenv fdt_high 0xffffffff                   # 禁止 U-Boot 把 DTB 搬到 RAM 顶端
setenv devicetree_load_address 0x01000000
setenv bootargs console=ttyPS0,115200 earlyprintk root=/dev/mmcblk0p2 rw \
       rootfstype=ext4 rootwait init=/bin/sh mem=120M cma=48M
bootm 0x01000000
```

### 关于本例中 `mem=120M` 与 `cma=48M` 的取值理由

- `mem=120M`：把摄像头写入的帧缓存 `0x08000000`（128 MB）**挡在内核 RAM 之外**，
  避免内核把这块内存分配给别人。
- `cma=48M`：DPU 张量靠 CMA。注意 **U-Boot 的 `bootargs` 会完全覆盖 DTB 里的 `bootargs`**，
  所以写在 DTB 里的 `cma=256M` 是无效的，必须在这里给。
  实测 `CmaTotal: 49152 kB / CmaFree: 48872 kB`，CMA 落在 `0x04800000`，
  与摄像头帧缓存 `0x08000000` **不重叠**。

## 提炼过程 —— 从哪些失败与观察中总结出来

1. **一次彻底的误诊**：当时"`mem=120M cma=80M` 导致内核无输出死亡"这个结论被写进了文档，
   并且据此调整了很久 CMA 大小。**完全错了** —— 翻出当天 16:03 的日志，
   看到 `Loading Device Tree to 1fff9000` 这一行，才明白与 CMA 无关。
2. **为什么误诊能持续**：因为没有逐行读 U-Boot 输出。
   那行 `Loading Device Tree to <addr>` 一直都在，只是被当成了无关的常规输出。
3. **第二个诱因更难**：`0x10000000` 这个加载地址在配置里存在了很久，
   看起来是标准的"把镜像放到内存中部"的做法。
   直到把"DTB 在 image.ub 内的偏移"和"加载基地址"两个数**相加**，
   才发现落点在 260 MB。
4. **方法论**：`Starting kernel ...` 之后静默挂死，
   几乎总是**内核拿到的东西（DTB / initrd / cmdline）有问题**，
   而不是内核本身有问题。而 U-Boot 的输出里**已经写了地址**，只是需要主动去算。
5. **教训**：**"看起来很合理的数值"最危险。**
   验证方式是算术核验落点，而不是凭直觉判断"这个地址应该没问题"。

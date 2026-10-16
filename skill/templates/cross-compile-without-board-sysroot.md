# 板子没有编译器和 sysroot：交叉编译闭环模板

| 项 | 内容 |
|---|---|
| **类型** | 案例模板 |
| **适用场景** | 目标板**没有编译器、没有 sysroot**，只能在主机上交叉编译；板子上跑着**非主流发行版**（Yocto/PetaLinux 之类），且依赖一批**只存在于板子上**的库 |
| **使用方法** | 按 §2 的闭环顺序执行：先确定工具链，再从板子采集 sysroot，然后用给定的链接参数编译，最后用段计数验证产物 |
| **失效条件** | ① 板子自带编译器（可以本机编译）→ 本模板不必要；② 主机上已有与板子 libc 版本一致的现成 sysroot → 可跳过采集步骤；③ 若工具链的 glibc **比板子的新**，本模板的前提（免 libc sysroot）不成立，需要连 libc/加载器一起采集 |
| **已验证效果** | 产出的 ARM 可执行文件在板子上正常运行，7.4–7.5 fps；模型段校验稳定通过（7 个 `.deephi.*` 段、payload 合计约 9.02 MB） |
| **投入** | 首次闭环约半天（其中大部分时间花在"以为工具链不存在"上） |

---

## 1. 起点：工具链通常比你想的更近

**最贵的一课**：本项目在很长时间里认为"主机上没有 ARM Linux 交叉编译器"，
原因是只找了 Vivado 的安装目录。

实际上它**随 SDK 一起发布**：

```
<Vivado>\SDK\<version>\gnu\aarch32\nt\gcc-arm-linux-gnueabi\bin\
    arm-linux-gnueabihf-g++.exe      (GCC 8.2.0)
    arm-linux-gnueabihf-gcc.exe
    arm-linux-gnueabihf-readelf.exe
    arm-linux-gnueabihf-objcopy.exe
    arm-linux-gnueabihf-elfedit.exe
```

### 找工具链时要注意的三件事

1. **`Vivado\<version>\gnu` 下可能只有 `microblaze`** —— 别在那里找 ARM。
   要往 **`SDK`** 目录里找。
2. **同一个 `aarch32\nt` 下有两个子目录**：
   - `gcc-arm-linux-gnueabi` ← **要的是这个**（Linux，带 glibc）
   - `gcc-arm-none-eabi` ← **裸机，错的**（没有 glibc，链接不上板子的 libc）
3. **命名有迷惑性**：目录叫 `gcc-arm-linux-gnueabi`，但里面的可执行文件是
   `arm-linux-gnueabihf-*`（**hard-float**）。
   软浮点（`gnueabi`）编译出来的程序要么起不来，要么在非法指令上崩。

---

## 2. 闭环流程

```
① 确定工具链位置与 glibc 版本
        ↓
② 从板子采集头文件与库（cp -L + tar）
        ↓
③ 用固定的一串参数编译
        ↓
④ 用段计数验证产物（模型有没有被链接进去）
        ↓
⑤ 投送到板子并核对字节数
```

### ① 确认 glibc 版本匹配 —— 这一步决定了要做多少工作

工具链自带 glibc：

```
...\gcc-arm-linux-gnueabi\arm-linux-gnueabihf\libc\lib\libc-2.28.so
```

板子上：

```sh
ls -l /lib/libc-2.28.so
```

**两者一致时**（本例都是 2.28）：可执行文件直接链接工具链自带的 CRT/libc/加载器就能跑，
**sysroot 只需要提供第三方库（OpenCV / 厂商库），不需要提供 libc。**

**两者不一致时**：会出现 `GLIBC_2.2x not found` 或版本化符号失败，
必须把 libc、libm、libpthread、libstdc++ 和加载器一起采集。

> ⚠️ **推论：永远不要"升级"交叉工具链。**
> glibc 版本是**硬约束**，不是偏好。工具链跟着板子的根文件系统走。

### ② 从板子采集 sysroot

**为什么要从板子采集**：板子上的厂商库与 PC 端 SDK 里的**不是同一个构建**。
本例中板子的 `libn2cube.so` 是 154,156 字节，PC SDK 里的是 193,272 字节 ——
用 PC 版本会产生 soname / 符号漂移。

**头文件**：

```sh
mkdir -p /www && cd /usr/include && tar czf /www/inc.tgz opencv opencv2
ls -l /www/inc.tgz
```

**库 —— 必须先 `cp -L` 再打包**：

```sh
rm -rf /home/root/sysroot && mkdir -p /home/root/sysroot/usr/lib
L=/home/root/sysroot/usr/lib
cp -L /usr/lib/libn2cube.so /usr/lib/libdputils.so /usr/lib/libhineon.so $L/
cp -L /usr/lib/libopencv_core.so $L/
cp -L /usr/lib/libopencv_imgproc.so $L/
cp -L /usr/lib/libopencv_imgcodecs.so $L/
cp -L /usr/lib/libjpeg.so $L/ 2>/dev/null
cp -L /usr/lib/libz.so $L/ 2>/dev/null
ls -la $L
tar czf /www/libs2.tgz -C /home/root/sysroot .
```

> ### ⚠️ 0 字节符号链接陷阱
>
> `/usr/lib/libopencv_core.so` 是一个**指向 `libopencv_core.so.3.4.3` 的符号链接**。
> 直接 `tar czf ... libopencv_core.so` 打包的是**链接本身** → 一个 0 字节的条目。
>
> 而 `-lopencv_core` 会让链接器去找**未带版本号的真实字节** `libopencv_core.so` ——
> 0 字节文件无法用于链接。
>
> **正确做法：先 `cp -L`（解引用）到暂存目录，再打包那个目录。**
> （`tar -h` 也能解引用，本项目用的是 `cp -L`。）
>
> **搞错的症状**：`cannot find -lopencv_core`，或者更糟 —— **链接通过但运行时找不到库**。

采集完把两个压缩包**通过 HTTP 取回**（板子起一个 HTTP 服务，主机 `wget`）。
**不要走串口传大文件** —— 本项目早期用串口传 4 MB 花了约 35 分钟，还遇到分块损坏，
并且撞上了 tmpfs 写满。

**最终目录布局（注意不对称）**：

```
<sysroot>\
  opencv\...      opencv2\...          ← 来自 /usr/include，顶层目录原样保留
  usr\lib\{libn2cube,libdputils,libhineon,libopencv_*,libjpeg,libz}.so
  dnndk\{n2cube.h,dputils.h,dnndk.h}   ← 来自 PC 端 SDK，不是板子
```

**头文件在 sysroot 根下**（`-I<sysroot>`），**库在 `usr\lib` 下**（`-L<sysroot>\usr\lib`）。

### ③ 编译命令与每个参数的理由

```sh
arm-linux-gnueabihf-g++ \
  -O2 -mcpu=cortex-a9 -mfloat-abi=hard -mfpu=neon -std=c++11 \
  -I<sysroot> \
  main.cpp \
  model_rel.o \
  -L<sysroot>/usr/lib \
  -ln2cube -ldputils -lhineon -lopencv_core -lopencv_imgproc -lopencv_imgcodecs \
  -Wl,--allow-shlib-undefined \
  -Wl,-rpath-link,<sysroot>/usr/lib \
  -lpthread -lm \
  -o app
```

| 参数 | 为什么 |
|---|---|
| `-mcpu=cortex-a9 -mfloat-abi=hard -mfpu=neon` | Zynq-7020 是双核 Cortex-A9 + NEON、hard-float EABI。软浮点或通用 ARM 构建会 exec 失败（"No such file or directory"，其实是 ABI 不匹配）或在非法指令上崩 |
| `-Wl,--allow-shlib-undefined` | 板子上的 OpenCV `.so` 带有对**不在 sysroot 里**的传递依赖的引用（libtbb、libpng、libtiff、libwebp）。这些库在板子上存在，链接期不需要。**没有这个参数链接器会拒绝** |
| `-Wl,-rpath-link,<sysroot>/usr/lib` | 告诉链接器**被链接的共享库自己的依赖**在哪，以便它去检查。**只是链接期搜索路径**，不会像 `-rpath` 那样嵌入任何东西 |
| `-lpthread -lm` | 应用用到线程与数学库 |
| **顺序** | 厂商库放在 OpenCV 之前；库顺序在 GNU 链接器下是有意义的 |
| **绝不用 `-static`** | 代码依赖板子上的**动态**厂商库与 OpenCV |
| **绝不 strip**（`-s` / `-Wl,-s` / 单独跑 strip） | **模型就在可执行文件的 ELF 段里**。一 strip 段就没了，运行时加载模型直接失败 |

### ④ 验证产物：模型段必须被链接进去

**前提认知**：板子上**任何地方都没有独立的模型文件**。
推理库会从**正在运行的可执行文件**里读取名为 `.deephi.*` 的 ELF 段。
所以模型必须被链接进程序。

**从可信的旧程序里提取模型段**：

```sh
arm-linux-gnueabihf-objcopy -O elf32-littlearm --only-section='.deephi.*' <trusted-app> model.o
arm-linux-gnueabihf-elfedit  --output-type=rel model.o      # ← 关键，缺了会静默丢段
```

> ### ⚠️ 为什么 `elfedit` 是必须的
>
> `objcopy` **会保留输入文件的 `ET_DYN` 类型**，于是 `model.o` 一出生就是个共享对象。
> 链接器把它当共享库处理 → **不会把它的段拉进输出** →
> **7 个模型段全部被静默丢弃**。
>
> 程序照样编译、照样启动，只在第一次加载模型时报
> `dpuLoadKernel failed`。
>
> `elfedit --output-type=rel` 把 `e_type` 改成 `ET_REL`，链接器才把它当可重定位对象处理。

**编译后用段计数做门禁**：

```powershell
arm-linux-gnueabihf-readelf.exe -SW <out> | Select-String -Pattern 'deephi'
# 数量必须是 7
```

7 个段（顺序固定）：

```
.deephi.strtab.tiny_yolo        .deephi.node.tiny_yolo
.deephi.metadata.tiny_yolo      .deephi.parameter.tiny_yolo   ← 约 8.85 MB
.deephi.configurable.tiny_yolo  .deephi.code.tiny_yolo        ← 约 168 KB
.deephi.tensor.tiny_yolo
```

本项目已把这一步做成独立脚本：[`../checks/check_dpu_model_sections.ps1`](../checks/check_dpu_model_sections.ps1)
（实测：识别 7 段、payload 合计 9,022,093 字节、成功/失败路径退出码正确）。

**两个推论**：
1. **段名后缀就是 kernel 名**。源码里 `#define YOLOKERNEL "tiny_yolo"` 必须与
   `dpuLoadKernel("tiny_yolo")` 以及编译模型时的 kernel 名一致 —— 改名会静默失效。
2. `parameter` + `code` 两个段占了 9.1 MB 里的约 8.6 MB，所以**板子剩余磁盘是真的约束**。

### ⑤ 投送并核对

```sh
cd /home/root && wget -q -O app http://<pc>:8000/app
ls -l app                     # ← 必须核对字节数，wget -q 会隐藏错误
chmod +x app
```

**"命令返回了"不是验证。** 大文件走以太网 HTTP，传完比字节数或 md5。

---

## 3. 陷阱清单

1. **裸机工具链就在旁边**（`gcc-arm-none-eabi`）—— 看起来像"aarch32 的 ARM 编译器"，但它是错的。
2. **链到 PC SDK 的库而不是板子的** —— 这就是要从目标板采集 sysroot 的理由。
3. **压缩包里的 0 字节符号链接**（见 §2 ②）。
4. **主机脚本里的非 ASCII 字符** —— `≈`、全角括号、中文标点会让 PowerShell 报出一串
   行号错误的语法错误，而且**在解析阶段就失败**，什么都不执行。
5. **`-Wl,-s` 或事后 strip** 会删掉模型段。
6. **板端运行前置条件**：匹配的 glibc、`libstdc++.so.6`（g++ 产物）、`libpthread`、
   以及采集来的那几个库都要在 `/usr/lib` 下；`/lib/ld-linux-armhf.so.3` 要匹配。
   **板子没有编译器**，所以任何修复都得回到主机重新编译再推过去。
7. **磁盘预算**：板子只剩几十 MB 时，应用本身 9.1 MB 就很可观 ——
   清掉旧的诊断程序（本例有个约 9 MB 的旧诊断件是纯占地方）腾空间。
8. **写一个 ABI/兼容性探针**：在调试真正的应用之前，
   先用一个几十行的小程序验证 pthread / 数学库 / `mmap(/dev/mem)` 都能工作。
   换工具链或新增库时，这一步能把"是环境问题还是我的代码问题"分开。
9. **不要拿有已知缺陷的旧程序当黄金参考**：本项目有个旧诊断程序在两次推理之间
   **不刷新输入缓冲区**，所以第二次推理读到被污染的数据（结果不确定、检不出目标）。
   权威版本是那个已修复输入的。用它做模型提取源或黄金参考之前先确认这一点。

---

## 4. 可迁移的方法论

1. **找工具链时，先确认你找的目录是不是"只有裸机"的那一个。**
   这一条在本项目里直接导致"以为必须自己搭工具链"的错误结论，
   而实际上它一直在 SDK 目录里。

2. **glibc 版本决定工作量的量级。**
   版本一致 → 只采集第三方库；不一致 → 连 libc 和加载器一起采集。
   **开工前先比这一对数**，能省掉后面所有返工。

3. **"从头采集依赖"比"链到主机上的同名库"可靠。**
   同名不同构建是最难查的一类问题 —— 它可能链接通过，只在运行时出问题。

4. **把构建验证做成自动门禁。**
   "模型段数必须是 7"这一条检查只花一秒，
   却能挡住一个**要花一次板上往返才能发现**的错误。

5. **凡是"静默丢失"的操作，都要有对应检查。**
   工具链在这里有三种静默失败：链接器丢弃段、tar 打包 0 字节链接、strip 删段。
   它们的共同点是**都不报错**。

---

## 5. 提炼过程 —— 从哪些失败与观察中总结出来

1. **"工具链不存在"这个结论维持了很久，代价很大。**
   它源于一次**不完备的搜索**（只找了 Vivado 目录，没找 SDK 目录）。
   教训被固化成一条：**确认"某样东西不存在"之前，先说明搜索范围**。

2. **`elfedit` 那一步是被"程序能编译、能启动、就是加载模型失败"逼出来的。**
   现象完全不指向链接，直到有人去查 ELF 类型才发现模型段根本没进可执行文件。
   现在它是一条**自动检查**（段计数），不再依赖人去想到。

3. **0 字节符号链接这个坑很典型**：`tar` 打包符号链接的行为本身是正确的，
   错的是"想当然地以为它会把目标文件的字节也带上"。
   症状（找不到库）与原因（链接指向了一个 0 字节文件）之间隔了好几层。

4. **"非 ASCII 让脚本解析失败"这条来自反复出现的问题**，
   最终被写成硬规则：构建与部署脚本保持纯 ASCII，中文只出现在文档里。

5. **本模板把"验证"提到与"构建"同等重要的位置**：
   段计数、字节数核对、ABI 探针 ——
   这三样都不是功能本身，但**没有它们，功能出问题时就无法判断是环境还是代码**。

# 无自启动的板子：可重复的断电上电 bring-up 模板

| 项 | 内容 |
|---|---|
| **类型** | 案例模板 |
| **适用场景** | 目标板**没有开机自启动**（根文件系统只进到 `init=/bin/sh`，没有 getty、没有 rc 脚本、没有 systemd），每次上电都要从"裸板"手动带到"应用在跑"，而且这个过程必须**可重复**且能**自动判定成功** |
| **使用方法** | 按 Phase A–H 顺序执行。**关键步骤必须在通电之前武装好**，否则只能再断电一次 |
| **失效条件** | ① 板子有可用的自启动机制，或已把整套流程固化进 SD 卡启动镜像 → 大部分步骤多余；② 板子有可用的 JTAG 调试通道 → 部分"板子失联就只能断电"的约束会放宽；③ 若关键产物（驱动模块、根文件系统）已经固化在板子上且不会丢，Phase G 的上传步骤可省 |
| **已验证效果** | 本项目用这套流程反复完成断上电重启，每次都回到 7.4–7.5 fps 的可用状态；脚本能自动报告失败在哪一阶段（退出码 1/2/3 分别对应 U-Boot 没抓到 / 串口打不开 / 内核没起来） |
| **投入** | 单次执行约 2–3 分钟（其中内核启动约 75 s）；写成脚本一次约一天 |

---

## 1. 最重要的设计原则：**先武装，再上电**

U-Boot 的 autoboot 倒计时只有**几秒**。如果等板子起来之后再启动抓取脚本，就永远抓不到命令行 ——
而这块板子**软重启不可用**（见陷阱 1），唯一补救办法是**再物理断电一次**。

所以顺序必须反过来：

```
① 启动主机侧 HTTP 服务器（board_deploy 目录，端口 8000）
② 启动串口抓取脚本（轮询端口，反复发 \r，直到看见 U-Boot 提示符）
③ 确认串口空闲、主机网络就绪、SD 卡插好
④ —— 现在才给板子上电 ——
```

> 脚本默认等待窗口 900 秒（15 分钟）。
> ⚠️ **文档漂移提醒**：本项目的 RUNBOOK 里写的是"30 分钟等待窗口"，而代码里是 900 s。
> **以代码为准**，需要更长的窗口就显式传参。这正是"技能包要写明失效条件"的一个实例 ——
> 文档和代码不一致时，**代码是权威**。

---

## 2. 完整流程

### Phase A · 抓 U-Boot（上电前后立即可用）

```powershell
$port = New-Object System.IO.Ports.SerialPort 'COM10',115200,None,8,one
$port.ReadTimeout = 400
$port.Open()
# 注意：绝对不要设置 DtrEnable / RtsEnable（见陷阱 5）
```

- 每约 120 ms 发一个裸 `\r`，匹配 `Zynq>` / `U-Boot>` / `U-Boot 2019`
- 若看到 `Starting kernel`，说明 autoboot 已经过去了 → 清空缓冲继续等 → **需要断电重来**
- **证明提示符是活的，而不只是显示在屏幕上**：发 `echo UB_PROBE`，必须能收到 `UB_PROBE`。
  只看到 U-Boot 的文字、但命令没有回应，说明 autoboot 已经过去了。

### Phase B · 引导内核（逐条，顺序不能乱）

```text
fatload mmc 0:1 0x01000000 image.ub
setenv fdt_high 0xffffffff
setenv devicetree_load_address 0x01000000
setenv bootargs console=ttyPS0,115200 earlyprintk root=/dev/mmcblk0p2 rw rootfstype=ext4 rootwait init=/bin/sh mem=120M cma=48M
bootm 0x01000000
```

等约 75 秒，然后 `echo BR_ALIVE` 确认拿到了 shell。

### Phase C · 建立最小运行环境

`init=/bin/sh` **什么都不挂载**，只有 proc/sys/dev 需要手动挂（`netstat`、`ifconfig` 等都依赖 `/proc`）：

```sh
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
mount -t proc proc /proc 2>/dev/null
mount -t sysfs sysfs /sys 2>/dev/null
mount -t devtmpfs devtmpfs /dev 2>/dev/null
mkdir -p /lib/firmware /www
echo ready

ifconfig eth0 192.168.1.50 netmask 255.255.255.0 up
```

> `uname -r` 必须与驱动模块的 vermagic 一致。
> 从 **SD 卡**引导内核，而不是从 QSPI 引导 —— 两者的 vermagic 不同，
> 用错了 `insmod` 会报 `disagrees about version of symbol module_layout`。

### Phase D · 加载比特流

```sh
wget -O /lib/firmware/dpu.bin http://192.168.1.100:8000/unified_clkfix_sw.bin
md5sum /lib/firmware/dpu.bin                       # 与构建产物核对
rmmod dpu 2>/dev/null
echo dpu.bin > /sys/class/fpga_manager/fpga0/firmware
sleep 9
cat /sys/class/fpga_manager/fpga0/state            # 会显示 operating —— 但不可信！见下
```

**比特流必须是"字交换"的 `.bin`，不是 `.bit`。**
PCAP DMA 期望每个 32 位字**字节反序**（同步字 `AA995566` → `6655AA99`），
且必须**剥掉 Vivado `.bit` 的头部**（同步字之前的一切）。
直接喂 `.bit` 会报 `could not find a sync word`。

> ⚠️ **`state=operating` 是假阳性**：加载失败之后它仍然显示 `operating` ——
> 反映的是 QSPI 里的**出厂比特流**，不是刚写进去的那个。
> **唯一可信的证据是读只有你的设计才有的寄存器**（见 Phase E 末尾）。

### Phase E · 配置 PL 时钟（顺序敏感）

```sh
busybox devmem 0xF8000008 32 0xDF0D        # 解锁 SLCR
busybox devmem 0xF8000170 32 0x00201400    # FCLK0_CTRL
busybox devmem 0xF800012C 32 0x01E00C40    # APER/FPGA3 时钟
busybox devmem 0xF8000240 32 0x0000000F    # PL 复位脉冲
sleep 1
busybox devmem 0xF8000240 32 0x00000000
busybox devmem 0xF8000004 32 0x767B        # 重新上锁
echo FCLK0=$(busybox devmem 0xF8000170)    # 读回必须是 0x00201400
```

| 寄存器 | 值 | 作用与漏掉的后果 |
|---|---|---|
| `0xF8000008` | `0xDF0D` | SLCR 解锁。**没有它，后续对 `0xF80001xx` / `0xF8000240` 的写会被直接丢弃** |
| `0xF8000170` | `0x00201400` | FCLK0 = IO_PLL(bit21) ÷ 20 = **精确 50.000 MHz**。裸机默认 `0x00200500`（÷5 = 200 MHz）→ PL 的 MMCM 锁定不了 → **计算域全死，但控制口仍然应答**（症状：任务只启动、永不完成、中断计数恒为 0） |
| `0xF800012C` | `0x01E00C40` | 外设时钟门控。**漏掉它，访问加速器寄存器会总线错误，`devmem` 会把板子挂死** |
| `0xF8000240` | `0x0000000F` → `0x00000000` | PL 复位脉冲，强制 PL 的 MMCM 按修正后的输入频率重新锁定。漏掉则 MMCM 仍锁在旧的（错误的）频率上 |
| `0xF8000004` | `0x767B` | SLCR 重新上锁 |

> ⚠️ **在比特流加载之前永远不要读 PL 寄存器** → 总线错误 → 内核 oops → 板子失联。

等约 6 秒后读签名，**这才是比特流生效的真正证据**：

```sh
echo ID=$(busybox devmem 0x40000000) SIG=$(busybox devmem 0x40f00000)
# 期望：ID=0x0D9C13F1  SIG=0x0C014450
```

### Phase F · 装入内核模块（必须在比特流之后）

```sh
insmod /home/root/dpu.ko 2>&1; echo rc=$?; ls -l /dev/dpu
```

**顺序反了的后果**：驱动 probe 会去访问 PL 窗口内的地址（本例是加速器 16 MB 窗口内的 `0x40F00000`），
而厂商比特流不译码该窗口 → external abort → **内核 oops，板子失联**。

### Phase G · 投送并启动应用

```sh
killall cam_stream 2>/dev/null; killall httpd 2>/dev/null; sleep 2
netstat -lnt 2>/dev/null | grep 8080 || echo PORT_FREE

cd /home/root && wget -q -O cam_stream http://192.168.1.100:8000/cam_stream
ls -l cam_stream                                    # 必须核对字节数！
chmod +x cam_stream
cd /home/root && ./cam_stream > /home/root/cam.log 2>&1 & echo STARTED_PID=$!
```

- **先确认端口空闲**：早前的验证流程可能还在用 `busybox httpd -p 8080` 占用端口。
- **`wget -q` 会隐藏错误**。板子磁盘只有几十 MB 空闲，所以**必须核对字节数**再 `chmod +x`。
  "命令返回了"不等于"文件对"。

### Phase H · 自动判定成功

**板端**：

```sh
netstat -lnt | grep 8080
tail -30 /home/root/cam.log
```

日志里应出现启动横幅、`dpuOpen + dpuLoadKernel(...)` 成功、推理线程启动、以及周期性的统计行。
**失败标志**：`dpuLoadKernel failed`。

**PC 端**：

```sh
curl -s -o stat.json --max-time 20 http://<board>:8080/stat
```

> ⚠️ **本项目的原始脚本在这里有个真实缺陷**：它只检查响应体 > 20 字节。
> 一个**陈旧或挂起的实例同样能通过**这个检查。
>
> **正确的判据是三件事同时成立**：
> ① `display_fps` 落在预期区间（本例 7.4–7.5）；
> ② `infer_ms` 落在预期区间（本例 192–193 ms）；
> ③ **隔几秒读两次，`display_frames` 与 `inferences` 都在增长**。
>
> 第 ③ 条最关键 —— 它是"**现在真的在跑**"而非"**曾经跑起来过**"的唯一证据。

**寄存器级的成功集合**：

| 检查 | 期望值 |
|---|---|
| `0xF8000170` | `0x00201400` |
| `0x40000000` | `0x0D9C13F1` |
| `0x40F00000` | `0x0C014450` |
| `fpga0/state` | `operating`（不可单独采信） |
| `/dev/dpu` | 存在 |
| 相机行计数器 | 在 0..44 之间滚动 |
| 帧缓存 `0x08000000` | 非零且随时间变化 |

---

## 3. 陷阱清单

1. **软重启会让板子变砖（比不重启更糟）。**
   本板打印 `Restarting system` 然后 `Reboot failed -- System halted`：
   PS 停机、控制台死、调试口也不通。
   **任何配置改动都需要一次物理断电重启。** 把这条写进脚本的输出里，
   否则接手的人会以为可以自动重启而卡死。

2. **`/tmp` 可能不存在。** 它是指向缺失的 `/var/tmp` 的坏符号链接，
   而 `init=/bin/sh` 下只挂了 proc/sys/dev。

3. **重定向到不存在的目录会静默杀掉整条命令。**
   `./app > /tmp/app.log 2>&1 & echo STARTED_PID=$!`
   → shell 无法建立重定向 → **应用根本没跑**，但 `$!` 仍然打印了一个进程号
   （那个后台子 shell 已经死了）。
   本项目因此**读到过一张上一次留下的结果图**，只因为三张"新"图的字节数完全相同才发现。
   **对策**：日志写到确定存在的目录，并且**用内容标记判定成功**
   （例如 grep 一个每次运行必定出现的字符串），绝不用"命令返回了"或"文件存在"。

4. **tmpfs 写满会静默截断。** 在 16 MB 的 tmpfs 上，一次传输合并出 3,117,056 字节，
   而源文件是 4,045,516 —— 每个分块的校验和都对，因为**这是文件系统满了，不是数据坏了**。
   先 `df` 目标目录、清掉旧产物。

5. **串口设置里这两个绝对不能开：`DtrEnable`、`RtsEnable`。**
   置位后板子**完全停止应答**，清零立刻恢复。
   另外：直接打开已知端口号而不是用 `GetPortNames()` 枚举（PC 重启后可能列不出来）；
   行尾用 **LF**；主机脚本保持**纯 ASCII**。

6. **不要做宽泛的进程清理**（`killall` 一切）—— 会把 HTTP 服务器和引导进程一起杀掉。

7. **`state=operating` 不是比特流可用的证据**（见 Phase D）。

8. **加载比特流之前不要读加速器寄存器**（见 Phase E）。

9. **旧的自动启动脚本可能是有害的。**
   本项目根文件系统里残留一个开机脚本，会在**坏比特流状态下**执行 `insmod` → 内核 oops。
   排查"随机起不来"时，先检查有没有这类遗留的自启动项。

10. **应用写 `/dev/mem` 时，帧几何必须精确。**
    本例真实行宽是 **1025×720 RGB565 = 1,476,000 字节/帧**（不是 1280）。
    几何错了不会报错，只会出乱图。

---

## 4. 可迁移的方法论

1. **把"必须在通电前完成的事"和"通电后要做的事"显式分开。**
   这个模板里最贵的一课就是顺序 —— 抓取窗口只有几秒，抓不到就要再断电一次。

2. **每个非显然的参数都要写明"省掉会怎样"。**
   上表里的每一个值，如果只写"需要设置"而没有失败模式，接手的人就无法判断能不能省。

3. **不要相信状态字段，要去读功能性证据。**
   `state=operating` 是假阳性；`insmod` 返回 0 也不代表模块在工作。
   **读一个只有你的设计才有的寄存器**，比任何状态字段都可靠。

4. **验证"现在在跑"，而不只是"跑起来过"。**
   隔几秒读两次、确认计数在增长 —— 这一个动作就能挡掉"陈旧实例/挂起进程"这类假成功。

5. **脚本的退出码要能区分失败在哪一阶段。**
   本例：2 = 串口打不开，1 = 没抓到 U-Boot，3 = 内核没起来到 shell。
   有区分度的退出码能把"失败了"变成"失败在哪"。

6. **把硬编码的绝对路径集中列出来。**
   这份流程里有主机路径、工具链路径、固定 IP 与端口号。
   列一张清单，"换台机器复现"就从几小时变成几分钟。

---

## 5. 提炼过程 —— 从哪些失败与观察中总结出来

1. **顺序问题是被"必须再断一次电"逼出来的。** 最初脚本是上电后才启动的，
   结果反复抓不到 U-Boot。意识到 autoboot 窗口只有几秒之后，
   把"武装"和"上电"的次序颠倒过来，问题消失。

2. **"假阳性"这一类反复出现，最终被单独列成一节**：
   `state=operating` 假阳性、`$!` 打印了已死进程的 PID、
   脚本只检查响应体 >20 字节（陈旧实例也能通过）、
   tmpfs 满了但每个分块校验和都对。
   **它们的共同点是：验证手段与被验证的目标之间只有间接关系。**

3. **"文档与代码不一致"被明确记录为一种需要处理的状况**：
   等待窗口（30 分钟 vs 900 秒）与 `/stat` 的字段名都出现了漂移。
   处理原则很简单：**代码是权威**，技能包里以代码为准并注明文档待修正。

4. **"先看有没有遗留的自启动项"这条来自一次真实的随机挂死**：
   排查很久才发现根文件系统里有个旧的启动脚本，在坏比特流状态下执行 `insmod`。
   现在它被列为"随机起不来"的第一检查项。

5. **把每一次失败都转成一条可检查的项**：
   这份模板的陷阱清单不是设计出来的，是**逐条踩出来的**。
   这也是为什么它写满了具体的数值和症状 —— 抽象成"注意顺序"就没人能用。

# checks/ —— 校验脚本

这些脚本的价值不在于"多跑一条命令"，而在于把**两种会静默失败的构建错误**变成硬失败。
两者都属于同一类陷阱：**工具报告成功，但你要的东西没有生效。**

| 脚本 | 检查什么 | 什么时候跑 | 失败意味着 |
|---|---|---|---|
| `check_dpu_model_sections.ps1` | 可执行文件里是否还有 `.deephi.*` 段 | **每次链接之后** | 链接器把模型段丢了，程序上板后 `dpuLoadKernel` 才会失败 |
| `check_ip_lock_status.tcl` | Block Design 里是否有 IP 处于 locked 状态 | **每次构建之前** | Vivado 会沿用旧网表构建，你的参数改动不在比特流里 |

---

## check_dpu_model_sections.ps1

### 为什么需要它

DNNDK 的 `dpuLoadKernel("<kernel>")` 从**正在运行的可执行文件**里读取名为 `.deephi.*` 的 ELF 段，
运行期并没有独立的模型文件。所以这些段一旦丢失，**程序依然能正常链接、正常启动**，
只在板上第一次调用推理时才失败。

### 丢失的经典原因

`objcopy` 会**保留输入文件的 `ET_DYN` 类型**。于是链接器把这个模型目标文件当成共享库处理，
**悄无声息地丢掉它的全部段**，不报任何错。

修法是把这个承载段的 `.o` 标成可重定位文件：

```sh
arm-linux-gnueabihf-objcopy -O elf32-littlearm --only-section='.deephi.*' <app> model.o
arm-linux-gnueabihf-elfedit  --output-type=rel model.o      # 关键的一步
```

验证 ELF 类型确实是 `REL` 而不是 `DYN`：

```sh
arm-linux-gnueabihf-readelf -h model.o | grep Type
```

### 用法

```powershell
.\check_dpu_model_sections.ps1 -Binary .\cam_stream
.\check_dpu_model_sections.ps1 -Binary .\model.o -Expected 7 -ToolchainBin 'D:\...\bin'
```

- `-Expected` 默认 7（`strtab / metadata / configurable / tensor / node / parameter / code`）。
  你要用自己的模型跑一次 `readelf -SW` 数清楚，然后把数字固定下来。
- 退出码 0 = 正常，1 = 段缺失或文件不存在。

---

## check_ip_lock_status.tcl

### 为什么需要它

IP 处于 locked 状态时，Vivado **不会更新它的综合检查点**，只打印警告，然后**照常构建成功**：

```
WARNING: [Vivado 12-4801] ... the IP is locked.
WARNING: [Project 1-577]  ... the out-of-date checkpoint will be used and
                            it may result in incorrect behavior.
```

你拿到的是一个**不含你的参数改动**的比特流，而且只有回到板上读回配置才会发现。

### 用法

```bat
vivado -mode batch -source check_ip_lock_status.tcl -tclargs <project.xpr> [bd_file]
```

- 退出码 0 = 无锁定 IP，可以构建；1 = 有锁定 IP，**不要相信这次构建出的比特流**。

### 清除锁定的顺序（有鸡生蛋问题）

所有 IP 的 `.dcp` 产物都缺失时：

- 对 BD 执行 `generate_target` 会被拒绝 —— `Block design contains locked IPs`
- 但要生成产物又必须先没有锁定 IP

解法是**先 `upgrade_ip`**：

```tcl
upgrade_ip [get_ips design_1_dpu_eu_0_0]
# ...其余各 IP
generate_target all [get_files design_1.bd]
```

> ⚠️ **`upgrade_ip` 可能重置 IP 配置。**
> 升级之后必须**重新读出你关心的全部参数**，不满足就直接 `exit 1` 拒绝构建。
> 否则会白等一次完整构建，拿到一个参数被悄悄改回去的比特流。

---

## 把它们接进构建流程

```
                   ┌──────────────────────────────┐
   改 IP 参数 ───▶ │ check_ip_lock_status.tcl     │──┐ 锁定>0 → 停止
                   └──────────────────────────────┘  │
                                                     ▼
                                        upgrade_ip → 复核参数 → 构建
                                                     │
                                                     ▼
                   ┌──────────────────────────────┐
   链接完成   ───▶ │ check_dpu_model_sections.ps1 │──▶ 段数≠7 → 停止
                   └──────────────────────────────┘
```

两条检查加起来不到两秒，能挡掉两类"要花一次板上往返或四十分钟构建才能发现"的错误。

---

## 验证状态（如实说明）

| 脚本 | 验证情况 |
|---|---|
| `check_dpu_model_sections.ps1` | ✅ **已在真实产物上实测**。对项目实际链接出的 ARM 可执行文件运行：识别出 7 个 `.deephi.*` 段、payload 合计 9,022,093 字节（与模型段文件 8.60 MB 吻合）、退出码 0。另测了段数不符（退出码 1，并打印 `elfedit` 排查提示）与文件不存在（退出码 1）两条失败路径 |
| `check_ip_lock_status.tcl` | ⚠️ **逻辑来自本项目实际使用的诊断脚本**（`diagnose_ip_lock.tcl` 与 `unlock_regen_and_build.tcl`），通用化改写后**尚未在完整工程上跑过一次全新的构建门禁**。首次接入时请人工确认输出符合预期 |

> 把验证状态写清楚，比假装两个脚本都测过更有用 ——
> 这样接手的人知道哪一条可以无条件信任，哪一条需要自己确认一遍。

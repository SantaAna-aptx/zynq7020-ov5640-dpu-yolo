# 改了 IP 参数却不生效 → IP 被锁定，静默沿用旧网表

| 项 | 内容 |
|---|---|
| **类型** | 踩坑清单 + 校验步骤 |
| **适用场景** | 用 Tcl 脚本批量修改 Block Design 里的 IP 参数后重建，怀疑"改了但没生效" |
| **使用方法** | 每次改完 IP 参数后，在构建日志里搜 `Project 1-577` / `12-4801`；改动后用 `report_ip_status` 复核锁定数 |
| **失效条件** | 适用于 Vivado 2019.x 的 IP 锁定机制。纯 RTL 工程（无 IP）不适用 |
| **已验证效果** | 发现后 `upgrade_ip` 使锁定数 5 → 0，随后重建的比特流参数正确 |
| **投入** | 定位 20 分钟；但**如果不发现，会白等一次完整构建（约 40 分钟）** |

---

## 现象

用 Tcl 改完 DPU 的三个参数后直接 build，日志里出现：

```
WARNING: [Vivado 12-4801] The synthesis checkpoint for IP '...design_1_dpu_eu_0_0.xci' is
         available but stale and the IP is locked.
WARNING: [Project 1-577]  IP run design_1_dpu_eu_0_0_synth_1 is ... out of date. Since the IP
         is locked, the synthesis checkpoint cannot be updated. The out-of-date checkpoint
         will be used and it may result in incorrect behavior.
```

**这就是"改了参数但比特流没变"的经典陷阱。**
危险之处在于它只是 `WARNING`，构建会**正常完成并出片** ——
你拿到的是一个参数没改的比特流，却以为改成功了。

## 根因

IP 因为各种原因（子核锁定、IP 文件过期、module reference 过期）进入 locked 状态后，
Vivado **不会更新它的综合检查点**，而是沿用旧的 `.dcp`。

### 鸡生蛋问题

更麻烦的是：所有 IP 的 `.dcp` 产物都缺失，而对 BD 执行 `reset_target` / `generate_target`
会被直接拒绝：

```
CRITICAL WARNING: [filemgmt 20-1365] Unable to generate target(s) ...
                  Block design contains locked IPs.
```

**要生成产物必须没有锁定 IP，要解锁又需要生成产物** —— 死循环。

## 排查步骤

1. **每次改 IP 参数后，在构建日志里搜这两条**：
   ```
   Project 1-577
   12-4801
   ```
   出现任何一条 → 立刻停下，不要等构建跑完。

2. 查看每个 IP 的锁定状态与**药方**：
   ```tcl
   report_ip_status
   ```
   实际输出示例：

   | IP | 状态 | 建议动作 |
   |---|---|---|
   | `design_1_dpu_eu_0_0` | IP contains locked subcore | **Upgrade IP** |
   | `design_1_ps7_0` / `dbg_gpio` / `rst_100` / `rst_cam` | Stale IP file detected | **Upgrade IP** |
   | `design_1_cam_top_0` / `frame_writer_0_0` | Stale module reference | **Refresh module reference** |

3. 复核锁定数：解到 0 才允许 `generate_target`。

## 修复

逐 IP 执行 `upgrade_ip`：

```tcl
upgrade_ip [get_ips design_1_dpu_eu_0_0]
# ... 其余各 IP
generate_target all [get_files design_1.bd]
```

锁定数 5 → 0 之后，`generate_target all` 才被允许执行。

### ⚠️ 必须加的一道保险：`upgrade_ip` 可能重置 IP 配置

**升级之后必须重新校验关键参数**，不满足就 `exit 1` 拒绝构建。
否则你会白等四十分钟，拿到一个参数被悄悄改回去的比特流。

本次实际遇到过这条：升级后重新读 `CONFIG.*` 与 `DNNDK_PRINT` 做断言，
确认三个开关仍然是期望值才继续。

参考脚本：`diagnose_ip_lock.tcl`（`report_ip_status` + 逐 IP `upgrade_ip`，把锁定数打到 0）、
`unlock_regen_and_build.tcl`（解锁 → 复核 DPU 特性 → 重新生成 → 构建）。
另有一个同类陷阱记录在 `rebuild_force_ooc.tcl` 的注释里（`cam_top` 的 OOC 综合产物过期）。

## 提炼过程 —— 从哪些失败与观察中总结出来

1. **最初的错误认知**：以为"构建成功 = 改动生效"。直到用 `dexplorer -w` 发现
   DPU 特性**还是旧的**（明明改过参数），才回头翻日志找到那两条 WARNING。
2. **关键习惯**：把"构建日志里必须搜的关键词"固化为流程的一部分。
   这类警告不会让构建失败，只能主动去找。
3. **对 `generate_target` 被拒绝的处理**：一开始以为是权限或文件锁定问题，
   反复删 `.Xil` 目录、重启 Vivado —— 无效。
   真正的解法在 `report_ip_status` 的"建议"列里，**它直接告诉你要 `upgrade_ip`**。
4. **教训**：**Vivado 的"成功"是有层次的**。
   构建成功、生成比特流成功，都不代表你的参数被采纳了。
   唯一可靠的验证是**回到板上读回实际配置**（本例用 `dexplorer -w`）。

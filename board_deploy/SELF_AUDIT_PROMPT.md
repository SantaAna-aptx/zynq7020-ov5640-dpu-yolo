# SELF-AUDIT PROMPT —— 项目全面扫盲自我提示词

> 当再次面对"全面检查/地毯式搜索/确保百分之百正确"类要求时，按本提示词执行。

## 核心原则
1. **不基于记忆判断，基于读回数据判断**——每个结论必须有寄存器读回值/文件内容/命令输出支撑
2. **一次只改一个变量**——改完立即验证，否则归因混乱
3. **先观测后修改**——先用只读手段确认状态，再动手改
4. **警惕自己的历史错误**——反斜杠转义、puts 通道复用、&&短路、sleep 时序、变量假设

## 层面顺序（从外到内）

### 0. 环境健康（每次开始）
- [ ] VM 存活：vmrun list
- [ ] Vivado 无残留：Get-Process vivado
- [ ] HTTP 服务器存活：Get-NetTCPConnection 8000
- [ ] 串口独占：无其他进程占 COM10

### 1. Bitstream 层
- [ ] date/time 与构建时间吻合（fpga loadb 输出）
- [ ] MD5 三点一致：构建产物 = web/ = 板端 /home/root
- [ ] SD 卡 FAT 内 design_1_wrapper.bit 为最新（板端挂载后 md5sum）
- [ ] FPGA 配置确认：cat /sys/class/fpga_manager/fpga0/state = operating

### 2. Vivado BD 层（hwh 解析）
- [ ] DPU CONFIG：ARCH/核心数/时钟假设频率
- [ ] 全部时钟引脚连接表（SIGIS=clk 的每个引脚）
- [ ] 全部复位连接表（SIGIS=rst + POLARITY）
- [ ] 地址映射表：DPU 3 个 M_AXI 各自的 SEG（offset/range 覆盖 DDR）
- [ ] 中断：dpu_interrupt SIGNAME → PS7 IRQ_F2P 位号

### 3. 设备树层（板端）
- [ ] dpu 节点：base-addr/interrupts（GIC 真实号）/compatible
- [ ] xlnk、cma、console
- [ ] /proc/interrupts 确认注册行与 GIC 硬件号
- [ ] inittab getty

### 4. rootfs 层
- [ ] 四个软件组件齐全（tiny_yolo/dpu.ko/三库/模型）
- [ ] OpenCV 环境
- [ ] rc.local 永久化配置

### 5. 运行时状态（板端寄存器读）
- [ ] SLCR：0xF8000110(IO_PLL_CTRL)/0xF8000170(FCLK0_CTRL)
- [ ] DPU：VER/RST/ISR/IMR/IRSR
- [ ] GIC：ISPR 全寄存器（0xF8F01200-214）
- [ ] CMA：指令缓冲内容

### 6. 执行链观测（终极）
- [ ] HP 口事务：tiny_yolo 前后 HP 计数器差
- [ ] DPU IRSR 运行中状态
- [ ] GIC pending 运行中状态

## 已知陷阱清单（本人犯过的错）
1. tcl 路径反斜杠 \v \r 转义 → 用正斜杠
2. tcl puts 到已关闭通道 → 脚本静默中断 → 每步 Log 独立开闭
3. Bash 后台 sleep N 在前一命令结束后才开始 → 实验时序失效
4. schtasks /sc once /st 23:4x → 到达时刻自动重复触发 → 进程堆积
5. && 短路：rmmod 失败导致 insmod 未执行
6. $filesize 变量为空 → fpga loadb 打印 Usage → 用固定数字
7. dump 读数在超时清理后 → 证据被清 → 运行中读
8. 变量假设未验证：IO_PLL 频率、divisor 语义、IRSR offset
9. 多个自动化互相并发 → EA reset / 工程锁 → 单实例纪律

## 快速恢复命令包（板端 root）
```
# 时钟使能
devmem 0xF8000008 32 0xDF0D
devmem 0xF8000170 32 0x00400A00
devmem 0xF800021C 32 0x00000001
# DPU 驱动
insmod /home/root/dpu.ko
# 状态速查
devmem 0x40000000   # DPU VER = 0x0D9C13F1
devmem 0x40000008   # DPU ISR
grep dpu /proc/interrupts
ls /dev/dpu
```

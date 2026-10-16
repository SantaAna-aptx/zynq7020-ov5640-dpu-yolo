# d5_full.ps1 -- one shot after a power cycle: grab U-Boot -> boot the kernel -> load the new
# bitstream -> run the four acceptance checks.
#
# This merges d4_loop.ps1's boot logic with d5_verify.ps1's checks, because a freshly powered
# board has no root shell yet and U-Boot has to be caught first.
#
# The boot recipe carries three hard-won settings, each with measured evidence behind it:
#   * image.ub MUST be loaded at 0x01000000, not 0x10000000. The FIT carries its device tree as
#     a subimage at offset 0x3F2BE4, so loading at 0x10000000 puts the DTB at 0x103F2BE4
#     (~260 MB) while the kernel only owns the first 120 MB -> hangs silently right after
#     "Starting kernel ...". At 0x01000000 the DTB lands near 20 MB, safely inside the cap.
#   * fdt_high=0xffffffff stops U-Boot relocating the DTB to the top of RAM (measured: it went to
#     0x1fff9000 = 512 MB, also outside mem=120M).
#   * mem=120M keeps the camera's 0x08000000 (128 MB) frame buffer out of kernel RAM.
#     cma=48M backs the DPU's tensors: the DTB only declares an xlnk node, and the cma=256M that
#     the delivery bootargs carried cannot fit inside 120M.
#
# Kept deliberately ASCII-only: non-ASCII characters in this file broke the PowerShell parser.
param(
  [string]$Port     = 'COM10',
  [string]$HostIp   = '192.168.1.100',
  [string]$BoardIp  = '192.168.1.50',
  [int]$HttpPort    = 8000,
  [int]$CatchSec    = 3600,
  [string]$Bin      = 'unified_dpufix_sw.bin',
  [string]$BinMd5   = 'bfd107dc67b8fa643e64166f7ac358bf',
  [int]$Iterations  = 2
)
$dir = 'E:\yoloProject\board_deploy'
$log = Join-Path $dir ("d5_full_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$sw  = New-Object System.IO.StreamWriter($log, $false); $sw.AutoFlush = $true
$sp  = New-Object System.IO.Ports.SerialPort $Port,115200,None,8,one
$sp.ReadTimeout = 400
$script:buf = ""
$py  = 'C:\Users\HP\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe'

function Raw { try { $d = $sp.ReadExisting() } catch { $d = "" }; if ($d) { $script:buf += $d; $sw.Write($d) }; return $d }
function Drain([int]$ms) { $t=(Get-Date).AddMilliseconds($ms); $o=""; while ((Get-Date) -lt $t) { $o += (Raw); Start-Sleep -Milliseconds 20 }; return $o }
function Send([string]$s) { try { $sp.Write($s) } catch { } }
function Ask([string]$c,[int]$w=3000){ Send ($c + "`n"); return (Drain $w) }
function Show([string]$t,[string]$o,[int]$n=30){
    Write-Host "--- $t ---"
    ($o -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } |
        Select-Object -Last $n | ForEach-Object { Write-Host ("   " + $_) }
}

Write-Host "=== waiting for U-Boot (power the board on; this waits $CatchSec s) ==="
try { $sp.Open() } catch { Write-Host "!! cannot open $Port : $($_.Exception.Message)"; $sw.Close(); exit 2 }
# Deliberately do NOT touch DtrEnable / RtsEnable. The validated harness (d4_loop.ps1) leaves both
# at their defaults, and asserting them is a plausible way to hold this board in reset - the CP210x
# handshake lines are wired on some boards. If the board ever looks dead on serial, this is suspect.
Drain 600 | Out-Null; $script:buf = ""

$deadline = (Get-Date).AddSeconds($CatchSec); $broke = $false
while ((Get-Date) -lt $deadline) {
    Send "`r"; Raw | Out-Null
    if ($script:buf -match '(Zynq>|U-Boot>|U-Boot 2019)') { $broke = $true; break }
    if ($script:buf -match 'Starting kernel') { $script:buf = "" }
    Start-Sleep -Milliseconds 120
}
if (-not $broke) { Write-Host "!! never saw U-Boot within $CatchSec s"; $sw.Close(); $sp.Close(); exit 1 }

# Seeing the banner is not the same as U-Boot still listening - it may just be leftover text in the
# buffer. An echo proves the command interface actually responds.
$probe = Ask "echo UB_PROBE" 2500
if ($probe -notmatch 'UB_PROBE') {
    Write-Host "!! saw U-Boot text but it does not answer commands (autoboot already passed)."
    Write-Host "   Power cycle the board again and re-run."
    Show "last serial output" $probe 15
    $sw.Close(); $sp.Close(); exit 1
}
Write-Host "U-Boot caught"

# ---------------- boot the kernel ----------------
Write-Host ""
Write-Host "=== booting kernel (image.ub @ 0x01000000, mem=120M cma=48M) ==="
Ask "fatload mmc 0:1 0x01000000 image.ub" 6000 | Out-Null
Ask "setenv fdt_high 0xffffffff" 600 | Out-Null
Ask "setenv devicetree_load_address 0x01000000" 600 | Out-Null
Ask "setenv bootargs console=ttyPS0,115200 earlyprintk root=/dev/mmcblk0p2 rw rootfstype=ext4 rootwait init=/bin/sh mem=120M cma=48M" 900 | Out-Null
Ask "bootm 0x01000000" 1500 | Out-Null
$bootlog = Drain 90000
Show "boot" $bootlog 22

Ask "" 1500 | Out-Null
if ((Ask "echo D5_ALIVE" 2500) -notmatch 'D5_ALIVE') {
    Write-Host "!! the kernel never reached a shell - last lines below"
    ($bootlog -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } | Select-Object -Last 12 | ForEach-Object { Write-Host "   $_" }
    Write-Host "log: $log"; $sw.Close(); $sp.Close(); exit 3
}
Ask "export PATH=/sbin:/bin:/usr/sbin:/usr/bin; mount -t proc proc /proc 2>/dev/null; mount -t sysfs sysfs /sys 2>/dev/null; mount -t devtmpfs devtmpfs /dev 2>/dev/null; mkdir -p /lib/firmware /www; echo ready" 2000 | Out-Null
Show "kernel / memory" (Ask "uname -r; cat /proc/cmdline; grep -E 'MemTotal|CmaTotal|CmaFree' /proc/meminfo" 2500) 6
Ask "ifconfig eth0 $BoardIp netmask 255.255.255.0 up" 3500 | Out-Null

# ---------------- load the new bitstream ----------------
Write-Host ""
Write-Host "==================== loading $Bin ===================="
Show "download" (Ask "wget -O /lib/firmware/dpu.bin http://${HostIp}:${HttpPort}/$Bin 2>&1 | tail -1; md5sum /lib/firmware/dpu.bin" 40000) 3
Ask "rmmod dpu 2>/dev/null; echo rmmod_ok" 2500 | Out-Null
Send "echo dpu.bin > /sys/class/fpga_manager/fpga0/firmware`n"; Start-Sleep -Seconds 9
Show "fpga state" (Ask "cat /sys/class/fpga_manager/fpga0/state" 2000) 2

# FCLK0 = 0x00201400 -> exactly 50.000 MHz. Without it the DPU's MMCM never locks and the compute
# domain is dead while S_AXI still answers, because S_AXI is clocked straight from FCLK_CLK0 - that
# is what once looked like "the DPU is alive but every task times out". 0xF800012C is required or
# DPU register access bus-faults. The PL reset pulse makes the MMCM re-lock.
Show "clocks" (Ask "busybox devmem 0xF8000008 32 0xDF0D; busybox devmem 0xF8000170 32 0x00201400; busybox devmem 0xF800012C 32 0x01E00C40; busybox devmem 0xF8000240 32 0x0000000F; sleep 1; busybox devmem 0xF8000240 32 0x00000000; busybox devmem 0xF8000004 32 0x767B; echo FCLK0=`$(busybox devmem 0xF8000170) done" 4000) 2
Start-Sleep -Seconds 6
Show "signatures" (Ask "echo ID=`$(busybox devmem 0x40000000) SIG=`$(busybox devmem 0x40f00000) s" 3000) 2
Show "insmod" (Ask "insmod /home/root/dpu.ko 2>&1; echo rc=`$?; ls -l /dev/dpu" 3500) 3

# ---------------- CHECK 1: the DPU's own feature report ----------------
Write-Host ""
Write-Host "=== CHECK 1: dexplorer -w (the old unified bitstream showed three Disabled here) ==="
$dex = Ask "cd /home/root/dpu && ./dexplorer -w 2>&1; echo DEX_DONE" 9000
Show "dexplorer" $dex 30
$flags = @{}
($dex -split "`n") | ForEach-Object {
    if ($_ -match '^\s*(Conv\+Leakyrelu|Conv\+Relu6|Channel Augmentation|Average Pool|DepthwiseConv\+Relu6|DepthwiseConv)\s*:\s*(\S+)') {
        $flags[$Matches[1]] = $Matches[2]
    }
}
$allGood = $true
foreach ($k in @('DepthwiseConv','DepthwiseConv+Relu6','Conv+Leakyrelu','Conv+Relu6','Channel Augmentation','Average Pool')) {
    $val = 'MISSING'
    if ($flags.ContainsKey($k)) { $val = $flags[$k] }
    if ($val -eq 'Enabled') { Write-Host ("   OK    {0,-24} {1}" -f $k, $val) }
    else { Write-Host ("   FAIL  {0,-24} {1}" -f $k, $val); $allGood = $false }
}
if (-not $allGood) { Write-Host "!! DPU feature set still wrong - stopping"; $sw.Close(); $sp.Close(); exit 4 }

# ---------------- CHECK 2: the 8/8 reference must reproduce ----------------
Write-Host ""
Write-Host "=== CHECK 2: dog.jpg (reference: identical=1, raw=6 nms=3) ==="
$o = Ask "cd /home/root/d3 && timeout 120 ./tiny_yolo_image_diag4 dog.jpg 2>&1 | grep -E 'Class name|DETERM_CHECK|DETERM_EXTRA|BOXES|RESULT_SAVED|IMAGE_INFO|RAWOUT|mismatch'; echo app_done" 140000
# Show more lines than the last run: with 15 bogus classes the old limit of 20 pushed IMAGE_INFO
# (the very first line) out of view, which is exactly the line that tells you whether the input
# image was read correctly.
Show "app" $o 45
$ident = 'FAIL'
if ($o -match 'identical=1') { $ident = 'PASS' }
$boxes = 'FAIL'
if ($o -match 'raw=6 after_nms=3') { $boxes = 'PASS' }
Write-Host ("   determinism identical=1 : " + $ident)
Write-Host ("   boxes raw=6 after_nms=3 : " + $boxes)

# ---------------- CHECK 3: the camera half in the same bitstream ----------------
Write-Host ""
Write-Host "=== CHECK 3: camera alive (debug word + frame data) ==="
Show "camera" (Ask "echo CAM=`$(busybox devmem 0x41220000) W0=`$(busybox devmem 0x08000000) MID=`$(busybox devmem 0x08040000) s" 3000) 3

# ---------------- CHECK 4: the closed loop ----------------
Write-Host ""
Write-Host "=== CHECK 4: live frame -> DPU -> annotated result back ==="
Ask "cd /home/root && (netstat -lnt 2>/dev/null | grep -q 8080) || httpd -p 8080 -h /www" 2000 | Out-Null
for ($i = 1; $i -le $Iterations; $i++) {
    Write-Host ("--- iteration {0}/{1} ---" -f $i, $Iterations)
    $t0 = Get-Date
    Ask "python3 /dump_frame.py /www/frame.raw 1476000 2>&1 | tail -1" 20000 | Out-Null
    $rawPc = Join-Path $dir 'd5_frame.raw'
    Remove-Item $rawPc -ErrorAction SilentlyContinue
    & curl.exe -s -o $rawPc --max-time 40 "http://${BoardIp}:8080/frame.raw" 2>&1 | Out-Null
    if ((-not (Test-Path $rawPc)) -or ((Get-Item $rawPc).Length -lt 1476000)) { Write-Host "   frame fetch failed"; continue }
    $jpgPc = Join-Path $dir 'd5_frame.jpg'
    $conv = & $py (Join-Path $dir 'raw565_to_jpg.py') $rawPc $jpgPc 1025 720 2>&1 | Select-Object -Last 1
    Write-Host "   convert: $conv"
    Send "wget -q -O /home/root/d3/live.jpg http://${HostIp}:${HttpPort}/d5_frame.jpg; ls -l /home/root/d3/live.jpg`n"
    Drain 15000 | Out-Null
    $res = Ask "cd /home/root/d3 && timeout 120 ./tiny_yolo_image_diag4 live.jpg 2>&1 | grep -E 'Class name|DETERM_CHECK|BOXES|IMAGE_INFO|RESULT_SAVED|mismatch'; echo loop$i" 140000
    ($res -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -match 'Class name|BOXES|DETERM_CHECK|IMAGE_INFO|RESULT_SAVED|mismatch' } | ForEach-Object { Write-Host ("   " + $_) }
    Ask "cp /home/root/result.jpg /www/result.jpg 2>/dev/null; echo r$i" 1800 | Out-Null
    $outPc = Join-Path $dir ("d5_result_{0}.jpg" -f $i)
    Remove-Item $outPc -ErrorAction SilentlyContinue
    & curl.exe -s -o $outPc --max-time 40 "http://${BoardIp}:8080/result.jpg" 2>&1 | Out-Null
    if ((Test-Path $outPc) -and ((Get-Item $outPc).Length -gt 1000)) {
        Write-Host ("   result image: {0} ({1} bytes)" -f $outPc, (Get-Item $outPc).Length)
    } else { Write-Host "   result image: NOT retrieved" }
    Write-Host ("   took {0:N1}s" -f ((Get-Date) - $t0).TotalSeconds)
}

Write-Host ""
Write-Host "log: $log"
$sw.Close(); $sp.Close()

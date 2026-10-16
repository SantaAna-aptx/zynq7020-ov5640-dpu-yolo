# bringup_and_stream.ps1 -- after a power cycle: catch U-Boot -> boot kernel -> load the bitstream
# -> set clocks -> insmod dpu.ko -> download and start cam_stream -> verify /stat.
#
# This is d5_full.ps1's proven bring-up chain with the verification steps replaced by "start the
# streamer", because that is now the thing we want running.
#
# The boot recipe carries three settings that each cost a power cycle to discover:
#   * image.ub at 0x01000000, NOT 0x10000000. The FIT holds its device tree at offset 0x3F2BE4,
#     so a load at 0x10000000 puts the DTB at ~260 MB while the kernel only owns the first 120 MB
#     -> silent hang right after "Starting kernel ...".
#   * fdt_high=0xffffffff stops U-Boot relocating the DTB to the top of RAM (measured 0x1fff9000
#     = 512 MB, equally out of reach under the cap).
#   * mem=120M keeps the camera's 0x08000000 frame buffer out of kernel RAM; cma=48M backs the DPU
#     tensors (the delivery bootargs' cma=256M cannot fit inside 120M).
# Then FCLK0 = 0x00201400 (exactly 50.000 MHz) is what makes the DPU's MMCM lock - without it the
# compute domain is dead while S_AXI still answers.
param(
  [string]$Port     = 'COM10',
  [string]$HostIp   = '192.168.1.100',
  [string]$BoardIp  = '192.168.1.50',
  [int]$HttpPort    = 8000,
  [int]$CatchSec    = 900,
  [string]$Bin      = 'unified_clkfix_sw.bin',
  [string]$App      = 'cam_stream',
  [int]$WarmupSec   = 20
)
$dir = 'E:\yoloProject\board_deploy'
$log = Join-Path $dir ("bringup_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$sw  = New-Object System.IO.StreamWriter($log, $false); $sw.AutoFlush = $true
$sp  = New-Object System.IO.Ports.SerialPort $Port,115200,None,8,one
$sp.ReadTimeout = 400
$script:buf = ""

function Raw { try { $d = $sp.ReadExisting() } catch { $d = "" }; if ($d) { $script:buf += $d; $sw.Write($d) }; return $d }
function Drain([int]$ms) { $t=(Get-Date).AddMilliseconds($ms); $o=""; while ((Get-Date) -lt $t) { $o += (Raw); Start-Sleep -Milliseconds 20 }; return $o }
function Send([string]$s) { try { $sp.Write($s) } catch { } }
function Ask([string]$c,[int]$w=3000){ Send ($c + "`n"); return (Drain $w) }
function Show([string]$t,[string]$o,[int]$n=25){
    Write-Host "--- $t ---"
    ($o -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } |
        Select-Object -Last $n | ForEach-Object { Write-Host ("   " + $_) }
}

Write-Host "=== waiting for U-Boot (power the board on; up to $CatchSec s) ==="
try { $sp.Open() } catch { Write-Host "!! $Port : $($_.Exception.Message)"; $sw.Close(); exit 2 }
# No DtrEnable / RtsEnable - asserting them makes this board stop answering commands entirely.
Drain 600 | Out-Null; $script:buf = ""

$deadline = (Get-Date).AddSeconds($CatchSec); $broke = $false
while ((Get-Date) -lt $deadline) {
    Send "`r"; Raw | Out-Null
    if ($script:buf -match '(Zynq>|U-Boot>|U-Boot 2019)') { $broke = $true; break }
    if ($script:buf -match 'Starting kernel') { $script:buf = "" }
    Start-Sleep -Milliseconds 120
}
if (-not $broke) { Write-Host "!! never saw U-Boot"; $sw.Close(); $sp.Close(); exit 1 }

$probe = Ask "echo UB_PROBE" 2500
if ($probe -notmatch 'UB_PROBE') {
    Write-Host "!! saw U-Boot text but it does not answer - autoboot already passed, power cycle again"
    $sw.Close(); $sp.Close(); exit 1
}
Write-Host "U-Boot caught"

Write-Host ""
Write-Host "=== booting kernel (image.ub @ 0x01000000, mem=120M cma=48M) ==="
Ask "fatload mmc 0:1 0x01000000 image.ub" 6000 | Out-Null
Ask "setenv fdt_high 0xffffffff" 600 | Out-Null
Ask "setenv devicetree_load_address 0x01000000" 600 | Out-Null
Ask "setenv bootargs console=ttyPS0,115200 earlyprintk root=/dev/mmcblk0p2 rw rootfstype=ext4 rootwait init=/bin/sh mem=120M cma=48M" 900 | Out-Null
Ask "bootm 0x01000000" 1500 | Out-Null
$bootlog = Drain 75000
Show "boot" $bootlog 12

Ask "" 1500 | Out-Null
if ((Ask "echo BR_ALIVE" 3000) -notmatch 'BR_ALIVE') {
    Write-Host "!! kernel never reached a shell"
    ($bootlog -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } | Select-Object -Last 10 | ForEach-Object { Write-Host "   $_" }
    Write-Host "log: $log"; $sw.Close(); $sp.Close(); exit 3
}
Ask "export PATH=/sbin:/bin:/usr/sbin:/usr/bin; mount -t proc proc /proc 2>/dev/null; mount -t sysfs sysfs /sys 2>/dev/null; mount -t devtmpfs devtmpfs /dev 2>/dev/null; mkdir -p /lib/firmware /www; echo ready" 2000 | Out-Null
Show "kernel" (Ask "uname -r; grep -E 'MemTotal|CmaTotal' /proc/meminfo" 2500) 4
Ask "ifconfig eth0 $BoardIp netmask 255.255.255.0 up" 3500 | Out-Null

Write-Host ""
Write-Host "==================== bitstream ===================="
Show "download" (Ask "wget -O /lib/firmware/dpu.bin http://${HostIp}:${HttpPort}/$Bin 2>&1 | tail -1; md5sum /lib/firmware/dpu.bin" 60000) 3
Ask "rmmod dpu 2>/dev/null; echo rmmod_ok" 2500 | Out-Null
Send "echo dpu.bin > /sys/class/fpga_manager/fpga0/firmware`n"; Start-Sleep -Seconds 9
Show "fpga state" (Ask "cat /sys/class/fpga_manager/fpga0/state" 2000) 2

Write-Host "=== clocks: FCLK0 = 0x00201400 (exactly 50.000 MHz) + PL reset pulse ==="
Show "clocks" (Ask "busybox devmem 0xF8000008 32 0xDF0D; busybox devmem 0xF8000170 32 0x00201400; busybox devmem 0xF800012C 32 0x01E00C40; busybox devmem 0xF8000240 32 0x0000000F; sleep 1; busybox devmem 0xF8000240 32 0x00000000; busybox devmem 0xF8000004 32 0x767B; echo FCLK0=`$(busybox devmem 0xF8000170) done" 4000) 2
Start-Sleep -Seconds 6
Show "signatures" (Ask "echo ID=`$(busybox devmem 0x40000000) SIG=`$(busybox devmem 0x40f00000) s" 3000) 2
Show "insmod" (Ask "insmod /home/root/dpu.ko 2>&1; echo rc=`$?; ls -l /dev/dpu" 3500) 3

Write-Host ""
Write-Host "==================== start $App ===================="
Show "kill old" (Ask "killall cam_stream 2>/dev/null; killall httpd 2>/dev/null; sleep 2; netstat -lnt 2>/dev/null | grep 8080 || echo PORT_FREE; echo KILL_DONE" 8000) 5
Show "fetch app" (Ask "cd /home/root && wget -q -O $App http://${HostIp}:${HttpPort}/$App; ls -l $App; chmod +x $App; echo FETCH_DONE" 90000) 4
Show "start" (Ask "cd /home/root && ./$App > /home/root/cam.log 2>&1 & echo STARTED_PID=`$!" 12000) 3

Write-Host ""
Write-Host ("=== warm up " + $WarmupSec + " s, then read the program log ===")
Start-Sleep -Seconds $WarmupSec
Show "cam.log" (Ask "cat /home/root/cam.log | tail -30; echo LOG_DONE" 10000) 30
Show "listening" (Ask "netstat -lnt 2>/dev/null | grep 8080 || echo NOT_LISTENING; echo NET_DONE" 8000) 4

Write-Host ""
Write-Host "=== live check over HTTP ==="
foreach ($u in @('/stat','/latest')) {
    $dst = Join-Path $dir ("bringup" + ($u -replace '/','_') + ".bin")
    Remove-Item $dst -ErrorAction SilentlyContinue
    & curl.exe -s -o $dst --max-time 20 ("http://${BoardIp}:8080" + $u) 2>&1 | Out-Null
    if ((Test-Path $dst) -and ((Get-Item $dst).Length -gt 20)) {
        Write-Host ("   {0} -> {1} bytes" -f $u, (Get-Item $dst).Length)
        if ($u -eq '/stat') { Write-Host ("      " + (Get-Content $dst -Raw)) }
    } else { Write-Host ("   {0} -> FAILED" -f $u) }
}
Write-Host ""
Write-Host ("open in a browser:  http://" + $BoardIp + ":8080/")
Write-Host ("log: " + $log)
$sw.Close(); $sp.Close()

# d4_loop.ps1 -- D4: camera -> inference closed loop on ONE unified bitstream.
#
# The unified bitstream is unified_color_sw.bin (the colour-fixed build: cam_top + frame_writer
# into 0x08000000, plus dpu_eu_0, with 0x4300 = 0x61 so the sensor emits true RGB565).
#
# Two hard-won settings make both halves work at once:
#   * FCLK0 = 0x00201400 -> 50.000 MHz exactly (DPU's clk_wiz is built for 50; the camera MMCM
#     wants 50 too). Without it the DPU compute domain is dead while its registers still answer.
#   * mem=120M on the kernel command line: the camera writes frames to 0x08000000, which is
#     otherwise kernel RAM - loading the camera bitstream with the full 1 GB would corrupt it.
#
# The loop itself is PC-assisted (the board has no compiler and no image tooling): the board
# dumps its frame buffer, the PC turns RGB565 into a JPG, the board runs YOLO on it and publishes
# the result image, the PC fetches it back. That proves the whole chain and shows boxes drawn on
# a live camera frame.
param(
  [string]$HostIp   = '192.168.1.100',
  [string]$BoardIp  = '192.168.1.50',
  [int]$HttpPort    = 8000,
  [int]$CatchSec    = 2400,
  [int]$Iterations  = 3,
  [switch]$SwapRB
)
$dir = 'E:\yoloProject\board_deploy'
$log = Join-Path $dir ("d4_loop_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$sw  = New-Object System.IO.StreamWriter($log, $false)
$sp  = New-Object System.IO.Ports.SerialPort 'COM10',115200,None,8,one
$sp.ReadTimeout = 500; $sp.NewLine = "`n"
$script:buf = ""
$py  = 'C:\Users\HP\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe'

function Raw { try { $d = $sp.ReadExisting() } catch { $d = "" }; if ($d) { $script:buf += $d; $sw.Write($d); $sw.Flush() }; return $d }
function Drain([int]$ms) { $t=(Get-Date).AddMilliseconds($ms); $o=""; while ((Get-Date) -lt $t) { $o += (Raw); Start-Sleep -Milliseconds 20 }; return $o }
function Send([string]$s) { try { $sp.Write($s) } catch { } }
function Ask([string]$c,[int]$w=3000){ Send ($c + "`n"); return (Drain $w) }
function Show([string]$t,[string]$o,[int]$n=6){ Write-Host "--- $t ---"; ($o -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } | Select-Object -Last $n | ForEach-Object { Write-Host "   $_" } }

Write-Host "=== boot: mem=120M keeps the camera's 0x08000000 frame buffer out of kernel RAM ==="
try { $sp.Open() } catch { Write-Host "!! COM10: $($_.Exception.Message)"; $sw.Close(); exit 2 }
Drain 600 | Out-Null; $script:buf = ""
$deadline = (Get-Date).AddSeconds($CatchSec); $broke = $false
while ((Get-Date) -lt $deadline) {
    Send "`r"; Raw | Out-Null
    if ($script:buf -match '(Zynq>|U-Boot>)') { $broke = $true; break }
    if ($script:buf -match 'Starting kernel') { $script:buf = "" }
    Start-Sleep -Milliseconds 120
}
if (-not $broke) { Write-Host "!! never reached the U-Boot prompt"; $sw.Close(); $sp.Close(); exit 1 }
# image.ub goes to 0x01000000, NOT 0x10000000. This is the whole reason this script hung at
# "Starting kernel ..." on 2026-10-15 20:08. The FIT is 4,155,676 B and carries the device tree
# as a subimage at offset 0x3F2BE4, so:
#     load at 0x10000000 -> fdt lands at 0x103F2BE4 = 260 MB   <- OUTSIDE mem=120M, kernel hangs
#     load at 0x01000000 -> fdt lands at 0x013F2BE4 =  20 MB   <- inside  mem=120M, fine
# fdt_high=0xffffffff stops U-Boot relocating the DTB to the top of RAM (measured earlier:
# "Loading Device Tree to 1fff9000" = 512 MB, equally unreachable under the cap), so with the
# low load address the DTB is used exactly where the FIT put it. Kernel entry is 0x8000 and the
# kernel image is ~4 MB, so neither overlaps the FIT at 16 MB.
Ask "fatload mmc 0:1 0x01000000 image.ub" 6000 | Out-Null
Ask "setenv fdt_high 0xffffffff" 600 | Out-Null
Ask "setenv devicetree_load_address 0x01000000" 600 | Out-Null
# cma=48M: the DPU driver backs its tensors with CMA (the DTB declares an xlnk node, and the
# delivery bootargs carried cma=256M - but 256M cannot fit inside mem=120M). CMA is carved out
# of the 120 MB, leaving ~72 MB for the rescue shell + app, which is ample. VERIFY CmaTotal in
# the "kernel+mem" step below: if it reads 0 the DPU will fail to allocate.
Ask "setenv bootargs console=ttyPS0,115200 earlyprintk root=/dev/mmcblk0p2 rw rootfstype=ext4 rootwait init=/bin/sh mem=120M cma=48M" 900 | Out-Null
Ask "bootm 0x01000000" 1500 | Out-Null
$bootlog = Drain 90000
Show "boot" $bootlog 25

# Fail fast instead of firing four minutes of commands into a dead console. The 20:08 run
# looked "busy" for 5 minutes while the kernel had in fact hung before the shell ever existed.
Ask "" 1500 | Out-Null
if ((Ask "echo DSH_ALIVE" 2500) -notmatch 'DSH_ALIVE') {
    Write-Host "!! the kernel never reached a shell - no point continuing"
    ($bootlog -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } | Select-Object -Last 12 | ForEach-Object { Write-Host "   $_" }
    Write-Host "log: $log"; $sw.Close(); $sp.Close(); exit 3
}
Ask "export PATH=/sbin:/bin:/usr/sbin:/usr/bin; mount -t proc proc /proc; mount -t sysfs sysfs /sys; mount -t devtmpfs devtmpfs /dev" 1500 | Out-Null
Ask "ifconfig eth0 $BoardIp netmask 255.255.255.0 up" 3500 | Out-Null
Show "kernel+mem" (Ask "uname -r; cat /proc/cmdline; grep -E 'MemTotal|MemFree|CmaTotal|CmaFree' /proc/meminfo" 2500) 6
Show "cma" (Ask "dmesg | grep -i -E 'cma|Memory:' | head -6; echo s5" 3000) 7

Write-Host "=== load the UNIFIED bitstream (camera + DPU, colour-fixed) ==="
Ask "mkdir -p /lib/firmware /www" 800 | Out-Null
Show "upload" (Ask "wget -O /lib/firmware/dpu.bin http://${HostIp}:${HttpPort}/unified_color_sw.bin 2>&1 | tail -1; md5sum /lib/firmware/dpu.bin" 30000) 2
Send "echo dpu.bin > /sys/class/fpga_manager/fpga0/firmware`n"; Start-Sleep -Seconds 9
Show "fpga state" (Ask "cat /sys/class/fpga_manager/fpga0/state" 2000) 2

Write-Host "=== clocks: FCLK0 = 0x00201400 (50.000 MHz) + PL reset ==="
Show "clocks" (Ask "busybox devmem 0xF8000008 32 0xDF0D; busybox devmem 0xF8000170 32 0x00201400; busybox devmem 0xF800012C 32 0x01E00C40; busybox devmem 0xF8000240 32 0x0000000F; sleep 1; busybox devmem 0xF8000240 32 0x00000000; busybox devmem 0xF8000004 32 0x767B; echo FCLK0=`$(busybox devmem 0xF8000170) done" 4000) 2
Start-Sleep -Seconds 6

Write-Host "=== A) camera half: is it producing frames? ==="
Show "debug word" (Ask "echo CAM=`$(busybox devmem 0x41220000) W0=`$(busybox devmem 0x08000000) MID=`$(busybox devmem 0x08040000) s1" 3000) 2

Write-Host "=== B) DPU half: signatures, driver, and does it compute? ==="
Show "signatures" (Ask "echo ID=`$(busybox devmem 0x40000000) SIG=`$(busybox devmem 0x40f00000) s2" 3500) 2
Show "insmod" (Ask "insmod /home/root/dpu.ko 2>&1; echo rc=`$?; ls -l /dev/dpu; echo s3" 3500) 3
$o = Ask "cd /home/root/d3 && timeout 120 ./tiny_yolo_image_diag4 dog.jpg 2>&1 | grep -E 'Class name|DETERM_CHECK|BOXES|mismatch|timeout'; echo s4" 140000
Show "DPU on a file image (sanity)" $o 12

Write-Host "=== C) the CLOSED LOOP: live camera frame -> DPU ==="
Ask "cd /home/root && (netstat -lnt 2>/dev/null | grep -q 8080) || httpd -p 8080 -h /www" 2000 | Out-Null
for ($i = 1; $i -le $Iterations; $i++) {
    Write-Host ("--- iteration {0}/{1} ---" -f $i, $Iterations)
    $t0 = Get-Date

    # 1) camera frame out of DDR
    Ask "python3 /dump_frame.py /www/frame.raw 1476000 2>&1 | tail -1" 20000 | Out-Null
    $rawPc = Join-Path $dir 'd4_frame.raw'
    & curl.exe -s -o $rawPc --max-time 40 "http://${BoardIp}:8080/frame.raw" 2>&1 | Out-Null
    if (-not (Test-Path $rawPc) -or (Get-Item $rawPc).Length -lt 1476000) {
        Write-Host "   frame fetch failed"; Start-Sleep -Seconds 3; continue
    }

    # 2) PC turns RGB565 into a JPG the app can read
    $jpgPc = Join-Path $dir 'd4_frame.jpg'
    $cargs = @((Join-Path $dir 'raw565_to_jpg.py'), $rawPc, $jpgPc, '1025', '720')
    if ($SwapRB) { $cargs += '--swap-rb' }
    $conv = & $py @cargs 2>&1 | Select-Object -Last 1
    Write-Host "   convert: $conv"

    # 3) hand the frame to the app and infer. The board has no upload endpoint, so the frame
    # goes back out through the PC's own HTTP server rather than a POST to the board's httpd
    # (that POST used to burn a 60 s curl timeout every iteration for nothing).
    Send "wget -q -O /home/root/d3/live.jpg http://${HostIp}:${HttpPort}/d4_frame.jpg; ls -l /home/root/d3/live.jpg`n"
    Drain 15000 | Out-Null
    $res = Ask "cd /home/root/d3 && timeout 120 ./tiny_yolo_image_diag4 live.jpg 2>&1 | grep -E 'Class name|DETERM_CHECK|BOXES|IMAGE_INFO|RESULT_SAVED|mismatch'; echo loop$i" 140000
    ($res -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -match 'Class name|BOXES|DETERM_CHECK|IMAGE_INFO|RESULT_SAVED' } | ForEach-Object { Write-Host ("   " + $_) }

    # 4) publish the annotated result and fetch it back. The app always writes the absolute
    # paths /home/root/result.jpg + .bmp (seen as RESULT_SAVED in earlier runs), so the source
    # is /home/root/result.jpg no matter which directory it was invoked from.
    Ask "cp /home/root/result.jpg /www/result.jpg 2>/dev/null; ls -l /www/result.jpg /home/root/result.jpg 2>/dev/null; echo r$i" 2000 | Out-Null
    $outPc = Join-Path $dir ("d4_result_{0}.jpg" -f $i)
    Remove-Item $outPc -ErrorAction SilentlyContinue
    & curl.exe -s -o $outPc --max-time 40 "http://${BoardIp}:8080/result.jpg" 2>&1 | Out-Null
    if ((Test-Path $outPc) -and (Get-Item $outPc).Length -gt 1000) {
        Write-Host ("   result image: {0} ({1} bytes)" -f $outPc, (Get-Item $outPc).Length)
    } else { Write-Host "   result image: NOT retrieved" }
    Write-Host ("   took {0:N1}s" -f ((Get-Date) - $t0).TotalSeconds)
}

Write-Host ""; Write-Host "log: $log"
$sw.Close(); $sp.Close()

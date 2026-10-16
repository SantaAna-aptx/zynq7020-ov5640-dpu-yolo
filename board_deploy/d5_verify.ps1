# d5_verify.ps1 -- verify a newly built unified bitstream IN PLACE, with no power cycle.
#
# The board is already booted (mem=120M cma=48M) at a root shell, so a bitstream swap is just
# fpga_manager + the clock recipe + a driver reload. That makes each build testable in ~3 minutes
# instead of a power cycle round trip.
#
# Checks, in order:
#   1. the DPU reports its own feature set via `dexplorer -w` - this is what rejected the old
#      bitstream ("Conv+Leakyrelu, DPU kernel: Enabled, DPU IP: Disabled")
#   2. the app reproduces the 8/8 reference on dog.jpg: identical=1, BOXES raw=6 after_nms=3
#   3. the camera half is still alive after the DPU fix (debug word + non-zero frame data)
#   4. the full closed loop: live camera frame -> PC RGB565->JPG -> DPU -> annotated result back
param(
  [string]$Bin     = 'unified_dpufix_sw.bin',
  [string]$BinMd5  = '',
  [string]$Port    = 'COM10',
  [string]$HostIp  = '192.168.1.100',
  [int]$HttpPort   = 8000,
  [int]$Iterations = 2
)
$dir = 'E:\yoloProject\board_deploy'
$log = Join-Path $dir ("d5_verify_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$sw  = New-Object System.IO.StreamWriter($log, $false); $sw.AutoFlush = $true
$sp  = New-Object System.IO.Ports.SerialPort $Port,115200,None,8,one
$sp.ReadTimeout = 500
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

try { $sp.Open() } catch { Write-Host "!! COM10: $($_.Exception.Message)"; $sw.Close(); exit 2 }
Drain 800 | Out-Null
if ((Ask "echo V5_ALIVE" 2500) -notmatch 'V5_ALIVE') {
    Write-Host "!! no shell prompt - power cycle the board, boot it, then re-run this script"
    $sw.Close(); $sp.Close(); exit 3
}
Ask "export PATH=/sbin:/bin:/usr/sbin:/usr/bin; mount -t proc proc /proc 2>/dev/null; mount -t sysfs sysfs /sys 2>/dev/null; mount -t devtmpfs devtmpfs /dev 2>/dev/null; mkdir -p /lib/firmware /www; echo ready" 2500 | Out-Null
Show "mem" (Ask "cat /proc/cmdline; grep -E 'MemTotal|CmaTotal' /proc/meminfo" 2000) 4

# ---------------- load the new bitstream ----------------
Write-Host ""
Write-Host "==================== loading $Bin ===================="
Show "fetch" (Ask "wget -O /lib/firmware/dpu.bin http://${HostIp}:${HttpPort}/$Bin 2>&1 | tail -1; md5sum /lib/firmware/dpu.bin" 30000) 3
Ask "rmmod dpu 2>/dev/null; echo rmmod_ok" 2500 | Out-Null
Send "echo dpu.bin > /sys/class/fpga_manager/fpga0/firmware`n"; Start-Sleep -Seconds 9
Show "fpga state" (Ask "cat /sys/class/fpga_manager/fpga0/state" 2000) 2

# FCLK0 = 0x00201400 -> 50.000 MHz exactly. Without it the DPU's MMCM never locks and the compute
# domain is dead while S_AXI still answers (see FCLK0_ROOT_CAUSE.md).
Show "clocks" (Ask "busybox devmem 0xF8000008 32 0xDF0D; busybox devmem 0xF8000170 32 0x00201400; busybox devmem 0xF800012C 32 0x01E00C40; busybox devmem 0xF8000240 32 0x0000000F; sleep 1; busybox devmem 0xF8000240 32 0x00000000; busybox devmem 0xF8000004 32 0x767B; echo FCLK0=`$(busybox devmem 0xF8000170) done" 4000) 2
Start-Sleep -Seconds 6

Show "signatures" (Ask "echo ID=`$(busybox devmem 0x40000000) SIG=`$(busybox devmem 0x40f00000) s" 3000) 2
Show "insmod" (Ask "insmod /home/root/dpu.ko 2>&1; echo rc=`$?; ls -l /dev/dpu" 3500) 3

# ---------------- 1) the DPU's own feature report ----------------
Write-Host ""
Write-Host "=== CHECK 1: dexplorer -w (the feature set that rejected the old bitstream) ==="
$dex = Ask "cd /home/root/dpu && ./dexplorer -w 2>&1; echo DEX_DONE" 8000
Show "dexplorer" $dex 30
$flags = @{}
($dex -split "`n") | ForEach-Object {
    if ($_ -match '^\s*(Conv\+Leakyrelu|Conv\+Relu6|Channel Augmentation|Average Pool|DepthwiseConv\+Relu6|DepthwiseConv)\s*:\s*(\S+)') {
        $flags[$Matches[1]] = $Matches[2]
    }
}
$allGood = $true
foreach ($k in @('DepthwiseConv','DepthwiseConv+Relu6','Conv+Leakyrelu','Conv+Relu6','Channel Augmentation','Average Pool')) {
    $val = if ($flags.ContainsKey($k)) { $flags[$k] } else { 'MISSING' }
    $mark = if ($val -eq 'Enabled') { 'OK  ' } else { $allGood = $false; 'FAIL' }
    Write-Host ("   $mark  {0,-24} {1}" -f $k, $val)
}
if (-not $allGood) { Write-Host "!! the DPU feature set is still wrong - stopping"; $sw.Close(); $sp.Close(); exit 4 }

# ---------------- 2) the app must reproduce the 8/8 reference ----------------
Write-Host ""
Write-Host "=== CHECK 2: tiny_yolo_image_diag4 dog.jpg (reference: identical=1, raw=6 nms=3) ==="
$o = Ask "cd /home/root/d3 && timeout 120 ./tiny_yolo_image_diag4 dog.jpg 2>&1 | grep -E 'Class name|DETERM_CHECK|BOXES|RESULT_SAVED|mismatch'; echo app_done" 140000
Show "app" $o 20
$ident = if ($o -match 'identical=1') { 'PASS' } else { 'FAIL' }
$boxes = if ($o -match 'raw=6 after_nms=3') { 'PASS' } else { 'FAIL' }
Write-Host "   determinism: $ident    boxes raw=6/nms=3: $boxes"

# ---------------- 3) the camera half, in the same bitstream ----------------
Write-Host ""
Write-Host "=== CHECK 3: camera alive in the same bitstream ==="
$cam = Ask "echo CAM=`$(busybox devmem 0x41220000) W0=`$(busybox devmem 0x08000000) MID=`$(busybox devmem 0x08040000) s" 3000
Show "camera" $cam 3

# ---------------- 4) the closed loop ----------------
Write-Host ""
Write-Host "=== CHECK 4: live camera frame -> DPU -> annotated result ==="
Ask "cd /home/root && (netstat -lnt 2>/dev/null | grep -q 8080) || httpd -p 8080 -h /www" 2000 | Out-Null
for ($i = 1; $i -le $Iterations; $i++) {
    Write-Host ("--- iteration {0}/{1} ---" -f $i, $Iterations)
    $t0 = Get-Date
    Ask "python3 /dump_frame.py /www/frame.raw 1476000 2>&1 | tail -1" 20000 | Out-Null
    $rawPc = Join-Path $dir 'd5_frame.raw'
    Remove-Item $rawPc -ErrorAction SilentlyContinue
    & curl.exe -s -o $rawPc --max-time 40 "http://192.168.1.50:8080/frame.raw" 2>&1 | Out-Null
    if (-not (Test-Path $rawPc) -or (Get-Item $rawPc).Length -lt 1476000) {
        Write-Host "   frame fetch failed"; continue
    }
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
    & curl.exe -s -o $outPc --max-time 40 "http://192.168.1.50:8080/result.jpg" 2>&1 | Out-Null
    if ((Test-Path $outPc) -and (Get-Item $outPc).Length -gt 1000) {
        Write-Host ("   result image: {0} ({1} bytes)" -f $outPc, (Get-Item $outPc).Length)
    } else { Write-Host "   result image: NOT retrieved" }
    Write-Host ("   took {0:N1}s" -f ((Get-Date) - $t0).TotalSeconds)
}

Write-Host ""
Write-Host "log: $log"
$sw.Close(); $sp.Close()

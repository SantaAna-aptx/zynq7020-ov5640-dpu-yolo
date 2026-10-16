# dpu_arch_probe.ps1 -- no power cycle needed. The board is already up at a root shell with the
# unified bitstream loaded, so this switches bitstreams in place and reads the DPU's own idea of
# its architecture under each one.
#
# Purpose: prove (a) that dpu_fclk0.bin - the D3 bitstream that scored 8/8 - still runs the app
# perfectly on THIS kernel with mem=120M cma=48M, and (b) exactly which features the unified
# bitstream is missing. That turns "Conv+Leakyrelu Disabled" into a concrete parameter to fix
# before spending 40 minutes on a rebuild.
param(
  [string]$Port    = 'COM10',
  [string]$HostIp  = '192.168.1.100',
  [int]$HttpPort   = 8000
)
$dir = 'E:\yoloProject\board_deploy'
$log = Join-Path $dir ("dpu_arch_probe_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$sw  = New-Object System.IO.StreamWriter($log, $false); $sw.AutoFlush = $true
$sp  = New-Object System.IO.Ports.SerialPort $Port,115200,None,8,one
$sp.ReadTimeout = 500
$script:buf = ""

function Raw { try { $d = $sp.ReadExisting() } catch { $d = "" }; if ($d) { $script:buf += $d; $sw.Write($d) }; return $d }
function Drain([int]$ms) { $t=(Get-Date).AddMilliseconds($ms); $o=""; while ((Get-Date) -lt $t) { $o += (Raw); Start-Sleep -Milliseconds 20 }; return $o }
function Ask([string]$c,[int]$w=3000){ Send ($c + "`n"); return (Drain $w) }
function Send([string]$s) { try { $sp.Write($s) } catch { } }
function Block([string]$title,[string]$cmd,[int]$w,[string[]]$keep){
    Write-Host "--- $title ---"
    $o = Ask $cmd $w
    ($o -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } | ForEach-Object {
        $line = $_
        foreach ($k in $keep) { if ($line -match $k) { Write-Host ("   " + $line); break } }
    }
    return $o
}

try { $sp.Open() } catch { Write-Host "!! COM10: $($_.Exception.Message)"; $sw.Close(); exit 2 }
Drain 800 | Out-Null

if ((Ask "echo PROBE_ALIVE" 2500) -notmatch 'PROBE_ALIVE') {
    Write-Host "!! no shell - the board is not at a prompt; power cycle and re-run"
    $sw.Close(); $sp.Close(); exit 3
}
Ask "export PATH=/sbin:/bin:/usr/sbin:/usr/bin; mount -t proc proc /proc 2>/dev/null; mount -t sysfs sysfs /sys 2>/dev/null; mount -t devtmpfs devtmpfs /dev 2>/dev/null; mkdir -p /lib/firmware /www; echo ready" 2500 | Out-Null

# The clock recipe is needed after EVERY bitstream load: without the PL reset pulse the DPU's MMCM
# never re-locks, and without FCLK0 = 0x00201400 (50.000 MHz) the compute domain is dead. Both are
# the hard-won result recorded in FCLK0_ROOT_CAUSE.md.
function LoadBit([string]$bin,[string]$md5){
    Write-Host ""
    Write-Host "==================== $bin ===================="
    Block "fetch" ("wget -O /lib/firmware/probe.bin http://${HostIp}:${HttpPort}/$bin 2>&1 | tail -2; md5sum /lib/firmware/probe.bin; echo got") 25000 @('probe\.bin','got','md5','[0-9a-f]{32}') | Out-Null
    Ask "rmmod dpu 2>/dev/null; echo rmmod_done" 2500 | Out-Null
    Send "echo probe.bin > /sys/class/fpga_manager/fpga0/firmware`n"; Start-Sleep -Seconds 9
    Block "fpga state" "cat /sys/class/fpga_manager/fpga0/state; echo st" 2000 @('operating','st') | Out-Null
    Block "clocks" "busybox devmem 0xF8000008 32 0xDF0D; busybox devmem 0xF8000170 32 0x00201400; busybox devmem 0xF800012C 32 0x01E00C40; busybox devmem 0xF8000240 32 0x0000000F; sleep 1; busybox devmem 0xF8000240 32 0x00000000; busybox devmem 0xF8000004 32 0x767B; echo FCLK0=`$(busybox devmem 0xF8000170) done" 4000 @('FCLK0','done') | Out-Null
    Start-Sleep -Seconds 5
    Block "signatures" "echo ID=`$(busybox devmem 0x40000000) SIG=`$(busybox devmem 0x40f00000) s" 3000 @('ID=|s') | Out-Null
    Block "insmod" "insmod /home/root/dpu.ko 2>&1; echo rc=`$?; ls -l /dev/dpu; echo ins_done" 3500 @('rc=|dev\/dpu|ins_done') | Out-Null
    Write-Host "--- dexplorer -w (the DPU reports its own feature set) ---"
    $o = Ask "cd /home/root/dpu && ./dexplorer -w 2>&1; echo DEX_DONE" 8000
    ($o -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' -and $_ -notmatch '^cd /home/root' } | ForEach-Object { Write-Host ("   " + $_) }
    return $o
}

# ---------- 1) the known-good D3 bitstream as a control ----------
$d3 = LoadBit 'dpu_fclk0.bin' '21db5b59125b4c35e860072f5b1e3c8f'
Block "D3 control: app on dog.jpg" "cd /home/root/d3 && timeout 90 ./tiny_yolo_image_diag4 dog.jpg 2>&1 | grep -E 'Class name|DETERM_CHECK|BOXES|IMAGE_INFO|RESULT_SAVED|mismatch'; echo ctl_done" 120000 @('Class name|DETERM_CHECK|BOXES|IMAGE_INFO|RESULT_SAVED|mismatch|ctl_done') | Out-Null

# ---------- 2) the unified bitstream under the same microscope ----------
$uni = LoadBit 'unified_color_sw.bin' 'a050ac24f39d6659cbd8b2d6241d0a52'
Block "unified: app on dog.jpg" "cd /home/root/d3 && timeout 90 ./tiny_yolo_image_diag4 dog.jpg 2>&1 | grep -E 'Class name|DETERM_CHECK|BOXES|IMAGE_INFO|RESULT_SAVED|mismatch'; echo uni_done" 120000 @('Class name|DETERM_CHECK|BOXES|IMAGE_INFO|RESULT_SAVED|mismatch|uni_done') | Out-Null

Write-Host ""
Write-Host "log: $log"
$sw.Close(); $sp.Close()

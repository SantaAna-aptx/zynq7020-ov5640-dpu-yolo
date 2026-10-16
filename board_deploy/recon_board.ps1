# recon_board.ps1 -- gather everything needed to decide how to build an on-board realtime
# camera + DPU streaming app. Read-only: it only lists and inspects.
param(
  [string]$Port = 'COM10',
  [string]$Log  = 'E:\yoloProject\board_deploy\recon_board.log'
)
$sw = New-Object System.IO.StreamWriter($Log, $false); $sw.AutoFlush = $true
$sp = New-Object System.IO.Ports.SerialPort $Port,115200,None,8,one
$sp.ReadTimeout = 400
$script:buf = ""

function Raw { try { $d = $sp.ReadExisting() } catch { $d = "" }; if ($d) { $script:buf += $d; $sw.Write($d) }; return $d }
function Drain([int]$ms) { $t=(Get-Date).AddMilliseconds($ms); $o=""; while ((Get-Date) -lt $t) { $o += (Raw); Start-Sleep -Milliseconds 20 }; return $o }
function Send([string]$s) { try { $sp.Write($s) } catch { } }
function Ask([string]$c,[int]$w=4000){ Send ($c + "`n"); return (Drain $w) }
function Section([string]$title,[string]$cmd,[int]$w=4000){
    Write-Host ""
    Write-Host ("========== " + $title + " ==========")
    $o = Ask $cmd $w
    ($o -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } | ForEach-Object { Write-Host ("  " + $_) }
}

try { $sp.Open() } catch { Write-Host "!! $Port : $($_.Exception.Message)"; $sw.Close(); exit 2 }
Drain 600 | Out-Null
Send "`r"; Start-Sleep -Milliseconds 400
if ((Ask "echo RECON_OK" 2500) -notmatch 'RECON_OK') { Write-Host "!! no shell"; $sw.Close(); $sp.Close(); exit 3 }

Section "target files" "ls -la /home/root/d3/ 2>&1; echo ---- ; ls /home/root/*.elf /home/root/*.jpg 2>/dev/null | head -20; echo SEC_DONE" 5000

Section "n2cube / dputils libs" "ls -la /usr/lib/libn2cube* /usr/lib/libdputils* /lib/libn2cube* 2>&1; echo SEC_DONE" 4000

Section "jpeg / png / z libs" "ls -la /usr/lib/libjpeg* /usr/lib/libpng* /usr/lib/libz.so* 2>&1; echo SEC_DONE" 4000

Section "opencv libs" "ls /usr/lib/libopencv_* 2>/dev/null | head -40; echo ---- ; ls /usr/lib/libopencv_* 2>/dev/null | wc -l; echo SEC_DONE" 5000

Section "headers" "ls /usr/include/ 2>&1 | head -30; echo ---- ; ls -d /usr/include/opencv* /usr/include/n2cube.h 2>&1; echo SEC_DONE" 5000

Section "python3 modules" "python3 -c `"import sys;print('py',sys.version.split()[0])`" 2>&1; python3 -c `"import ctypes;print('ctypes OK')`" 2>&1; python3 -c `"import cv2;print('cv2',cv2.__version__)`" 2>&1 | head -3; python3 -c `"import numpy;print('numpy',numpy.__version__)`" 2>&1 | head -3; python3 -c `"from PIL import Image;print('PIL OK')`" 2>&1 | head -3; echo SEC_DONE" 12000

Section "cpu / mem / disk" "cat /proc/cpuinfo | grep -E 'model name|Processor|Features' | head -3; echo ---- ; head -3 /proc/meminfo; echo ---- ; df -h / /home 2>&1; echo SEC_DONE" 6000

Section "busybox httpd capabilities" "busybox httpd --help 2>&1 | head -20; echo ---- ; ls -la /usr/bin/python3 /bin/busybox 2>&1; echo SEC_DONE" 5000

Section "blocking io / dev/mem access" "ls -la /dev/mem 2>&1; echo ---- ; cat /proc/iomem 2>/dev/null | head -8; echo SEC_DONE" 4000

Write-Host ""
Write-Host ("log: " + $Log)
$sw.Close(); $sp.Close()

# bench_board.ps1 -- measure the handful of numbers that decide the streaming architecture.
param(
  [string]$Port = 'COM10',
  [string]$Log  = 'E:\yoloProject\board_deploy\bench_board.log'
)
$sw = New-Object System.IO.StreamWriter($Log, $false); $sw.AutoFlush = $true
$sp = New-Object System.IO.Ports.SerialPort $Port,115200,None,8,one
$sp.ReadTimeout = 400
$script:buf = ""

function Raw { try { $d = $sp.ReadExisting() } catch { $d = "" }; if ($d) { $script:buf += $d; $sw.Write($d) }; return $d }
function Drain([int]$ms) { $t=(Get-Date).AddMilliseconds($ms); $o=""; while ((Get-Date) -lt $t) { $o += (Raw); Start-Sleep -Milliseconds 20 }; return $o }
function Send([string]$s) { try { $sp.Write($s) } catch { } }
function Ask([string]$c,[int]$w=4000){ Send ($c + "`n"); return (Drain $w) }
function Section([string]$t,[string]$c,[int]$w=4000){
    Write-Host ""
    Write-Host ("========== " + $t + " ==========")
    $o = Ask $c $w
    ($o -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } | ForEach-Object { Write-Host ("  " + $_) }
}

try { $sp.Open() } catch { Write-Host "!! $Port : $($_.Exception.Message)"; $sw.Close(); exit 2 }
Drain 600 | Out-Null
Send "`r"; Start-Sleep -Milliseconds 400
if ((Ask "echo BENCH_OK" 2500) -notmatch 'BENCH_OK') { Write-Host "!! no shell"; $sw.Close(); $sp.Close(); exit 3 }

Section "A) app single-run cost (includes model load)" "cd /home/root/d3 && time ./tiny_yolo_image_diag4 dog.jpg > /dev/null 2>&1; echo SEC_DONE" 25000

Section "B) tmpfs / shm availability" "ls -ld /dev/shm 2>&1; echo ---- ; mount | grep -iE 'tmpfs|shm' ; echo ---- ; df -h /dev/shm 2>&1; echo SEC_DONE" 5000

Section "C) numpy RGB565->BGR + cv2 imencode cost (the per-frame CPU work)" "python3 -c `"
import numpy as np, cv2, time
n=1025*720
raw=np.random.randint(0,65535,n,dtype=np.uint16)
t=time.time()
for _ in range(5):
    r=((raw>>11)&0x1f).astype(np.uint8); g=((raw>>5)&0x3f).astype(np.uint8); b=(raw&0x1f).astype(np.uint8)
    img=np.dstack([b*255//31,g*255//63,r*255//31])
print('rgb565->bgr : %.3f s/frame'%((time.time()-t)/5))
t=time.time()
for _ in range(5):
    ok,buf=cv2.imencode('.jpg',img,[cv2.IMWRITE_JPEG_QUALITY,80])
print('imencode    : %.3f s/frame, %d bytes'%((time.time()-t)/5,len(buf)))
t=time.time()
for _ in range(5):
    cv2.resize(img,(640,360))
print('resize 640  : %.3f s/frame'%((time.time()-t)/5))
echo=0
`" 2>&1; echo SEC_DONE" 60000

Section "D) reading the DDR frame via /dev/mem" "python3 -c `"
import mmap,os,time,struct
fd=os.open('/dev/mem',os.O_RDONLY|os.O_SYNC)
m=mmap.mmap(fd,1476000,mmap.MAP_SHARED,mmap.PROT_READ,offset=0x08000000)
t=time.time()
for _ in range(5): d=m[:1476000]
print('devmem read : %.3f s/frame, first=%s'%((time.time()-t)/5,d[:8].hex()))
m.close(); os.close(fd)
`" 2>&1; echo SEC_DONE" 30000

Section "E) free memory + /www" "free 2>/dev/null || cat /proc/meminfo | head -3; echo ---- ; ls -la /www 2>&1 | head -8; echo SEC_DONE" 5000

Write-Host ""
Write-Host ("log: " + $Log)
$sw.Close(); $sp.Close()

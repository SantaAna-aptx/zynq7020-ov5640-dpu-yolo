# collect_sysroot.ps1 -- pull the OpenCV headers and the shared libraries off the board so the
# Windows ARM cross compiler can build against exactly the versions the board runs.
#
# Why from the board and not from anywhere else: the app links libopencv_*.so.3.4 and the board's
# libn2cube.so is 154,156 bytes while the PC SDK copy is 193,272 - different builds. Linking
# against the board's own copies removes any soname/symbol drift.
param(
  [string]$Port   = 'COM10',
  [string]$HostIp = '192.168.1.100',
  [string]$BoardIp= '192.168.1.50',
  [int]$HttpPort  = 8000
)
$dir = 'E:\yoloProject\board_deploy'
$out = Join-Path $dir 'sysroot_arm'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$log = Join-Path $dir ("collect_sysroot_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$sw  = New-Object System.IO.StreamWriter($log, $false); $sw.AutoFlush = $true
$sp  = New-Object System.IO.Ports.SerialPort $Port,115200,None,8,one
$sp.ReadTimeout = 300
$script:buf = ""

function Raw { try { $d = $sp.ReadExisting() } catch { $d = "" }; if ($d) { $script:buf += $d; $sw.Write($d) }; return $d }
function Drain([int]$ms) { $t=(Get-Date).AddMilliseconds($ms); $o=""; while ((Get-Date) -lt $t) { $o += (Raw); Start-Sleep -Milliseconds 20 }; return $o }
function Send([string]$s) { try { $sp.Write($s) } catch { } }
function AskWait([string]$cmd,[string]$marker,[int]$count=2,[int]$maxMs=60000){
    Send ($cmd + "`n")
    $t = (Get-Date).AddMilliseconds($maxMs); $o = ""
    while ((Get-Date) -lt $t) {
        $o += (Raw)
        if (([regex]::Matches($o,[regex]::Escape($marker))).Count -ge $count) { break }
        Start-Sleep -Milliseconds 100
    }
    $o += (Drain 500)
    return $o
}
function Show([string]$t,[string]$o,[int]$n=20){
    Write-Host "--- $t ---"
    ($o -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } |
        Select-Object -Last $n | ForEach-Object { Write-Host ("   " + $_) }
}

try { $sp.Open() } catch { Write-Host "!! $Port : $($_.Exception.Message)"; $sw.Close(); exit 2 }
Drain 600 | Out-Null
Send "`r"; Start-Sleep -Milliseconds 400
if ((AskWait "echo CS_ALIVE" "CS_ALIVE" 2 6000) -notmatch 'CS_ALIVE') { Write-Host "!! no shell"; $sw.Close(); $sp.Close(); exit 3 }

# --- 1) headers: opencv + opencv2 (the board has them; the PC toolchain does not) ---
Write-Host "=== packing headers on the board ==="
Show "tar headers" (AskWait "mkdir -p /www && cd /usr/include && tar czf /www/inc.tgz opencv opencv2 2>&1 | tail -3; ls -l /www/inc.tgz; echo INC_DONE" "INC_DONE" 2 90000) 4

# --- 2) libraries: cp -L dereferences the version symlinks so we get real bytes under the plain
#        .so name the linker wants (-lopencv_core looks for libopencv_core.so). Plain tar packed
#        the symlinks themselves (0-byte entries), which is useless for linking.
Write-Host ""
Write-Host "=== packing libraries on the board (dereferenced) ==="
$libCmd = 'rm -rf /home/root/sysroot; mkdir -p /home/root/sysroot/usr/lib; L=/home/root/sysroot/usr/lib; ' +
          'cp -L /usr/lib/libn2cube.so /usr/lib/libdputils.so /usr/lib/libhineon.so $L/; ' +
          'cp -L /usr/lib/libopencv_core.so $L/; cp -L /usr/lib/libopencv_imgproc.so $L/; cp -L /usr/lib/libopencv_imgcodecs.so $L/; ' +
          'cp -L /usr/lib/libjpeg.so $L/ 2>/dev/null; cp -L /usr/lib/libz.so $L/ 2>/dev/null; ' +
          'ls -la $L; tar czf /www/libs2.tgz -C /home/root/sysroot .; ls -l /www/libs2.tgz; echo LIBS_DONE'
Show "tar libs" (AskWait $libCmd "LIBS_DONE" 2 90000) 20

# --- 3) also the real .so files behind the soname symlinks (tar -h dereferences) ---
Show "lib inventory" (AskWait "ls -l /usr/lib/libn2cube.so /usr/lib/libopencv_core.so.3.4 /lib/libc.so.6 2>&1; echo INV_DONE" "INV_DONE" 2 6000) 6

# --- 4) fetch both archives over HTTP ---
Write-Host ""
Write-Host "=== downloading archives to the PC ==="
foreach ($a in @(@('inc.tgz','inc.tgz'), @('libs2.tgz','libs2.tgz'))) {
    $dst = Join-Path $out $a[1]
    Remove-Item $dst -ErrorAction SilentlyContinue
    & curl.exe -s -o $dst --max-time 180 "http://${BoardIp}:8080/$($a[0])" 2>&1 | Out-Null
    if ((Test-Path $dst) -and ((Get-Item $dst).Length -gt 1000)) {
        Write-Host ("   {0}  {1} bytes" -f $a[1], (Get-Item $dst).Length)
    } else { Write-Host ("   {0}  FETCH FAILED" -f $a[1]) }
}

Write-Host ""
Write-Host ("sysroot dir: " + $out)
Write-Host ("log: " + $log)
$sw.Close(); $sp.Close()

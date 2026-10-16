# measure_cam_fps.ps1 -- measure the camera's real frame rate by watching the line counter wrap.
#
# Why it matters for the optimisation plan: cam_stream spends 59 ms per iteration in
# wait_frame_start(), which is "wait for the next frame boundary". That cost is set by the camera's
# frame period, not by our code. If the sensor is running at ~8 fps it is an immovable floor and the
# whole pipeline cannot exceed that; if it is running near 30 fps then the wait could be shortened.
param(
  [string]$Port = 'COM10',
  [string]$Log  = 'E:\yoloProject\board_deploy\measure_cam_fps.log'
)
$sw = New-Object System.IO.StreamWriter($Log, $false); $sw.AutoFlush = $true
$sp = New-Object System.IO.Ports.SerialPort $Port,115200,None,8,one
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

try { $sp.Open() } catch { Write-Host "!! $Port : $($_.Exception.Message)"; $sw.Close(); exit 2 }
Drain 600 | Out-Null
Send "`r"; Start-Sleep -Milliseconds 400
if ((AskWait "echo MF_ALIVE" "MF_ALIVE" 2 6000) -notmatch 'MF_ALIVE') { Write-Host "!! no shell"; $sw.Close(); $sp.Close(); exit 3 }

# Poll the line counter for 6 s and count wraps. Also sample the distribution of values so we can
# see how long the "at the start of a frame" window actually is.
$py = @'
import mmap, os, struct, time
fd = os.open("/dev/mem", os.O_RDONLY | os.O_SYNC)
m = mmap.mmap(fd, 4096, mmap.MAP_SHARED, mmap.PROT_READ, offset=0x41220000)
prev = struct.unpack("<I", m[:4])[0]
wraps = 0
vals = {}
t0 = time.time()
n = 0
while time.time() - t0 < 6.0:
    cur = struct.unpack("<I", m[:4])[0]
    vals[cur] = vals.get(cur, 0) + 1
    if cur < prev:
        wraps += 1
    prev = cur
    n += 1
dur = time.time() - t0
print("samples      : %d (%.1f us apart)" % (n, dur / n * 1e6))
print("wraps        : %d in %.2f s" % (wraps, dur))
if wraps:
    print("frame period : %.2f ms -> %.2f fps" % (dur / wraps * 1000.0, wraps / dur))
print("line-counter values seen (value:count):")
for k in sorted(vals):
    print("   %3d : %d" % (k, vals[k]))
m.close(); os.close(fd)
'@
$pyCorr = $py -replace "`r",""
$b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pyCorr))
Write-Host "=== uploading measurement script ==="
AskWait ("echo " + $b64 + " | base64 -d > /home/root/mf.py; wc -c /home/root/mf.py; echo UP_DONE") "UP_DONE" 2 30000 | Out-Null

Write-Host "=== measuring (6 s of line-counter polling) ==="
$o = AskWait "cd /home/root && python3 mf.py; echo MF_DONE" "MF_DONE" 2 30000
($o -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' -and $_ -notmatch 'python3 mf.py' } | ForEach-Object { Write-Host ("  " + $_) }

Write-Host ""
Write-Host ("log: " + $Log)
$sw.Close(); $sp.Close()

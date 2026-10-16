# deploy_stream.ps1 -- push cam_stream to the board and start it as a resident service.
#
# The program runs forever, so it is started in the background and its log is polled instead of
# waiting for it to exit.
#
# Note on port 8080: the earlier verification loops used busybox httpd on 8080 to move frames
# around. cam_stream wants that port for its own M-JPEG server, so any httpd is killed first.
param(
  [string]$Port   = 'COM10',
  [string]$HostIp = '192.168.1.100',
  [int]$HttpPort  = 8000,
  [string]$Remote = '/home/root',
  [int]$WaitSec   = 12
)
$dir = 'E:\yoloProject\board_deploy'
$log = Join-Path $dir ("deploy_stream_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
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
function Show([string]$t,[string]$o,[int]$n=25){
    Write-Host "--- $t ---"
    ($o -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } |
        Select-Object -Last $n | ForEach-Object { Write-Host ("   " + $_) }
}

try { $sp.Open() } catch { Write-Host "!! $Port : $($_.Exception.Message)"; $sw.Close(); exit 2 }
Drain 600 | Out-Null
Send "`r"; Start-Sleep -Milliseconds 400
if ((AskWait "echo DS_ALIVE" "DS_ALIVE" 2 6000) -notmatch 'DS_ALIVE') { Write-Host "!! no shell"; $sw.Close(); $sp.Close(); exit 3 }

Write-Host "=== 1) board state: bitstream / driver / camera ==="
Show "state" (AskWait "cat /sys/class/fpga_manager/fpga0/state 2>&1; ls -l /dev/dpu 2>&1; echo CAM=`$(busybox devmem 0x41220000); echo STATE_DONE" "STATE_DONE" 2 8000) 6

Write-Host ""
Write-Host "=== 2) free port 8080 (old cam_stream instance or busybox httpd) ==="
Show "kill old" (AskWait "killall cam_stream 2>/dev/null; killall httpd 2>/dev/null; sleep 2; netstat -lnt 2>/dev/null | grep 8080 || echo PORT_8080_FREE; echo KILL_DONE" "KILL_DONE" 2 10000) 5

Write-Host ""
Write-Host "=== 3) push cam_stream and start it in the background ==="
Show "fetch" (AskWait "cd $Remote && wget -q -O cam_stream http://${HostIp}:${HttpPort}/cam_stream; ls -l cam_stream; chmod +x cam_stream; echo FETCH_DONE" "FETCH_DONE" 2 60000) 4

Show "start" (AskWait "cd $Remote && ./cam_stream > $Remote/cam.log 2>&1 & echo STARTED_PID=`$!" "STARTED_PID" 2 12000) 4

Write-Host ""
Write-Host ("=== 4) wait " + $WaitSec + " s then read the program log ===")
Start-Sleep -Seconds $WaitSec
Show "cam.log" (AskWait "cat $Remote/cam.log | tail -25; echo LOG_DONE" "LOG_DONE" 2 10000) 26

Show "listening" (AskWait "netstat -lnt 2>/dev/null | grep 8080 || echo NOT_LISTENING; echo NET_DONE" "NET_DONE" 2 8000) 5

Write-Host ""
Write-Host "=== 5) pull one frame over HTTP from the PC side ==="
foreach ($u in @('/latest','/stat')) {
    $dst = Join-Path $dir ("cam_probe" + ($u -replace '/','_') + ".bin")
    Remove-Item $dst -ErrorAction SilentlyContinue
    & curl.exe -s -o $dst --max-time 20 ("http://192.168.1.50:8080" + $u) 2>&1 | Out-Null
    if ((Test-Path $dst) -and ((Get-Item $dst).Length -gt 20)) {
        Write-Host ("   {0}  -> {1} bytes" -f $u, (Get-Item $dst).Length)
        if ($u -eq '/stat') { Write-Host ("      " + (Get-Content $dst -Raw)) }
    } else { Write-Host ("   {0}  -> FAILED" -f $u) }
}

Write-Host ""
Write-Host ("log: " + $log)
$sw.Close(); $sp.Close()

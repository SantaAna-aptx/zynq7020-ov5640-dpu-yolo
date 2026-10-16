# d5_loop_only.ps1 -- run just the closed loop against an ALREADY loaded bitstream.
#
# Why a separate script: d5_verify.ps1 re-downloads and re-loads the bitstream first, which costs
# a couple of minutes and re-initialises the camera (killing auto-exposure/white-balance
# convergence). When the DPU is already up and you just want "capture -> infer -> bring back the
# annotated image", this is the fast path.
#
# Speed fix: the old loop used fixed Drain windows (20 s + 15 s + 140 s = ~178 s per iteration) even
# though the app itself finishes in ~0.3 s. Here each step waits for a unique end marker instead.
# The marker is counted, not merely matched, because the command echo contains it once and the
# shell's own output adds the second occurrence - matching on the first would fire immediately.
param(
  [string]$Port     = 'COM10',
  [string]$HostIp   = '192.168.1.100',
  [string]$BoardIp  = '192.168.1.50',
  [int]$HttpPort    = 8000,
  [int]$Iterations  = 3
)
$dir = 'E:\yoloProject\board_deploy'
$log = Join-Path $dir ("d5_loop_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$sw  = New-Object System.IO.StreamWriter($log, $false); $sw.AutoFlush = $true
$sp  = New-Object System.IO.Ports.SerialPort $Port,115200,None,8,one
$sp.ReadTimeout = 300
$script:buf = ""
$py  = 'C:\Users\HP\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe'

function Raw { try { $d = $sp.ReadExisting() } catch { $d = "" }; if ($d) { $script:buf += $d; $sw.Write($d) }; return $d }
function Drain([int]$ms) { $t=(Get-Date).AddMilliseconds($ms); $o=""; while ((Get-Date) -lt $t) { $o += (Raw); Start-Sleep -Milliseconds 20 }; return $o }
function Send([string]$s) { try { $sp.Write($s) } catch { } }

# Wait until $marker has been seen $count times (echo + real output), or $maxMs elapses.
function AskWait([string]$cmd, [string]$marker, [int]$count = 2, [int]$maxMs = 60000) {
    Send ($cmd + "`n")
    $t = (Get-Date).AddMilliseconds($maxMs)
    $o = ""
    while ((Get-Date) -lt $t) {
        $o += (Raw)
        if (([regex]::Matches($o, [regex]::Escape($marker))).Count -ge $count) { break }
        Start-Sleep -Milliseconds 80
    }
    $o += (Drain 400)
    return $o
}
function Show([string]$t,[string]$o,[int]$n=30){
    Write-Host "--- $t ---"
    ($o -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } |
        Select-Object -Last $n | ForEach-Object { Write-Host ("   " + $_) }
}

try { $sp.Open() } catch { Write-Host "!! $Port : $($_.Exception.Message)"; $sw.Close(); exit 2 }
Drain 600 | Out-Null
# No DtrEnable / RtsEnable - asserting them makes this board stop answering entirely.
Send "`r"; Start-Sleep -Milliseconds 500
$probe = AskWait "echo LOOP_ALIVE" "LOOP_ALIVE" 2 8000
if ($probe -notmatch 'LOOP_ALIVE') {
    Write-Host "!! no shell prompt. If the board is mid-boot, wait; otherwise power cycle it."
    $sw.Close(); $sp.Close(); exit 3
}
Write-Host "shell ok"

# The bitstream should already be loaded and the driver inserted from the earlier verification.
$state = AskWait "ls /dev/dpu 2>&1; cat /sys/class/fpga_manager/fpga0/state; echo STATE_DONE" "STATE_DONE" 2 8000
if ($state -notmatch 'dev/dpu') {
    Write-Host "!! /dev/dpu missing - run d5_verify.ps1 (or d5_full.ps1) first to load the bitstream"
    Show "state" $state 6; $sw.Close(); $sp.Close(); exit 4
}
if ($state -notmatch 'operating') { Write-Host "!! fpga_manager not in 'operating' state" }
Write-Host "dpu driver + fpga operating"

# make sure the board's httpd serves /www so we can pull the frame and the result back
AskWait "cd /home/root && (netstat -lnt 2>/dev/null | grep -q 8080) || httpd -p 8080 -h /www; echo HTTPD_DONE" "HTTPD_DONE" 2 6000 | Out-Null

for ($i = 1; $i -le $Iterations; $i++) {
    Write-Host ""
    Write-Host "--- iteration $i/$Iterations ---"
    $t0 = Get-Date

    # 1) camera frame out of DDR
    AskWait "python3 /dump_frame.py /www/frame.raw 1476000 2>&1 | tail -1; echo DUMP_DONE" "DUMP_DONE" 2 30000 | Out-Null
    $rawPc = Join-Path $dir ("d5_frame_{0}.raw" -f $i)
    Remove-Item $rawPc -ErrorAction SilentlyContinue
    & curl.exe -s -o $rawPc --max-time 40 "http://${BoardIp}:8080/frame.raw" 2>&1 | Out-Null
    if ((-not (Test-Path $rawPc)) -or ((Get-Item $rawPc).Length -lt 1476000)) {
        Write-Host "   frame fetch failed"; continue
    }

    # 2) RGB565 -> JPEG on the PC
    $jpgPc = Join-Path $dir ("d5_live_{0}.jpg" -f $i)
    $conv = & $py (Join-Path $dir 'raw565_to_jpg.py') $rawPc $jpgPc 1025 720 2>&1 | Select-Object -Last 1
    Write-Host "   $conv"

    # 3) hand it to the board (through the PC's httpd - the board has no upload endpoint)
    AskWait "wget -q -O /home/root/d3/live.jpg http://${HostIp}:${HttpPort}/d5_live_$i.jpg; ls -l /home/root/d3/live.jpg; echo GET_DONE" "GET_DONE" 2 20000 | Out-Null

    # 4) infer. Write to a file and only then fetch the interesting lines, so the grep pattern
    #    never appears in the echo where it would confuse the marker wait.
    #    NOTE: log to /home/root/d3, NOT /tmp - this kernel boots with init=/bin/sh and only
    #    proc/sys/dev get mounted, so /tmp does not exist and the redirect silently kills the
    #    whole command (the app then never runs and the result image we fetch back is a stale one).
    $res = AskWait "cd /home/root/d3 && timeout 90 ./tiny_yolo_image_diag4 live.jpg > /home/root/d3/app.log 2>&1; grep -E 'Class name|DETERM|BOXES|IMAGE_INFO|RESULT_SAVED|mismatch' /home/root/d3/app.log; echo APP_DONE" "APP_DONE" 2 120000
    if ($res -notmatch 'DETERM_CHECK') {
        Write-Host "   !! the app produced no DETERM_CHECK - showing the raw tail of its log"
        Show "app.log tail" (AskWait "tail -12 /home/root/d3/app.log 2>&1; echo TAIL_DONE" "TAIL_DONE" 2 8000) 14
    } else {
        ($res -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -match 'Class name|DETERM|BOXES|IMAGE_INFO|RESULT_SAVED|mismatch' } | ForEach-Object { Write-Host ("   " + $_) }
    }

    # 5) bring the annotated result image back
    AskWait "cp /home/root/result.jpg /www/result.jpg 2>/dev/null; echo CP_DONE" "CP_DONE" 2 8000 | Out-Null
    $outPc = Join-Path $dir ("d5_live_result_{0}.jpg" -f $i)
    Remove-Item $outPc -ErrorAction SilentlyContinue
    & curl.exe -s -o $outPc --max-time 40 "http://${BoardIp}:8080/result.jpg" 2>&1 | Out-Null
    if ((Test-Path $outPc) -and ((Get-Item $outPc).Length -gt 1000)) {
        Write-Host ("   live frame  : {0}" -f $jpgPc)
        Write-Host ("   result image: {0} ({1} bytes)" -f $outPc, (Get-Item $outPc).Length)
    } else { Write-Host "   result image: NOT retrieved" }
    Write-Host ("   took {0:N1}s" -f ((Get-Date) - $t0).TotalSeconds)
}

Write-Host ""
Write-Host "log: $log"
$sw.Close(); $sp.Close()

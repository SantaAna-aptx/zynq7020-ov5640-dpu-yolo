# live_focus.ps1 -- live camera preview for adjusting the lens, WITHOUT accumulating files.
#
# Design rules (per the user's request):
#   * nothing is archived: only one overwritten latest.png exists in the web directory, and the
#     raw buffer goes to the TEMP folder, also overwritten every cycle
#   * it can be paused: while focus\PAUSE exists the loop grabs nothing at all, so it uses no
#     serial, CPU or disk; the web page keeps showing the last frame and says "paused"
#   * the page itself needs no server: focus\index.html reloads every few seconds
#
# Control it with focus_ctl.ps1 -Action pause | resume | stop
param(
  [string]$BoardIp  = '192.168.1.50',
  [string]$HostIp   = '192.168.1.100',
  [int]$IntervalSec = 5,
  [int]$Width       = 1025,   # measured line width of this camera
  [int]$Height      = 720,
  [switch]$SwapRB             # swap red/blue on the host: needed only while the PL still runs
                              # the old sensor configuration (0x4300 = 0x60)
)
$ErrorActionPreference = 'Continue'
$dir   = 'E:\yoloProject\board_deploy'
$out   = Join-Path $dir 'focus'
$tmp   = Join-Path $env:TEMP 'dsh_focus'
New-Item -ItemType Directory -Force -Path $out | Out-Null
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$py    = 'C:\Users\HP\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe'
$need  = $Width * $Height * 2
$pause = Join-Path $out 'PAUSE'
$stop  = Join-Path $out 'STOP'

$sp = New-Object System.IO.Ports.SerialPort 'COM10',115200,None,8,one
$sp.ReadTimeout = 300; $sp.NewLine = "`n"
try { $sp.Open() } catch { Write-Host "!! cannot open COM10: $($_.Exception.Message)"; exit 2 }

function Drain([int]$ms) { $t=(Get-Date).AddMilliseconds($ms); $o=""; while ((Get-Date) -lt $t) { try { $d=$sp.ReadExisting(); if ($d) { $o += $d } } catch {}; Start-Sleep -Milliseconds 15 }; return $o }
function Send([string]$s) { try { $sp.Write($s) } catch {} }
function Cmd([string]$c,[int]$w=1500){ Send ($c + "`n"); return (Drain $w) }
function Status([string]$state,[double]$score,[double]$best,[string]$at) {
    $js = 'window.FOCUS = {{paused:{0}, score:{1}, best:{2}, at:''{3}''}};' -f `
          ($(if ($state -eq 'paused') {'true'} else {'false'})), $score, $best, $at
    Set-Content -Path (Join-Path $out 'status.js') -Encoding ascii -Value $js
}

Send "`r`n"; Drain 1200 | Out-Null
Cmd "export PATH=/sbin:/bin:/usr/sbin:/usr/bin; mount -t proc proc /proc 2>/dev/null" 1000 | Out-Null
Cmd "mkdir -p /www; (netstat -lnt 2>/dev/null | grep -q 8080) || httpd -p 8080 -h /www" 1800 | Out-Null

$best = -1.0
Write-Host "live focus preview running - nothing is archived."
Write-Host "  page  : http://${HostIp}:8000/focus/index.html"
Write-Host "  pause : focus_ctl.ps1 -Action pause     (or create $pause)"
Write-Host "  resume: focus_ctl.ps1 -Action resume"
Write-Host "  stop  : focus_ctl.ps1 -Action stop"
Status 'running' -1 -1 (Get-Date).ToString('HH:mm:ss')

while (-not (Test-Path $stop)) {
    if (Test-Path $pause) {
        Start-Sleep -Seconds 2
        continue
    }

    $t0 = Get-Date
    Send "python3 /dump_frame.py /www/frame.raw $need`n"
    $r = ""; $tw = (Get-Date).AddSeconds(30)
    while ((Get-Date) -lt $tw) {
        $r += (Drain 150)
        if ($r -match 'wrote ') { break }
        if ($r -match 'Traceback') { break }
    }

    $raw = Join-Path $tmp 'latest.raw'
    & curl.exe -s -o $raw --max-time 40 "http://${BoardIp}:8080/frame.raw" 2>&1 | Out-Null
    if (-not (Test-Path $raw) -or (Get-Item $raw).Length -lt $need) {
        Start-Sleep -Seconds $IntervalSec; continue
    }

    # One PNG, overwritten in place: the browser needs a file to fetch, but nothing accumulates.
    $png = Join-Path $out 'latest.png'
    $args = @((Join-Path $dir 'focus_frame.py'), $raw, $png, $png, $Width, $Height)
    if ($SwapRB) { $args += '--swap-rb' }
    $res = & $py @args 2>&1
    $score = -1.0
    $line = ($res | Where-Object { $_ -match 'SCORE' } | Select-Object -Last 1)
    if ($line -match 'SCORE=([-0-9.]+)') { $score = [double]$Matches[1] }
    if ($score -gt $best) { $best = $score }

    Status 'running' $score $best (Get-Date).ToString('HH:mm:ss')
    Write-Host ("[{0}] score {1,7:N1}   best {2,7:N1}" -f (Get-Date).ToString('HH:mm:ss'), $score, $best)

    $spent = ((Get-Date) - $t0).TotalSeconds
    if ($spent -lt $IntervalSec) { Start-Sleep -Seconds ([math]::Ceiling($IntervalSec - $spent)) }
}
Status 'stopped' -1 $best (Get-Date).ToString('HH:mm:ss')
$sp.Close()
Write-Host "stopped."

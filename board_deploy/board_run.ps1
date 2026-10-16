# board_run.ps1 -- push one file to the board over HTTP, make it executable and run it.
# Used to validate that a cross-compiled ARM binary actually starts on this Yocto rootfs.
param(
  [string]$File    = 'abi_probe',
  [string]$Port    = 'COM10',
  [string]$HostIp  = '192.168.1.100',
  [int]$HttpPort   = 8000,
  [string]$Remote  = '/home/root/d3',
  [int]$RunMs      = 15000
)
$dir = 'E:\yoloProject\board_deploy'
$log = Join-Path $dir ("board_run_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$sw  = New-Object System.IO.StreamWriter($log, $false); $sw.AutoFlush = $true
$sp  = New-Object System.IO.Ports.SerialPort $Port,115200,None,8,one
$sp.ReadTimeout = 300
$script:buf = ""

function Raw { try { $d = $sp.ReadExisting() } catch { $d = "" }; if ($d) { $script:buf += $d; $sw.Write($d) }; return $d }
function Drain([int]$ms) { $t=(Get-Date).AddMilliseconds($ms); $o=""; while ((Get-Date) -lt $t) { $o += (Raw); Start-Sleep -Milliseconds 20 }; return $o }
function Send([string]$s) { try { $sp.Write($s) } catch { } }
function AskWait([string]$cmd,[string]$marker,[int]$count=2,[int]$maxMs=30000){
    Send ($cmd + "`n")
    $t = (Get-Date).AddMilliseconds($maxMs); $o = ""
    while ((Get-Date) -lt $t) {
        $o += (Raw)
        if (([regex]::Matches($o,[regex]::Escape($marker))).Count -ge $count) { break }
        Start-Sleep -Milliseconds 80
    }
    $o += (Drain 400)
    return $o
}
function Show([string]$t,[string]$o,[int]$n=60){
    Write-Host "--- $t ---"
    ($o -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } |
        Select-Object -Last $n | ForEach-Object { Write-Host ("   " + $_) }
}

try { $sp.Open() } catch { Write-Host "!! $Port : $($_.Exception.Message)"; $sw.Close(); exit 2 }
Drain 600 | Out-Null
Send "`r"; Start-Sleep -Milliseconds 400
if ((AskWait "echo BR_ALIVE" "BR_ALIVE" 2 6000) -notmatch 'BR_ALIVE') { Write-Host "!! no shell"; $sw.Close(); $sp.Close(); exit 3 }

Show "board libc" (AskWait "ls -la /lib/libc.so.6 /lib/libc-*.so 2>&1; ls /lib/ld-linux* 2>&1; echo LIBC_DONE" "LIBC_DONE" 2 6000) 8

Write-Host ""
Write-Host ("=== push " + $File + " and run ===")
Show "fetch" (AskWait "cd $Remote && wget -q -O $File http://${HostIp}:${HttpPort}/$File; ls -l $File; chmod +x $File; echo FETCH_DONE" "FETCH_DONE" 2 25000) 4

$run = AskWait "cd $Remote && ./$File; echo RUN_EXIT=`$?" "RUN_EXIT" 2 $RunMs
Show "run output" $run 40

Write-Host ""
Write-Host ("log: " + $log)
$sw.Close(); $sp.Close()

# focus_ctl.ps1 -- pause / resume / stop the live focus preview.
#
#   focus_ctl.ps1 -Action pause     stop grabbing frames (no serial, CPU or disk use at all);
#                                   the web page keeps showing the last frame and says "paused"
#   focus_ctl.ps1 -Action resume    start grabbing again
#   focus_ctl.ps1 -Action stop      end the preview process entirely
#   focus_ctl.ps1 -Action status    report what is currently happening
param(
  [Parameter(Mandatory=$true)][ValidateSet('pause','resume','stop','status')][string]$Action
)
$out   = 'E:\yoloProject\board_deploy\focus'
$pause = Join-Path $out 'PAUSE'
$stop  = Join-Path $out 'STOP'

switch ($Action) {
    'pause' {
        New-Item -ItemType File -Force -Path $pause | Out-Null
        Write-Host "paused - the preview grabs nothing until you resume."
        Write-Host "the page still shows the last frame: http://192.168.1.100:8000/focus/index.html"
    }
    'resume' {
        Remove-Item $pause -Force -ErrorAction SilentlyContinue
        Write-Host "resumed."
    }
    'stop' {
        New-Item -ItemType File -Force -Path $stop | Out-Null
        Start-Sleep -Seconds 4
        Get-CimInstance Win32_Process -Filter "Name like '%powershell%'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -match 'live_focus\.ps1' } |
            ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
        Remove-Item $stop  -Force -ErrorAction SilentlyContinue
        Remove-Item $pause -Force -ErrorAction SilentlyContinue
        Write-Host "preview stopped."
    }
    'status' {
        $procs = (Get-CimInstance Win32_Process -Filter "Name like '%powershell%'" -ErrorAction SilentlyContinue |
                  Where-Object { $_.CommandLine -match 'live_focus\.ps1' } | Measure-Object).Count
        $p = Test-Path $pause
        Write-Host ("preview process : {0}" -f $(if ($procs -gt 0) { "running ($procs)" } else { 'not running' }))
        Write-Host ("state           : {0}" -f $(if ($p) { 'PAUSED' } elseif ($procs -gt 0) { 'grabbing frames' } else { 'stopped' }))
        $d = Join-Path $out 'latest.png'
        if (Test-Path $d) { Write-Host ("last frame      : {0}  ({1} KB)" -f (Get-Item $d).LastWriteTime, [math]::Round((Get-Item $d).Length/1KB)) }
    }
}

# Relaunch crash watcher -> Discord #crash-report webhook. Runs every 1 min via
# the "Relaunch-CrashWatcher" scheduled task. Posts a short Wheaty + map-log
# summary when a new file appears in C:\server\dmp.
$ErrorActionPreference = "Continue"
try { (Get-Process -Id $PID).PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle } catch {}

$log = "C:\relaunch-ops\logs\crash_watcher.log"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $log) | Out-Null
if ((Test-Path $log) -and (Get-Item $log).Length -gt 2MB) {
    (Get-Content $log -Tail 500) | Set-Content -Path $log -Encoding utf8
}
("{0}  crash-watcher poll" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")) | Out-File -FilePath $log -Append -Encoding utf8

& "C:\Program Files\Python312\python.exe" "C:\server\tools\crash-watcher\crash_watcher_relaunch.py" 2>&1 |
    Out-File -FilePath $log -Append -Encoding utf8

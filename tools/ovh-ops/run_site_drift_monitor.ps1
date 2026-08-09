# Relaunch docs drift monitor -- runs at :20 and :50 via "Relaunch-DriftMonitor".
# Dead-man's-switch for fjb-relaunch; alerts Discord if the hourly docs refresh stalls.
$ErrorActionPreference = "Continue"
# Run at IDLE priority so this batch job's CPU/I-O yields to the game on the shared
# C: drive (the python child inherits it). Prevents starving the map tick -> watchdog
# trips correlated with this task's :20/:50 slots. See tools/ovh-ops/README.md.
try { (Get-Process -Id $PID).PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle } catch {}
$log = "C:\relaunch-ops\logs\site_drift_monitor.log"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $log) | Out-Null
if ((Test-Path $log) -and (Get-Item $log).Length -gt 2MB) {
    (Get-Content $log -Tail 500) | Set-Content -Path $log -Encoding utf8
}
("{0}  drift check" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")) | Out-File -FilePath $log -Append -Encoding utf8
& "C:\Program Files\Python312\python.exe" "C:\relaunch-ops\site_drift_monitor_relaunch.py" 2>&1 |
    Out-File -FilePath $log -Append -Encoding utf8

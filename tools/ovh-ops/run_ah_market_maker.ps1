# Relaunch AH market-maker -- runs hourly (:30) via Scheduled Task "Relaunch-AHBot".
# Reads C:\server\settings\network.lua (localhost xi_relaunch = the live OVH DB).
# Self-hosted on OVH 2026-07-06 (migrated off the Azure cron; no remote DB).
$ErrorActionPreference = "Continue"
# Run at IDLE priority so this job's DB/CPU work yields to the game on the shared
# C: drive (the python child inherits it). See tools/ovh-ops/README.md.
try { (Get-Process -Id $PID).PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle } catch {}
$log = "C:\relaunch-ops\logs\ah_market_maker.log"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $log) | Out-Null

# Trim the log if it grows past ~5 MB so it can't fill the disk.
if ((Test-Path $log) -and (Get-Item $log).Length -gt 5MB) {
    $keep = Get-Content $log -Tail 2000
    Set-Content -Path $log -Value $keep -Encoding UTF8
}

("===== {0}  AH market-maker START =====" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")) | Add-Content $log
Set-Location "C:\server\tools"
& "C:\Program Files\Python312\python.exe" ah_market_maker.py --commit 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
("===== done (python exit {0}) =====`r`n" -f $LASTEXITCODE) | Add-Content $log

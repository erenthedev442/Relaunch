# Relaunch join watcher -> Discord #player-logins webhook. Runs every 1 min via
# the "Relaunch-JoinWatcher" scheduled task. Posts new-character + login events
# (and, if a second webhook file is present, achievements / HL rank-ups /
# ascensions) from the LIVE xi_relaunch DB. See tools/join-watcher/RELAUNCH-DEPLOY.md.
$ErrorActionPreference = "Continue"
# IDLE priority so this 1-min job yields CPU/I-O to the game on the shared C:
# drive (the python child inherits it) -- same guard the drift monitor uses so a
# background task can't starve the map tick. See tools/ovh-ops/README.md.
try { (Get-Process -Id $PID).PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle } catch {}

$log = "C:\relaunch-ops\logs\join_watcher.log"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $log) | Out-Null
if ((Test-Path $log) -and (Get-Item $log).Length -gt 2MB) {
    (Get-Content $log -Tail 500) | Set-Content -Path $log -Encoding utf8
}
("{0}  join-watcher poll" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")) | Out-File -FilePath $log -Append -Encoding utf8

# Run the watcher IN-PLACE from C:\server so it can import tools/docgen/_db.py
# (the xi_relaunch connection helper) and read the live Lua catalogs.
& "C:\Program Files\Python312\python.exe" "C:\server\tools\join-watcher\ffxi_join_watcher_relaunch.py" 2>&1 |
    Out-File -FilePath $log -Append -Encoding utf8

# Relaunch LinkShell -> Discord #linkshell bridge SUPERVISOR.
# Runs tools/discord_bot/ls_bridge.py -- a persistent ~3s daemon that mirrors the
# in-game "Legendary" linkshell into #linkshell (one-way, webhook-only) -- in a
# restart loop, so a crash or DB blip self-heals. Launched at boot by the
# "Relaunch-LSBridge" scheduled task (MultipleInstances=IgnoreNew,
# ExecutionTimeLimit unlimited). See tools/discord_bot/RELAUNCH-DEPLOY.md.
$ErrorActionPreference = "Continue"

# IDLE priority so the bridge yields CPU/I-O to the game on the shared C: drive
# (the python child inherits it) -- same guard the other Relaunch-* ops tasks use.
try { (Get-Process -Id $PID).PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle } catch {}

$Py  = "C:\Program Files\Python312\python.exe"
$App = "C:\server\tools\discord_bot\ls_bridge.py"
$log = "C:\relaunch-ops\logs\ls_bridge.log"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $log) | Out-Null

function Log($m){ ("{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $m) | Out-File -FilePath $log -Append -Encoding utf8 }

Log "supervisor start (pid $PID)"
while ($true) {
    # trim log if > 2 MB
    if ((Test-Path $log) -and (Get-Item $log).Length -gt 2MB) {
        (Get-Content $log -Tail 500) | Set-Content -Path $log -Encoding utf8
    }
    if (-not (Test-Path $App)) {
        Log "ls_bridge.py missing at $App -- waiting 60s (deploy not landed yet?)"
        Start-Sleep -Seconds 60
        continue
    }
    # Run the daemon in-place from C:\server so it imports tools/docgen/_db.py and
    # reads config.py next to it. This call BLOCKS until the daemon exits.
    & $Py $App 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
    Log "ls_bridge exited (code $LASTEXITCODE); restarting in 5s"
    Start-Sleep -Seconds 5
}

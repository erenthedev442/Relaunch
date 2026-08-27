# Relaunch #rescue-me bot daemon -- keeps rescue_bot.py alive.
# Long-lived gateway bot (reads !rescue messages), so this is a RESTART LOOP,
# not a Task Scheduler poll. IDLE priority + log rotation like the other ops
# jobs. Registered as the "Relaunch-RescueBot" task (ONSTART, unlimited exec
# time). See tools/discord_bot/RESCUE-BOT-RELAUNCH-DEPLOY.md.
$ErrorActionPreference = "Continue"
# IDLE priority so this never competes with the game on the shared C: drive
# (the python child inherits it). See tools/ovh-ops/README.md.
try { (Get-Process -Id $PID).PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle } catch {}

$env:LEGENDARY_LIVE_ROOT = "C:\server"
$py  = "C:\Program Files\Python312\python.exe"
$bot = "C:\server\tools\discord_bot\rescue_bot.py"
$log = "C:\relaunch-ops\logs\rescue_bot.log"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $log) | Out-Null

while ($true) {
    if ((Test-Path $log) -and (Get-Item $log).Length -gt 5MB) {
        (Get-Content $log -Tail 1000) | Set-Content -Path $log -Encoding utf8
    }
    ("{0}  starting rescue_bot.py" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")) |
        Out-File -FilePath $log -Append -Encoding utf8
    & $py $bot 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
    # rescue_bot exits 2 when unconfigured (no token/channel) -- don't hot-loop.
    ("{0}  rescue_bot.py exited (code {1}) -- restarting in 15s" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $LASTEXITCODE) |
        Out-File -FilePath $log -Append -Encoding utf8
    Start-Sleep -Seconds 15
}

# Non-interactive Deploy Everything. Resets C:\server to origin/relaunch first
# so the emergency Halver pull cannot auto-commit over the crash fix.
$ErrorActionPreference = 'Continue'
Set-Location C:\server
$env:GIT_TERMINAL_PROMPT = '0'

Write-Host '========== reset to origin/relaunch =========='
git fetch origin relaunch
if ($LASTEXITCODE -ne 0) { throw 'git fetch failed' }
git reset --hard origin/relaunch
git log -1 --oneline
git status -sb

Write-Host '========== deploy-relaunch.ps1 =========='
# First Read-Host = Proceed; last Read-Host = close. Two answers, then done.
$answers = "Y`r`n`r`n"
$answers | & powershell -NoProfile -ExecutionPolicy Bypass -File C:\server\deploy-relaunch.ps1
Write-Host "DEPLOY_WRAPPER_EXIT=$LASTEXITCODE"

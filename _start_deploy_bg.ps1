New-Item -ItemType Directory -Force -Path C:\relaunch-ops\logs | Out-Null
Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','C:\server\_run_deploy.ps1' -RedirectStandardOutput 'C:\relaunch-ops\logs\deploy-now.out' -RedirectStandardError 'C:\relaunch-ops\logs\deploy-now.err' -WindowStyle Hidden
Write-Host 'DEPLOY_STARTED'

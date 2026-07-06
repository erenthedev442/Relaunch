@echo off
title Relaunch - Status
echo === Relaunch server status (local VPS processes) ===
echo.
powershell -NoProfile -Command "foreach($p in 'xi_connect','xi_world','xi_search','xi_map'){$r=Get-Process $p -ErrorAction SilentlyContinue; if($r){Write-Host ('{0,-12} active     PID {1}   {2} MB' -f $p,$r.Id,[int]($r.WorkingSet64/1MB)) -ForegroundColor Green}else{Write-Host ('{0,-12} INACTIVE' -f $p) -ForegroundColor Red}}; $sup = Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'powershell.exe' -and $_.CommandLine -match 'relaunch-supervisor' }; if($sup){Write-Host ('supervisor    active     PID {0}' -f $sup.ProcessId) -ForegroundColor Green}else{Write-Host 'supervisor    NOT RUNNING (crashed servers will NOT auto-restart)' -ForegroundColor Yellow}"
echo.
pause

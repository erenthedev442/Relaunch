@echo off
title Relaunch - Stop Server
echo Stopping all xi servers (connect, search, map, world)...
echo (players will be disconnected)
echo.
schtasks /end /tn "FFXIRelaunch" >nul 2>&1
powershell -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'powershell.exe' -and $_.CommandLine -match 'relaunch-supervisor' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }; foreach($p in 'xi_map','xi_connect','xi_world','xi_search'){ Get-Process $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue }; Start-Sleep 2; foreach($p in 'xi_connect','xi_world','xi_search','xi_map'){$r=Get-Process $p -ErrorAction SilentlyContinue; if($r){Write-Host ($p+' : still up') -ForegroundColor Yellow}else{Write-Host ($p+' : inactive') -ForegroundColor Green}}"
echo.
echo (four 'inactive' lines above = all servers stopped)
echo Use "Relaunch - Start Server" to bring them back.
pause

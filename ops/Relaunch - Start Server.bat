@echo off
title Relaunch - Start Server
echo Starting all xi servers via the FFXIRelaunch supervisor...
echo.
schtasks /run /tn "FFXIRelaunch" >nul 2>&1
powershell -NoProfile -Command "Start-Sleep 8; foreach($p in 'xi_connect','xi_world','xi_search','xi_map'){$r=Get-Process $p -ErrorAction SilentlyContinue; if($r){Write-Host ('{0,-12} active     PID {1}' -f $p,$r.Id) -ForegroundColor Green}else{Write-Host ('{0,-12} not up yet' -f $p) -ForegroundColor Yellow}}"
echo.
echo (all four 'active' = servers launching; the MAP server then takes
echo  about 1-2 minutes to finish loading all 300 zones before players
echo  can zone in -- check "Relaunch - Map Logs" for "ready to work")
pause

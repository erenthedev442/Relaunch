@echo off
title Relaunch - Restart Map
echo Restarting the MAP server only (login stays up; players in zones
echo get bounced to character select, then can log right back in).
echo.
powershell -NoProfile -Command "$was = Get-Process xi_map -ErrorAction SilentlyContinue; if($was){ Stop-Process -Id $was.Id -Force; Write-Host 'xi_map stopped - the supervisor will relaunch it within ~10s...' -ForegroundColor Yellow } else { Write-Host 'xi_map was not running.' -ForegroundColor Yellow }; Start-Sleep 15; $now = Get-Process xi_map -ErrorAction SilentlyContinue; if($now){ Write-Host ('xi_map active again (PID '+$now.Id+') - now loading zones, ~1-2 min.') -ForegroundColor Green } else { Write-Host 'xi_map did NOT come back. Is FFXIRelaunch running? Use Start Server.' -ForegroundColor Red }"
echo.
pause

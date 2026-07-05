@echo off
setlocal
title Relaunch Server - Stop

set "KEY=C:\Users\richa\Downloads\ffxi-server_key.pem"
set "HOST=azureuser@172.215.213.23"
set "SSHOPT=-o StrictHostKeyChecking=accept-new"

echo.
echo Stopping RELAUNCH server services (live server is NOT touched)...
echo.

REM Stop the map server first so players get a clean disconnect, then the
REM rest of the stack. Unit names are exact -- the live services (xi_map,
REM xi_connect, ...) have no _relaunch suffix and are never matched.
REM systemd's Restart=always does NOT apply to manual stops, and there is
REM no relaunch watchdog cron, so the services STAY stopped until
REM relaunch-start.bat brings them back.
ssh %SSHOPT% -i "%KEY%" %HOST% "sudo systemctl stop xi_map_relaunch xi_search_relaunch xi_world_relaunch xi_connect_relaunch xi_relaunch"

if errorlevel 1 (
    echo.
    echo [ERROR] Stop command failed. Check SSH connectivity.
    pause
    exit /b 1
)

echo.
echo Checking service status (all should be inactive)...
echo.

ssh %SSHOPT% -i "%KEY%" %HOST% "systemctl is-active xi_connect_relaunch xi_world_relaunch xi_search_relaunch xi_map_relaunch; echo; systemctl --no-pager --no-legend list-units --all 'xi_*relaunch*'"

echo.
echo Done. Restart later with relaunch-start.bat
echo.
pause

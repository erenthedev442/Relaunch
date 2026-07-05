@echo off
setlocal
title Relaunch Server - Start

set "KEY=C:\Users\richa\Downloads\ffxi-server_key.pem"
set "HOST=azureuser@172.215.213.23"
set "SSHOPT=-o StrictHostKeyChecking=accept-new"

echo.
echo Starting relaunch server services...
echo.

ssh %SSHOPT% -i "%KEY%" %HOST% "sudo systemctl start xi_relaunch xi_connect_relaunch xi_world_relaunch xi_search_relaunch xi_map_relaunch"

if errorlevel 1 (
    echo.
    echo [ERROR] Start command failed. Check SSH connectivity.
    pause
    exit /b 1
)

echo.
echo Checking service status...
echo.

ssh %SSHOPT% -i "%KEY%" %HOST% "systemctl is-active xi_connect_relaunch xi_world_relaunch xi_search_relaunch xi_map_relaunch"

echo.
echo Done. Use relaunch-logs.bat or:
echo   ssh -i "%KEY%" %HOST% "journalctl -u xi_map_relaunch -f"
echo.
pause

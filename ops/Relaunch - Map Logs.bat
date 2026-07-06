@echo off
title Relaunch - Map Logs
echo === Last 80 lines of the map server log ===
echo.
powershell -NoProfile -Command "Get-Content 'C:\server\log\map-server.log' -Tail 80"
echo.
pause

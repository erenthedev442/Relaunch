@echo off
title Relaunch - Other Logs (connect / world / search)
echo ================= CONNECT (login) - last 30 =================
powershell -NoProfile -Command "Get-Content 'C:\server\log\connect-server.log' -Tail 30"
echo.
echo ================= WORLD - last 30 =================
powershell -NoProfile -Command "Get-Content 'C:\server\log\world-server.log' -Tail 30"
echo.
echo ================= SEARCH - last 30 =================
powershell -NoProfile -Command "Get-Content 'C:\server\log\search-server.log' -Tail 30"
echo.
pause

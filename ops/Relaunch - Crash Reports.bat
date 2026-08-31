@echo off
title Relaunch - Crash Reports
echo === Five newest crash reports (double-click on the VPS) ===
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\server\ops\crash-reports.ps1"
echo.
pause

@echo off
title Relaunch - Troll Check
echo Read-only check of known troll IPs, logins, and remake patterns.
echo Does not ban, kick, or firewall anyone.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File C:\server\tools\troll-watch\check_trolls.ps1 %*
echo.
pause

@echo off
title Relaunch - Build Progress
echo Live C++ build progress meter.
echo Open this in a second window WHILE a rebuild is compiling to watch the
echo [done/total] step counter and percentage.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File C:\server\build-progress.ps1
echo.
pause

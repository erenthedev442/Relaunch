@echo off
title Relaunch Custom DATs - Installer
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator access...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
echo.
echo ============================================================
echo  Finished. Read the messages above, then press a key to close.
echo ============================================================
pause >nul

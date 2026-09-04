@echo off
title Relaunch Launcher
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0RelaunchLauncher.ps1"
if errorlevel 1 pause

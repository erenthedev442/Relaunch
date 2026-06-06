@echo off
REM ============================================================
REM Legendary FFXI - Deploy SQL changes to the LIVE Azure server
REM ============================================================
REM Double-click this to push your sql\zz_*.sql edits to the real
REM (Azure) server and restart the game so they go live.
REM
REM The first time, it asks your server username once and saves it
REM (deploy-to-azure.config). After that it's a one-click button.
REM
REM All the Linux/SSH work happens automatically - you just watch.
REM ============================================================
setlocal
set "HERE=%~dp0"
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%HERE%deploy-to-azure.ps1"

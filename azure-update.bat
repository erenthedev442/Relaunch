@echo off
REM ============================================================
REM Legendary FFXI - FULL update of the LIVE Azure server
REM ============================================================
REM Double-click for the Azure equivalent of your laptop's
REM "rebuild + dbtool update", all in one:
REM   backup -> git pull (code) -> rebuild -> reload ALL sql -> restart
REM
REM Use this for CODE / LandSandBoat updates. For a quick "I only
REM changed a SQL file" push, use deploy-to-azure.bat instead
REM (faster - it just uploads the zz_*.sql files and restarts).
REM
REM Uses the same saved login as deploy-to-azure (asked once).
REM ============================================================
setlocal
set "HERE=%~dp0"
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%HERE%azure-update.ps1"

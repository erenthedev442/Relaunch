@echo off
setlocal EnableExtensions
title FFXI AH Market Maker - Control Panel

REM ============================================================
REM  Control panel for the "FFXI AH Market Maker" scheduled task.
REM  Double-click to open. Turn the AH bot on/off, run it on
REM  demand, restart it, or reinstall it if it ever goes missing.
REM
REM  Enable/disable/run do NOT need admin rights (it is your own
REM  task). If any action says "Access is denied", right-click
REM  this file and choose "Run as administrator".
REM ============================================================

set "TASK=FFXI AH Market Maker"
set "PY=C:\Users\richa\AppData\Local\Programs\Python\Python312\python.exe"
set "SCRIPT=D:\server\tools\ah_market_maker.py"

goto menu

:menu
cls
echo ==================================================
echo      FFXI AH Market Maker  -  Control Panel
echo ==================================================
echo.
echo  Current status:
call :status
echo.
echo  --------------------------------------------------
echo   [1]  Turn ON / Install   - enable daily schedule + run now
echo   [2]  Turn OFF            - disable the schedule
echo   [3]  Run a pass NOW      - one immediate pass
echo   [4]  Restart             - stop current pass, then run now
echo   [5]  Refresh this screen
echo   [0]  Exit
echo  --------------------------------------------------
echo.
set "choice="
set /p "choice=Select an option then press Enter: "
if "%choice%"=="1" goto turnon
if "%choice%"=="2" goto turnoff
if "%choice%"=="3" goto runnow
if "%choice%"=="4" goto restart
if "%choice%"=="5" goto menu
if "%choice%"=="0" goto end
goto menu

:status
schtasks /query /tn "%TASK%" >nul 2>&1
if errorlevel 1 goto status_missing
schtasks /query /tn "%TASK%" /v /fo list | findstr /C:"Status:" /C:"Scheduled Task State:" /C:"Last Run Time:" /C:"Last Result:" /C:"Next Run Time:"
goto :eof
:status_missing
echo    NOT INSTALLED - the task does not exist. Use option [1] to install it.
goto :eof

:turnon
echo.
schtasks /query /tn "%TASK%" >nul 2>&1
if errorlevel 1 goto turnon_install
echo Enabling the scheduled task...
schtasks /change /tn "%TASK%" /enable
goto turnon_run
:turnon_install
echo Task not found - installing it now ^(runs once a day at 4:00 AM while you are logged on^)...
schtasks /create /tn "%TASK%" /tr "%PY% %SCRIPT% --commit" /sc daily /st 04:00 /it /f
:turnon_run
echo.
echo Kicking off a pass right now so stock updates immediately...
schtasks /run /tn "%TASK%"
echo.
echo The bot is ON. It will run automatically once a day at 4:00 AM.
echo.
pause
goto menu

:turnoff
echo.
echo Disabling the scheduled task...
schtasks /change /tn "%TASK%" /disable
echo.
echo The bot is OFF. Gear already on the AH stays listed; it just
echo will not be restocked or bought back until you turn it back on.
echo.
pause
goto menu

:runnow
echo.
echo Running one pass now...
schtasks /run /tn "%TASK%"
echo.
echo Started. Choose [5] in a few seconds - "Last Result: 0" means success.
echo.
pause
goto menu

:restart
echo.
echo Stopping any in-progress pass...
schtasks /end /tn "%TASK%" >nul 2>&1
echo Starting a fresh pass...
schtasks /run /tn "%TASK%"
echo.
echo Restarted.
echo.
pause
goto menu

:end
endlocal
exit /b 0

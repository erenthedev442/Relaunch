@echo off
setlocal EnableExtensions
title Legendary Discord Webhook - Control Panel

REM ============================================================
REM  Control panel for the "Legendary Discord Webhook" task.
REM  Double-click to open. Turn the Discord notifier on/off, run
REM  it on demand, restart it, or reinstall it if it goes missing.
REM
REM  This is the ONE-WAY webhook notifier (discord_bot.py): it
REM  polls the live DB every 5 minutes and posts rank-ups, capstone
REM  achievements, HNM King spawns, weekly sweeps, daily/weekly
REM  digests, and server patch-notes to your Discord channel.
REM
REM  It is idempotent and safe to run as often as you like - the
REM  first run silently records a baseline (no historical flood),
REM  and every later run only posts what is genuinely new.
REM
REM  This does NOT run the two-way slash-command bot (token_bot.py),
REM  which is a separate long-lived daemon you start yourself.
REM
REM  Enable/disable/run do NOT need admin rights (it is your own
REM  task). If any action says "Access is denied", right-click
REM  this file and choose "Run as administrator".
REM ============================================================

set "TASK=Legendary Discord Webhook"
set "PY=C:\Users\richa\AppData\Local\Programs\Python\Python312\python.exe"
set "SCRIPT=D:\server\tools\discord_bot\discord_bot.py"
set "CONFIG=D:\server\tools\discord_bot\config.py"

goto menu

:menu
cls
echo ==================================================
echo    Legendary Discord Webhook  -  Control Panel
echo ==================================================
echo.
echo  Config:
call :cfgcheck
echo.
echo  Current status:
call :status
echo.
echo  --------------------------------------------------
echo   [1]  Turn ON / Install   - enable 5-min schedule + run now
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

:cfgcheck
if exist "%CONFIG%" (
  echo    config.py found.
) else (
  echo    config.py MISSING - copy config.example.py to config.py and paste
  echo    your Discord webhook URL first, or the bot will exit with error 1.
)
goto :eof

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
if not exist "%CONFIG%" (
  echo WARNING: config.py is missing. The bot will exit with error 1 until you
  echo copy config.example.py to config.py and set WEBHOOK_URL. Installing the
  echo schedule anyway so it is ready once you add the config.
  echo.
)
schtasks /query /tn "%TASK%" >nul 2>&1
if errorlevel 1 goto turnon_install
echo Enabling the scheduled task...
schtasks /change /tn "%TASK%" /enable
goto turnon_run
:turnon_install
echo Task not found - installing it now ^(runs every 5 minutes while you are logged on^)...
schtasks /create /tn "%TASK%" /tr "%PY% %SCRIPT%" /sc minute /mo 5 /it /f
:turnon_run
echo.
echo Kicking off a pass right now so any new events post immediately...
schtasks /run /tn "%TASK%"
echo.
echo The notifier is ON. It will run automatically every 5 minutes.
echo The very first run only records a baseline ^(no historical flood^);
echo new events start posting from the next pass onward.
echo.
pause
goto menu

:turnoff
echo.
echo Disabling the scheduled task...
schtasks /change /tn "%TASK%" /disable
echo.
echo The notifier is OFF. Messages already posted stay in Discord; new
echo events just will not be detected or posted until you turn it back on.
echo.
pause
goto menu

:runnow
echo.
echo Running one pass now...
schtasks /run /tn "%TASK%"
echo.
echo Started. Choose [5] in a few seconds - "Last Result: 0" means success.
echo  ^(1 = config.py / WEBHOOK_URL missing, 2 = DB unreachable, 3 = webhook error^)
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

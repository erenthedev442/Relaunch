@echo off
setlocal EnableExtensions
title Legendary DB Backup - Control Panel

REM ============================================================
REM  Control panel for the "Legendary DB Backup" task.
REM  Double-click to open. Schedule nightly backups, run one on
REM  demand, test-restore a backup, or see what is on disk.
REM
REM  This protects the project's one hard promise: NEVER WIPE
REM  PROGRESSION. It mysqldumps the live game DB (xidb) to a
REM  timestamped, compressed file, prunes old copies, and can
REM  PROVE a backup works by restoring it into a throwaway temp
REM  database and checking row counts. A backup you have never
REM  test-restored is a hope, not a backup.
REM
REM  Backups are written to  D:\server-backups\db  -- OUTSIDE the
REM  git tree, so a reclone or "git clean" can never delete them.
REM
REM  The verify/test-restore only ever touches a throwaway DB
REM  (xidb_verify_tmp); it never writes to the live xidb.
REM
REM  Enable/disable/run do NOT need admin rights (it is your own
REM  task). If any action says "Access is denied", right-click
REM  this file and choose "Run as administrator".
REM ============================================================

set "TASK=Legendary DB Backup"
set "PY=C:\Users\richa\AppData\Local\Programs\Python\Python312\python.exe"
set "SCRIPT=D:\server\tools\db_backup\db_backup.py"

goto menu

:menu
cls
echo ==================================================
echo      Legendary DB Backup  -  Control Panel
echo ==================================================
echo.
echo  Scheduled task status:
call :status
echo.
echo  Backups on disk:
call :listbk
echo.
echo  --------------------------------------------------
echo   [1]  Turn ON / Install  - nightly 04:00 backup+verify, run one now
echo   [2]  Turn OFF           - disable the nightly schedule
echo   [3]  Back up NOW        - one immediate backup + test-restore
echo   [4]  Verify newest      - test-restore the newest backup only
echo   [5]  List backups
echo   [6]  Restore help       - how to restore a backup for real
echo   [7]  Refresh this screen
echo   [0]  Exit
echo  --------------------------------------------------
echo.
set "choice="
set /p "choice=Select an option then press Enter: "
if "%choice%"=="1" goto turnon
if "%choice%"=="2" goto turnoff
if "%choice%"=="3" goto runnow
if "%choice%"=="4" goto verifynow
if "%choice%"=="5" goto listnow
if "%choice%"=="6" goto restorehelp
if "%choice%"=="7" goto menu
if "%choice%"=="0" goto end
goto menu

:status
schtasks /query /tn "%TASK%" >nul 2>&1
if errorlevel 1 goto status_missing
schtasks /query /tn "%TASK%" /v /fo list | findstr /C:"Scheduled Task State:" /C:"Last Run Time:" /C:"Last Result:" /C:"Next Run Time:"
goto :eof
:status_missing
echo    NOT INSTALLED - use option [1] to install the nightly schedule.
goto :eof

:listbk
"%PY%" "%SCRIPT%" list
goto :eof

:turnon
echo.
schtasks /query /tn "%TASK%" >nul 2>&1
if errorlevel 1 goto turnon_install
echo Enabling the scheduled task...
schtasks /change /tn "%TASK%" /enable
goto turnon_run
:turnon_install
echo Task not found - installing a nightly 04:00 backup ^(runs while you are logged on^)...
schtasks /create /tn "%TASK%" /tr "%PY% %SCRIPT% backup --verify" /sc daily /st 04:00 /it /f
echo.
echo ^(For unattended backups that run even when logged off, re-create the task
echo  with  /ru SYSTEM  from an elevated prompt. The default needs you logged on.^)
:turnon_run
echo.
echo Running one backup + verify right now so you have a fresh copy immediately...
"%PY%" "%SCRIPT%" backup --verify
echo.
echo The nightly backup is ON ^(04:00 daily^). Backups land in D:\server-backups\db.
echo The first line above shows the file written; "verify OK" means it test-restored.
echo.
pause
goto menu

:turnoff
echo.
echo Disabling the scheduled task...
schtasks /change /tn "%TASK%" /disable
echo.
echo The nightly backup is OFF. Backups already on disk stay where they are;
echo no NEW backups will be taken until you turn it back on. You can still take
echo one manually any time with option [3].
echo.
pause
goto menu

:runnow
echo.
echo Taking a backup now and test-restoring it...
"%PY%" "%SCRIPT%" backup --verify
echo.
echo Done. "verify OK" / "PASS" above means the backup is restorable.
echo  ^(exit 1 = creds, 2 = tools/DB, 3 = backup failed, 4 = verify failed^)
echo.
pause
goto menu

:verifynow
echo.
echo Test-restoring the NEWEST backup into a throwaway DB...
"%PY%" "%SCRIPT%" verify
echo.
echo "PASS" means the newest backup restores cleanly. The temp DB is dropped
echo automatically; your live xidb is never touched by verify.
echo.
pause
goto menu

:listnow
echo.
"%PY%" "%SCRIPT%" list
echo.
pause
goto menu

:restorehelp
echo.
"%PY%" "%SCRIPT%" restore-help
echo.
pause
goto menu

:end
endlocal
exit /b 0

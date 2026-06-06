@echo off
REM ============================================================
REM Legendary FFXI - Apply SQL file changes to the LOCAL database
REM ============================================================
REM Double-click this after editing any SQL file to make the
REM change active in the LOCAL game server. It:
REM   1. Verifies the database is reachable
REM   2. Backs up the whole DB to sql\backups\  (restore point)
REM   3. Stops the server if it's running (item/mob/npc data only
REM      loads at map-server startup, so a restart is required)
REM   4. Reimports ALL sql\*.sql + modules\custom\sql\*.sql via
REM      dbtool, rebuilding game-data tables from the files
REM   5. Restarts the server (only if it was running before)
REM
REM SAFE: dbtool PROTECTS player tables (characters, inventory,
REM accounts, storage, etc.) - they are NOT dropped or reimported.
REM Only game-data tables (items, mobs, npcs, and your zz_ custom
REM files) are rebuilt from the SQL files - which is the point.
REM
REM A full reimport takes a couple of minutes - that is normal.
REM
REM LOCAL ONLY: this updates the database on THIS Windows machine.
REM To push the same changes to the LIVE Azure server, deploy them
REM there separately (git pull / scp the sql files, then on the box:
REM   mysql -u root -p xidb < sql/<file>.sql   - or - dbtool update full).
REM ============================================================

setlocal EnableExtensions
set "REPO_ROOT=%~dp0"
set "TOOLS=%REPO_ROOT%tools"
REM MariaDB client (same path kill-servers.bat uses). Edit if yours differs.
set "MYSQL=C:\Program Files\MariaDB 10.6\bin\mysql.exe"

echo.
echo ============================================================
echo  Legendary FFXI - Apply SQL changes to the LOCAL database
echo ============================================================
echo  Backs up the DB, then reimports every SQL file so your
echo  edits go live. Player characters/inventory are preserved.
echo  Takes a couple of minutes.
echo ============================================================
echo.
set "GO="
set /p "GO=Proceed? [Y/N] "
if /i not "%GO%"=="Y" (
    echo Cancelled - nothing was changed.
    pause
    exit /b 0
)

REM --- Sanity: MariaDB client present? -------------------------------
if not exist "%MYSQL%" (
    echo.
    echo ERROR: MariaDB client not found at:
    echo   %MYSQL%
    echo Edit the MYSQL= line near the top of this .bat to your real path.
    pause
    exit /b 1
)

REM --- Step 0: is the DB reachable? gate before doing anything -------
echo.
echo [1/5] Checking database connection...
"%MYSQL%" -h127.0.0.1 -uroot -pwarrior3 xidb -e "SELECT 1;" >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: cannot connect to the 'xidb' database.
    echo  - Is MariaDB running? ^(services.msc -^> MariaDB^)
    echo  - Do the creds match settings\network.lua ^(root / warrior3^)?
    echo Nothing was changed.
    pause
    exit /b 1
)
echo       OK.

REM --- Remember whether the server is up, so we can restart it -------
set "WAS_RUNNING="
tasklist /FI "IMAGENAME eq xi_map.exe" 2>nul | find /i "xi_map.exe" >nul && set "WAS_RUNNING=1"

REM --- Step 1: backup (silent dbtool skips this with auto_backup:0) --
echo.
echo [2/5] Backing up database to sql\backups\ ...
cd /d "%TOOLS%"
py -3 dbtool.py backup
if errorlevel 1 (
    echo.
    echo ERROR: backup step failed - ABORTING before any changes.
    pause
    exit /b 1
)
echo       Backup saved.

REM --- Step 2: stop the server if running ---------------------------
if defined WAS_RUNNING (
    echo.
    echo [3/5] Stopping server so new data loads on restart...
    call :stop_server
    echo       Server stopped.
) else (
    echo.
    echo [3/5] Server not running - skipping stop.
)

REM --- Step 3: full reimport ----------------------------------------
echo.
echo [4/5] Reimporting all SQL files ^(dbtool update full^)...
py -3 dbtool.py update full
if errorlevel 1 (
    echo.
    echo ============================================================
    echo  WARNING: dbtool reported an error. The DB may be partially
    echo  updated. A fresh backup is in sql\backups\ - restore via:
    echo     cd tools ^&^& py -3 dbtool.py   ^(menu -^> import backup^)
    echo  The server was NOT restarted.
    echo ============================================================
    pause
    exit /b 1
)
echo       Import finished.

REM --- Step 4: restart only if it was running before ----------------
if defined WAS_RUNNING (
    echo.
    echo [5/5] Restarting server...
    if exist "%REPO_ROOT%supervisor.stop" del /F "%REPO_ROOT%supervisor.stop" >nul 2>&1
    start "Legendary Supervisor" "%REPO_ROOT%start-supervisor.bat"
    echo       Supervisor relaunched in a new window.
) else (
    echo.
    echo [5/5] Server was not running - not starting it.
    echo       Run start-supervisor.bat when you want to play.
)

echo.
echo ============================================================
echo  DONE - your SQL changes are live in the LOCAL database.
echo ============================================================
pause
exit /b 0

REM ============================================================
REM Subroutine: stop the server cleanly, force-kill if it stalls
REM (kept out of the IF-blocks above; labels inside ( ) break batch)
REM ============================================================
:stop_server
> "%REPO_ROOT%supervisor.stop" echo stop
set /a TRIES=0
:ss_loop
tasklist /FI "IMAGENAME eq xi_map.exe" 2>nul | find /i "xi_map.exe" >nul
if errorlevel 1 goto :eof
set /a TRIES+=1
if %TRIES% GEQ 30 (
    echo       Supervisor slow to stop - force-killing binaries.
    taskkill /F /IM xi_map.exe     >nul 2>&1
    taskkill /F /IM xi_connect.exe >nul 2>&1
    taskkill /F /IM xi_world.exe   >nul 2>&1
    taskkill /F /IM xi_search.exe  >nul 2>&1
    ping -n 3 127.0.0.1 >nul
    goto :eof
)
ping -n 2 127.0.0.1 >nul
goto :ss_loop

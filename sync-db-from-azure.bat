@echo off
REM ============================================================
REM Legendary FFXI - Sync test DB from live Azure server
REM ============================================================
REM Dumps the live Azure DB and restores it into the local xidb.
REM Run this before a test session to get fresh live data.
REM
REM WARNING: This OVERWRITES your local xidb completely.
REM          Stop the local test server first (kill-servers.bat).
REM ============================================================

setlocal
set "KEY=C:\Users\richa\Downloads\ffxi-server_key.pem"
set "AZURE=azureuser@172.215.213.23"
set "MYSQL=C:\Program Files\MariaDB 10.6\bin\mysql.exe"
set "DUMP=%TEMP%\xidb_test_seed.sql"

echo [1/3] Dumping live DB from Azure...
ssh -i "%KEY%" %AZURE% "mysqldump -u xiuser -pwarrior3 xidb > /tmp/xidb_sync.sql"
if errorlevel 1 (
    echo ERROR: SSH/dump failed. Is the Azure server reachable?
    pause & exit /b 1
)

echo [2/3] Downloading dump...
scp -i "%KEY%" "%AZURE%:/tmp/xidb_sync.sql" "%DUMP%"
if errorlevel 1 (
    echo ERROR: SCP download failed.
    pause & exit /b 1
)

echo [3/3] Restoring into local xidb...
"%MYSQL%" -u root -pwarrior3 xidb < "%DUMP%"
if errorlevel 1 (
    echo ERROR: Restore failed.
    pause & exit /b 1
)

"%MYSQL%" -u root -pwarrior3 -e "SELECT COUNT(*) as chars FROM xidb.chars; SELECT COUNT(*) as accounts FROM xidb.accounts;" 2>nul

echo.
echo Done. Local test DB is now a snapshot of live.
echo Start the test server with: start-supervisor.bat
echo.
del "%DUMP%" 2>nul
pause

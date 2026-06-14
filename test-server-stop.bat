@echo off
title Stop Local Test Server
REM ============================================================
REM  Stop the local test server + redirect client back to Azure
REM
REM  What this does:
REM    1. Kills xi_map, xi_world, xi_connect, xi_search
REM    2. Clears accounts_sessions so next startup is clean
REM    3. Points Dad/Ryan back to the Azure live server
REM ============================================================

REM --- self-elevate to Administrator (hosts file needs it) ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator access to update hosts file...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "REPO=%~dp0"
set "MYSQL=C:\Program Files\MariaDB 10.6\bin\mysql.exe"
set "HOSTS=%WINDIR%\System32\drivers\etc\hosts"
set "AZURE_IP=172.215.213.23"

echo [1/3] Stopping local server processes...
taskkill /F /IM xi_map.exe     >nul 2>&1 && echo   xi_map     stopped. || echo   xi_map     not running.
taskkill /F /IM xi_connect.exe >nul 2>&1 && echo   xi_connect stopped. || echo   xi_connect not running.
taskkill /F /IM xi_world.exe   >nul 2>&1 && echo   xi_world   stopped. || echo   xi_world   not running.
taskkill /F /IM xi_search.exe  >nul 2>&1 && echo   xi_search  stopped. || echo   xi_search  not running.

echo.
echo [2/3] Clearing local sessions...
"%MYSQL%" -u root -pwarrior3 xidb -e "DELETE FROM accounts_sessions;" >nul 2>&1

echo.
echo [3/3] Pointing Dad/Ryan back to Azure (%AZURE_IP%)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$h = '%HOSTS%'; $c = Get-Content $h | Where-Object { ($_ -notmatch '\bRyan\b') -and ($_ -notmatch '\bDad\b') -and ($_ -notmatch 'LOCAL TEST SERVER') }; $c += '# Legendary server'; $c += '%AZURE_IP% Ryan'; $c += '%AZURE_IP% Dad'; Set-Content -Path $h -Value $c -Encoding ASCII"

if errorlevel 1 (
    echo ERROR: Could not update hosts file. Run Fix-Connection.bat manually.
) else (
    echo    Done. Dad/Ryan now point to Azure (%AZURE_IP%).
)

if exist "%REPO%supervisor.pid"  del /F "%REPO%supervisor.pid"
if exist "%REPO%supervisor.stop" del /F "%REPO%supervisor.stop"

echo.
echo ============================================================
echo  Test server stopped. You can now play on live (Azure).
echo  To refresh test DB from live: sync-db-from-azure.bat
echo ============================================================
echo.
pause

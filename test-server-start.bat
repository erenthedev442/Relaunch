@echo off
title Start Local Test Server
REM ============================================================
REM  Start the local test server + redirect client to localhost
REM
REM  What this does:
REM    1. Points Dad/Ryan -> 127.0.0.1 in hosts (needs Admin)
REM    2. Starts xi_connect, xi_world, xi_search, xi_map locally
REM
REM  After this: launch your FFXI client normally -- it will
REM  connect to the local server instead of Azure.
REM
REM  When done testing: run test-server-stop.bat
REM ============================================================

REM --- self-elevate to Administrator (hosts file needs it) ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator access to update hosts file...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "REPO=%~dp0"
set "HOSTS=%WINDIR%\System32\drivers\etc\hosts"
set "LOCAL_IP=127.0.0.1"

echo [1/2] Pointing Dad/Ryan to localhost...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$h = '%HOSTS%'; $c = Get-Content $h | Where-Object { ($_ -notmatch '\bRyan\b') -and ($_ -notmatch '\bDad\b') }; $c += '# LOCAL TEST SERVER'; $c += '%LOCAL_IP% Ryan'; $c += '%LOCAL_IP% Dad'; Set-Content -Path $h -Value $c -Encoding ASCII"

if errorlevel 1 (
    echo ERROR: Could not update hosts file.
    pause & exit /b 1
)
echo    Done. Dad/Ryan now point to 127.0.0.1.

echo.
echo [2/2] Starting local server (supervisor)...
start "Legendary TEST Server" /d "%REPO%" powershell.exe -ExecutionPolicy Bypass -NoProfile -NoExit -File "%REPO%supervisor.ps1"

echo.
echo ============================================================
echo  Local test server is starting up.
echo  Launch your FFXI client normally -- it will connect here.
echo  When done testing, run test-server-stop.bat
echo ============================================================
echo.
pause

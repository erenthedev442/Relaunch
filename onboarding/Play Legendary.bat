@echo off
title Play Legendary
REM ============================================================
REM  Play Legendary - one-click launcher
REM  Ashita must run as ADMINISTRATOR (it injects into FFXI),
REM  so this script self-elevates: you'll get a Windows "Yes/No"
REM  (UAC) prompt - click YES.
REM ============================================================

REM --- Are we already running as admin? (net session needs admin) ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator access ^(needed to launch the game^)...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

REM --- The server's lobby stage is advertised as host "Dad"; make sure that
REM     name resolves to the Legendary server so login can complete. ---
set "HOSTSFILE=%WINDIR%\System32\drivers\etc\hosts"
findstr /i /c:"Dad" "%HOSTSFILE%" >nul 2>&1
if errorlevel 1 (
    echo Adding server host entry ^(172.215.213.23 Dad^)...
    >>"%HOSTSFILE%" echo.
    >>"%HOSTSFILE%" echo 172.215.213.23 Dad
)

if not exist "Ashita-cli.exe" (
    echo.
    echo ERROR: Ashita-cli.exe is not in this folder.
    echo Make sure this .bat is inside the unzipped Legendary-Launcher folder.
    echo.
    pause
    exit /b
)

echo Launching Legendary...
Ashita-cli.exe Legendary.ini

echo.
echo ============================================================
echo  If the game did NOT open, the error is shown above.
echo  Copy that text and send it to your admin for a quick fix.
echo ============================================================
pause

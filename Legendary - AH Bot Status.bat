@echo off
setlocal
title AH Market-Maker Status
REM ============================================================================
REM  Legendary - AH Bot Status.bat
REM  Shows whether the AH market-maker is running + recent transaction history.
REM  Pipes tools\ah_status.sh to the Azure box and runs it. READ-ONLY: it only
REM  queries the live DB and reads the cron/log -- safe to run anytime.
REM ============================================================================
set "KEY=%USERPROFILE%\Downloads\ffxi-server_key.pem"
set "HOST=azureuser@172.215.213.23"
set "SSHOPT=-o StrictHostKeyChecking=accept-new -o ConnectTimeout=25"
set "SCRIPT=%~dp0tools\ah_status.sh"

if not exist "%SCRIPT%" (
  echo ERROR: cannot find "%SCRIPT%"
  echo This .bat must sit in your server folder, next to the "tools" folder.
  pause
  exit /b 1
)

echo Connecting to the server for AH bot status...
echo.
type "%SCRIPT%" | ssh -i "%KEY%" %SSHOPT% %HOST% "tr -d '\r' | bash -s"

echo.
pause

@echo off
setlocal
set KEY=%USERPROFILE%\Downloads\ffxi-server_key.pem
set HOST=azureuser@172.215.213.23

set HOURS=24
if not "%~1"=="" set HOURS=%~1

echo.
echo ============================================================
echo  GM AUDIT LOG  --  last %HOURS% hours
echo  (usage: gm_audit.bat [hours])
echo ============================================================
echo.

ssh -i "%KEY%" -o StrictHostKeyChecking=no %HOST% "sudo mysql xidb --table -e 'SELECT date_time, gm_name, command, full_string FROM audit_gm WHERE date_time > NOW() - INTERVAL %HOURS% HOUR ORDER BY date_time DESC LIMIT 200;'"

echo.
echo ============================================================
echo  SUMMARY  --  by GM and command
echo ============================================================
echo.

ssh -i "%KEY%" -o StrictHostKeyChecking=no %HOST% "sudo mysql xidb --table -e 'SELECT gm_name, command, COUNT(*) AS uses, MAX(date_time) AS last_used FROM audit_gm WHERE date_time > NOW() - INTERVAL %HOURS% HOUR GROUP BY gm_name, command ORDER BY gm_name, uses DESC;'"

echo.
pause

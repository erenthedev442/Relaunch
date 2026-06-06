@echo off
REM ============================================================
REM Legendary FFXI - Clear stale player login sessions
REM ============================================================
REM Wipes accounts_sessions so players who are stuck with
REM "Player already logged in" can reconnect immediately.
REM Safe to run while the server is up or down.
REM ============================================================

setlocal
set "MYSQL=C:\Program Files\MariaDB 10.6\bin\mysql.exe"

echo Clearing accounts_sessions...
"%MYSQL%" -u root -pwarrior3 xidb -e "DELETE FROM accounts_sessions; SELECT ROW_COUNT() AS rows_deleted;"

echo.
echo Done. Stale sessions cleared.
echo.
pause

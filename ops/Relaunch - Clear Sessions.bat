@echo off
title Relaunch - Clear Sessions
echo Clearing all login sessions (fixes "character already logged in" lockouts).
echo Safe to run anytime; affected players just log back in.
echo.
"C:\Program Files\MariaDB 10.6\bin\mysql.exe" -u root -prichard xi_relaunch -e "DELETE FROM accounts_sessions; SELECT ROW_COUNT() AS sessions_cleared;"
echo.
pause

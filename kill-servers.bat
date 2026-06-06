@echo off
REM ============================================================
REM Legendary FFXI - Force-kill all server processes
REM ============================================================
REM Use this when the supervisor isn't running or you need to
REM hard-stop everything immediately. Also clears accounts_sessions
REM so the next startup has a clean slate.
REM ============================================================

setlocal
set "MYSQL=C:\Program Files\MariaDB 10.6\bin\mysql.exe"
set "REPO=D:\server"

echo Killing server processes...
echo.

taskkill /F /IM xi_map.exe     >nul 2>&1 && echo   xi_map     stopped. || echo   xi_map     not running.
taskkill /F /IM xi_connect.exe >nul 2>&1 && echo   xi_connect stopped. || echo   xi_connect not running.
taskkill /F /IM xi_world.exe   >nul 2>&1 && echo   xi_world   stopped. || echo   xi_world   not running.
taskkill /F /IM xi_search.exe  >nul 2>&1 && echo   xi_search  stopped. || echo   xi_search  not running.

echo.
echo Clearing accounts_sessions...
"%MYSQL%" -u root -pwarrior3 xidb -e "DELETE FROM accounts_sessions; SELECT ROW_COUNT() AS sessions_cleared;"

echo.
REM Clean up supervisor bookkeeping files so start-supervisor.bat
REM doesn't trip over stale state from the previous run.
if exist "%REPO%\supervisor.pid"  del /F "%REPO%\supervisor.pid"
if exist "%REPO%\supervisor.stop" del /F "%REPO%\supervisor.stop"

echo All done. Run start-supervisor.bat to bring servers back up.
echo.
pause

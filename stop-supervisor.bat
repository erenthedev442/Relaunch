@echo off
REM ============================================================
REM Legendary FFXI - Stop the server supervisor cleanly
REM ============================================================
REM Drops a sentinel file (supervisor.stop) that the running
REM supervisor checks every 500ms. On detection, the supervisor
REM:
REM   1. Logs "stop file detected"
REM   2. Kills xi_connect / xi_world / xi_search / xi_map
REM   3. Exits cleanly
REM
REM This is the preferred way to shut down because it triggers
REM the supervisor's `finally` block (no orphaned processes).
REM If the supervisor isn't running, this is a harmless no-op
REM (the file just sits there until you start the supervisor,
REM which clears it on startup).
REM ============================================================

setlocal
set "REPO_ROOT=%~dp0"

echo Requesting supervisor shutdown via %REPO_ROOT%supervisor.stop ...
echo stop > "%REPO_ROOT%supervisor.stop"

REM Give the supervisor up to 10 seconds to notice + tear down.
echo Waiting up to 10s for supervisor to release its PID file...
set "PIDFILE=%REPO_ROOT%supervisor.pid"
set /a TRIES=0
:waitloop
if not exist "%PIDFILE%" goto done
set /a TRIES+=1
if %TRIES% GEQ 10 goto timeout
ping -n 2 127.0.0.1 >nul
goto waitloop

:timeout
echo.
echo WARNING: supervisor.pid still present after 10s. The supervisor may
echo be stuck, or it isn't running. Check its console window. If you
echo need to kill it forcibly, use Task Manager to end the powershell.exe
echo whose PID matches the contents of %PIDFILE%.
echo.
goto end

:done
echo Supervisor shut down cleanly.

:end
endlocal
pause

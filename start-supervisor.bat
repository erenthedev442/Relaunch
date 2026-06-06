@echo off
REM ============================================================
REM Legendary FFXI - Start the server supervisor
REM ============================================================
REM Double-click this file to launch the supervisor. It will
REM open a console window that:
REM   - Starts xi_connect, xi_world, xi_search, xi_map
REM   - Watches all 4 processes
REM   - On any crash, kills the other 3 and restarts all 4
REM   - Logs everything to D:\server\supervisor.log
REM
REM To stop the supervisor cleanly:
REM   - Press Ctrl+C in the supervisor's console window, OR
REM   - Run stop-supervisor.bat (creates a stop-file the
REM     supervisor checks every 500ms).
REM ============================================================

setlocal
set "REPO_ROOT=%~dp0"
cd /d "%REPO_ROOT%"

REM -ExecutionPolicy Bypass: don't require the user to set machine
REM policy just to run our own script.
REM -NoExit: keep the window open after the script ends so the user
REM can read final log lines / errors before it closes.
REM Note: PowerShell honors Ctrl+C natively and runs the supervisor's
REM `finally` block on its way out, so cleanup is automatic.
powershell.exe -ExecutionPolicy Bypass -NoProfile -NoExit -File "%REPO_ROOT%supervisor.ps1"

@echo off
title Relaunch - Deploy
echo =================================================================
echo   RELAUNCH DEPLOY  (runs locally on the VPS, targets C:\server)
echo   Pull latest relaunch code, apply zz_ SQL, restart the servers.
echo   For Lua/SQL/settings changes. C++ (src\*.cpp) changes need a
echo   full rebuild first -- this bat does NOT rebuild binaries.
echo =================================================================
echo.
pushd C:\server

echo --- git pull (origin/relaunch, fast-forward only) ---
git pull --ff-only origin relaunch
if errorlevel 1 (
  echo.
  echo [STOP] git pull failed ^(local commits/conflicts, or auth^). Nothing changed.
  echo        Resolve in C:\server manually, then re-run.
  popd
  pause
  exit /b 1
)
echo.

echo --- apply custom SQL (sql\zz_*.sql) ---
call apply-custom-sql.bat
echo.

echo --- restart servers (stop supervisor + kill, then start task) ---
schtasks /end /tn "FFXIRelaunch" >nul 2>&1
powershell -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'powershell.exe' -and $_.CommandLine -match 'relaunch-supervisor' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }; foreach($p in 'xi_map','xi_connect','xi_world','xi_search'){ Get-Process $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue }; Start-Sleep 2"
schtasks /run /tn "FFXIRelaunch" >nul 2>&1
echo.
echo Deploy complete. Servers restarting (map ~1-2 min to finish loading).
echo Check "Relaunch - Status" and "Relaunch - Map Logs".
popd
pause

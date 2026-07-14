@echo off
title Relaunch - Full Rebuild
echo ============================================================
echo   RELAUNCH FULL REBUILD  (runs locally on this VPS, C:\server)
echo.
echo   [1] git pull origin relaunch      (latest pushed code)
echo   [2] stop servers + back up binaries
echo   [3] apply modules\custom\sql\*.sql to xi_relaunch
echo   [4] C++ rebuild (MSVC / Ninja, Release)
echo   [5] restart servers + health check
echo.
echo   Players DISCONNECT during the rebuild (~2-5 min).
echo   If the build fails, the previous binaries are restored
echo   automatically so the server still comes back up.
echo   Website (www.ffxi-legendary.com) is NOT published here.
echo ============================================================
echo.
set "GO="
set /p GO="   Proceed with full rebuild? [Y/N]:  "
if /i not "%GO%"=="Y" ( echo   Cancelled - nothing changed.& echo.& pause & exit /b 0 )
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File C:\server\vps-rebuild.ps1
echo.
pause

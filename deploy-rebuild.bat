@echo off
echo.
echo  =================================================================
echo   DISABLED (2026-07-02) -- do not use from the RELAUNCH worktree.
echo.
echo   This bat was a stale copy from the Legendary branch and still
echo   targeted the LIVE server (/home/azureuser/server). Running it
echo   from D:\server_relaunch sprayed relaunch src/ into the live
echo   tree, so every later live rebuild silently baked in relaunch
echo   code (recurring Martial Wraps / Giuoco Grip regression).
echo.
echo   Deploy LIVE      from D:\server (Deploy Everything).
echo   Deploy RELAUNCH  with relaunch-rebuild.bat / relaunch-*.bat
echo                    (targets /home/azureuser/relaunch).
echo  =================================================================
echo.
pause
exit /b 1

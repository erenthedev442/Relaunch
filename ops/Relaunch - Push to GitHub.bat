@echo off
title Relaunch - Push to GitHub
echo ============================================================
echo   BACK UP C:\server TO GITHUB  (origin/relaunch)
echo   Commits + pushes all tracked changes (code + ops tooling).
echo   settings\*.lua, build\, and the .exe binaries are gitignored.
echo   Run this from the VPS RDP session (GitHub login works here).
echo ============================================================
echo.
pushd C:\server
echo === Changes that will be backed up ===
git status --short
echo.
set "GO="
set /p GO="   Commit + push everything above to GitHub? [Y/N]:  "
if /i not "%GO%"=="Y" ( echo   Cancelled - nothing pushed.& echo.& popd & pause & exit /b 0 )
git add -A
git commit -m "VPS backup %DATE% %TIME%"
git push origin relaunch
echo.
echo Done. (A push summary or 'Everything up-to-date' above = success.)
echo If it asked you to sign in to GitHub, that is a one-time credential setup.
popd
echo.
pause

@echo off
setlocal
title Legendary - Azure Rebuild (box-only, no laptop files)

REM ============================================================
REM  azure-rebuild.bat  -  recompile + restart the AZURE server
REM  using ONLY the source already on the box.
REM
REM  Ships NOTHING from this laptop and never touches the local
REM  database. The whole job runs on the Azure box: it verifies the
REM  core patches (if that script is present), backs up the live DB,
REM  compiles the C++ already in the box's source tree, then restarts.
REM
REM  USE THIS TO: build engine changes that were previously deployed
REM  to the box but not yet compiled, or just recompile the binaries.
REM
REM  IMPORTANT: this rebuilds the box's CURRENT source. It does NOT
REM  fetch new code -- ~/server on the box is NOT a git checkout. To
REM  put NEW local changes on the box first, use deploy-everything.bat.
REM
REM  Downtime: the compile runs while the server stays UP on the old
REM  binary; only the final restart drops players (~5 seconds).
REM ============================================================

set "KEY=C:\Users\richa\Downloads\ffxi-server_key.pem"
set "HOST=azureuser@172.215.213.23"
set "REMOTE=/home/azureuser/server"
set "SSHOPT=-o StrictHostKeyChecking=accept-new"

echo(
echo   AZURE REBUILD (box-only)
echo   - recompiles the source ALREADY on the Azure box, then restarts
echo   - ships NOTHING from this laptop; local DB is never touched
echo   - does NOT fetch new code (use deploy-everything.bat for that)
echo(
set "GO="
set /p GO="   Proceed? [Y/N]:  "
if /i not "%GO%"=="Y" ( echo   Cancelled - nothing changed.& goto :end )

echo(
echo   Running on the box (compile keeps the server UP; restart at the end)...
echo(
ssh -i "%KEY%" %SSHOPT% %HOST% "cd %REMOTE% && echo '[1/4] verify core patches (if present)...' && { if [ -f tools/verify_core_patches.py ] && command -v python3 >/dev/null 2>&1; then python3 tools/verify_core_patches.py || { echo '   CORE-PATCH VERIFY FAILED - aborting, nothing rebuilt.'; exit 7; }; else echo '   (verify script not on box yet - skipping)'; fi; } && echo '[2/4] backing up live DB...' && mkdir -p sql/backups && (sudo mariadb-dump xidb > sql/backups/prerebuild-$(date +%%Y%%m%%d-%%H%%M%%S).sql 2>/dev/null && echo '   saved' || echo '   (backup skipped)') && echo '[3/4] compiling (server stays UP on old binary)...' && cmake --build build -j2 && echo '[4/4] restarting (brief disconnect)...' && (sudo systemctl restart xi 2>/dev/null || sudo systemctl restart xi_map xi_connect xi_search xi_world) && echo REBUILD-OK"
set "RC=%ERRORLEVEL%"

echo(
if "%RC%"=="0" (
    echo   ============================================================
    echo    Azure rebuild complete - new binary live, server restarted.
    echo   ============================================================
) else (
    echo   ============================================================
    echo    Azure rebuild FAILED ^(exit %RC%^) - see the output above.
    echo    If the compile failed, the server was NOT restarted.
    echo   ============================================================
)
echo(
pause
:end

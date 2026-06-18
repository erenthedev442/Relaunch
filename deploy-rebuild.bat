@echo off
setlocal
title Legendary - Deploy + Rebuild

REM ============================================================
REM  Legendary - Deploy + Rebuild
REM
REM  Commits, ships everything to Azure, rebuilds C++, applies
REM  all SQL, and restarts xi_map.  Skips gear re-scoring and
REM  site publish (run deploy-everything.bat for the full flow).
REM
REM    [0] Verify core LSB patches are intact
REM    [1] Git commit + push  (backup to fjb)
REM    [2] Pack + ship  modules/custom + scripts + tools + src
REM    [3] Upload sql/zz_*.sql
REM    [4] Rebuild C++ + apply SQL + restart + health-check
REM ============================================================

set "KEY=C:\Users\richa\Downloads\ffxi-server_key.pem"
set "HOST=azureuser@172.215.213.23"
set "SRC=D:\server"
set "REMOTE=/home/azureuser/server"
set "TGZ=%TEMP%\fjb_rebuild.tgz"
set "OUT=%TEMP%\fjb_rebuild_out.txt"
set "SSHOPT=-o StrictHostKeyChecking=accept-new"
set "LOG=%SRC%\deploy-rebuild.log"
set "SRVOK=skipped"

(echo === Deploy + Rebuild started %DATE% %TIME% ===)> "%LOG%"

echo(
echo   DEPLOY + REBUILD:  commit  -^>  ship files  -^>  C++ rebuild  -^>  SQL  -^>  restart
echo   No gear re-score or site publish.  Build step takes several minutes.
echo   Step-by-step log:  %LOG%
echo(
set "GO="
set /p GO="   Proceed? [Y/N]:  "
if /i not "%GO%"=="Y" ( echo   Cancelled - nothing changed.& goto :end )

REM ---- [0] Verify core LSB patches ----
echo(
echo  [0/4] Verifying core LSB patches are intact...
python "%SRC%\tools\verify_core_patches.py"
if errorlevel 1 goto :patchwarn
goto :patchok
:patchwarn
echo(
echo   ============================================================
echo    WARNING: one or more CORE PATCHES look REVERTED (see above).
echo    Deploying now would push code MISSING your customizations.
echo    Fix: reference_lsb_core_patches.md  /  git diff 54bd6e24f9 HEAD
echo   ============================================================
set "PGO="
set /p PGO="   Deploy anyway? [y/N]:  "
if /i not "%PGO%"=="Y" ( echo   Aborted - re-apply the patches, then re-run.& goto :end )
:patchok

REM ---- [1] Git commit + push ----
echo(
echo  [1/4] Committing + pushing all changes to GitHub (backup)...
(echo [%TIME%] [1/4] git: start)>> "%LOG%"
git -C "%SRC%" add -A
set "DEPLOYMSG=%TEMP%\fjb_deploy_msg.txt"
(echo Deploy + Rebuild %DATE% %TIME%)> "%DEPLOYMSG%"
(echo.)>> "%DEPLOYMSG%"
git -C "%SRC%" diff --cached --name-status >> "%DEPLOYMSG%"
git -C "%SRC%" commit -F "%DEPLOYMSG%" >> "%LOG%" 2>&1
del "%DEPLOYMSG%" >nul 2>&1
powershell -NoProfile -Command "$j=Start-Job { git -C 'D:\server' push fjb HEAD 2>&1 }; if (Wait-Job $j -Timeout 90) { Receive-Job $j } else { Stop-Job $j; 'push timed out (sign-in popup?) - skipped; run: git push fjb HEAD' }; Remove-Job $j -Force" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
(echo [%TIME%] [1/4] git: done)>> "%LOG%"

REM ---- [2] Pack + ship all files ----
REM   --exclude=scripts/specs: the ---@meta stubs (Globals.lua etc.) CLOBBER
REM   the real C++ bindings if hot-reloaded by FileWatcher on the live box.
echo(
echo  [2/4] Packing + shipping modules/custom, scripts, tools, src to Azure...
(echo [%TIME%] [2/4] pack+upload+install: start)>> "%LOG%"
tar -czf "%TGZ%" -C "%SRC%" --exclude=scripts/specs modules/custom scripts tools src
if errorlevel 1 ( echo        ERROR: tar failed -- skipping server deploy.& set "SRVOK=PROBLEM"& goto :finish )
scp -i "%KEY%" %SSHOPT% "%TGZ%" %HOST%:/tmp/fjb_rebuild.tgz
if errorlevel 1 ( echo        ERROR: scp failed -- skipping server deploy.& set "SRVOK=PROBLEM"& goto :finish )
del "%TGZ%" >nul 2>&1
ssh -i "%KEY%" %SSHOPT% %HOST% "cd %REMOTE% && rm -f /tmp/fjb_extract_ok && sudo tar -czf $HOME/predeploy-$(date +%%Y%%m%%d-%%H%%M%%S).tgz modules/custom scripts tools 2>/dev/null && ls -t $HOME/predeploy-*.tgz | tail -n +6 | xargs -r rm -f; sudo tar -xzf /tmp/fjb_rebuild.tgz -C %REMOTE% --no-same-owner && sudo chown -R xi:xi %REMOTE%/modules/custom %REMOTE%/scripts %REMOTE%/tools %REMOTE%/src && touch /tmp/fjb_extract_ok; rm -f /tmp/fjb_rebuild.tgz; test -f /tmp/fjb_extract_ok && echo   files-OK; rm -f /tmp/fjb_extract_ok" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"files-OK" "%OUT%" >nul
if errorlevel 1 ( echo        ERROR: extract/install failed -- skipping rebuild.& set "SRVOK=PROBLEM"& goto :finish )
(echo [%TIME%] [2/4] install: OK)>> "%LOG%"

REM ---- [3] Upload sql/zz_*.sql ----
REM   Two-step via /tmp: sql/ is xi:xi-owned so a direct scp gets EPERM.
echo  Uploading sql/zz_*.sql to box...
ssh -i "%KEY%" %SSHOPT% %HOST% "rm -rf /tmp/fjb_zz && mkdir -p /tmp/fjb_zz" >> "%LOG%" 2>&1
for %%F in ("%SRC%\sql\zz_*.sql") do (
    scp -i "%KEY%" %SSHOPT% "%%F" %HOST%:/tmp/fjb_zz/ >> "%LOG%" 2>&1
)
ssh -i "%KEY%" %SSHOPT% %HOST% "sudo cp /tmp/fjb_zz/*.sql %REMOTE%/sql/ && sudo chown xi:xi %REMOTE%/sql/zz_*.sql && rm -rf /tmp/fjb_zz && echo   zz-sql-installed" >> "%LOG%" 2>&1
(echo [%TIME%] [3] zz_*.sql upload done)>> "%LOG%"

REM ---- [4] Rebuild C++ + apply SQL + restart ----
echo(
echo  [4/4] Rebuilding C++ + applying ALL SQL + restarting Azure (several minutes)...
(echo [%TIME%] [4/4] rebuild+restart: start)>> "%LOG%"
type nul > "%OUT%"
start "Legendary - Build Progress" powershell -NoProfile -Command "Get-Content -Path '%OUT%' -Wait | ForEach-Object { Write-Host $_; if ($_ -match 'DONE - rebuilt|build failed|NOT restarted') { Start-Sleep 2; break } }"
ssh -i "%KEY%" %SSHOPT% %HOST% "tr -d '\015' < %REMOTE%/tools/_azure_update_remote.sh > /tmp/_au.sh && bash /tmp/_au.sh; rm -f /tmp/_au.sh" >> "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"

REM Capture build outcome before health-check overwrites %OUT%.
set "BUILDFAIL="
findstr /c:"build failed" "%OUT%" >nul && set "BUILDFAIL=1"
findstr /c:"build OK." "%OUT%" >nul || findstr /c:"skipping rebuild" "%OUT%" >nul || set "BUILDFAIL=1"
(echo [%TIME%] [4/4] rebuild outcome: BUILDFAIL=%BUILDFAIL%)>> "%LOG%"

REM Health check
ssh -i "%KEY%" %SSHOPT% %HOST% "for s in xi_map xi_world xi_search xi_connect; do echo    $s=$(systemctl is-active $s); done; echo '   --- recent map errors (none below = clean) ---'; sudo journalctl -u xi_map --since '2 min ago' --no-pager 2>/dev/null | grep -iE 'attempt to|stack traceback|\.lua:[0-9]+:|\[error\]|fatal' | head -8" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"xi_map=active" "%OUT%" >nul
if errorlevel 1 (
    echo        WARNING: xi_map not confirmed active - check output above.
    set "SRVOK=PROBLEM"
) else if defined BUILDFAIL (
    echo        ERROR: C++ REBUILD FAILED -- old binary still running. Fix the build + re-deploy.
    set "SRVOK=BUILD FAILED"
) else (
    echo        server live.
    set "SRVOK=OK"
)
(echo [%TIME%] [4/4] done - SRVOK=%SRVOK%)>> "%LOG%"

:finish
echo(
echo   ===========================================================
echo   Deploy + Rebuild finished.
echo     Server:  %SRVOK%
echo   Full log:  %LOG%
echo   Rollback: restore newest ~/predeploy-*.tgz on the box.
echo   ===========================================================
(echo [%TIME%] DONE - server=%SRVOK%)>> "%LOG%"
powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; [void][System.Windows.Forms.MessageBox]::Show('Deploy + Rebuild finished.'+[Environment]::NewLine+'Server: %SRVOK%'+[Environment]::NewLine+[Environment]::NewLine+'Full log: %LOG%','Legendary - Deploy + Rebuild')" >nul 2>&1

:end
echo(
pause

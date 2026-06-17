@echo off
setlocal
title Legendary - Deploy (No Rebuild)

REM ============================================================
REM  Legendary - Deploy (No Rebuild)   -- Lua / SQL changes only
REM
REM  Same as deploy-everything.bat but SKIPS the C++ rebuild
REM  (cmake --build, the slowest step). Run this whenever ALL
REM  pending changes are Lua or SQL -- nothing in src/ touched.
REM  Takes ~2 min instead of ~10.
REM
REM    [1] re-score ALL gear catalogs from live data
REM    [2] commit + push working tree to GitHub (backup)
REM    [3] ship modules/custom + scripts + tools to Azure
REM        (no src/); extract while server stays up -- step [4] restarts
REM    [4] git pull + apply ALL changed SQL + restart + health-check
REM    [5] publish the website FROM THE BOX (live db)
REM
REM  ** If any src/ C++ file changed: run deploy-everything.bat **
REM ============================================================

set "KEY=C:\Users\richa\Downloads\ffxi-server_key.pem"
set "HOST=azureuser@172.215.213.23"
set "SRC=D:\server"
set "REMOTE=/home/azureuser/server"
set "TGZ=%TEMP%\fjb_nrb.tgz"
set "OUT=%TEMP%\fjb_nrb_out.txt"
set "SSHOPT=-o StrictHostKeyChecking=accept-new"
set "SITE_BAT=D:\server\.claude\worktrees\busy-johnson-c59e6e\refresh-site.bat"
set "LOG=%SRC%\deploy-no-rebuild.log"
set "SRVOK=skipped"
set "SITEOK=skipped"

(echo === Deploy No-Rebuild started %DATE% %TIME% ===)> "%LOG%"

echo(
echo   DEPLOY (NO REBUILD):  Lua/SQL only -- C++ rebuild skipped.
echo   Re-score ^> GitHub backup ^> Azure file sync ^> SQL reload ^> site publish.
echo   Use deploy-everything.bat if any src/ C++ file was changed.
echo   Step-by-step log:  %LOG%
echo(
set "GO="
set /p GO="   Proceed? [Y/N]:  "
if /i not "%GO%"=="Y" ( echo   Cancelled - nothing changed.& goto :end )

REM ---- [0] VERIFY core LSB patches survived (merge/revert tripwire) ----
REM   Also covers the Lua-side patches this no-rebuild deploy ships
REM   (damage cap Lua, init.txt, CP-suppression enum, etc.).
echo(
echo  [0/5] Verifying core LSB patches are intact...
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

REM ---- [1] Re-score gear catalogs ----
echo(
echo  [1/5] Re-scoring ALL gear catalogs from live data...
(echo [%TIME%] [1/5] re-score: start)>> "%LOG%"
if not exist "%SITE_BAT%" ( echo        ERROR: re-score script not found - aborting.& set "SITEOK=MISSING"& goto :finish )
set "LEGENDARY_AUTO_PUBLISH=1"
call "%SITE_BAT%"
set "LEGENDARY_AUTO_PUBLISH="
set "SITEOK=rescored; box publish pending"
(echo [%TIME%] [1/5] re-score returned)>> "%LOG%"

REM ---- [2] Commit + push to GitHub ----
echo(
echo  [2/5] Committing + pushing all changes to GitHub (backup)...
(echo [%TIME%] [2/5] git add/commit/push: start)>> "%LOG%"
git -C "%SRC%" add -A
git -C "%SRC%" commit -m "Deploy (No Rebuild) %DATE% %TIME%" >> "%LOG%" 2>&1
powershell -NoProfile -Command "$j=Start-Job { git -C 'D:\server' push fjb HEAD 2>&1 }; if (Wait-Job $j -Timeout 90) { Receive-Job $j } else { Stop-Job $j; 'push timed out (sign-in popup?) - skipped; run: git push fjb HEAD' }; Remove-Job $j -Force" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
(echo [%TIME%] [2/5] git: done)>> "%LOG%"

REM ---- [3] Ship files + extract + apply custom SQL ----
REM   src/ intentionally excluded -- not rebuilding C++.
echo(
echo  [3/5] Shipping modules/custom + scripts + tools to Azure (server stays up during extract)...
(echo [%TIME%] [3/5] pack+upload+install: start)>> "%LOG%"
tar -czf "%TGZ%" -C "%SRC%" modules/custom scripts tools
if errorlevel 1 ( echo        ERROR: tar failed -- skipping server deploy.& set "SRVOK=PROBLEM"& goto :finish )
scp -i "%KEY%" %SSHOPT% "%TGZ%" %HOST%:/tmp/fjb_nrb.tgz
if errorlevel 1 ( echo        ERROR: scp of bundle failed -- skipping server deploy.& set "SRVOK=PROBLEM"& goto :finish )
del "%TGZ%" >nul 2>&1
ssh -i "%KEY%" %SSHOPT% %HOST% "cd %REMOTE% && rm -f /tmp/fjb_nrb_ok && sudo tar -czf $HOME/predeploy-$(date +%%Y%%m%%d-%%H%%M%%S).tgz modules/custom scripts tools 2>/dev/null && ls -t $HOME/predeploy-*.tgz | tail -n +6 | xargs -r rm -f; sudo tar -xzf /tmp/fjb_nrb.tgz -C %REMOTE% --no-same-owner && sudo chown -R xi:xi %REMOTE%/modules/custom %REMOTE%/scripts %REMOTE%/tools && touch /tmp/fjb_nrb_ok; rm -f /tmp/fjb_nrb.tgz; test -f /tmp/fjb_nrb_ok && echo   files-OK; rm -f /tmp/fjb_nrb_ok" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"files-OK" "%OUT%" >nul
if errorlevel 1 ( echo        ERROR: install / custom-SQL step failed.& set "SRVOK=PROBLEM"& goto :finish )
(echo [%TIME%] [3/5] install: OK)>> "%LOG%"

REM ---- 3b. Upload sql/zz_*.sql so _apply_changed_sql.sh has fresh copies. ----
echo  Uploading sql/zz_*.sql to box...
for %%F in ("%SRC%\sql\zz_*.sql") do (
    scp -i "%KEY%" %SSHOPT% "%%F" %HOST%:%REMOTE%/sql/ >> "%LOG%" 2>&1
)
(echo [%TIME%] [3b] zz_*.sql upload done)>> "%LOG%"

REM ---- [4] git pull + apply ALL changed SQL + restart (no C++ rebuild) ----
echo(
echo  [4/5] Applying ALL changed SQL + restarting xi_map (no rebuild)...
(echo [%TIME%] [4/5] sql+restart: start)>> "%LOG%"
ssh -i "%KEY%" %SSHOPT% %HOST% "cd %REMOTE% && mkdir -p sql/backups; BK=sql/backups/predeploy-$(date +%%Y%%m%%d-%%H%%M%%S).sql; sudo mariadb-dump xidb > $BK 2>/dev/null || sudo mysqldump xidb > $BK 2>/dev/null && echo '   backup: '$BK || echo '   WARNING: backup skipped'; git pull --ff-only 2>&1 | tail -2; bash tools/_apply_changed_sql.sh && (sudo systemctl restart xi 2>/dev/null || sudo systemctl restart xi_map xi_connect xi_search xi_world) && echo restart OK." > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"restart OK." "%OUT%" >nul
if errorlevel 1 ( echo        ERROR: SQL apply or restart failed -- check output above.& set "SRVOK=PROBLEM" ) else ( set "SRVOK=precheck" )
(echo [%TIME%] [4/5] sql+restart: done)>> "%LOG%"

REM Health check
ssh -i "%KEY%" %SSHOPT% %HOST% "for s in xi_map xi_world xi_search xi_connect; do echo    $s=$(systemctl is-active $s); done; echo '   --- recent map errors (none below = clean) ---'; sudo journalctl -u xi_map --since '2 min ago' --no-pager 2>/dev/null | grep -iE 'attempt to|stack traceback|\.lua:[0-9]+:|\[error\]|fatal' | head -8" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"xi_map=active" "%OUT%" >nul
if errorlevel 1 ( echo        WARNING: xi_map not confirmed active - check output above.& set "SRVOK=PROBLEM" ) else if not "%SRVOK%"=="PROBLEM" ( echo        server live.& set "SRVOK=OK" )
(echo [%TIME%] [4/5] health: SRVOK=%SRVOK%)>> "%LOG%"

REM ---- [5] Publish site from the box ----
echo(
echo  [5/5] Publishing the website from the Azure box (live db -^> correct players)...
(echo [%TIME%] [5/5] box publish: start)>> "%LOG%"
ssh -i "%KEY%" %SSHOPT% %HOST% "bash ~/server/tools/refresh_site_azure.sh; tail -3 ~/refresh_site.log" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"refresh_site DONE" "%OUT%" >nul
if errorlevel 1 ( echo        WARNING: box publish not confirmed - check output above.& set "SITEOK=PROBLEM" ) else ( echo        website published from box.& set "SITEOK=OK" )
(echo [%TIME%] [5/5] box publish: SITEOK=%SITEOK%)>> "%LOG%"

:finish
echo(
echo   ===========================================================
echo   Deploy (No Rebuild) finished.
echo     Website:  %SITEOK%
echo     Server:   %SRVOK%
echo   Full log:   %LOG%
echo   If C++ changes needed: run deploy-everything.bat instead.
echo   ===========================================================
(echo [%TIME%] DONE - website=%SITEOK% server=%SRVOK%)>> "%LOG%"
powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; [void][System.Windows.Forms.MessageBox]::Show('Deploy (No Rebuild) finished.'+[Environment]::NewLine+'Website: %SITEOK%'+[Environment]::NewLine+'Server: %SRVOK%'+[Environment]::NewLine+[Environment]::NewLine+'Full log: %LOG%','Legendary - Deploy (No Rebuild)')" >nul 2>&1

:end
echo(
pause

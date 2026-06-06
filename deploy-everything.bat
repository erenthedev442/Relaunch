@echo off
setlocal
title Legendary - Deploy Everything

REM ============================================================
REM  Legendary - Deploy Everything   (server + website, one click)
REM
REM  Captures ALL your changes and pushes them live everywhere:
REM    [1] re-score gear catalogs (rebalance_all)
REM    [2] commit + push the whole working tree to GitHub (fjb) - backup
REM    [3] deploy content + code to the Azure SERVER (file sync) +
REM        auto-apply changed modules/custom/sql
REM    [4] rebuild C++ + reload zz_*.sql + restart + health-check
REM    [5] refresh + publish the WEBSITE (docs -> Cloudflare Pages)
REM
REM  ** EVERY step is timestamped into deploy-everything.log (next to this
REM     script). If the window ever closes early, open that log to see the
REM     exact step it reached. A popup confirms when the run finishes. **
REM
REM  network.lua / DB / navmeshes are never touched; a pre-deploy backup
REM  is saved on the box (~/predeploy-*.tgz) and the DB is dumped first.
REM ============================================================

set "KEY=C:\Users\richa\Downloads\ffxi-server_key.pem"
set "HOST=azureuser@172.215.213.23"
set "SRC=D:\server"
set "REMOTE=/home/azureuser/server"
set "TGZ=%TEMP%\fjb_full.tgz"
set "OUT=%TEMP%\fjb_de_out.txt"
set "SSHOPT=-o StrictHostKeyChecking=accept-new"
set "SITE_BAT=D:\server\.claude\worktrees\busy-johnson-c59e6e\refresh-site.bat"
set "LOG=%SRC%\deploy-everything.log"
set "SRVOK=skipped"
set "SITEOK=skipped"

(echo === Deploy Everything run started %DATE% %TIME% ===)> "%LOG%"

echo(
echo   DEPLOY EVERYTHING:  re-score  -^>  GitHub backup  -^>  Azure server  -^>  website
echo   Full release - C++ rebuild + site build can take several minutes.
echo   Step-by-step log:  %LOG%
echo(
set "GO="
set /p GO="   Proceed? [Y/N]:  "
if /i not "%GO%"=="Y" ( echo   Cancelled - nothing changed.& (echo [%TIME%] cancelled by user)>>"%LOG%"& goto :end )

REM ---- 1. Re-score gear catalogs (shown on console; markers in log) ----
echo(
echo  [1/6] Re-scoring gear catalogs (rebalance_all)...
(echo [%TIME%] [1/6] rebalance: start)>> "%LOG%"
call "%SRC%\tools\rebalance_all.bat"
if errorlevel 1 ( echo        WARNING: rebalance reported an issue - continuing with catalogs on disk.& (echo [%TIME%] [1/6] rebalance: WARNING)>>"%LOG%" ) else ( (echo [%TIME%] [1/6] rebalance: OK)>>"%LOG%" )

REM ---- 2. Commit + push the working tree to GitHub (push time-boxed to 90s) ----
echo(
echo  [2/6] Committing + pushing all changes to GitHub (backup)...
(echo [%TIME%] [2/6] git add/commit/push: start)>> "%LOG%"
git -C "%SRC%" add -A
git -C "%SRC%" commit -m "Deploy Everything %DATE% %TIME%" >> "%LOG%" 2>&1
powershell -NoProfile -Command "$j=Start-Job { git -C 'D:\server' push fjb HEAD 2>&1 }; if (Wait-Job $j -Timeout 90) { Receive-Job $j } else { Stop-Job $j; 'push timed out (sign-in popup?) - skipped; run: git push fjb HEAD' }; Remove-Job $j -Force" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
(echo [%TIME%] [2/6] git: done)>> "%LOG%"

REM ---- 3. Pack server content + code ----
echo(
echo  [3/6] Packing server bundle (modules/custom + scripts + tools + src)...
(echo [%TIME%] [3/6] tar: start)>> "%LOG%"
tar -czf "%TGZ%" -C "%SRC%" modules/custom scripts tools src
if errorlevel 1 ( echo        ERROR: tar failed -- skipping server deploy.& (echo [%TIME%] [3/6] tar: FAILED - skip server)>>"%LOG%"& goto :site )
(echo [%TIME%] [3/6] tar: OK)>> "%LOG%"

REM ---- 4. Upload + install + apply changed custom SQL on Azure ----
echo  [4/6] Uploading + installing on Azure + applying changed custom SQL...
(echo [%TIME%] [4/6] upload+install: start)>> "%LOG%"
scp -i "%KEY%" %SSHOPT% "%TGZ%" %HOST%:/tmp/fjb_full.tgz
if errorlevel 1 ( echo        ERROR: scp (bundle) failed -- skipping server deploy.& (echo [%TIME%] [4/6] scp bundle: FAILED - skip server)>>"%LOG%"& goto :site )
del "%TGZ%" >nul 2>&1
pushd "%SRC%\sql"
scp -i "%KEY%" %SSHOPT% zz_*.sql "../tools/_azure_update_remote.sh" %HOST%:
set "RC=%ERRORLEVEL%"
popd
if not "%RC%"=="0" ( echo        ERROR: scp (sql / remote script) failed -- skipping server deploy.& (echo [%TIME%] [4/6] scp sql: FAILED - skip server)>>"%LOG%"& goto :site )
ssh -i "%KEY%" %SSHOPT% %HOST% "cd %REMOTE% && sudo tar -czf $HOME/predeploy-$(date +%%Y%%m%%d-%%H%%M%%S).tgz modules/custom scripts tools 2>/dev/null && ls -t $HOME/predeploy-*.tgz | tail -n +6 | xargs -r rm -f; sudo tar -xzf /tmp/fjb_full.tgz -C %REMOTE% --no-same-owner && sudo chown -R xi:xi %REMOTE%/modules/custom %REMOTE%/scripts %REMOTE%/tools %REMOTE%/src && rm -f /tmp/fjb_full.tgz && echo   files-OK && tr -d '\015' < tools/_apply_changed_custom_sql.sh > /tmp/_acs.sh && bash /tmp/_acs.sh; rm -f /tmp/_acs.sh" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"files-OK" "%OUT%" >nul
if errorlevel 1 ( echo        ERROR: install / custom-SQL step failed -- skipping rebuild.& (echo [%TIME%] [4/6] install: FAILED - skip rebuild)>>"%LOG%"& goto :site )
(echo [%TIME%] [4/6] install: OK)>> "%LOG%"

REM ---- 5. Rebuild C++ + reload zz_*.sql + restart + health-check ----
echo  [5/6] Rebuilding C++ + reloading zz_ SQL + restarting Azure (may take a while)...
(echo [%TIME%] [5/6] rebuild+restart: start)>> "%LOG%"
ssh -i "%KEY%" %SSHOPT% %HOST% "tr -d '\015' < ~/_azure_update_remote.sh > ~/_au.sh && bash ~/_au.sh; rm -f ~/_au.sh" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
ssh -i "%KEY%" %SSHOPT% %HOST% "for s in xi_map xi_world xi_search xi_connect; do echo    $s=$(systemctl is-active $s); done; echo '   --- recent map errors (none below = clean) ---'; sudo journalctl -u xi_map --since '2 min ago' --no-pager 2>/dev/null | grep -iE 'attempt to|stack traceback|\.lua:[0-9]+:|\[error\]|fatal' | head -8" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"xi_map=active" "%OUT%" >nul
if errorlevel 1 ( echo        WARNING: xi_map not confirmed active - check health output above / the log.& set "SRVOK=PROBLEM"& (echo [%TIME%] [5/6] restart: xi_map NOT active)>>"%LOG%" ) else ( echo        server live.& set "SRVOK=OK"& (echo [%TIME%] [5/6] rebuild+restart: OK)>>"%LOG%" )

REM ---- 6. Refresh + publish the WEBSITE (docs -> Cloudflare Pages) ----
:site
echo(
echo  [6/6] Refreshing + publishing the website (docs -> Cloudflare)...
echo        (the website script will ask you to type Y to publish)
(echo [%TIME%] [6/6] website: start)>> "%LOG%"
if exist "%SITE_BAT%" ( call "%SITE_BAT%"& set "SITEOK=ran" ) else ( echo   ERROR: website script not found: %SITE_BAT%& set "SITEOK=MISSING"& (echo [%TIME%] [6/6] website: SCRIPT MISSING)>>"%LOG%" )
(echo [%TIME%] [6/6] website: returned)>> "%LOG%"

echo(
echo   ===========================================================
echo   Deploy Everything finished.
echo     Server:   %SRVOK%
echo     Website:  see the website output above (Cloudflare line)
echo   Full log:   %LOG%
echo   Server rollback if needed: "Azure - Connect.bat" -^> restore
echo   newest ~/predeploy-*.tgz -^> "Azure - Restart Map.bat".
echo   ===========================================================
(echo [%TIME%] DONE - server=%SRVOK% site=%SITEOK%)>> "%LOG%"

REM Unmissable completion popup (fires on normal completion).
powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; [void][System.Windows.Forms.MessageBox]::Show('Deploy Everything finished.'+[Environment]::NewLine+'Server: %SRVOK%'+[Environment]::NewLine+'Website: %SITEOK%'+[Environment]::NewLine+[Environment]::NewLine+'Full log: %LOG%','Legendary - Deploy Everything')" >nul 2>&1

:end
echo(
pause

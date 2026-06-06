@echo off
setlocal
title Legendary - Deploy Everything

REM ============================================================
REM  Legendary - Deploy Everything   (server + website, one click)
REM
REM  Captures ALL your changes and pushes them live everywhere:
REM    [1] re-score gear catalogs (rebalance_all) so server + site
REM        reflect the latest data
REM    [2] commit + push the whole working tree to GitHub (fjb) - backup
REM    [3] deploy content + code to the Azure SERVER: modules/custom +
REM        scripts + tools + src (file sync) + auto-apply changed
REM        modules/custom/sql
REM    [4] rebuild C++ (cmake) + reload zz_*.sql + restart + health-check
REM    [5] refresh + publish the WEBSITE (docs -> Cloudflare Pages)
REM
REM  Full release - rebuild + site build can take several minutes.
REM  For a quick content-only server push use "Azure - Deploy to Server".
REM  network.lua / DB / navmeshes are never touched; a pre-deploy backup
REM  is saved on the box (~/predeploy-*.tgz) and the DB is dumped first.
REM ============================================================

set "KEY=C:\Users\richa\Downloads\ffxi-server_key.pem"
set "HOST=azureuser@172.215.213.23"
set "SRC=D:\server"
set "REMOTE=/home/azureuser/server"
set "TGZ=%TEMP%\fjb_full.tgz"
set "SSHOPT=-o StrictHostKeyChecking=accept-new"
set "SITE_BAT=D:\server\.claude\worktrees\busy-johnson-c59e6e\refresh-site.bat"

echo(
echo   DEPLOY EVERYTHING:  re-score  ->  GitHub backup  ->  Azure server  ->  website
echo   Full release (C++ rebuild + site build can take several minutes).
echo(
set "GO="
set /p GO="   Proceed? [Y/N]:  "
if /i not "%GO%"=="Y" ( echo   Cancelled - nothing changed. & goto :end )

REM ---- 1. Re-score gear catalogs (so server + site reflect current data) ----
echo(
echo  [1/6] Re-scoring gear catalogs (rebalance_all)...
call "%SRC%\tools\rebalance_all.bat"
if errorlevel 1 ( echo   WARNING: rebalance reported an issue - continuing with catalogs on disk. )

REM ---- 2. Commit + push the working tree to GitHub (fjb) as a backup.
REM         Push is time-boxed to 90s so an auth popup can't hang the release. ----
echo(
echo  [2/6] Committing + pushing all changes to GitHub (backup)...
git -C "%SRC%" add -A
git -C "%SRC%" commit -m "Deploy Everything %DATE% %TIME%" >nul 2>&1
powershell -NoProfile -Command "$j=Start-Job { git -C 'D:\server' push fjb HEAD 2>&1 }; if (Wait-Job $j -Timeout 90) { Receive-Job $j | Out-Host } else { Stop-Job $j; Write-Host '  push timed out (sign-in popup?) - skipped; run git push manually later' }; Remove-Job $j -Force"

REM ---- 3. Pack server content + code ----
echo(
echo  [3/6] Packing server bundle (modules/custom + scripts + tools + src)...
tar -czf "%TGZ%" -C "%SRC%" modules/custom scripts tools src
if errorlevel 1 ( echo   ERROR: tar failed -- skipping server deploy. & goto :site )

REM ---- 4. Upload + install + apply changed custom SQL on Azure ----
echo  [4/6] Uploading + installing on Azure + applying changed custom SQL...
scp -i "%KEY%" %SSHOPT% "%TGZ%" %HOST%:/tmp/fjb_full.tgz
if errorlevel 1 ( echo   ERROR: scp (bundle) failed -- skipping server deploy. & goto :site )
del "%TGZ%" >nul 2>&1
pushd "%SRC%\sql"
scp -i "%KEY%" %SSHOPT% zz_*.sql "../tools/_azure_update_remote.sh" %HOST%:
set "RC=%ERRORLEVEL%"
popd
if not "%RC%"=="0" ( echo   ERROR: scp (sql / remote script) failed -- skipping server deploy. & goto :site )
ssh -i "%KEY%" %SSHOPT% %HOST% "cd %REMOTE% && sudo tar -czf $HOME/predeploy-$(date +%%Y%%m%%d-%%H%%M%%S).tgz modules/custom scripts tools 2>/dev/null && ls -t $HOME/predeploy-*.tgz | tail -n +6 | xargs -r rm -f; sudo tar -xzf /tmp/fjb_full.tgz -C %REMOTE% --no-same-owner && sudo chown -R xi:xi %REMOTE%/modules/custom %REMOTE%/scripts %REMOTE%/tools %REMOTE%/src && rm -f /tmp/fjb_full.tgz && echo   files-OK && tr -d '\015' < tools/_apply_changed_custom_sql.sh > /tmp/_acs.sh && bash /tmp/_acs.sh; rm -f /tmp/_acs.sh"
if errorlevel 1 ( echo   ERROR: install / custom-SQL step failed -- skipping rebuild. & goto :site )

REM ---- 5. Rebuild C++ + reload zz_*.sql + restart + health-check ----
echo  [5/6] Rebuilding C++ + reloading zz_ SQL + restarting Azure (may take a while)...
ssh -i "%KEY%" %SSHOPT% -t %HOST% "tr -d '\015' < ~/_azure_update_remote.sh > ~/_au.sh && bash ~/_au.sh; rm -f ~/_au.sh"
if errorlevel 1 ( echo   WARNING: rebuild/restart reported a problem (see above). )
ssh -i "%KEY%" %SSHOPT% %HOST% "for s in xi_map xi_world xi_search xi_connect; do echo    $s=$(systemctl is-active $s); done; echo   '--- recent map errors (none below = clean) ---'; sudo journalctl -u xi_map --since '2 min ago' --no-pager 2>/dev/null | grep -iE 'attempt to|stack traceback|\.lua:[0-9]+:|\[error\]|fatal' | head -8"

REM ---- 6. Refresh + publish the WEBSITE (docs -> Cloudflare Pages) ----
:site
echo(
echo  [6/6] Refreshing + publishing the website (docs -> Cloudflare)...
if exist "%SITE_BAT%" ( call "%SITE_BAT%" ) else ( echo   ERROR: website script not found: %SITE_BAT% )

echo(
echo   ===========================================================
echo   Deploy Everything finished. Review the steps above for any
echo   WARNING/ERROR lines. Server rollback if needed: "Azure - Connect.bat"
echo   -^> restore newest ~/predeploy-*.tgz -^> "Azure - Restart Map.bat".
echo   ===========================================================
:end
echo(
pause

@echo off
setlocal
title Legendary - Deploy Everything

REM ============================================================
REM  Legendary - Deploy Everything   (server + website, one click)
REM
REM  SCORE ONCE, DEPLOY BOTH.  The website refresh is the SINGLE place
REM  that re-scores every gear catalog; the exact files it produces are
REM  then shipped to the Azure server. That guarantees the live server
REM  and legendary-ffxi.pages.dev always show identical gear tiers
REM  (this killed the old server-vs-website drift).
REM
REM    [1] refresh + publish the WEBSITE = re-score ALL catalogs, build
REM        the docs, deploy to Cloudflare Pages   (auto-confirmed)
REM    [2] commit + push the freshly-scored working tree to GitHub (backup)
REM    [3] ship the SAME content + code to the Azure SERVER (file sync)
REM        + auto-apply changed modules/custom/sql
REM    [4] rebuild C++ + reload zz_*.sql + restart + health-check
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
set "SITELOG=D:\server\.claude\worktrees\busy-johnson-c59e6e\refresh-site.log"
set "LOG=%SRC%\deploy-everything.log"
set "SRVOK=skipped"
set "SITEOK=skipped"

(echo === Deploy Everything run started %DATE% %TIME% ===)> "%LOG%"

echo(
echo   DEPLOY EVERYTHING:  website re-score+publish  -^>  GitHub backup  -^>  Azure server
echo   Score ONCE, deploy BOTH - server and website stay in sync.
echo   Full release - site build + C++ rebuild can take several minutes.
echo   Step-by-step log:  %LOG%
echo(
set "GO="
set /p GO="   Proceed? [Y/N]:  "
if /i not "%GO%"=="Y" ( echo   Cancelled - nothing changed.& goto :end )

REM ---- 1. WEBSITE FIRST = the single re-score. refresh-site re-scores
REM         EVERY catalog, builds the docs, and deploys to Cloudflare. The
REM         LEGENDARY_AUTO_PUBLISH flag makes it confirm + finish without
REM         prompting. The catalogs it leaves on disk are exactly what we
REM         ship to the server in step 3 -> server == website. ----
echo(
echo  [1/4] Refreshing + publishing the WEBSITE (re-scores all catalogs, docs -^> Cloudflare)...
(echo [%TIME%] [1/4] website + single re-score: start)>> "%LOG%"
if not exist "%SITE_BAT%" ( echo        ERROR: website script not found - aborting.& set "SITEOK=MISSING"& goto :finish )
set "LEGENDARY_AUTO_PUBLISH=1"
call "%SITE_BAT%"
set "LEGENDARY_AUTO_PUBLISH="
set "SITEOK=check log"
findstr /c:"cloudflare deploy exit code: 0" "%SITELOG%" >nul
if not errorlevel 1 set "SITEOK=OK"
(echo [%TIME%] [1/4] website returned - SITEOK=%SITEOK%)>> "%LOG%"

REM ---- 2. Commit + push the freshly-scored working tree to GitHub.
REM         Push is time-boxed to 90s so an auth popup can't hang it. ----
echo(
echo  [2/4] Committing + pushing all changes to GitHub (backup)...
(echo [%TIME%] [2/4] git add/commit/push: start)>> "%LOG%"
git -C "%SRC%" add -A
git -C "%SRC%" commit -m "Deploy Everything %DATE% %TIME%" >> "%LOG%" 2>&1
powershell -NoProfile -Command "$j=Start-Job { git -C 'D:\server' push fjb HEAD 2>&1 }; if (Wait-Job $j -Timeout 90) { Receive-Job $j } else { Stop-Job $j; 'push timed out (sign-in popup?) - skipped; run: git push fjb HEAD' }; Remove-Job $j -Force" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
(echo [%TIME%] [2/4] git: done)>> "%LOG%"

REM ---- 3. Ship the SAME catalogs to the Azure SERVER (file sync + custom SQL) ----
echo(
echo  [3/4] Shipping the same content to the Azure server (modules/custom + scripts + tools + src)...
(echo [%TIME%] [3/4] pack+upload+install: start)>> "%LOG%"
tar -czf "%TGZ%" -C "%SRC%" modules/custom scripts tools src
if errorlevel 1 ( echo        ERROR: tar failed -- skipping server deploy.& set "SRVOK=PROBLEM"& goto :finish )
scp -i "%KEY%" %SSHOPT% "%TGZ%" %HOST%:/tmp/fjb_full.tgz
if errorlevel 1 ( echo        ERROR: scp of bundle failed -- skipping server deploy.& set "SRVOK=PROBLEM"& goto :finish )
del "%TGZ%" >nul 2>&1
pushd "%SRC%\sql"
scp -i "%KEY%" %SSHOPT% zz_*.sql "../tools/_azure_update_remote.sh" %HOST%:
set "RC=%ERRORLEVEL%"
popd
if not "%RC%"=="0" ( echo        ERROR: scp of sql/script failed -- skipping server deploy.& set "SRVOK=PROBLEM"& goto :finish )
ssh -i "%KEY%" %SSHOPT% %HOST% "cd %REMOTE% && sudo tar -czf $HOME/predeploy-$(date +%%Y%%m%%d-%%H%%M%%S).tgz modules/custom scripts tools 2>/dev/null && ls -t $HOME/predeploy-*.tgz | tail -n +6 | xargs -r rm -f; sudo tar -xzf /tmp/fjb_full.tgz -C %REMOTE% --no-same-owner && sudo chown -R xi:xi %REMOTE%/modules/custom %REMOTE%/scripts %REMOTE%/tools %REMOTE%/src && rm -f /tmp/fjb_full.tgz && echo   files-OK && tr -d '\015' < tools/_apply_changed_custom_sql.sh > /tmp/_acs.sh && bash /tmp/_acs.sh; rm -f /tmp/_acs.sh" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"files-OK" "%OUT%" >nul
if errorlevel 1 ( echo        ERROR: install / custom-SQL step failed -- skipping rebuild.& set "SRVOK=PROBLEM"& goto :finish )
(echo [%TIME%] [3/4] install: OK)>> "%LOG%"

REM ---- 4. Rebuild C++ + reload zz_*.sql + restart + health-check ----
echo(
echo  [4/4] Rebuilding C++ + reloading zz_ SQL + restarting Azure (may take a while)...
(echo [%TIME%] [4/4] rebuild+restart: start)>> "%LOG%"
ssh -i "%KEY%" %SSHOPT% %HOST% "tr -d '\015' < ~/_azure_update_remote.sh > ~/_au.sh && bash ~/_au.sh; rm -f ~/_au.sh" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
ssh -i "%KEY%" %SSHOPT% %HOST% "for s in xi_map xi_world xi_search xi_connect; do echo    $s=$(systemctl is-active $s); done; echo '   --- recent map errors (none below = clean) ---'; sudo journalctl -u xi_map --since '2 min ago' --no-pager 2>/dev/null | grep -iE 'attempt to|stack traceback|\.lua:[0-9]+:|\[error\]|fatal' | head -8" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"xi_map=active" "%OUT%" >nul
if errorlevel 1 ( echo        WARNING: xi_map not confirmed active - check health output above.& set "SRVOK=PROBLEM" ) else ( echo        server live.& set "SRVOK=OK" )
(echo [%TIME%] [4/4] rebuild+restart done - SRVOK=%SRVOK%)>> "%LOG%"

:finish
echo(
echo   ===========================================================
echo   Deploy Everything finished.
echo     Website:  %SITEOK%
echo     Server:   %SRVOK%
echo   Full log:   %LOG%
echo   Server rollback if needed: "Azure - Connect.bat" -^> restore
echo   newest ~/predeploy-*.tgz -^> "Azure - Restart Map.bat".
echo   ===========================================================
(echo [%TIME%] DONE - website=%SITEOK% server=%SRVOK%)>> "%LOG%"
powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; [void][System.Windows.Forms.MessageBox]::Show('Deploy Everything finished.'+[Environment]::NewLine+'Website: %SITEOK%'+[Environment]::NewLine+'Server: %SRVOK%'+[Environment]::NewLine+[Environment]::NewLine+'Full log: %LOG%','Legendary - Deploy Everything')" >nul 2>&1

:end
echo(
pause

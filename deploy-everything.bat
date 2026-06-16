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
REM    [1] re-score ALL gear catalogs from live data + build docs locally
REM        (the laptop NO LONGER publishes -- it reads an empty db)
REM    [2] commit + push the freshly-scored working tree to GitHub (backup)
REM    [3] ship the SAME content + code to the Azure SERVER (file sync)
REM    [4] rebuild C++ + apply ALL changed SQL + restart + health-check
REM    [5] PUBLISH the website FROM THE BOX (reads the LIVE db -> correct
REM        player data); replaces the old laptop Cloudflare deploy
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
echo   DEPLOY EVERYTHING:  re-score catalogs  -^>  GitHub backup  -^>  Azure server
echo   -^>  publish the site FROM THE BOX [live db].  Score once, deploy both.
echo   Full release - site build + C++ rebuild can take several minutes.
echo   Step-by-step log:  %LOG%
echo(
set "GO="
set /p GO="   Proceed? [Y/N]:  "
if /i not "%GO%"=="Y" ( echo   Cancelled - nothing changed.& goto :end )

REM ---- 1. RE-SCORE = the single re-score. refresh-site re-scores EVERY
REM         catalog from live data (LEGENDARY_AUTO_PUBLISH lets it run
REM         non-interactively). Its laptop Cloudflare deploy is now DISABLED
REM         -- the BOX publishes in step 5. The catalogs it leaves on disk
REM         are exactly what we ship to the server in step 3. ----
echo(
echo  [1/5] Re-scoring ALL gear catalogs from live data (the site publishes from the box in step 5)...
(echo [%TIME%] [1/5] re-score: start)>> "%LOG%"
if not exist "%SITE_BAT%" ( echo        ERROR: re-score script not found - aborting.& set "SITEOK=MISSING"& goto :finish )
set "LEGENDARY_AUTO_PUBLISH=1"
call "%SITE_BAT%"
set "LEGENDARY_AUTO_PUBLISH="
set "SITEOK=rescored; box publish pending"
(echo [%TIME%] [1/5] re-score returned)>> "%LOG%"

REM ---- 2. Commit + push the freshly-scored working tree to GitHub.
REM         Push is time-boxed to 90s so an auth popup can't hang it. ----
echo(
echo  [2/5] Committing + pushing all changes to GitHub (backup)...
(echo [%TIME%] [2/5] git add/commit/push: start)>> "%LOG%"
git -C "%SRC%" add -A
git -C "%SRC%" commit -m "Deploy Everything %DATE% %TIME%" >> "%LOG%" 2>&1
powershell -NoProfile -Command "$j=Start-Job { git -C 'D:\server' push fjb HEAD 2>&1 }; if (Wait-Job $j -Timeout 90) { Receive-Job $j } else { Stop-Job $j; 'push timed out (sign-in popup?) - skipped; run: git push fjb HEAD' }; Remove-Job $j -Force" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
(echo [%TIME%] [2/5] git: done)>> "%LOG%"

REM ---- 3. Ship the SAME catalogs to the Azure SERVER (file sync + custom SQL) ----
echo(
echo  [3/5] Shipping the same content to the Azure server (modules/custom + scripts + tools + src)...
(echo [%TIME%] [3/5] pack+upload+install: start)>> "%LOG%"
tar -czf "%TGZ%" -C "%SRC%" modules/custom scripts tools src
if errorlevel 1 ( echo        ERROR: tar failed -- skipping server deploy.& set "SRVOK=PROBLEM"& goto :finish )
scp -i "%KEY%" %SSHOPT% "%TGZ%" %HOST%:/tmp/fjb_full.tgz
if errorlevel 1 ( echo        ERROR: scp of bundle failed -- skipping server deploy.& set "SRVOK=PROBLEM"& goto :finish )
del "%TGZ%" >nul 2>&1
ssh -i "%KEY%" %SSHOPT% %HOST% "cd %REMOTE% && rm -f /tmp/fjb_extract_ok && sudo tar -czf $HOME/predeploy-$(date +%%Y%%m%%d-%%H%%M%%S).tgz modules/custom scripts tools 2>/dev/null && ls -t $HOME/predeploy-*.tgz | tail -n +6 | xargs -r rm -f; echo '   stopping xi_map for a storm-free extract...'; sudo systemctl stop xi_map; sudo tar -xzf /tmp/fjb_full.tgz -C %REMOTE% --no-same-owner && sudo chown -R xi:xi %REMOTE%/modules/custom %REMOTE%/scripts %REMOTE%/tools %REMOTE%/src && touch /tmp/fjb_extract_ok; sudo systemctl start xi_map; echo '   xi_map restarted after extract'; rm -f /tmp/fjb_full.tgz; test -f /tmp/fjb_extract_ok && echo   files-OK; rm -f /tmp/fjb_extract_ok" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"files-OK" "%OUT%" >nul
if errorlevel 1 ( echo        ERROR: install / custom-SQL step failed -- skipping rebuild.& set "SRVOK=PROBLEM"& goto :finish )
(echo [%TIME%] [3/5] install: OK)>> "%LOG%"

REM ---- 3b. Upload sql/zz_*.sql so _apply_changed_sql.sh has fresh copies.
REM          The box is tarball-synced (not a git clone) so git-diff won't
REM          detect SQL changes; the fallback in _apply_changed_sql.sh
REM          re-applies every zz_*.sql it finds in sql/ after this upload. ----
echo  Uploading sql/zz_*.sql to box...
for %%F in ("%SRC%\sql\zz_*.sql") do (
    scp -i "%KEY%" %SSHOPT% "%%F" %HOST%:%REMOTE%/sql/ >> "%LOG%" 2>&1
)
(echo [%TIME%] [3b] zz_*.sql upload done)>> "%LOG%"

REM ---- 4. Rebuild C++ + reload zz_*.sql + restart + health-check ----
echo(
echo  [4/5] Rebuilding C++ + applying ALL changed SQL + restarting Azure (may take a while)...
(echo [%TIME%] [4/5] rebuild+restart: start)>> "%LOG%"
ssh -i "%KEY%" %SSHOPT% %HOST% "tr -d '\015' < %REMOTE%/tools/_azure_update_remote.sh > /tmp/_au.sh && bash /tmp/_au.sh; rm -f /tmp/_au.sh" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"

REM ---- Capture the REBUILD outcome NOW, before the health-check overwrites
REM      %OUT%. _azure_update_remote.sh prints "build OK." on success and aborts
REM      with "build failed - server NOT restarted" on failure. Without this,
REM      a failed C++ rebuild would still report Server: OK below -- step 3's
REM      extract-restart leaves xi_map "active" on the OLD binary, so the
REM      is-active check alone can't tell a good build from a bad one. ----
set "BUILDFAIL="
findstr /c:"build failed" "%OUT%" >nul && set "BUILDFAIL=1"
findstr /c:"build OK." "%OUT%" >nul || findstr /c:"skipping rebuild" "%OUT%" >nul || set "BUILDFAIL=1"
(echo [%TIME%] [4/5] rebuild outcome: BUILDFAIL=%BUILDFAIL%)>> "%LOG%"

ssh -i "%KEY%" %SSHOPT% %HOST% "for s in xi_map xi_world xi_search xi_connect; do echo    $s=$(systemctl is-active $s); done; echo '   --- recent map errors (none below = clean) ---'; sudo journalctl -u xi_map --since '2 min ago' --no-pager 2>/dev/null | grep -iE 'attempt to|stack traceback|\.lua:[0-9]+:|\[error\]|fatal' | head -8" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"xi_map=active" "%OUT%" >nul
if errorlevel 1 ( echo        WARNING: xi_map not confirmed active - check health output above.& set "SRVOK=PROBLEM" ) else if defined BUILDFAIL ( echo        ERROR: C++ REBUILD FAILED -- new binary NOT live; xi_map still up on the OLD binary. Fix the build + re-deploy.& set "SRVOK=BUILD FAILED" ) else ( echo        server live.& set "SRVOK=OK" )
(echo [%TIME%] [4/5] rebuild+restart done - SRVOK=%SRVOK%)>> "%LOG%"

REM ---- 5. PUBLISH the website FROM THE BOX (reads the LIVE db, so the
REM         freshly-shipped catalogs + correct player data go live). This
REM         replaces the retired laptop Cloudflare deploy. ----
echo(
echo  [5/5] Publishing the website from the Azure box (live db -^> correct players)...
(echo [%TIME%] [5/5] box publish: start)>> "%LOG%"
ssh -i "%KEY%" %SSHOPT% %HOST% "bash ~/server/tools/refresh_site_azure.sh; tail -3 ~/refresh_site.log" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"refresh_site DONE" "%OUT%" >nul
if errorlevel 1 ( echo        WARNING: box publish not confirmed - check output above.& set "SITEOK=PROBLEM" ) else ( echo        website published from box.& set "SITEOK=OK" )
(echo [%TIME%] [5/5] box publish done - SITEOK=%SITEOK%)>> "%LOG%"

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

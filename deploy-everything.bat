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
REM keepalive: a dropped connection ERRORS in ~60s instead of hanging the deploy forever.
REM (15s probe x4 misses = ~60s dead-detect; ConnectTimeout bounds the initial connect.)
set "SSHOPT=-o StrictHostKeyChecking=accept-new -o ServerAliveInterval=15 -o ServerAliveCountMax=4 -o ConnectTimeout=20"
set "SITE_BAT=D:\server\refresh-site.bat"
set "SITELOG=D:\server\refresh-site.log"
set "LOG=%SRC%\deploy-everything.log"
set "SRVOK=skipped"
set "SITEOK=skipped"
set "SYNCOK=skipped"

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

REM ---- 0. VERIFY core LSB patches survived (merge/revert tripwire) ----
REM   Refuses to ship a rebuild that lost your in-place customizations
REM   (damage cap, CP suppression, sub-job equip, init.txt, etc.).
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
REM Skip the laptop's Cloudflare publish -- the box publishes from the LIVE db in step [5/5].
REM (refresh-site.bat gates its step [4/4] on this flag; the re-score + local build still run.)
set "LEGENDARY_SKIP_PUBLISH=1"
call "%SITE_BAT%"
set "LEGENDARY_AUTO_PUBLISH="
set "LEGENDARY_SKIP_PUBLISH="
set "SITEOK=rescored; box publish pending"
(echo [%TIME%] [1/5] re-score returned)>> "%LOG%"

REM ---- 2. Commit + push the freshly-scored working tree to GitHub.
REM         Push is time-boxed to 90s so an auth popup can't hang it. ----
echo(
echo  [2/5] Committing + pushing all changes to GitHub (backup)...
(echo [%TIME%] [2/5] git add/commit/push: start)>> "%LOG%"
git -C "%SRC%" add -A
REM Self-documenting marker: "Deploy Everything ..." subject (watermark detection
REM still matches on the first line) + a changed-file list in the commit body, so
REM the auto-swept commits say WHAT shipped instead of being an opaque marker.
set "DEPLOYMSG=%TEMP%\fjb_deploy_msg.txt"
(echo Deploy Everything %DATE% %TIME%)> "%DEPLOYMSG%"
(echo.)>> "%DEPLOYMSG%"
git -C "%SRC%" diff --cached --name-status >> "%DEPLOYMSG%"
git -C "%SRC%" commit -F "%DEPLOYMSG%" >> "%LOG%" 2>&1
del "%DEPLOYMSG%" >nul 2>&1
powershell -NoProfile -Command "$j=Start-Job { git -C 'D:\server' push fjb HEAD 2>&1 }; if (Wait-Job $j -Timeout 90) { Receive-Job $j } else { Stop-Job $j; 'push timed out (sign-in popup?) - skipped; run: git push fjb HEAD' }; Remove-Job $j -Force" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
(echo [%TIME%] [2/5] git: done)>> "%LOG%"

REM ---- 2b. Regenerate the changelog NOW that [2/5] created THIS deploy's
REM          "Deploy Everything" marker. The changelog generator drops commits
REM          newer than the latest marker ("not live yet"), so generating it in
REM          [1/5] -- before this deploy's marker exists -- lagged every deploy's
REM          own changes by one deploy. Re-running it here puts this update on
REM          the page, and [4c] then ships the corrected docs/changelog.md to the
REM          box. Non-fatal: if it fails the page just lags one deploy (old behavior).
echo(
echo  [2b] Regenerating changelog (now this deploy's marker exists)...
(echo [%TIME%] [2b] changelog regen: start)>> "%LOG%"
python "%SRC%\tools\regen_changelog.py" >> "%LOG%" 2>&1
if errorlevel 1 (
    echo        WARNING: changelog regen failed - page will lag one deploy. Continuing.
) else (
    echo        changelog regenerated.
)
REM Commit/push the refreshed page (no-ops harmlessly if it didn't change or
REM regen failed). [4c] ships docs/changelog.md to the box from disk regardless,
REM so the publish is correct even if this commit/push is skipped.
git -C "%SRC%" add docs/changelog.md >> "%LOG%" 2>&1
git -C "%SRC%" commit -m "docs(changelog): regenerate post-deploy-marker (include this update)" >> "%LOG%" 2>&1
powershell -NoProfile -Command "$j=Start-Job { git -C 'D:\server' push fjb HEAD 2>&1 }; if (Wait-Job $j -Timeout 90) { Receive-Job $j } else { Stop-Job $j; 'changelog push timed out - skipped' }; Remove-Job $j -Force" >> "%LOG%" 2>&1
(echo [%TIME%] [2b] changelog regen done)>> "%LOG%"

REM ---- 3. Ship the SAME catalogs to the Azure SERVER (file sync + custom SQL) ----
echo(
echo  [3/5] Shipping the same content to the Azure server (modules/custom + scripts + tools + src)...
(echo [%TIME%] [3/5] pack+upload+install: start)>> "%LOG%"
REM --exclude=scripts/specs: never ship the ---@meta tooling stubs (core/Globals.lua
REM etc.) to the box -- a live FileWatcher reload of them clobbers the real C++ global
REM bindings (GetSystemTime/Vanadiel*/GetZone -> nil). See sync-lua-to-azure.bat note.
tar -czf "%TGZ%" -C "%SRC%" --exclude=scripts/specs modules/custom scripts tools src
if errorlevel 1 ( echo        ERROR: tar failed -- skipping server deploy.& set "SRVOK=PROBLEM"& goto :finish )
scp -i "%KEY%" %SSHOPT% "%TGZ%" %HOST%:/tmp/fjb_full.tgz
if errorlevel 1 ( echo        ERROR: scp of bundle failed -- skipping server deploy.& set "SRVOK=PROBLEM"& goto :finish )
del "%TGZ%" >nul 2>&1
ssh -i "%KEY%" %SSHOPT% %HOST% "cd %REMOTE% && rm -f /tmp/fjb_extract_ok && sudo tar -czf $HOME/predeploy-$(date +%%Y%%m%%d-%%H%%M%%S).tgz modules/custom scripts tools 2>/dev/null && ls -t $HOME/predeploy-*.tgz | tail -n +6 | xargs -r rm -f; sudo tar -xzf /tmp/fjb_full.tgz -C %REMOTE% --no-same-owner && sudo chown -R xi:xi %REMOTE%/modules/custom %REMOTE%/scripts %REMOTE%/tools %REMOTE%/src && touch /tmp/fjb_extract_ok; rm -f /tmp/fjb_full.tgz; test -f /tmp/fjb_extract_ok && echo   files-OK; rm -f /tmp/fjb_extract_ok" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"files-OK" "%OUT%" >nul
if errorlevel 1 ( echo        ERROR: install / custom-SQL step failed -- skipping rebuild.& set "SRVOK=PROBLEM"& goto :finish )
(echo [%TIME%] [3/5] install: OK)>> "%LOG%"

REM ---- 3b. Upload sql/zz_*.sql so _apply_changed_sql.sh has fresh copies.
REM          The box is tarball-synced (not a git clone) so git-diff won't
REM          detect SQL changes; the fallback in _apply_changed_sql.sh
REM          re-applies every zz_*.sql it finds in sql/ after this upload. ----
echo  Uploading sql/zz_*.sql to box (via /tmp + sudo cp -- sql/ is xi:xi-owned, a plain scp gets Permission denied)...
REM Timeout-wrapped: the ssh session can stay open (keepalives keep succeeding)
REM AFTER the remote command finishes -- a known hang that froze this deploy twice
REM at exactly this step. Run it in a job and move on after 60s; the dir is created
REM on the box before the stall, so the scp loop below still works.
powershell -NoProfile -Command "$j=Start-Job { ssh -i '%KEY%' %SSHOPT% %HOST% 'rm -rf /tmp/fjb_zz && mkdir -p /tmp/fjb_zz' 2>&1 }; if (Wait-Job $j -Timeout 60) { Receive-Job $j } else { Stop-Job $j; 'WARNING: [3b] mkdir ssh stalled >60s - continuing (dir already created on box)' }; Remove-Job $j -Force" >> "%LOG%" 2>&1
for %%F in ("%SRC%\sql\zz_*.sql") do (
    scp -i "%KEY%" %SSHOPT% "%%F" %HOST%:/tmp/fjb_zz/ >> "%LOG%" 2>&1
)
powershell -NoProfile -Command "$j=Start-Job { ssh -i '%KEY%' %SSHOPT% %HOST% 'sudo cp /tmp/fjb_zz/*.sql %REMOTE%/sql/ && sudo chown xi:xi %REMOTE%/sql/zz_*.sql && rm -rf /tmp/fjb_zz && echo zz-sql-installed' 2>&1 }; if (Wait-Job $j -Timeout 60) { Receive-Job $j } else { Stop-Job $j; 'WARNING: [3b] sudo-cp ssh stalled >60s - continuing' }; Remove-Job $j -Force" >> "%LOG%" 2>&1
(echo [%TIME%] [3b] zz_*.sql upload done)>> "%LOG%"

REM ---- 4. Rebuild C++ + reload zz_*.sql + restart + health-check ----
echo(
echo  [4/5] Rebuilding C++ + applying ALL changed SQL + restarting Azure (may take a while)...
(echo [%TIME%] [4/5] rebuild+restart: start)>> "%LOG%"
REM -- Live build-progress side window: tails the captured output so you can
REM    watch the per-file counter (percent / done-of-total / elapsed) instead
REM    of waiting blind. Self-closes when the build prints DONE or a failure.
type nul > "%OUT%"
start "Legendary - Build Progress" powershell -NoProfile -Command "Get-Content -Path '%OUT%' -Wait | ForEach-Object { Write-Host $_; if ($_ -match 'DONE - rebuilt|build failed|NOT restarted') { Start-Sleep 2; break } }"
ssh -i "%KEY%" %SSHOPT% %HOST% "tr -d '\015' < %REMOTE%/tools/_azure_update_remote.sh > /tmp/_au.sh && bash /tmp/_au.sh; rm -f /tmp/_au.sh" >> "%OUT%" 2>&1
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

REM ---- 4d. Clean banned + over-maxBoost augments from OFFLINE player gear.
REM          Runs right after the restart on purpose: accounts_sessions is freshest
REM          (most chars dropped = most cleaned), the box already has this deploy's
REM          catalog (maxBoost ceilings), and it lands BEFORE [6/6] DB sync so the
REM          laptop's synced copy matches. The tool zeroes banned/orphan augment
REM          slots and caps any boost above its catalog maxBoost, KEEPING the item;
REM          it backs up every touched row + writes a restore .sql on the box, and
REM          SKIPS online chars (reported -> cleaned on a later deploy). Non-fatal +
REM          timeout-wrapped so it can never stall the deploy. Gated on SRVOK=OK:
REM          if the server didn't deploy cleanly we don't touch player gear.
echo(
if /i not "%SRVOK%"=="OK" goto :augclean_skip
echo  [4d] Cleaning banned + over-cap augments from player gear (offline chars)...
(echo [%TIME%] [4d] augment clean: start)>> "%LOG%"
powershell -NoProfile -Command "$j=Start-Job { ssh -i '%KEY%' %SSHOPT% %HOST% 'DRY=0 python3 ~/server/tools/clean_banned_augments.py' 2>&1 }; if (Wait-Job $j -Timeout 300) { Receive-Job $j } else { Stop-Job $j; 'WARNING: [4d] augment clean stalled >300s - continuing' }; Remove-Job $j -Force" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
(echo [%TIME%] [4d] augment clean done)>> "%LOG%"
goto :augclean_done
:augclean_skip
echo  [4d] Augment clean SKIPPED - server not healthy (SRVOK=%SRVOK%). Run it by hand after fixing the build.
(echo [%TIME%] [4d] augment clean SKIPPED - SRVOK=%SRVOK%)>> "%LOG%"
:augclean_done

REM ---- 4c. Sync ALL doc pages to the box's publish checkout. The laptop's
REM          Legendary docs are the source of truth; ship docs (minus the live-data
REM          player pages the box regenerates) + nav + theme into ~/legendary-docs.
REM          Step [5]'s box publish then layers fresh players/leaderboards on top.
REM          This also carries the changelog (it lives in docs/). The box CANNOT
REM          regenerate these itself (its ~/server has no .git; hand-written page
REM          shells + nav don't live there). Server-safe: docs only, never touches xi_map.
echo(
echo  [4c] Syncing all doc pages to the box docs site...
set "DOCSTGZ=%TEMP%\fjb_docs.tgz"
set "DOCSYNC=OK"
tar -czf "%DOCSTGZ%" -C "%SRC%" --exclude=docs/community/players docs mkdocs.yml overrides
if errorlevel 1 ( echo        WARNING: docs tar failed - site keeps previous pages.& set "DOCSYNC=TAR FAIL"& goto :docs_sync_done )
scp -i "%KEY%" %SSHOPT% "%DOCSTGZ%" %HOST%:/tmp/fjb_docs.tgz >> "%LOG%" 2>&1
if errorlevel 1 ( echo        WARNING: docs scp failed - site keeps previous pages.& set "DOCSYNC=SCP FAIL"& goto :docs_sync_done )
ssh -i "%KEY%" %SSHOPT% %HOST% "tar -xzf /tmp/fjb_docs.tgz -C ~/legendary-docs && rm -f /tmp/fjb_docs.tgz && echo docs-synced" >> "%LOG%" 2>&1
echo        all doc pages synced to box.
:docs_sync_done
del "%DOCSTGZ%" >nul 2>&1
(echo [%TIME%] [4c] docs sync - %DOCSYNC%)>> "%LOG%"

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

REM ---- 6. Sync local test DB from the freshly-deployed Azure server ----
REM   Overwrites local xidb so the laptop test server matches live exactly.
REM   Requires the local test server to be stopped (kill-servers.bat) to
REM   avoid in-use table locks on import.
echo(
echo  [6/6] Syncing local test DB from Azure (overwrites local xidb)...
(echo [%TIME%] [6/6] DB sync: start)>> "%LOG%"
set "DBDUMP=%TEMP%\xidb_sync.sql"
set "MYSQLEXE=C:\Program Files\MariaDB 10.6\bin\mysql.exe"
ssh -i "%KEY%" %SSHOPT% %HOST% "mysqldump --single-transaction -u xiuser -pwarrior3 xidb > /tmp/xidb_sync.sql && echo dump-OK" > "%OUT%" 2>&1
findstr /c:"dump-OK" "%OUT%" >nul
if errorlevel 1 (
    echo        ERROR: Azure DB dump failed -- local DB not synced. Check %LOG%.
    set "SYNCOK=DUMP FAILED"
    goto :finish
)
echo        Downloading dump to laptop...
scp -i "%KEY%" %SSHOPT% "%HOST%:/tmp/xidb_sync.sql" "%DBDUMP%" >> "%LOG%" 2>&1
if errorlevel 1 (
    echo        ERROR: SCP download failed -- local DB not synced.
    set "SYNCOK=DOWNLOAD FAILED"
    goto :finish
)
echo        Restoring into local xidb...
"%MYSQLEXE%" -u root -pwarrior3 xidb < "%DBDUMP%" >> "%LOG%" 2>&1
if errorlevel 1 (
    echo        ERROR: Local DB restore failed -- xidb may be partially restored.
    set "SYNCOK=RESTORE FAILED"
) else (
    echo        Local test DB synced from live.
    set "SYNCOK=OK"
)
del "%DBDUMP%" 2>nul
ssh -i "%KEY%" %SSHOPT% %HOST% "rm -f /tmp/xidb_sync.sql" >> "%LOG%" 2>&1
(echo [%TIME%] [6/6] DB sync done - SYNCOK=%SYNCOK%)>> "%LOG%"

:finish
echo(
echo   ===========================================================
echo   Deploy Everything finished.
echo     Website:  %SITEOK%
echo     Server:   %SRVOK%
echo     DB Sync:  %SYNCOK%
echo   Full log:   %LOG%
echo   Server rollback if needed: "Azure - Connect.bat" -^> restore
echo   newest ~/predeploy-*.tgz -^> "Azure - Restart Map.bat".
echo   ===========================================================
(echo [%TIME%] DONE - website=%SITEOK% server=%SRVOK% sync=%SYNCOK%)>> "%LOG%"
powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; [void][System.Windows.Forms.MessageBox]::Show('Deploy Everything finished.'+[Environment]::NewLine+'Website: %SITEOK%'+[Environment]::NewLine+'Server: %SRVOK%'+[Environment]::NewLine+'DB Sync: %SYNCOK%'+[Environment]::NewLine+[Environment]::NewLine+'Full log: %LOG%','Legendary - Deploy Everything')" >nul 2>&1

:end
echo(
pause

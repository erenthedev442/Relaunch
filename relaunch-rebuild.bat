@echo off
setlocal
title Relaunch - Full Rebuild

REM ============================================================
REM  relaunch-rebuild.bat  -  C++ rebuild + tools + SQL + restart RELAUNCH
REM
REM  [1] Ship FULL relaunch branch -> ~/relaunch/
REM  [2] Apply modules/custom/sql/*.sql to xi_relaunch DB
REM  [3] C++ rebuild in ~/relaunch/build (self-contained, no ~/server dependency)
REM  [4] Restart ALL relaunch services + health check
REM  [5] Publish the relaunch website (www.ffxi-legendary.com) from the box
REM
REM  LIVE SERVER (~server): NEVER TOUCHED.  ~/relaunch has its own source
REM  tree, build directory, and binaries.  No files are read from or
REM  written to ~/server by this script.
REM
REM  This is the RELAUNCH-BRANCH copy -- run it from D:\server_relaunch.
REM ============================================================

set "KEY=C:\Users\richa\Downloads\ffxi-server_key.pem"
set "HOST=azureuser@172.215.213.23"
set "SRC=D:\server_relaunch"
set "REMOTE=/home/azureuser/relaunch"
set "LOG=%SRC%\relaunch-rebuild.log"
set "OUT=%TEMP%\relaunch_rebuild_out.txt"
set "SSHOPT=-o StrictHostKeyChecking=accept-new"
set "SRVOK=skipped"
set "SITEOK=skipped"

(echo === Relaunch Rebuild started %DATE% %TIME% ===)> "%LOG%"

echo(
echo   RELAUNCH FULL REBUILD
echo   [1] Ship full relaunch branch  --^>  %REMOTE%/
echo   [2] Apply SQL  --^>  xi_relaunch (if any)
echo   [3] C++ rebuild in ~/relaunch/build  (self-contained)
echo   [4] Restart all relaunch services + health check
echo   [5] Publish the relaunch website (www.ffxi-legendary.com)
echo   PRODUCTION SERVER (~server): NOT TOUCHED
echo(
set "GO="
set /p GO="   Proceed? [Y/N]:  "
if /i not "%GO%"=="Y" ( echo   Cancelled - nothing changed.& goto :end )

REM ---- [push] Sync committed relaunch branch to origin BEFORE deploying, so the
REM      website (which rebuilds from origin/relaunch) matches the exact code we
REM      ship to the server in [1]. Without this, a committed-but-not-pushed deploy
REM      leaves the server ahead of the site = content drift. A push failure means
REM      the site would rebuild STALE, so ABORT before touching the server.
echo(
echo  [push] Syncing committed relaunch branch to origin (Relaunch repo)...
(echo [%TIME%] [push] git push origin relaunch: start)>> "%LOG%"
git -C "%SRC%" push origin relaunch > "%OUT%" 2>&1
if errorlevel 1 (
  type "%OUT%"
  type "%OUT%" >> "%LOG%"
  echo(
  echo   *** ABORT: push to origin FAILED. The website rebuilds from origin/relaunch,
  echo       so deploying now would DRIFT the site from the server. Fix the push
  echo       ^(commit your work / resolve non-fast-forward^) and re-run. Nothing shipped.
  set "SRVOK=PUSH-FAILED"
  set "SITEOK=PUSH-FAILED"
  goto :finish
)
type "%OUT%"
type "%OUT%" >> "%LOG%"
(echo [%TIME%] [push] origin synced OK)>> "%LOG%"

REM ---- [marker] Create deploy marker + regenerate changelog ----
REM  An empty "Relaunch Deploy" commit marks what shipped. regen_changelog.py
REM  reads git history after this marker exists, so the changelog includes THIS
REM  deploy's changes immediately. The updated changelog is committed + pushed
REM  so the box's docs cron picks it up and the site stays in sync.
echo(
echo  [marker] Creating deploy marker commit...
(echo [%TIME%] [marker] deploy marker: start)>> "%LOG%"
git -C "%SRC%" commit --allow-empty -m "Relaunch Deploy %DATE% %TIME%" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
if errorlevel 1 ( echo   WARNING: marker commit failed - changelog may lag by one deploy. )
(echo [%TIME%] [marker] marker created)>> "%LOG%"

echo  [marker] Regenerating changelog...
python "%SRC%\tools\regen_changelog.py" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"

REM  Stage + commit the updated changelog (if regen produced changes).
git -C "%SRC%" add docs/changelog.md > nul 2>&1
git -C "%SRC%" diff --cached --quiet docs/changelog.md > nul 2>&1
if errorlevel 1 (
  git -C "%SRC%" commit -m "docs(changelog): regenerate for deploy %DATE%" > "%OUT%" 2>&1
  type "%OUT%"
  type "%OUT%" >> "%LOG%"
  git -C "%SRC%" push origin relaunch > "%OUT%" 2>&1
  type "%OUT%"
  type "%OUT%" >> "%LOG%"
  echo   changelog updated + pushed.
) else (
  echo   changelog unchanged.
)
(echo [%TIME%] [marker] changelog done)>> "%LOG%"

REM ---- [1] Archive FULL relaunch branch + ship + extract ----
REM  Ships the entire repo snapshot (src, cmake, modules, scripts, tools, etc.)
REM  to ~/relaunch/.  This gives relaunch its own complete source tree so the
REM  C++ build in step [3] is fully self-contained -- no files from ~/server/.
echo(
echo  [1/5] Archiving full relaunch branch and shipping to Azure...
(echo [%TIME%] [1/5] git-archive+upload: start)>> "%LOG%"
git -C "%SRC%" archive relaunch | ssh -i "%KEY%" %SSHOPT% %HOST% "tar -xf - -C %REMOTE% --no-same-owner --overwrite && echo   files-OK" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"files-OK" "%OUT%" >nul
if errorlevel 1 ( echo   ERROR: git archive or extract failed.& set "SRVOK=PROBLEM"& goto :finish )
(echo [%TIME%] [1/5] files shipped OK)>> "%LOG%"

REM ---- [2] Apply custom SQL to xi_relaunch ----
echo(
echo  [2/5] Applying modules/custom/sql/*.sql to xi_relaunch...
(echo [%TIME%] [2/5] sql: start)>> "%LOG%"
ssh -i "%KEY%" %SSHOPT% %HOST% "cd %REMOTE% && applied=0; shopt -s nullglob; for f in modules/custom/sql/*.sql; do sudo mariadb xi_relaunch < \"$f\" && echo \"   applied $f\" && applied=$((applied+1)); done; echo \"   sql-DONE ($applied files)\"" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"sql-DONE" "%OUT%" >nul
if errorlevel 1 ( echo   WARNING: SQL step may have failed - check output above.& set "SRVOK=PROBLEM"& goto :finish )
(echo [%TIME%] [2/5] sql OK)>> "%LOG%"

REM ---- [3] C++ rebuild from ~/relaunch (self-contained build tree) ----
REM  Builds entirely from ~/relaunch/ -- its own CMakeLists.txt, src/, modules/,
REM  and build/ directory.  Binaries (xi_map etc.) land in ~/relaunch/ (the cmake
REM  RUNTIME_OUTPUT_DIRECTORY is CMAKE_SOURCE_DIR).  First run creates build/ and
REM  fetches dependencies (~5-10 min); subsequent runs are incremental (~1-2 min).
echo(
echo  [3/5] Rebuilding C++ from ~/relaunch/build  (self-contained, no ~/server dep)...
(echo [%TIME%] [3/5] rebuild: start)>> "%LOG%"
ssh -i "%KEY%" %SSHOPT% %HOST% "cd ~/relaunch && echo '   Reconfiguring...' && cmake -B build -S . 2>&1 && echo '   Compiling...' && cmake --build build -j2 && echo   binaries-OK" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"binaries-OK" "%OUT%" >nul
if errorlevel 1 ( echo   ERROR: build failed - relaunch NOT restarted.& set "SRVOK=PROBLEM"& goto :finish )
(echo [%TIME%] [3/5] build OK)>> "%LOG%"

REM ---- [4] Restart all relaunch services + health check ----
echo(
echo  [4/5] Restarting all relaunch services (brief disconnect for relaunch players)...
(echo [%TIME%] [4/5] restart: start)>> "%LOG%"
ssh -i "%KEY%" %SSHOPT% %HOST% "sudo systemctl restart xi_connect_relaunch xi_world_relaunch xi_search_relaunch xi_map_relaunch && echo   restart-OK" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"restart-OK" "%OUT%" >nul
if errorlevel 1 ( echo   WARNING: restart may have failed.& set "SRVOK=PROBLEM"& goto :finish )
set "SRVOK=precheck"
(echo [%TIME%] [4/5] restart OK)>> "%LOG%"

echo(
echo  [4/5] Health check...
(echo [%TIME%] [4/5] health: start)>> "%LOG%"
ssh -i "%KEY%" %SSHOPT% %HOST% "for s in xi_map_relaunch xi_connect_relaunch xi_world_relaunch xi_search_relaunch; do echo    $s=$(systemctl is-active $s); done; echo '   --- recent relaunch errors ---'; sudo journalctl -u xi_map_relaunch --since '2 min ago' --no-pager 2>/dev/null | grep -iE 'attempt to|stack traceback|\.lua:[0-9]+:|\[error\]|fatal' | head -8" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"xi_map_relaunch=active" "%OUT%" >nul
if errorlevel 1 ( echo   WARNING: xi_map_relaunch not confirmed active.& set "SRVOK=PROBLEM" ) else if not "%SRVOK%"=="PROBLEM" ( set "SRVOK=OK" )
(echo [%TIME%] [4/5] health done, SRVOK=%SRVOK%)>> "%LOG%"

REM ---- [5] Publish the relaunch website from the box ----
REM  Builds www.ffxi-legendary.com from the relaunch branch + xi_relaunch DB
REM  ON THE BOX (the laptop reads an empty DB, so this MUST run box-side).
REM  Docs-only: regenerates docs -> mkdocs -> Cloudflare; does NOT touch the
REM  game services (neither relaunch nor Legendary). Reached only when steps
REM  [1]-[4] above did not hard-fail.
echo(
echo  [5/5] Publishing the relaunch website (www.ffxi-legendary.com) from the box...
echo        (~2-3 min: docgen -^> mkdocs -^> Cloudflare; relaunch players unaffected)
(echo [%TIME%] [5/5] site: start)>> "%LOG%"
ssh -i "%KEY%" %SSHOPT% %HOST% "bash ~/relaunch-docs/tools/refresh_site_relaunch.sh; echo; echo ===== RESULT =====; tail -14 ~/refresh_site_relaunch.log" > "%OUT%" 2>&1
type "%OUT%"
type "%OUT%" >> "%LOG%"
findstr /c:"Deployment complete" "%OUT%" >nul
if errorlevel 1 ( echo   WARNING: site publish may have failed - check output above.& set "SITEOK=PROBLEM" ) else ( set "SITEOK=OK" )
(echo [%TIME%] [5/5] site done, SITEOK=%SITEOK%)>> "%LOG%"

:finish
echo(
echo   ============================================================
echo    Relaunch rebuild finished.
echo    Server:  %SRVOK%
echo    Website: %SITEOK%
echo    Log:     %LOG%
echo    PRODUCTION SERVER (~/server): NOT TOUCHED.
echo   ============================================================
(echo [%TIME%] DONE server=%SRVOK% site=%SITEOK%)>> "%LOG%"

:end
echo(
pause

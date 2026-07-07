# =====================================================================
# deploy-relaunch.ps1  --  one-click OVH RELAUNCH "Deploy Everything" (+ website)
# Runs LOCALLY on the OVH VPS (C:\server).  This is the relaunch/OVH equivalent
# of Legendary's Deploy Everything: it rebuilds + restarts the LIVE relaunch
# server AND republishes the relaunch website, from a single confirm.
#
# It is a THIN WRAPPER on two proven, box-native pieces -- it does not reinvent
# either:
#   [A] CODE   ->  vps-rebuild.ps1        (already on the box)
#         git sync origin/relaunch (auto-reconcile, preserves on-disk edits)
#         -> stop (schtasks /end FFXIRelaunch + kill exes, back up *.bak)
#         -> apply modules\custom\sql\*.sql to xi_relaunch
#         -> C++ rebuild (vcvars64 + cmake Ninja; restores *.bak on failure)
#         -> restart (schtasks /run FFXIRelaunch) + health check
#         -> push local commit(s) to origin after a good build
#   [B] WEBSITE -> Relaunch-DocsRefresh task (refresh_site_relaunch.ps1)
#         docgen (live C:\server tree + xi_relaunch) -> mkdocs -> Cloudflare
#         Pages (fjb-relaunch.pages.dev).  vps-rebuild.ps1 deliberately SKIPS
#         this ("that was Azure-box infra") -- so we add it here.
#
# WHY a wrapper and not one big script: vps-rebuild.ps1 is the code-only path
# behind the existing "Relaunch - Rebuild" shortcut; leaving it untouched keeps
# a plain rebuild available, while THIS is the superset that also ships docs.
#
# SAFE: [A] restores the previous binaries on a build failure; [B] only reads
# the DB + deploys static files and runs AFTER the server is already back up,
# so a docs hiccup can never take the game down.  The website step is
# independent of the C++ build result (docs track origin/relaunch, which
# vps-rebuild just pushed), so it publishes even if the build fell back.
# =====================================================================
$ErrorActionPreference = 'Continue'
$root     = 'C:\server'
$rebuild  = Join-Path $root 'vps-rebuild.ps1'
$docsTask = 'Relaunch-DocsRefresh'
$docsLog  = 'C:\relaunch-ops\logs\refresh_site_relaunch.log'
$log      = Join-Path $root 'deploy-relaunch.log'
$exes     = 'xi_connect','xi_world','xi_search','xi_map'

function Say($m,$c='Gray'){ Write-Host $m -ForegroundColor $c; try { Add-Content $log ("{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$m) } catch {} }

Say ''
Say '============================================================' 'Cyan'
Say '  RELAUNCH - DEPLOY EVERYTHING  (code + website)' 'Cyan'
Say '  [A] git sync -> stop -> SQL -> C++ rebuild -> restart -> push' 'Cyan'
Say '  [B] docgen -> mkdocs -> Cloudflare  (fjb-relaunch.pages.dev)' 'Cyan'
Say '  LIVE relaunch server: players briefly disconnect on the restart.' 'Cyan'
Say '  (Legendary / ~server is a separate box and is NOT touched.)' 'Cyan'
Say '============================================================' 'Cyan'
$go = Read-Host '  Proceed? [Y/N]'
if ($go -notmatch '^[Yy]') { Say '  Cancelled - nothing changed.' 'Yellow'; Read-Host '  Press Enter to close'; exit 0 }

if (-not (Test-Path $rebuild)) { Say "  ERROR: $rebuild not found - cannot rebuild. Aborting." 'Red'; Read-Host '  Press Enter to close'; exit 1 }

# ---- [A] CODE: run the proven local rebuild (own logging + *.bak safety) ----
Say ''
Say '########## [A] CODE REBUILD  (vps-rebuild.ps1) ##########' 'Cyan'
& $rebuild
Say '########## [A] code rebuild returned ##########' 'Cyan'

Start-Sleep 3
$up      = @(Get-Process | Where-Object { $_.ProcessName -like 'xi_*' } | Select-Object -ExpandProperty ProcessName -Unique)
$upList  = @($exes | Where-Object { $up -contains $_ })
$upCount = $upList.Count
Say ("  services up: {0}/4  ({1})" -f $upCount, ($upList -join ', '))
if ($upCount -lt 4) { Say '  NOTE: not all 4 confirmed yet - the FFXIRelaunch watchdog respawns any missing exe within ~10s.' 'Yellow' }

# ---- [B] WEBSITE: trigger the docs task, wait for it, verify ----
Say ''
Say '########## [B] PUBLISH WEBSITE  (fjb-relaunch.pages.dev) ##########' 'Cyan'
Say '  ~2-3 min: docgen -> mkdocs -> Cloudflare. Relaunch players unaffected.'
$before = (Get-ScheduledTaskInfo -TaskName $docsTask -ErrorAction SilentlyContinue).LastRunTime
schtasks /run /tn $docsTask 2>&1 | Out-Null
# Wait until the task has actually STARTED (LastRunTime advances) AND FINISHED
# (State leaves Running). Cap ~5 min so a wedged run can't hang the deploy.
$n = 0; $st = 'Unknown'
do {
    Start-Sleep 8
    $st  = (Get-ScheduledTask     -TaskName $docsTask -ErrorAction SilentlyContinue).State
    $now = (Get-ScheduledTaskInfo -TaskName $docsTask -ErrorAction SilentlyContinue).LastRunTime
    $started = ($now -ne $before)
    $n++
} while ((($st -eq 'Running') -or (-not $started)) -and $n -lt 40)
$info   = Get-ScheduledTaskInfo -TaskName $docsTask -ErrorAction SilentlyContinue
$taskOk = ($info.LastTaskResult -eq 0)
# Corroborate with the publish log's success marker (defensive: task result can
# read 0 before the script's own guards, e.g. a "0 players -> skip").
$doneMarker = $false
if (Test-Path $docsLog) {
    $tail = @(Get-Content $docsLog -Tail 30)
    $doneMarker = [bool]($tail -match 'refresh_site_relaunch DONE')
    $skip       = [bool]($tail -match 'no-players-skip|wrangler-failed|mkdocs-failed|docgen failed')
    Say '  --- publish log tail ---'
    $tail | Select-Object -Last 6 | ForEach-Object { Say ("    | " + $_) }
} else { $skip = $false }
$siteOk = ($doneMarker -and -not $skip)
if ($siteOk)      { Say '  website: PUBLISHED (refresh_site_relaunch DONE). Live in ~30s.' 'Green' }
elseif ($taskOk)  { Say ("  website: task exited 0 but no DONE marker - CHECK $docsLog") 'Yellow' }
else              { Say ("  website: CHECK - task result=" + $info.LastTaskResult + " state=" + $st + " (see $docsLog)") 'Yellow' }

# ---- summary ----
$srvMsg = if ($upCount -eq 4) { 'OK (4/4 up)' } else { "CHECK ($upCount/4)" }
$srvCol = if ($upCount -eq 4) { 'Green' }       else { 'Yellow' }
$webMsg = if ($siteOk)        { 'published' }   else { 'CHECK - see log' }
$webCol = if ($siteOk)        { 'Green' }       else { 'Yellow' }
Say ''
Say '============================================================' 'Cyan'
Say '  DEPLOY FINISHED' 'Cyan'
Say ("  Server : " + $srvMsg) $srvCol
Say ("  Website: " + $webMsg) $webCol
Say  '  Logs   : deploy-relaunch.log | vps-rebuild.log | relaunch-ops\logs\refresh_site_relaunch.log'
Say '============================================================' 'Cyan'
Read-Host '  Press Enter to close'

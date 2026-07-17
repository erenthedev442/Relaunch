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
#         -> apply sql\zz*.sql overlay layer (item mods etc.) + modules\custom\sql\*.sql
#         -> C++ rebuild (vcvars64 + cmake Ninja; restores *.bak on failure)
#         -> restart (schtasks /run FFXIRelaunch) + health check
#         -> push local commit(s) to origin after a good build
#   [A2] CHANGELOG -> deploy marker + regen (this script)
#         "Relaunch Deploy <stamp>" empty commit (the changelog generator's
#         live-marker) -> regen_changelog.py -> commit/push docs/changelog.md.
#         Skipped when the build failed.
#   [B] WEBSITE -> Relaunch-DocsRefresh task (refresh_site_relaunch.ps1)
#         docgen (live C:\server tree + xi_relaunch) -> mkdocs -> Cloudflare
#         Pages (www.ffxi-legendary.com).  vps-rebuild.ps1 deliberately SKIPS
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
Say '  [B] docgen -> mkdocs -> Cloudflare  (www.ffxi-legendary.com)' 'Cyan'
Say '  LIVE relaunch server: players briefly disconnect on the restart.' 'Cyan'
Say '  (Legendary / ~server is a separate box and is NOT touched.)' 'Cyan'
Say '============================================================' 'Cyan'

# ---- PRE-FLIGHT: what THIS deploy will pull, detailed per collaborator ----
# Read-only, non-gating, fail-open (never blocks the deploy). Fetches origin,
# then for every incoming commit whose author email is NOT in $MyEmails prints
# a review card: subject, the author's own commit-message body (their stated
# intent), an impact line (C++ = live after THIS rebuild, SQL = applied this
# deploy, Lua = live on restart, tests/docs), and the per-file diffstat.
# The FULL line-by-line diff of every collaborator commit is also written to
# $reviewFile -- open it in notepad while the Proceed prompt waits.
# $MyEmails = the identities YOU commit under; edit if you gain another.
# It does not approve or hold anything -- just understanding before you answer.
$MyEmails   = @('rknutz@gmail.com','richardknutzjr@hotmail.com')
$reviewFile = Join-Path $root 'deploy-collab-review.txt'
try {
    git -C $root fetch origin relaunch --quiet 2>$null
    $US = [char]0x1f
    $incoming = @(git -C $root log 'HEAD..origin/relaunch' --format='%ae' 2>$null)
    if (-not $incoming -or $incoming.Count -eq 0) {
        Say '  Incoming: nothing new since your live code (or offline -- fetch skipped).' 'Gray'
    } else {
        $mineCount  = @($incoming | Where-Object { $MyEmails -contains $_ }).Count
        $otherCount = $incoming.Count - $mineCount
        Say ('  Incoming this deploy: {0} commit(s) -- {1} yours, {2} from other collaborators.' -f $incoming.Count, $mineCount, $otherCount) 'Cyan'
        if ($otherCount -gt 0) {
            # Collaborator commits oldest-first so the story reads forward.
            # --no-merges: PR merge commits carry no changes of their own.
            # NB: precomputed format vars -- `--format=(expr)` makes PowerShell
            # pass the parenthesized value as a SEPARATE argument and git dies
            # with "ambiguous argument"; `--format=$var` stays one argument.
            $fmtHash = "%h{0}%ae" -f $US
            $fmtMeta = "%h{0}%an{0}%ad{0}%s" -f $US
            $collabHashes = @()
            foreach ($ln in @(git -C $root log 'HEAD..origin/relaunch' --reverse --no-merges --format=$fmtHash 2>$null)) {
                $p = $ln.Split($US)
                if ($p.Count -ge 2 -and -not ($MyEmails -contains $p[1])) { $collabHashes += $p[0] }
            }
            Say ''
            Say '  ====== COLLABORATOR CHANGES GOING LIVE THIS DEPLOY ======' 'Yellow'
            ("Collaborator review  {0}`r`nRange: HEAD..origin/relaunch  ({1} collaborator commit(s))`r`n" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $collabHashes.Count) |
                Out-File $reviewFile -Encoding utf8
            $ci = 0
            foreach ($h in $collabHashes) {
                $ci++
                $meta = (git -C $root show -s --format=$fmtMeta --date=format:'%m/%d %H:%M' $h 2>$null) -split $US
                Say ''
                Say ('  [{0}/{1}]  {2}  --  {3}' -f $ci, $collabHashes.Count, $meta[1], $meta[3]) 'White'
                Say ('          {0}  {1}' -f $meta[0], $meta[2]) 'DarkGray'
                # The author's own explanation of what/why, from the commit body.
                $body = @(git -C $root show -s --format=%b $h 2>$null) | Where-Object { $_.Trim() }
                foreach ($b in ($body | Select-Object -First 10)) { Say ('          ' + $b.Trim()) 'Gray' }
                if ($body.Count -gt 10) { Say ('          ... (+{0} more lines -- see review file)' -f ($body.Count - 10)) 'DarkGray' }
                # Impact: what kind of change this is and when it takes effect.
                $files = @(git -C $root show --name-only --format= $h 2>$null) | Where-Object { $_.Trim() }
                $cpp = @($files | Where-Object { $_ -match '^(src/|modules/custom/cpp/)' }).Count
                $sql = @($files | Where-Object { $_ -match '\.sql$' }).Count
                $lua = @($files | Where-Object { $_ -match '\.lua$' -and $_ -notmatch '^scripts/(tests|specs)/' }).Count
                $tst = @($files | Where-Object { $_ -match '^scripts/(tests|specs)/' }).Count
                $doc = @($files | Where-Object { $_ -match '^(docs/|tools/docgen/|site/)' }).Count
                $tags = @()
                if ($cpp) { $tags += ('C++ x{0} (live after THIS rebuild)' -f $cpp) }
                if ($sql) { $tags += ('SQL x{0} (applied this deploy)' -f $sql) }
                if ($lua) { $tags += ('Lua x{0} (live on restart)' -f $lua) }
                if ($tst) { $tags += ('tests x{0}' -f $tst) }
                if ($doc) { $tags += ('docs/site x{0}' -f $doc) }
                if ($tags.Count) { Say ('          impact: ' + ($tags -join '  |  ')) 'Cyan' }
                # Per-file diffstat (capped; the full list is in the review file).
                $stat = @(git -C $root show --stat=110 --format= $h 2>$null) | Where-Object { $_.Trim() }
                foreach ($s in ($stat | Select-Object -First 12)) { Say ('          ' + $s.Trim()) 'DarkGray' }
                if ($stat.Count -gt 12) { Say ('          ... (+{0} more files -- see review file)' -f ($stat.Count - 12)) 'DarkGray' }
                # Full patch into the review file (binary files show as one line).
                ('=' * 78) | Out-File $reviewFile -Append -Encoding utf8
                git -C $root show --no-color $h 2>$null | Out-File $reviewFile -Append -Encoding utf8
            }
            Say ''
            Say ('  Full line-by-line diffs: {0}' -f $reviewFile) 'Yellow'
            Say '  (open it in notepad now if you want -- the prompt below waits for you.)' 'Gray'
            Say '  =========================================================' 'Yellow'
            Say '  (Awareness only -- these are NOT held; answering Y deploys them.)' 'Gray'
        }
    }
} catch { Say ('  (incoming-changes preflight skipped: {0})' -f $_.Exception.Message) 'Gray' }

$go = Read-Host '  Proceed? [Y/N]'
if ($go -notmatch '^[Yy]') { Say '  Cancelled - nothing changed.' 'Yellow'; Read-Host '  Press Enter to close'; exit 0 }

if (-not (Test-Path $rebuild)) { Say "  ERROR: $rebuild not found - cannot rebuild. Aborting." 'Red'; Read-Host '  Press Enter to close'; exit 1 }

# ---- [A] CODE: run the proven local rebuild (own logging + *.bak safety) ----
Say ''
Say '########## [A] CODE REBUILD  (vps-rebuild.ps1) ##########' 'Cyan'
# Remember where vps-rebuild.log ends now, so [A2] can read ONLY what THIS run
# appends (a stale 'build OK' from a previous run must not count).
$vpsLog = Join-Path $root 'vps-rebuild.log'
$vpsLogLines = 0; if (Test-Path $vpsLog) { $vpsLogLines = @(Get-Content $vpsLog).Count }
& $rebuild
Say '########## [A] code rebuild returned ##########' 'Cyan'

Start-Sleep 3
$up      = @(Get-Process | Where-Object { $_.ProcessName -like 'xi_*' } | Select-Object -ExpandProperty ProcessName -Unique)
$upList  = @($exes | Where-Object { $up -contains $_ })
$upCount = $upList.Count
Say ("  services up: {0}/4  ({1})" -f $upCount, ($upList -join ', '))
if ($upCount -lt 4) { Say '  NOTE: not all 4 confirmed yet - the FFXIRelaunch watchdog respawns any missing exe within ~10s.' 'Yellow' }

# ---- [A2] CHANGELOG: deploy marker -> regen -> commit/push ----
# The public changelog page (docs/changelog.md) is generated from git history
# and only advances past "Relaunch Deploy ..." marker commits (the not-live-yet
# guard in tools/docgen/generators/changelog.py). The old Azure path wrote the
# marker in relaunch-rebuild.bat; this is the OVH equivalent. It runs between
# [A] and [B] because the docs task in [B] hard-resets C:\relaunch-docs to
# origin/relaunch -- the marker + regenerated changelog MUST be pushed first or
# the site publishes the previous changelog. Every failure here is NON-FATAL:
# the worst case is the changelog lagging one deploy, never a broken deploy.
Say ''
Say '########## [A2] CHANGELOG + DEPLOY MARKER ##########' 'Cyan'
$Py = 'C:\Program Files\Python312\python.exe'; if (-not (Test-Path $Py)) { $Py = 'python' }
Set-Location $root
# Only mark this deploy as LIVE if vps-rebuild logged a good build THIS run and
# HEAD landed on origin/relaunch (git sync wasn't skipped). On a failed build
# the previous binaries were restored, so a marker would falsely publish dead
# changes as live -- skip, and the next good deploy's marker sweeps them up.
$vpsNew = ''; if (Test-Path $vpsLog) { $vpsNew = (@(Get-Content $vpsLog | Select-Object -Skip $vpsLogLines) -join "`n") }
$goodBuild = $vpsNew -match 'build OK - new binaries in place'
$onOrigin  = ((git rev-parse HEAD 2>$null) -eq (git rev-parse origin/relaunch 2>$null))
if ($goodBuild -and $onOrigin) {
    $stamp = Get-Date -Format 'ddd MM/dd/yyyy HH:mm:ss'
    git commit --allow-empty -m ("Relaunch Deploy " + $stamp) | Out-Null
    Say ("  marker committed: Relaunch Deploy " + $stamp)
    $env:LEGENDARY_LIVE_ROOT = $root   # changelog.py reads git history from here (default is the dev box path)
    & $Py (Join-Path $root 'tools\regen_changelog.py') 2>&1 | ForEach-Object { Say ("    | " + $_) }
    git add docs/changelog.md 2>$null
    git diff --cached --quiet -- docs/changelog.md
    if ($LASTEXITCODE -ne 0) {
        git commit -m ("docs(changelog): regenerate for deploy " + $stamp) | Out-Null
        Say '  changelog regenerated + committed.'
    } else {
        Say '  changelog unchanged.'
    }
    git push origin relaunch 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Say '  pushed - docs task in [B] will publish the fresh changelog.' 'Green' }
    else { Say '  WARNING: push failed - the site keeps the previous changelog until the next successful push.' 'Yellow' }
} elseif (-not $goodBuild) {
    Say '  SKIP marker: vps-rebuild did not report a good build (previous binaries running) - changelog catches up on the next good deploy.' 'Yellow'
} else {
    Say '  SKIP marker: HEAD is not on origin/relaunch (git sync skipped?) - changelog not regenerated.' 'Yellow'
}

# ---- [B] WEBSITE: trigger the docs task, wait for it, verify ----
Say ''
Say '########## [B] PUBLISH WEBSITE  (www.ffxi-legendary.com) ##########' 'Cyan'
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

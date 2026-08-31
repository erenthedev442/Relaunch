# =====================================================================
# vps-rebuild.ps1 - OVH VPS RELAUNCH full rebuild (runs LOCALLY on the VPS)
# Equivalent of the old Azure relaunch-rebuild.bat, retargeted to C:\server.
#
#   [1] git SYNC with origin/relaunch  (auto-reconcile - see below)
#   [2] stop servers + back up binaries    (Windows locks running .exe)
#   [3] apply sql\zz*.sql overlay layer + modules\custom\sql\*.sql -> xi_relaunch
#   [4] C++ rebuild (MSVC/Ninja) in C:\server\build
#   [5] restart servers + health check
#   [+] push local commit(s) back to origin (only after a GOOD build)
#
# STEP [1] AUTO-RECONCILE - handles every git state automatically so the
# rebuild always builds the fully-integrated code and the box stays backed
# up to GitHub. On-disk editing in the RDP session is a first-class workflow,
# so local work is NEVER discarded - it is committed and replayed on top of
# origin. Scenarios covered:
#   * clean + in sync            -> nothing to do
#   * clean + behind             -> fast-forward from origin
#   * clean + ahead              -> keep local; push after a good build
#   * diverged (ahead + behind)  -> rebase local onto origin (auto)
#       - rebase conflict        -> abort, build on-disk, warn (manual fix)
#   * uncommitted on-disk edits  -> auto-commit first (nothing lost), then above
#   * offline / no credentials   -> skip remote sync, build on-disk, warn
#   * not on 'relaunch' branch   -> skip git sync entirely, build on-disk, warn
# Fetch/push use whatever git credentials exist. Run interactively (the
# "Relaunch - Rebuild" shortcut) so the Windows credential store is available;
# if creds are missing it degrades gracefully to an on-disk build.
#
# SAFETY: current xi_*.exe are copied to *.bak before the build. If the
# build fails, the .bak binaries are restored so the server still comes
# back up on the previous working build. Does NOT publish the website
# (that was Azure-box infra).
# =====================================================================
$ErrorActionPreference = 'Continue'
$env:GIT_TERMINAL_PROMPT = '0'   # fail fetch/push instead of hanging on Username:
$root   = 'C:\server'
$branch = 'relaunch'
$mysql  = 'C:\Program Files\MariaDB 10.6\bin\mysql.exe'
$vcvars = 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat'
$exes   = 'xi_connect.exe','xi_world.exe','xi_search.exe','xi_map.exe'
$log    = Join-Path $root 'vps-rebuild.log'

function Say($m,$c='Gray'){ Write-Host $m -ForegroundColor $c; try { Add-Content $log ("{0} {1}" -f (Get-Date -Format 'HH:mm:ss'),$m) } catch {} }

Say '' ; Say '================= VPS RELAUNCH REBUILD =================' 'Cyan'
Set-Location $root

# ---- [1] git SYNC (auto-reconcile; NON-FATAL - always builds SOME code) ----
Say '[1/5] Sync with origin/relaunch (auto-reconcile; on-disk work is preserved)...' 'Cyan'
$gitReady       = $false   # on branch AND fetch succeeded
$rebaseConflict = $false   # diverged + could not auto-rebase
$curBranch = (git rev-parse --abbrev-ref HEAD 2>$null)
if ($curBranch -ne $branch) {
  Say ("   NOT on '$branch' (HEAD = '$curBranch') - skipping git sync, building on-disk code") 'Red'
} else {
  # 1a. preserve any uncommitted on-disk edits as a real commit (never discard).
  #     git add -A respects .gitignore, so build/ , *.log and *.bak are skipped.
  if (git status --porcelain) {
    git add -A
    git commit -m ("ops(vps): auto-commit on-disk edits pre-rebuild " + (Get-Date -Format 'yyyy-MM-dd HH:mm')) | Out-Null
    Say '   committed uncommitted on-disk edits (auto - nothing lost)' 'Yellow'
  }
  # 1b. fetch origin (offline / no-creds is non-fatal -> build on-disk)
  git fetch origin $branch
  if ($LASTEXITCODE -ne 0) {
    Say '   fetch failed (offline or no credentials) - building on-disk code' 'Yellow'
  } else {
    $gitReady = $true
    $lr = (git rev-list --left-right --count "HEAD...origin/$branch") -split '\s+'
    $ahead = [int]$lr[0]; $behind = [int]$lr[1]
    if ($ahead -eq 0 -and $behind -eq 0) {
      Say '   already in sync with origin' 'Green'
    } elseif ($ahead -eq 0) {
      git merge --ff-only "origin/$branch" | Out-Null
      Say ("   fast-forwarded $behind commit(s) from origin") 'Green'
    } elseif ($behind -eq 0) {
      Say ("   $ahead local commit(s) ahead of origin - will push after a good build") 'Green'
    } else {
      Say ("   diverged ($ahead local / $behind origin) - rebasing local work onto origin...") 'Yellow'
      # Auto-reconcile: rebase local onto origin, auto-resolving conflicts ONLY in
      # generated artifacts that still live in THIS repo post docs-split
      # (exports/*.csv + exports/*.json) -- they are regenerated, so taking
      # origin's copy is harmless. A real conflict in code / SQL / Lua still aborts
      # + warns for a human. Empty commits (already upstream) are skipped.
      git rebase "origin/$branch" 2>$null | Out-Null
      $guard = 0
      while ((Test-Path .git/rebase-merge) -or (Test-Path .git/rebase-apply)) {
        if ((++$guard) -gt 60) { git rebase --abort 2>$null | Out-Null; $rebaseConflict = $true; break }
        $conf = @(git ls-files -u | ForEach-Object { ($_ -split "`t")[-1] } | Sort-Object -Unique)
        if ($conf.Count -gt 0) {
          $bad = @($conf | Where-Object { $_ -notmatch '^exports/.*\.(csv|json)$' })
          if ($bad.Count -gt 0) { git rebase --abort 2>$null | Out-Null; $rebaseConflict = $true; break }
          foreach ($f in $conf) { git checkout --theirs -- $f 2>$null | Out-Null; git add -- $f 2>$null | Out-Null }
        }
        git -c core.editor=true rebase --continue 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0 -and ((Test-Path .git/rebase-merge) -or (Test-Path .git/rebase-apply))) {
          git rebase --skip 2>$null | Out-Null
        }
      }
      if ($rebaseConflict) {
        Say '   REBASE CONFLICT in code - aborted, building on-disk code. Resolve by hand, then rebuild.' 'Red'
      } else {
        Say '   rebase clean - local work replayed on top of origin (generated docs auto-resolved)' 'Green'
      }
    }
  }
}

# ---- [2] stop servers + back up binaries ----
Say '[2/5] Stopping servers + backing up current binaries...' 'Cyan'
schtasks /end /tn 'FFXIRelaunch' 2>$null | Out-Null
Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'powershell.exe' -and $_.CommandLine -match 'relaunch-supervisor' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -EA SilentlyContinue }
foreach($e in $exes){ Get-Process ($e -replace '\.exe$','') -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue }
Start-Sleep 3
foreach($e in $exes){ if(Test-Path "$root\$e"){ Copy-Item "$root\$e" "$root\$e.bak" -Force -EA SilentlyContinue } }

# ---- [2b] DB SAFETY SNAPSHOT (before any SQL touches xi_relaunch) ----
# Binaries get *.bak; the DB got nothing, so a bad / non-idempotent SQL apply had
# no rollback point. Take a timestamped mysqldump BEFORE [3] and keep the last 8.
# Fail-open: a dump failure warns loudly but never blocks the deploy. db-backups/
# is gitignored so [1]'s auto-commit never captures the dumps.
Say '[2b] DB safety snapshot (mysqldump xi_relaunch)...' 'Cyan'
$mysqldump = 'C:\Program Files\MariaDB 10.6\bin\mysqldump.exe'
$dumpDir   = Join-Path $root 'db-backups'
$null = New-Item -ItemType Directory -Force -Path $dumpDir
if (Test-Path $mysqldump) {
  $dumpFile = Join-Path $dumpDir ('xi_relaunch-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.sql')
  $dErr = "$env:TEMP\dumperr.txt"
  # --single-transaction = consistent InnoDB snapshot without locking players out.
  Start-Process -FilePath $mysqldump -ArgumentList @('-u','root','--password=richard','--single-transaction','--quick','--routines','--events','xi_relaunch') -RedirectStandardOutput $dumpFile -RedirectStandardError $dErr -Wait -NoNewWindow
  $dumpLen = (Get-Item $dumpFile -EA SilentlyContinue).Length
  if ($dumpLen -gt 4096) {
    Say ("   snapshot OK: {0} ({1:N1} MB)" -f (Split-Path $dumpFile -Leaf), ($dumpLen/1MB)) 'Green'
    Get-ChildItem $dumpDir -Filter 'xi_relaunch-*.sql' | Sort-Object LastWriteTime -Descending | Select-Object -Skip 8 | Remove-Item -Force -EA SilentlyContinue
  } else {
    Say '   WARNING: DB snapshot looks empty/failed - continuing WITHOUT a rollback point.' 'Yellow'
    if (Test-Path $dErr) { @(Get-Content $dErr) | Where-Object { $_ -notmatch 'Using a password on the command line' } | Select-Object -First 3 | ForEach-Object { Say ("     " + $_) 'Yellow' } }
  }
} else { Say '   WARNING: mysqldump not found - no DB snapshot taken this deploy.' 'Yellow' }

# my.ini config drift: a game deploy never cycles MariaDB, so if my.ini was edited
# after mysqld started, staged DB-config changes are NOT live (need a service restart).
try {
  $myIni   = 'C:\Program Files\MariaDB 10.6\data\my.ini'
  $mysqldP = Get-Process mysqld -EA SilentlyContinue | Select-Object -First 1
  if ((Test-Path $myIni) -and $mysqldP -and ((Get-Item $myIni).LastWriteTime -gt $mysqldP.StartTime)) {
    Say '   NOTE: my.ini edited after mysqld start - DB config staged but NOT active; restart the MariaDB service to apply (this deploy does not).' 'Yellow'
  }
} catch {}

# ---- [3] apply custom SQL ----
# [3a] the sql\zz*.sql OVERLAY layer (item mods / latents / carryforward).
# Owner escalation 2026-07-12: this layer previously only landed via a manual
# apply-custom-sql.bat run, so content like the 220 +4 reforge stat blocks
# could sit in the repo while the live items examined blank. Every deploy now
# applies it (idempotent INSERT IGNORE / ON DUPLICATE KEY UPDATE), BEFORE the
# modules layer so module config overrides keep the final word. Non-fatal:
# a failure here warns loudly but never blocks the deploy.
Say '[3/5] Applying sql\zz*.sql overlay layer (apply_custom_sql.py)...' 'Cyan'
$pyExe = 'C:\Program Files\Python312\python.exe'; if (-not (Test-Path $pyExe)) { $pyExe = 'python' }
$env:XI_MYSQL_BIN = $mysql
& $pyExe "$root\tools\apply_custom_sql.py" 2>&1 | ForEach-Object { Say ("   | " + $_) }
if ($LASTEXITCODE -ne 0) { Say '   WARNING: zz overlay apply FAILED - item-stat overlays may be stale (run apply-custom-sql.bat by hand).' 'Yellow' }

# [3b] modules\custom\sql (custom systems + config overrides - final word).
# RECURSE: subfolders (e.g. sql\trusts\) were silently skipped by the old
# top-level-only glob, so custom-trust SQL never reached the live DB via a deploy.
# Order = top-level first, then subfolders, alphabetical within each (stable).
# Every file must be idempotent (re-applied every deploy).
Say '   Applying modules\custom\sql (recursive, incl. subfolders) to xi_relaunch...' 'Cyan'
$sqlRoot = "$root\modules\custom\sql"
$sqls = Get-ChildItem $sqlRoot -Recurse -Filter '*.sql' -EA SilentlyContinue |
        Sort-Object -Property @{ Expression = { (Split-Path $_.FullName -Parent).Length } }, FullName
if ($sqls) {
  $sqlFail = 0
  foreach($f in $sqls){
    $o = "$env:TEMP\sqlout.txt"
    if (Test-Path $o) { Remove-Item $o -Force -EA SilentlyContinue }
    $rel = $f.FullName.Substring($sqlRoot.Length).TrimStart('\')
    Start-Process -FilePath $mysql -ArgumentList @('-u','root','--password=richard','xi_relaunch') -RedirectStandardInput $f.FullName -RedirectStandardError $o -Wait -NoNewWindow
    # The mysql client writes errors to stderr ($o). The old script redirected it
    # and never read it, so a broken/failed SQL file applied SILENTLY. Now we check
    # (filtering the benign command-line-password warning).
    $errLines = @()
    if (Test-Path $o) { $errLines = @(Get-Content $o | Where-Object { $_.Trim() -and $_ -notmatch 'Using a password on the command line' }) }
    if ($errLines.Count -gt 0) {
      $sqlFail++
      Say ("   FAILED  " + $rel + " :") 'Red'
      foreach ($ln in ($errLines | Select-Object -First 4)) { Say ("      " + $ln.Trim()) 'Red' }
    } else {
      Say ("   applied " + $rel)
    }
  }
  if ($sqlFail -gt 0) { Say ("   WARNING: {0} custom SQL file(s) reported errors above - the DB may be inconsistent. Review before relying on this deploy." -f $sqlFail) 'Yellow' }
} else { Say '   (no modules\custom\sql\**\*.sql files - skipped)' }

# ---- [4] C++ rebuild (MSVC/Ninja) ----
Say '[4/5] C++ rebuild (vcvars64 + cmake, Ninja/MSVC Release)...' 'Cyan'
# Build ONLY the 4 server targets. xi_test (the unit-test binary) fails to
# link because it references battleutils but does not include the custom
# fjb_combat module object -- it is not needed to run the server, and building
# it would abort the whole build (Ninja stops on first failure).
$buildLog = 'C:\server\vps-rebuild-build.log'
Say '   ninja prints [done/total] per step below = live progress (or run "Relaunch - Build Progress")' 'DarkGray'
$buildLine = 'call "' + $vcvars + '" >nul 2>&1 && cmake -B build -S . && cmake --build build --target xi_connect xi_world xi_search xi_map -j 4'
cmd /c $buildLine 2>&1 | Tee-Object -FilePath $buildLog   # console AND log, so progress is capturable
$buildOk = ($LASTEXITCODE -eq 0)

if ($buildOk) {
  Say '   build OK - new binaries in place.' 'Green'
  foreach($e in $exes){ Remove-Item "$root\$e.bak" -Force -EA SilentlyContinue }
} else {
  Say '   BUILD FAILED - restoring previous binaries from *.bak.' 'Red'
  foreach($e in $exes){ if(Test-Path "$root\$e.bak"){ Copy-Item "$root\$e.bak" "$root\$e" -Force -EA SilentlyContinue } }
}

# ---- ensure runtime output dirs exist before the map server boots ----
# navmeshes/ is where xi_map caches per-zone pathfinding meshes it builds at
# first zone load. If the folder is MISSING, CNavMesh::save fails ("Could not
# open file for writing navmeshes/<Zone>.nav") and the server rebuilds every
# zone's navmesh on EVERY start (slow boot + CPU + red error spam). It's
# untracked (not in git) so a fresh/cleaned C:\server can lack it; create if
# absent. There is no git clean in this deploy, so once built it persists.
$null = New-Item -ItemType Directory -Force -Path (Join-Path $root 'navmeshes')
Say '   navmeshes/ ensured (mob pathfinding cache)' 'DarkGray'

# ---- [5] restart + health check ----
Say '[5/5] Restarting servers via FFXIRelaunch task...' 'Cyan'
$mapLog  = Join-Path $root 'log\map-server.log'
$mapLen0 = 0; if (Test-Path $mapLog) { $mapLen0 = (Get-Item $mapLog).Length }
schtasks /run /tn 'FFXIRelaunch' 2>$null | Out-Null
Start-Sleep 8
$up = @(Get-Process | Where-Object { $_.ProcessName -like 'xi_*' } | Select-Object -ExpandProperty ProcessName -Unique)
foreach($e in $exes){ $n = $e -replace '\.exe$',''; if($up -contains $n){ Say ("   " + $n + " : active") 'Green' } else { Say ("   " + $n + " : NOT UP") 'Yellow' } }

# Process-up != booted-OK. Wait for xi_map to log the readiness marker
# ('The map-server is ready to work...') from THIS restart, then scan the new tail
# for fatal boot errors. Bounded ~2 min; read shared so the live writer is not locked.
Say '   verifying map-server readiness (loads all zones)...' 'DarkGray'
$mapReady = $false; $newLog = ''; $w = 0
do {
  Start-Sleep 6; $w++
  if (Test-Path $mapLog) {
    try {
      $fs = New-Object System.IO.FileStream($mapLog, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
      $fs.Seek($mapLen0, [System.IO.SeekOrigin]::Begin) | Out-Null
      $sr = New-Object System.IO.StreamReader($fs); $newLog = $sr.ReadToEnd(); $sr.Close(); $fs.Close()
    } catch {}
    if ($newLog -match 'map-server is ready to work') { $mapReady = $true }
  }
} while (-not $mapReady -and $w -lt 20)
if ($mapReady) {
  Say '   map-server: READY (all zones loaded).' 'Green'
  $bootErr = @($newLog -split "`r?`n" | Where-Object { $_ -match '\[error\]|\[critical\]|CacheLuaObjectFromFile' } | Select-Object -First 8)
  if ($bootErr.Count -gt 0) {
    Say ("   NOTE: {0} error/critical line(s) during boot - review map-server.log:" -f $bootErr.Count) 'Yellow'
    foreach ($b in $bootErr) { Say ("      " + $b.Trim()) 'Yellow' }
  } else { Say '   boot clean - no error/critical lines.' 'Green' }
} else {
  Say '   WARNING: no readiness marker within ~2 min - CHECK map-server.log (still loading, or a boot fault).' 'Yellow'
}

# ---- [+] back up local commit(s) to origin - ONLY after a good build and a
#      clean git state (never push a broken build or an unresolved divergence) ----
if ($buildOk -and $gitReady -and (-not $rebaseConflict)) {
  $localAhead = 0
  try { $localAhead = [int](git rev-list --count "origin/$branch..HEAD" 2>$null) } catch {}
  if ($localAhead -gt 0) {
    Say ("[git] pushing $localAhead local commit(s) to origin/$branch (backup)...") 'Cyan'
    git push origin $branch
    if ($LASTEXITCODE -eq 0) { Say '   pushed - box is backed up to GitHub' 'Green' }
    else { Say '   push failed (offline/no creds) - local commit(s) remain on the box only' 'Yellow' }
  }
}

Say ''
if ($buildOk) { Say ('REBUILD COMPLETE (build OK). Map server loads all zones in ~1-2 min.') 'Green' }
else          { Say ('REBUILD FINISHED BUT BUILD FAILED - running PREVIOUS binaries. See errors above / ' + $log) 'Red' }
if ($rebaseConflict) { Say ('NOTE: git rebase had conflicts - built ON-DISK code, origin NOT merged. Resolve manually.') 'Red' }
Say '======================================================='

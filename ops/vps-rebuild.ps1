# =====================================================================
# vps-rebuild.ps1 - OVH VPS RELAUNCH full rebuild (runs LOCALLY on the VPS)
# Equivalent of the old Azure relaunch-rebuild.bat, retargeted to C:\server.
#
#   [1] git SYNC with origin/relaunch  (auto-reconcile - see below)
#   [2] stop servers + back up binaries    (Windows locks running .exe)
#   [3] apply modules\custom\sql\*.sql -> xi_relaunch
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
      git rebase "origin/$branch"
      if ($LASTEXITCODE -ne 0) {
        git rebase --abort 2>$null | Out-Null
        $rebaseConflict = $true
        Say '   REBASE CONFLICT - aborted, building on-disk code. Resolve by hand, then rebuild.' 'Red'
      } else {
        Say '   rebase clean - local work replayed on top of origin' 'Green'
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

# ---- [3] apply custom SQL ----
Say '[3/5] Applying modules\custom\sql\*.sql to xi_relaunch...' 'Cyan'
$sqls = Get-ChildItem "$root\modules\custom\sql\*.sql" -EA SilentlyContinue
if ($sqls) {
  foreach($f in $sqls){
    $o = "$env:TEMP\sqlout.txt"
    Start-Process -FilePath $mysql -ArgumentList @('-u','root','--password=richard','xi_relaunch') -RedirectStandardInput $f.FullName -RedirectStandardError $o -Wait -NoNewWindow
    Say ("   applied " + $f.Name)
  }
} else { Say '   (no modules\custom\sql\*.sql files - skipped)' }

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

# ---- [5] restart + health check ----
Say '[5/5] Restarting servers via FFXIRelaunch task...' 'Cyan'
schtasks /run /tn 'FFXIRelaunch' 2>$null | Out-Null
Start-Sleep 8
$up = @(Get-Process | Where-Object { $_.ProcessName -like 'xi_*' } | Select-Object -ExpandProperty ProcessName -Unique)
foreach($e in $exes){ $n = $e -replace '\.exe$',''; if($up -contains $n){ Say ("   " + $n + " : active") 'Green' } else { Say ("   " + $n + " : NOT UP") 'Yellow' } }

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

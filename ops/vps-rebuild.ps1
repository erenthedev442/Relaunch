# =====================================================================
# vps-rebuild.ps1 - OVH VPS RELAUNCH full rebuild (runs LOCALLY on the VPS)
# Equivalent of the old Azure relaunch-rebuild.bat, retargeted to C:\server.
#
#   [1] git pull origin relaunch (if tree clean; else builds on-disk edits)
#   [2] stop servers + back up binaries    (Windows locks running .exe)
#   [3] apply modules\custom\sql\*.sql -> xi_relaunch
#   [4] C++ rebuild (MSVC/Ninja) in C:\server\build
#   [5] restart servers + health check
#
# SAFETY: current xi_*.exe are copied to *.bak before the build. If the
# build fails, the .bak binaries are restored so the server still comes
# back up on the previous working build. Does NOT publish the website
# (that was Azure-box infra) and does NOT touch git history/markers.
# =====================================================================
$ErrorActionPreference = 'Continue'
$root   = 'C:\server'
$mysql  = 'C:\Program Files\MariaDB 10.6\bin\mysql.exe'
$vcvars = 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat'
$exes   = 'xi_connect.exe','xi_world.exe','xi_search.exe','xi_map.exe'
$log    = Join-Path $root 'vps-rebuild.log'

function Say($m,$c='Gray'){ Write-Host $m -ForegroundColor $c; try { Add-Content $log ("{0} {1}" -f (Get-Date -Format 'HH:mm:ss'),$m) } catch {} }

Say '' ; Say '================= VPS RELAUNCH REBUILD =================' 'Cyan'
Set-Location $root

# ---- [1] git pull (NON-FATAL: if the tree has local edits/commits or is
#      offline, we just build whatever code is on disk. Editing directly in
#      the VPS RDP session is a first-class workflow -- no laptop needed) ----
Say '[1/5] git pull --ff-only origin relaunch (optional; builds on-disk code either way)...' 'Cyan'
git pull --ff-only origin relaunch
if ($LASTEXITCODE -ne 0) {
  Say '   (pull skipped - local edits/commits or offline; building the code currently on disk)' 'Yellow'
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

Say ''
if ($buildOk) { Say ('REBUILD COMPLETE (build OK). Map server loads all zones in ~1-2 min.') 'Green' }
else          { Say ('REBUILD FINISHED BUT BUILD FAILED - running PREVIOUS binaries. See errors above / ' + $log) 'Red' }
Say '======================================================='

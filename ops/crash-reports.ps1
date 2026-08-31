# Newest Wheaty crash reports + supervisor deaths. Run from the VPS.
$ErrorActionPreference = 'Continue'
$root = 'C:\server'
$dmp  = Join-Path $root 'dmp'
$sup  = Join-Path $root 'relaunch-supervisor.log'
$map  = Join-Path $root 'log\map-server.log'

Write-Host ''
Write-Host '=== Supervisor (last 8 start / hang / kill lines) ===' -ForegroundColor Cyan
if (Test-Path $sup) {
    Select-String -Path $sup -Pattern 'Starting xi_|HUNG|force kill|Supervisor starting' |
        Select-Object -Last 8 |
        ForEach-Object { $_.Line }
} else {
    Write-Host "(no $sup)"
}

Write-Host ''
Write-Host '=== Top 5 crash reports (C:\server\dmp) ===' -ForegroundColor Cyan
$reports = @(Get-ChildItem (Join-Path $dmp '*.log') -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 5)
if (-not $reports) {
    Write-Host '(no Wheaty .log files — process may have hung without a dump)'
} else {
    $n = 0
    foreach ($f in $reports) {
        $n++
        Write-Host ''
        Write-Host ("---- {0}  {1}  {2} ----" -f $n, $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'), $f.Name) -ForegroundColor Yellow
        $lines = Get-Content $f.FullName -TotalCount 80
        $keep = $lines | Where-Object {
            $_ -match 'CRASH|Exception code|Assertion|Watchdog|Faulting|\.cpp|\.h:|\.lua:'
        }
        if ($keep) { $keep | Select-Object -First 12 } else { $lines | Select-Object -First 15 }
    }
}

Write-Host ''
Write-Host '=== Last 5 map errors (watchdog / Lua / fatal) ===' -ForegroundColor Cyan
if (Test-Path $map) {
    Select-String -Path $map -Pattern 'INACTIVITY WATCHDOG|luautils::|Fatal|std::terminate|!!! CRASH' |
        Select-Object -Last 5 |
        ForEach-Object { $_.Line.Trim() }
} else {
    Write-Host "(no $map)"
}
Write-Host ''
